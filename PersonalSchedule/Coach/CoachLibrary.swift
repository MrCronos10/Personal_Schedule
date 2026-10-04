import Foundation
import SwiftData

/// The **Reading Coach**'s rule book: how a question becomes a prompt, how a reply is saved, what
/// the Coach is and isn't allowed to touch. See CONTEXT.md and ADR 0008.
///
/// The Coach never writes a **Known**, a **Clean Sighting**, a **Lookup** or a **Topic Known** —
/// those live where ADR 0004 and ADR 0007 said they do. This library is read-only against them;
/// its only writes are `CoachMessage` rows for the chat log.
@MainActor
struct CoachLibrary {
    let context: ModelContext
    let client: CoachClient

    /// What the Coach has already said about this Article, oldest first. The chat sheet renders
    /// this directly; a new session opens where the last one ended.
    func messages(for article: Article) throws -> [CoachMessage] {
        try context.fetch(FetchDescriptor<CoachMessage>(
            sortBy: [SortDescriptor(\.createdAt)]
        )).filter { $0.article?.persistentModelID == article.persistentModelID }
    }

    /// Sends a question to the Coach and saves the exchange. The whole thread is sent each time so
    /// the Coach can answer "what does 'this' mean" with the previous reply still in mind.
    ///
    /// Two rows are written: the student's turn, then the Coach's reply, in order. The call throws
    /// if the client fails and the user turn is rolled back — a question that never got an answer
    /// is kept out of the thread rather than kept as a dangling line that will never be answered.
    ///
    /// `onChunk` receives each piece of the reply as it streams in, so the sheet can show the reply
    /// building up live rather than appearing all at once. The final CoachMessage is saved with the
    /// joined whole; a view that only reloads at the end still sees the complete reply.
    @discardableResult
    func ask(_ question: String, about article: Article, language: CoachLanguage,
             on day: Day = Day.today(),
             onChunk: ((String) -> Void)? = nil) async throws -> CoachMessage {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CoachLibraryError.emptyQuestion }

        let userMessage = CoachMessage(role: .user, text: trimmed, article: article, language: language, day: day)
        context.insert(userMessage)
        try context.save()

        let prompt = try buildPrompt(for: article, latest: trimmed, language: language)

        do {
            var reply = ""
            for try await chunk in client.streamReply(to: prompt) {
                reply += chunk
                onChunk?(chunk)
            }
            let trimmedReply = reply.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedReply.isEmpty else { throw CoachClientError.malformedResponse }
            let coachMessage = CoachMessage(role: .coach, text: trimmedReply, article: article,
                                            language: language, day: day)
            context.insert(coachMessage)
            try context.save()
            return coachMessage
        } catch {
            // The question never got an answer, or the answer came back empty: drop the user row so
            // the thread doesn't carry an unanswered line that will stay that way forever.
            context.delete(userMessage)
            try? context.save()
            throw error
        }
    }

    /// Clears this Article's chat. Deleting rather than archiving, because a `CoachMessage` isn't
    /// evidence — the student's **Known** count depends on nothing here — and keeping stale advice
    /// around is worse than losing it.
    func clearMessages(for article: Article) throws {
        for message in try messages(for: article) {
            context.delete(message)
        }
        try context.save()
    }

    /// Builds the prompt from the Article, the Known HSK Words inside it, and the Topic Words
    /// inside it. Exposed so tests can assert what the Coach actually sends — not internal, so a
    /// change here is one the tests catch.
    func buildPrompt(for article: Article, latest: String, language: CoachLanguage) throws -> CoachPrompt {
        let priorMessages = try messages(for: article)
        var history: [CoachTurn] = priorMessages.map { message in
            CoachTurn(role: message.role == .user ? .user : .assistant, text: message.text)
        }
        // The user's turn just saved isn't in the fetched history until the next read, so append it
        // explicitly. (It was already saved in `ask`, but the prompt is built on the data about to
        // be sent, not the data in the store.)
        if history.last?.role != .user || history.last?.text != latest {
            history.append(CoachTurn(role: .user, text: latest))
        }

        let articleView = ArticleView(title: article.title, source: article.source, text: article.text)
        let hskWords = VocabularyLibrary.hskWords(in: article.text).map(\.word)
        let knownInArticle = try knownHSKWords(in: Set(hskWords))
        let topicInArticle = topicWords(in: article.text)
        return CoachPrompt(history: history,
                           article: articleView,
                           knownInArticle: knownInArticle,
                           topicWordsInArticle: topicInArticle,
                           language: language)
    }

    // MARK: - Context

    private func knownHSKWords(in articleWords: Set<String>) throws -> [String] {
        guard !articleWords.isEmpty else { return [] }
        let rows = try context.fetch(FetchDescriptor<WordProgress>(predicate: #Predicate { $0.isKnown }))
        return rows.map(\.word).filter(articleWords.contains).sorted()
    }

    private func topicWords(in text: String) -> [String] {
        // Longest-match pass against the bundled Topic List, matching how the 农业词 screen marks
        // words so the Coach's view of the Article agrees with what the student sees.
        let candidates = TopicWordList.all.map(\.word).sorted { $0.count > $1.count }
        var seen: Set<String> = []
        var out: [String] = []
        for candidate in candidates where text.contains(candidate) {
            if seen.insert(candidate).inserted { out.append(candidate) }
        }
        return out.sorted()
    }
}

enum CoachLibraryError: LocalizedError, Equatable {
    case emptyQuestion

    var errorDescription: String? {
        switch self {
        case .emptyQuestion: return "Write a question first."
        }
    }
}
