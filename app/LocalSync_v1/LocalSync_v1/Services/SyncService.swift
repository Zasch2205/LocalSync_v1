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
}
