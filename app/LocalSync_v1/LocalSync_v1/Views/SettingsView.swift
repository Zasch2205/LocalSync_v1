import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var connection: ConnectionConfig
    let isBusy: Bool
    let onTestConnection: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Verbindung") {
                    TextField("z. B. http://192.168.1.50:5005", text: $connection.baseURLString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Benutzername", text: $connection.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Passwort", text: $connection.password)

                    TextField("z. B. /Dokumente/PDF", text: $connection.remotePath)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Prüfung") {
                    Button("Verbindung testen") {
                        onTestConnection()
                    }
                    .disabled(isBusy)
                }
            }
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}
