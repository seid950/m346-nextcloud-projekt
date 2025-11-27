#!/bin/bash

echo "Erstelle Projektstruktur..."

# Hauptordner
mkdir -p docs
mkdir -p docs/img
mkdir -p scripts
mkdir -p cloud-init
mkdir -p planning

# Dokumentationsdateien
touch docs/01_Einleitung.md
touch docs/02_Architektur.md
touch docs/03_Installation_Webserver.md
touch docs/04_Installation_DBserver.md
touch docs/05_Automation.md
touch docs/06_Tests.md
touch docs/07_Reflexion.md

# Bild-Platzhalter (optional)
touch docs/img/.gitkeep

# Planungsordner + Dateien
echo "# Projektplanung" > planning/PLANUNG.md
touch planning/aufgabenverteilung.md
touch planning/zeitplan.md

# Script-Platzhalter
touch scripts/.gitkeep

# Cloud-Init-Platzhalter
touch cloud-init/.gitkeep

# README anlegen nur wenn nicht vorhanden
if [ ! -f README.md ]; then
    echo "# Nextcloud Projekt – Modul 346" > README.md
    echo "" >> README.md
    echo "Dieses Repository enthält unsere Projektarbeit zur Installation von Nextcloud mit separatem Datenbankserver." >> README.md
fi

echo "Projektstruktur erfolgreich erstellt!"

