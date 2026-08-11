import Foundation
import Observation

@MainActor
@Observable
final class ChatStore {
    static let maximumPendingImages = 4

    private enum Keys {
        static let messages = "potter.messages"
        static let sessionID = "potter.sessionID"
    }

    var messages: [ChatMessage]
    var draft = ""
    var pendingImages: [PendingImageAttachment] = []
    var isLoadingImages = false
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
        let images = pendingImages
        guard (!message.isEmpty || !images.isEmpty), !isSending, !isLoadingImages else { return }
        guard let baseURL = settings.baseURL else {
            errorMessage = PotterClientError.invalidServerURL.localizedDescription
            return
        }

        let messageForAgent: String
        if message.isEmpty {
            messageForAgent = images.count == 1
                ? "What can you tell me about this image?"
                : "What can you tell me about these images?"
        } else {
            messageForAgent = message
        }

        draft = ""
        pendingImages = []
        errorMessage = nil
        isSending = true
        defer { isSending = false }
        messages.append(
            ChatMessage(
                role: .user,
                text: messageForAgent,
                images: images.map { ChatImageAttachment(thumbnailData: $0.thumbnailData) }
            )
        )
        persistMessages()

        do {
            let response = try await client.send(
                baseURL,
                settings.accessToken,
                messageForAgent,
                sessionID,
                images.map {
                    PotterImageInput(
                        mimeType: $0.mimeType,
                        data: $0.imageData.base64EncodedString()
                    )
                }
            )
            messages.append(ChatMessage(role: .potter, text: response.reply))
            persistMessages()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addPendingImage(_ image: PendingImageAttachment) {
        guard pendingImages.count < Self.maximumPendingImages else { return }
        pendingImages.append(image)
    }

    func removePendingImage(id: UUID) {
        pendingImages.removeAll { $0.id == id }
    }

    func startNewConversation(using settings: PotterSettings) async {
        let oldSessionID = sessionID
        sessionID = "ios-\(UUID().uuidString.lowercased())"
        defaults?.set(sessionID, forKey: Keys.sessionID)
        messages = []
        draft = ""
        pendingImages = []
        isLoadingImages = false
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
