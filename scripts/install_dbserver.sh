#!/bin/bash
# install_dbserver.sh
# Installiert MySQL und erstellt Datenbank + Benutzer für Nextcloud.

set -e

DB_NAME="nextcloud"
DB_USER="ncuser"
DB_PASS="Passwort123!"   # Hinweis: In der Doku erwähnen, dass dies Beispiel-Passwort ist.

echo "[1/4] System aktualisieren..."
sudo apt update

echo "[2/4] MySQL Server installieren..."
sudo apt install -y mysql-server

echo "[3/4] MySQL Grundkonfiguration (ohne Interaktivität)..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'RootPasswort123!';"
sudo mysql -uroot -pRootPasswort123! -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -uroot -pRootPasswort123! -e "DROP DATABASE IF EXISTS test;"
sudo mysql -uroot -pRootPasswort123! -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -uroot -pRootPasswort123! -e "FLUSH PRIVILEGES;"

echo "[4/4] Datenbank und Benutzer für Nextcloud anlegen..."
sudo mysql -uroot -pRootPasswort123! <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

echo "Installation DB-Server abgeschlossen."
echo "Datenbank:   ${DB_NAME}"
echo "Benutzer:    ${DB_USER}"
echo "Passwort:    ${DB_PASS}"
