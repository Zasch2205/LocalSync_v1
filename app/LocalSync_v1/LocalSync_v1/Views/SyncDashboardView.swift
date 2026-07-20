import SwiftUI

struct SyncDashboardView: View {
    @StateObject private var viewModel: SyncViewModel

    init(viewModel: SyncViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Verbindung") {
                    TextField("WebDAV URL", text: $viewModel.connection.baseURLString)
                    TextField("Benutzername", text: $viewModel.connection.username)
                    TextField("Remote-Pfad", text: $viewModel.connection.remotePath)
                }

                Section("Aktionen") {
                    Button("Remote laden") {
                        Task { await viewModel.loadRemoteFiles() }
                    }
                    .disabled(viewModel.isBusy)

                    Button("Lokal laden") {
                        Task { await viewModel.loadLocalFiles() }
                    }
                    .disabled(viewModel.isBusy)

                    Button("Alle herunterladen") {
                        Task { await viewModel.downloadAllRemoteFiles() }
                    }
                    .disabled(viewModel.isBusy || viewModel.remoteFiles.isEmpty)

                    Button("Alle hochladen") {
                        Task { await viewModel.uploadAllLocalFiles() }
                    }
                    .disabled(viewModel.isBusy)
                }

                Section("Status") {
                    Text(viewModel.lastMessage)
                    if viewModel.isBusy {
                        ProgressView()
                    }
                }

                Section("Remote PDFs") {
                    ForEach(viewModel.remoteFiles) { file in
                        Text(file.filename)
                    }
                }

                Section("Lokale PDFs") {
                    ForEach(viewModel.localFiles) { file in
                        Text(file.filename)
                    }
                }
            }
            .navigationTitle("LocalSync")
        }
    }
}

