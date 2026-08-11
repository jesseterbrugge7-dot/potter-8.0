import PhotosUI
import SwiftUI

struct ChatView: View {
    @Environment(ChatStore.self) private var store
    @Environment(PotterSettings.self) private var settings
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    var body: some View {
        @Bindable var store = store
        @Bindable var settings = settings

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
                    photoSelection: $selectedPhotoItems,
                    attachments: store.pendingImages,
                    isLoadingImages: store.isLoadingImages,
                    isSending: store.isSending,
                    removeAttachment: store.removePendingImage,
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
            .onChange(of: selectedPhotoItems) { _, items in
                guard !items.isEmpty else { return }
                Task { await loadSelectedPhotos(items) }
            }
        }
        .navigationTitle("Potter 8.0")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text("Potter 8.0")
                        .font(.headline)
                    Text(settings.selectedModel.compactTitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Potter model")
                .accessibilityValue(settings.selectedModel.title)
            }

            ToolbarTitleMenu {
                ForEach(PotterModelOption.allCases) { model in
                    Button {
                        settings.selectedModel = model
                    } label: {
                        Label(
                            model.title,
                            systemImage: model == settings.selectedModel
                                ? "checkmark"
                                : model.systemImage
                        )
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await store.startNewConversation(using: settings) }
                } label: {
                    Label("New conversation", systemImage: "square.and.pencil")
                }
                .disabled(store.isSending || store.isLoadingImages)
            }
        }
    }

    @MainActor
    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        guard !store.isLoadingImages else { return }
        let availableSlots = ChatStore.maximumPendingImages - store.pendingImages.count
        guard availableSlots > 0 else {
            selectedPhotoItems = []
            return
        }

        store.isLoadingImages = true
        store.errorMessage = nil
        defer {
            store.isLoadingImages = false
            selectedPhotoItems = []
        }

        for item in items.prefix(availableSlots) {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw ImageAttachmentError.unreadableImage
                }
                let attachment = try await Task.detached(priority: .userInitiated) {
                    try ImageAttachmentProcessor.prepare(data)
                }.value
                store.addPendingImage(attachment)
            } catch is CancellationError {
                return
            } catch {
                store.errorMessage = error.localizedDescription
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
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                if !message.images.isEmpty {
                    MessageImageGrid(images: message.images)
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .textSelection(.enabled)
                        .padding(.horizontal, message.images.isEmpty ? 0 : 8)
                        .padding(.vertical, message.images.isEmpty ? 0 : 5)
                }

                if message.role == .potter,
                   let modelID = message.modelID,
                   let model = PotterModelOption(rawValue: modelID) {
                    Label(model.compactTitle, systemImage: model.systemImage)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, message.images.isEmpty ? 0 : 8)
                }
            }
                .padding(.horizontal, message.images.isEmpty ? 14 : 6)
                .padding(.vertical, message.images.isEmpty ? 11 : 6)
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
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: String {
        guard !message.images.isEmpty else { return message.text }
        let imageSummary = "\(message.images.count) attached image\(message.images.count == 1 ? "" : "s")"
        return message.text.isEmpty ? imageSummary : "\(imageSummary). \(message.text)"
    }
}

private struct MessageImageGrid: View {
    let images: [ChatImageAttachment]

    private var columns: [GridItem] {
        if images.count == 1 {
            return [GridItem(.flexible())]
        }
        return [
            GridItem(.flexible(), spacing: 4),
            GridItem(.flexible(), spacing: 4),
        ]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(images) { attachment in
                if let image = UIImage(data: attachment.thumbnailData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: images.count == 1 ? 170 : 112)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .accessibilityLabel("Attached image")
                }
            }
        }
        .frame(width: images.count == 1 ? 238 : 250)
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
    @Binding var photoSelection: [PhotosPickerItem]
    let attachments: [PendingImageAttachment]
    let isLoadingImages: Bool
    let isSending: Bool
    let removeAttachment: (UUID) -> Void
    let send: () -> Void

    private var canSend: Bool {
        (!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty)
            && !isLoadingImages
            && !isSending
    }

    private var remainingPhotoSlots: Int {
        max(0, ChatStore.maximumPendingImages - attachments.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !attachments.isEmpty || isLoadingImages {
                AttachmentStrip(
                    attachments: attachments,
                    isLoading: isLoadingImages,
                    remove: removeAttachment
                )
            }

            HStack(alignment: .bottom, spacing: 9) {
                PhotosPicker(
                    selection: $photoSelection,
                    maxSelectionCount: max(1, remainingPhotoSlots),
                    matching: .images
                ) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(remainingPhotoSlots > 0 ? Color.indigo : Color.secondary)
                        .frame(width: 42, height: 42)
                        .background(
                            Color(uiColor: .secondarySystemGroupedBackground),
                            in: Circle()
                        )
                }
                .disabled(remainingPhotoSlots == 0 || isLoadingImages || isSending)
                .accessibilityLabel("Attach photos")
                .accessibilityHint("Select up to four photos for Potter to analyze")

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
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

private struct AttachmentStrip: View {
    let attachments: [PendingImageAttachment]
    let isLoading: Bool
    let remove: (UUID) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(attachments) { attachment in
                    ZStack(alignment: .topTrailing) {
                        if let image = UIImage(data: attachment.thumbnailData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 72, height: 72)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        }

                        Button {
                            remove(attachment.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.72))
                        }
                        .offset(x: 6, y: -6)
                        .accessibilityLabel("Remove attached photo")
                    }
                    .padding(.top, 6)
                    .padding(.trailing, 6)
                }

                if isLoading {
                    VStack(spacing: 7) {
                        ProgressView()
                        Text("Loading")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 72, height: 72)
                    .background(
                        Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                    )
                }
            }
            .padding(.horizontal, 2)
        }
        .accessibilityLabel("Photo attachments")
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
