#!/bin/bash
# ==============================================
# Nextcloud Cleanup Script - Modul 346
# Löscht alle erstellten AWS Ressourcen
# Ausführung: bash cleanup.sh
# ==============================================

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REGION="us-east-1"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}   NEXTCLOUD CLEANUP${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# ==============================================
# 1. DEPLOYMENT-INFO LADEN
# ==============================================
echo -e "${YELLOW}[1/4] Suche Deployment-Informationen...${NC}"

if [ -f "deployment-info.json" ]; then
    DB_INSTANCE_ID=$(grep -o '"instance_id": "[^"]*"' deployment-info.json | head -1 | cut -d'"' -f4)
    WEB_INSTANCE_ID=$(grep -o '"instance_id": "[^"]*"' deployment-info.json | tail -1 | cut -d'"' -f4)
    DB_SG_ID=$(grep -o '"security_group_id": "[^"]*"' deployment-info.json | head -1 | cut -d'"' -f4)
    WEB_SG_ID=$(grep -o '"security_group_id": "[^"]*"' deployment-info.json | tail -1 | cut -d'"' -f4)
    
    echo "  ✓ Deployment-Info geladen"
    echo "    DB Instance: $DB_INSTANCE_ID"
    echo "    Web Instance: $WEB_INSTANCE_ID"
else
    echo "  ! Keine deployment-info.json gefunden"
    echo "  Suche nach Ressourcen mit Tag 'Project=M346-Nextcloud'..."
    
    INSTANCES=$(aws ec2 describe-instances \
        --filters "Name=tag:Project,Values=M346-Nextcloud" \
                  "Name=instance-state-name,Values=running,stopped,pending" \
        --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Type`].Value|[0]]' \
        --output text \
        --region $REGION)
    
    if [ -z "$INSTANCES" ]; then
        echo -e "${GREEN}  ✓ Keine Instanzen gefunden${NC}"
        exit 0
    fi
    
    DB_INSTANCE_ID=$(echo "$INSTANCES" | grep "Database" | awk '{print $1}')
    WEB_INSTANCE_ID=$(echo "$INSTANCES" | grep "Webserver" | awk '{print $1}')
    
    echo "  Gefundene Instanzen:"
    [ ! -z "$DB_INSTANCE_ID" ] && echo "    DB: $DB_INSTANCE_ID"
    [ ! -z "$WEB_INSTANCE_ID" ] && echo "    Web: $WEB_INSTANCE_ID"
fi

echo ""

# ==============================================
# 2. BESTÄTIGUNG
# ==============================================
echo -e "${RED}⚠️  ACHTUNG: Folgende Ressourcen werden GELÖSCHT:${NC}"
echo ""

[ ! -z "$DB_INSTANCE_ID" ] && echo "  🖥️  Database Instance: $DB_INSTANCE_ID"
[ ! -z "$WEB_INSTANCE_ID" ] && echo "  🖥️  Webserver Instance: $WEB_INSTANCE_ID"
[ ! -z "$DB_SG_ID" ] && echo "  🛡️  Database Security Group: $DB_SG_ID"
[ ! -z "$WEB_SG_ID" ] && echo "  🛡️  Webserver Security Group: $WEB_SG_ID"

echo ""
read -p "Fortfahren? (ja/nein): " CONFIRM

if [ "$CONFIRM" != "ja" ]; then
    echo -e "${YELLOW}Abgebrochen.${NC}"
    exit 0
fi

echo ""

# ==============================================
# 3. INSTANZEN TERMINIEREN
# ==============================================
echo -e "${YELLOW}[2/4] Terminiere EC2-Instanzen...${NC}"

INSTANCES_TO_TERMINATE=""
[ ! -z "$DB_INSTANCE_ID" ] && INSTANCES_TO_TERMINATE="$INSTANCES_TO_TERMINATE $DB_INSTANCE_ID"
[ ! -z "$WEB_INSTANCE_ID" ] && INSTANCES_TO_TERMINATE="$INSTANCES_TO_TERMINATE $WEB_INSTANCE_ID"

if [ ! -z "$INSTANCES_TO_TERMINATE" ]; then
    aws ec2 terminate-instances --instance-ids $INSTANCES_TO_TERMINATE --region $REGION > /dev/null
    echo "  ✓ Terminierung gestartet: $INSTANCES_TO_TERMINATE"
    
    echo "  Warte bis Instanzen terminiert sind..."
    aws ec2 wait instance-terminated --instance-ids $INSTANCES_TO_TERMINATE --region $REGION 2>/dev/null || sleep 30
    echo -e "${GREEN}  ✓ Instanzen terminiert${NC}"
else
    echo "  Keine Instanzen zum Terminieren"
fi

echo ""

# ==============================================
# 4. SECURITY GROUPS LÖSCHEN
# ==============================================
echo -e "${YELLOW}[3/4] Lösche Security Groups...${NC}"

sleep 5  # Warten damit AWS die Ressourcen freigibt

if [ ! -z "$WEB_SG_ID" ]; then
    aws ec2 delete-security-group --group-id $WEB_SG_ID --region $REGION 2>/dev/null && \
        echo "  ✓ Webserver Security Group gelöscht" || \
        echo "  ! Webserver Security Group konnte nicht gelöscht werden"
fi

if [ ! -z "$DB_SG_ID" ]; then
    aws ec2 delete-security-group --group-id $DB_SG_ID --region $REGION 2>/dev/null && \
        echo "  ✓ Database Security Group gelöscht" || \
        echo "  ! Database Security Group konnte nicht gelöscht werden"
fi

# Falls keine IDs vorhanden, versuche über Namen
if [ -z "$WEB_SG_ID" ] && [ -z "$DB_SG_ID" ]; then
    aws ec2 delete-security-group --group-name nextcloud-web-sg --region $REGION 2>/dev/null && \
        echo "  ✓ nextcloud-web-sg gelöscht" || true
    aws ec2 delete-security-group --group-name nextcloud-db-sg --region $REGION 2>/dev/null && \
        echo "  ✓ nextcloud-db-sg gelöscht" || true
fi

echo ""

# ==============================================
# 5. LOKALE DATEIEN
# ==============================================
echo -e "${YELLOW}[4/4] Lokale Dateien aufräumen...${NC}"

echo ""
echo "Vorhandene Dateien:"
[ -f "deployment-info.json" ] && echo "  • deployment-info.json"
[ -f "cloud-init-database.yaml" ] && echo "  • cloud-init-database.yaml"
[ -f "cloud-init-webserver.yaml" ] && echo "  • cloud-init-webserver.yaml"

echo ""
read -p "Sollen diese Dateien auch gelöscht werden? (ja/nein): " DELETE_FILES

if [ "$DELETE_FILES" == "ja" ]; then
    rm -f deployment-info.json
    rm -f cloud-init-database.yaml
    rm -f cloud-init-webserver.yaml
    echo -e "${GREEN}  ✓ Lokale Dateien gelöscht${NC}"
else
    echo "  Dateien behalten"
fi

echo ""

# ==============================================
# ZUSAMMENFASSUNG
# ==============================================
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   CLEANUP ABGESCHLOSSEN!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Gelöschte Ressourcen:"
[ ! -z "$DB_INSTANCE_ID" ] && echo "  ✓ Database Instance"
[ ! -z "$WEB_INSTANCE_ID" ] && echo "  ✓ Webserver Instance"
echo "  ✓ Security Groups"
echo ""
echo -e "${YELLOW}💡 Tipp: Überprüfe in der AWS Console ob alles weg ist.${NC}"
echo ""