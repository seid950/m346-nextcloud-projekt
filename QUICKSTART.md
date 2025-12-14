# Quick Start Guide

Schnellanleitung für das Nextcloud Deployment auf AWS.

## Voraussetzungen

- ✅ AWS Academy Lab gestartet
- ✅ AWS CLI installiert
- ✅ Git installiert

## Installation in 3 Schritten

### 1. Repository klonen

```bash
git clone https://github.com/seid950/m346-nextcloud-projekt.git
cd m346-nextcloud-projekt
```

### 2. Deployment starten

```bash
bash deploy.sh
```

Bestätigung mit `j` (ja).

### 3. Nach 2-3 Minuten: Nextcloud öffnen

Die URL wird am Ende des Scripts angezeigt:

```
http://XX.XX.XX.XX
```

## Setup-Assistent

1. **Admin-Account erstellen**
   - Username: frei wählbar
   - Passwort: frei wählbar (min. 8 Zeichen)

2. **Datenbank-Daten eingeben**
   
   Die Werte werden am Ende des Scripts angezeigt:
   
   ```
   Datenbank-Typ:      MySQL/MariaDB
   Datenbank-Host:     172.31.XX.XX
   Datenbank-Name:     nextcloud
   Datenbank-Benutzer: nextcloud
   Datenbank-Passwort: [aus Script-Ausgabe]
   Datenverzeichnis:   /var/nextcloud-data
   ```

3. **Installation abschließen** ✅

## Cleanup

Alle AWS-Ressourcen löschen:

```bash
bash cleanup.sh
```

Bestätigung mit `ja`.

## Hilfe

- **Logs prüfen:** Siehe README.md → Monitoring & Troubleshooting
- **Probleme:** GitHub Issues erstellen
- **Dokumentation:** Vollständige Docs in README.md

## Zeitaufwand

- ⏱️ Deployment: ~4 Minuten
- ⏱️ Setup-Assistent: ~1 Minute
- ⏱️ Cleanup: ~1 Minute

**Total: ~6 Minuten** bis zur fertigen Nextcloud-Installation!

---

Viel Erfolg! 🚀
