import Foundation

protocol NASClient {
    func listPDFs(connection: ConnectionConfig) async throws -> [SyncFile]
    func downloadFile(connection: ConnectionConfig, remoteFilename: String, to localURL: URL) async throws
    func uploadFile(connection: ConnectionConfig, localURL: URL, remoteFilename: String) async throws
}

enum NASClientError: LocalizedError {
    case notImplemented
    case invalidBaseURL
    case invalidRemotePath
    case unauthorized
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "NAS client is not implemented yet."
        case .invalidBaseURL:
            return "Ungültige WebDAV URL."
        case .invalidRemotePath:
            return "Ungültiger Remote-Pfad."
        case .unauthorized:
            return "Anmeldung fehlgeschlagen (401)."
        case .serverError(let statusCode):
            return "Serverfehler mit Status \(statusCode)."
        }
    }
}
