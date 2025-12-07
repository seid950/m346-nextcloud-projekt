# Einleitung

## Projektübersicht

Dieses Projekt wurde im Rahmen des Moduls 346 "Cloudlösungen konzipieren und realisieren" am GBS St.Gallen durchgeführt. Ziel war es, Nextcloud als Cloud-Dienst vollautomatisiert auf AWS zu deployen.

## Projektziele

1. **Nextcloud Community Edition** auf AWS installieren
2. **Separate Server** für Webserver und Datenbank einrichten
3. **Infrastructure as Code** (IaC) mit Cloud-Init umsetzen
4. **Vollautomatisierung** des Deployments erreichen
5. **Dokumentation** aller Schritte und Tests

## Team

- **Seid Veseli** - Projektleiter, Script-Entwicklung, AWS-Konfiguration
- **Amar Ibraimi** - Script-Entwicklung, Testing, Deployment
- **Leandro Graf** - Dokumentation, Git-Management, Repository-Struktur

## Technologie-Stack

- **Cloud-Provider:** AWS (EC2)
- **Region:** us-east-1
- **Betriebssystem:** Ubuntu 22.04 LTS
- **Webserver:** Apache 2.4
- **Datenbank:** MariaDB 10.6
- **Application:** Nextcloud 28.0.1
- **IaC:** Cloud-Init (YAML)
- **Versionsverwaltung:** Git / GitHub

## Projektdauer

- **Start:** 02.12.2024
- **Ende:** 13.12.2024
- **Verfügbare Zeit:** 3 Lektionen à 2 Stunden

## Anforderungen gemäß Projektauftrag

✅ Nextcloud Community Edition (Archive-Installation)  
✅ Kein Docker, kein Web Installer  
✅ Separate Server für Web und Datenbank  
✅ Infrastructure as Code (Cloud-Init)  
✅ Versionsverwaltung mit Git  
✅ Markdown-Dokumentation  
✅ Test-Dokumentation mit Screenshots  

## Dokumentationsstruktur

Diese Dokumentation ist wie folgt aufgebaut:

1. **Einleitung** - Projektübersicht und Ziele
2. **Architektur** - Technische Struktur und Design
3. **Installation Webserver** - Nextcloud Installation
4. **Installation DB-Server** - Datenbank-Setup
5. **Automation** - Cloud-Init und Deployment
6. **Tests** - Test-Dokumentation mit Screenshots
7. **Reflexion** - Persönliche Erfahrungen