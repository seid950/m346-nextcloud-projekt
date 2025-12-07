#!/bin/bash
set -e

# ==============================================
# AWS Nextcloud Deployment Script - Modul 346
# Team: Seid Veseli, Amar Ibraimi, Leandro Graf
# ==============================================

# Konfiguration
REGION="us-east-1"
AMI_ID="ami-03deb8c961063af8c"  # Ubuntu 22.04 LTS
INSTANCE_TYPE="t2.micro"
KEY_NAME="vockey"

# Sichere Passwörter generieren (24 Zeichen)
DB_ROOT_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-24)
DB_NC_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-24)

echo "=== Starting Nextcloud Deployment ==="
echo "Generated DB Root Password: $DB_ROOT_PASSWORD"
echo "Generated DB User Password: $DB_NC_PASSWORD"
echo ""

# Alte Ressourcen aufräumen
echo "Cleaning up old resources..."

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

WEB_SG_ID=$(aws ec2 create-security-group \
    --group-name nextcloud-web-sg \
    --description "Nextcloud Web Server" \
    --region $REGION \
    --query 'GroupId' \
    --output text)

echo "DB Security Group: $DB_SG_ID"
echo "Web Security Group: $WEB_SG_ID"

# Security Group Rules
echo "Adding Security Group Rules..."

aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 3306 --source-group $WEB_SG_ID --region $REGION
aws ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION

# ==============================================
# Datenbank Server User Data
# ==============================================
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

echo "Launching Database Server..."
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

echo "Database Instance ID: $DB_INSTANCE_ID"
echo "Waiting for database server to start..."

aws ec2 wait instance-running --instance-ids $DB_INSTANCE_ID --region $REGION

DB_PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids $DB_INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text)

echo "Database Private IP: $DB_PRIVATE_IP"
echo "Waiting 120 seconds for database setup to complete..."
sleep 120

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

echo "Launching Web Server..."
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

echo "Web Instance ID: $WEB_INSTANCE_ID"
echo "Waiting for web server to start..."

aws ec2 wait instance-running --instance-ids $WEB_INSTANCE_ID --region $REGION

WEB_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $WEB_INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

# ==============================================
# DEPLOYMENT INFO SPEICHERN
# ==============================================
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
echo "  Datenverzeichnis: /var/nextcloud-data"
echo ""
echo "Alle Details gespeichert in: deployment-info.json"
echo "Cloud-Init Dateien: cloud-init-database.yaml, cloud-init-webserver.yaml"
echo ""
echo "================================================"

rm -f db-userdata.sh web-userdata.sh