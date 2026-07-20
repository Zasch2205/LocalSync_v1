import Foundation

final class ConnectionConfigStore {
    private let defaults: UserDefaults
    private let key = "localsync.connection.config.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> ConnectionConfig {
        guard let data = defaults.data(forKey: key) else {
            return .empty
        }

        do {
            return try JSONDecoder().decode(ConnectionConfig.self, from: data)
        } catch {
            return .empty
        }
    }

    func save(_ config: ConnectionConfig) {
        let persisted = ConnectionConfig(
            baseURLString: config.baseURLString,
            username: config.username,
            password: "",
            remotePath: config.remotePath
        )

        guard let data = try? JSONEncoder().encode(persisted) else {
            return
        }
        defaults.set(data, forKey: key)
    }
}

