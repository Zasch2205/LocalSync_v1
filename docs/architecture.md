# LocalSync_v1 – Architektur (v1)

## Überblick
Die App besteht aus UI-Schicht, Sync-Logik, NAS-Client und lokalem Dateispeicher.

## Komponenten

### 1) UI (SwiftUI)
Verantwortlich für:
- NAS-Verbindungsdaten eingeben
- Remote-Dateien anzeigen
- Download/Upload manuell auslösen
- Sync-Status und Fehler anzeigen

### 2) SyncService
Verantwortlich für:
- Orchestrierung von Download/Upload
- Abgleich lokaler und remote Metadaten (Name, Größe, Änderungszeit)
- Konfliktentscheidung (v1: neuere Datei gewinnt)

Schnittstellen:
- `syncFromRemote()`
- `syncToRemote()`
- `resolveConflicts()`

### 3) NASClient (WebDAV)
Verantwortlich für:
- Authentifizierung
- Dateiliste abrufen
- Datei herunterladen
- Datei hochladen

Schnittstellen:
- `listPDFs(path:)`
- `downloadFile(remotePath:, localURL:)`
- `uploadFile(localURL:, remotePath:)`

### 4) LocalFileStore
Verantwortlich für:
- Lokale Dateiablage in App-Documents
- Lesen/Schreiben/Löschen lokaler PDFs
- Lesen lokaler Metadaten (mtime, size)

Schnittstellen:
- `listLocalPDFs()`
- `saveFile(data:, filename:)`
- `fileURL(filename:)`

### 5) MetadataStore (leichtgewichtig)
Verantwortlich für:
- Speicherung minimaler Sync-Metadaten:
  - `filename`
  - `lastLocalModified`
  - `lastRemoteModified`
  - `lastSyncAt`
  - `syncState`

Implementierung v1:
- JSON-Datei im App-Speicher (kein CoreData/SwiftData nötig)

## Datenfluss

### Download-Flow (NAS -> Lokal)
1. UI löst „Vom NAS laden“ aus.
2. SyncService ruft `NASClient.listPDFs`.
3. Für neue/aktualisierte Dateien wird `downloadFile` aufgerufen.
4. LocalFileStore speichert Datei lokal.
5. MetadataStore aktualisiert Sync-Status.

### Upload-Flow (Lokal -> NAS)
1. UI löst „Zum NAS hochladen“ aus.
2. SyncService prüft lokal geänderte PDFs.
3. Konfliktprüfung gegen Remote-Metadaten.
4. Bei Freigabe Upload via `NASClient.uploadFile`.
5. MetadataStore aktualisiert Sync-Status.

## Konfliktstrategie (v1)
- Vergleich über Änderungszeit (`modifiedAt`).
- Neuere Datei gewinnt.
- UI zeigt Konflikt-Hinweis nach Auflösung.

## Sicherheit
- Zugangsdaten nicht im Klartext in Dateien speichern.
- Nutzung von iOS Keychain für Credentials.
- Netzwerk nur über HTTPS/WebDAVS.

## Logging & Fehler
- Nutzerfreundliche Fehlermeldungen (Auth, Timeout, Dateifehler).
- Interne Logs für Debug-Builds.

## Erweiterungen (v2+)
- Hintergrund-Sync
- Delta-Sync/Hash-Vergleich
- Versionierung mit manueller Konfliktauflösung
- Selektive Ordner-/Datei-Filter
