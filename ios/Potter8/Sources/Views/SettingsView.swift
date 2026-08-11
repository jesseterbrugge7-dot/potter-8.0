import SwiftUI

struct SettingsView: View {
    @Environment(PotterSettings.self) private var settings
    @Environment(ChatStore.self) private var store
    @State private var isTesting = false
    @State private var connectionResult: String?
    @State private var connectionFailed = false

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                Picker("AI model", selection: $settings.selectedModel) {
                    ForEach(PotterModelOption.allCases) { model in
                        Label(model.title, systemImage: model.systemImage)
                            .tag(model)
                    }
                }
                .pickerStyle(.menu)

                LabeledContent("Provider", value: settings.selectedModel.provider)
                LabeledContent("Access", value: settings.selectedModel.access)

                if let variable = settings.selectedModel.serverVariable {
                    LabeledContent("Server key") {
                        Text(variable)
                            .font(.caption.monospaced())
                    }
                } else {
                    LabeledContent("Server key", value: "Not required")
                }
            } header: {
                Text("AI model")
            } footer: {
                if settings.selectedModel == .localFree {
                    Text("Free local mode uses Ollama on your Potter computer. Run: ollama pull gemma3:4b")
                } else if settings.selectedModel == .gemini31Pro {
                    Text("Gemini offers a limited free API tier. Put GEMINI_API_KEY in the Potter server terminal, never in the app or GitHub.")
                } else if settings.selectedModel == .claudeCode {
                    Text("Claude Code mode is a coding-focused Fable 5 chat. It is not Anthropic's separate Claude Code terminal or cloud-routines product.")
                } else {
                    Text("This provider charges for API usage. Add its key only to the Potter server terminal; the key never enters the iOS app.")
                }
            }

            Section {
                TextField("Server URL", text: $settings.serverURLText)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Local access token", text: $settings.accessToken)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button {
                    testConnection()
                } label: {
                    HStack {
                        Text("Test connection")
                        Spacer()
                        if isTesting { ProgressView() }
                    }
                }
                .disabled(isTesting)

                if let connectionResult {
                    Label(
                        connectionResult,
                        systemImage: connectionFailed ? "xmark.circle.fill" : "checkmark.circle.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(connectionFailed ? Color.red : Color.green)
                }
            } header: {
                Text("Potter server")
            } footer: {
                Text("Simulator: http://127.0.0.1:8787. iPhone: use the .local address and token printed by the Python server.")
            }

            Section("Conversation") {
                Button("Start a new conversation", role: .destructive) {
                    Task { await store.startNewConversation(using: settings) }
                }
            }

            Section("Privacy and safety") {
                Label("Provider API keys stay on your Python server.", systemImage: "key.horizontal")
                Label("The iOS app stores only the local access token in Keychain.", systemImage: "lock.shield")
                Label("Photos are sent only after you attach and send them.", systemImage: "photo.on.rectangle")
                Label("Shell commands and file writes are disabled in iOS server mode.", systemImage: "hand.raised")
            }

            Section("About") {
                LabeledContent("Name", value: "Potter 8.0")
                LabeledContent("Version", value: "8.0.1")
                LabeledContent("License", value: "MIT")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func testConnection() {
        isTesting = true
        connectionResult = nil
        Task {
            do {
                connectionResult = try await store.testConnection(using: settings)
                connectionFailed = false
            } catch {
                connectionResult = error.localizedDescription
                connectionFailed = true
            }
            isTesting = false
        }
    }
}

#Preview {
    let settings = PotterSettings(
        serverURLText: "http://127.0.0.1:8787",
        accessToken: "preview-token",
        defaults: nil
    )
    let store = ChatStore(client: .preview, defaults: nil)
    NavigationStack { SettingsView() }
        .environment(settings)
        .environment(store)
}
