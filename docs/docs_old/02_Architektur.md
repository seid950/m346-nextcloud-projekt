##Erklärung der Projektordner
Ordner: docs

In diesem Ordner befindet sich die gesamte Projektdokumentation im Markdown-Format. Der Projektauftrag verlangt, dass die Dokumentation direkt im Git-Repository gepflegt wird.
Alle inhaltlichen Kapitel werden hier abgelegt.

Dateien in docs

01_Einleitung.md
Beschreibt das Projekt, die Ausgangslage, Ziele und den Projektauftrag.

02_Architektur.md
Dokumentiert die Infrastruktur, Netzwerkstruktur, Serveraufbau, verwendete Dienste und ein Architekturdiagramm.

03_Installation_Webserver.md
Enthält die Schritt-für-Schritt-Anleitung zur Installation des Webservers (Apache, PHP, Nextcloud).

04_Installation_DBserver.md
Beinhaltet die Installation und Konfiguration des Datenbankservers (MySQL), inklusive Erstellen der Datenbank und des Users.

05_Automation.md
Dokumentiert die Skripte und optionalen Cloud-Init Dateien, mit denen die Installation automatisiert werden kann. Dieser Teil ist relevant für den Bewertungspunkt Automatisierungsgrad.

06_Tests.md
Enthält die Testfälle, Testergebnisse und Screenshots. Dieser Teil ist wichtig für den Bewertungspunkt Tests.

07_Reflexion.md
Beinhaltet die Reflexion aller Teammitglieder über das Projekt, Arbeitsweise und Verbesserungsvorschläge. Wichtig für den Bewertungspunkt Reflexion.

Ordner docs/img

Hier werden alle Bilder der Dokumentation abgelegt, insbesondere Screenshots der Installation, AWS, Testdurchläufe und Diagramme.

Ordner: planning

Dieser Ordner enthält alle Dateien zur Planung und Organisation des Projekts. Diese Unterlagen dienen als Nachweis einer strukturierten Arbeitsweise.

Dateien in planning

PLANUNG.md
Übergreifende Projektplanung, Vorgehensmodell, Zielsetzung und Projektstruktur.

aufgabenverteilung.md
Dokumentiert, welche Aufgaben welches Teammitglied übernimmt. Relevanter Nachweis für den Bewertungspunkt Aufgabenverteilung.

zeitplan.md
Zeitliche Einteilung des Projekts, Arbeitsblöcke und geplante Abfolge der Arbeitsschritte.

Ordner: scripts

In diesem Ordner liegen alle Shell-Skripte, die für den Automatisierungsgrad verwendet werden.
Dazu gehören zum Beispiel:

Skript zur Installation des Webservers

Skript zur Installation des Datenbankservers

Skript zur Ausgabe der Datenbank-Zugangsdaten

Skript zur Statusprüfung der Dienste

Dieser Ordner ist wichtig für die Bewertungskriterien Automatisierungsgrad und Technik.

Ordner: cloud-init

Hier können Cloud-Init Dateien abgelegt werden, falls die Installation vollständig automatisiert über AWS beim Start einer Instanz erfolgen soll.
Cloud-Init ist ein optionaler, aber hochwertiger Bestandteil, der den Bewertungspunkt Inbetriebnahme sehr positiv beeinflussen kann.

Datei: README.md

Diese Datei befindet sich im Hauptverzeichnis des Repositories.
Sie enthält die zentrale Anleitung für die Inbetriebnahme der Lösung durch die Lehrperson.
Die README beschreibt:

Voraussetzungen

Schritt-für-Schritt-Anleitung

Verwendete Skripte

Starten der Server

Installation des Systems

Die README ist der wichtigste Einstiegspunkt für die Bewertung der Inbetriebnahme.
