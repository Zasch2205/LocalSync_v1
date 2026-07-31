import Foundation

final class LocalFileStore {
    private let fileManager = FileManager.default
    private let appFolderName = "LocalSync"
    private let markerFilename = "README.txt"

    var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var appDocumentsDirectory: URL {
        documentsDirectory.appendingPathComponent(appFolderName, isDirectory: true)
    }

    private func ensureAppDocumentsDirectoryExists() throws {
        let directory = appDocumentsDirectory
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        try migrateLegacyPDFFilesIfNeeded(to: directory)

        let markerFile = directory.appendingPathComponent(markerFilename)
        if !fileManager.fileExists(atPath: markerFile.path) {
            let contents = "This folder is managed by LocalSync.\nPlace PDFs here to sync.\n"
            try contents.write(to: markerFile, atomically: true, encoding: .utf8)
        }
    }

    private func migrateLegacyPDFFilesIfNeeded(to directory: URL) throws {
        let legacyItems = try fileManager.contentsOfDirectory(
            at: documentsDirectory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        for legacyURL in legacyItems where legacyURL.pathExtension.lowercased() == "pdf" {
            guard (try legacyURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile ?? false) else {
                continue
            }

            let targetURL = directory.appendingPathComponent(legacyURL.lastPathComponent)
            guard !fileManager.fileExists(atPath: targetURL.path) else {
                continue
            }

            try fileManager.moveItem(at: legacyURL, to: targetURL)
        }
    }

    func listLocalPDFs() throws -> [SyncFile] {
        try ensureAppDocumentsDirectoryExists()

        let urls = try fileManager.contentsOfDirectory(
            at: appDocumentsDirectory,
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
        try? ensureAppDocumentsDirectoryExists()
        return appDocumentsDirectory.appendingPathComponent(filename)
    }

    func deleteLocalFile(filename: String) throws {
        let url = localURL(filename: filename)
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }
        try fileManager.removeItem(at: url)
    }

    func renameLocalFile(from oldFilename: String, to newFilename: String) throws {
        let sourceURL = localURL(filename: oldFilename)
        let destinationURL = localURL(filename: newFilename)
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            return
        }
        guard !fileManager.fileExists(atPath: destinationURL.path) else {
            throw CocoaError(.fileWriteFileExists)
        }
        try fileManager.moveItem(at: sourceURL, to: destinationURL)
    }
}
