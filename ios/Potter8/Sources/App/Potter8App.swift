import SwiftUI

@main
struct Potter8App: App {
    @State private var settings = PotterSettings()
    @State private var chatStore = ChatStore(client: .live)

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(settings)
                .environment(chatStore)
                .tint(.indigo)
        }
    }
}
