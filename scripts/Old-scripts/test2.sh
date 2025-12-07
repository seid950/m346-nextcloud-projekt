#!/bin/bash
# ==============================================
# Nextcloud Deployment Script - Modul 346
# Team: Seid Veseli, Amar Ibraimi, Leandro Graf
# Erstellt automatisch Web- und DB-Server auf AWS
# ==============================================

set -e  # Bei Fehler abbrechen

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   NEXTCLOUD DEPLOYMENT GESTARTET${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# ==============================================
# KONFIGURATION
# ==============================================
REGION="us-east-1"
AMI_ID="ami-03deb8c961063af8c"  # Ubuntu 22.04 LTS
INSTANCE_TYPE="t2.micro"
KEY_NAME="vockey"
NEXTCLOUD_VERSION="28.0.1"

# Sichere Passwörter generieren (24 Zeichen, alphanumerisch)
DB_ROOT_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-24)
DB_NC_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-24)

echo -e "${BLUE}Konfiguration:${NC}"
echo "  Region: $REGION"
echo "  Instance Type: $INSTANCE_TYPE"
echo "  Nextcloud Version: $NEXTCLOUD_VERSION"
echo "  Key Name: $KEY_NAME"
echo ""
echo -e "${BLUE}Generierte Passwörter:${NC}"
echo "  DB Root: $DB_ROOT_PASSWORD"
echo "  DB Nextcloud: $DB_NC_PASSWORD"
echo ""

# ==============================================
# 1. AWS CLI PRÜFEN
# ==============================================
echo -e "${YELLOW}[1/9] Überprüfe AWS CLI...${NC}"

if ! command -v aws &> /dev/null; then
    echo -e "${RED}ERROR: AWS CLI nicht gefunden!${NC}"
    exit 1
fi

if ! aws sts get-caller-identity --region $REGION &> /dev/null; then
    echo -e "${RED}ERROR: AWS Credentials nicht konfiguriert!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ AWS CLI konfiguriert${NC}"
echo ""

# ==============================================
# 2. ALTE RESSOURCEN AUFRÄUMEN
# ==============================================
echo -e "${YELLOW}[2/9] Räume alte Ressourcen auf...${NC}"

OLD_INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=nextcloud-*" "Name=instance-state-name,Values=running,pending,stopped" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text \
    --region $REGION 2>/dev/null || true)

if [ ! -z "$OLD_INSTANCES" ]; then
    echo "  Terminiere alte Instanzen: $OLD_INSTANCES"
    aws ec2 terminate-instances --instance-ids $OLD_INSTANCES --region $REGION > /dev/null
    aws ec2 wait instance-terminated --instance-ids $OLD_INSTANCES --region $REGION 2>/dev/null || sleep 30
    echo -e "${GREEN}✓ Alte Instanzen entfernt${NC}"
fi

sleep 5
aws ec2 delete-security-group --group-name nextcloud-web-sg --region $REGION 2>/dev/null && echo "  ✓ Alte Web-SG gelöscht" || true
aws ec2 delete-security-group --group-name nextcloud-db-sg --region $REGION 2>/dev/null && echo "  ✓ Alte DB-SG gelöscht" || true

echo -e "${GREEN}✓ Aufräumen abgeschlossen${NC}"
echo ""

# ==============================================
# 3. SECURITY GROUPS ERSTELLEN
# ==============================================
echo -e "${YELLOW}[3/9] Erstelle Security Groups...${NC}"

DB_SG_ID=$(aws ec2 create-security-group \
    --group-name nextcloud-db-sg \
    --description "Nextcloud Database Server - M346" \
    --region $REGION \
    --query 'GroupId' \
    --output text)

WEB_SG_ID=$(aws ec2 create-security-group \
    --group-name nextcloud-web-sg \
    --description "Nextcloud Web Server - M346" \
    --region $REGION \
    --query 'GroupId' \
    --output text)

echo "  DB Security Group: $DB_SG_ID"
echo "  Web Security Group: $WEB_SG_ID"

# Firewall-Regeln
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $REGION > /dev/null
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION > /dev/null
aws ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 3306 --source-group $WEB_SG_ID --region $REGION > /dev/null
aws ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION > /dev/null

echo -e "${GREEN}✓ Security Groups konfiguriert${NC}"
echo ""

# ==============================================
# 4. CLOUD-INIT DATABASE ERSTELLEN
# ==============================================
echo -e "${YELLOW}[4/9] Erstelle Cloud-Init für Datenbank...${NC}"

cat > cloud-init-database.yaml << EOF
#cloud-config
# Nextcloud Database Server - Modul 346
# Automatisierte MariaDB Installation

package_update: true
package_upgrade: true

packages:
  - mariadb-server
  - mariadb-client

write_files:
  - path: /root/setup-db.sh
    permissions: '0700'
    content: |
      #!/bin/bash
      exec > >(tee /var/log/db-setup.log)
      exec 2>&1
      set -e
      
      echo "=== Database Setup Start ==="
      
      # Warten bis MariaDB bereit
      sleep 10
      
      # Root-Passwort setzen
      mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';"
      mysql -e "DELETE FROM mysql.user WHERE User='';"
      mysql -e "DROP DATABASE IF EXISTS test;"
      mysql -e "FLUSH PRIVILEGES;"
      
      # Nextcloud Datenbank erstellen
      mysql -u root -p'${DB_ROOT_PASSWORD}' << SQLEOF
CREATE DATABASE nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'nextcloud'@'%' IDENTIFIED BY '${DB_NC_PASSWORD}';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'%';
FLUSH PRIVILEGES;
SQLEOF
      
      echo "=== Database Setup Complete ==="

  - path: /etc/mysql/mariadb.conf.d/60-nextcloud.cnf
    content: |
      [mysqld]
      bind-address = 0.0.0.0
      max_connections = 200
      innodb_buffer_pool_size = 128M
      character_set_server = utf8mb4
      collation_server = utf8mb4_general_ci

runcmd:
  - systemctl start mariadb
  - systemctl enable mariadb
  - bash /root/setup-db.sh
  - systemctl restart mariadb
  - |
    PRIVATE_IP=\$(hostname -I | awk '{print \$1}')
    echo "=== DB Server Ready ==="
    echo "Private IP: \$PRIVATE_IP"
    echo "Database: nextcloud"
    echo "User: nextcloud"

final_message: "Database Server ready after \$UPTIME seconds"
EOF

echo -e "${GREEN}✓ cloud-init-database.yaml erstellt${NC}"
echo ""

# ==============================================
# 5. DATENBANK-SERVER STARTEN
# ==============================================
echo -e "${YELLOW}[5/9] Starte Datenbank-Server...${NC}"

DB_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $DB_SG_ID \
    --user-data file://cloud-init-database.yaml \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nextcloud-db},{Key=Project,Value=M346-Nextcloud}]' \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "  Instance ID: $DB_INSTANCE_ID"
aws ec2 wait instance-running --instance-ids $DB_INSTANCE_ID --region $REGION

DB_PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids $DB_INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text)

echo -e "${GREEN}✓ Datenbank-Server gestartet${NC}"
echo "  Private IP: $DB_PRIVATE_IP"
echo "  Warte 120 Sekunden für MariaDB Setup..."
sleep 120
echo ""

# ==============================================
# 6. CLOUD-INIT WEBSERVER ERSTELLEN
# ==============================================
echo -e "${YELLOW}[6/9] Erstelle Cloud-Init für Webserver...${NC}"

cat > cloud-init-webserver.yaml << EOF
#cloud-config
# Nextcloud Webserver - Modul 346
# Automatisierte Nextcloud Installation

package_update: true
package_upgrade: true

packages:
  - apache2
  - libapache2-mod-php
  - php
  - php-mysql
  - php-zip
  - php-xml
  - php-mbstring
  - php-gd
  - php-curl
  - php-imagick
  - php-intl
  - php-bcmath
  - php-gmp
  - wget
  - bzip2
  - unzip

write_files:
  - path: /root/install-nextcloud.sh
    permissions: '0700'
    content: |
      #!/bin/bash
      exec > >(tee /var/log/nextcloud-install.log)
      exec 2>&1
      set -e
      
      echo "=== Nextcloud Installation Start ==="
      
      cd /tmp
      
      # Download mit Fallback
      if ! wget --timeout=60 https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2; then
        echo "Fallback to latest version..."
        wget --timeout=60 https://download.nextcloud.com/server/releases/latest.tar.bz2
        mv latest.tar.bz2 nextcloud-${NEXTCLOUD_VERSION}.tar.bz2
      fi
      
      tar -xjf nextcloud-${NEXTCLOUD_VERSION}.tar.bz2
      
      # Installation
      rm -rf /var/www/html/*
      mv nextcloud/* /var/www/html/
      rm -rf /tmp/nextcloud /tmp/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2
      
      mkdir -p /var/nextcloud-data
      chown -R www-data:www-data /var/www/html/
      chown -R www-data:www-data /var/nextcloud-data/
      chmod -R 755 /var/www/html/
      
      echo "=== Nextcloud Installation Complete ==="

  - path: /etc/apache2/sites-available/000-default.conf
    content: |
      <VirtualHost *:80>
          DocumentRoot /var/www/html
          
          <Directory /var/www/html/>
              Require all granted
              AllowOverride All
              Options FollowSymLinks MultiViews
              
              <IfModule mod_dav.c>
                  Dav off
              </IfModule>
          </Directory>
          
          ErrorLog \${APACHE_LOG_DIR}/error.log
          CustomLog \${APACHE_LOG_DIR}/access.log combined
      </VirtualHost>

runcmd:
  - a2enmod rewrite headers env dir mime setenvif
  - systemctl restart apache2
  - bash /root/install-nextcloud.sh
  - |
    PUBLIC_IP=\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    cat > /root/nextcloud-info.txt << 'INFOEOF'
NEXTCLOUD BEREIT
URL: http://\$PUBLIC_IP

Setup-Assistent:
  Admin: selbst waehlen
  Datenverzeichnis: /var/nextcloud-data
  
Datenbank MySQL/MariaDB:
  Host: ${DB_PRIVATE_IP}
  Name: nextcloud
  User: nextcloud
  Password: ${DB_NC_PASSWORD}
INFOEOF
  - cat /root/nextcloud-info.txt

final_message: "Webserver ready after \$UPTIME seconds"
EOF

echo -e "${GREEN}✓ cloud-init-webserver.yaml erstellt${NC}"
echo ""

# ==============================================
# 7. WEBSERVER STARTEN
# ==============================================
echo -e "${YELLOW}[7/9] Starte Webserver...${NC}"

WEB_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $WEB_SG_ID \
    --user-data file://cloud-init-webserver.yaml \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nextcloud-web},{Key=Project,Value=M346-Nextcloud}]' \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "  Instance ID: $WEB_INSTANCE_ID"
aws ec2 wait instance-running --instance-ids $WEB_INSTANCE_ID --region $REGION

WEB_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $WEB_INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo -e "${GREEN}✓ Webserver gestartet${NC}"
echo "  Public IP: $WEB_PUBLIC_IP"
echo ""

# ==============================================
# 8. WARTE BIS WEBSERVER BEREIT
# ==============================================
echo -e "${YELLOW}[8/9] Warte bis Webserver bereit ist...${NC}"
echo "Dies kann 2-4 Minuten dauern..."
echo ""

MAX_WAIT=300
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$WEB_PUBLIC_IP 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        echo ""
        echo -e "${GREEN}✓ Webserver antwortet!${NC}"
        break
    fi
    
    echo -n "."
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

echo ""

if [ $ELAPSED -ge $MAX_WAIT ]; then
    echo -e "${RED}⚠️  Timeout nach 5 Minuten${NC}"
    echo "Prüfe: aws ec2 get-console-output --instance-id $WEB_INSTANCE_ID --region $REGION"
fi

echo ""

# ==============================================
# 9. DEPLOYMENT-INFO SPEICHERN
# ==============================================
echo -e "${YELLOW}[9/9] Speichere Deployment-Informationen...${NC}"

cat > deployment-info.json << EOF
{
  "deployment_date": "$(date -u +"%Y-%m-%d %H:%M:%S UTC")",
  "team": ["Seid Veseli", "Amar Ibraimi", "Leandro Graf"],
  "region": "$REGION",
  "nextcloud_version": "$NEXTCLOUD_VERSION",
  "database": {
    "instance_id": "$DB_INSTANCE_ID",
    "private_ip": "$DB_PRIVATE_IP",
    "security_group": "$DB_SG_ID",
    "database_name": "nextcloud",
    "database_user": "nextcloud",
    "database_password": "$DB_NC_PASSWORD",
    "root_password": "$DB_ROOT_PASSWORD"
  },
  "webserver": {
    "instance_id": "$WEB_INSTANCE_ID",
    "public_ip": "$WEB_PUBLIC_IP",
    "security_group": "$WEB_SG_ID",
    "url": "http://$WEB_PUBLIC_IP"
  }
}
EOF

echo -e "${GREEN}✓ deployment-info.json erstellt${NC}"
echo ""

# ==============================================
# ZUSAMMENFASSUNG
# ==============================================
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   DEPLOYMENT ERFOLGREICH!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}📊 SERVER DETAILS:${NC}"
echo ""
echo "Database Server:"
echo "  Instance ID:  $DB_INSTANCE_ID"
echo "  Private IP:   $DB_PRIVATE_IP"
echo "  Security Group: $DB_SG_ID"
echo ""
echo "Web Server:"
echo "  Instance ID:  $WEB_INSTANCE_ID"
echo "  Public IP:    $WEB_PUBLIC_IP"
echo "  Security Group: $WEB_SG_ID"
echo ""
echo -e "${BLUE}🌐 NEXTCLOUD URL:${NC}"
echo -e "${GREEN}  http://$WEB_PUBLIC_IP${NC}"
echo ""
echo -e "${BLUE}🔐 DATENBANK-ZUGANGSDATEN FÜR SETUP-ASSISTENT:${NC}"
echo "  ┌─────────────────────────────────────────────────┐"
echo "  │ Datenbank-Typ: MySQL/MariaDB                    │"
echo "  │ Datenbank-Host: $DB_PRIVATE_IP              │"
echo "  │ Datenbank-Name: nextcloud                       │"
echo "  │ Datenbank-User: nextcloud                       │"
echo "  │ Datenbank-Passwort: $DB_NC_PASSWORD │"
echo "  │ Datenverzeichnis: /var/nextcloud-data           │"
echo "  └─────────────────────────────────────────────────┘"
echo ""
echo -e "${YELLOW}📝 NÄCHSTE SCHRITTE:${NC}"
echo "  1. Öffne im Browser: http://$WEB_PUBLIC_IP"
echo "  2. Erstelle Admin-Account (frei wählbar)"
echo "  3. Trage obige Datenbank-Daten ein"
echo "  4. Klicke 'Installation abschließen'"
echo ""
echo -e "${BLUE}📂 DATEIEN:${NC}"
echo "  • cloud-init-database.yaml - DB-Konfiguration"
echo "  • cloud-init-webserver.yaml - Web-Konfiguration"
echo "  • deployment-info.json - Alle Details & Passwörter"
echo ""
echo -e "${BLUE}🔍 LOGS PRÜFEN:${NC}"
echo "  aws ec2 get-console-output --instance-id $WEB_INSTANCE_ID --region $REGION"
echo ""
echo -e "${GREEN}========================================${NC}"

# Cleanup temporäre User-Data Dateien (falls vorhanden)
rm -f db-userdata.sh web-userdata.sh 2>/dev/null || true