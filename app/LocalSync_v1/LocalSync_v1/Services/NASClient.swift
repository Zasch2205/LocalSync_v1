import Foundation

protocol NASClient {
    func listPDFs(path: String) async throws -> [SyncFile]
    func downloadFile(remotePath: String, to localURL: URL) async throws
    func uploadFile(localURL: URL, remotePath: String) async throws
}

enum NASClientError: LocalizedError {
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "NAS client is not implemented yet."
        }
    }
}

