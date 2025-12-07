#!/bin/bash
# output_db_credentials.sh
# Gibt die Verbindungsdaten für die Nextcloud-Datenbank aus.

DB_HOST="<PRIVATE-IP-ODER-HOSTNAME-DES-DB-SERVERS>"
DB_NAME="nextcloud"
DB_USER="ncuser"
DB_PASS="Passwort123!"

echo "DATABASE_HOST=${DB_HOST}"
echo "DATABASE_NAME=${DB_NAME}"
echo "DATABASE_USER=${DB_USER}"
echo "DATABASE_PASSWORD=${DB_PASS}"
