#!/bin/bash
set -e

# ==============================================
# AWS Nextcloud Cleanup Script
# Löscht alle Ressourcen des Deployments
# ==============================================

REGION="us-east-1"

echo "=== Starting Nextcloud Cleanup ==="
echo ""
echo "WARNUNG: Dieses Skript löscht alle Nextcloud-Ressourcen!"
echo "- EC2 Instanzen (Web + Database Server)"
echo "- Security Groups"
echo ""
read -p "Möchten Sie fortfahren? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup abgebrochen."
    exit 0
fi

echo ""
echo "=== Schritt 1: EC2 Instanzen terminieren ==="

# Alle Nextcloud-Instanzen finden
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=nextcloud-*" \
              "Name=instance-state-name,Values=running,pending,stopped,stopping" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text \
    --region $REGION 2>/dev/null || true)

if [ -z "$INSTANCE_IDS" ]; then
    echo "Keine Nextcloud-Instanzen gefunden."
else
    echo "Gefundene Instanzen: $INSTANCE_IDS"
    
    # Instanzen terminieren
    for INSTANCE_ID in $INSTANCE_IDS; do
        echo "Terminiere Instanz: $INSTANCE_ID"
        aws ec2 terminate-instances \
            --instance-ids $INSTANCE_ID \
            --region $REGION
    done
    
    echo "Warte bis alle Instanzen terminiert sind..."
    aws ec2 wait instance-terminated \
        --instance-ids $INSTANCE_IDS \
        --region $REGION 2>/dev/null || sleep 60
    
    echo "✓ Alle Instanzen terminiert"
fi

echo ""
echo "=== Schritt 2: Security Groups löschen ==="

# Kurze Pause, damit AWS die Terminierung verarbeitet
sleep 10

# Web Security Group löschen
echo "Lösche Web Security Group..."
WEB_SG_DELETED=$(aws ec2 delete-security-group \
    --group-name nextcloud-web-sg \
    --region $REGION 2>&1)

if [ $? -eq 0 ]; then
    echo "✓ Web Security Group gelöscht"
else
    echo "⚠ Web Security Group konnte nicht gelöscht werden (existiert möglicherweise nicht)"
fi

# Database Security Group löschen
echo "Lösche Database Security Group..."
DB_SG_DELETED=$(aws ec2 delete-security-group \
    --group-name nextcloud-db-sg \
    --region $REGION 2>&1)

if [ $? -eq 0 ]; then
    echo "✓ Database Security Group gelöscht"
else
    echo "⚠ Database Security Group konnte nicht gelöscht werden (existiert möglicherweise nicht)"
fi

echo ""
echo "=== Schritt 3: Temporäre Dateien aufräumen ==="

# Lokale temporäre Dateien löschen
rm -f db-userdata.sh web-userdata.sh

echo "✓ Temporäre Dateien gelöscht"

echo ""
echo "================================================"
echo "    CLEANUP ABGESCHLOSSEN"
echo "================================================"
echo ""
echo "Alle Nextcloud-Ressourcen wurden entfernt:"
echo "  ✓ EC2 Instanzen terminiert"
echo "  ✓ Security Groups gelöscht"
echo "  ✓ Temporäre Dateien entfernt"
echo ""
echo "Hinweis: Prüfen Sie die AWS Console, um sicherzustellen,"
echo "dass alle Ressourcen entfernt wurden."
echo ""
echo "================================================"
