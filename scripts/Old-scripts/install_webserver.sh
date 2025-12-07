#!/bin/bash
# install_webserver.sh
# Installiert Apache, PHP und Nextcloud auf einem Ubuntu-Server.
# Dieses Skript ist für die Projektarbeit Modul 346 gedacht.

set -e

echo "[1/6] System aktualisieren..."
sudo apt update

echo "[2/6] Apache Webserver installieren..."
sudo apt install -y apache2

echo "[3/6] PHP und benötigte Module installieren..."
sudo apt install -y \
  php \
  libapache2-mod-php \
  php-mysql \
  php-xml \
  php-gd \
  
  php-curl \
  php-zip \
  php-mbstring \
  php-intl

echo "[4/6] Nextcloud herunterladen und entpacken..."
cd /var/www
sudo apt install -y unzip
sudo wget https://download.nextcloud.com/server/releases/latest.zip -O nextcloud.zip
sudo unzip -q nextcloud.zip
sudo rm nextcloud.zip

echo "[5/6] Besitzrechte für Webserver setzen..."
sudo chown -R www-data:www-data nextcloud
sudo find nextcloud/ -type d -exec chmod 750 {} \;
sudo find nextcloud/ -type f -exec chmod 640 {} \;

echo "[6/6] Apache VirtualHost für Nextcloud konfigurieren..."
sudo bash -c 'cat > /etc/apache2/sites-available/nextcloud.conf << "EOF"
<VirtualHost *:80>
    ServerName _default_
    DocumentRoot /var/www/nextcloud
    <Directory /var/www/nextcloud>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog \${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
EOF'

sudo a2ensite nextcloud.conf
sudo a2dissite 000-default.conf || true
sudo a2enmod rewrite headers env dir mime
sudo systemctl reload apache2

echo "Installation Webserver abgeschlossen. Nextcloud sollte unter http://SERVER-IP erreichbar sein."
