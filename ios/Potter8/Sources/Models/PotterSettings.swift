import Foundation
import Observation

@MainActor
@Observable
final class PotterSettings {
    private enum Keys {
        static let serverURL = "potter.serverURL"
        static let accessToken = "potter.accessToken"
    }

    private let defaults: UserDefaults?

    var serverURLText: String {
        didSet { defaults?.set(serverURLText, forKey: Keys.serverURL) }
    }

    var accessToken: String {
        didSet {
            guard defaults != nil else { return }
            KeychainStore.save(accessToken, account: Keys.accessToken)
        }
    }

    init(
        serverURLText: String? = nil,
        accessToken: String? = nil,
        defaults: UserDefaults? = .standard
    ) {
        self.defaults = defaults
        self.serverURLText = serverURLText
            ?? defaults?.string(forKey: Keys.serverURL)
            ?? "http://127.0.0.1:8787"
        self.accessToken = accessToken
            ?? (defaults == nil ? "" : KeychainStore.read(account: Keys.accessToken))
    }

    var baseURL: URL? {
        let trimmed = serverURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }
}
