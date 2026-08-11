import Foundation
import Observation

@MainActor
@Observable
final class ChatStore {
    private enum Keys {
        static let messages = "potter.messages"
        static let sessionID = "potter.sessionID"
    }

    var messages: [ChatMessage]
    var draft = ""
    var isSending = false
    var errorMessage: String?

    private let client: PotterClient
    private let defaults: UserDefaults?
    private(set) var sessionID: String

    init(
        client: PotterClient,
        messages: [ChatMessage]? = nil,
        defaults: UserDefaults? = .standard
    ) {
        self.client = client
        self.defaults = defaults
        self.sessionID = defaults?.string(forKey: Keys.sessionID)
            ?? "ios-\(UUID().uuidString.lowercased())"
        if let messages {
            self.messages = messages
        } else if let data = defaults?.data(forKey: Keys.messages),
                  let saved = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            self.messages = saved
        } else {
            self.messages = []
        }
        defaults?.set(sessionID, forKey: Keys.sessionID)
    }

    func send(using settings: PotterSettings) async {
        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, !isSending else { return }
        guard let baseURL = settings.baseURL else {
            errorMessage = PotterClientError.invalidServerURL.localizedDescription
            return
        }

        draft = ""
        errorMessage = nil
        isSending = true
        defer { isSending = false }
        messages.append(ChatMessage(role: .user, text: message))
        persistMessages()

        do {
            let response = try await client.send(
                baseURL,
                settings.accessToken,
                message,
                sessionID
            )
            messages.append(ChatMessage(role: .potter, text: response.reply))
            persistMessages()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startNewConversation(using settings: PotterSettings) async {
        let oldSessionID = sessionID
        sessionID = "ios-\(UUID().uuidString.lowercased())"
        defaults?.set(sessionID, forKey: Keys.sessionID)
        messages = []
        draft = ""
        errorMessage = nil
        persistMessages()

        guard let baseURL = settings.baseURL else { return }
        do {
            try await client.reset(baseURL, settings.accessToken, oldSessionID)
        } catch {
            errorMessage = "New chat started locally. Old server session could not be reset: \(error.localizedDescription)"
        }
    }

    func testConnection(using settings: PotterSettings) async throws -> String {
        guard let baseURL = settings.baseURL else {
            throw PotterClientError.invalidServerURL
        }
        let health = try await client.health(baseURL)
        return "\(health.name) \(health.version) · \(health.model)"
    }

    private func persistMessages() {
        guard let defaults,
              let data = try? JSONEncoder().encode(Array(messages.suffix(100)))
        else { return }
        defaults.set(data, forKey: Keys.messages)
    }
}
