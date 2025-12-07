# Installation Webserver

## Übersicht

Der Webserver hostet die Nextcloud-Applikation und wird vollautomatisch über Cloud-Init konfiguriert.

## Cloud-Init Konfiguration

Die Datei `cloud-init-webserver.yaml` wird automatisch vom deploy.sh Script generiert und enthält alle Installationsschritte.

### Package Installation
```yaml
packages:
  - apache2              # Webserver
  - libapache2-mod-php   # PHP-Modul für Apache
  - php                  # PHP 8.1
  - php-mysql            # MySQL/MariaDB Extension
  - php-zip              # ZIP-Unterstützung
  - php-xml              # XML-Parsing
  - php-mbstring         # Multibyte String
  - php-gd               # Bildbearbeitung
  - php-curl             # HTTP-Requests
  - php-imagick          # Erweiterte Bildbearbeitung
  - php-intl             # Internationalisierung
  - php-bcmath           # Mathematik
  - php-gmp              # Große Zahlen
  - wget                 # Download-Tool
  - bzip2                # Entpack-Tool
  - unzip                # ZIP-Unterstützung
```

## Installationsschritte

### 1. Nextcloud Download
```bash
cd /tmp
wget -q https://download.nextcloud.com/server/releases/nextcloud-28.0.1.tar.bz2
tar -xjf nextcloud-28.0.1.tar.bz2
```

**Warum Version 28.0.1?**
- Stabile LTS-Version
- Gut getestet
- Bekannte Kompatibilität mit PHP 8.1

### 2. Installation nach /var/www/html
```bash
rm -rf /var/www/html/*
mv nextcloud/* /var/www/html/
mv nextcloud/.htaccess /var/www/html/
mv nextcloud/.user.ini /var/www/html/
```

**Wichtig:** Nextcloud wird direkt im Root-Verzeichnis installiert, damit die URL `http://IP/` direkt funktioniert (keine `/nextcloud` im Pfad).

### 3. Datenverzeichnis
```bash
mkdir -p /var/nextcloud-data
chown -R www-data:www-data /var/nextcloud-data/
chmod -R 755 /var/nextcloud-data/
```

**Warum außerhalb von /var/www/html?**
- Sicherheit: Daten nicht öffentlich zugänglich
- Best Practice von Nextcloud
- Einfacheres Backup-Management

### 4. Berechtigungen
```bash
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/
```

**www-data:** Standard-User für Apache auf Ubuntu

## Apache Konfiguration

### VirtualHost Setup
```apache
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
    
    ErrorLog ${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog ${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
```

**Wichtige Einstellungen:**
- `AllowOverride All` - Erlaubt .htaccess Regeln
- `Dav off` - WebDAV über Apache deaktiviert (Nextcloud macht das selbst)

### Apache Module
```bash
a2enmod rewrite      # URL-Rewriting für schöne URLs
a2enmod headers      # HTTP-Header Manipulation
a2enmod env          # Umgebungsvariablen
a2enmod dir          # Directory-Handling
a2enmod mime         # MIME-Types
a2enmod setenvif     # Conditional Env-Vars
```

## Datenbank-Verbindung

### Verbindungstest
```bash
mysql -h 172.31.30.69 -u nextcloud -p'PASSWORD' -e "SELECT 1;"
```

Dieser Test wird automatisch im Cloud-Init ausgeführt und zeigt:
- ✅ "Datenbankverbindung erfolgreich" wenn OK
- ❌ "Datenbankverbindung fehlgeschlagen" bei Fehler

## Installation überprüfen

Nach 3-4 Minuten sollte der Server bereit sein:
```bash
# Service Status
systemctl status apache2

# PHP Version
php -v

# Nextcloud Dateien
ls -la /var/www/html/

# Logs checken
tail -f /var/log/apache2/nextcloud_error.log
```

## Zugriff auf Nextcloud

**URL:** `http://PUBLIC_IP`

Der Setup-Assistent sollte automatisch erscheinen.