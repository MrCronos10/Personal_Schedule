import Foundation

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

struct ArticleView: Equatable, Sendable {
    let title: String
    let source: String?
    let text: String
}

/// What the Coach uses to talk to a model. One method, so a test fake and the real Anthropic client
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
            return "No Anthropic API key is set yet. Add one in 设置."
        case .transport(let message):
            return "Couldn't reach the model: \(message)"
        case .api(let status, let body):
            return "The model returned \(status). \(body)"
        case .malformedResponse:
            return "The model's reply was in a shape I didn't expect."
        }
    }
}

/// The real client: a POST to Anthropic's Messages API, Sonnet 5.5. See ADR 0008 for why Sonnet
/// and not Haiku or Opus, and why the student's key lives in Keychain and the request goes direct
/// to Anthropic rather than through a proxy for now.
struct AnthropicCoachClient: CoachClient {
    /// The model id. Changed in one place so a swap to Haiku later for a cheaper mode is a one-line
    /// edit, not a search across the project.
    static let model = "claude-sonnet-5-5"
    static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    static let anthropicVersion = "2023-06-01"
    /// How many tokens the Coach may spend on a reply. A sentence or two of Chinese plus an English
    /// line is comfortably under this; higher costs more and encourages the model to pad.
    static let maxTokens = 600

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
                        // On an error status Anthropic sends a short JSON body. Reading the body
                        // off the byte stream itself keeps this to one request.
                        var buffer = Data()
                        for try await byte in bytes { buffer.append(byte) }
                        throw CoachClientError.api(status: http.statusCode,
                                                   body: String(data: buffer, encoding: .utf8) ?? "")
                    }
                    var sawAnyText = false
                    for try await line in bytes.lines {
                        // Server-Sent Events: event names and empty lines are structure; the data
                        // lines carry one JSON object each (see Anthropic's streaming docs).
                        guard line.hasPrefix("data:") else { continue }
                        let payload = line.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
                        guard !payload.isEmpty else { continue }
                        if let text = Self.textDelta(from: payload), !text.isEmpty {
                            sawAnyText = true
                            continuation.yield(text)
                        }
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
        let body = AnthropicRequest(
            model: Self.model,
            maxTokens: Self.maxTokens,
            stream: true,
            system: CoachPromptBuilder.systemPrompt(for: prompt),
            messages: prompt.history.map { AnthropicRequest.Message(role: $0.role.rawValue, content: $0.text) }
        )
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    /// Pulls one text piece out of an SSE `data:` line, or nil for every other event the stream
    /// carries (message_start, content_block_start, ping, message_stop…). Separate so a unit test
    /// can hand it a known payload and assert the result without any URLSession at all.
    static func textDelta(from payload: String) -> String? {
        guard let data = payload.data(using: .utf8) else { return nil }
        guard let event = try? JSONDecoder().decode(SSEEvent.self, from: data) else { return nil }
        guard event.type == "content_block_delta" else { return nil }
        guard event.delta?.type == "text_delta" else { return nil }
        return event.delta?.text
    }

    private struct AnthropicRequest: Encodable {
        let model: String
        let maxTokens: Int
        let stream: Bool
        let system: String
        let messages: [Message]

        enum CodingKeys: String, CodingKey {
            case model
            case maxTokens = "max_tokens"
            case stream
            case system
            case messages
        }

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    struct SSEEvent: Decodable {
        let type: String
        let delta: Delta?
        struct Delta: Decodable {
            let type: String?
            let text: String?
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
        switch prompt.language {
        case .both:
            lines.append("Answer in BOTH languages: a short Chinese line first, then a short English line.")
        case .chinese:
            lines.append("Answer in Chinese only. Keep sentences short and use words at HSK 4-5 level where you can.")
        case .english:
            lines.append("Answer in English only. Quote Chinese words with pinyin: 发酵 (fā jiào).")
        }
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
}
