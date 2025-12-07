#!/bin/bash
set -e

# ==============================================
# AWS Nextcloud Deployment Script
# Erstellt automatisch Web- und DB-Server
# ==============================================

# Konfiguration
REGION="us-east-1"
AMI_ID="ami-03deb8c961063af8c"  # Ubuntu 22.04 LTS us-east-1
INSTANCE_TYPE="t2.micro"
KEY_NAME="vockey"

# Passwörter
DB_ROOT_PASSWORD="SecureRoot2024!"
DB_NC_PASSWORD="NextcloudDB2024!"

echo "=== Starting Nextcloud Deployment ==="

# Alte Ressourcen aufräumen
echo "Cleaning up old resources..."

# Alte Instanzen terminieren
OLD_INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=nextcloud-*" "Name=instance-state-name,Values=running,pending,stopped" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text \
    --region $REGION 2>/dev/null || true)

if [ ! -z "$OLD_INSTANCES" ]; then
    echo "Terminating old instances: $OLD_INSTANCES"
    aws ec2 terminate-instances --instance-ids $OLD_INSTANCES --region $REGION
    echo "Waiting for instances to terminate..."
    aws ec2 wait instance-terminated --instance-ids $OLD_INSTANCES --region $REGION 2>/dev/null || sleep 30
fi

# Alte Security Groups löschen
echo "Deleting old security groups..."
aws ec2 delete-security-group --group-name nextcloud-web-sg --region $REGION 2>/dev/null || true
aws ec2 delete-security-group --group-name nextcloud-db-sg --region $REGION 2>/dev/null || true
sleep 5

# Security Groups erstellen
echo "Creating Security Groups..."

DB_SG_ID=$(aws ec2 create-security-group \
    --group-name nextcloud-db-sg \
    --description "Nextcloud Database Server" \
    --region $REGION \
    --query 'GroupId' \
    --output text)

echo "DB Security Group: $DB_SG_ID"

WEB_SG_ID=$(aws ec2 create-security-group \
    --group-name nextcloud-web-sg \
    --description "Nextcloud Web Server" \
    --region $REGION \
    --query 'GroupId' \
    --output text)

echo "Web Security Group: $WEB_SG_ID"

# Security Group Rules
echo "Adding Security Group Rules..."

# Web: HTTP von überall
aws ec2 authorize-security-group-ingress \
    --group-id $WEB_SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region $REGION

# Web: SSH
aws ec2 authorize-security-group-ingress \
    --group-id $WEB_SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region $REGION

# DB: MySQL nur von Web Security Group
aws ec2 authorize-security-group-ingress \
    --group-id $DB_SG_ID \
    --protocol tcp \
    --port 3306 \
    --source-group $WEB_SG_ID \
    --region $REGION

# DB: SSH
aws ec2 authorize-security-group-ingress \
    --group-id $DB_SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region $REGION

# ==============================================
# Datenbank Server User Data
# ==============================================
cat > db-userdata.sh << 'DBEOF'
#!/bin/bash
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting Database Server Setup ==="

# Updates
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# MariaDB installieren
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server

# MariaDB starten
systemctl start mariadb
systemctl enable mariadb

# Root-Passwort setzen
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'DBROOT_PASS';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "FLUSH PRIVILEGES;"

# Nextcloud Datenbank erstellen
mysql -u root -pDBROOT_PASS << EOF
CREATE DATABASE nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'nextcloud'@'%' IDENTIFIED BY 'DBNC_PASS';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'%';
FLUSH PRIVILEGES;
EOF

# Remote-Zugriff erlauben
sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb

# IP abrufen
PRIVATE_IP=$(hostname -I | awk '{print $1}')

# Ausgabe speichern
cat > /root/db-info.txt << EOF
=== DATENBANK VERBINDUNGSDETAILS ===
DB Host (Private IP): $PRIVATE_IP
DB Name: nextcloud
DB User: nextcloud
DB Password: DBNC_PASS
Root Password: DBROOT_PASS
=====================================
EOF

cat /root/db-info.txt
echo "=== Database Server Setup Complete ==="
DBEOF

# Passwörter einfügen
sed -i "s/DBROOT_PASS/$DB_ROOT_PASSWORD/g" db-userdata.sh
sed -i "s/DBNC_PASS/$DB_NC_PASSWORD/g" db-userdata.sh

# Datenbank-Server starten
echo "Launching Database Server..."
DB_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $DB_SG_ID \
    --user-data file://db-userdata.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nextcloud-db}]' \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Database Instance ID: $DB_INSTANCE_ID"
echo "Waiting for database server to start..."

# Auf Running Status warten
aws ec2 wait instance-running --instance-ids $DB_INSTANCE_ID --region $REGION

# Private IP abrufen
DB_PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids $DB_INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text)

echo "Database Private IP: $DB_PRIVATE_IP"
echo "Waiting 90 seconds for database setup to complete..."
sleep 90

# ==============================================
# Web Server User Data
# ==============================================
cat > web-userdata.sh << 'WEBEOF'
#!/bin/bash
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting Web Server Setup ==="

DB_HOST="DB_PRIVATE_IP_PLACEHOLDER"
DB_PASSWORD="DBNC_PASS"

# Updates
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Apache & PHP installieren
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apache2 \
    libapache2-mod-php \
    php php-mysql php-zip php-xml php-mbstring php-gd \
    php-curl php-imagick php-intl php-bcmath php-gmp \
    wget bzip2

# Nextcloud herunterladen (Archive)
cd /tmp
wget -q https://download.nextcloud.com/server/releases/latest.tar.bz2
tar -xjf latest.tar.bz2

# Nach /var/www/html verschieben
rm -rf /var/www/html/*
mv nextcloud/* /var/www/html/
rm -rf /tmp/nextcloud /tmp/latest.tar.bz2

# Datenverzeichnis erstellen
mkdir -p /var/nextcloud-data

# Berechtigungen
chown -R www-data:www-data /var/www/html/
chown -R www-data:www-data /var/nextcloud-data/
chmod -R 755 /var/www/html/

# Apache Konfiguration (Root-Verzeichnis!)
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

# Apache Module aktivieren
a2enmod rewrite headers env dir mime setenvif
systemctl restart apache2

# Public IP abrufen
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Verbindungsinfos ausgeben
cat > /root/nextcloud-info.txt << EOF
================================================
    NEXTCLOUD INSTALLATION BEREIT
================================================

Nextcloud URL: http://$PUBLIC_IP

WICHTIG: Beim Setup-Assistenten eingeben:

Admin Account:
  - Benutzername: admin (frei wählbar)
  - Passwort: (frei wählbar - mind. 8 Zeichen)

Datenverzeichnis:
  /var/nextcloud-data

Datenbank konfigurieren (MySQL/MariaDB wählen):
  - Datenbank-Benutzer: nextcloud
  - Datenbank-Passwort: $DB_PASSWORD
  - Datenbank-Name: nextcloud
  - Datenbank-Host: $DB_HOST

================================================
EOF

cat /root/nextcloud-info.txt
echo "=== Web Server Setup Complete ==="
WEBEOF

# DB IP und Passwort einfügen
sed -i "s/DB_PRIVATE_IP_PLACEHOLDER/$DB_PRIVATE_IP/g" web-userdata.sh
sed -i "s/DBNC_PASS/$DB_NC_PASSWORD/g" web-userdata.sh

# Web-Server starten
echo "Launching Web Server..."
WEB_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $WEB_SG_ID \
    --user-data file://web-userdata.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nextcloud-web}]' \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Web Instance ID: $WEB_INSTANCE_ID"
echo "Waiting for web server to start..."

aws ec2 wait instance-running --instance-ids $WEB_INSTANCE_ID --region $REGION

# Public IP abrufen
WEB_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $WEB_INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo ""
echo "================================================"
echo "    DEPLOYMENT ERFOLGREICH"
echo "================================================"
echo ""
echo "Database Server:"
echo "  Instance ID: $DB_INSTANCE_ID"
echo "  Private IP: $DB_PRIVATE_IP"
echo ""
echo "Web Server:"
echo "  Instance ID: $WEB_INSTANCE_ID"
echo "  Public IP: $WEB_PUBLIC_IP"
echo ""
echo "NEXTCLOUD URL: http://$WEB_PUBLIC_IP"
echo ""
echo "Warte 2-3 Minuten bis Setup abgeschlossen ist,"
echo "dann Browser öffnen und Installationsassistent aufrufen."
echo ""
echo "Datenbank-Verbindungsdetails für den Assistenten:"
echo "  Datenbank-Typ: MySQL/MariaDB"
echo "  Datenbank-Host: $DB_PRIVATE_IP"
echo "  Datenbank-Name: nextcloud"
echo "  Datenbank-User: nextcloud"
echo "  Datenbank-Password: $DB_NC_PASSWORD"
echo ""
echo "================================================"

# Cleanup temporäre Dateien
rm -f db-userdata.sh web-userdata.sh
