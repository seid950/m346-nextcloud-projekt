# Test-Dokumentation

## Testumgebung Vorlage Alles hier drin sind Platzhalter

- **Datum:** 09.12.2024
- **AWS Region:** us-east-1
- **Nextcloud Version:** 28.0.1
- **Tester:** Seid Veseli, Amar Ibraimi, Leandro Graf

---

## Test 1: AWS CLI Konfiguration

**Testziel:** Überprüfen ob AWS CLI korrekt konfiguriert ist

**Durchführung:**
```bash
aws --version
aws sts get-caller-identity
```

**Erwartetes Ergebnis:**
```
{
    "UserId": "AROA...",
    "Account": "123456789",
    "Arn": "arn:aws:sts::..."
}
```

**Tester:** Seid Veseli  
**Zeitpunkt:** 09.12.2024, 14:15 Uhr  
**Status:** ✅ ERFOLGREICH

**Fazit:** AWS CLI korrekt installiert und mit Academy-Credentials konfiguriert.

---

## Test 2: Deployment-Script Ausführung

**Testziel:** Überprüfen ob deploy.sh ohne Fehler durchläuft

**Durchführung:**
```bash
bash deploy.sh
```

**Screenshot:**
![Deployment Terminal](../img/01_deployment_terminal.png)

**Erwartetes Ergebnis:**
- ✅ Alle Schritte durchlaufen ([1/8] bis [8/8])
- ✅ Keine Error-Messages
- ✅ Beide Instance IDs ausgegeben
- ✅ IP-Adressen angezeigt
- ✅ Datenbank-Credentials angezeigt

**Tatsächliches Ergebnis:**
```
========================================
   DEPLOYMENT ERFOLGREICH!
========================================

Database Server:
  Instance ID:  i-0b787e75a71e4498e
  Private IP:   172.31.30.69

Web Server:
  Instance ID:  i-06ce3a3c3bd95e9c6
  Public IP:    52.90.54.109

NEXTCLOUD URL: http://52.90.54.109
```

**Tester:** Seid Veseli, Amar Ibraimi  
**Zeitpunkt:** 09.12.2024, 14:20 Uhr  
**Status:** ✅ ERFOLGREICH

**Fazit:** Deployment läuft vollautomatisch durch. Beide Server wurden erfolgreich erstellt. Gesamtdauer: ~4 Minuten.

---

## Test 3: Generierte Konfigurationsdateien

**Testziel:** Überprüfen ob Cloud-Init YAMLs und deployment-info.json erstellt wurden

**Durchführung:**
```bash
ls -la
cat cloud-init-database.yaml
cat cloud-init-webserver.yaml
cat deployment-info.json
```

**Screenshot:**
![Generierte Dateien](../img/02_generated_files.png)

**Erwartetes Ergebnis:**
- ✅ cloud-init-database.yaml existiert
- ✅ cloud-init-webserver.yaml existiert
- ✅ deployment-info.json existiert
- ✅ Alle Dateien enthalten korrekte Konfiguration

**Tester:** Leandro Graf  
**Zeitpunkt:** 09.12.2024, 14:25 Uhr  
**Status:** ✅ ERFOLGREICH

**Fazit:** Alle Konfigurationsdateien wurden automatisch generiert und enthalten valide Syntax. Passwörter sind sicher generiert (24 Zeichen).

---

## Test 4: AWS EC2 Instanzen

**Testziel:** Überprüfen ob beide EC2-Instanzen in AWS Console sichtbar sind

**Durchführung:**
1. AWS Console öffnen
2. EC2 → Instances aufrufen
3. Nach Tag "Project: M346-Nextcloud" filtern

**Screenshot:**
![AWS EC2 Instances](../img/03_aws_instances.png)

**Erwartetes Ergebnis:**
- ✅ 2 Instanzen mit Status "Running"
- ✅ Tags korrekt gesetzt
- ✅ Security Groups zugewiesen
- ✅ Public/Private IPs vorhanden

**Tatsächliches Ergebnis:**
| Name | Instance ID | Status | Public IP | Private IP |
|------|-------------|--------|-----------|------------|
| nextcloud-webserver | i-06ce3a3c3bd95e9c6 | Running | 52.90.54.109 | 172.31.x.x |
| nextcloud-database | i-0b787e75a71e4498e | Running | - | 172.31.30.69 |

**Tester:** Amar Ibraimi  
**Zeitpunkt:** 09.12.2024, 14:28 Uhr  
**Status:** ✅ ERFOLGREICH

**Fazit:** Beide Instanzen laufen korrekt. Webserver hat Public IP, DB-Server nur Private IP (wie gewünscht).

---

## Test 5: Security Groups

**Testziel:** Überprüfen ob Security Groups korrekt konfiguriert sind

**Durchführung:**
```bash
aws ec2 describe-security-groups --group-names nextcloud-web-sg nextcloud-db-sg
```

**Screenshot:**
![Security Groups](../img/04_security_groups.png)

**Erwartetes Ergebnis:**

**nextcloud-web-sg:**
- Port 80 (HTTP) von 0.0.0.0/0
- Port 22 (SSH) von 0.0.0.0/0

**nextcloud-db-sg:**
- Port 3306 (MySQL) von nextcloud-web-sg
- Port 22 (SSH) von 0.0.0.0/0

**Tester:** Seid Veseli  
**Zeitpunkt:** 09.12.2024, 14:30 Uhr  
**Status:** ✅ ERFOLGREICH

**Fazit:** Security Groups sind korrekt konfiguriert. Datenbank ist nur vom Webserver erreichbar (nicht öffentlich).

---

## Test 6: Datenbank-Verbindung vom Webserver

**Testziel:** Überprüfen ob Webserver sich mit Datenbank verbinden kann

**Durchführung:**
```bash
ssh -i vockey.pem ubuntu@52.90.54.109
mysql -h 172.31.30.69 -u nextcloud -p
# Passwort: Kx7mNp2qR8vW4jL9sT3h
SHOW DATABASES;
USE nextcloud;
SHOW TABLES;
```

**Screenshot:**
![Database Connection](../img/05_database_connection.png)

**Erwartetes Ergebnis:**
```
+--------------------+
| Database           |
+--------------------+
| information_schema |
| nextcloud          |
+--------------------+
```

**Tester:** Amar Ibraimi  
**Zeitpunkt:** 09.12.2024, 14:35 Uhr  
**Status:** ✅ ERFOLGREICH

**Fazit:** Datenbankverbindung funktioniert einwandfrei. nextcloud-User hat Zugriff auf nextcloud-Datenbank.

---

## Test 7: Nextcloud Setup-Assistent erreichbar

**Testziel:** Überprüfen ob Nextcloud-Setup-Assistent im Browser lädt

**Durchführung:**
1. Browser öffnen (Chrome)
2. URL eingeben: http://52.90.54.109
3. Warten (~10 Sekunden)

**Screenshot:**
![Nextcloud Setup](../img/06_nextcloud_setup.png)

**Erwartetes Ergebnis:**
- ✅ Setup-Assistent wird angezeigt
- ✅ Felder für Admin-Account sichtbar
- ✅ Datenbank-Konfiguration sichtbar
- ✅ Keine PHP-Errors

**Tester:** Leandro Graf  
**Zeitpunkt:** 09.12.2024, 14:40 Uhr  
**Status:** ✅ ERFOLGREICH

**Fazit:** Nextcloud lädt korrekt. Apache und PHP funktionieren. Setup-Assistent ist vollständig sichtbar.

---

## Test 8: Nextcloud Installation abschließen

**Testziel:** Nextcloud vollständig installieren und testen

**Durchführung:**
1. Admin-Account erstellen:
   - Username: `admin`
   - Password: `SecureAdmin2024!`
2. Datenverzeichnis: `/var/nextcloud-data`
3. Datenbank konfigurieren:
   - Typ: MySQL/MariaDB
   - Host: `172.31.30.69`
   - Database: `nextcloud`
   - User: `nextcloud`
   - Password: `Kx7mNp2qR8vW4jL9sT3h`
4. "Installation abschließen" klicken

**Screenshot:**
![Nextcloud Installation](../img/07_nextcloud_installing.png)

**Erwartetes Ergebnis:**
- ✅ Installation läuft ohne Fehler
- ✅ Nach 1-2 Minuten: Dashboard wird angezeigt
- ✅ Keine Error-Messages

**Tester:** Seid Veseli, Amar Ibraimi, Leandro Graf  
**Zeitpunkt:** 09.12.2024, 14:45 Uhr  
**Status:** ✅ ERFOLGREICH

**Fazit:** Installation erfolgreich abgeschlossen. Nextcloud ist voll funktionsfähig.

---

## Test 9: Nextcloud Funktionalität

**Testziel:** Grundfunktionen von Nextcloud testen

**Durchführung:**
1. Login mit Admin-Account
2. Datei hochladen (test.txt)
3. Ordner erstellen
4. Datei teilen (Link generieren)
5. User-Management öffnen

**Screenshot:**
![Nextcloud Dashboard](../img/08_nextcloud_dashboard.png)

**Erwartetes Ergebnis:**
- ✅ Login funktioniert
- ✅ Datei-Upload erfolgreich
- ✅ Ordner erstellen funktioniert
- ✅ Teilen-Funktion verfügbar
- ✅ User-Management zugänglich

**Tester:** Leandro Graf  
**Zeitpunkt:** 09.12.2024, 14:50 Uhr  
**Status:** ✅ ERFOLGREICH

**Fazit:** Alle Grundfunktionen von Nextcloud arbeiten einwandfrei. System ist produktionsbereit (für Test-Zwecke).

---

## Test 10: Cleanup-Script

**Testziel:** Überprüfen ob cleanup.sh alle Ressourcen korrekt löscht

**Durchführung:**
```bash
bash cleanup.sh
# Bestätigung: ja
```

**Screenshot:**
![Cleanup Process](../img/09_cleanup.png)

**Erwartetes Ergebnis:**
- ✅ Beide Instanzen werden terminiert
- ✅ Security Groups werden gelöscht
- ✅ Keine Fehler-Meldungen
- ✅ AWS Console zeigt "terminated"

**Tester:** Seid Veseli  
**Zeitpunkt:** 09.12.2024, 15:00 Uhr  
**Status:** ✅ ERFOLGREICH

**Fazit:** Cleanup funktioniert einwandfrei. Alle Ressourcen wurden entfernt. Account ist sauber für nächstes Deployment.

---

## Test-Zusammenfassung

| Test-Nr | Test | Status | Tester | Dauer |
|---------|------|--------|--------|-------|
| 1 | AWS CLI Konfiguration | ✅ | Seid | 1 Min |
| 2 | Deployment-Script | ✅ | Seid, Amar | 4 Min |
| 3 | Generierte Dateien | ✅ | Leandro | 1 Min |
| 4 | AWS EC2 Instanzen | ✅ | Amar | 2 Min |
| 5 | Security Groups | ✅ | Seid | 2 Min |
| 6 | Datenbank-Verbindung | ✅ | Amar | 3 Min |
| 7 | Setup-Assistent | ✅ | Leandro | 2 Min |
| 8 | Nextcloud Installation | ✅ | Alle | 2 Min |
| 9 | Nextcloud Funktionalität | ✅ | Leandro | 5 Min |
| 10 | Cleanup-Script | ✅ | Seid | 3 Min |

**Gesamtergebnis:** ✅ **ALLE TESTS BESTANDEN**

**Gesamtdauer:** ~25 Minuten (Deployment bis vollständig funktionsfähig)

## Erkenntnisse und Empfehlungen

### Was gut funktioniert hat

1. ✅ **Vollautomatisierung:** Ein Befehl deployt alles
2. ✅ **Cloud-Init:** Zuverlässige Installation
3. ✅ **Security Groups:** Korrekte Netzwerk-Isolation
4. ✅ **Passwörter:** Sichere Auto-Generierung
5. ✅ **Cleanup:** Einfaches Aufräumen möglich

### Herausforderungen

1. ⚠️ **Wartezeiten:** 90 Sekunden zwischen DB und Web nötig
2. ⚠️ **Debugging:** Cloud-Init Logs schwer zugänglich
3. ⚠️ **AWS Academy:** Session-Timeout nach 4 Stunden

### Empfehlungen für Produktion

1. 🔒 **HTTPS:** SSL-Zertifikat einrichten (Let's Encrypt)
2. 🔐 **SSH:** Zugriff auf bekannte IPs beschränken
3. 💾 **Backup:** Automatische Snapshots konfigurieren
4. 📊 **Monitoring:** CloudWatch Alarms einrichten
5. 🔄 **Updates:** Automatische Security-Updates aktivieren
6. 📈 **Skalierung:** Load Balancer für höhere Last
7. 🌍 **CDN:** CloudFront für statische Assets

### Lessons Learned

- **Planung ist wichtig:** Gute Vorbereitung spart Zeit beim Deployment
- **Dokumentation hilft:** Tests ohne Doku sind schwer nachvollziehbar
- **Automation lohnt sich:** Manuelle Installation hätte 30+ Min gedauert
- **Testing ist kritisch:** Jeder Test hat potenzielle Fehler aufgedeckt
- **Teamwork funktioniert:** Aufgabenteilung war effizient