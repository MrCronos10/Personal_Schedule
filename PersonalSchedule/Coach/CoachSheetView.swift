import SwiftData
import SwiftUI

/// The 问 sheet opened from inside an **Article**: the student's **Coach Session** on this Article.
/// See CONTEXT.md and ADR 0008.
///
/// The sheet lives *inside* the reader rather than as its own tab, so the Article it is about is
/// always the one on screen behind it. No navigation here; the one way out is to close.
struct CoachSheetView: View {
    let article: Article

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    @State private var question = ""
    @State private var language: CoachLanguage = .both
    @State private var messages: [CoachMessage] = []
    @State private var isSending = false
    @State private var errorText: String?
    /// What the Coach has streamed back for the question in flight. Grows as chunks arrive; cleared
    /// once the final message is saved and `reload()` has picked it up, so the live bubble doesn't
    /// double with the stored one.
    @State private var streamingText: String = ""

    private var isChinese: Bool { locale.language.languageCode == .chinese }

    private var apiKey: String? { CoachSecrets.apiKey() }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                contextLine
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if messages.isEmpty {
                                emptyGreeting
                            } else {
                                ForEach(messages, id: \.persistentModelID) { message in
                                    MessageBubble(message: message)
                                        .id(message.persistentModelID)
                                }
                            }
                            if !streamingText.isEmpty {
                                StreamingBubble(text: streamingText)
                                    .id("streaming")
                            } else if isSending {
                                Text("…")
                                    .font(Theme.serif(22))
                                    .foregroundStyle(Theme.muted)
                                    .padding(.horizontal, 12)
                                    .id("streaming")
                            }
                            if let errorText {
                                Text(errorText)
                                    .font(Theme.meta)
                                    .foregroundStyle(Theme.error)
                                    .padding(.horizontal, 12)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: streamingText) { _, _ in
                        // Follow the live reply so the newest text stays in view as it writes.
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo("streaming", anchor: .bottom)
                        }
                    }
                }
                composer
            }
            .background(Theme.paper)
            .navigationTitle(isChinese ? "问读伴" : "Ask 读伴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isChinese ? "关闭" : "Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !messages.isEmpty {
                        Menu {
                            Button(role: .destructive) { clearThread() } label: {
                                Label(isChinese ? "清除对话" : "Clear chat", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .task { reload() }
    }

    private var contextLine: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(isChinese ? "关于这篇：" : "About this Article:")
                .font(Theme.meta)
                .foregroundStyle(Theme.muted)
            Text(verbatim: article.title)
                .font(Theme.serif(16))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.card)
        .overlay(alignment: .bottom) { Divider().background(Theme.rule) }
    }

    @ViewBuilder
    private var emptyGreeting: some View {
        VStack(alignment: .leading, spacing: 6) {
            if apiKey == nil {
                Text(isChinese ? "还没有添加 Anthropic API key。打开 设置 粘贴一个。"
                              : "No Anthropic API key yet. Open 设置 and paste one.")
                    .font(Theme.meta)
                    .foregroundStyle(Theme.late)
            } else {
                Text(isChinese ? "问读伴一个关于这篇文章的问题。"
                              : "Ask 读伴 anything about this Article.")
                    .font(Theme.serif(16))
                    .foregroundStyle(Theme.muted)
                Text(isChinese ? "读伴不会给你的词打钩，也不会说你哪天没来。"
                              : "读伴 never marks words Known and never says you're behind.")
                    .font(Theme.meta)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
    }

    private var composer: some View {
        VStack(spacing: 8) {
            Picker(isChinese ? "回答语言" : "Answer in", selection: $language) {
                Text(isChinese ? "中/EN" : "中/EN").tag(CoachLanguage.both)
                Text(isChinese ? "只中文" : "中文").tag(CoachLanguage.chinese)
                Text(isChinese ? "只英文" : "English").tag(CoachLanguage.english)
            }
            .pickerStyle(.segmented)
            HStack(alignment: .bottom, spacing: 8) {
                TextField(isChinese ? "你的问题" : "Your question", text: $question, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .disabled(isSending)
                Button(action: send) {
                    Text(isSending ? (isChinese ? "…" : "…") : (isChinese ? "发送" : "Send"))
                        .frame(minWidth: 54)
                }
                .buttonStyle(RedButtonStyle())
                .disabled(isSending || question.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.card)
        .overlay(alignment: .top) { Divider().background(Theme.rule) }
    }

    private func reload() {
        let library = CoachLibrary(context: context, client: makeClient())
        messages = (try? library.messages(for: article)) ?? []
    }

    private func makeClient() -> CoachClient {
        AnthropicCoachClient(apiKey: apiKey ?? "")
    }

    private func send() {
        let question = self.question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        guard apiKey != nil else {
            errorText = isChinese ? "请先在 设置 里添加 Anthropic API key。" : "Add an Anthropic API key in 设置 first."
            return
        }
        self.question = ""
        isSending = true
        errorText = nil
        streamingText = ""
        let library = CoachLibrary(context: context, client: makeClient())
        Task { @MainActor in
            do {
                _ = try await library.ask(question, about: article, language: language) { chunk in
                    streamingText += chunk
                }
                reload()
            } catch {
                errorText = error.localizedDescription
                reload()
            }
            // Clear the live bubble only after the stored message has been reloaded, so the newest
            // reply never flickers between the live bubble and the saved one.
            streamingText = ""
            isSending = false
        }
    }

    private func clearThread() {
        let library = CoachLibrary(context: context, client: makeClient())
        try? library.clearMessages(for: article)
        reload()
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let last = messages.last else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(last.persistentModelID, anchor: .bottom)
        }
    }
}

/// The live Coach reply while it streams in. Mirrors `MessageBubble`'s coach side so it reads as
/// the same object; a cursor at the end makes the writing visible rather than looking frozen.
private struct StreamingBubble: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                (Text(verbatim: text) + Text("▍").foregroundColor(Theme.muted))
                    .font(Theme.serif(15))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.cardHigh)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 12)
    }
}

private struct MessageBubble: View {
    let message: CoachMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .user { Spacer(minLength: 40) }
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(verbatim: message.text)
                    .font(Theme.serif(15))
                    .foregroundStyle(message.role == .user ? Theme.paper : Theme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.role == .user ? Theme.red : Theme.cardHigh)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if message.role == .coach { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 12)
    }
}
