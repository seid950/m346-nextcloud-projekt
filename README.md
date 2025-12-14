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

#### AWS CLI testen

**Wo:** In deinem Terminal (egal welches Verzeichnis)

```bash
aws --version
```

**Erwartete Ausgabe:**
```
aws-cli/2.15.10 Python/3.11.6 Linux/5.15.0 exe/x86_64
```
oder ähnlich (Version 2.x.x oder höher)

**Falls "command not found":** Siehe [Troubleshooting - Problem 1](#problem-1-aws-cli-not-found)

---

#### AWS Credentials prüfen

**Wo:** In deinem Terminal

```bash
aws sts get-caller-identity
```

**Erwartete Ausgabe:**
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/awsstudent"
}
```

**Falls Fehler:** Credentials noch nicht konfiguriert - siehe [Schritt 2: AWS Learner Lab starten](#schritt-2-aws-learner-lab-starten)

---

### Lokale Umgebung

- ✅ **Bash-Shell** (Linux, macOS, oder WSL unter Windows)
- ✅ **Git** installiert
- ✅ **Internet-Verbindung**

#### Git testen

**Wo:** In deinem Terminal

```bash
git --version
```

**Erwartete Ausgabe:**
```
git version 2.43.0
```
oder ähnlich (Version 2.x.x oder höher)

---

## Installation

### Schritt 1: Repository klonen

**Wo:** In deinem Home-Verzeichnis oder wo du deine Projekte hast

```bash
# Navigiere zu deinem Projekt-Ordner (z.B. Desktop oder Dokumente)
cd ~/Desktop

# Repository herunterladen
git clone https://github.com/seid950/m346-nextcloud-projekt.git
```

**Erwartete Ausgabe:**
```
Cloning into 'm346-nextcloud-projekt'...
remote: Enumerating objects: 50, done.
remote: Counting objects: 100% (50/50), done.
remote: Compressing objects: 100% (35/35), done.
remote: Total 50 (delta 15), reused 50 (delta 15), pack-reused 0
Receiving objects: 100% (50/50), 25.30 KiB | 1.15 MiB/s, done.
Resolving deltas: 100% (15/15), done.
```

---

```bash
# In das Projekt-Verzeichnis wechseln
cd m346-nextcloud-projekt
```

**Wo du jetzt bist:** Im Verzeichnis `m346-nextcloud-projekt`

**Prompt sollte zeigen:**
```bash
~/Desktop/m346-nextcloud-projekt$
```
oder ähnlich

---

```bash
# Inhalt des Projekts anzeigen
ls -la
```

**Erwartete Ausgabe:**
```
total 48
drwxr-xr-x  5 user user  4096 Dec 14 10:00 .
drwxr-xr-x 25 user user  4096 Dec 14 10:00 ..
drwxr-xr-x  8 user user  4096 Dec 14 10:00 .git
-rw-r--r--  1 user user   150 Dec 14 10:00 .gitignore
-rw-r--r--  1 user user 15234 Dec 14 10:00 DOKUMENTATION.md
-rw-r--r--  1 user user  8432 Dec 14 10:00 README.md
drwxr-xr-x  2 user user  4096 Dec 14 10:00 screenshots
drwxr-xr-x  2 user user  4096 Dec 14 10:00 scripts
```

**Wichtig:** Du solltest sehen:
- ✅ README.md
- ✅ DOKUMENTATION.md
- ✅ scripts/ (Ordner)
- ✅ screenshots/ (Ordner)

---

### Schritt 2: AWS Learner Lab starten

**Wo:** In deinem Browser

#### 1. In AWS Academy einloggen

1. Gehe zu: https://awsacademy.instructure.com
2. Login mit deinen Academy-Credentials
3. Wähle deinen Kurs aus

#### 2. Learner Lab öffnen

1. Klicke auf "Modules"
2. Klicke auf "Learner Lab - Foundational Services"
3. Klicke auf "Start Lab"

**Was du siehst:**
- Roter Punkt neben "AWS" (Lab startet)
- Nach 1-2 Minuten: Grüner Punkt (Lab bereit)

#### 3. AWS CLI Credentials kopieren

1. **Klicke auf "AWS Details"**
2. **Klicke auf "Show" bei AWS CLI Credentials**

**Was du siehst:**
```
[default]
aws_access_key_id=ASIAXXXXXXXXXXXXXXXXX
aws_secret_access_key=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
aws_session_token=FwoGZXIvYXdzEBkaDC...sehr langer Token...
```

3. **Klicke auf "Copy"** (kopiert alle 3 Zeilen)

#### 4. Credentials in lokale AWS Config einfügen

**Wo:** In deinem Terminal

```bash
# Öffne die AWS Credentials-Datei
nano ~/.aws/credentials
```

**Was passiert:** Nano Text-Editor öffnet sich

**Falls Datei leer ist oder nicht existiert:**
- Füge die kopierten Credentials ein
- Drücke `Ctrl + O` (Speichern)
- Drücke `Enter` (bestätigen)
- Drücke `Ctrl + X` (Schließen)

**Falls schon ein [default] Block existiert:**
- Lösche den alten Block
- Füge die neuen Credentials ein
- Speichern und Schließen (wie oben)

**Die Datei sollte jetzt so aussehen:**
```ini
[default]
aws_access_key_id=ASIAXXXXXXXXXXXXXXXXX
aws_secret_access_key=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
aws_session_token=FwoGZXIvYXdzEBkaDC...
```

#### 5. Credentials testen

**Wo:** In deinem Terminal

```bash
aws ec2 describe-regions --region us-east-1
```

**Erwartete Ausgabe:**
```json
{
    "Regions": [
        {
            "Endpoint": "ec2.eu-north-1.amazonaws.com",
            "RegionName": "eu-north-1",
            "OptInStatus": "opt-in-not-required"
        },
        {
            "Endpoint": "ec2.ap-south-1.amazonaws.com",
            "RegionName": "ap-south-1",
            "OptInStatus": "opt-in-not-required"
        },
        ...
    ]
}
```

**Falls Fehler "Unable to locate credentials":**
- Credentials wurden nicht korrekt eingefügt
- Wiederhole Schritt 4

**Falls andere Fehler:**
- Siehe [Troubleshooting](#troubleshooting)

---

### Schritt 3: Deployment ausführen

**Wo:** In deinem Terminal, im Verzeichnis `m346-nextcloud-projekt`

**Prüfe zuerst wo du bist:**
```bash
pwd
```

**Sollte zeigen:**
```
/home/user/Desktop/m346-nextcloud-projekt
```
oder ähnlich (Hauptsache endet mit `m346-nextcloud-projekt`)

**Falls nicht im richtigen Verzeichnis:**
```bash
cd ~/Desktop/m346-nextcloud-projekt
# oder wo auch immer dein Projekt ist
```

---

#### Deployment-Script starten

```bash
bash scripts/deploy.sh
```

**Was jetzt passiert - Schritt für Schritt:**

---

#### 1. Passwort-Generierung

**Ausgabe:**
```
Generiere sichere Passwoerter...
   Root-Passwort generiert (24 Zeichen, alphanumerisch)
   Nextcloud-DB-Passwort generiert (24 Zeichen, alphanumerisch)
```

**Was passiert:** Script generiert 2 sichere Passwörter für die Datenbank

---

#### 2. Konfiguration anzeigen

**Ausgabe:**
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

**Was passiert:** Script zeigt was deployed wird

---

#### 3. Bestätigung

**Ausgabe:**
```
ACHTUNG: Dieses Script wird folgende Aktionen ausfuehren:
   - Alte Nextcloud-Instanzen terminieren
   - Neue Security Groups erstellen
   - 2 EC2-Instanzen starten (Database + Webserver)
   - Nextcloud vollautomatisch installieren

Deployment starten? [j/n]:
```

**Was du tun musst:**
- Tippe `j` (für "ja")
- Drücke `Enter`

**Erwartete Reaktion:** Script läuft weiter

**Falls du `n` tippst:** Script bricht ab (nichts wird deployed)

---

#### 4. Phase 1/7: Cleanup

**Ausgabe:**
```
[PHASE 1/7] CLEANUP ALTE RESSOURCEN
=======================================================================

   Suche alte Nextcloud-Instanzen...
   Keine alten Instanzen gefunden
   Loesche alte Security Groups...
   Web-SG nicht vorhanden
   DB-SG nicht vorhanden
```

**Was passiert:** Script löscht alte Ressourcen falls vorhanden

**Dauer:** 5-10 Sekunden

---

#### 5. Phase 2/7: Security Groups

**Ausgabe:**
```
[PHASE 2/7] SECURITY GROUPS ERSTELLEN
=======================================================================

   Erstelle Security Groups...
   Database SG erstellt:  sg-0a1b2c3d4e5f6g7h8
   Webserver SG erstellt: sg-9h8g7f6e5d4c3b2a1

   Konfiguriere Firewall-Regeln...
   Webserver:  Port 80 (HTTP) offen fuer 0.0.0.0/0
   Webserver:  Port 22 (SSH) offen fuer 0.0.0.0/0
   Database:   Port 3306 (MySQL) nur von Webserver-SG
   Database:   Port 22 (SSH) offen fuer 0.0.0.0/0
```

**Was passiert:** 
- 2 Security Groups werden erstellt
- Firewall-Regeln werden konfiguriert

**Dauer:** 5-10 Sekunden

---

#### 6. Phase 3/7: User-Data Scripts

**Ausgabe:**
```
[PHASE 3/7] INFRASTRUCTURE AS CODE
=======================================================================

   Erstelle User-Data Scripts...
```

**Was passiert:** Cloud-Init Scripts für beide Server werden generiert

**Dauer:** 2-3 Sekunden

---

#### 7. Phase 4/7: Database Server

**Ausgabe:**
```
[PHASE 4/7] DATABASE SERVER DEPLOYMENT
=======================================================================

   Starte Database Server Instanz...
   Instanz gestartet: i-0a1b2c3d4e5f6g7h8
   Warte bis Instanz laeuft...
   Instanz laeuft
   Private IP: 172.31.24.60

   Warte 120 Sekunden fuer MariaDB Installation & Konfiguration...
   ............
```

**Was passiert:**
- Database Server wird gestartet
- Script wartet 120 Sekunden (2 Minuten)
- 12 Punkte erscheinen (1 Punkt alle 10 Sekunden)

**Dauer:** ~2 Minuten

**WICHTIG:** Einfach warten! Nicht abbrechen!

---

#### 8. Phase 5/7: Webserver

**Ausgabe:**
```
[PHASE 5/7] WEBSERVER DEPLOYMENT
=======================================================================

   Erstelle Webserver User-Data...
   Starte Webserver Instanz...
   Instanz gestartet: i-9h8g7f6e5d4c3b2a1
   Warte bis Instanz laeuft...
   Instanz laeuft
   Public IP: 54.162.154.237
```

**Was passiert:** Webserver wird gestartet

**Dauer:** 10-20 Sekunden

---

#### 9. Phase 6/7: Deployment-Info

**Ausgabe:**
```
[PHASE 6/7] DEPLOYMENT-DOKUMENTATION
=======================================================================

   Speichere Deployment-Informationen...
```

**Was passiert:** 
- `deployment-info.json` wird erstellt
- `cloud-init-database.yaml` wird erstellt  
- `cloud-init-webserver.yaml` wird erstellt

**Dauer:** 1-2 Sekunden

---

#### 10. Phase 7/7: Erfolgsmeldung

**Ausgabe:**
```
[PHASE 7/7] DEPLOYMENT ABGESCHLOSSEN
=======================================================================

    ██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗   ██╗███████╗██████╗ 
    ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝██╔════╝██╔══██╗
    ██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚████╔╝ █████╗  ██║  ██║
    ██║  ██║██╔══╝  ██╔═══╝ ██║     ██║   ██║  ╚██╔╝  ██╔══╝  ██║  ██║
    ██████╔╝███████╗██║     ███████╗╚██████╔╝   ██║   ███████╗██████╔╝
    ╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝   ╚══════╝╚═════╝ 

+-----------------------------------------------------------------------+
| DEPLOYMENT UEBERSICHT                                                 |
+-----------------------------------------------------------------------+
|                                                                       |
|   Database Server:                                                    |
|     Instance ID:    i-0a1b2c3d4e5f6g7h8                               |
|     Private IP:     172.31.24.60                                      |
|     Security Group: sg-0a1b2c3d4e5f6g7h8                              |
|                                                                       |
|   Webserver:                                                          |
|     Instance ID:    i-9h8g7f6e5d4c3b2a1                               |
|     Public IP:      54.162.154.237                                    |
|     Security Group: sg-9h8g7f6e5d4c3b2a1                              |
|                                                                       |
+-----------------------------------------------------------------------+


+=========================================================================+
|                                                                         |
|                       NEXTCLOUD INSTALLATION                            |
|                                                                         |
|                          http://54.162.154.237                          |
|                                                                         |
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

GENERIERTE DATEIEN:
   - deployment-info.json        Alle Deployment-Details & Passwoerter
   - cloud-init-database.yaml    Database Server Konfiguration
   - cloud-init-webserver.yaml   Webserver Konfiguration

LOGS PRUEFEN:
   - Database:  aws ec2 get-console-output --instance-id i-0a1b2c3d4e5f6g7h8
   - Webserver: aws ec2 get-console-output --instance-id i-9h8g7f6e5d4c3b2a1

CLEANUP:
   - Zum Loeschen: bash cleanup.sh

═══════════════════════════════════════════════════════════════════════
Deployment erfolgreich abgeschlossen um 14:35:27
═══════════════════════════════════════════════════════════════════════
```

**WICHTIG - KOPIERE JETZT:**

1. **Die Nextcloud URL:** `http://54.162.154.237` (deine wird anders sein!)
2. **Datenbank-Host:** `172.31.24.60` (deine wird anders sein!)
3. **Datenbank-Passwort:** Das lange 24-Zeichen Passwort!

**Am besten:** Mache Screenshot oder kopiere in ein Textfile!

---

### Schritt 4: Warten

**Wo:** Mach eine Kaffeepause ☕

**WICHTIG:** Auch wenn das Script fertig ist, braucht Nextcloud noch 2-3 Minuten!

**Was im Hintergrund passiert:**
- Apache startet
- PHP wird konfiguriert
- Nextcloud wird entpackt
- Berechtigungen werden gesetzt

#### Testen ob Nextcloud bereit ist

**Wo:** In deinem Terminal

```bash
# Ersetze XX.XX.XX.XX mit deiner Public IP
curl http://54.162.154.237
```

**Falls NICHT bereit (noch warten):**
```
curl: (7) Failed to connect to 54.162.154.237 port 80: Connection refused
```
→ Warte noch 1-2 Minuten, dann nochmal probieren

**Falls BEREIT (Nextcloud läuft):**
```html
<!DOCTYPE html>
<html class="ng-csp" data-placeholder-focus="false" lang="de" data-locale="de" >
  <head>
    <meta charset="utf-8">
    <title>Nextcloud</title>
    ...sehr viel HTML-Code...
```
→ **PERFEKT!** Nextcloud ist bereit!

---

## Nextcloud konfigurieren

### Schritt 1: Nextcloud-URL öffnen

**Wo:** In deinem Browser (Chrome, Firefox, Safari, etc.)

1. **Browser öffnen**
2. **URL-Leiste klicken**
3. **URL eingeben:** `http://54.162.154.237` (deine IP aus Terminal!)
4. **Enter drücken**

**Was du siehst:**

![Nextcloud Setup-Assistent](screenshots/03_nextcloud_setup.png)

- Nextcloud Logo oben
- "Nextcloud installieren" als Überschrift
- Formular mit mehreren Feldern

**Falls "Seite kann nicht angezeigt werden":**
- Warte noch 1-2 Minuten
- Prüfe ob du die richtige IP verwendest
- Siehe [Troubleshooting - Problem 3](#problem-3-nextcloud-setup-assistent-erscheint-nicht)

---

### Schritt 2: Admin-Account erstellen

**Wo:** Im oberen Teil des Setup-Formulars

**Was du siehst:**
```
Administrator-Account erstellen

Benutzername:  [__________]
Passwort:      [__________]
```

**Was du eingeben sollst:**

1. **Benutzername:** Tippe `admin` (oder einen Namen deiner Wahl)
   - Erlaubt: Buchstaben, Zahlen, Unterstrich
   - Keine Leerzeichen!

2. **Passwort:** Tippe ein sicheres Passwort (z.B. `TestPass123!`)
   - Minimum 8 Zeichen
   - Empfohlung: Groß- und Kleinbuchstaben + Zahlen + Sonderzeichen

**Beispiel:**
```
Benutzername:  admin
Passwort:      TestPass123!
```

**WICHTIG:** 
- ⚠️ Merke dir dieses Passwort! Du brauchst es später zum Login
- ⚠️ Dies ist DEIN Admin-Account, nicht die Datenbank!

---

### Schritt 3: Datenverzeichnis (Optional)

**Wo:** Etwas weiter unten im Formular

**Was du siehst:**
```
Datenverzeichnis
[/var/www/html/data]
```

**Was du tun musst:**

1. **Lösche den vorgeschlagenen Pfad**
2. **Tippe ein:** `/var/nextcloud-data`

**Warum:** Unser Script hat das Datenverzeichnis dort vorbereitet

**Sollte jetzt so aussehen:**
```
Datenverzeichnis
[/var/nextcloud-data]
```

---

### Schritt 4: Datenbank konfigurieren

**Wo:** Weiter unten im Formular

**Was du siehst:**
```
Datenbank einrichten

○ SQLite
● MySQL/MariaDB
○ PostgreSQL
```

**Was du tun musst:**

#### 1. Datenbank-Typ auswählen

**Klicke auf:** `MySQL/MariaDB` (Kreis sollte gefüllt sein: ●)

---

#### 2. Datenbank-Benutzer eingeben

**Wo:** Erstes Feld unter "Datenbank einrichten"

**Was du siehst:**
```
Datenbank-Benutzer
[__________]
```

**Tippe ein:** `nextcloud`

**Sollte jetzt so aussehen:**
```
Datenbank-Benutzer
[nextcloud]
```

---

#### 3. Datenbank-Passwort eingeben

**Wo:** Zweites Feld

**Was du siehst:**
```
Datenbank-Passwort
[__________]
```

**Was du tun musst:**
1. **Gehe zu deinem Terminal**
2. **Finde die Box "DATENBANK-ZUGANGSDATEN"**
3. **Kopiere das Passwort** (die lange Zeile mit 24 Zeichen!)

**Beispiel aus Terminal:**
```
|   Datenbank-Passwort:    xY9mK2nL5pQ8rT1vW4zA7bC0                     |
```

4. **Füge das Passwort ins Browser-Feld ein**

**WICHTIG:**
- ⚠️ Kopiere es EXAKT! Jedes Zeichen zählt!
- ⚠️ Keine Leerzeichen am Anfang/Ende!
- ⚠️ Groß-/Kleinschreibung beachten!

**Sollte jetzt so aussehen:**
```
Datenbank-Passwort
[xY9mK2nL5pQ8rT1vW4zA7bC0]
```

---

#### 4. Datenbank-Name eingeben

**Wo:** Drittes Feld

**Was du siehst:**
```
Datenbank-Name
[__________]
```

**Tippe ein:** `nextcloud`

**Sollte jetzt so aussehen:**
```
Datenbank-Name
[nextcloud]
```

---

#### 5. Datenbank-Host eingeben

**Wo:** Viertes Feld

**Was du siehst:**
```
Datenbank-Host
[localhost]
```

**Was du tun musst:**
1. **Lösche** `localhost`
2. **Gehe zu deinem Terminal**
3. **Kopiere die Private IP** aus "Datenbank-Host"

**Beispiel aus Terminal:**
```
|   Datenbank-Host:        172.31.24.60                                 |
```

4. **Füge die IP ins Browser-Feld ein**

**WICHTIG:**
- ⚠️ Verwende die **Private IP** (172.31.x.x)
- ⚠️ NICHT die Public IP vom Webserver!
- ⚠️ NICHT localhost!

**Sollte jetzt so aussehen:**
```
Datenbank-Host
[172.31.24.60]
```

---

### Schritt 5: Installation starten

**Wo:** Unten im Formular

**Was du siehst:**
```
[Installation abschließen]  ← Blauer Button
```

**Prüfe nochmal alles:**

✅ **Admin-Account:**
   - Benutzername: `admin` (oder dein gewählter Name)
   - Passwort: Dein Admin-Passwort

✅ **Datenverzeichnis:**
   - `/var/nextcloud-data`

✅ **Datenbank:**
   - Typ: MySQL/MariaDB ausgewählt
   - Benutzer: `nextcloud`
   - Passwort: Das lange 24-Zeichen Passwort
   - Name: `nextcloud`
   - Host: `172.31.24.60` (deine Private IP)

**Wenn alles korrekt:**
1. **Klicke auf "Installation abschließen"**
2. **Warte 30-60 Sekunden**

**Was du siehst:**
- Ladeanzeige / Spinner
- "Nextcloud wird eingerichtet..."

---

### Schritt 6: Fertig!

**Was du jetzt siehst:**

![Nextcloud Dashboard](screenshots/04_nextcloud_running.png)

- Nextcloud Dashboard
- Oben rechts: Dein Username
- Links: Menü (Dateien, Fotos, etc.)
- Mitte: Willkommens-Dialog (kann geschlossen werden mit X)

**GRATULATION! Nextcloud läuft! 🎉**

---

## Ressourcen löschen

**WICHTIG:** Vergiss nicht, die AWS-Ressourcen zu löschen wenn du fertig bist!  
**Warum:** AWS Learner Lab hat Credits - verschwendete Ressourcen = verschwendete Credits

---

### Cleanup-Script ausführen

**Wo:** In deinem Terminal, im Verzeichnis `m346-nextcloud-projekt`

```bash
# Stelle sicher dass du im richtigen Verzeichnis bist
pwd
```

**Sollte zeigen:**
```
/home/user/Desktop/m346-nextcloud-projekt
```

**Falls nicht:**
```bash
cd ~/Desktop/m346-nextcloud-projekt
```

---

```bash
# Cleanup-Script starten
bash scripts/cleanup.sh
```

**Was jetzt passiert:**

---

#### 1. Banner

**Ausgabe:**
```
+===============================================================================+
|                                                                               |
|    ██████╗██╗     ███████╗ █████╗ ███╗   ██╗██╗   ██╗██████╗                  |
|   ██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║██║   ██║██╔══██╗                 |
|   ██║     ██║     █████╗  ███████║██╔██╗ ██║██║   ██║██████╔╝                 |
|   ██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║██║   ██║██╔═══╝                  |
|   ╚██████╗███████╗███████╗██║  ██║██║ ╚████║╚██████╔╝██║                      |
|    ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝                      |
|                                                                               |
|            NEXTCLOUD RESSOURCEN AUFRAEUMEN                                    |
|                                                                               |
+===============================================================================+
```

---

#### 2. Deployment-Info laden

**Ausgabe:**
```
[PHASE 1/4] DEPLOYMENT-INFO LADEN
=======================================================================

   Deployment-Info geladen
     Database Instance:  i-0a1b2c3d4e5f6g7h8
     Webserver Instance: i-9h8g7f6e5d4c3b2a1
     Database SG:        sg-0a1b2c3d4e5f6g7h8
     Webserver SG:       sg-9h8g7f6e5d4c3b2a1
```

**Was passiert:** Script liest die `deployment-info.json` Datei

---

#### 3. Ressourcen anzeigen

**Ausgabe:**
```
[PHASE 2/4] RESSOURCEN IDENTIFIZIEREN
=======================================================================

ACHTUNG: Folgende Ressourcen werden PERMANENT GELOESCHT:

+-----------------------------------------------------------------------+
| ZU LOESCHENDE RESSOURCEN                                              |
+-----------------------------------------------------------------------+
|   Database Instance:   i-0a1b2c3d4e5f6g7h8                            |
|   Webserver Instance:  i-9h8g7f6e5d4c3b2a1                            |
|   Database SG:         sg-0a1b2c3d4e5f6g7h8                           |
|   Webserver SG:        sg-9h8g7f6e5d4c3b2a1                           |
+-----------------------------------------------------------------------+

Fortfahren mit dem Loeschen? [ja/nein]:
```

**Was du tun musst:**
- Tippe **`ja`** (komplett ausschreiben!)
- Drücke **Enter**

**Falls du `nein` tippst:** Script bricht ab (nichts wird gelöscht)

**WICHTIG:** Du musst `ja` schreiben, nicht nur `j`!

---

#### 4. EC2-Instanzen terminieren

**Ausgabe:**
```
[PHASE 3/4] EC2-INSTANZEN TERMINIEREN
=======================================================================

   Terminiere Instanzen...
   Terminierung gestartet: i-0a1b2c3d4e5f6g7h8 i-9h8g7f6e5d4c3b2a1

   Warte bis Instanzen terminiert sind...
   INSTANZEN ERFOLGREICH TERMINIERT
```

**Was passiert:** 
- Beide EC2-Instanzen werden gestoppt
- Script wartet bis sie komplett terminiert sind

**Dauer:** 30-60 Sekunden

---

#### 5. Security Groups löschen

**Ausgabe:**
```
[PHASE 4/4] SECURITY GROUPS LOESCHEN
=======================================================================

   Warte 5 Sekunden damit AWS Ressourcen freigibt...

   Loesche Webserver Security Group...
   Webserver SG geloescht: sg-9h8g7f6e5d4c3b2a1
   Loesche Database Security Group...
   Database SG geloescht: sg-0a1b2c3d4e5f6g7h8
```

**Was passiert:** Beide Security Groups werden gelöscht

**Dauer:** 5-10 Sekunden

---

#### 6. Lokale Dateien (Optional)

**Ausgabe:**
```
[OPTIONAL] LOKALE DATEIEN AUFRAEUMEN
=======================================================================

Vorhandene Dateien:
   - deployment-info.json
   - cloud-init-database.yaml
   - cloud-init-webserver.yaml

Sollen diese Dateien auch geloescht werden? [ja/nein]:
```

**Was du tun musst - EINE VON ZWEI OPTIONEN:**

**Option 1:** Du willst die Dateien behalten (für später ansehen)
- Tippe `nein`
- Drücke Enter

**Option 2:** Du willst die Dateien löschen
- Tippe `ja`
- Drücke Enter

**Empfehlung:** `nein` - die Dateien enthalten nützliche Infos!

---

#### 7. Fertig

**Ausgabe:**
```
═══════════════════════════════════════════════════════════════════════
CLEANUP ERFOLGREICH ABGESCHLOSSEN
═══════════════════════════════════════════════════════════════════════

+-----------------------------------------------------------------------+
| GELOESCHTE RESSOURCEN                                                 |
+-----------------------------------------------------------------------+
|   Database Instance terminiert                                        |
|   Webserver Instance terminiert                                       |
|   Database Security Group geloescht                                   |
|   Webserver Security Group geloescht                                  |
+-----------------------------------------------------------------------+

TIPP:
   Ueberpruefe in der AWS Console, ob alle Ressourcen entfernt wurden:
   https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:

Cleanup abgeschlossen um 14:42:15
```

**PERFEKT! Alle AWS-Ressourcen sind gelöscht! ✅**

---

## Troubleshooting

### Problem 1: "AWS CLI not found"

**Fehlermeldung:**
```bash
bash: aws: command not found
```

**Ursache:** AWS CLI ist nicht installiert

**Lösung:**

**Wo:** In deinem Terminal

```bash
# AWS CLI installieren (Linux/WSL)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Erwartete Ausgabe:**
```
You can now run: /usr/local/bin/aws --version
```

**Prüfen:**
```bash
aws --version
```

**Sollte zeigen:**
```
aws-cli/2.15.10 ...
```

---

### Problem 2: "Deployment starten?" erscheint nicht

**Problem:** Script läuft nicht oder bricht sofort ab

**Ursache:** Script ist nicht ausführbar

**Lösung:**

**Wo:** In deinem Terminal, im Projekt-Verzeichnis

```bash
# Prüfe Berechtigungen
ls -la scripts/deploy.sh
```

**Erwartete Ausgabe:**
```
-rwxr-xr-x 1 user user 15432 Dec 14 10:00 scripts/deploy.sh
       ^^^
       └─ Diese x bedeuten "ausführbar"
```

**Falls KEIN x vorhanden:**
```
-rw-r--r-- 1 user user 15432 Dec 14 10:00 scripts/deploy.sh
      ^
      └─ Kein x = nicht ausführbar!
```

**Beheben:**
```bash
chmod +x scripts/deploy.sh
```

**Nochmal prüfen:**
```bash
ls -la scripts/deploy.sh
```

**Sollte jetzt x haben:**
```
-rwxr-xr-x ...
```

**Nochmal probieren:**
```bash
bash scripts/deploy.sh
```

---

### Problem 3: Nextcloud Setup-Assistent erscheint nicht

**Problem:** Browser zeigt "Site can't be reached" oder lädt endlos

**Ursache 1:** Nextcloud ist noch nicht fertig installiert

**Lösung 1:** Warte länger

**Wo:** In deinem Terminal

```bash
# Teste ob Webserver antwortet
curl http://XX.XX.XX.XX
```

**Ersetze XX.XX.XX.XX mit deiner Public IP!**

**Falls nicht bereit:**
```
curl: (7) Failed to connect to 54.162.154.237 port 80: Connection refused
```
→ **Warte noch 1-2 Minuten**, dann nochmal testen

**Falls bereit:**
```html
<!DOCTYPE html>
<html class="ng-csp" ...
```
→ **Nextcloud ist bereit!** Probiere nochmal im Browser

---

**Ursache 2:** Falsche IP-Adresse verwendet

**Lösung 2:** Prüfe die IP

**Wo:** In deinem Terminal

```bash
# Zeige alle Nextcloud-Instanzen
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=nextcloud-web" \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

**Erwartete Ausgabe:**
```
54.162.154.237
```

**Dies ist deine korrekte URL:** `http://54.162.154.237`

---

**Ursache 3:** AWS Security Group blockiert

**Lösung 3:** Prüfe Security Group

```bash
# Zeige Web Security Group
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=nextcloud-web-sg" \
  --region us-east-1
```

**Prüfe ob Port 80 offen ist:**
```json
"IpPermissions": [
  {
    "FromPort": 80,
    "IpProtocol": "tcp",
    "IpRanges": [
      {
        "CidrIp": "0.0.0.0/0"
      }
    ],
    "ToPort": 80
  }
]
```

**Falls Port 80 fehlt:** Deployment nochmal ausführen

---

### Problem 4: Datenbank-Verbindung fehlgeschlagen

**Fehlermeldung im Setup:** "Can't connect to MySQL server"

**Ursache 1:** Falsche Private IP verwendet

**Lösung 1:**

**WICHTIG:**
- ✅ Verwende **Private IP** (172.31.x.x)
- ❌ NICHT die Public IP!
- ❌ NICHT "localhost"!

**Wo findest du die Private IP:**
```bash
# In deinem Terminal, nach dem Deployment
# Oder prüfe mit:
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=nextcloud-db" \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
  --output text
```

**Erwartete Ausgabe:**
```
172.31.24.60
```

**Dies ist die korrekte Datenbank-Host IP!**

---

**Ursache 2:** Falsches Passwort

**Lösung 2:** Passwort nochmal kopieren

**WICHTIG:**
- Das Passwort ist **genau 24 Zeichen** lang
- **Groß-/Kleinschreibung** beachten!
- **Keine Leerzeichen** am Anfang/Ende!

**Wo findest du es:**
```bash
# Schaue in deployment-info.json
cat deployment-info.json | grep db_nextcloud_password
```

**Erwartete Ausgabe:**
```json
"db_nextcloud_password": "xY9mK2nL5pQ8rT1vW4zA7bC0"
```

**Kopiere es EXAKT!**

---

**Ursache 3:** Datenbank noch nicht bereit

**Lösung 3:** Warte länger

```bash
# Prüfe ob Database Server läuft
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=nextcloud-db" \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text
```

**Sollte zeigen:**
```
running
```

**Falls "pending":** Warte noch 1-2 Minuten

---

### Problem 5: "Data directory is not writable"

**Fehlermeldung:** Schreibfehler beim Datenverzeichnis

**Ursache:** Falsche Berechtigungen

**Lösung:**

**Wo:** SSH zum Webserver

```bash
# Verbinde dich zum Webserver
ssh -i vockey.pem ubuntu@XX.XX.XX.XX
```

**Ersetze XX.XX.XX.XX mit der Webserver Public IP!**

**Im SSH:**
```bash
# Prüfe Berechtigungen
ls -ld /var/nextcloud-data/
```

**Sollte zeigen:**
```
drwxr-xr-x 2 www-data www-data 4096 Dec 14 10:00 /var/nextcloud-data/
               ^^^^^^^^ ^^^^^^^^
               └─ Owner sollte www-data sein!
```

**Falls falsch:**
```bash
# Korrigiere Berechtigungen
sudo chown -R www-data:www-data /var/nextcloud-data/
sudo chmod 755 /var/nextcloud-data/
```

**Nochmal prüfen:**
```bash
ls -ld /var/nextcloud-data/
```

**Jetzt sollte es korrekt sein!**

**Verlasse SSH:**
```bash
exit
```

**Probiere Nextcloud-Setup nochmal im Browser**

---

### Problem 6: AWS Learner Lab Session abgelaufen

**Fehlermeldung:**
```
An error occurred (AuthFailure) when calling the DescribeInstances operation
```

**Ursache:** AWS Lab-Session ist abgelaufen (max. 4 Stunden)

**Lösung:**

**Wo:** In deinem Browser

1. **Gehe zu AWS Academy**
2. **Klicke "Start Lab"**
3. **Warte bis grüner Punkt**
4. **Klicke "AWS Details"**
5. **Kopiere neue Credentials**

**Wo:** In deinem Terminal

```bash
# Öffne Credentials-Datei
nano ~/.aws/credentials
```

**Lösche den alten [default] Block**  
**Füge neue Credentials ein**  
**Speichern:** Ctrl + O, Enter  
**Schließen:** Ctrl + X

**Teste:**
```bash
aws sts get-caller-identity
```

**Sollte funktionieren!**

**Jetzt:** Deployment nochmal starten

---

### Problem 7: Security Group already exists

**Fehlermeldung:**
```
A security group with the name 'nextcloud-web-sg' already exists
```

**Ursache:** Security Groups von altem Deployment existieren noch

**Lösung:**

**Wo:** In deinem Terminal

```bash
# Lösche alte Security Groups manuell
aws ec2 delete-security-group \
  --group-name nextcloud-web-sg \
  --region us-east-1

aws ec2 delete-security-group \
  --group-name nextcloud-db-sg \
  --region us-east-1
```

**Erwartete Ausgabe:** (keine Ausgabe = erfolgreich)

**Falls Fehler "DependencyViolation":**
```
An error occurred (DependencyViolation) when calling the DeleteSecurityGroup
```

**Bedeutet:** Instanzen verwenden noch die Security Groups

**Lösung:**
```bash
# Terminiere alte Instanzen zuerst
bash scripts/cleanup.sh

# Warte 1 Minute

# Nochmal probieren
aws ec2 delete-security-group --group-name nextcloud-web-sg --region us-east-1
aws ec2 delete-security-group --group-name nextcloud-db-sg --region us-east-1
```

**Jetzt:** Deployment nochmal starten

---

## Nützliche Befehle

### AWS-Ressourcen prüfen

**Alle Nextcloud-Instanzen anzeigen:**

**Wo:** In deinem Terminal

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=M346-Nextcloud" \
  --region us-east-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

**Erwartete Ausgabe:**
```
-----------------------------------------------------------------------
|                        DescribeInstances                            |
+---------------------+----------+----------------+-------------------+
|  i-0a1b2c3d4e5f6g7h8|  running |  None          |  nextcloud-db     |
|  i-9h8g7f6e5d4c3b2a1|  running |  54.162.154.237|  nextcloud-web    |
+---------------------+----------+----------------+-------------------+
```

---

**Security Groups anzeigen:**

```bash
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=nextcloud-*" \
  --region us-east-1 \
  --query 'SecurityGroups[*].[GroupId,GroupName]' \
  --output table
```

**Erwartete Ausgabe:**
```
------------------------------------------
|        DescribeSecurityGroups          |
+------------------------+----------------+
|  sg-0a1b2c3d4e5f6g7h8  |  nextcloud-db-sg   |
|  sg-9h8g7f6e5d4c3b2a1  |  nextcloud-web-sg  |
+------------------------+----------------+
```

---

### Server-Logs ansehen

**Webserver Console Output:**

**Wo:** In deinem Terminal

```bash
aws ec2 get-console-output \
  --instance-id i-XXXXXXXXX \
  --region us-east-1 \
  --output text > webserver.log
```

**Ersetze `i-XXXXXXXXX` mit deiner Webserver Instance ID!**

**Log-Datei öffnen:**
```bash
cat webserver.log
```

**Was du siehst:**
- Cloud-init Logs
- Apache Installation
- PHP Installation
- Nextcloud Download
- Fehler (falls welche aufgetreten sind)

---

### SSH-Zugriff

**Zum Webserver verbinden:**

**Wo:** In deinem Terminal

```bash
ssh -i vockey.pem ubuntu@XX.XX.XX.XX
```

**Ersetze XX.XX.XX.XX mit Webserver Public IP!**

**Erwartete Ausgabe:**
```
Welcome to Ubuntu 24.04 LTS
...
ubuntu@ip-172-31-24-61:~$
```

**Du bist jetzt auf dem Webserver!**

**Nützliche Befehle im SSH:**

```bash
# Apache-Status prüfen
sudo systemctl status apache2

# Nextcloud-Dateien anzeigen
ls -la /var/www/html/

# Apache-Logs anzeigen
sudo tail -f /var/log/apache2/error.log
```

**SSH verlassen:**
```bash
exit
```

---

### Deployment-Info anzeigen

**Wo:** In deinem Terminal, im Projekt-Verzeichnis

```bash
# JSON-Datei anzeigen
cat deployment-info.json
```

**Erwartete Ausgabe:**
```json
{
  "deployment_date": "2024-12-14 14:30:00 UTC",
  "region": "us-east-1",
  "database": {
    "instance_id": "i-0a1b2c3d4e5f6g7h8",
    "private_ip": "172.31.24.60",
    ...
  }
}
```

**Formatiert anzeigen (mit jq):**
```bash
cat deployment-info.json | jq .
```

---

## Support & Kontakt

**GitHub Repository:**  
https://github.com/seid950/m346-nextcloud-projekt

**Bei Problemen:**
1. Prüfe [Troubleshooting](#troubleshooting)
2. Schaue Logs an (siehe [Nützliche Befehle](#nützliche-befehle))
3. Erstelle ein GitHub Issue

**Team:**
- Seid Veseli (Projektleiter)
- Amar Ibraimi
- Leandro Graf

---

## Weitere Dokumentation

- **DOKUMENTATION.md** - Vollständige Projekt-Dokumentation
  - Einleitung & Projektziele
  - Projektplanung & Zeitmanagement
  - System-Architektur
  - Deployment-Prozess
  - Tests & Validierung
  - Aufgabenverteilung
  - Reflexion
  - Quellen

---

**Viel Erfolg mit Nextcloud! 🚀**
