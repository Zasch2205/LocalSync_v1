import Foundation

enum AppContainer {
    static func makeSyncViewModel() -> SyncViewModel {
        let localStore = LocalFileStore()
        let nasClient = WebDAVNASClient()
        let syncService = SyncService(nasClient: nasClient, localFileStore: localStore)
        let configStore = ConnectionConfigStore()
        let passwordStore = KeychainPasswordStore()
        return SyncViewModel(
            syncService: syncService,
            configStore: configStore,
            passwordStore: passwordStore
        )
    }
}
