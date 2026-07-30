import Foundation

final class MockNASClient: NASClient {
    func testConnection(connection: ConnectionConfig) async throws {
    }

    func fileExists(connection: ConnectionConfig, remoteFilename: String) async throws -> Bool {
        false
    }

    func listPDFs(connection: ConnectionConfig) async throws -> [SyncFile] {
        [
            SyncFile(filename: "Angebot.pdf", sizeBytes: 153_600, modifiedAt: .now.addingTimeInterval(-86_400), location: .remote),
            SyncFile(filename: "Vertrag.pdf", sizeBytes: 402_100, modifiedAt: .now.addingTimeInterval(-3_600), location: .remote)
        ]
    }

    func downloadFile(connection: ConnectionConfig, remoteFilename: String, to localURL: URL) async throws {
        let placeholder = Data("Mock content for \(remoteFilename)".utf8)
        try placeholder.write(to: localURL, options: .atomic)
    }

    func uploadFile(connection: ConnectionConfig, localURL: URL, remoteFilename: String) async throws {
    }
}
