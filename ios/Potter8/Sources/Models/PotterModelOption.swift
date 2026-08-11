import Foundation

enum PotterModelOption: String, CaseIterable, Codable, Identifiable, Sendable {
    case openAI56 = "openai-gpt-5.6"
    case fable5 = "anthropic-fable-5"
    case kimiK3 = "moonshot-kimi-k3"
    case grok45 = "xai-grok-4.5"
    case gemini31Pro = "google-gemini-3.1-pro"
    case claudeCode = "anthropic-claude-code"
    case localFree = "ollama-local-free"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openAI56: "OpenAI GPT-5.6"
        case .fable5: "Claude Fable 5"
        case .kimiK3: "Kimi K3"
        case .grok45: "Grok 4.5"
        case .gemini31Pro: "Gemini 3.1 Pro"
        case .claudeCode: "Claude Code"
        case .localFree: "Potter Local"
        }
    }

    var compactTitle: String {
        switch self {
        case .openAI56: "GPT-5.6"
        case .fable5: "Fable 5"
        case .kimiK3: "Kimi K3"
        case .grok45: "Grok 4.5"
        case .gemini31Pro: "Gemini 3.1 Pro"
        case .claudeCode: "Claude Code"
        case .localFree: "Local · Free"
        }
    }

    var provider: String {
        switch self {
        case .openAI56: "OpenAI"
        case .fable5, .claudeCode: "Anthropic"
        case .kimiK3: "Moonshot AI"
        case .grok45: "xAI"
        case .gemini31Pro: "Google"
        case .localFree: "Ollama"
        }
    }

    var access: String {
        switch self {
        case .gemini31Pro: "Free API tier available"
        case .localFree: "Free on your computer"
        case .claudeCode: "Paid API · Fable 5 coding mode"
        case .kimiK3: "Paid API · open-weight model"
        case .openAI56, .fable5, .grok45: "Paid API"
        }
    }

    var serverVariable: String? {
        switch self {
        case .openAI56: "OPENAI_API_KEY"
        case .fable5, .claudeCode: "ANTHROPIC_API_KEY"
        case .kimiK3: "MOONSHOT_API_KEY"
        case .grok45: "XAI_API_KEY"
        case .gemini31Pro: "GEMINI_API_KEY"
        case .localFree: nil
        }
    }

    var systemImage: String {
        switch self {
        case .openAI56: "brain.head.profile"
        case .fable5: "sparkles"
        case .kimiK3: "moon.stars"
        case .grok45: "bolt.horizontal.circle"
        case .gemini31Pro: "diamond"
        case .claudeCode: "chevron.left.forwardslash.chevron.right"
        case .localFree: "laptopcomputer"
        }
    }
}
