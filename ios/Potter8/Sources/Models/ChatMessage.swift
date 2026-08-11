import Foundation

enum MessageRole: String, Codable, Sendable {
    case user
    case potter
}

struct ChatMessage: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let role: MessageRole
    let text: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        role: MessageRole,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

struct PotterChatRequest: Encodable, Sendable {
    let message: String
    let sessionID: String

    enum CodingKeys: String, CodingKey {
        case message
        case sessionID = "session_id"
    }
}

struct PotterChatResponse: Decodable, Sendable {
    let reply: String
    let sessionID: String
    let model: String

    enum CodingKeys: String, CodingKey {
        case reply
        case sessionID = "session_id"
        case model
    }
}

struct PotterHealthResponse: Decodable, Sendable {
    let status: String
    let name: String
    let version: String
    let model: String
}

struct PotterResetRequest: Encodable, Sendable {
    let sessionID: String

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
    }
}

struct PotterErrorResponse: Decodable, Sendable {
    let error: String
}
