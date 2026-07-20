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

    init(syncService: SyncService) {
        self.syncService = syncService
    }

    func loadRemoteFiles() async {
        await runTask {
            remoteFiles = try await syncService.fetchRemotePDFs(connection: connection)
            lastMessage = "Remote-Dateien geladen: \(remoteFiles.count)"
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
