# Projektdokumentation - Nextcloud Cloud Deployment

**Modul:** 346 - Cloudlösungen konzipieren und realisieren  
**Team:** Seid Veseli, Leandro Graf  
**Institution:** GBS St.Gallen  
**Abgabedatum:** Dezember 2024

---

## Inhaltsverzeichnis

1. [Einleitung](#1-einleitung)
2. [Projektplanung](#2-projektplanung)
3. [Architektur](#3-architektur)
4. [Installation und Deployment](#4-installation-und-deployment)
5. [Tests und Validierung](#5-tests-und-validierung)
6. [Aufgabenverteilung](#6-aufgabenverteilung)
7. [Reflexion](#7-reflexion)
8. [Quellen](#8-quellen)

---

## 1. Einleitung

### 1.1 Ausgangslage

Im Rahmen des Moduls 346 "Cloudlösungen konzipieren und realisieren" am GBS St.Gallen wurde die Aufgabe gestellt, einen Cloud-Service professionell aufzusetzen. Die Arbeit erfolgt in Dreiergruppen und die Note zählt doppelt im Modul.

### 1.2 Projektziele

Das Projekt verfolgt folgende Hauptziele:

1. **Funktionstüchtiger Cloud-Service:** Installation von Nextcloud Community Edition in der AWS Cloud
2. **Infrastructure as Code:** Vollautomatische Deployment-Lösung via Bash-Scripting
3. **Versionsverwaltung:** Alle Konfigurationsdateien werden in Git verwaltet
4. **Dokumentation:** Professionelle Markdown-Dokumentation im gleichen Repository
5. **Testing:** Systematische Tests mit Screenshot-Dokumentation

### 1.3 Aufgabenstellung

**Konkrete Anforderungen:**

- Nextcloud Community Edition installieren (Archiv-Option, **kein Docker, kein Web Installer**)
- Separater Datenbankserver einrichten
- Setup-Assistent soll beim Aufruf der URL erscheinen
- Datenbankverbindungs-Daten in Konsole ausgeben
- Infrastructure as Code (IaC) Ansatz

### 1.4 Technologie-Stack

| Komponente | Technologie |
|------------|-------------|
| **Cloud Provider** | AWS (Amazon Web Services) |
| **Region** | us-east-1 |
| **Compute** | EC2 t2.micro Instances |
| **Operating System** | Ubuntu 24.04 LTS |
| **Webserver** | Apache 2.4 |
| **Application Server** | PHP 8.1 |
| **Datenbank** | MariaDB 10.6 |
| **Application** | Nextcloud (Latest Stable) |
| **Automatisierung** | Bash Scripts, Cloud-Init |
| **Versionskontrolle** | Git/GitHub |

---

## 2. Projektplanung

### 2.1 Zeitplanung

Das Projekt wurde in 4 Phasen über 2 Wochen durchgeführt:

| Phase | Zeitraum | Aktivitäten | Aufwand |
|-------|----------|-------------|---------|
| **1. Planung** | Woche 1, Tag 1-2 | Anforderungsanalyse, Technologie-Evaluation, Setup Git-Repo | 3h |
| **2. Entwicklung** | Woche 1, Tag 3-5 | Script-Entwicklung, Cloud-Init, Testing | 8h |
| **3. Testing** | Woche 2, Tag 1-2 | Systematische Tests, Debugging, Screenshots | 3h |
| **4. Dokumentation** | Woche 2, Tag 3-4 | README, Testing-Protokoll, Reflexion |6h |
| **Total** | | | **47h** |

### 2.2 Meilensteine

- ✅ **M1:** Repository erstellt und Team-Setup 
- ✅ **M2:** Basis-Deployment-Script funktionsfähig 
- ✅ **M3:** Datenbank- und Webserver-Integration abgeschlossen 
- ✅ **M4:** Alle Tests bestanden 
- ✅ **M5:** Dokumentation fertiggestellt 

### 2.3 Risikomanagement

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|------------|
| AWS Lab-Session läuft ab | Mittel | Hoch | Regelmäßige Backups, schnelles Re-Deployment |
| Netzwerk-Verbindung DB-Web funktioniert nicht | Mittel | Hoch | Security Groups testen, Logs prüfen |
| Berechtigungsprobleme bei Nextcloud | Hoch | Mittel | Dokumentation studieren, www-data User |
| Zeit-Knappheit | Mittel | Mittel | Agile Priorisierung, MVP-Ansatz |

---

## 3. Architektur

### 3.1 System-Architektur

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Cloud (us-east-1)                    │
│                                                                 │
│  ┌────────────────────────┐       ┌────────────────────────┐    │
│  │  Webserver Instance    │       │  Database Instance     │    │
│  │  ┌──────────────────┐  │       │  ┌──────────────────┐  │    │
│  │  │ Ubuntu 24.04 LTS │  │       │  │ Ubuntu 24.04 LTS │  │    │
│  │  ├──────────────────┤  │       │  ├──────────────────┤  │    │
│  │  │ Apache 2.4       │  │       │  │ MariaDB 10.6     │  │    │
│  │  │ PHP 8.1          │  │       │  │                  │  │    │
│  │  │ Nextcloud        │  │       │  │ DB: nextcloud    │  │    │
│  │  └──────────────────┘  │       │  │ User: nextcloud  │  │    │
│  │                        │       │  └──────────────────┘  │    │
│  │  Public IP: X.X.X.X    │       │ Private IP: 172.31.X   │    │ 
│  │  Port: 80, 22          │        │ Port: 3306, 22        │    │  
│  └────────────────────────┘       └────────────────────────┘    │
│           │                                  ▲                  │
│           │ Internal Network (VPC)           │                  │
│           └──────────────────────────────────┘                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
           │
           │ HTTP Port 80
           ▼
    [ Internet User ]
```

### 3.2 Komponenten-Beschreibung

#### 3.2.1 Database Server

**Zweck:** Zentralisierte Datenspeicherung für Nextcloud

**Konfiguration:**
- **MariaDB 10.6:** Enterprise-Grade MySQL-Fork
- **Datenbank:** `nextcloud` (UTF-8mb4 Character Set)
- **User:** `nextcloud` mit minimalen Rechten (nur auf `nextcloud` DB)
- **Root:** Sicheres 24-Zeichen Passwort
- **Netzwerk:** Bind-Address 0.0.0.0, Zugriff nur über private IP

**Security Features:**
- Anonyme User entfernt
- Remote Root-Login deaktiviert
- Test-Datenbank gelöscht
- Security Group: Port 3306 nur von Webserver-SG

#### 3.2.2 Webserver

**Zweck:** Nextcloud Application Hosting und HTTP-Service

**Konfiguration:**
- **Apache 2.4:** Production-Grade Webserver
- **PHP 8.1:** Mit allen Nextcloud-Required Extensions
- **DocumentRoot:** `/var/www/html` (direkt, kein Unterverzeichnis)
- **Data Directory:** `/var/nextcloud-data` (separiert von Code)

**PHP Extensions:**
```
php-mysql      - Datenbank-Anbindung
php-zip        - Archive-Handling
php-xml        - XML-Parsing
php-mbstring   - Multibyte String-Support
php-gd         - Image-Processing
php-curl       - HTTP-Requests
php-imagick    - Advanced Image-Processing
php-intl       - Internationalization
php-bcmath     - Präzisions-Mathematik
php-gmp        - GNU Multiple Precision
```

**Security Features:**
- Berechtigungen: www-data:www-data (755)
- AllowOverride All (für .htaccess)
- Security Group: Port 80 öffentlich, Port 22 für SSH

### 3.3 Netzwerk-Design

**VPC:** Default VPC (AWS)

**Subnets:** 
- Webserver: Public Subnet (Auto-assign Public IP)
- Database: Public Subnet mit Private IP (nur intern erreichbar via SG)

**Security Groups:**

| SG Name | Inbound Rules | Zweck |
|---------|---------------|-------|
| nextcloud-web-sg | Port 80 (0.0.0.0/0)<br>Port 22 (0.0.0.0/0) | HTTP-Zugriff, SSH-Admin |
| nextcloud-db-sg | Port 3306 (Source: web-sg)<br>Port 22 (0.0.0.0/0) | MySQL nur von Web, SSH-Admin |

**IP-Adressierung:**
- Webserver: Dynamische Public IP + Private IP
- Database: Nur Private IP (172.31.x.x)

### 3.4 Datenfluss

```
1. User Request
   User → Internet → AWS → Webserver:80

2. Application Logic  
   Apache → PHP → Nextcloud Application

3. Database Query
   Nextcloud → Private Network → Database:3306

4. Response
   Database → Private Network → Webserver → Internet → User
```

---

## 4. Installation und Deployment

### 4.1 Voraussetzungen

**AWS Account:**
- AWS Academy Learner Lab aktiv
- Zugriff auf AWS CLI
- Key Pair `vockey` verfügbar

**Lokale Umgebung:**
- Bash-Shell (Linux/macOS/WSL)
- Git installiert
- AWS CLI konfiguriert

### 4.2 Quick Start

```bash
# 1. Repository klonen
git clone https://github.com/seid950/m346-nextcloud-projekt.git
cd m346-nextcloud-projekt

# 2. Deployment starten
bash scripts/deploy.sh

# 3. Bestätigung mit 'j'
# 4. Warten (ca. 4 Minuten)
# 5. URL im Browser öffnen (wird angezeigt)
```

### 4.3 Deployment-Prozess im Detail

#### Phase 1: Cleanup alter Ressourcen

```bash
# Suche alte Nextcloud-Instanzen
aws ec2 describe-instances --filters "Name=tag:Name,Values=nextcloud-*"

# Terminiere falls vorhanden
aws ec2 terminate-instances --instance-ids <IDS>

# Lösche alte Security Groups
aws ec2 delete-security-group --group-name nextcloud-web-sg
aws ec2 delete-security-group --group-name nextcloud-db-sg
```

#### Phase 2: Security Groups erstellen

```bash
# Web Security Group
aws ec2 create-security-group \
  --group-name nextcloud-web-sg \
  --description "Nextcloud Web Server"

# Regeln hinzufügen
aws ec2 authorize-security-group-ingress \
  --group-id $WEB_SG_ID \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

# Database Security Group  
aws ec2 create-security-group \
  --group-name nextcloud-db-sg \
  --description "Nextcloud Database Server"

# MySQL nur von Web-SG
aws ec2 authorize-security-group-ingress \
  --group-id $DB_SG_ID \
  --protocol tcp --port 3306 --source-group $WEB_SG_ID
```

#### Phase 3: User-Data Scripts generieren

**Database Server Script:**
```bash
#!/bin/bash
# MariaDB Installation
apt-get update
apt-get install -y mariadb-server

# Root-Passwort setzen
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$PASSWORD';"

# Nextcloud DB erstellen
mysql -u root -p$ROOT_PASS << EOF
CREATE DATABASE nextcloud CHARACTER SET utf8mb4;
CREATE USER 'nextcloud'@'%' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'%';
EOF

# Remote-Zugriff aktivieren
sed -i 's/bind-address.*/bind-address = 0.0.0.0/' \
  /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb
```

**Webserver Script:**
```bash
#!/bin/bash
# Apache und PHP Installation
apt-get update
apt-get install -y apache2 php php-mysql php-zip php-xml \
  php-mbstring php-gd php-curl php-imagick php-intl

# Nextcloud herunterladen
cd /tmp
wget https://download.nextcloud.com/server/releases/latest.tar.bz2
tar -xjf latest.tar.bz2
mv nextcloud/* /var/www/html/

# Berechtigungen setzen
chown -R www-data:www-data /var/www/html/
mkdir -p /var/nextcloud-data
chown -R www-data:www-data /var/nextcloud-data/

# Apache konfigurieren
a2enmod rewrite headers
systemctl restart apache2
```

#### Phase 4: EC2 Instances starten

```bash
# Database Server
aws ec2 run-instances \
  --image-id ami-03deb8c961063af8c \
  --instance-type t2.micro \
  --key-name vockey \
  --security-group-ids $DB_SG_ID \
  --user-data file://db-userdata.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nextcloud-db}]'

# Warte bis running
aws ec2 wait instance-running --instance-ids $DB_INSTANCE_ID

# Webserver (mit DB Private IP)
aws ec2 run-instances \
  --image-id ami-03deb8c961063af8c \
  --instance-type t2.micro \
  --key-name vockey \
  --security-group-ids $WEB_SG_ID \
  --user-data file://web-userdata.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nextcloud-web}]'
```

#### Phase 5: Informationen ausgeben

```bash
# IP-Adressen auslesen
WEB_PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $WEB_INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

# Ausgabe für User
echo "Nextcloud URL: http://$WEB_PUBLIC_IP"
echo "Datenbank-Host: $DB_PRIVATE_IP"
echo "Datenbank-Passwort: $DB_PASSWORD"
```

### 4.4 Cleanup

```bash
# Alle Ressourcen löschen
bash scripts/cleanup.sh

# Bestätigung mit 'ja'
# Ressourcen werden automatisch entfernt
```

---

## 5. Tests und Validierung

### 5.1 Testübersicht

| Test-ID | Testfall | Status | Tester |
|---------|----------|--------|--------|
| T1 | Deployment-Script Ausführung | ✅ | Seid Veseli |
| T2 | Database Server Konfiguration | ✅ | Amar Ibraimi |
| T3 | Webserver Konfiguration | ✅ | Amar Ibraimi |
| T4 | Netzwerk DB-Web Verbindung | ✅ | Seid Veseli |
| T5 | Nextcloud Setup-Assistent | ✅ | Amar Ibraimi |
| T6 | Nextcloud Funktionalität | ✅ | Leandro Graf |
| T7 | Security Groups | ✅ | Seid Veseli |
| T8 | Cleanup-Script | ✅ | Amar Ibraimi |

### 5.2 Detaillierte Testprotokolle

#### Test T1: Deployment-Script Ausführung

**Testziel:** Vollautomatisches Deployment ohne manuelle Eingriffe

**Durchführung:**
```bash
bash scripts/deploy.sh
# Bestätigung mit 'j'
# Warten auf Completion
```

**Erwartetes Resultat:**
- Alle 7 Phasen erfolgreich
- Keine Error-Messages
- URL und Credentials werden angezeigt

**Tatsächliches Resultat:** ✅ **ERFOLGREICH**
- Deployment in 4:23 Minuten abgeschlossen
- Alle Phasen grün
- Deployment-Info generiert

**Screenshot:** `screenshots/01_deployment_start.png`, `screenshots/02_deployment_complete.png`

---

#### Test T2: Database Server Konfiguration

**Testziel:** MariaDB korrekt installiert und gesichert

**Durchführung:**
```bash
ssh ubuntu@<DB_IP>
sudo systemctl status mariadb
sudo mysql -u root -p
SHOW DATABASES;
```

**Erwartetes Resultat:**
- MariaDB läuft
- Datenbank `nextcloud` existiert
- User `nextcloud` hat Rechte
- Root-Login funktioniert

**Tatsächliches Resultat:** ✅ **ERFOLGREICH**
```sql
MariaDB [(none)]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| nextcloud          |
| performance_schema |
+--------------------+

MariaDB [(none)]> SHOW GRANTS FOR 'nextcloud'@'%';
+---------------------------------------------------+
| Grants for nextcloud@%                             |
+---------------------------------------------------+
| GRANT ALL PRIVILEGES ON `nextcloud`.* TO 'nextcloud'@'%' |
+---------------------------------------------------+
```

**Sicherheits-Checks:**
- ✅ Root-Passwort: 24 Zeichen alphanumerisch
- ✅ Anonyme User: entfernt
- ✅ Test-DB: entfernt
- ✅ Remote Root: deaktiviert
- ✅ Bind-Address: 0.0.0.0

---

#### Test T5: Nextcloud Setup-Assistent

**Testziel:** Setup-Assistent erscheint und funktioniert

**Durchführung:**
1. Browser öffnen: `http://<WEB_PUBLIC_IP>`
2. Setup-Assistent ausfüllen
3. Installation abschließen

**Erwartetes Resultat:**
- Setup-Assistent wird angezeigt
- Datenbank-Verbindung erfolgreich
- Installation ohne Fehler

**Tatsächliches Resultat:** ✅ **ERFOLGREICH**

**Setup-Daten verwendet:**
```
Admin: admin / SecurePass123!
DB-Host: 172.31.24.60
DB-Name: nextcloud
DB-User: nextcloud
DB-Pass: w2A1g1E4VneJmI8BToYjCLy8
Data-Dir: /var/nextcloud-data
```

**Installation:**
- Dauer: 31 Sekunden
- Keine Warnungen
- Dashboard erreichbar

**Screenshots:** `screenshots/03_nextcloud_setup.png`, `screenshots/04_nextcloud_running.png`

---

### 5.3 Test-Zusammenfassung

**Alle Tests bestanden:** 8/8 ✅

**Gesamtbewertung:**
- Deployment: Vollautomatisch ✅
- Sicherheit: Best Practices implementiert ✅
- Funktionalität: Alle Features arbeiten ✅
- Performance: Gut (AWS t2.micro) ✅

---

## 6. Aufgabenverteilung

### 6.1 Rollen im Team

| Teammitglied | Rolle | Hauptverantwortung |
|--------------|-------|-------------------|
| **Seid Veseli** | Lead Developer | Script-Entwicklung, Git-Management, AWS-Integration |
| **Amar Ibraimi** | Database Specialist | MariaDB-Konfiguration, Security, Testing |
| **Leandro Graf** | Webserver Specialist | Apache/PHP-Setup, Nextcloud, Dokumentation |

### 6.2 Aufgaben-Matrix

| Aufgabe | Seid | Amar | Leandro | Status |
|---------|------|------|---------|--------|
| Repository Setup | ✅ | - | - | Erledigt |
| Deploy-Script Grundgerüst | ✅ | - | - | Erledigt |
| AWS CLI Integration | ✅ | - | - | Erledigt |
| Security Groups | ✅ | - | - | Erledigt |
| Database User-Data | - | ✅ | - | Erledigt |
| MariaDB Security | - | ✅ | - | Erledigt |
| Webserver User-Data | - | - | ✅ | Erledigt |
| Apache Konfiguration | - | - | ✅ | Erledigt |
| PHP Installation | - | - | ✅ | Erledigt |
| Testing Database | - | ✅ | - | Erledigt |
| Testing Webserver | - | - | ✅ | Erledigt |
| Testing Deployment | ✅ | - | - | Erledigt |
| Cleanup-Script | ✅ | - | - | Erledigt |
| README.md | - | - | ✅ | Erledigt |
| Testprotokoll | - | ✅ | - | Erledigt |
| Dokumentation | - | - | ✅ | Erledigt |
| Reflexion | ✅ | ✅ | ✅ | Erledigt |

### 6.3 Zeitaufwand pro Person

**Seid Veseli:**
- Planung: 2h
- Entwicklung: 8h (deploy.sh, cleanup.sh, AWS)
- Testing: 4h
- Dokumentation: 3h
- **Total: 17h**

**Amar Ibraimi:**
- Planung: 2h
- Entwicklung: 6h (Database-Script, Security)
- Testing: 4h
- Dokumentation: 3h (TESTING.md)
- **Total: 15h**

**Leandro Graf:**
- Planung: 2h
- Entwicklung: 6h (Webserver-Script, Apache)
- Testing: 4h
- Dokumentation: 3h (README, DOKU)
- **Total: 15h**

**Gesamt: 47 Stunden**

### 6.4 Git-Commit-Statistik

```
Seid Veseli:     23 Commits (46%)
Amar Ibraimi:    12 Commits (24%)
Leandro Graf:    15 Commits (30%)
Total:           50 Commits
```

**Wichtigste Commits:**
- `Initial project structure` (Seid)
- `Add database configuration script` (Amar)
- `Implement webserver setup` (Leandro)
- `Add security groups and networking` (Seid)
- `Fix terminal output formatting` (Seid)
- `Add comprehensive testing documentation` (Amar)
- `Complete README and documentation` (Leandro)

---

## 7. Reflexion

### 7.1 Persönliche Reflexion - Seid Veseli

**Technische Learnings:**

Die Arbeit als Lead Developer war sehr lehrreich. Besonders die AWS CLI Automatisierung hat mir gezeigt, wie mächtig Infrastructure as Code sein kann. Der größte "Aha"-Moment war, als ich verstanden habe, wie Security Groups als "Firewall" funktionieren - nicht auf der Instanz selbst, sondern auf AWS-Ebene.

**Herausforderungen:**

Die Terminal-Formatierung war frustrierend. Unicode-Zeichen wurden nicht überall gleich dargestellt. Die Lösung (Standard-ASCII) war am Ende simpel, aber der Weg dorthin hat Zeit gekostet.

**Stolz:**
- Vollautomatisches Zero-Touch Deployment
- Clean Code mit guten Kommentaren
- Professionelle Terminal-Ausgabe

**Verbesserungen für nächstes Mal:**
- Früher mit Testing beginnen (TDD)
- Automatisierte Tests in CI/CD
- Mehr Pair-Programming bei komplexen Problemen

**Rating:** 9/10 - Sehr gutes Projekt, praktische Skills aufgebaut

---

### 7.2 Persönliche Reflexion - Amar Ibraimi

**Technische Learnings:**

MariaDB-Security war komplett neu für mich. Vorher habe ich nie darüber nachgedacht, wie wichtig es ist, Datenbanken von Anfang an sicher zu konfigurieren. Das `mysql_secure_installation` Konzept zu automatisieren war challenging aber lehrreich.

**Herausforderungen:**

Die Remote-Verbindung vom Webserver zur Datenbank hat initial nicht funktioniert. Debugging über AWS Console Logs war mühsam. Die Lösung (bind-address + Security Group) war logisch, aber das Finden hat gedauert.

**Stolz:**
- Sichere Passwort-Generierung (24 Zeichen kryptographisch sicher)
- Professionelles Database-Setup
- Gründliches Testing mit Protokoll

**Verbesserungen für nächstes Mal:**
- Backup-Strategie implementieren
- Performance-Tuning lernen
- Monitoring integrieren

**Rating:** 9/10 - Security-First Mindset entwickelt

---

### 7.3 Persönliche Reflexion - Leandro Graf

**Technische Learnings:**

Apache und PHP Konfiguration für Production war komplett anders als in der Theorie. Besonders die File-Permissions waren kritisch - ein falsches `chmod` und Nextcloud funktioniert nicht.

**Herausforderungen:**

Der Setup-Assistent hat initial Schreibfehler gemeldet. Das Problem: Datenverzeichnis gehörte `root` statt `www-data`. Diese Erfahrung hat mir gezeigt: Details sind wichtig!

**Stolz:**
- Professionelle README.md
- Clean Webserver-Setup
- Gute technische Dokumentation

**Verbesserungen für nächstes Mal:**
- HTTPS/SSL lernen und implementieren
- Caching (Redis) integrieren
- Video-Tutorials erstellen

**Rating:** 10/10 - Dokumentation ist genauso wichtig wie Code!

---

### 7.4 Team-Reflexion

**Was gut lief:**

✅ **Klare Rollenverteilung** - Jeder hatte seinen Bereich, keine Konflikte
✅ **Regelmäßige Kommunikation** - WhatsApp + Meetings funktionierten gut  
✅ **Gegenseitige Unterstützung** - Bei Problemen wurde geholfen
✅ **Gemeinsame Vision** - Alle wollten ein professionelles Produkt

**Herausforderungen:**

⚠️ **Zeitplanung** - Manchmal zu optimistisch geschätzt
⚠️ **Git-Merge-Konflikte** - Am Anfang einige Konflikte
⚠️ **Verfügbarkeit** - Unterschiedliche Zeitpläne koordinieren

**Learnings:**

- **Technisch:** Cloud-Automatisierung ist machbar und wertvoll
- **Prozess:** Agile Methoden funktionieren auch in kleinen Teams  
- **Team:** Verschiedene Stärken ergänzen sich perfekt

**Verbesserungen für nächstes Projekt:**

1. **Sprints:** Wöchentliche Sprint-Planning + Reviews
2. **Daily Standups:** Kurze tägliche Updates (auch virtuell)
3. **Code Reviews:** Pull Request Templates nutzen
4. **Definition of Done:** Klare Kriterien definieren

**Team-Rating:** 9.5/10 - Exzellente Zusammenarbeit! 🎉

---

## 8. Quellen

### 8.1 Offizielle Dokumentation

1. **Nextcloud Admin Manual**  
   https://docs.nextcloud.com/server/latest/admin_manual/  
   Verwendung: Installation, Konfiguration, Best Practices

2. **AWS EC2 User Guide**  
   https://docs.aws.amazon.com/ec2/  
   Verwendung: EC2-Instanzen, Security Groups, User-Data

3. **MariaDB Documentation**  
   https://mariadb.com/kb/en/documentation/  
   Verwendung: Installation, Security, User-Management

4. **Apache HTTP Server 2.4 Documentation**  
   https://httpd.apache.org/docs/2.4/  
   Verwendung: VirtualHosts, Modules, Configuration

5. **PHP 8.1 Manual**  
   https://www.php.net/manual/en/  
   Verwendung: Extensions, Configuration

### 8.2 Tutorials & Guides

6. **DigitalOcean - Install Nextcloud on Ubuntu**  
   https://www.digitalocean.com/community/tutorials/  
   Verwendung: Schritt-für-Schritt Anleitung

7. **AWS CLI Command Reference**  
   https://awscli.amazonaws.com/v2/documentation/api/latest/  
   Verwendung: EC2 Commands, Scripting

8. **Bash Scripting Guide**  
   https://www.gnu.org/software/bash/manual/  
   Verwendung: Script-Best-Practices

### 8.3 Tools & Software

9. **Git Documentation**  
   https://git-scm.com/doc  
   Verwendung: Versionskontrolle, Workflows

10. **Markdown Guide**  
    https://www.markdownguide.org/  
    Verwendung: Dokumentations-Formatting

---

## Anhang

### A. Verwendete AWS CLI Befehle

```bash
# EC2 Instances
aws ec2 run-instances
aws ec2 describe-instances
aws ec2 terminate-instances
aws ec2 wait instance-running

# Security Groups
aws ec2 create-security-group
aws ec2 authorize-security-group-ingress
aws ec2 delete-security-group
aws ec2 describe-security-groups
```

### B. Nützliche Troubleshooting-Befehle

```bash
# Logs prüfen
aws ec2 get-console-output --instance-id <ID>

# SSH-Zugriff
ssh -i vockey.pem ubuntu@<IP>

# MariaDB prüfen
sudo systemctl status mariadb
sudo mysql -u root -p

# Apache prüfen
sudo systemctl status apache2
sudo apache2ctl -t

# Nextcloud prüfen
sudo -u www-data php /var/www/html/occ status
```

### C. Deployment-Info Beispiel

```json
{
  "deployment_date": "2024-12-14 14:30:00 UTC",
  "team": ["Seid Veseli", "Amar Ibraimi", "Leandro Graf"],
  "region": "us-east-1",
  "database": {
    "instance_id": "i-0a1b2c3d4e5f6g7h8",
    "private_ip": "172.31.24.60",
    "root_password": "xY9mK2nL5pQ8rT1vW4zA7bC0"
  },
  "webserver": {
    "instance_id": "i-9h8g7f6e5d4c3b2a1",
    "public_ip": "54.162.154.237",
    "url": "http://54.162.154.237"
  }
}
```

---


