import Foundation

final class LocalFileStore {
    private let fileManager = FileManager.default

    var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func listLocalPDFs() throws -> [SyncFile] {
        let urls = try fileManager.contentsOfDirectory(
            at: documentsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )

        return try urls
            .filter { $0.pathExtension.lowercased() == "pdf" }
            .map { url in
                let values = try url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                return SyncFile(
                    filename: url.lastPathComponent,
                    sizeBytes: Int64(values.fileSize ?? 0),
                    modifiedAt: values.contentModificationDate ?? .distantPast,
                    location: .local
                )
            }
            .sorted { $0.filename.localizedCaseInsensitiveCompare($1.filename) == .orderedAscending }
    }

    func localURL(filename: String) -> URL {
        documentsDirectory.appendingPathComponent(filename)
    }

    func deleteLocalFile(filename: String) throws {
        let url = localURL(filename: filename)
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }
        try fileManager.removeItem(at: url)
    }
}
