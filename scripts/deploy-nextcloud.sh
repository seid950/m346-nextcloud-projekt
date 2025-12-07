#!/bin/bash
set -e

# ==============================================
# Nextcloud Cloud Deployment Automation
# Modul 346 - GBS St.Gallen
# Team: Seid Veseli, Amar Ibraimi, Leandro Graf
# ==============================================

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Banner
clear
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║  ███╗   ██╗███████╗██╗  ██╗████████╗ ██████╗██╗      ██████╗ ██╗   ██╗██████╗ ║
║  ████╗  ██║██╔════╝╚██╗██╔╝╚══██╔══╝██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗║
║  ██╔██╗ ██║█████╗   ╚███╔╝    ██║   ██║     ██║     ██║   ██║██║   ██║██║  ██║║
║  ██║╚██╗██║██╔══╝   ██╔██╗    ██║   ██║     ██║     ██║   ██║██║   ██║██║  ██║║
║  ██║ ╚████║███████╗██╔╝ ██╗   ██║   ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝║
║  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ ║
║                                                                               ║
║            AUTOMATISCHES CLOUD DEPLOYMENT SYSTEM                              ║
║                  Infrastructure as Code                                       ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

EOF
echo -e "${NC}"

echo -e "${BOLD}${BLUE}Projekt:${NC}      Modul 346 - Cloudlösungen konzipieren und realisieren"
echo -e "${BOLD}${BLUE}Team:${NC}         Seid Veseli (Lead), Amar Ibraimi, Leandro Graf"
echo -e "${BOLD}${BLUE}Institution:${NC}  GBS St.Gallen - Gewerbliches Berufs- und Weiterbildungszentrum"
echo -e "${BOLD}${BLUE}Datum:${NC}        $(date '+%d.%m.%Y %H:%M:%S')"
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
echo ""

# Konfiguration
REGION="us-east-1"
AMI_ID="ami-03deb8c961063af8c"
INSTANCE_TYPE="t2.micro"
KEY_NAME="vockey"

# Sichere Passwörter generieren
echo -e "${YELLOW}🔐 Generiere sichere Passwörter...${NC}"
DB_ROOT_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-24)
DB_NC_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-24)
echo -e "${GREEN}   ✓ Root-Passwort generiert (24 Zeichen, alphanumerisch)${NC}"
echo -e "${GREEN}   ✓ Nextcloud-DB-Passwort generiert (24 Zeichen, alphanumerisch)${NC}"
echo ""

# Deployment-Konfiguration anzeigen
echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│${NC} ${BOLD}DEPLOYMENT-KONFIGURATION${NC}                                          ${CYAN}│${NC}"
echo -e "${CYAN}├─────────────────────────────────────────────────────────────────────┤${NC}"
echo -e "${CYAN}│${NC}  AWS Region:           ${GREEN}${REGION}${NC}                                   ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  Instance Type:        ${GREEN}${INSTANCE_TYPE}${NC}                                  ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  AMI ID:               ${GREEN}${AMI_ID}${NC}              ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  Key Pair:             ${GREEN}${KEY_NAME}${NC}                                    ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  Nextcloud Version:    ${GREEN}Latest Stable${NC}                             ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  Webserver:            ${GREEN}Apache 2.4 + PHP 8.1${NC}                       ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  Datenbank:            ${GREEN}MariaDB 10.6${NC}                               ${CYAN}│${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────┘${NC}"
echo ""

# Bestätigung
echo -e "${YELLOW}${BOLD}⚠️  ACHTUNG:${NC} Dieses Script wird folgende Aktionen ausführen:"
echo -e "   ${CYAN}•${NC} Alte Nextcloud-Instanzen terminieren"
echo -e "   ${CYAN}•${NC} Neue Security Groups erstellen"
echo -e "   ${CYAN}•${NC} 2 EC2-Instanzen starten (Database + Webserver)"
echo -e "   ${CYAN}•${NC} Nextcloud vollautomatisch installieren"
echo ""
echo -e -n "${BOLD}Deployment starten? [${GREEN}j${NC}${BOLD}/${RED}n${NC}${BOLD}]:${NC} "
read -r CONFIRM

if [[ ! "$CONFIRM" =~ ^[jJyY]$ ]]; then
    echo ""
    echo -e "${RED}✗ Deployment abgebrochen.${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}${BOLD}✓ Deployment bestätigt. Starte Prozess...${NC}"
echo ""
sleep 1

# Alte Ressourcen aufräumen
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}[PHASE 1/7]${NC} ${MAGENTA}CLEANUP ALTER RESSOURCEN${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

OLD_INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=nextcloud-*" "Name=instance-state-name,Values=running,pending,stopped" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text \
    --region $REGION 2>/dev/null || true)

if [ ! -z "$OLD_INSTANCES" ]; then
    echo -e "${YELLOW}   ⚙️  Gefundene Instanzen: ${OLD_INSTANCES}${NC}"
    echo -e "${YELLOW}   🗑️  Terminiere alte Instanzen...${NC}"
    aws ec2 terminate-instances --instance-ids $OLD_INSTANCES --region $REGION > /dev/null
    echo -e "${YELLOW}   ⏳ Warte auf Terminierung...${NC}"
    aws ec2 wait instance-terminated --instance-ids $OLD_INSTANCES --region $REGION 2>/dev/null || sleep 30
    echo -e "${GREEN}   ✓ Alte Instanzen erfolgreich entfernt${NC}"
else
    echo -e "${GREEN}   ✓ Keine alten Instanzen gefunden${NC}"
fi

echo -e "${YELLOW}   🗑️  Lösche alte Security Groups...${NC}"
aws ec2 delete-security-group --group-name nextcloud-web-sg --region $REGION 2>/dev/null && echo -e "${GREEN}   ✓ Web-SG gelöscht${NC}" || echo -e "${BLUE}   ℹ Web-SG nicht vorhanden${NC}"
aws ec2 delete-security-group --group-name nextcloud-db-sg --region $REGION 2>/dev/null && echo -e "${GREEN}   ✓ DB-SG gelöscht${NC}" || echo -e "${BLUE}   ℹ DB-SG nicht vorhanden${NC}"
sleep 5

echo -e "${GREEN}${BOLD}   ✓ CLEANUP ABGESCHLOSSEN${NC}"
echo ""

# Security Groups erstellen
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}[PHASE 2/7]${NC} ${MAGENTA}SECURITY GROUPS KONFIGURATION${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}   🛡️  Erstelle Security Groups...${NC}"

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

echo -e "${GREEN}   ✓ Database SG erstellt:  ${BOLD}${DB_SG_ID}${NC}"
echo -e "${GREEN}   ✓ Webserver SG erstellt: ${BOLD}${WEB_SG_ID}${NC}"
echo ""

echo -e "${YELLOW}   🔒 Konfiguriere Firewall-Regeln...${NC}"

aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $REGION > /dev/null
echo -e "${GREEN}   ✓ Webserver:  Port 80 (HTTP) offen für 0.0.0.0/0${NC}"

aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION > /dev/null
echo -e "${GREEN}   ✓ Webserver:  Port 22 (SSH) offen für 0.0.0.0/0${NC}"

aws ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 3306 --source-group $WEB_SG_ID --region $REGION > /dev/null
echo -e "${GREEN}   ✓ Database:   Port 3306 (MySQL) nur von Webserver-SG${NC}"

aws ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION > /dev/null
echo -e "${GREEN}   ✓ Database:   Port 22 (SSH) offen für 0.0.0.0/0${NC}"

echo ""
echo -e "${GREEN}${BOLD}   ✓ SECURITY GROUPS KONFIGURIERT${NC}"
echo ""

# ==============================================
# Cloud-Init Dateien erstellen
# ==============================================
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}[PHASE 3/7]${NC} ${MAGENTA}INFRASTRUCTURE AS CODE - GENERIERUNG${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}   📝 Erstelle User-Data Scripts...${NC}"
cat > db-userdata.sh << 'DBEOF'
#!/bin/bash
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting Database Server Setup ==="

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server

systemctl start mariadb
systemctl enable mariadb

mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'DBROOT_PASS';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "FLUSH PRIVILEGES;"

mysql -u root -pDBROOT_PASS << EOF
CREATE DATABASE nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'nextcloud'@'%' IDENTIFIED BY 'DBNC_PASS';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'%';
FLUSH PRIVILEGES;
EOF

sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb

PRIVATE_IP=$(hostname -I | awk '{print $1}')

cat > /root/db-info.txt << EOF
DB Host: $PRIVATE_IP
DB Name: nextcloud
DB User: nextcloud
DB Password: DBNC_PASS
Root Password: DBROOT_PASS
EOF

cat /root/db-info.txt
echo "=== Database Server Setup Complete ==="
DBEOF

sed -i "s/DBROOT_PASS/$DB_ROOT_PASSWORD/g" db-userdata.sh
sed -i "s/DBNC_PASS/$DB_NC_PASSWORD/g" db-userdata.sh

echo -e "${GREEN}   ✓ Database User-Data Script erstellt${NC}"

# Cloud-Init YAML für DB erstellen (für Git-Versionierung)
cat > cloud-init-database.yaml << EOF
#cloud-config
# Datenbank Server - User Data Script wird verwendet
# Dieses File dient nur der Dokumentation
write_files:
  - path: /root/setup-info.txt
    content: |
      Database setup via user-data script
      Root Password: ${DB_ROOT_PASSWORD}
      Nextcloud Password: ${DB_NC_PASSWORD}
EOF

echo -e "${GREEN}   ✓ cloud-init-database.yaml für Versionsverwaltung erstellt${NC}"
echo ""

echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}[PHASE 4/7]${NC} ${MAGENTA}DATABASE SERVER DEPLOYMENT${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}   🚀 Starte Database Server Instanz...${NC}"
DB_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $DB_SG_ID \
    --user-data file://db-userdata.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nextcloud-db},{Key=Project,Value=M346-Nextcloud}]' \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo -e "${GREEN}   ✓ Instanz gestartet: ${BOLD}${DB_INSTANCE_ID}${NC}"
echo -e "${YELLOW}   ⏳ Warte bis Instanz läuft...${NC}"

aws ec2 wait instance-running --instance-ids $DB_INSTANCE_ID --region $REGION

DB_PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids $DB_INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text)

echo -e "${GREEN}   ✓ Instanz läuft${NC}"
echo -e "${GREEN}   ✓ Private IP: ${BOLD}${DB_PRIVATE_IP}${NC}"
echo ""
echo -e "${YELLOW}   ⏰ Warte 120 Sekunden für MariaDB Installation & Konfiguration...${NC}"

# Progress Bar
for i in {1..120}; do
    if [ $((i % 10)) -eq 0 ]; then
        echo -ne "${CYAN}   ▓${NC}"
    fi
    sleep 1
done
echo ""

echo -e "${GREEN}${BOLD}   ✓ DATABASE SERVER BEREIT${NC}"
echo ""

# ==============================================
# Web Server User Data
# ==============================================
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}[PHASE 5/7]${NC} ${MAGENTA}WEBSERVER DEPLOYMENT${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}   📝 Erstelle Webserver User-Data...${NC}"
cat > web-userdata.sh << 'WEBEOF'
#!/bin/bash
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting Web Server Setup ==="

DB_HOST="DB_PRIVATE_IP_PLACEHOLDER"
DB_PASSWORD="DBNC_PASS"

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apache2 libapache2-mod-php \
    php php-mysql php-zip php-xml php-mbstring php-gd \
    php-curl php-imagick php-intl php-bcmath php-gmp \
    wget bzip2

cd /tmp
wget -q https://download.nextcloud.com/server/releases/latest.tar.bz2
tar -xjf latest.tar.bz2

rm -rf /var/www/html/*
mv nextcloud/* /var/www/html/
rm -rf /tmp/nextcloud /tmp/latest.tar.bz2

mkdir -p /var/nextcloud-data

chown -R www-data:www-data /var/www/html/
chown -R www-data:www-data /var/nextcloud-data/
chmod -R 755 /var/www/html/

cat > /etc/apache2/sites-available/000-default.conf << 'APACHECONF'
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
</VirtualHost>
APACHECONF

a2enmod rewrite headers env dir mime setenvif
systemctl restart apache2

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

cat > /root/nextcloud-info.txt << EOF
Nextcloud URL: http://$PUBLIC_IP

Setup-Assistent Datenbank-Eingaben:
  Datenbank-Benutzer: nextcloud
  Datenbank-Passwort: $DB_PASSWORD
  Datenbank-Name: nextcloud
  Datenbank-Host: $DB_HOST
  Datenverzeichnis: /var/nextcloud-data
EOF

cat /root/nextcloud-info.txt
echo "=== Web Server Setup Complete ==="
WEBEOF

sed -i "s/DB_PRIVATE_IP_PLACEHOLDER/$DB_PRIVATE_IP/g" web-userdata.sh
sed -i "s/DBNC_PASS/$DB_NC_PASSWORD/g" web-userdata.sh

echo -e "${GREEN}   ✓ Webserver User-Data Script erstellt${NC}"

# Cloud-Init YAML für Web erstellen (für Git-Versionierung)
cat > cloud-init-webserver.yaml << EOF
#cloud-config
# Webserver - User Data Script wird verwendet
# Dieses File dient nur der Dokumentation
write_files:
  - path: /root/setup-info.txt
    content: |
      Webserver setup via user-data script
      DB Host: ${DB_PRIVATE_IP}
      DB Password: ${DB_NC_PASSWORD}
EOF

echo -e "${GREEN}   ✓ cloud-init-webserver.yaml für Versionsverwaltung erstellt${NC}"
echo ""
echo -e "${YELLOW}   🚀 Starte Webserver Instanz...${NC}"
WEB_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $WEB_SG_ID \
    --user-data file://web-userdata.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nextcloud-web},{Key=Project,Value=M346-Nextcloud}]' \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo -e "${GREEN}   ✓ Instanz gestartet: ${BOLD}${WEB_INSTANCE_ID}${NC}"
echo -e "${YELLOW}   ⏳ Warte bis Instanz läuft...${NC}"

aws ec2 wait instance-running --instance-ids $WEB_INSTANCE_ID --region $REGION

WEB_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $WEB_INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo -e "${GREEN}   ✓ Instanz läuft${NC}"
echo -e "${GREEN}   ✓ Public IP: ${BOLD}${WEB_PUBLIC_IP}${NC}"
echo ""
echo -e "${GREEN}${BOLD}   ✓ WEBSERVER BEREIT${NC}"
echo ""

# ==============================================
# DEPLOYMENT INFO SPEICHERN
# ==============================================
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}[PHASE 6/7]${NC} ${MAGENTA}DEPLOYMENT-DOKUMENTATION${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}   💾 Speichere Deployment-Informationen...${NC}"
cat > deployment-info.json << EOF
{
  "deployment_date": "$(date -u +"%Y-%m-%d %H:%M:%S UTC")",
  "team": ["Seid Veseli", "Amar Ibraimi", "Leandro Graf"],
  "region": "$REGION",
  "ami_id": "$AMI_ID",
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

echo -e "${GREEN}   ✓ deployment-info.json erstellt${NC}"
echo -e "${GREEN}   ✓ cloud-init-database.yaml gespeichert${NC}"
echo -e "${GREEN}   ✓ cloud-init-webserver.yaml gespeichert${NC}"
echo ""
echo -e "${GREEN}${BOLD}   ✓ DOKUMENTATION ABGESCHLOSSEN${NC}"
echo ""

rm -f db-userdata.sh web-userdata.sh

# ==============================================
# ERFOLGSAUSGABE
# ==============================================
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}[PHASE 7/7]${NC} ${GREEN}DEPLOYMENT ERFOLGREICH ABGESCHLOSSEN${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${GREEN}"
cat << "EOF"
    ██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗   ██╗███████╗██████╗ 
    ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝██╔════╝██╔══██╗
    ██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚████╔╝ █████╗  ██║  ██║
    ██║  ██║██╔══╝  ██╔═══╝ ██║     ██║   ██║  ╚██╔╝  ██╔══╝  ██║  ██║
    ██████╔╝███████╗██║     ███████╗╚██████╔╝   ██║   ███████╗██████╔╝
    ╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝   ╚══════╝╚═════╝ 
EOF
echo -e "${NC}"

echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│${NC} ${BOLD}DEPLOYMENT ÜBERSICHT${NC}                                              ${CYAN}│${NC}"
echo -e "${CYAN}├─────────────────────────────────────────────────────────────────────┤${NC}"
echo -e "${CYAN}│${NC}                                                                     ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  ${BOLD}${BLUE}Database Server:${NC}                                               ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}    Instance ID:    ${GREEN}${DB_INSTANCE_ID}${NC}                ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}    Private IP:     ${GREEN}${DB_PRIVATE_IP}${NC}                          ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}    Security Group: ${GREEN}${DB_SG_ID}${NC}          ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}                                                                     ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  ${BOLD}${BLUE}Webserver:${NC}                                                     ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}    Instance ID:    ${GREEN}${WEB_INSTANCE_ID}${NC}                ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}    Public IP:      ${GREEN}${WEB_PUBLIC_IP}${NC}                           ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}    Security Group: ${GREEN}${WEB_SG_ID}${NC}          ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}                                                                     ${CYAN}│${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────┘${NC}"
echo ""

echo -e "${BOLD}${MAGENTA}🌐 NEXTCLOUD URL:${NC}"
echo -e "${GREEN}${BOLD}   ➜  http://${WEB_PUBLIC_IP}${NC}"
echo ""

echo -e "${YELLOW}⏰ ${BOLD}WICHTIG:${NC}"
echo -e "   • Warte ${YELLOW}2-3 Minuten${NC} bis Nextcloud komplett installiert ist"
echo -e "   • Öffne dann die URL im Browser"
echo -e "   • Der Setup-Assistent wird automatisch angezeigt"
echo ""

echo -e "${BOLD}${BLUE}🔐 DATENBANK-ZUGANGSDATEN FÜR SETUP-ASSISTENT:${NC}"
echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│${NC}  Datenbank-Typ:         ${GREEN}MySQL/MariaDB${NC}                          ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  Datenbank-Host:        ${GREEN}${DB_PRIVATE_IP}${NC}                       ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  Datenbank-Name:        ${GREEN}nextcloud${NC}                              ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  Datenbank-Benutzer:    ${GREEN}nextcloud${NC}                              ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  Datenbank-Passwort:    ${GREEN}${DB_NC_PASSWORD}${NC}    ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  Datenverzeichnis:      ${GREEN}/var/nextcloud-data${NC}                    ${CYAN}│${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────┘${NC}"
echo ""

echo -e "${BOLD}${BLUE}📝 INSTALLATION ABSCHLIESSEN:${NC}"
echo -e "   ${CYAN}1.${NC} Öffne: ${GREEN}http://${WEB_PUBLIC_IP}${NC}"
echo -e "   ${CYAN}2.${NC} Erstelle Admin-Account (Username + Passwort frei wählbar)"
echo -e "   ${CYAN}3.${NC} Trage obige Datenbank-Daten ein"
echo -e "   ${CYAN}4.${NC} Klicke ${GREEN}'Installation abschließen'${NC}"
echo ""

echo -e "${BOLD}${BLUE}📂 GENERIERTE DATEIEN:${NC}"
echo -e "   ${CYAN}•${NC} ${GREEN}deployment-info.json${NC}        - Alle Deployment-Details & Passwörter"
echo -e "   ${CYAN}•${NC} ${GREEN}cloud-init-database.yaml${NC}    - Database Server Konfiguration"
echo -e "   ${CYAN}•${NC} ${GREEN}cloud-init-webserver.yaml${NC}   - Webserver Konfiguration"
echo ""

echo -e "${BOLD}${BLUE}🔍 LOGS PRÜFEN:${NC}"
echo -e "   ${CYAN}•${NC} Database: ${YELLOW}aws ec2 get-console-output --instance-id ${DB_INSTANCE_ID} --region ${REGION}${NC}"
echo -e "   ${CYAN}•${NC} Webserver: ${YELLOW}aws ec2 get-console-output --instance-id ${WEB_INSTANCE_ID} --region ${REGION}${NC}"
echo ""

echo -e "${BOLD}${BLUE}🗑️  CLEANUP:${NC}"
echo -e "   ${CYAN}•${NC} Zum Löschen: ${YELLOW}bash cleanup.sh${NC}"
echo ""

echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}✓ Deployment erfolgreich abgeschlossen um $(date '+%H:%M:%S')${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""