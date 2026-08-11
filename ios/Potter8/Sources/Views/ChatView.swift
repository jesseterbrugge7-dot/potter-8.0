import SwiftUI

struct ChatView: View {
    @Environment(ChatStore.self) private var store
    @Environment(PotterSettings.self) private var settings

    var body: some View {
        @Bindable var store = store

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    if store.messages.isEmpty {
                        EmptyConversationView()
                            .padding(.top, 80)
                    } else {
                        ForEach(store.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }

                    if store.isSending {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Potter is working…")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .id("loading")
                    }

                    if let errorMessage = store.errorMessage {
                        ErrorBanner(message: errorMessage)
                            .id("error")
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                ComposerBar(
                    text: $store.draft,
                    isSending: store.isSending,
                    send: { Task { await store.send(using: settings) } }
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: store.messages.count) { _, _ in
                guard let last = store.messages.last else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
            .onChange(of: store.isSending) { _, isSending in
                if isSending {
                    withAnimation { proxy.scrollTo("loading", anchor: .bottom) }
                }
            }
        }
        .navigationTitle("Potter 8.0")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await store.startNewConversation(using: settings) }
                } label: {
                    Label("New conversation", systemImage: "square.and.pencil")
                }
                .disabled(store.isSending)
            }
        }
    }
}

private struct EmptyConversationView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wand.and.stars.inverse")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.indigo)
                .accessibilityHidden(true)
            Text("What should we work on?")
                .font(.title2.bold())
            Text("Ask a question, research something current, solve a problem, or plan a project.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 330)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 42) }
            Text(message.text)
                .textSelection(.enabled)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .foregroundStyle(message.role == .user ? Color.white : Color.primary)
                .background(
                    message.role == .user
                        ? Color.indigo
                        : Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
            if message.role == .potter { Spacer(minLength: 42) }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.role == .user ? "You" : "Potter")
        .accessibilityValue(message.text)
    }
}

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ComposerBar: View {
    @Binding var text: String
    let isSending: Bool
    let send: () -> Void

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message Potter", text: $text, axis: .vertical)
                .lineLimit(1...5)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )

            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(canSend ? Color.indigo : Color.secondary, in: Circle())
            }
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

#Preview("Conversation") {
    let settings = PotterSettings(
        serverURLText: "http://127.0.0.1:8787",
        accessToken: "preview",
        defaults: nil
    )
    let store = ChatStore(
        client: .preview,
        messages: [
            ChatMessage(role: .user, text: "Help me plan a small open-source app."),
            ChatMessage(role: .potter, text: "Absolutely. I’ll start with the smallest useful architecture and a testable first milestone."),
        ],
        defaults: nil
    )
    NavigationStack { ChatView() }
        .environment(settings)
        .environment(store)
}

#Preview("Empty") {
    let settings = PotterSettings(defaults: nil)
    let store = ChatStore(client: .preview, messages: [], defaults: nil)
    NavigationStack { ChatView() }
        .environment(settings)
        .environment(store)
}
