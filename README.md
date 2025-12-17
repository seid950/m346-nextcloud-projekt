# Nextcloud Cloud Deployment - AWS Automatisierung

Vollautomatische Nextcloud-Installation auf AWS mit zwei separaten EC2-Instanzen (Webserver + Datenbank).

**Projekt:** Modul 346 - Cloudlösungen konzipieren und realisieren  
**Team:** Seid Veseli, Amar Ibraimi, Leandro Graf  
**Institution:** GBS St.Gallen

---

## Quick Start

```bash
# 1. Repository klonen
git clone https://github.com/seid950/m346-nextcloud-projekt.git
cd m346-nextcloud-projekt

# 2. AWS Credentials konfigurieren
aws configure set aws_access_key_id ASIA...
aws configure set aws_secret_access_key wJal...
aws configure set aws_session_token "FwoG..."
aws configure set region us-east-1

# 3. Deployment starten
bash scripts/deploy.sh

# 4. Mit 'j' bestätigen, ~4 Min warten

# 5. Nextcloud im Browser öffnen

# 6. Fertig!
```

---

## Inhaltsverzeichnis

- [Voraussetzungen](#voraussetzungen)
- [Installation](#installation)
- [Deployment](#deployment)
- [Nextcloud Setup](#nextcloud-setup)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)

---

## Voraussetzungen

### Was du brauchst

- ✅ **Linux-Terminal** (Ubuntu, Debian, WSL2, oder andere Distribution)
- ✅ **AWS Academy Learner Lab** Zugang
- ✅ **Internet-Verbindung**

**Hinweis:** Entwickelt mit **WSL2 (Ubuntu 22.04)**, funktioniert auf jedem Linux-System.

---

## Installation

### 1. AWS CLI installieren

**Prüfen:**
```bash
aws --version
```

**Falls "command not found":**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip
aws --version  # Testen
```

**Unzip installieren falls nötig:**
```bash
sudo apt install unzip -y     # Ubuntu/Debian/WSL
sudo dnf install unzip -y     # Fedora/RHEL
```

---

### 2. AWS Learner Lab starten

1. Login: https://awsacademy.instructure.com
2. **Modules** → **Learner Lab**
3. **Start Lab** (warte bis grüner Punkt ✅)

---

### 3. AWS Credentials konfigurieren

**In AWS Academy:**
1. Klicke **"AWS Details"** → **"Show"**
2. Klicke **"Copy"**

**Im Terminal - ZWEI METHODEN:**

**Option A - Mit aws configure (empfohlen):**
```bash
aws configure set aws_access_key_id ASIAXXXXXXXXXXXXXXXXX
aws configure set aws_secret_access_key wJalrXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
aws configure set aws_session_token "FwoGZXIvYXdzEBkaDC...DEIN-TOKEN..."
aws configure set region us-east-1
```
**Ersetze mit deinen echten Credentials aus AWS Academy!**

**Vorteile:**
- Schnell und einfach
- Bei neuer Session einfach nochmal ausführen

**Option B - Manuell:**
```bash
mkdir -p ~/.aws
nano ~/.aws/credentials
# Credentials einfügen: Rechte Maustaste oder Shift+Insert
# Speichern: Ctrl+O, Enter, Ctrl+X
```

**Testen:**
```bash
aws sts get-caller-identity
```

**Sollte zeigen:**
```json
{
    "UserId": "AIDAXXXXXXXXXX:user",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/awsstudent"
}
```

---

### 4. Repository klonen

```bash
cd ~
git clone https://github.com/seid950/m346-nextcloud-projekt.git
cd m346-nextcloud-projekt
ls -la  # Prüfen
```

**Falls Git nicht installiert:**
```bash
sudo apt install git -y     # Ubuntu/Debian/WSL
sudo dnf install git -y     # Fedora/RHEL
```

---

## Deployment

### Script ausführen

```bash
bash scripts/deploy.sh
```

### Was passiert

**1. Passwörter werden generiert**
```
Generiere sichere Passwoerter...
   Root-Passwort generiert (24 Zeichen)
   Nextcloud-DB-Passwort generiert (24 Zeichen)
```

**2. Konfiguration wird angezeigt**
```
+-----------------------------------------------------------------------+
| DEPLOYMENT-KONFIGURATION                                              |
+-----------------------------------------------------------------------+
|  AWS Region:           us-east-1                                      |
|  Instance Type:        t2.micro                                       |
|  AMI ID:               ami-03deb8c961063af8c                          |
|  Webserver:            Apache 2.4 + PHP 8.1                           |
|  Datenbank:            MariaDB 10.6                                   |
+-----------------------------------------------------------------------+
```

**3. Bestätigung**
```
Deployment starten? [j/n]:
```

**📸 SCREENSHOT 1:** Jetzt Screenshot machen!  
Speichern als: `Screenshots/01_deployment_start.png`

**Dann:** Tippe `j` und Enter

**4. Deployment läuft**
```
[PHASE 1/7] CLEANUP ALTE RESSOURCEN
[PHASE 2/7] SECURITY GROUPS ERSTELLEN
[PHASE 3/7] INFRASTRUCTURE AS CODE
[PHASE 4/7] DATABASE SERVER DEPLOYMENT
   Warte 120 Sekunden fuer MariaDB...
   ............
[PHASE 5/7] WEBSERVER DEPLOYMENT
[PHASE 6/7] DEPLOYMENT-DOKUMENTATION
[PHASE 7/7] DEPLOYMENT ABGESCHLOSSEN
```

**Dauer:** ~4 Minuten  
**⚠️ NICHT ABBRECHEN!**

**5. Erfolg!**
```
    ██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗   ██╗███████╗██████╗ 
    ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝██╔════╝██╔══██╗
    ██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚████╔╝ █████╗  ██║  ██║
    ██║  ██║██╔══╝  ██╔═══╝ ██║     ██║   ██║  ╚██╔╝  ██╔══╝  ██║  ██║
    ██████╔╝███████╗██║     ███████╗╚██████╔╝   ██║   ███████╗██████╔╝
    ╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝   ╚══════╝╚═════╝ 

+=========================================================================+
|                       NEXTCLOUD INSTALLATION                            |
|                          http://54.162.154.237                          |
+=========================================================================+

WICHTIG: Warte 2-3 Minuten bis Nextcloud komplett installiert ist

DATENBANK-ZUGANGSDATEN FUER SETUP-ASSISTENT:
+-----------------------------------------------------------------------+
|   Datenbank-Typ:         MySQL/MariaDB                                |
|   Datenbank-Host:        172.31.24.60                                 |
|   Datenbank-Name:        nextcloud                                    |
|   Datenbank-Benutzer:    nextcloud                                    |
|   Datenbank-Passwort:    xY9mK2nL5pQ8rT1vW4zA7bC0                     |
|   Datenverzeichnis:      /var/nextcloud-data                          |
+-----------------------------------------------------------------------+
```

**📸 SCREENSHOT 2:** Jetzt Screenshot machen!  
Speichern als: `Screenshots/02_deployment_complete.png`

**Wichtig - Notiere:**
- ✅ Nextcloud URL (Public IP)
- ✅ Datenbank-Host (Private IP)
- ✅ Datenbank-Passwort (24 Zeichen)

### Warten bis bereit

**Auch nach Script-Ende: Warte 2-3 Minuten!**

**Testen:**
```bash
curl http://54.162.154.237  # Deine IP!
```

**Falls "Connection refused":** Noch 1-2 Min warten  
**Falls HTML-Code:** Bereit! ✅

---

## Nextcloud Setup

### 1. Browser öffnen

Öffne: `http://DEINE-PUBLIC-IP`

**📸 SCREENSHOT 3:** Setup-Assistent (bevor du was ausfüllst!)  
Speichern als: `Screenshots/03_nextcloud_setup.png`

---

### 2. Formular ausfüllen

**Admin-Account:**
- Benutzername: `admin`
- Passwort: Dein gewähltes Passwort (merken!)

**Datenverzeichnis:**
- Ändere zu: `/var/nextcloud-data`

**Datenbank (MySQL/MariaDB auswählen!):**
- Benutzer: `nextcloud`
- Passwort: `[24-Zeichen aus Terminal]`
- Name: `nextcloud`
- Host: `172.31.24.60` **(Private IP, NICHT localhost!)**

**⚠️ WICHTIG:**
- Private IP verwenden (172.31.x.x)
- Passwort EXAKT kopieren
- NICHT localhost verwenden!

---

### 3. Installation starten

Klicke: **Installation abschließen**

Warte 30-60 Sekunden...

**📸 SCREENSHOT 4:** Dashboard  
Speichern als: `Screenshots/04_nextcloud_running.png`

**🎉 FERTIG!**

---

## Cleanup

**Wichtig:** Ressourcen nach Nutzung löschen!

```bash
cd ~/m346-nextcloud-projekt
bash scripts/cleanup.sh
```

Bestätigung: `ja` (komplett ausschreiben!)

**Dauer:** ~1 Minute

---

## Troubleshooting

**Alle Details:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### Häufigste Probleme

| Problem | Schnelle Lösung |
|---------|-----------------|
| **Credentials funktionieren nicht** | `aws configure set ...` nochmal ausführen |
| **Nextcloud lädt nicht** | 2-3 Min warten, dann `curl http://IP` |
| **DB-Verbindung fehlgeschlagen** | Private IP (172.31.x.x) verwenden! |
| **AWS Session abgelaufen** | Neue Session starten, Credentials neu setzen |

**Credentials schnell neu setzen:**
```bash
aws configure set aws_access_key_id ASIA...
aws configure set aws_secret_access_key wJal...
aws configure set aws_session_token "FwoG..."
```

**Private IP finden:**
```bash
cat deployment-info.json | grep private_ip
```

**Testen ob Nextcloud bereit:**
```bash
curl http://DEINE-IP
# HTML = bereit, "Connection refused" = noch warten
```

---

## Nützliche Befehle

**AWS-Ressourcen anzeigen:**
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=M346-Nextcloud" \
  --region us-east-1 \
  --output table
```

**Deployment-Info:**
```bash
cat deployment-info.json
cat deployment-info.json | grep password  # Nur Passwörter
cat deployment-info.json | grep ip        # Nur IPs
```

**Bei neuer AWS Session:**
```bash
# Credentials schnell aktualisieren
aws configure set aws_access_key_id ASIA...
aws configure set aws_secret_access_key wJal...
aws configure set aws_session_token "FwoG..."
```

---

## Architektur

```
┌──────────────────────────────────────────────────┐
│           AWS Cloud (us-east-1)                  │
│                                                  │
│  ┌──────────────┐         ┌──────────────┐      │
│  │  Webserver   │         │  Database    │      │
│  │  t2.micro    │◄────────│  t2.micro    │      │
│  │              │         │              │      │
│  │  Apache 2.4  │         │  MariaDB 10.6│      │
│  │  PHP 8.1     │         │  nextcloud DB│      │
│  │  Nextcloud   │         │              │      │
│  │              │         │              │      │
│  │  Public IP   │         │  Private IP  │      │
│  │  Port 80, 22 │         │  Port 3306   │      │
│  └──────────────┘         └──────────────┘      │
│        │                                         │
└────────┼─────────────────────────────────────────┘
         │
         ▼
   [ Internet User ]
```

**Key Points:**
- 2 separate EC2-Instanzen
- Webserver: Public IP (Internet-erreichbar)
- Database: Private IP (nur intern)
- Security Groups als Firewall
- Vollautomatisch per Script

---

## Technische Details

**Entwickelt mit:**
- OS: Windows 11 + WSL2 (Ubuntu 22.04)
- AWS CLI: 2.15.10
- Region: us-east-1
- AMI: ami-03deb8c961063af8c (Ubuntu 24.04 LTS)
- Instance Type: 2x t2.micro (Free Tier)

**Kompatibel mit:**
- Alle Linux-Distributionen
- macOS
- Windows mit WSL/WSL2

**Automatisierung:**
- Infrastructure as Code
- Cloud-Init (User-Data)
- Bash-Scripts
- Git-Versionierung

---

## Weitere Dokumentation

- **DOKUMENTATION.md** - Vollständige Projekt-Dokumentation
  - Projektziele, Planung, Architektur
  - Herausforderungen & Lösungen
  - Tests & Validierung
  - Reflexion & Quellen

- **TROUBLESHOOTING.md** - Detaillierte Problemlösungen
  - 9 häufige Probleme mit Lösungen
  - Logs ansehen, Debugging-Befehle

- **QUICKSTART.md** - Ultra-kurze Anleitung

---

## Support

**GitHub:** https://github.com/seid950/m346-nextcloud-projekt

**Team:**
- Seid Veseli (Projektleiter, Scripts, Testing)
- Amar Ibraimi (Database Specialist, Testing)
- Leandro Graf (Documentation Lead)