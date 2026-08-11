import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case chat
    case settings

    var id: String { rawValue }

    @ViewBuilder
    var label: some View {
        switch self {
        case .chat:
            Label("Potter", systemImage: "wand.and.stars")
        case .settings:
            Label("Settings", systemImage: "gearshape")
        }
    }
}

struct AppView: View {
    @State private var selectedTab: AppTab = .chat

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ChatView()
            }
            .tabItem { AppTab.chat.label }
            .tag(AppTab.chat)

            NavigationStack {
                SettingsView()
            }
            .tabItem { AppTab.settings.label }
            .tag(AppTab.settings)
        }
    }
}
