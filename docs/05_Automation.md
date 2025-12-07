# Automatisierung

## Übersicht Vorlage Alles hier drin sind Platzhalter

Die gesamte Infrastructure wird über das `deploy.sh` Script vollautomatisch bereitgestellt. Dieses Kapitel erklärt die Funktionsweise und Komponenten.

## deploy.sh - Hauptskript

### Funktionsweise

Das Script führt folgende Schritte automatisch aus:

1. ✅ AWS CLI Überprüfung
2. ✅ Alte Ressourcen aufräumen
3. ✅ Security Groups erstellen
4. ✅ Cloud-Init Dateien generieren
5. ✅ Datenbank-Server starten
6. ✅ 90 Sekunden warten (DB-Setup)
7. ✅ Webserver-Cloud-Init mit DB-IP erstellen
8. ✅ Webserver starten
9. ✅ Deployment-Informationen speichern
10. ✅ Zugangsdaten ausgeben

### Automatisierungsgrad

**Gütestufe 3 erreicht:**
- ✅ Webserver komplett installiert
- ✅ Datenbank vorhanden und konfiguriert
- ✅ Verbindung funktionstüchtig
- ✅ IP-Adresse wird angezeigt
- ✅ Datenbank-Credentials werden ausgegeben

## Infrastructure as Code (IaC)

### Cloud-Init als IaC-Tool

**Vorteile:**
- Deklarative Syntax (YAML)
- Versionierbar in Git
- Wiederholbar und reproduzierbar
- Native AWS-Integration
- Keine zusätzlichen Tools nötig

**Nachteile:**
- Kein State-Management (wie Terraform)
- Schwieriger zu debuggen
- Einmal-Ausführung beim Boot

### Versionsverwaltung

Alle Konfigurationsdateien werden in Git verwaltet:
```bash
# Initial Setup
git add deploy.sh cleanup.sh

# Nach Deployment
git add cloud-init-database.yaml
git add cloud-init-webserver.yaml
git add deployment-info.json

# Commits mit aussagekräftigen Messages
git commit -m "feat: Add automated deployment with cloud-init"
```

**Commit-History zeigt:**
- Wer hat was geändert (Seid, Amar, Leandro)
- Wann wurden Änderungen gemacht
- Welche Konfigurationen wurden angepasst

## Passwort-Generierung

### Sichere Zufallspasswörter
```bash
DB_ROOT_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-24)
DB_NC_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-24)
```

**Eigenschaften:**
- 24 Zeichen lang
- Alphanumerisch
- Kryptographisch sicher (openssl)
- Automatisch bei jedem Deployment neu

**Beispiel:**
```
DB_ROOT_PASSWORD: Kx7mNp2qR8vW4jL9sT3h
DB_NC_PASSWORD: Bz6nYp9wL2xK5mC8vR4t
```

## Error Handling

### Fehlerbehandlung im Script
```bash
set -e  # Script stoppt bei Fehler

# AWS CLI Check
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI nicht gefunden!"
    exit 1
fi

# Credentials Check
if ! aws sts get-caller-identity --region $REGION &> /dev/null; then
    echo "ERROR: AWS Credentials nicht konfiguriert!"
    exit 1
fi
```

### Farbige Ausgabe
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}✓ Erfolgreich${NC}"
echo -e "${RED}✗ Fehler${NC}"
echo -e "${YELLOW}⏳ Warten...${NC}"
```

**Vorteil:** Benutzer sieht sofort Status der Installation

## Cleanup-Prozess

### Alte Ressourcen entfernen
```bash
# Alte Instanzen finden
OLD_INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=M346-Nextcloud" \
              "Name=instance-state-name,Values=running,pending,stopped" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text \
    --region $REGION)

# Terminieren
if [ ! -z "$OLD_INSTANCES" ]; then
    aws ec2 terminate-instances --instance-ids $OLD_INSTANCES --region $REGION
    aws ec2 wait instance-terminated --instance-ids $OLD_INSTANCES --region $REGION
fi
```

**Warum wichtig?**
- AWS Academy hat Limits
- Verhindert versehentliche Doppel-Deployments
- Sauberer Start bei jedem Test

## Security Groups

### Automatische Erstellung
```bash
# Datenbank Security Group
DB_SG_ID=$(aws ec2 create-security-group \
    --group-name nextcloud-db-sg \
    --description "Nextcloud Database Server - M346" \
    --region $REGION \
    --query 'GroupId' \
    --output text)

# Regel: MySQL nur von Web-SG
aws ec2 authorize-security-group-ingress \
    --group-id $DB_SG_ID \
    --protocol tcp \
    --port 3306 \
    --source-group $WEB_SG_ID \
    --region $REGION
```

**Sicherheit durch Design:**
- DB nur von Webserver erreichbar (nicht 0.0.0.0/0)
- Minimale Ports geöffnet
- Automatisch konfiguriert, keine manuellen Fehler

## Deployment-Informationen

### deployment-info.json
```json
{
  "deployment_date": "2024-12-07 15:30:00 UTC",
  "region": "us-east-1",
  "nextcloud_version": "28.0.1",
  "database": {
    "instance_id": "i-0b787e75a71e4498e",
    "private_ip": "172.31.30.69",
    "security_group_id": "sg-xxx",
    "database_name": "nextcloud",
    "database_user": "nextcloud",
    "database_password": "Kx7mNp2qR8vW4jL9sT3h",
    "root_password": "Bz6nYp9wL2xK5mC8vR4t"
  },
  "webserver": {
    "instance_id": "i-06ce3a3c3bd95e9c6",
    "public_ip": "52.90.54.109",
    "security_group_id": "sg-yyy",
    "url": "http://52.90.54.109"
  }
}
```

**Verwendung:**
- Dokumentation des Deployments
- Credentials nachschlagen
- Cleanup-Script kann Ressourcen finden
- Audit-Trail für Bewertung

## Timing und Wartezeiten

### Warum 90 Sekunden warten?
```bash
echo "Warte 90 Sekunden für MariaDB Setup..."
sleep 90
```

**Grund:**
- MariaDB Installation braucht Zeit (~60-80 Sek)
- Datenbank muss bereit sein BEVOR Webserver startet
- Webserver braucht DB-IP für Cloud-Init
- Zu kurze Wartezeit → Verbindungsfehler

### AWS Wait Commands
```bash
# Warten bis Instanz läuft
aws ec2 wait instance-running --instance-ids $DB_INSTANCE_ID --region $REGION

# Warten bis Instanz terminiert ist
aws ec2 wait instance-terminated --instance-ids $OLD_INSTANCES --region $REGION
```

**Besser als sleep:** AWS prüft aktiv den Status

## Wiederholbarkeit

### Idempotenz

Das Script kann mehrfach ausgeführt werden:

1. **Cleanup:** Alte Ressourcen werden entfernt
2. **Frischer Start:** Neue IDs, neue Passwörter
3. **Gleiche Tags:** `Project=M346-Nextcloud`
4. **Gleiche Namen:** `nextcloud-database`, `nextcloud-webserver`

**Ergebnis:** Jedes Deployment ist identisch reproduzierbar

## Best Practices

### ✅ Was wir richtig gemacht haben

1. **Error Handling:** Script stoppt bei Fehlern
2. **Credentials Check:** Prüfung vor Start
3. **Cleanup:** Alte Ressourcen automatisch entfernen
4. **Dokumentation:** Alles in Git versioniert
5. **Ausgabe:** Klare, farbige Status-Messages
6. **Sicherheit:** Sichere Passwörter, minimal Ports

### 🔄 Was verbessert werden könnte

1. **Rollback:** Bei Fehler automatisch aufräumen
2. **Logging:** Alle Schritte in Log-Datei
3. **Parameter:** Region/Instance-Type konfigurierbar
4. **Validation:** Nextcloud-Health-Check nach Deployment
5. **HTTPS:** SSL-Zertifikat automatisch einrichten
6. **Backup:** Automatische Snapshot-Erstellung

## Zusammenfassung

Das Deployment ist **vollautomatisiert** und erfüllt alle Anforderungen:

| Kriterium | Status | Bemerkung |
|-----------|--------|-----------|
| IaC | ✅ | Cloud-Init YAML |
| Versionierung | ✅ | Git Repository |
| Automatisierung | ✅ | Ein Befehl: `bash deploy.sh` |
| Dokumentiert | ✅ | Alle Schritte erklärt |
| Wiederholbar | ✅ | Cleanup + Deployment |
| Sicher | ✅ | Auto-Passwörter, SG-Regeln |

**Gütestufe 3 erreicht:** ✅