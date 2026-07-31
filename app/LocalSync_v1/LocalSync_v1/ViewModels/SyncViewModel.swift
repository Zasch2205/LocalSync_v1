import Foundation
import Combine

@MainActor
final class SyncViewModel: ObservableObject {
    @Published var connection = ConnectionConfig.empty
    @Published var remoteFiles: [SyncFile] = []
    @Published var localFiles: [SyncFile] = []
    @Published var isBusy = false
    @Published var lastMessage = "Bereit"

    private let syncService: SyncService
    private let configStore: ConnectionConfigStore
    private let passwordStore: KeychainPasswordStore
    private var cancellables: Set<AnyCancellable> = []

    init(
        syncService: SyncService,
        configStore: ConnectionConfigStore,
        passwordStore: KeychainPasswordStore
    ) {
        self.syncService = syncService
        self.configStore = configStore
        self.passwordStore = passwordStore

        var saved = configStore.load()
        saved.password = passwordStore.loadPassword()
        connection = saved

        $connection
            .dropFirst()
            .sink { [weak self] newValue in
                self?.configStore.save(newValue)
                self?.passwordStore.savePassword(newValue.password)
            }
            .store(in: &cancellables)
    }

    func loadRemoteFiles() async {
        await runTask {
            remoteFiles = try await syncService.fetchRemotePDFs(connection: connection)
            lastMessage = "Remote-Dateien geladen: \(remoteFiles.count)"
        }
    }

    func testConnection() async {
        await runTask {
            try await syncService.testConnection(connection: connection)
            lastMessage = "Verbindung erfolgreich"
        }
    }

    func loadLocalFiles() async {
        await runTask {
            localFiles = try syncService.listLocalPDFs()
            lastMessage = "Lokale Dateien geladen: \(localFiles.count)"
        }
    }

    func downloadAllRemoteFiles() async {
        await runTask {
            for file in remoteFiles {
                try await syncService.download(remoteFile: file, connection: connection)
            }
            localFiles = try syncService.listLocalPDFs()
            lastMessage = "Download abgeschlossen: \(remoteFiles.count) Dateien"
        }
    }

    func uploadAllLocalFiles() async {
        await runTask {
            let files = try syncService.listLocalPDFs()
            for file in files {
                try await syncService.upload(localFile: file, connection: connection)
            }
            lastMessage = "Upload abgeschlossen: \(files.count) Dateien"
        }
    }

    func uploadSingleLocalFile(_ localFile: SyncFile) async {
        await runTask {
            let uploadedName = try await syncService.uploadWithIncrementedNameIfNeeded(localFile: localFile, connection: connection)
            remoteFiles = try await syncService.fetchRemotePDFs(connection: connection)
            if uploadedName == localFile.filename {
                lastMessage = "Datei hochgeladen: \(uploadedName)"
            } else {
                lastMessage = "Datei hochgeladen als: \(uploadedName)"
            }
        }
    }

    func deleteSingleLocalFile(_ localFile: SyncFile) async {
        await runTask {
            try syncService.deleteLocalFile(filename: localFile.filename)
            localFiles = try syncService.listLocalPDFs()
            lastMessage = "Lokal gelöscht: \(localFile.filename)"
        }
    }

    func renameSingleLocalFile(_ localFile: SyncFile, to newFilename: String) async {
        await runTask {
            let renamed = try syncService.renameLocalFile(from: localFile.filename, to: newFilename)
            localFiles = try syncService.listLocalPDFs()
            lastMessage = "Lokal umbenannt: \(localFile.filename) → \(renamed)"
        }
    }

    func downloadSingleRemoteFile(_ remoteFile: SyncFile) async {
        await runTask {
            let downloadedName = try await syncService.downloadSingleRemoteFile(remoteFile: remoteFile, connection: connection)
            localFiles = try syncService.listLocalPDFs()
            if downloadedName == remoteFile.filename {
                lastMessage = "Auf iPhone/iPad geladen: \(downloadedName)"
            } else {
                lastMessage = "Auf iPhone/iPad geladen als: \(downloadedName)"
            }
        }
    }

    func deleteSingleRemoteFile(_ remoteFile: SyncFile) async {
        await runTask {
            try await syncService.deleteRemoteFile(filename: remoteFile.filename, connection: connection)
            remoteFiles = try await syncService.fetchRemotePDFs(connection: connection)
            lastMessage = "NAS gelöscht: \(remoteFile.filename)"
        }
    }

    func renameSingleRemoteFile(_ remoteFile: SyncFile, to newFilename: String) async {
        await runTask {
            let renamed = try await syncService.renameRemoteFile(from: remoteFile.filename, to: newFilename, connection: connection)
            remoteFiles = try await syncService.fetchRemotePDFs(connection: connection)
            lastMessage = "NAS umbenannt: \(remoteFile.filename) → \(renamed)"
        }
    }

    func localFileURL(filename: String) -> URL {
        syncService.localFileURL(filename: filename)
    }

    private func runTask(_ operation: () async throws -> Void) async {
        isBusy = true
        defer { isBusy = false }

        do {
            try await operation()
        } catch {
            lastMessage = "Fehler: \(error.localizedDescription)"
        }
    }
}
