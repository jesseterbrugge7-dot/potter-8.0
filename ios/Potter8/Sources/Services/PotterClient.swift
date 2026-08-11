import Foundation

enum PotterClientError: LocalizedError {
    case invalidServerURL
    case invalidResponse
    case server(status: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidServerURL:
            "Enter a valid Potter server URL in Settings."
        case .invalidResponse:
            "The Potter server returned an unreadable response."
        case .server(_, let message):
            message
        }
    }
}

struct PotterClient: Sendable {
    var send: @Sendable (
        _ baseURL: URL,
        _ token: String,
        _ message: String,
        _ sessionID: String
    ) async throws -> PotterChatResponse
    var reset: @Sendable (
        _ baseURL: URL,
        _ token: String,
        _ sessionID: String
    ) async throws -> Void
    var health: @Sendable (_ baseURL: URL) async throws -> PotterHealthResponse
}

extension PotterClient {
    static let live = PotterClient(
        send: { baseURL, token, message, sessionID in
            var request = try request(
                baseURL: baseURL,
                path: "v1/chat",
                method: "POST",
                token: token
            )
            request.httpBody = try JSONEncoder().encode(
                PotterChatRequest(message: message, sessionID: sessionID)
            )
            return try await perform(request, as: PotterChatResponse.self)
        },
        reset: { baseURL, token, sessionID in
            var request = try request(
                baseURL: baseURL,
                path: "v1/reset",
                method: "POST",
                token: token
            )
            request.httpBody = try JSONEncoder().encode(
                PotterResetRequest(sessionID: sessionID)
            )
            let _: EmptyResetResponse = try await perform(request, as: EmptyResetResponse.self)
        },
        health: { baseURL in
            let request = try request(
                baseURL: baseURL,
                path: "health",
                method: "GET",
                token: nil
            )
            return try await perform(request, as: PotterHealthResponse.self)
        }
    )

    static let preview = PotterClient(
        send: { _, _, message, sessionID in
            try await Task.sleep(for: .milliseconds(250))
            return PotterChatResponse(
                reply: "I can help with ‘\(message)’. This is the offline preview response.",
                sessionID: sessionID,
                model: "preview"
            )
        },
        reset: { _, _, _ in },
        health: { _ in
            PotterHealthResponse(status: "ok", name: "Potter 8.0", version: "8.0.0", model: "preview")
        }
    )

    private struct EmptyResetResponse: Decodable {
        let reset: Bool
    }

    private static func request(
        baseURL: URL,
        path: String,
        method: String,
        token: String?
    ) throws -> URLRequest {
        guard let scheme = baseURL.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              baseURL.host != nil
        else {
            throw PotterClientError.invalidServerURL
        }
        let endpoint = baseURL.appending(path: path)
        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.timeoutInterval = 180
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if method != "GET" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private static func perform<Response: Decodable>(
        _ request: URLRequest,
        as responseType: Response.Type
    ) async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PotterClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(PotterErrorResponse.self, from: data).error)
                ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw PotterClientError.server(status: httpResponse.statusCode, message: message)
        }
        do {
            return try JSONDecoder().decode(responseType, from: data)
        } catch {
            throw PotterClientError.invalidResponse
        }
    }
}
