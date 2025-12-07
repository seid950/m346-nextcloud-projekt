# Nextcloud Cloud Deployment - Modul 346

Automatisierte Installation von Nextcloud auf AWS mit separaten Web- und Datenbankservern.

## 📋 Projektübersicht

Dieses Projekt erfüllt die Anforderungen des Modul 346 Projektauftrags:
- ✅ Nextcloud Community Edition (Archive-Installation)
- ✅ Separate Server für Webserver und Datenbank
- ✅ Infrastructure as Code (Cloud-Init)
- ✅ Vollautomatisierte Installation
- ✅ Kein Docker, kein Web Installer

## 👥 Team



## 🎯 Architektur

```
┌─────────────────────────────────────────────────────┐
│                    AWS Cloud                        │
│                                                     │
│  ┌──────────────────┐        ┌──────────────────┐ │
│  │  Web Server      │◄──────►│  DB Server       │ │
│  │                  │ Port   │                  │ │
│  │  - Apache 2.4    │ 3306   │  - MariaDB       │ │
│  │  - PHP 8.1       │        │  - nextcloud DB  │ │
│  │  - Nextcloud     │        │                  │ │
│  │    28.0.1        │        │                  │ │
│  └──────────────────┘        └──────────────────┘ │
│         │                                          │
│         │ Port 80                                  │
│         ▼                                          │
│  ┌──────────────────┐                             │
│  │  Internet        │                             │
│  │  (Public IP)     │                             │
│  └──────────────────┘                             │
└─────────────────────────────────────────────────────┘
```

## 🚀 Installation

### Voraussetzungen

1. **AWS Account** (AWS Academy Student Lab)
2. **AWS CLI** installiert
3. **Git Bash** (auf Windows) oder Bash Terminal
4. **SSH Key Pair** namens `vockey` in AWS Region `us-east-1`

### AWS CLI Installation (Windows)

```powershell
# Option 1: Mit winget
winget install Amazon.AWSCLI

# Option 2: Manuell
# Download von: https://awscli.amazonaws.com/AWSCLIV2.msi
```

### AWS Credentials einrichten

1. Starte dein AWS Academy Lab
2. Klicke auf "AWS Details" → "Show" bei AWS CLI credentials
3. Kopiere die drei Zeilen (access_key, secret_key, session_token)
4. Erstelle/Bearbeite `~/.aws/credentials`:

```ini
[default]
aws_access_key_id=DEINE_KEY_ID
aws_secret_access_key=DEIN_SECRET
aws_session_token=DEIN_TOKEN
```

5. Erstelle/Bearbeite `~/.aws/config`:

```ini
[default]
region=us-east-1
```

6. Teste die Verbindung:

```bash
aws sts get-caller-identity
```

### Deployment ausführen

```bash
# Repository klonen
git clone <dein-repo-url>
cd <repo-ordner>

# Deploy-Script ausführbar machen
chmod +x deploy.sh

# Deployment starten
bash deploy.sh
```

**Dauer:** ~3-4 Minuten bis alles bereit ist.

### Was das Script macht

1. ✅ Überprüft AWS CLI Konfiguration
2. ✅ Räumt alte Ressourcen auf
3. ✅ Erstellt Security Groups mit korrekten Firewall-Regeln
4. ✅ Generiert sichere Cloud-Init Konfigurationen
5. ✅ Startet Datenbank-Server mit MariaDB
6. ✅ Wartet bis Datenbank bereit ist
7. ✅ Startet Webserver mit Apache + PHP + Nextcloud
8. ✅ Gibt alle Zugangsdaten aus

## 📝 Nextcloud Setup

Nach dem Deployment (warte 2-3 Minuten):

### 1. Browser öffnen

```
http://<PUBLIC_IP>
```

Die URL wird am Ende des Deployments angezeigt.

### 2. Setup-Assistent ausfüllen

**Admin-Account erstellen:**
- Benutzername: `admin` (oder beliebig)
- Passwort: Sicheres Passwort wählen (mind. 8 Zeichen)

**Datenverzeichnis:**
```
/var/nextcloud-data
```

**Datenbank konfigurieren:**
- Datenbank-Typ: `MySQL/MariaDB`
- Datenbank-Host: `<DB_PRIVATE_IP>` (wird ausgegeben)
- Datenbank-Name: `nextcloud`
- Datenbank-Benutzer: `nextcloud`
- Datenbank-Passwort: `<wird ausgegeben>`

### 3. Installation abschließen

Klicke auf "Installation abschließen" und warte 1-2 Minuten.

## 🧪 Testing

### Test 1: Server-Erreichbarkeit

```bash
# Web Server HTTP-Zugriff testen
curl -I http://<PUBLIC_IP>

# Sollte "HTTP/1.1 200 OK" oder Redirect zurückgeben
```

### Test 2: Datenbank-Verbindung

```bash
# SSH auf Webserver
ssh -i vockey.pem ubuntu@<WEB_PUBLIC_IP>

# Datenbank-Verbindung testen
mysql -h <DB_PRIVATE_IP> -u nextcloud -p
# Passwort eingeben: <DB_NC_PASSWORD>

# SQL-Test
SHOW DATABASES;
USE nextcloud;
SHOW TABLES;
```

### Test 3: Nextcloud Funktionalität

1. ✅ Login mit Admin-Account
2. ✅ Datei hochladen
3. ✅ Ordner erstellen
4. ✅ Datei teilen
5. ✅ Benutzerverwaltung öffnen

## 📊 Deployment-Informationen

Alle Details werden in `deployment-info.json` gespeichert:

```json
{
  "deployment_date": "2024-12-07 15:30:00 UTC",
  "region": "us-east-1",
  "nextcloud_version": "28.0.1",
  "database": {
    "instance_id": "i-...",
    "private_ip": "172.31.x.x",
    "database_password": "..."
  },
  "webserver": {
    "instance_id": "i-...",
    "public_ip": "xx.xx.xx.xx",
    "url": "http://xx.xx.xx.xx"
  }
}
```

## 🗑️ Cleanup

Um alle Ressourcen zu löschen:

```bash
bash cleanup.sh
```

**Achtung:** Dies löscht permanent:
- Beide EC2-Instanzen
- Alle Security Groups
- Optional: Lokale Konfigurationsdateien

## 📁 Repository-Struktur

```
.
├── README.md                      # Diese Datei
├── deploy.sh                      # Hauptdeployment-Script
├── cleanup.sh                     # Cleanup-Script
├── cloud-init-database.yaml       # DB-Server Konfiguration (generiert)
├── cloud-init-webserver.yaml      # Webserver Konfiguration (generiert)
├── deployment-info.json           # Deployment-Details (generiert)
└── docs/
    ├── projektplanung.md          # Projektplanung und Aufgaben
    ├── tests.md                   # Test-Dokumentation mit Screenshots
    └── reflexion.md               # Persönliche Reflexionen
```

## 🔧 Troubleshooting

### Problem: "AWS CLI not found"

**Lösung:**
```bash
# AWS CLI installieren
winget install Amazon.AWSCLI

# Terminal neu starten
```

### Problem: "Could not connect to the endpoint URL"

**Lösung:**
```bash
# AWS Credentials neu setzen
aws configure

# Region: us-east-1
```

### Problem: "Nextcloud lädt nicht"

**Lösung:**
```bash
# Warte länger (bis zu 5 Minuten)

# Status prüfen
aws ec2 get-console-output --instance-id <WEB_INSTANCE_ID>

# In den Logs nach Fehlern suchen
```

### Problem: "Database connection failed"

**Lösung:**
```bash
# 1. Prüfe ob DB-Server läuft
aws ec2 describe-instances --instance-ids <DB_INSTANCE_ID>

# 2. Prüfe Security Group (Port 3306 offen?)
aws ec2 describe-security-groups --group-ids <DB_SG_ID>

# 3. SSH auf Web-Server und teste Verbindung
ssh -i vockey.pem ubuntu@<WEB_PUBLIC_IP>
mysql -h <DB_PRIVATE_IP> -u nextcloud -p
```

##  Sicherheitshinweise

- ✅ Passwörter werden automatisch generiert (24 Zeichen)
- ✅ Datenbank nur über interne IP erreichbar
- ✅ Security Groups mit minimal notwendigen Ports
- ⚠️ HTTP (nicht HTTPS) - für Produktion HTTPS einrichten!
- ⚠️ SSH von überall - in Produktion einschränken!

##  Quellen

- Nextcloud Dokumentation: https://docs.nextcloud.com
- AWS EC2 Dokumentation: https://docs.aws.amazon.com/ec2/
- Cloud-Init Dokumentation: https://cloudinit.readthedocs.io/
- MariaDB Dokumentation: https://mariadb.org/documentation/

##  Lizenz

Dieses Projekt ist für Bildungszwecke im Rahmen des Modul 346.

---

**Projekt Status:** ✅ Abgeschlossen  
**Letzte Aktualisierung:** Dezember 2024