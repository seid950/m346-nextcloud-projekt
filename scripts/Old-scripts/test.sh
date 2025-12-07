#!/bin/bash
# ==============================================
# Nextcloud Deployment Script - Modul 346
# Erstellt automatisch Web- und DB-Server auf AWS
# Ausführung: bash deploy.sh
# ==============================================

set -e  # Bei Fehler abbrechen

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================
# KONFIGURATION
# ==============================================
REGION="us-east-1"
AMI_ID="ami-0e2c8caa4b6378d8c"  # Ubuntu 22.04 LTS
INSTANCE_TYPE="t2.micro"
KEY_NAME="vockey"
NEXTCLOUD_VERSION="28.0.1"

# Sichere Passwörter generieren
DB_ROOT_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-24)
DB_NC_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-24)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   NEXTCLOUD DEPLOYMENT GESTARTET${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Konfiguration:${NC}"
echo "  Region: $REGION"
echo "  Instance Type: $INSTANCE_TYPE"
echo "  Nextcloud Version: $NEXTCLOUD_VERSION"
echo "  Key Name: $KEY_NAME"
echo ""

# ==============================================
# 1. AWS CLI ÜBERPRÜFEN
# ==============================================
echo -e "${YELLOW}[1/8] Überprüfe AWS CLI...${NC}"

if ! command -v aws &> /dev/null; then
    echo -e "${RED}ERROR: AWS CLI nicht gefunden!${NC}"
    echo "Installiere AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

# AWS Credentials testen
if ! aws sts get-caller-identity --region $REGION &> /dev/null; then
    echo -e "${RED}ERROR: AWS Credentials nicht konfiguriert!${NC}"
    echo "Führe aus: aws configure"
    exit 1
fi

echo -e "${GREEN}✓ AWS CLI konfiguriert${NC}"
echo ""

# ==============================================
# 2. ALTE RESSOURCEN AUFRÄUMEN
# ==============================================
echo -e "${YELLOW}[2/8] Räume alte Ressourcen auf...${NC}"

# Alte Instanzen finden
OLD_INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=M346-Nextcloud" \
              "Name=instance-state-name,Values=running,pending,stopped" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text \
    --region $REGION 2>/dev/null || true)

if [ ! -z "$OLD_INSTANCES" ]; then
    echo "  Terminiere alte Instanzen: $OLD_INSTANCES"
    aws ec2 terminate-instances --instance-ids $OLD_INSTANCES --region $REGION > /dev/null
    echo "  Warte auf Terminierung..."
    aws ec2 wait instance-terminated --instance-ids $OLD_INSTANCES --region $REGION 2>/dev/null || sleep 30
    echo -e "${GREEN}✓ Alte Instanzen entfernt${NC}"
else
    echo "  Keine alten Instanzen gefunden"
fi

# Alte Security Groups löschen (nach kurzer Wartezeit)
sleep 5
aws ec2 delete-security-group --group-name nextcloud-web-sg --region $REGION 2>/dev/null && echo "  ✓ Alte Web-SG gelöscht" || true
aws ec2 delete-security-group --group-name nextcloud-db-sg --region $REGION 2>/dev/null && echo "  ✓ Alte DB-SG gelöscht" || true

echo -e "${GREEN}✓ Aufräumen abgeschlossen${NC}"
echo ""

# ==============================================
# 3. SECURITY GROUPS ERSTELLEN
# ==============================================
echo -e "${YELLOW}[3/8] Erstelle Security Groups...${NC}"

# Datenbank Security Group
DB_SG_ID=$(aws ec2 create-security-group \
    --group-name nextcloud-db-sg \
    --description "Nextcloud Database Server - M346" \
    --region $REGION \
    --query 'GroupId' \
    --output text)
echo "  DB Security Group: $DB_SG_ID"

# Web Security Group
WEB_SG_ID=$(aws ec2 create-security-group \
    --group-name nextcloud-web-sg \
    --description "Nextcloud Web Server - M346" \
    --region $REGION \
    --query 'GroupId' \
    --output text)
echo "  Web Security Group: $WEB_SG_ID"

# Firewall-Regeln hinzufügen
echo "  Konfiguriere Firewall-Regeln..."

# Web: HTTP (80)
aws ec2 authorize-security-group-ingress \
    --group-id $WEB_SG_ID \
    --protocol tcp --port 80 --cidr 0.0.0.0/0 \
    --region $REGION > /dev/null

# Web: SSH (22)
aws ec2 authorize-security-group-ingress \
    --group-id $WEB_SG_ID \
    --protocol tcp --port 22 --cidr 0.0.0.0/0 \
    --region $REGION > /dev/null

# DB: MySQL nur von Web Security Group
aws ec2 authorize-security-group-ingress \
    --group-id $DB_SG_ID \
    --protocol tcp --port 3306 --source-group $WEB_SG_ID \
    --region $REGION > /dev/null

# DB: SSH (22)
aws ec2 authorize-security-group-ingress \
    --group-id $DB_SG_ID \
    --protocol tcp --port 22 --cidr 0.0.0.0/0 \
    --region $REGION > /dev/null

echo -e "${GREEN}✓ Security Groups konfiguriert${NC}"
echo ""

# ==============================================
# 4. CLOUD-INIT DATEIEN ERSTELLEN
# ==============================================
echo -e "${YELLOW}[4/8] Erstelle Cloud-Init Konfigurationen...${NC}"

# ===== DATABASE CLOUD-INIT =====
cat > cloud-init-database.yaml << EOF
#cloud-config
# Nextcloud Database Server
# Projekt: Modul 346
# Automatisierte MariaDB Installation

package_update: true
package_upgrade: true

packages:
  - mariadb-server
  - mariadb-client

write_files:
  - path: /root/setup-database.sh
    permissions: '0700'
    content: |
      #!/bin/bash
      set -e
      
      echo "=== Database Setup gestartet ==="
      
      # Warten bis MariaDB bereit ist
      sleep 10
      
      # Root-Passwort setzen
      mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';"
      mysql -e "FLUSH PRIVILEGES;"
      
      # Nextcloud Datenbank und User erstellen
      mysql -u root -p'${DB_ROOT_PASSWORD}' << SQLEOF
CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS 'nextcloud'@'%' IDENTIFIED BY '${DB_NC_PASSWORD}';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'%';
FLUSH PRIVILEGES;
SQLEOF
      
      echo "=== Database Setup abgeschlossen ==="

  - path: /etc/mysql/mariadb.conf.d/60-nextcloud.cnf
    content: |
      [mysqld]
      # Remote-Zugriff erlauben
      bind-address = 0.0.0.0
      
      # Performance-Optimierungen
      max_connections = 200
      innodb_buffer_pool_size = 128M
      
      # Zeichensatz
      character_set_server = utf8mb4
      collation_server = utf8mb4_general_ci

runcmd:
  # MariaDB starten
  - systemctl start mariadb
  - systemctl enable mariadb
  
  # Setup-Script ausführen
  - bash /root/setup-database.sh
  
  # MariaDB mit neuer Config neustarten
  - systemctl restart mariadb
  
  # Status-Info ausgeben
  - |
    PRIVATE_IP=\$(hostname -I | awk '{print \$1}')
    cat > /root/db-info.txt << INFOEOF
================================================
      DATENBANK SERVER BEREIT
================================================

Private IP: \$PRIVATE_IP
Database: nextcloud
User: nextcloud
Password: ${DB_NC_PASSWORD}
Root Password: ${DB_ROOT_PASSWORD}

Status: \$(systemctl is-active mariadb)
================================================
INFOEOF
  - cat /root/db-info.txt

final_message: "Database Server Setup abgeschlossen nach \$UPTIME Sekunden"
EOF

echo "  ✓ cloud-init-database.yaml erstellt"

# ===== WEBSERVER CLOUD-INIT (wird nach DB-Start generiert) =====
# Wird später erstellt wenn wir die DB Private IP haben

echo -e "${GREEN}✓ Cloud-Init Dateien vorbereitet${NC}"
echo ""

# ==============================================
# 5. DATENBANK-SERVER STARTEN
# ==============================================
echo -e "${YELLOW}[5/8] Starte Datenbank-Server...${NC}"

DB_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $DB_SG_ID \
    --user-data file://cloud-init-database.yaml \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=nextcloud-database},{Key=Project,Value=M346-Nextcloud},{Key=Type,Value=Database}]" \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "  Instance ID: $DB_INSTANCE_ID"
echo "  Warte bis Instanz läuft..."

aws ec2 wait instance-running --instance-ids $DB_INSTANCE_ID --region $REGION

# Private IP abrufen
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
# 6. WEBSERVER CLOUD-INIT ERSTELLEN
# ==============================================
echo -e "${YELLOW}[6/8] Erstelle Webserver Cloud-Init...${NC}"

cat > cloud-init-webserver.yaml << EOF
#cloud-config
# Nextcloud Webserver
# Projekt: Modul 346
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
      set -e
      
      echo "=== Nextcloud Installation gestartet ==="
      
      # Nextcloud herunterladen (spezifische Version mit Fallback)
      cd /tmp
      wget --timeout=30 --tries=3 https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2 || \
      wget --timeout=30 --tries=3 https://download.nextcloud.com/server/releases/latest.tar.bz2 && \
      mv latest.tar.bz2 nextcloud-${NEXTCLOUD_VERSION}.tar.bz2
      
      # Entpacken
      tar -xjf nextcloud-${NEXTCLOUD_VERSION}.tar.bz2
      
      # Nach /var/www/html verschieben (für Root-Zugriff)
      rm -rf /var/www/html/*
      mv nextcloud/* /var/www/html/
      mv nextcloud/.htaccess /var/www/html/ 2>/dev/null || true
      mv nextcloud/.user.ini /var/www/html/ 2>/dev/null || true
      
      # Datenverzeichnis außerhalb von DocumentRoot
      mkdir -p /var/nextcloud-data
      
      # Berechtigungen setzen
      chown -R www-data:www-data /var/www/html/
      chown -R www-data:www-data /var/nextcloud-data/
      chmod -R 755 /var/www/html/
      
      # Cleanup
      rm -rf /tmp/nextcloud /tmp/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2
      
      echo "=== Nextcloud Dateien installiert ==="

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
          
          ErrorLog \${APACHE_LOG_DIR}/nextcloud_error.log
          CustomLog \${APACHE_LOG_DIR}/nextcloud_access.log combined
      </VirtualHost>

runcmd:
  # Apache Module aktivieren
  - a2enmod rewrite headers env dir mime setenvif
  
  # Apache neustarten
  - systemctl restart apache2
  
  # Nextcloud installieren
  - bash /root/install-nextcloud.sh
  
  # Datenbank-Verbindung testen
  - |
    echo "=== Teste Datenbankverbindung ==="
    apt-get install -y mariadb-client
    if mysql -h ${DB_PRIVATE_IP} -u nextcloud -p'${DB_NC_PASSWORD}' -e "SELECT 1;" 2>/dev/null; then
      echo "✓ Datenbankverbindung erfolgreich"
    else
      echo "✗ Datenbankverbindung fehlgeschlagen"
    fi
  
  # Info-Datei erstellen
  - |
    PUBLIC_IP=\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    cat > /root/nextcloud-info.txt << INFOEOF
================================================
      NEXTCLOUD WEBSERVER BEREIT
================================================

Nextcloud URL: http://\$PUBLIC_IP

SETUP-ASSISTENT AUSFÜLLEN:

1. Admin-Account erstellen:
   Username: (frei wählbar, z.B. "admin")
   Passwort: (mind. 8 Zeichen, sicher wählen)

2. Datenverzeichnis:
   /var/nextcloud-data

3. Datenbank konfigurieren (MySQL/MariaDB):
   Datenbank-Benutzer: nextcloud
   Datenbank-Passwort: ${DB_NC_PASSWORD}
   Datenbank-Name: nextcloud
   Datenbank-Host: ${DB_PRIVATE_IP}

================================================
INFOEOF
  - cat /root/nextcloud-info.txt

final_message: "Webserver Setup abgeschlossen nach \$UPTIME Sekunden"
EOF

echo -e "${GREEN}✓ cloud-init-webserver.yaml erstellt${NC}"
echo ""

# ==============================================
# 7. WEBSERVER STARTEN
# ==============================================
echo -e "${YELLOW}[7/8] Starte Webserver...${NC}"

WEB_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $WEB_SG_ID \
    --user-data file://cloud-init-webserver.yaml \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=nextcloud-webserver},{Key=Project,Value=M346-Nextcloud},{Key=Type,Value=Webserver}]" \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "  Instance ID: $WEB_INSTANCE_ID"
echo "  Warte bis Instanz läuft..."

aws ec2 wait instance-running --instance-ids $WEB_INSTANCE_ID --region $REGION

# Public IP abrufen
WEB_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $WEB_INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo -e "${GREEN}✓ Webserver gestartet${NC}"
echo "  Public IP: $WEB_PUBLIC_IP"
echo ""

# ==============================================
# WARTE BIS WEBSERVER BEREIT IST
# ==============================================
echo -e "${YELLOW}Warte bis Webserver vollständig bereit ist...${NC}"
echo "Dies kann 3-5 Minuten dauern..."
echo ""

MAX_WAIT=300  # 5 Minuten
ELAPSED=0
DOTS=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$WEB_PUBLIC_IP 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        echo ""
        echo -e "${GREEN}✓ Webserver ist bereit!${NC}"
        break
    fi
    
    echo -n "."
    DOTS=$((DOTS + 1))
    
    if [ $((DOTS % 50)) -eq 0 ]; then
        echo " ${ELAPSED}s"
    fi
    
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

echo ""

if [ $ELAPSED -ge $MAX_WAIT ]; then
    echo -e "${RED}⚠️  Timeout - Webserver antwortet nicht nach 5 Minuten${NC}"
    echo "Prüfe manuell mit: aws ec2 get-console-output --instance-id $WEB_INSTANCE_ID --region us-east-1"
    echo ""
fi

# ==============================================
# 8. DEPLOYMENT-INFO SPEICHERN
# ==============================================
echo -e "${YELLOW}[8/8] Speichere Deployment-Informationen...${NC}"

cat > deployment-info.json << EOF
{
  "deployment_date": "$(date -u +"%Y-%m-%d %H:%M:%S UTC")",
  "region": "$REGION",
  "nextcloud_version": "$NEXTCLOUD_VERSION",
  "database": {
    "instance_id": "$DB_INSTANCE_ID",
    "private_ip": "$DB_PRIVATE_IP",
    "security_group_id": "$DB_SG_ID",
    "database_name": "nextcloud",
    "database_user": "nextcloud",
    "database_password": "$DB_NC_PASSWORD",
    "root_password": "$DB_ROOT_PASSWORD"
  },
  "webserver": {
    "instance_id": "$WEB_INSTANCE_ID",
    "public_ip": "$WEB_PUBLIC_IP",
    "security_group_id": "$WEB_SG_ID",
    "url": "http://$WEB_PUBLIC_IP"
  }
}
EOF

echo -e "${GREEN}✓ Informationen gespeichert in: deployment-info.json${NC}"
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
echo -e "${YELLOW}⏳ WICHTIG:${NC}"
echo "  • Warte 2-3 Minuten bis Setup komplett abgeschlossen ist"
echo "  • Öffne dann die URL im Browser"
echo "  • Der Nextcloud Setup-Assistent wird angezeigt"
echo ""
echo -e "${BLUE}🔐 DATENBANK-ZUGANGSDATEN FÜR SETUP:${NC}"
echo "  ┌─────────────────────────────────────────────┐"
echo "  │ Datenbank-Typ: MySQL/MariaDB                │"
echo "  │ Datenbank-Host: $DB_PRIVATE_IP        │"
echo "  │ Datenbank-Name: nextcloud                   │"
echo "  │ Datenbank-User: nextcloud                   │"
echo "  │ Datenbank-Passwort: $DB_NC_PASSWORD │"
echo "  │ Datenverzeichnis: /var/nextcloud-data       │"
echo "  └─────────────────────────────────────────────┘"
echo ""
echo -e "${BLUE}📝 WEITERE INFOS:${NC}"
echo "  • Deployment-Details: deployment-info.json"
echo "  • Cloud-Init DB: cloud-init-database.yaml"
echo "  • Cloud-Init Web: cloud-init-webserver.yaml"
echo ""
echo -e "${BLUE}🔍 STATUS PRÜFEN:${NC}"
echo "  aws ec2 get-console-output --instance-id $WEB_INSTANCE_ID --region $REGION"
echo ""
echo -e "${GREEN}========================================${NC}"