import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var connection: ConnectionConfig
    let isBusy: Bool
    let onTestConnection: () -> Void

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
                        settingsCard
                        testCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .foregroundStyle(Color(red: 0.84, green: 0.91, blue: 1.0))
                }
            }
        }
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verbindung")
                .font(.headline)

            TextField("z. B. http://192.168.1.50:5005", text: $connection.baseURLString)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            TextField("Benutzername", text: $connection.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            SecureField("Passwort", text: $connection.password)
                .textFieldStyle(.roundedBorder)

            TextField("z. B. /Dokumente/PDF", text: $connection.remotePath)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
        }
        .padding(14)
        .cardStyle()
    }

    private var testCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prüfung")
                .font(.headline)

            Button("Verbindung testen") {
                onTestConnection()
            }
            .disabled(isBusy)
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .foregroundStyle(.white)
            .background(Color(red: 0.14, green: 0.34, blue: 0.66), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            if isBusy {
                ProgressView()
                    .tint(.white)
            }
        }
        .padding(14)
        .cardStyle()
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
