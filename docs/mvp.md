# LocalSync_v1 – MVP

## Ziel
Eine iOS/iPadOS-App, die PDF-Dateien zwischen einem Synology NAS (Cloud/Netzwerkquelle) und lokalem App-Speicher synchronisiert, damit Dateien offline bearbeitet und später zurückgespielt werden können.

## Problem
- PDFs liegen auf dem NAS.
- Auf dem iPad sollen sie lokal verfügbar sein (offline nutzbar).
- Nach lokaler Bearbeitung sollen Änderungen wieder aufs NAS hochgeladen werden.

## MVP-Umfang (v1)
1. Verbindung zum NAS über WebDAV konfigurieren.
2. Liste verfügbarer PDF-Dateien vom NAS abrufen.
3. Ausgewählte PDFs lokal herunterladen.
4. Lokale PDF-Dateien in der App anzeigen.
5. Geänderte lokale PDFs zurück aufs NAS hochladen.
6. Einfaches Konfliktverhalten: „neuere Datei gewinnt“ (nach Änderungszeit).

## Nicht im MVP (später)
- Vollautomatische Hintergrund-Synchronisierung.
- Mehrbenutzer-Features.
- Erweiterte Konfliktauflösung mit Version-Historie.
- Unterstützung weiterer Dateitypen außer PDF.
- Erweiterung auf MP3 Dateien.

## User Stories
- Als Nutzer möchte ich meine NAS-PDFs lokal auf dem iPad speichern, um sie ohne Internet zu bearbeiten.
- Als Nutzer möchte ich später meine lokal geänderten PDFs wieder aufs NAS hochladen.
- Als Nutzer möchte ich sehen, welche Dateien lokal, remote oder geändert sind.

## Akzeptanzkriterien
- NAS-Verbindung kann gespeichert und getestet werden.
- Mindestens eine PDF kann erfolgreich heruntergeladen und lokal geöffnet werden.
- Mindestens eine lokal geänderte PDF kann erfolgreich zurück aufs NAS hochgeladen werden.
- Bei Konflikt (lokal + remote geändert) wird die neuere Datei verwendet und der Nutzer erhält einen Hinweis.

## Erste technische Entscheidungen
- Plattform: iPadOS/iOS (SwiftUI, Swift)
- Netzwerkprotokoll: WebDAV
- Lokaler Speicher: App Sandbox (Documents-Verzeichnis)
- Metadaten: zunächst leichtgewichtig (JSON/Dateiattribute), keine Datenbank im MVP

## Risiken
- Unterschiedliche WebDAV-Konfigurationen auf Synology.
- Dateikonflikte bei parallelen Änderungen.
- iOS-Dateizugriff und „Open in Place“-Verhalten bei externer Bearbeitung.

## Definition of Done (MVP)
- Verbindung, Download, lokales Anzeigen, Upload funktionieren stabil mit Testdateien.
- Basis-Fehlerbehandlung vorhanden (Netzwerkfehler, Auth-Fehler, Datei nicht gefunden).
- Projekt dokumentiert (README + docs/architecture.md + docs/mvp.md).
