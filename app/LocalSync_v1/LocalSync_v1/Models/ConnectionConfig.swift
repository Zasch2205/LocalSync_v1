import Foundation

struct ConnectionConfig: Codable, Equatable {
    var baseURLString: String
    var username: String
    var remotePath: String

    static let empty = ConnectionConfig(baseURLString: "", username: "", remotePath: "/")

    var baseURL: URL? {
        URL(string: baseURLString)
    }
}

