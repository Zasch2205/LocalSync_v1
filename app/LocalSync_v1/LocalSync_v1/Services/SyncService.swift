import Foundation

enum SyncServiceError: LocalizedError {
    case emptyFilename

    var errorDescription: String? {
        switch self {
        case .emptyFilename:
            return "Bitte einen Dateinamen eingeben."
        }
    }
}

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
        _ = try await downloadWithIncrementedNameIfNeeded(remoteFile: remoteFile, connection: connection)
    }

    func downloadWithIncrementedNameIfNeeded(remoteFile: SyncFile, connection: ConnectionConfig) async throws -> String {
        let resolvedName = resolveAvailableLocalFilename(baseFilename: remoteFile.filename)
        let targetURL = localFileStore.localURL(filename: resolvedName)
        try await nasClient.downloadFile(connection: connection, remoteFilename: remoteFile.filename, to: targetURL)
        return resolvedName
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

    func renameLocalFile(from oldFilename: String, to requestedFilename: String) throws -> String {
        let resolvedName = try normalizeFilename(requestedFilename, fallbackFrom: oldFilename)
        try localFileStore.renameLocalFile(from: oldFilename, to: resolvedName)
        return resolvedName
    }

    func downloadSingleRemoteFile(remoteFile: SyncFile, connection: ConnectionConfig) async throws -> String {
        try await downloadWithIncrementedNameIfNeeded(remoteFile: remoteFile, connection: connection)
    }

    func deleteRemoteFile(filename: String, connection: ConnectionConfig) async throws {
        try await nasClient.deleteFile(connection: connection, remoteFilename: filename)
    }

    func renameRemoteFile(from oldFilename: String, to requestedFilename: String, connection: ConnectionConfig) async throws -> String {
        let resolvedName = try normalizeFilename(requestedFilename, fallbackFrom: oldFilename)
        try await nasClient.renameFile(connection: connection, from: oldFilename, to: resolvedName)
        return resolvedName
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

    private func normalizeFilename(_ requestedFilename: String, fallbackFrom originalFilename: String) throws -> String {
        let trimmed = requestedFilename.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw SyncServiceError.emptyFilename
        }

        let originalExtension = (originalFilename as NSString).pathExtension
        let requestedExtension = (trimmed as NSString).pathExtension
        if requestedExtension.isEmpty, !originalExtension.isEmpty {
            return "\(trimmed).\(originalExtension)"
        }
        return trimmed
    }

    private func resolveAvailableLocalFilename(baseFilename: String) -> String {
        if !localFileStore.fileExists(filename: baseFilename) {
            return baseFilename
        }

        let base = (baseFilename as NSString).deletingPathExtension
        let ext = (baseFilename as NSString).pathExtension

        var index = 1
        while true {
            let candidateBase = "\(base)_\(index)"
            let candidate = ext.isEmpty ? candidateBase : "\(candidateBase).\(ext)"
            if !localFileStore.fileExists(filename: candidate) {
                return candidate
            }
            index += 1
        }
    }
}
