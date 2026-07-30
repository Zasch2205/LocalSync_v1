import SwiftUI

struct SyncDashboardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel: SyncViewModel
    @State private var isSettingsPresented = false
    @State private var selectedLocalPDFURL: URL?

    init(viewModel: SyncViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.14, blue: 0.34),
                        Color(red: 0.10, green: 0.24, blue: 0.56),
                        Color(red: 0.14, green: 0.33, blue: 0.70)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        AppLogoView()
                        if horizontalSizeClass == .regular {
                            settingsHeaderButton
                        }
                        actionCard
                        statusCard
                        fileListCard(title: "NAS PDFs", files: viewModel.remoteFiles, emptyText: "Keine NAS-PDFs geladen")
                        fileListCard(title: "iPhone/iPad PDFs", files: viewModel.localFiles, emptyText: "Keine lokalen PDFs gefunden")
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Image(systemName: hasMissingSettings ? "gearshape.badge.exclamationmark" : "gearshape")
                    }
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView(
                    connection: $viewModel.connection,
                    statusMessage: viewModel.lastMessage,
                    isBusy: viewModel.isBusy,
                    onTestConnection: { Task { await viewModel.testConnection() } }
                )
            }
            .sheet(isPresented: Binding(
                get: { selectedLocalPDFURL != nil },
                set: { if !$0 { selectedLocalPDFURL = nil } }
            )) {
                if let url = selectedLocalPDFURL {
                    PDFPreviewView(fileURL: url)
                }
            }
        }
    }

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Aktionen")
                .font(.headline)

            actionButton("NAS-Dateien anzeigen", systemImage: "externaldrive.fill.badge.icloud") {
                Task { await viewModel.loadRemoteFiles() }
            }
            .disabled(viewModel.isBusy || hasMissingSettings)

            actionButton("iPhone/iPad-Dateien anzeigen", systemImage: "iphone.gen3") {
                Task { await viewModel.loadLocalFiles() }
            }
            .disabled(viewModel.isBusy)

            actionButton("Auf iPhone/iPad laden", systemImage: "arrow.down.circle.fill") {
                Task { await viewModel.downloadAllRemoteFiles() }
            }
            .disabled(viewModel.isBusy || hasMissingSettings || viewModel.remoteFiles.isEmpty)

            actionButton("Auf NAS laden", systemImage: "arrow.up.circle.fill") {
                Task { await viewModel.uploadAllLocalFiles() }
            }
            .disabled(viewModel.isBusy || hasMissingSettings)
        }
        .padding(14)
        .cardStyle()
    }

    private var settingsHeaderButton: some View {
        HStack {
            Spacer()
            Button {
                isSettingsPresented = true
            } label: {
                Label("Einstellungen", systemImage: "gearshape.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .foregroundStyle(.white)
                    .background(Color(red: 0.14, green: 0.34, blue: 0.66), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.headline)
            Text(viewModel.lastMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if viewModel.isBusy {
                ProgressView()
                    .tint(.blue)
            }
        }
        .padding(14)
        .cardStyle()
    }

    private func fileListCard(title: String, files: [SyncFile], emptyText: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            if files.isEmpty {
                Text(emptyText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(files) { file in
                    HStack(spacing: 10) {
                        Image(systemName: "doc.richtext")
                            .foregroundStyle(Color(red: 0.74, green: 0.86, blue: 1.0))

                        if title == "iPhone/iPad PDFs" {
                            HStack(spacing: 8) {
                                Button {
                                    selectedLocalPDFURL = viewModel.localFileURL(filename: file.filename)
                                } label: {
                                    Text(file.filename)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)

                                ShareLink(item: viewModel.localFileURL(filename: file.filename)) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundStyle(Color(red: 0.84, green: 0.91, blue: 1.0))
                                }
                            }
                        } else {
                            Text(file.filename)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Spacer()
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding(14)
        .cardStyle()
    }

    private func actionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .foregroundStyle(.white)
            .background(Color(red: 0.14, green: 0.34, blue: 0.66), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .opacity(viewModel.isBusy ? 0.85 : 1.0)
    }

    private var hasMissingSettings: Bool {
        viewModel.connection.baseURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        viewModel.connection.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        viewModel.connection.remotePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}
