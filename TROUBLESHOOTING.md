# Troubleshooting Guide

Detaillierte Lösungen für alle Probleme beim Nextcloud-Deployment.

---

## Inhaltsverzeichnis

- [Problem 1: AWS CLI nicht installiert](#problem-1-aws-cli-nicht-installiert)
- [Problem 2: Git nicht installiert](#problem-2-git-nicht-installiert)
- [Problem 3: Credentials funktionieren nicht](#problem-3-credentials-funktionieren-nicht)
- [Problem 4: Script startet nicht](#problem-4-script-startet-nicht)
- [Problem 5: Nextcloud Setup-Assistent lädt nicht](#problem-5-nextcloud-setup-assistent-lädt-nicht)
- [Problem 6: Datenbank-Verbindung fehlgeschlagen](#problem-6-datenbank-verbindung-fehlgeschlagen)
- [Problem 7: Data directory not writable](#problem-7-data-directory-not-writable)
- [Problem 8: AWS Session abgelaufen](#problem-8-aws-session-abgelaufen)
- [Problem 9: Security Group already exists](#problem-9-security-group-already-exists)

---

## Problem 1: AWS CLI nicht installiert

**Fehlermeldung:**
```
bash: aws: command not found
```

**Ursache:** AWS CLI ist nicht installiert

**Lösung:**

```bash
# Download
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Unzip installieren (falls nötig)
sudo apt install unzip -y     # Ubuntu/Debian/WSL
sudo dnf install unzip -y     # Fedora/RHEL
sudo pacman -S unzip          # Arch

# Entpacken und installieren
unzip awscliv2.zip
sudo ./aws/install

# Aufräumen
rm -rf aws awscliv2.zip

# Testen
aws --version
```

**Erwartete Ausgabe:**
```
aws-cli/2.15.10 Python/3.11.6 Linux/5.15.0-91-generic exe/x86_64.ubuntu.22
```

---

## Problem 2: Git nicht installiert

**Fehlermeldung:**
```
bash: git: command not found
```

**Ursache:** Git ist nicht installiert

**Lösung:**

```bash
# Ubuntu/Debian/WSL
sudo apt update
sudo apt install git -y

# Fedora/RHEL
sudo dnf install git -y

# Arch Linux
sudo pacman -S git

# Testen
git --version
```

**Erwartete Ausgabe:**
```
git version 2.43.0
```

---

## Problem 3: Credentials funktionieren nicht

**Fehlermeldung:**
```
Unable to locate credentials. You can configure credentials by running "aws configure".
```

oder

```
An error occurred (UnauthorizedOperation) when calling the DescribeInstances operation
```

**Ursache:** Credentials nicht korrekt konfiguriert

**Lösung:**

### **Methode 1: Mit aws configure (schnell)**

1. Gehe zu AWS Academy
2. Klicke **"AWS Details"** → **"Show"**
3. Kopiere die Credentials

4. Im Terminal:
```bash
aws configure set aws_access_key_id ASIAXXXXXXXXXX
aws configure set aws_secret_access_key wJalXXXXXXXXXXXXXXXXXXXXXXXX
aws configure set aws_session_token "FwoGZXIvYXdzEBkaDC...DEIN-TOKEN..."
aws configure set region us-east-1
```

**WICHTIG:** Ersetze mit deinen echten Credentials aus AWS Academy!

### **Methode 2: Manuell mit nano**

```bash
# Öffne Credentials-Datei
nano ~/.aws/credentials

# Füge ein (ersetze mit deinen Credentials):
[default]
aws_access_key_id=ASIAXXXXXXXXXX
aws_secret_access_key=wJalXXXXXXXXXXXXXXXXXXXXXXXX
aws_session_token=FwoGZXIvYXdzEBkaDC...

# Speichern: Ctrl+O, Enter, Ctrl+X
```

### **Testen:**

```bash
aws sts get-caller-identity
```

**Erwartete Ausgabe:**
```json
{
    "UserId": "AIDAXXXXXXXXXX:user",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/awsstudent"
}
```

---

## Problem 4: Script startet nicht

**Fehlermeldung:**
```
bash: scripts/deploy.sh: No such file or directory
```

**Ursache:** Du bist nicht im richtigen Verzeichnis

**Lösung:**

```bash
# Prüfe wo du bist
pwd

# Sollte zeigen:
# /home/username/m346-nextcloud-projekt

# Falls nicht:
cd ~/m346-nextcloud-projekt

# Prüfe ob Script existiert
ls -la scripts/deploy.sh

# Falls nicht ausführbar:
chmod +x scripts/deploy.sh

# Nochmal starten
bash scripts/deploy.sh
```

---

## Problem 5: Nextcloud Setup-Assistent lädt nicht

**Symptom:** Browser zeigt "Diese Website ist nicht erreichbar" oder "Connection refused"

**Ursache 1: Nextcloud ist noch nicht fertig installiert**

**Lösung:**

Warte noch 2-3 Minuten, dann teste:

```bash
# Ersetze mit deiner Public IP
curl http://54.162.154.237
```

**Falls zeigt:**
```
curl: (7) Failed to connect to 54.162.154.237 port 80: Connection refused
```
→ **Noch nicht bereit**, warte noch 1 Minute

**Falls zeigt:**
```html
<!DOCTYPE html>
<html class="ng-csp" data-placeholder-focus="false" lang="de">
  <head>
    <meta charset="utf-8">
    <title>Nextcloud</title>
```
→ **Bereit!** Probiere nochmal im Browser

---

**Ursache 2: Falsche IP-Adresse**

**Lösung:**

```bash
# Prüfe richtige Public IP
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=nextcloud-web" \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

**Ausgabe:** (z.B.)
```
54.162.154.237
```

**Diese IP im Browser verwenden:** `http://54.162.154.237`

---

**Ursache 3: AWS Security Group Problem**

**Lösung:**

```bash
# Prüfe Security Group
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=nextcloud-web-sg" \
  --region us-east-1 \
  --query 'SecurityGroups[0].IpPermissions[*].[FromPort,ToPort,IpRanges]' \
  --output table
```

**Sollte Port 80 zeigen:**
```
---------------------------------
|  80  |  80  |  0.0.0.0/0      |
---------------------------------
```

**Falls Port 80 fehlt:** Deployment nochmal ausführen

---

## Problem 6: Datenbank-Verbindung fehlgeschlagen

**Fehlermeldung im Setup-Assistent:**
```
Error: Can't connect to MySQL server
```

**Ursache 1: Falsche IP-Adresse**

**Lösung:**

**⚠️ WICHTIG:** Verwende die **Private IP**, NICHT localhost!

```bash
# Finde Private IP der Datenbank
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=nextcloud-db" \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
  --output text
```

**Ausgabe:** (z.B.)
```
172.31.24.60
```

**Diese IP im Setup-Assistenten verwenden!**

**NICHT verwenden:**
- ❌ localhost
- ❌ 127.0.0.1
- ❌ Public IP des Webservers

---

**Ursache 2: Falsches Passwort**

**Lösung:**

```bash
# Passwort aus deployment-info.json holen
cat deployment-info.json | grep "db_password"
```

**Ausgabe:** (z.B.)
```json
"db_password": "xY9mK2nL5pQ8rT1vW4zA7bC0"
```

**Kopiere EXAKT:**
- Genau 24 Zeichen
- Groß-/Kleinschreibung beachten
- Keine Leerzeichen am Anfang/Ende

---

**Ursache 3: Datenbank noch nicht bereit**

**Lösung:**

```bash
# Prüfe DB-Server Status
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

**Test ob MariaDB läuft:**
```bash
# SSH zum DB-Server (ersetze mit Private IP)
ssh -i vockey.pem ubuntu@172.31.24.60

# Im SSH:
sudo systemctl status mariadb

# Sollte "active (running)" zeigen
# Exit mit: exit
```

---

## Problem 7: Data directory not writable

**Fehlermeldung:**
```
Your data directory is not writable by Nextcloud.
Please check the file permissions.
```

**Ursache:** Falsche Berechtigungen

**Lösung:**

```bash
# SSH zum Webserver (ersetze mit Public IP)
ssh -i vockey.pem ubuntu@54.162.154.237

# Prüfe Berechtigungen
ls -ld /var/nextcloud-data/

# Sollte zeigen:
# drwxr-xr-x 2 www-data www-data 4096 ...

# Falls falsch, korrigiere:
sudo chown -R www-data:www-data /var/nextcloud-data/
sudo chmod 755 /var/nextcloud-data/

# Nochmal prüfen
ls -ld /var/nextcloud-data/

# Exit
exit
```

**Probiere Setup nochmal im Browser**

---

## Problem 8: AWS Session abgelaufen

**Fehlermeldung:**
```
An error occurred (AuthFailure) when calling the DescribeInstances operation
```

oder

```
An error occurred (ExpiredToken) when calling the GetCallerIdentity operation
```

**Ursache:** AWS Learner Lab Session ist abgelaufen (max. 4 Stunden)

**Lösung:**

### **Schritt 1: Neue Session starten**

1. Gehe zu AWS Academy
2. Klicke **"Start Lab"**
3. Warte bis grüner Punkt

### **Schritt 2: Neue Credentials kopieren**

1. Klicke **"AWS Details"** → **"Show"**
2. Kopiere die neuen Credentials

### **Schritt 3: Credentials aktualisieren**

**Option A - Mit aws configure (schnell):**
```bash
aws configure set aws_access_key_id ASIA...
aws configure set aws_secret_access_key wJal...
aws configure set aws_session_token "FwoG..."
aws configure set region us-east-1
```

**Option B - Mit nano:**
```bash
nano ~/.aws/credentials
# Alles löschen, neue Credentials einfügen
# Ctrl+O, Enter, Ctrl+X
```

### **Schritt 4: Testen**

```bash
aws sts get-caller-identity
```

**Sollte jetzt funktionieren!**

---

## Problem 9: Security Group already exists

**Fehlermeldung:**
```
A security group with the name 'nextcloud-web-sg' already exists
```

**Ursache:** Security Groups von altem Deployment existieren noch

**Lösung:**

### **Option 1: Mit cleanup.sh (empfohlen)**

```bash
bash scripts/cleanup.sh
# Bestätigung mit "ja"
# Warte 1 Minute
```

### **Option 2: Manuell löschen**

```bash
# Lösche alte Security Groups
aws ec2 delete-security-group \
  --group-name nextcloud-web-sg \
  --region us-east-1

aws ec2 delete-security-group \
  --group-name nextcloud-db-sg \
  --region us-east-1
```

**Falls Fehler "DependencyViolation":**

```
An error occurred (DependencyViolation) when calling the DeleteSecurityGroup operation
```

**Bedeutet:** Instanzen verwenden noch die Security Groups

**Lösung:**

```bash
# 1. Finde alte Instanzen
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=M346-Nextcloud" \
  --region us-east-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
  --output table

# 2. Terminiere sie (ersetze mit Instance IDs)
aws ec2 terminate-instances \
  --instance-ids i-XXXXXXXXX i-YYYYYYYYY \
  --region us-east-1

# 3. Warte 1 Minute

# 4. Security Groups nochmal löschen
aws ec2 delete-security-group --group-name nextcloud-web-sg --region us-east-1
aws ec2 delete-security-group --group-name nextcloud-db-sg --region us-east-1
```

**Jetzt:** Deployment nochmal starten

---

## Logs ansehen

**Wenn gar nichts funktioniert, schaue die Logs an:**

### **EC2 Console Output**

```bash
# Webserver Logs
aws ec2 get-console-output \
  --instance-id i-XXXXXXXXX \
  --region us-east-1 \
  --output text > webserver.log

# Anschauen
cat webserver.log
```

### **Apache Logs (via SSH)**

```bash
# SSH zum Webserver
ssh -i vockey.pem ubuntu@WEBSERVER-PUBLIC-IP

# Apache Logs
sudo tail -100 /var/log/apache2/error.log

# User-Data Log (Installation)
sudo tail -100 /var/log/user-data.log
```

### **MariaDB Logs (via SSH)**

```bash
# SSH zum DB-Server
ssh -i vockey.pem ubuntu@DB-PRIVATE-IP

# MariaDB Logs
sudo tail -100 /var/log/mysql/error.log

# User-Data Log
sudo tail -100 /var/log/user-data.log
```

---

## Nützliche Befehle für Debugging

**Alle Nextcloud-Ressourcen anzeigen:**
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=M346-Nextcloud" \
  --region us-east-1 \
  --output table
```

**Security Groups prüfen:**
```bash
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=nextcloud-*" \
  --region us-east-1 \
  --output table
```

**Deployment-Info anzeigen:**
```bash
cat deployment-info.json | jq .
# Falls jq nicht installiert:
cat deployment-info.json
```

---

## Noch Probleme?

**GitHub Issues:**  
https://github.com/seid950/m346-nextcloud-projekt/issues

**Team:**
- Seid Veseli
- Amar Ibraimi  
- Leandro Graf

---

**Zurück zum [README.md](README.md)**

---

## Problem 1: Credentials funktionieren nicht

**Symptom:**
```bash
aws sts get-caller-identity
```
Zeigt Fehler:
```
Unable to locate credentials. You can configure credentials by running "aws configure".
```

**Ursache:** Credentials nicht korrekt in `~/.aws/credentials` gespeichert

**Lösung:**

**Methode 1 - Mit nano (wie im Hauptteil):**

**Schritt 1 - Datei prüfen:**
```bash
cat ~/.aws/credentials
```

**Sollte zeigen:**
```ini
[default]
aws_access_key_id=ASIA...
aws_secret_access_key=wJal...
aws_session_token=FwoG...
```

**Falls leer oder falsch:**

**Schritt 2 - Nochmal einfügen:**
1. Gehe zu AWS Academy
2. Klicke "AWS Details" → "Show"
3. Klicke "Copy"
4. Im Terminal:
```bash
nano ~/.aws/credentials
```
5. Alles löschen (Ctrl+K mehrmals)
6. Rechtsklick zum Einfügen
7. Ctrl+O → Enter → Ctrl+X
8. Nochmal testen:
```bash
aws sts get-caller-identity
```

---

**Methode 2 - Mit aws configure (schneller!):**

```bash
# Kopiere deine Credentials aus AWS Academy und führe aus:
aws configure set aws_access_key_id ASIAIOSFODNN7EXAMPLE
aws configure set aws_secret_access_key wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
aws configure set aws_session_token "FwoGZXIvYXdzEBkaDC...dein Token..."
aws configure set region us-east-1
```

**WICHTIG:** Ersetze mit deinen echten Credentials!

**Testen:**
```bash
aws sts get-caller-identity
```

---

## Problem 2: AWS CLI Installation schlägt fehl

**Symptom:**
```bash
sudo ./aws/install
```
Zeigt Fehler:
```
./aws/install: Permission denied
```

**Lösung:**

**Schritt 1 - Executable-Rechte setzen:**
```bash
chmod +x aws/install
```

**Schritt 2 - Nochmal installieren:**
```bash
sudo ./aws/install
```

---

**Anderes Symptom:**
```
Could not install AWS CLI
```

**Lösung:**

**Prüfe ob Python installiert ist:**
```bash
python3 --version
```

**Falls nicht:**
```bash
sudo apt update
sudo apt install python3 -y
```

**Dann nochmal AWS CLI installieren**

---

## Problem 3: Git clone funktioniert nicht

**Symptom:**
```bash
git clone https://github.com/seid950/m346-nextcloud-projekt.git
```
Zeigt:
```
bash: git: command not found
```

**Ursache:** Git ist nicht installiert

**Lösung:**
```bash
sudo apt update
sudo apt install git -y
```

**Dann nochmal klonen:**
```bash
git clone https://github.com/seid950/m346-nextcloud-projekt.git
```

---

## Problem 4: Deployment Script startet nicht

**Symptom:**
```bash
bash scripts/deploy.sh
```
Zeigt:
```
bash: scripts/deploy.sh: No such file or directory
```

**Ursache:** Du bist nicht im richtigen Verzeichnis

**Lösung:**

**Schritt 1 - Prüfe wo du bist:**
```bash
pwd
```

**Sollte zeigen:**
```
/home/username/m346-nextcloud-projekt
```

**Schritt 2 - Falls nicht, navigiere dorthin:**
```bash
cd ~/m346-nextcloud-projekt
```

**Schritt 3 - Nochmal probieren:**
```bash
bash scripts/deploy.sh
```

---

## Problem 5: Nextcloud Setup-Assistent lädt nicht

**Symptom:** Browser zeigt "Diese Website ist nicht erreichbar" oder "Connection refused"

**Ursache:** Nextcloud ist noch nicht fertig installiert

**Lösung 1 - Länger warten:**

Warte noch 2-3 Minuten, dann nochmal probieren.

**Test im Terminal:**
```bash
curl http://XX.XX.XX.XX
```
*Ersetze XX.XX.XX.XX mit deiner Public IP!*

**Falls zeigt:**
```
curl: (7) Failed to connect
```
→ Noch nicht bereit, noch 1 Minute warten

**Falls zeigt:**
```html
<!DOCTYPE html>
<html...
```
→ Bereit! Jetzt im Browser probieren

---

**Lösung 2 - Falsche IP?**

**Prüfe die richtige IP:**
```bash
cat deployment-info.json | grep public_ip
```

**Zeigt:**
```json
"public_ip": "54.162.154.237",
```

**Diese IP im Browser verwenden:** `http://54.162.154.237`

---

## Problem 6: Datenbank-Verbindung fehlgeschlagen

**Symptom:** Im Setup-Assistenten erscheint:
```
Error: Can't connect to MySQL server
```

**Ursache 1:** Falsche Private IP verwendet

**Lösung:**

**Prüfe die richtige Private IP:**
```bash
cat deployment-info.json | grep private_ip
```

**Zeigt:**
```json
"private_ip": "172.31.24.60",
```

**Diese IP verwenden - NICHT:**
- ❌ localhost
- ❌ 127.0.0.1
- ❌ Die Public IP

**Sondern:**
- ✅ 172.31.24.60 (deine Private IP)

---

**Ursache 2:** Falsches Passwort

**Lösung:**

**Passwort nochmal holen:**
```bash
cat deployment-info.json | grep db_password
```

**Zeigt:**
```json
"db_password": "xY9mK2nL5pQ8rT1vW4zA7bC0"
```

**Das EXAKTE Passwort kopieren:**
- Markiere das Passwort
- Rechtsklick → Kopieren
- Im Browser einfügen
- **Keine Leerzeichen am Anfang/Ende!**

---

## Problem 7: AWS Session abgelaufen

**Symptom:**
```
An error occurred (AuthFailure) when calling the ... operation
```

**Ursache:** AWS Learner Lab Session ist abgelaufen (max. 4 Stunden)

**Lösung:**

**Schritt 1 - Neue Session starten:**
1. Gehe zu AWS Academy
2. Klicke "Start Lab"
3. Warte bis grüner Punkt

**Schritt 2 - Neue Credentials kopieren:**
1. Klicke "AWS Details" → "Show"
2. Klicke "Copy"

**Schritt 3 - Credentials ersetzen:**

**Option A - Mit nano:**
```bash
nano ~/.aws/credentials
```
- Alles löschen
- Neue Credentials einfügen
- Ctrl+O → Enter → Ctrl+X

**Option B - Mit aws configure (schneller!):**
```bash
aws configure set aws_access_key_id ASIA...
aws configure set aws_secret_access_key wJal...
aws configure set aws_session_token "FwoG..."
aws configure set region us-east-1
```

**Schritt 4 - Testen:**
```bash
aws sts get-caller-identity
```

**Sollte jetzt funktionieren!**

---

**Zurück zum [README.md](README.md)**