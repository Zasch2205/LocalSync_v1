import Foundation

final class SyncService {
    private let nasClient: NASClient
    private let localFileStore: LocalFileStore

    init(nasClient: NASClient, localFileStore: LocalFileStore) {
        self.nasClient = nasClient
        self.localFileStore = localFileStore
    }

    func testConnection(connection: ConnectionConfig) async throws {
        try await nasClient.testConnection(connection: connection)
    }

    func fetchRemotePDFs(connection: ConnectionConfig) async throws -> [SyncFile] {
        try await nasClient.listPDFs(connection: connection)
    }

    func listLocalPDFs() throws -> [SyncFile] {
        try localFileStore.listLocalPDFs()
    }

    func download(remoteFile: SyncFile, connection: ConnectionConfig) async throws {
        let targetURL = localFileStore.localURL(filename: remoteFile.filename)
        try await nasClient.downloadFile(connection: connection, remoteFilename: remoteFile.filename, to: targetURL)
    }

    func upload(localFile: SyncFile, connection: ConnectionConfig) async throws {
        let localURL = localFileStore.localURL(filename: localFile.filename)
        try await nasClient.uploadFile(connection: connection, localURL: localURL, remoteFilename: localFile.filename)
    }

    func uploadWithIncrementedNameIfNeeded(localFile: SyncFile, connection: ConnectionConfig) async throws -> String {
        let localURL = localFileStore.localURL(filename: localFile.filename)
        let resolvedName = try await resolveAvailableRemoteFilename(baseFilename: localFile.filename, connection: connection)
        try await nasClient.uploadFile(connection: connection, localURL: localURL, remoteFilename: resolvedName)
        return resolvedName
    }

    func localFileURL(filename: String) -> URL {
        localFileStore.localURL(filename: filename)
    }

    func deleteLocalFile(filename: String) throws {
        try localFileStore.deleteLocalFile(filename: filename)
    }

    private func resolveAvailableRemoteFilename(baseFilename: String, connection: ConnectionConfig) async throws -> String {
        let base = (baseFilename as NSString).deletingPathExtension
        let ext = (baseFilename as NSString).pathExtension

        if try await !nasClient.fileExists(connection: connection, remoteFilename: baseFilename) {
            return baseFilename
        }

        var index = 1
        while true {
            let candidateBase = "\(base)_\(index)"
            let candidate = ext.isEmpty ? candidateBase : "\(candidateBase).\(ext)"
            if try await !nasClient.fileExists(connection: connection, remoteFilename: candidate) {
                return candidate
            }
            index += 1
        }
    }
}
