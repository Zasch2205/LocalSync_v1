import Foundation

struct SyncFile: Identifiable, Hashable {
    let id: String
    let filename: String
    let sizeBytes: Int64
    let modifiedAt: Date
    let location: SyncFileLocation

    init(filename: String, sizeBytes: Int64, modifiedAt: Date, location: SyncFileLocation) {
        self.id = filename
        self.filename = filename
        self.sizeBytes = sizeBytes
        self.modifiedAt = modifiedAt
        self.location = location
    }
}

enum SyncFileLocation: String {
    case local
    case remote
}

enum SyncState: String {
    case synced
    case localChanged
    case remoteChanged
    case conflict
    case unknown
}

