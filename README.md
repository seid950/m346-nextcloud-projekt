# Nextcloud Cloud Deployment - AWS Automatisierung

Vollautomatische Nextcloud-Installation auf AWS mit zwei separaten EC2-Instanzen (Webserver + Datenbank).

**Projekt:** Modul 346 - Cloudlösungen konzipieren und realisieren  
**Team:** Seid Veseli, Amar Ibraimi, Leandro Graf  
**Institution:** GBS St.Gallen

---

## Inhaltsverzeichnis

- [Voraussetzungen](#voraussetzungen)
- [Installation](#installation)
- [Deployment](#deployment)
- [Nextcloud Setup](#nextcloud-setup)
- [Cleanup](#cleanup)
- [Nützliche Befehle](#nützliche-befehle)
- [Technische Details](#technische-details)
- [Weitere Dokumentation](#weitere-dokumentation)
- [Support](#support)

---

## Voraussetzungen

- Linux-Terminal (Ubuntu, Debian, WSL2, oder andere Distribution)
- AWS Academy Learner Lab Zugang
- GitHub Account (Repository ist privat)
- Internet-Verbindung

**Entwickelt mit:** WSL2 (Ubuntu 22.04)

---

## Installation

### 1. AWS CLI installieren

```bash
# Prüfen
aws --version

# Falls nicht installiert:
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y  # Falls unzip fehlt
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Testen
aws --version
```

---

### 2. AWS Learner Lab starten

1. Login: https://awsacademy.instructure.com
2. **Modules** → **Learner Lab** → **Start Lab**
3. Warte bis grüner Punkt ✅

---

### 3. AWS Credentials konfigurieren

**In AWS Academy:**
1. Klicke **"AWS Details"** → **"Show"**
2. Klicke **"Copy"**

**Im Terminal (zwei Optionen):**

**Option A - aws configure (schneller):**
```bash
aws configure set aws_access_key_id ASIA...
aws configure set aws_secret_access_key wJal...
aws configure set aws_session_token "FwoG..."
aws configure set region us-east-1
```

**Option B - nano:**
```bash
mkdir -p ~/.aws
nano ~/.aws/credentials
# Credentials einfügen (Rechtsklick oder Shift+Insert)
# Speichern: Ctrl+O, Enter, Ctrl+X
```

**Testen:**
```bash
aws sts get-caller-identity
```

---

### 4. Repository klonen (PRIVAT)

#### 4.1 GitHub Personal Access Token erstellen

**Dieses Repository ist privat. Du brauchst einen Token für den Zugriff.**

**Schritt 1 - GitHub Settings öffnen:**
1. Öffne deinen Browser
2. Gehe zu: https://github.com
3. Klicke oben rechts auf dein **Profilbild**
4. Klicke auf **"Settings"** (im Dropdown-Menü)

**Schritt 2 - Developer Settings:**
1. Scrolle ganz nach unten in der linken Seitenleiste
2. Klicke auf **"Developer settings"** (letzter Punkt)

**Schritt 3 - Personal Access Tokens:**
1. Klicke auf **"Personal access tokens"** (linke Seite)
2. Klicke auf **"Tokens (classic)"**
3. Klicke auf **"Generate new token"** (oben rechts)
4. Klicke auf **"Generate new token (classic)"**

**Schritt 4 - Token konfigurieren:**

**Note (Name):**
```
m346-nextcloud-projekt
```

**Expiration (Ablaufdatum):**
- Wähle: **90 days** (oder länger)

**Select scopes (Berechtigungen):**
- ✅ Aktiviere nur: **`repo`**
  - Dies aktiviert automatisch alle Sub-Optionen:
  - `repo:status`
  - `repo_deployment`
  - `public_repo`
  - `repo:invite`
  - `security_events`

**⚠️ WICHTIG:** Nur `repo` anklicken, nichts anderes!

**Schritt 5 - Token generieren:**
1. Scrolle ganz nach unten
2. Klicke auf **"Generate token"** (grüner Button)

**Schritt 6 - Token kopieren:**

**Was du jetzt siehst:**
```
ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Ein langer Token mit ~40 Zeichen.

**⚠️ SEHR WICHTIG:**
- Dieser Token wird **nur EINMAL** angezeigt!
- Kopiere ihn **SOFORT**:
  1. Klicke auf das Copy-Icon 📋 neben dem Token
  2. Oder markiere und kopiere (Ctrl+C / Cmd+C)
- Speichere ihn in einem Text-Editor (Notepad, etc.)
- Falls du ihn verlierst: Neuen Token erstellen

**Token-Format:**
- Beginnt mit: `ghp_`
- Gefolgt von 36 zufälligen Zeichen
- Beispiel: `ghp_1A2b3C4d5E6f7G8h9I0j1K2l3M4n5O6p7Q8r`

---

#### 4.2 Klonen

```bash
# Git installieren falls nötig
sudo apt install git -y  # Ubuntu/Debian/WSL

# Klonen
cd ~
git clone https://github.com/seid950/m346-nextcloud-projekt.git
```

**Authentifizierung:**
- Username: Dein GitHub-Username
- Password: Token (ghp_xxx...) - NICHT GitHub-Passwort!

**Token cachen (optional):**
```bash
git config --global credential.helper 'cache --timeout=3600'
```

**In Projekt wechseln:**
```bash
cd m346-nextcloud-projekt
ls -la
```

---

## Deployment

### 1. Script-Berechtigung prüfen

```bash
ls -la scripts/deploy-nextcloud.sh
# Sollte 'x' haben: -rwxr-xr-x
# Die 'x' bedeuten "ausführbar"

# Falls nicht (-rw-r--r-- ohne x):
chmod +x scripts/deploy-nextcloud.sh scripts/cleanup-nextcloud.sh
```

---

### 2. Deployment starten

```bash
bash scripts/deploy-nextcloud.sh
```

---

### 3. Deployment-Ablauf

**Was passiert:**

1. **Passwörter generieren** (24 Zeichen)
2. **Konfiguration anzeigen** (Region, Instance Type, etc.)
3. **Bestätigung:** Tippe `j` und Enter



4. **Deployment läuft** (~4 Minuten):
   - Phase 1/7: Cleanup
   - Phase 2/7: Security Groups
   - Phase 3/7: User-Data Scripts
   - Phase 4/7: Database Server (Wartezeit: 120 Sek)
   - Phase 5/7: Webserver
   - Phase 6/7: Deployment-Info
   - Phase 7/7: Fertig

5. **Erfolg - Notiere:**
   - Nextcloud URL (Public IP): `http://54.x.x.x`
   - DB-Host (Private IP): `172.31.x.x`
   - DB-Passwort: 24 Zeichen



---

### 4. Warten bis Nextcloud bereit

**Warte 2-3 Minuten nach Script-Ende!**

```bash
# Testen (ersetze mit deiner IP):
curl http://54.x.x.x

# "Connection refused" = noch warten
# HTML-Code = bereit 
```

---

## Nextcloud Setup

### 1. Browser öffnen

Öffne: `http://DEINE-PUBLIC-IP`



---

### 2. Formular ausfüllen

**Admin-Account:**
- Benutzername: `admin`
- Passwort: Dein Admin-Passwort (merken!)

**Datenverzeichnis:**
- Ändere zu: `/var/nextcloud-data`

**Datenbank (MySQL/MariaDB auswählen!):**
- Benutzer: `nextcloud`
- Passwort: 24 Zeichen aus Terminal
- Name: `nextcloud`
- Host: `172.31.x.x` (Private IP - NICHT localhost!)

** WICHTIG:** Private IP verwenden (172.31.x.x), NICHT localhost!

---

### 3. Installation starten

Klicke: **"Installation abschließen"**

Warte 30-60 Sekunden...


---

## Cleanup

**Ressourcen löschen:**

```bash
cd ~/m346-nextcloud-projekt
bash scripts/cleanup-nextcloud.sh
```

Bestätigung: `ja` (komplett ausschreiben!)

Optional lokale Dateien: `nein` (empfohlen)

---



## Nützliche Befehle

```bash
# AWS-Ressourcen anzeigen
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=M346-Nextcloud" \
  --region us-east-1 \
  --output table

# Deployment-Info
cat deployment-info.json
cat deployment-info.json | grep password
cat deployment-info.json | grep ip
```

---


**Key Points:**
- 2 separate EC2-Instanzen
- Webserver: Public IP (Internet)
- Database: Private IP (intern)
- Security Groups: Firewall
- Vollautomatisch: Cloud-Init

---

## Technische Details

**Entwickelt mit:**
- OS: Windows 11 + WSL2 (Ubuntu 22.04)
- AWS CLI: 2.15.10
- Region: us-east-1
- Instance Type: 2x t2.micro

**Software-Stack:**
- Webserver: Apache 2.4 + PHP 8.1
- Database: MariaDB 10.6
- Nextcloud: Latest Stable

**Kompatibel mit:**
- Alle Linux-Distributionen
- macOS
- Windows mit WSL/WSL2

---

## Weitere Dokumentation

- **DOKUMENTATION.md** - Vollständige Projekt-Dokumentation
- **TROUBLESHOOTING.md** - Detaillierte Problemlösungen (10 Probleme)


---

## Support

**GitHub:** https://github.com/seid950/m346-nextcloud-projekt

**Team:**
- Seid Veseli (Projektleiter, Scripts, Testing)
- Amar Ibraimi (Database Specialist, Testing)
- Leandro Graf (Documentation Lead)

