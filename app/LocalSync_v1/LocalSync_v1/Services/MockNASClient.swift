import Foundation

final class MockNASClient: NASClient {
    func listPDFs(path: String) async throws -> [SyncFile] {
        [
            SyncFile(filename: "Angebot.pdf", sizeBytes: 153_600, modifiedAt: .now.addingTimeInterval(-86_400), location: .remote),
            SyncFile(filename: "Vertrag.pdf", sizeBytes: 402_100, modifiedAt: .now.addingTimeInterval(-3_600), location: .remote)
        ]
    }

    func downloadFile(remotePath: String, to localURL: URL) async throws {
        let placeholder = Data("Mock content for \(remotePath)".utf8)
        try placeholder.write(to: localURL, options: .atomic)
    }

    func uploadFile(localURL: URL, remotePath: String) async throws {
    }
}

