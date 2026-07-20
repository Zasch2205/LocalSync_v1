import Foundation

final class SyncService {
    private let nasClient: NASClient
    private let localFileStore: LocalFileStore

    init(nasClient: NASClient, localFileStore: LocalFileStore) {
        self.nasClient = nasClient
        self.localFileStore = localFileStore
    }

    func fetchRemotePDFs(remotePath: String) async throws -> [SyncFile] {
        try await nasClient.listPDFs(path: remotePath)
    }

    func listLocalPDFs() throws -> [SyncFile] {
        try localFileStore.listLocalPDFs()
    }

    func download(remoteFile: SyncFile, remotePath: String) async throws {
        let fromPath = remotePath.appending("/\(remoteFile.filename)")
        let targetURL = localFileStore.localURL(filename: remoteFile.filename)
        try await nasClient.downloadFile(remotePath: fromPath, to: targetURL)
    }

    func upload(localFile: SyncFile, remotePath: String) async throws {
        let localURL = localFileStore.localURL(filename: localFile.filename)
        let destination = remotePath.appending("/\(localFile.filename)")
        try await nasClient.uploadFile(localURL: localURL, remotePath: destination)
    }
}

