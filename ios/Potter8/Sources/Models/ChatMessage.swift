import Foundation

enum MessageRole: String, Codable, Sendable {
    case user
    case potter
}

struct ChatImageAttachment: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let thumbnailData: Data

    init(id: UUID = UUID(), thumbnailData: Data) {
        self.id = id
        self.thumbnailData = thumbnailData
    }
}

struct PendingImageAttachment: Identifiable, Equatable, Sendable {
    let id: UUID
    let imageData: Data
    let thumbnailData: Data
    let mimeType: String

    init(
        id: UUID = UUID(),
        imageData: Data,
        thumbnailData: Data,
        mimeType: String
    ) {
        self.id = id
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.mimeType = mimeType
    }
}

struct ChatMessage: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let role: MessageRole
    let text: String
    let images: [ChatImageAttachment]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        role: MessageRole,
        text: String,
        images: [ChatImageAttachment] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.images = images
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case role
        case text
        case images
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        role = try container.decode(MessageRole.self, forKey: .role)
        text = try container.decode(String.self, forKey: .text)
        images = try container.decodeIfPresent([ChatImageAttachment].self, forKey: .images) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

struct PotterImageInput: Encodable, Sendable {
    let mimeType: String
    let data: String

    enum CodingKeys: String, CodingKey {
        case mimeType = "mime_type"
        case data
    }
}

struct PotterChatRequest: Encodable, Sendable {
    let message: String
    let sessionID: String
    let images: [PotterImageInput]

    enum CodingKeys: String, CodingKey {
        case message
        case sessionID = "session_id"
        case images
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
