import Foundation
import OSLog

/// What the student wants their reply in. See CONTEXT.md.
///
/// Sent to the model as part of the system prompt. A per-message toggle means a student who typed
/// a hard question in Chinese can still ask for an English answer, without changing a global
/// setting first.
enum CoachLanguage: String, Codable, CaseIterable, Sendable {
    case both
    case chinese
    case english
}

/// A pedagogically-shaped prompt the **Reading Coach** sends to the model. See CONTEXT.md and
/// ADR 0008.
///
/// Carried as a value, not written into one long string here, so a test can assert the context the
/// Coach actually sends (the Article's title and text, which Topic Words it holds, how many Words
/// the student has reached **Known**) rather than parse one back out of a prompt afterward.
struct CoachPrompt: Equatable, Sendable {
    /// The whole chat so far on this Article, oldest first. Rebuilt on every send; a Coach that
    /// forgot the previous turn would answer "what does 'this' mean" with a shrug.
    var history: [CoachTurn]
    /// The Article the student is reading. Title, source, text — never a summary; the model does
    /// its own understanding of the text.
    var article: ArticleView
    /// The Known HSK **Words** in this Article, so the Coach doesn't waste a reply explaining a
    /// word already Known. Only the ones inside the Article: the whole Known set would be 1,500
    /// words of context the model doesn't need.
    var knownInArticle: [String]
    /// **Topic Words** inside this Article, pointed out so the Coach knows which ones matter to
    /// the student's fertilizer business (ADR 0007).
    var topicWordsInArticle: [String]
    /// How the student wants this one message answered.
    var language: CoachLanguage
}

struct CoachTurn: Equatable, Sendable {
    enum Role: String, Codable, Sendable { case user, assistant }
    let role: Role
    let text: String
}

/// One message as the chat API receives it: `system`, `user` or `assistant`, and its text.
struct ChatMessage: Equatable, Sendable, Encodable {
    let role: String
    let content: String
}

struct ArticleView: Equatable, Sendable {
    let title: String
    let source: String?
    let text: String
}

/// What the Coach uses to talk to a model. One method, so a test fake and the real Qwen client
/// share a shape. See ADR 0008.
///
/// Streams rather than returns one whole reply: the student sees text appear as the model writes
/// it, instead of waiting on a blank sheet. Each yielded value is one piece of the reply, in order;
/// joining them is the whole reply. The library both saves the joined whole and hands each piece
/// to the sheet as it arrives.
protocol CoachClient: Sendable {
    func streamReply(to prompt: CoachPrompt) -> AsyncThrowingStream<String, Error>
}

enum CoachClientError: LocalizedError, Equatable {
    case missingAPIKey
    case transport(String)
    case api(status: Int, body: String)
    case malformedResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No Qwen API key is set yet. Add one in 设置."
        case .transport(let message):
            return "Couldn't reach the model: \(message)"
        case .api(let status, let body):
            return "The model returned \(status). \(body)"
        case .malformedResponse:
            return "The model's reply was in a shape I didn't expect."
        }
    }
}

/// How many tokens one reply cost, read from the stream's last chunk. Logged in debug builds to
/// check the cache is hitting; never shown and never saved (ADR 0008: no counts on screen).
struct CoachUsage: Equatable, Sendable {
    let inputTokens: Int
    let cachedTokens: Int
    let outputTokens: Int
}

/// The real client: a POST to Alibaba Model Studio's OpenAI-compatible chat endpoint
/// (International, Singapore), `qwen3.7-flash`. See ADR 0011 for why Qwen, and ADR 0008 for why the
/// student's key lives in Keychain and the request goes direct rather than through a proxy for now.
///
/// No cache code: Model Studio caches a repeated prompt start on its own. `CoachPromptBuilder`
/// keeps that start identical within a Session.
struct QwenCoachClient: CoachClient {
    /// The model id. Alibaba renames Flash models roughly every quarter, so it lives in one place.
    static let model = "qwen3.7-flash"
    static let endpoint = URL(string: "https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions")!
    /// The ceiling on one reply, the student's choice (ADR 0011). The prompt's "keep answers short"
    /// keeps ordinary replies well under it; only what the model writes is billed.
    static let maxTokens = 1000

    let apiKey: String
    let urlSession: URLSession

    init(apiKey: String, urlSession: URLSession = .shared) {
        self.apiKey = apiKey
        self.urlSession = urlSession
    }

    func streamReply(to prompt: CoachPrompt) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            guard !apiKey.isEmpty else {
                continuation.finish(throwing: CoachClientError.missingAPIKey)
                return
            }
            let request: URLRequest
            do {
                request = try buildRequest(for: prompt)
            } catch {
                continuation.finish(throwing: CoachClientError.transport(error.localizedDescription))
                return
            }
            let task = Task { [urlSession] in
                do {
                    let (bytes, response) = try await urlSession.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw CoachClientError.malformedResponse
                    }
                    guard (200..<300).contains(http.statusCode) else {
                        // On an error status Model Studio sends a short JSON body. Reading the body
                        // off the byte stream itself keeps this to one request.
                        var buffer = Data()
                        for try await byte in bytes { buffer.append(byte) }
                        throw CoachClientError.api(status: http.statusCode,
                                                   body: String(data: buffer, encoding: .utf8) ?? "")
                    }
                    var sawAnyText = false
                    for try await line in bytes.lines {
                        // Server-Sent Events: empty lines are structure; the data lines carry one
                        // JSON object each, and the stream ends with `data: [DONE]`.
                        guard line.hasPrefix("data:") else { continue }
                        let payload = line.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
                        guard !payload.isEmpty else { continue }
                        guard let chunk = Self.chunk(from: payload) else { continue }
                        if let text = Self.textDelta(in: chunk), !text.isEmpty {
                            sawAnyText = true
                            continuation.yield(text)
                        }
                        #if DEBUG
                        if let usage = Self.usage(in: chunk) {
                            Self.log.debug("Coach tokens: input \(usage.inputTokens), cached \(usage.cachedTokens), output \(usage.outputTokens)")
                        }
                        #endif
                    }
                    if sawAnyText {
                        continuation.finish()
                    } else {
                        continuation.finish(throwing: CoachClientError.malformedResponse)
                    }
                } catch let error as CoachClientError {
                    continuation.finish(throwing: error)
                } catch is CancellationError {
                    continuation.finish(throwing: CancellationError())
                } catch {
                    continuation.finish(throwing: CoachClientError.transport(error.localizedDescription))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func buildRequest(for prompt: CoachPrompt) throws -> URLRequest {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "authorization")
        request.httpBody = try Self.requestBody(for: prompt)
        return request
    }

    /// The JSON the Coach posts. Separate so a test can read exactly what is sent.
    static func requestBody(for prompt: CoachPrompt) throws -> Data {
        try JSONEncoder().encode(ChatRequest(
            model: model,
            maxTokens: maxTokens,
            stream: true,
            streamOptions: .init(includeUsage: true),
            enableThinking: false,
            messages: CoachPromptBuilder.chatMessages(for: prompt)
        ))
    }

    /// Pulls one text piece out of an SSE `data:` line, or nil for every other line the stream
    /// carries (the finish chunk, the usage chunk, `[DONE]`, anything that isn't JSON). Separate so
    /// a unit test can hand it a known payload and assert the result without any URLSession at all.
    static func textDelta(from payload: String) -> String? {
        chunk(from: payload).flatMap(textDelta(in:))
    }

    /// The token counts on the stream's usage chunk, or nil for every other line.
    static func usage(from payload: String) -> CoachUsage? {
        chunk(from: payload).flatMap(usage(in:))
    }

    private static func textDelta(in chunk: StreamChunk) -> String? {
        chunk.choices.first?.delta?.content
    }

    private static func usage(in chunk: StreamChunk) -> CoachUsage? {
        guard let usage = chunk.usage else { return nil }
        return CoachUsage(inputTokens: usage.promptTokens,
                          cachedTokens: usage.promptTokensDetails?.cachedTokens ?? 0,
                          outputTokens: usage.completionTokens)
    }

    private static func chunk(from payload: String) -> StreamChunk? {
        guard let data = payload.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(StreamChunk.self, from: data)
    }

    #if DEBUG
    private static let log = Logger(subsystem: "com.kuypav.PersonalSchedule", category: "Coach")
    #endif

    private struct ChatRequest: Encodable {
        let model: String
        let maxTokens: Int
        let stream: Bool
        let streamOptions: StreamOptions
        /// Off in writing: hidden reasoning is billed and can spend the reply budget before any
        /// text arrives.
        let enableThinking: Bool
        let messages: [ChatMessage]

        enum CodingKeys: String, CodingKey {
            case model
            case maxTokens = "max_tokens"
            case stream
            case streamOptions = "stream_options"
            case enableThinking = "enable_thinking"
            case messages
        }

        struct StreamOptions: Encodable {
            let includeUsage: Bool
            enum CodingKeys: String, CodingKey { case includeUsage = "include_usage" }
        }
    }

    private struct StreamChunk: Decodable {
        let choices: [Choice]
        let usage: Usage?

        struct Choice: Decodable {
            let delta: Delta?
        }
        struct Delta: Decodable {
            let content: String?
        }
        struct Usage: Decodable {
            let promptTokens: Int
            let completionTokens: Int
            let promptTokensDetails: Details?

            enum CodingKeys: String, CodingKey {
                case promptTokens = "prompt_tokens"
                case completionTokens = "completion_tokens"
                case promptTokensDetails = "prompt_tokens_details"
            }
        }
        struct Details: Decodable {
            let cachedTokens: Int?
            enum CodingKeys: String, CodingKey { case cachedTokens = "cached_tokens" }
        }
    }
}

/// Builds the system prompt from a `CoachPrompt`. Separate from the client so the exact wording can
/// be tested without hitting the network and tuned without changing the networking code.
enum CoachPromptBuilder {
    static func systemPrompt(for prompt: CoachPrompt) -> String {
        var lines: [String] = []
        lines.append("You are 读伴, a reading coach for a Chinese learner at Hainan University.")
        lines.append("The student reads real Chinese writing they chose (微信 posts, menus, signs, articles).")
        lines.append("Your job is to help the student read THIS Article more easily. Keep answers short and specific.")
        lines.append("")
        lines.append("House rules (never break these):")
        lines.append("- Never mark a word as learned or Known. The app does that from reading evidence.")
        lines.append("- Never say the student is behind, due, or should 'practice more'. There is no streak.")
        lines.append("- Never recommend other apps, decks or flashcards.")
        lines.append("- Always include pinyin in parentheses the first time you use a Chinese word in a reply.")
        lines.append("")
        lines.append("The Article the student is reading:")
        lines.append("Title: \(prompt.article.title)")
        if let source = prompt.article.source, !source.isEmpty {
            lines.append("Source: \(source)")
        }
        lines.append("Text:")
        lines.append(prompt.article.text)
        lines.append("")
        if !prompt.knownInArticle.isEmpty {
            lines.append("Words in this Article the student has already reached Known (don't re-explain unless asked): " +
                         prompt.knownInArticle.joined(separator: "、"))
        }
        if !prompt.topicWordsInArticle.isEmpty {
            lines.append("Topic Words in this Article (fertilizer business vocabulary, matter to the student): " +
                         prompt.topicWordsInArticle.joined(separator: "、"))
        }
        return lines.joined(separator: "\n")
    }

    /// The messages the client sends, in the order that keeps the cached start stable: the system
    /// prompt, the earlier turns as they were, then the new question with its language line. The
    /// language line is added here, at send time, never into a saved Coach Message.
    static func chatMessages(for prompt: CoachPrompt) -> [ChatMessage] {
        var messages = [ChatMessage(role: "system", content: systemPrompt(for: prompt))]
        messages += prompt.history.map { ChatMessage(role: $0.role.rawValue, content: $0.text) }
        if prompt.history.last?.role == .user, let last = messages.popLast() {
            messages.append(ChatMessage(role: last.role,
                                        content: last.content + "\n\n" + languageInstruction(for: prompt.language)))
        }
        return messages
    }

    /// The Coach Language line. Not in the system prompt: it is picked per message, and the system
    /// prompt must stay byte-for-byte the same within a Session so the provider can cache it
    /// (ADR 0011).
    static func languageInstruction(for language: CoachLanguage) -> String {
        switch language {
        case .both:
            return "Answer in BOTH languages: a short Chinese line first, then a short English line."
        case .chinese:
            return "Answer in Chinese only. Keep sentences short and use words at HSK 4-5 level where you can."
        case .english:
            return "Answer in English only. Quote Chinese words with pinyin: 发酵 (fā jiào)."
        }
    }
}
