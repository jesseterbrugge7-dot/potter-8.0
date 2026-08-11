import Foundation
import Observation

@MainActor
@Observable
final class PotterSettings {
    private enum Keys {
        static let serverURL = "potter.serverURL"
        static let accessToken = "potter.accessToken"
        static let selectedModel = "potter.selectedModel"
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

    var selectedModel: PotterModelOption {
        didSet { defaults?.set(selectedModel.rawValue, forKey: Keys.selectedModel) }
    }

    init(
        serverURLText: String? = nil,
        accessToken: String? = nil,
        selectedModel: PotterModelOption? = nil,
        defaults: UserDefaults? = .standard
    ) {
        self.defaults = defaults
        self.serverURLText = serverURLText
            ?? defaults?.string(forKey: Keys.serverURL)
            ?? "http://127.0.0.1:8787"
        self.accessToken = accessToken
            ?? (defaults == nil ? "" : KeychainStore.read(account: Keys.accessToken))
        self.selectedModel = selectedModel
            ?? defaults?.string(forKey: Keys.selectedModel).flatMap {
                PotterModelOption(rawValue: $0)
            }
            ?? .openAI56
    }

    var baseURL: URL? {
        let trimmed = serverURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }
}
