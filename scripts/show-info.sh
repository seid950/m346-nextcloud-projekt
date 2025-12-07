#!/bin/bash

# ==============================================
# Nextcloud Deployment Info Script
# Zeigt alle wichtigen Daten der Installation
# ==============================================

REGION="us-east-1"

echo "================================================"
echo "    NEXTCLOUD DEPLOYMENT INFORMATIONEN"
echo "================================================"
echo ""

# Datenbank-Server Informationen
echo "=== DATENBANK-SERVER ==="
DB_INSTANCE=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=nextcloud-db" "Name=instance-state-name,Values=running" \
    --region $REGION \
    --query 'Reservations[0].Instances[0]' \
    --output json 2>/dev/null)

if [ ! -z "$DB_INSTANCE" ]; then
    DB_INSTANCE_ID=$(echo $DB_INSTANCE | jq -r '.InstanceId')
    DB_PRIVATE_IP=$(echo $DB_INSTANCE | jq -r '.PrivateIpAddress')
    DB_STATE=$(echo $DB_INSTANCE | jq -r '.State.Name')
    DB_TYPE=$(echo $DB_INSTANCE | jq -r '.InstanceType')
    DB_LAUNCH_TIME=$(echo $DB_INSTANCE | jq -r '.LaunchTime')
    
    echo "Instance ID: $DB_INSTANCE_ID"
    echo "Status: $DB_STATE"
    echo "Instance Type: $DB_TYPE"
    echo "Private IP: $DB_PRIVATE_IP"
    echo "Launch Time: $DB_LAUNCH_TIME"
    echo ""
    echo "Datenbank-Zugangsdaten:"
    echo "  - DB Name: nextcloud"
    echo "  - DB User: nextcloud"
    echo "  - DB Password: NextcloudDB2024!"
    echo "  - Root Password: SecureRoot2024!"
else
    echo "FEHLER: Datenbank-Server nicht gefunden!"
fi

echo ""
echo "=== WEB-SERVER ==="

# Web-Server Informationen
WEB_INSTANCE=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=nextcloud-web" "Name=instance-state-name,Values=running" \
    --region $REGION \
    --query 'Reservations[0].Instances[0]' \
    --output json 2>/dev/null)

if [ ! -z "$WEB_INSTANCE" ]; then
    WEB_INSTANCE_ID=$(echo $WEB_INSTANCE | jq -r '.InstanceId')
    WEB_PUBLIC_IP=$(echo $WEB_INSTANCE | jq -r '.PublicIpAddress')
    WEB_PRIVATE_IP=$(echo $WEB_INSTANCE | jq -r '.PrivateIpAddress')
    WEB_STATE=$(echo $WEB_INSTANCE | jq -r '.State.Name')
    WEB_TYPE=$(echo $WEB_INSTANCE | jq -r '.InstanceType')
    WEB_LAUNCH_TIME=$(echo $WEB_INSTANCE | jq -r '.LaunchTime')
    
    echo "Instance ID: $WEB_INSTANCE_ID"
    echo "Status: $WEB_STATE"
    echo "Instance Type: $WEB_TYPE"
    echo "Public IP: $WEB_PUBLIC_IP"
    echo "Private IP: $WEB_PRIVATE_IP"
    echo "Launch Time: $WEB_LAUNCH_TIME"
else
    echo "FEHLER: Web-Server nicht gefunden!"
fi

echo ""
echo "=== NEXTCLOUD ZUGANG ==="
if [ ! -z "$WEB_PUBLIC_IP" ]; then
    echo "Nextcloud URL: http://$WEB_PUBLIC_IP"
    echo ""
    echo "Installation (falls noch nicht abgeschlossen):"
    echo "  1. Browser öffnen: http://$WEB_PUBLIC_IP"
    echo "  2. Admin-Account erstellen"
    echo "  3. Data folder: /var/nextcloud-data"
    echo "  4. Datenbank konfigurieren:"
    echo "     - Datenbank-User: nextcloud"
    echo "     - Datenbank-Password: NextcloudDB2024!"
    echo "     - Datenbank-Name: nextcloud"
    echo "     - Datenbank-Host: $DB_PRIVATE_IP"
fi

echo ""
echo "=== SECURITY GROUPS ==="

# Security Groups auflisten
DB_SG=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=nextcloud-db-sg" \
    --region $REGION \
    --query 'SecurityGroups[0]' \
    --output json 2>/dev/null)

if [ ! -z "$DB_SG" ] && [ "$DB_SG" != "null" ]; then
    DB_SG_ID=$(echo $DB_SG | jq -r '.GroupId')
    echo "Datenbank SG: $DB_SG_ID (nextcloud-db-sg)"
    echo "  - Port 3306: MySQL (nur von Web-Server)"
    echo "  - Port 22: SSH"
fi

WEB_SG=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=nextcloud-web-sg" \
    --region $REGION \
    --query 'SecurityGroups[0]' \
    --output json 2>/dev/null)

if [ ! -z "$WEB_SG" ] && [ "$WEB_SG" != "null" ]; then
    WEB_SG_ID=$(echo $WEB_SG | jq -r '.GroupId')
    echo "Web SG: $WEB_SG_ID (nextcloud-web-sg)"
    echo "  - Port 80: HTTP (von überall)"
    echo "  - Port 22: SSH"
fi

echo ""
echo "=== SSH ZUGANG ==="
if [ ! -z "$WEB_PUBLIC_IP" ]; then
    echo "Web-Server:"
    echo "  ssh -i ~/.ssh/vockey.pem ubuntu@$WEB_PUBLIC_IP"
fi
if [ ! -z "$DB_PRIVATE_IP" ]; then
    echo "Datenbank-Server (über Web-Server):"
    echo "  ssh -i ~/.ssh/vockey.pem ubuntu@$DB_PRIVATE_IP"
fi

echo ""
echo "=== ARCHITEKTUR ==="
echo "┌─────────────────┐"
echo "│   Internet      │"
echo "└────────┬────────┘"
echo "         │ Port 80"
echo "         ▼"
echo "┌─────────────────┐"
echo "│  Web-Server     │"
echo "│  $WEB_PUBLIC_IP"
echo "│  Apache+PHP     │"
echo "│  Nextcloud      │"
echo "└────────┬────────┘"
echo "         │ Port 3306"
echo "         │ Internal"
echo "         ▼"
echo "┌─────────────────┐"
echo "│  DB-Server      │"
echo "│  $DB_PRIVATE_IP"
echo "│  MariaDB        │"
echo "└─────────────────┘"

echo ""
echo "=== KOSTEN-ÜBERSICHT ==="
echo "Instance Types: 2x $WEB_TYPE"
echo "Hinweis: AWS Learner Lab hat begrenzte Credits!"

echo ""
echo "================================================"
echo "Für Dokumentation: Screenshot von diesem Output!"
echo "================================================"
