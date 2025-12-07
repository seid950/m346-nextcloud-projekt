# Installation Datenbank-Server

## Übersicht

Der Datenbank-Server läuft auf einer separaten EC2-Instanz und hostet MariaDB mit der Nextcloud-Datenbank.

## Cloud-Init Konfiguration

Die Datei `cloud-init-database.yaml` wird automatisch generiert und konfiguriert MariaDB vollständig.

### Package Installation
```yaml
packages:
  - mariadb-server   # Datenbank-Server
  - mariadb-client   # CLI-Tool für Administration
```

## MariaDB Installation

### 1. Root-Passwort setzen
```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'SECURE_PASSWORD';
FLUSH PRIVILEGES;
```

**Sicherheit:** Passwort wird automatisch generiert (24 Zeichen, alphanumerisch)

### 2. Nextcloud Datenbank erstellen
```sql
CREATE DATABASE IF NOT EXISTS nextcloud 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_general_ci;
```

**utf8mb4:** 
- Vollständige UTF-8 Unterstützung
- Emojis werden korrekt gespeichert
- Nextcloud-Empfehlung

### 3. Nextcloud User erstellen
```sql
CREATE USER IF NOT EXISTS 'nextcloud'@'%' 
IDENTIFIED BY 'SECURE_PASSWORD';

GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'%';
FLUSH PRIVILEGES;
```

**'%' bedeutet:** User kann sich von jedem Host verbinden (wichtig für Webserver-Zugriff)

## MariaDB Konfiguration

### Remote-Zugriff aktivieren

**Datei:** `/etc/mysql/mariadb.conf.d/60-nextcloud.cnf`
```ini
[mysqld]
# Remote-Zugriff erlauben
bind-address = 0.0.0.0

# Performance-Optimierungen
max_connections = 200
innodb_buffer_pool_size = 128M

# Zeichensatz
character_set_server = utf8mb4
collation_server = utf8mb4_general_ci
```

**bind-address = 0.0.0.0:**
- Standard: 127.0.0.1 (nur localhost)
- Geändert zu: 0.0.0.0 (alle Netzwerk-Interfaces)
- **WICHTIG:** Security Group schützt trotzdem (nur Webserver darf verbinden)

### Konfiguration anwenden
```bash
systemctl restart mariadb
systemctl enable mariadb
```

## Sicherheitskonzept

### 1. Netzwerk-Isolation

✅ **Keine Public IP:** Datenbank hat nur Private IP  
✅ **Security Group:** Port 3306 nur von Webserver-SG erreichbar  
✅ **AWS VPC:** Automatische Netzwerk-Isolation  

### 2. Authentifizierung

✅ **Sichere Passwörter:** 24 Zeichen, auto-generiert  
✅ **User-Isolation:** nextcloud-User hat nur Zugriff auf nextcloud DB  
✅ **Root-Schutz:** Root nur von localhost  

### 3. Daten-Sicherheit

✅ **utf8mb4:** Korrekte Zeichensatz-Behandlung  
✅ **InnoDB:** ACID-Transaktionen  
✅ **MariaDB Logs:** Alle Queries werden geloggt  

## Verbindung testen

### Von Webserver aus
```bash
# SSH auf Webserver
ssh -i vockey.pem ubuntu@PUBLIC_IP

# Datenbank-Verbindung testen
mysql -h 172.31.30.69 -u nextcloud -p

# Passwort eingeben, dann:
SHOW DATABASES;
USE nextcloud;
SHOW TABLES;
```

**Erwartete Ausgabe:**
```
+--------------------+
| Database           |
+--------------------+
| information_schema |
| nextcloud          |
+--------------------+
```

## Monitoring

### Status überprüfen
```bash
# Service Status
systemctl status mariadb

# Aktive Verbindungen
mysql -u root -p -e "SHOW PROCESSLIST;"

# Datenbank-Größe
mysql -u root -p -e "SELECT table_schema AS 'Database', 
ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' 
FROM information_schema.tables 
GROUP BY table_schema;"
```

### Logs
```bash
# Error Log
tail -f /var/log/mysql/error.log

# Slow Query Log (optional aktivieren)
tail -f /var/log/mysql/slow-query.log
```

## Backup-Strategie (Empfehlung)

Für Produktion sollte implementiert werden:
```bash
# Datenbank-Backup
mysqldump -u root -p nextcloud > nextcloud_backup_$(date +%Y%m%d).sql

# Backup komprimieren
gzip nextcloud_backup_*.sql

# Auf S3 hochladen (optional)
aws s3 cp nextcloud_backup_*.sql.gz s3://backup-bucket/
```

## Performance-Tuning

### Für größere Installationen:
```ini
[mysqld]
# Memory
innodb_buffer_pool_size = 512M  # 60-70% of available RAM
key_buffer_size = 128M

# Connections
max_connections = 500
thread_cache_size = 50

# Query Cache (optional)
query_cache_type = 1
query_cache_size = 64M
```