# Nextcloud Database Server Deployment
# Modul 346 - Projektarbeit
# Ausführen: .\deploy-database.ps1

$ErrorActionPreference = "Stop"

Write-Host "Nextcloud Datenbank-Server Deployment gestartet..." -ForegroundColor Green
Write-Host ""

# ============================================
# KONFIGURATION
# ============================================
$REGION = "us-east-1"
$KEY_NAME = "nextcloud-key"
$AMI_ID = "ami-0e2c8caa4b6378d8c"  # Ubuntu 22.04 LTS in us-east-1
$INSTANCE_TYPE = "t2.micro"
$SG_NAME = "nextcloud-db-sg"

# Datenbank Credentials (sicher generiert)
$DB_ROOT_PASSWORD = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object {[char]$_})
$DB_NAME = "nextcloud"
$DB_USER = "nextcloud_user"
$DB_PASSWORD = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object {[char]$_})

Write-Host "Konfiguration:" -ForegroundColor Cyan
Write-Host "   Region: $REGION"
Write-Host "   Instance Type: $INSTANCE_TYPE"
Write-Host "   Datenbank: MariaDB"
Write-Host ""

# ============================================
# 1. KEY PAIR ERSTELLEN/PRÜFEN
# ============================================
Write-Host "Prüfe SSH Key Pair..." -ForegroundColor Yellow

try {
    $existingKey = aws ec2 describe-key-pairs --key-names $KEY_NAME --region $REGION 2>$null | ConvertFrom-Json
    Write-Host "   Key Pair '$KEY_NAME' existiert bereits" -ForegroundColor Green
} catch {
    Write-Host "   Erstelle neuen Key Pair '$KEY_NAME'..." -ForegroundColor Yellow
    $keyOutput = aws ec2 create-key-pair --key-name $KEY_NAME --region $REGION --query 'KeyMaterial' --output text
    
    # Key speichern
    $keyOutput | Out-File -FilePath ".\$KEY_NAME.pem" -Encoding ASCII
    Write-Host "    Key Pair erstellt und gespeichert: $KEY_NAME.pem" -ForegroundColor Green
    Write-Host "     WICHTIG: Bewahre diese Datei sicher auf!" -ForegroundColor Red
}

Write-Host ""

# ============================================
# 2. SECURITY GROUP ERSTELLEN
# ============================================
Write-Host "  Erstelle Security Group für Datenbank..." -ForegroundColor Yellow

# Prüfen ob SG existiert
try {
    $existingSG = aws ec2 describe-security-groups --group-names $SG_NAME --region $REGION 2>$null | ConvertFrom-Json
    $SG_ID = $existingSG.SecurityGroups[0].GroupId
    Write-Host "    Security Group existiert bereits: $SG_ID" -ForegroundColor Green
} catch {
    # Security Group erstellen
    $sgOutput = aws ec2 create-security-group `
        --group-name $SG_NAME `
        --description "Security Group for Nextcloud Database Server" `
        --region $REGION | ConvertFrom-Json
    
    $SG_ID = $sgOutput.GroupId
    Write-Host "    Security Group erstellt: $SG_ID" -ForegroundColor Green
    
    # SSH Zugriff (nur für Debugging)
    aws ec2 authorize-security-group-ingress `
        --group-id $SG_ID `
        --protocol tcp `
        --port 22 `
        --cidr 0.0.0.0/0 `
        --region $REGION | Out-Null
    
    # MySQL/MariaDB Port (wird später auf Webserver-IP eingeschränkt)
    aws ec2 authorize-security-group-ingress `
        --group-id $SG_ID `
        --protocol tcp `
        --port 3306 `
        --cidr 0.0.0.0/0 `
        --region $REGION | Out-Null
    
    Write-Host "   Firewall-Regeln konfiguriert (Port 22, 3306)" -ForegroundColor Green
}

Write-Host ""

# ============================================
# 3. CLOUD-INIT SCRIPT ERSTELLEN
# ============================================
$CLOUD_INIT = @"
#cloud-config

# Nextcloud Database Server Setup
# Modul 346 - Automatisierte Installation

package_update: true
package_upgrade: true

packages:
  - mariadb-server
  - mariadb-client

write_files:
  - path: /root/db-setup.sql
    content: |
      -- Root Password setzen
      ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';
      
      -- Nextcloud Datenbank erstellen
      CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
      
      -- Nextcloud User erstellen mit Remote-Zugriff
      CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
      GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';
      FLUSH PRIVILEGES;
      
  - path: /etc/mysql/mariadb.conf.d/60-nextcloud.cnf
    content: |
      [mysqld]
      bind-address = 0.0.0.0
      max_connections = 200
      innodb_buffer_pool_size = 128M

runcmd:
  # MariaDB Service starten
  - systemctl start mariadb
  - systemctl enable mariadb
  
  # Warten bis MariaDB bereit ist
  - sleep 10
  
  # Datenbank Setup ausführen
  - mysql < /root/db-setup.sql
  
  # MariaDB neustarten mit neuer Config
  - systemctl restart mariadb
  
  # Status ausgeben
  - echo "=== DATABASE SERVER READY ==="
  - echo "Database: $DB_NAME"
  - echo "User: $DB_USER"
  - echo "Password: $DB_PASSWORD"
  - echo "Root Password: $DB_ROOT_PASSWORD"
  - echo "Private IP: `$(hostname -I | awk '{print `$1}')`"

final_message: "Nextcloud Database Server installation complete after `$UPTIME seconds"
"@

# Cloud-Init in Datei speichern (für Dokumentation)
$CLOUD_INIT | Out-File -FilePath "cloud-init-database.yaml" -Encoding UTF8
Write-Host " Cloud-Init Script gespeichert: cloud-init-database.yaml" -ForegroundColor Cyan

# Base64 encodieren für AWS
$CLOUD_INIT_B64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($CLOUD_INIT))

Write-Host ""

# ============================================
# 4. EC2 INSTANZ STARTEN
# ============================================
Write-Host "  Starte EC2-Instanz für Datenbank-Server..." -ForegroundColor Yellow

$instanceOutput = aws ec2 run-instances `
    --image-id $AMI_ID `
    --instance-type $INSTANCE_TYPE `
    --key-name $KEY_NAME `
    --security-group-ids $SG_ID `
    --user-data $CLOUD_INIT_B64 `
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Nextcloud-Database},{Key=Project,Value=M346}]" `
    --region $REGION | ConvertFrom-Json

$INSTANCE_ID = $instanceOutput.Instances[0].InstanceId

Write-Host "    Instanz gestartet: $INSTANCE_ID" -ForegroundColor Green
Write-Host "    Warte bis Instanz läuft..." -ForegroundColor Yellow

# Warten bis Instanz läuft
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

Write-Host "    Instanz läuft!" -ForegroundColor Green
Write-Host ""

# ============================================
# 5. IP-ADRESSEN ABRUFEN
# ============================================
Write-Host " Rufe IP-Adressen ab..." -ForegroundColor Yellow

$instanceDetails = aws ec2 describe-instances `
    --instance-ids $INSTANCE_ID `
    --region $REGION | ConvertFrom-Json

$PRIVATE_IP = $instanceDetails.Reservations[0].Instances[0].PrivateIpAddress
$PUBLIC_IP = $instanceDetails.Reservations[0].Instances[0].PublicIpAddress

Write-Host "   Private IP: $PRIVATE_IP" -ForegroundColor Cyan
Write-Host "   Public IP: $PUBLIC_IP" -ForegroundColor Cyan
Write-Host ""

# ============================================
# 6. KONFIGURATION SPEICHERN
# ============================================
Write-Host " Speichere Konfiguration für Webserver-Deployment..." -ForegroundColor Yellow

$config = @{
    db_instance_id = $INSTANCE_ID
    db_private_ip = $PRIVATE_IP
    db_public_ip = $PUBLIC_IP
    db_security_group_id = $SG_ID
    db_name = $DB_NAME
    db_user = $DB_USER
    db_password = $DB_PASSWORD
    db_root_password = $DB_ROOT_PASSWORD
    key_name = $KEY_NAME
    region = $REGION
} | ConvertTo-Json

$config | Out-File -FilePath "db-config.json" -Encoding UTF8

Write-Host "    Gespeichert in: db-config.json" -ForegroundColor Green
Write-Host ""

# ============================================
# ZUSAMMENFASSUNG
# ============================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host " DATENBANK-SERVER ERFOLGREICH DEPLOYED!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host " Server Details:" -ForegroundColor Cyan
Write-Host "   Instance ID: $INSTANCE_ID"
Write-Host "   Private IP:  $PRIVATE_IP"
Write-Host "   Public IP:   $PUBLIC_IP"
Write-Host ""
Write-Host " Datenbank Zugangsdaten:" -ForegroundColor Cyan
Write-Host "   Host:     $PRIVATE_IP"
Write-Host "   Port:     3306"
Write-Host "   Database: $DB_NAME"
Write-Host "   User:     $DB_USER"
Write-Host "   Password: $DB_PASSWORD"
Write-Host ""
Write-Host "  WICHTIG:" -ForegroundColor Yellow
Write-Host "   1. Warte ~2-3 Minuten bis Cloud-Init fertig ist"
Write-Host "   2. Führe danach deploy-webserver.ps1 aus"
Write-Host "   3. Die Zugangsdaten sind in db-config.json gespeichert"
Write-Host ""
Write-Host " Status prüfen mit:" -ForegroundColor Cyan
Write-Host "   aws ec2 get-console-output --instance-id $INSTANCE_ID --region $REGION"
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green