import Foundation

enum AppContainer {
    static func makeSyncViewModel() -> SyncViewModel {
        let localStore = LocalFileStore()
        let nasClient = WebDAVNASClient()
        let syncService = SyncService(nasClient: nasClient, localFileStore: localStore)
        return SyncViewModel(syncService: syncService)
    }
}
