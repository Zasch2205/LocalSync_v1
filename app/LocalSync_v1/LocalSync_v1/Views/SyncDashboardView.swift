import SwiftUI

struct SyncDashboardView: View {
    @StateObject private var viewModel: SyncViewModel
    @State private var isSettingsPresented = false

    init(viewModel: SyncViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Aktionen") {
                    Button("NAS-Dateien anzeigen") {
                        Task { await viewModel.loadRemoteFiles() }
                    }
                    .disabled(viewModel.isBusy)

                    Button("iPhone/iPad-Dateien anzeigen") {
                        Task { await viewModel.loadLocalFiles() }
                    }
                    .disabled(viewModel.isBusy)

                    Button("Auf iPhone/iPad laden") {
                        Task { await viewModel.downloadAllRemoteFiles() }
                    }
                    .disabled(viewModel.isBusy || viewModel.remoteFiles.isEmpty)

                    Button("Auf NAS laden") {
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

                Section("NAS PDFs") {
                    ForEach(viewModel.remoteFiles) { file in
                        Text(file.filename)
                    }
                }

                Section("iPhone/iPad PDFs") {
                    ForEach(viewModel.localFiles) { file in
                        Text(file.filename)
                    }
                }
            }
            .navigationTitle("LocalSync")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView(
                    connection: $viewModel.connection,
                    isBusy: viewModel.isBusy,
                    onTestConnection: { Task { await viewModel.testConnection() } }
                )
            }
        }
    }
}
