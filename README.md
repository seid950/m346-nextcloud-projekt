# Nextcloud Cloud Deployment - AWS Automatisierung

Vollautomatische Nextcloud-Installation auf AWS mit zwei separaten EC2-Instanzen (Webserver + Datenbank).

**Projekt:** Modul 346 - Cloudlösungen konzipieren und realisieren  
**Team:** Seid Veseli, Amar Ibraimi, Leandro Graf  
**Institution:** GBS St.Gallen

---

## Inhaltsverzeichnis

- [Quick Start](#quick-start)
- [Voraussetzungen](#voraussetzungen)
- [Installation](#installation)
- [Nextcloud konfigurieren](#nextcloud-konfigurieren)
- [Ressourcen löschen](#ressourcen-löschen)
- [Troubleshooting](#troubleshooting)
- [Nützliche Befehle](#nützliche-befehle)

---

## Quick Start

```bash
# 1. Repository klonen
git clone https://github.com/seid950/m346-nextcloud-projekt.git
cd m346-nextcloud-projekt

# 2. Deployment starten
bash scripts/deploy.sh

# 3. Mit 'j' bestätigen und warten (~4 Minuten)

# 4. Nextcloud-URL im Browser öffnen (wird angezeigt)

# 5. Setup-Assistent ausfüllen mit angezeigten Datenbank-Daten

# 6. Fertig! Nextcloud läuft.
```

---

## Voraussetzungen

### AWS Account

- ✅ **AWS Academy Learner Lab** gestartet
- ✅ **AWS CLI** installiert und konfiguriert
- ✅ **Key Pair** `vockey` verfügbar

**AWS CLI testen:**
```bash
aws --version
# Sollte zeigen: aws-cli/2.x.x oder höher
```

**AWS Credentials prüfen:**
```bash
aws sts get-caller-identity
# Sollte deine AWS Account-Info zeigen
```

### Lokale Umgebung

- ✅ **Bash-Shell** (Linux, macOS, oder WSL unter Windows)
- ✅ **Git** installiert
- ✅ **Internet-Verbindung**

**Git testen:**
```bash
git --version
# Sollte zeigen: git version 2.x.x oder höher
```

---

## Installation

### Schritt 1: Repository klonen

```bash
# Repository herunterladen
git clone https://github.com/seid950/m346-nextcloud-projekt.git

# In Projekt-Verzeichnis wechseln
cd m346-nextcloud-projekt

# Inhalt prüfen
ls -la
# Sollte zeigen: README.md, DOKUMENTATION.md, scripts/
```

### Schritt 2: AWS Learner Lab starten

1. **In AWS Academy einloggen**
2. **Learner Lab öffnen**
3. **"Start Lab" klicken**
4. **Warten bis Status "ready" (grün)**
5. **AWS CLI Credentials kopieren:**
   - Klicke auf "AWS Details"
   - Kopiere die Credentials
   - Füge sie in `~/.aws/credentials` ein

**Credentials testen:**
```bash
aws ec2 describe-regions --region us-east-1
# Sollte Liste von AWS Regionen zeigen
```

### Schritt 3: Deployment ausführen

```bash
# Deployment-Script starten
bash scripts/deploy.sh
```

**Was passiert jetzt:**

1. **Konfiguration anzeigen:**
   ```
   +-----------------------------------------------------------------------+
   | DEPLOYMENT-KONFIGURATION                                              |
   +-----------------------------------------------------------------------+
   |  AWS Region:           us-east-1                                      |
   |  Instance Type:        t2.micro                                       |
   |  AMI ID:               ami-03deb8c961063af8c                          |
   |  Key Pair:             vockey                                         |
   |  Nextcloud Version:    Latest Stable                                  |
   |  Webserver:            Apache 2.4 + PHP 8.1                           |
   |  Datenbank:            MariaDB 10.6                                   |
   +-----------------------------------------------------------------------+
   ```

2. **Bestätigung:**
   ```
   Deployment starten? [j/n]:
   ```
   → Tippe `j` und drücke Enter

3. **Deployment läuft (ca. 4 Minuten):**
   - Phase 1/7: Cleanup alter Ressourcen
   - Phase 2/7: Security Groups erstellen
   - Phase 3/7: User-Data Scripts generieren
   - Phase 4/7: Database Server deployen (+ 120s Wartezeit)
   - Phase 5/7: Webserver deployen
   - Phase 6/7: Deployment-Info speichern
   - Phase 7/7: Informationen ausgeben

4. **Erfolgsmeldung:**
   ```
   +=========================================================================+
   |                                                                         |
   |                       NEXTCLOUD INSTALLATION                            |
   |                                                                         |
   |                          http://XX.XX.XX.XX                             |
   |                                                                         |
   +=========================================================================+
   ```

**WICHTIG:** Kopiere die URL und die Datenbank-Zugangsdaten!

### Schritt 4: Warten

**Nach dem Deployment:**
- ⏱️ Warte **2-3 Minuten** bis Nextcloud vollständig installiert ist
- Der Webserver muss Apache starten, PHP konfigurieren und Nextcloud entpacken
- Die Datenbank muss MariaDB initialisieren

**Testen ob bereit:**
```bash
# In Browser öffnen oder curl testen:
curl http://XX.XX.XX.XX

# Wenn du HTML-Code siehst → Nextcloud ist bereit!
```

---

## Nextcloud konfigurieren

### Schritt 1: Nextcloud-URL öffnen

1. **Browser öffnen** (Chrome, Firefox, Safari, etc.)
2. **URL eingeben:** `http://XX.XX.XX.XX` (aus Terminal kopieren)
3. **Enter drücken**

**Was du siehst:**
- Nextcloud Setup-Assistent
- Felder für Admin-Account
- Felder für Datenbank-Verbindung

### Schritt 2: Admin-Account erstellen

**Im oberen Teil des Setup-Assistenten:**

```
Benutzername:  admin              ← Frei wählbar
Passwort:      DeinPasswort123!   ← Frei wählbar (min. 8 Zeichen)
```

**Empfehlung:** Sichere Passwörter verwenden!

### Schritt 3: Datenbank-Verbindung konfigurieren

**Kopiere die Daten aus dem Terminal:**

Das Deployment-Script zeigt diese Box:

```
+-----------------------------------------------------------------------+
| DATENBANK-ZUGANGSDATEN FUER SETUP-ASSISTENT:                          |
+-----------------------------------------------------------------------+
|   Datenbank-Typ:         MySQL/MariaDB                                |
|   Datenbank-Host:        172.31.XX.XX                                 |
|   Datenbank-Name:        nextcloud                                    |
|   Datenbank-Benutzer:    nextcloud                                    |
|   Datenbank-Passwort:    XXXXXXXXXXXXXXXXXXXXXXXX                     |
|   Datenverzeichnis:      /var/nextcloud-data                          |
+-----------------------------------------------------------------------+
```

**Im Setup-Assistenten eintragen:**

1. **Datenbank-Typ:** `MySQL/MariaDB` auswählen
2. **Datenbank-Benutzer:** `nextcloud`
3. **Datenbank-Passwort:** `[Das lange Passwort aus Terminal kopieren!]`
4. **Datenbank-Name:** `nextcloud`
5. **Datenbank-Host:** `172.31.XX.XX` (Private IP aus Terminal)
6. **Datenverzeichnis:** `/var/nextcloud-data`

**WICHTIG:** 
- ⚠️ Das Datenbank-Passwort ist LANG (24 Zeichen) - kopiere es genau!
- ⚠️ Verwende die **Private IP** (172.31.x.x), nicht die Public IP!

### Schritt 4: Installation abschließen

1. **Button klicken:** "Installation abschließen"
2. **Warten:** 30-60 Sekunden
3. **Fertig!** Nextcloud Dashboard erscheint

**Was du jetzt siehst:**
- Nextcloud Dashboard
- Dateien-App
- Willkommens-Dialog (kann geschlossen werden)

---

## Ressourcen löschen

**WICHTIG:** Vergiss nicht, die AWS-Ressourcen zu löschen wenn du fertig bist!

### Cleanup-Script ausführen

```bash
# In Projekt-Verzeichnis
cd m346-nextcloud-projekt

# Cleanup starten
bash scripts/cleanup.sh
```

**Was passiert:**

1. **Ressourcen anzeigen:**
   ```
   +-----------------------------------------------------------------------+
   | ZU LOESCHENDE RESSOURCEN                                              |
   +-----------------------------------------------------------------------+
   |   Database Instance:   i-0a1b2c3d4e5f6g7h8                            |
   |   Webserver Instance:  i-9h8g7f6e5d4c3b2a1                            |
   |   Database SG:          sg-1234567890abcdef0                          |
   |   Webserver SG:         sg-0fedcba0987654321                          |
   +-----------------------------------------------------------------------+
   ```

2. **Bestätigung:**
   ```
   Fortfahren mit dem Loeschen? [ja/nein]:
   ```
   → Tippe `ja` und drücke Enter

3. **Löschen (ca. 1 Minute):**
   - EC2-Instanzen terminieren
   - Security Groups löschen
   - Bestätigung ausgeben

4. **Fertig:**
   ```
   +-----------------------------------------------------------------------+
   | GELOESCHTE RESSOURCEN                                                 |
   +-----------------------------------------------------------------------+
   |   Database Instance terminiert                                        |
   |   Webserver Instance terminiert                                       |
   |   Database Security Group geloescht                                   |
   |   Webserver Security Group geloescht                                  |
   +-----------------------------------------------------------------------+
   ```

**Optional:** Lokale Dateien löschen
- Wenn gefragt, kannst du auch die generierten lokalen Dateien löschen:
  - `deployment-info.json`
  - `cloud-init-database.yaml`
  - `cloud-init-webserver.yaml`

---

## Troubleshooting

### Problem 1: "AWS CLI not found"

**Fehlermeldung:**
```
bash: aws: command not found
```

**Lösung:**
```bash
# AWS CLI installieren
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Prüfen
aws --version
```

### Problem 2: "Deployment starten?" erscheint nicht

**Fehlermeldung:**
```
Script läuft nicht / bricht sofort ab
```

**Lösung:**
```bash
# Prüfe ob Script ausführbar ist
ls -la scripts/deploy.sh

# Wenn nicht ausführbar:
chmod +x scripts/deploy.sh

# Nochmal versuchen
bash scripts/deploy.sh
```

### Problem 3: Nextcloud Setup-Assistent erscheint nicht

**Problem:** Browser zeigt "Site can't be reached" oder lädt endlos

**Lösung 1:** Warte länger
```bash
# Es kann 2-3 Minuten dauern!
# Teste mit curl:
curl http://XX.XX.XX.XX

# Wenn "curl: (7) Failed to connect" → noch warten
# Wenn HTML-Code → bereit!
```

**Lösung 2:** Logs prüfen
```bash
# Webserver-Logs ansehen
aws ec2 get-console-output --instance-id i-XXXXXXXXX --region us-east-1

# Suche nach Fehlern
```

### Problem 4: Datenbank-Verbindung fehlgeschlagen

**Fehlermeldung im Setup:** "Can't connect to MySQL server"

**Häufige Ursachen:**

1. **Falsche Private IP verwendet**
   - ✅ Verwende `172.31.XX.XX` (aus Terminal)
   - ❌ NICHT die Public IP des DB-Servers verwenden!

2. **Falsches Passwort**
   - Das Passwort ist 24 Zeichen lang
   - Kopiere es EXAKT aus dem Terminal
   - Keine Leerzeichen am Anfang/Ende!

3. **Datenbank noch nicht bereit**
   - Warte 2-3 Minuten nach Deployment
   - Database Server braucht Zeit für MariaDB-Installation

**Lösung:**
```bash
# Prüfe ob Database Server läuft
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=nextcloud-db" \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].State.Name'

# Sollte zeigen: "running"
```

### Problem 5: Setup sagt "Data directory is not writable"

**Problem:** Berechtigungsfehler beim Datenverzeichnis

**Lösung:**
```bash
# SSH zum Webserver
ssh -i vockey.pem ubuntu@XX.XX.XX.XX

# Berechtigungen prüfen
ls -ld /var/nextcloud-data/

# Sollte zeigen: drwxr-xr-x www-data www-data

# Falls falsch, korrigieren:
sudo chown -R www-data:www-data /var/nextcloud-data/
sudo chmod 755 /var/nextcloud-data/
```

### Problem 6: AWS Learner Lab Session abgelaufen

**Problem:** "An error occurred (AuthFailure)"

**Lösung:**
```bash
# 1. In AWS Academy: "Start Lab" klicken
# 2. Neue Credentials kopieren
# 3. In ~/.aws/credentials einfügen
# 4. Deployment neu starten
```

### Problem 7: Security Group already exists

**Fehlermeldung:** "A security group with the name 'nextcloud-web-sg' already exists"

**Lösung:**
```bash
# Alte Security Groups manuell löschen
aws ec2 delete-security-group --group-name nextcloud-web-sg --region us-east-1
aws ec2 delete-security-group --group-name nextcloud-db-sg --region us-east-1

# Deployment neu starten
bash scripts/deploy.sh
```

---

## Nützliche Befehle

### AWS-Ressourcen prüfen

**Alle Nextcloud-Instanzen anzeigen:**
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=M346-Nextcloud" \
  --region us-east-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

**Security Groups anzeigen:**
```bash
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=nextcloud-*" \
  --region us-east-1 \
  --query 'SecurityGroups[*].[GroupId,GroupName]' \
  --output table
```

**Instance-Status prüfen:**
```bash
aws ec2 describe-instance-status \
  --instance-ids i-XXXXXXXXX \
  --region us-east-1
```

### Server-Logs ansehen

**Webserver Console Output:**
```bash
aws ec2 get-console-output \
  --instance-id i-XXXXXXXXX \
  --region us-east-1 \
  --output text > webserver.log

# Log-Datei öffnen
cat webserver.log
```

**Database Server Console Output:**
```bash
aws ec2 get-console-output \
  --instance-id i-XXXXXXXXX \
  --region us-east-1 \
  --output text > database.log

cat database.log
```

### SSH-Zugriff

**Zum Webserver verbinden:**
```bash
ssh -i vockey.pem ubuntu@XX.XX.XX.XX

# Apache-Status prüfen
sudo systemctl status apache2

# Nextcloud-Dateien anzeigen
ls -la /var/www/html/

# Logs anzeigen
sudo tail -f /var/log/apache2/error.log
```

**Zum Database Server verbinden:**
```bash
# Erst zum Webserver
ssh -i vockey.pem ubuntu@<WEB_PUBLIC_IP>

# Dann von dort zum DB-Server (nur private IP!)
ssh ubuntu@172.31.XX.XX

# MariaDB-Status prüfen
sudo systemctl status mariadb

# MySQL verbinden
sudo mysql -u root -p
```

### Nextcloud-Status prüfen

```bash
# Auf Webserver via SSH
ssh -i vockey.pem ubuntu@XX.XX.XX.XX

# Nextcloud occ (Command Line Tool)
sudo -u www-data php /var/www/html/occ status

# Sollte zeigen:
# - installed: true
# - version: XX.X.X
# - versionstring: Nextcloud XX.X.X
```

### Deployment-Info anzeigen

Nach dem Deployment wird eine `deployment-info.json` erstellt:

```bash
# Datei anzeigen
cat deployment-info.json

# Formatiert ausgeben (mit jq)
cat deployment-info.json | jq .
```

**Enthält:**
- Instance IDs
- IP-Adressen
- Security Group IDs
- Passwörter (SICHER AUFBEWAHREN!)
- Deployment-Zeitstempel

---

## Support & Kontakt

**GitHub Repository:**  
https://github.com/seid950/m346-nextcloud-projekt

**Bei Problemen:**
1. Prüfe [Troubleshooting](#troubleshooting)
2. Schaue Logs an (siehe [Nützliche Befehle](#nützliche-befehle))
3. Erstelle ein GitHub Issue

**Team:**
- Seid Veseli
- Amar Ibraimi
- Leandro Graf

---

## Weitere Dokumentation

- **DOKUMENTATION.md** - Vollständige Projekt-Dokumentation
  - Projektplanung
  - Architektur
  - Tests
  - Reflexion
  - Aufgabenverteilung

---

**Viel Erfolg mit Nextcloud! 🚀**
