import Foundation

final class WebDAVNASClient: NASClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func testConnection(connection: ConnectionConfig) async throws {
        _ = try await listPDFs(connection: connection)
    }

    func fileExists(connection: ConnectionConfig, remoteFilename: String) async throws -> Bool {
        let fileURL = try buildRemoteFileURL(connection: connection, filename: remoteFilename)
        var request = URLRequest(url: fileURL)
        request.httpMethod = "HEAD"
        applyBasicAuth(to: &request, connection: connection)

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        switch http.statusCode {
        case 200...299:
            return true
        case 404:
            return false
        case 401:
            throw NASClientError.unauthorized
        default:
            throw NASClientError.serverError(http.statusCode)
        }
    }

    func listPDFs(connection: ConnectionConfig) async throws -> [SyncFile] {
        let directoryURL = try buildRemoteDirectoryURL(connection: connection)
        var request = URLRequest(url: directoryURL)
        request.httpMethod = "PROPFIND"
        request.setValue("1", forHTTPHeaderField: "Depth")
        request.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = """
        <?xml version="1.0" encoding="utf-8" ?>
        <d:propfind xmlns:d="DAV:">
          <d:prop>
            <d:getlastmodified />
            <d:getcontentlength />
            <d:resourcetype />
          </d:prop>
        </d:propfind>
        """.data(using: .utf8)
        applyBasicAuth(to: &request, connection: connection)

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        let parser = WebDAVPropfindParser()
        let entries = try parser.parse(data: data)

        return entries
            .filter { !$0.isCollection }
            .compactMap { entry in
                let filename = extractFilename(fromHref: entry.href)
                guard filename.lowercased().hasSuffix(".pdf") else {
                    return nil
                }

                return SyncFile(
                    filename: filename,
                    sizeBytes: entry.contentLength ?? 0,
                    modifiedAt: entry.lastModified ?? .distantPast,
                    location: .remote
                )
            }
            .sorted { $0.filename.localizedCaseInsensitiveCompare($1.filename) == .orderedAscending }
    }

    func downloadFile(connection: ConnectionConfig, remoteFilename: String, to localURL: URL) async throws {
        let fileURL = try buildRemoteFileURL(connection: connection, filename: remoteFilename)
        var request = URLRequest(url: fileURL)
        request.httpMethod = "GET"
        applyBasicAuth(to: &request, connection: connection)

        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        try data.write(to: localURL, options: .atomic)
    }

    func uploadFile(connection: ConnectionConfig, localURL: URL, remoteFilename: String) async throws {
        let fileURL = try buildRemoteFileURL(connection: connection, filename: remoteFilename)
        var request = URLRequest(url: fileURL)
        request.httpMethod = "PUT"
        request.setValue("application/pdf", forHTTPHeaderField: "Content-Type")
        applyBasicAuth(to: &request, connection: connection)

        let bodyData = try Data(contentsOf: localURL)
        let (_, response) = try await session.upload(for: request, from: bodyData)
        try validate(response: response)
    }

    func deleteFile(connection: ConnectionConfig, remoteFilename: String) async throws {
        let fileURL = try buildRemoteFileURL(connection: connection, filename: remoteFilename)
        var request = URLRequest(url: fileURL)
        request.httpMethod = "DELETE"
        applyBasicAuth(to: &request, connection: connection)

        let (_, response) = try await session.data(for: request)
        try validate(response: response)
    }

    func renameFile(connection: ConnectionConfig, from oldRemoteFilename: String, to newRemoteFilename: String) async throws {
        let sourceURL = try buildRemoteFileURL(connection: connection, filename: oldRemoteFilename)
        let destinationURL = try buildRemoteFileURL(connection: connection, filename: newRemoteFilename)
        var request = URLRequest(url: sourceURL)
        request.httpMethod = "MOVE"
        request.setValue(destinationURL.absoluteString, forHTTPHeaderField: "Destination")
        request.setValue("F", forHTTPHeaderField: "Overwrite")
        applyBasicAuth(to: &request, connection: connection)

        let (_, response) = try await session.data(for: request)
        try validate(response: response)
    }

    private func applyBasicAuth(to request: inout URLRequest, connection: ConnectionConfig) {
        guard !connection.username.isEmpty else { return }
        let credentials = "\(connection.username):\(connection.password)"
        guard let encoded = credentials.data(using: .utf8)?.base64EncodedString() else { return }
        request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
    }

    private func buildRemoteDirectoryURL(connection: ConnectionConfig) throws -> URL {
        guard let baseURL = connection.baseURL else {
            throw NASClientError.invalidBaseURL
        }

        let normalizedPath = normalizeRemotePath(connection.remotePath)
        guard let directoryURL = URL(string: normalizedPath, relativeTo: baseURL)?.absoluteURL else {
            throw NASClientError.invalidRemotePath
        }
        return directoryURL
    }

    private func buildRemoteFileURL(connection: ConnectionConfig, filename: String) throws -> URL {
        let directoryURL = try buildRemoteDirectoryURL(connection: connection)
        return directoryURL.appendingPathComponent(filename)
    }

    private func normalizeRemotePath(_ remotePath: String) -> String {
        let trimmed = remotePath.trimmingCharacters(in: .whitespacesAndNewlines)
        let withLeadingSlash = trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)"
        return withLeadingSlash.hasSuffix("/") ? withLeadingSlash : "\(withLeadingSlash)/"
    }

    private func extractFilename(fromHref href: String) -> String {
        if let url = URL(string: href) {
            return url.lastPathComponent.removingPercentEncoding ?? url.lastPathComponent
        }

        let raw = href.split(separator: "/").last.map(String.init) ?? href
        return raw.removingPercentEncoding ?? raw
    }

    private func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        switch http.statusCode {
        case 200...299, 207:
            return
        case 401:
            throw NASClientError.unauthorized
        default:
            throw NASClientError.serverError(http.statusCode)
        }
    }
}

private struct WebDAVEntry {
    var href: String = ""
    var contentLength: Int64?
    var lastModified: Date?
    var isCollection = false
}

private final class WebDAVPropfindParser: NSObject, XMLParserDelegate {
    private var entries: [WebDAVEntry] = []
    private var currentEntry = WebDAVEntry()
    private var currentElementName = ""
    private var currentText = ""

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return formatter
    }()

    func parse(data: Data) throws -> [WebDAVEntry] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else {
            throw parser.parserError ?? URLError(.cannotParseResponse)
        }
        return entries
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElementName = localName(from: elementName)
        currentText = ""

        if currentElementName == "response" {
            currentEntry = WebDAVEntry()
        }

        if currentElementName == "collection" {
            currentEntry.isCollection = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let normalized = localName(from: elementName)
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized == "href" {
            currentEntry.href = text
        } else if normalized == "getcontentlength" {
            currentEntry.contentLength = Int64(text)
        } else if normalized == "getlastmodified" {
            currentEntry.lastModified = dateFormatter.date(from: text)
        } else if normalized == "response" {
            if !currentEntry.href.isEmpty {
                entries.append(currentEntry)
            }
        }

        currentText = ""
    }

    private func localName(from elementName: String) -> String {
        elementName
            .split(separator: ":")
            .last
            .map(String.init)?
            .lowercased() ?? elementName.lowercased()
    }
}
