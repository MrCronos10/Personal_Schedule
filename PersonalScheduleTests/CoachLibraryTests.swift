import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// The **Reading Coach**'s rules: building a prompt, saving the exchange, respecting what the
/// Coach is not allowed to touch. See CONTEXT.md and ADR 0008.
@MainActor
struct CoachLibraryTests {
    /// Captures the last prompt the library sent, and hands back whatever the test wants to come
    /// back from the model. The real client streams Server-Sent Events; the fake yields its chunks
    /// one at a time so a test can assert what the Library did with each piece as it arrived.
    final class FakeCoachClient: CoachClient, @unchecked Sendable {
        var lastPrompt: CoachPrompt?
        var chunks: [String] = ["好的 (hǎo de) · OK."]
        var errorToThrow: Error?

        func streamReply(to prompt: CoachPrompt) -> AsyncThrowingStream<String, Error> {
            lastPrompt = prompt
            return AsyncThrowingStream { continuation in
                if let errorToThrow {
                    continuation.finish(throwing: errorToThrow)
                    return
                }
                for chunk in chunks { continuation.yield(chunk) }
                continuation.finish()
            }
        }
    }

    private struct Setup {
        let context: ModelContext
        let fake: FakeCoachClient
        let library: CoachLibrary
    }

    private func setUp() throws -> Setup {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let fake = FakeCoachClient()
        return Setup(context: context, fake: fake,
                     library: CoachLibrary(context: context, client: fake))
    }

    private func article(_ text: String, _ title: String = "示例") throws -> Article {
        let setup = try setUp()
        let article = try ArticleLibrary(context: setup.context).add(text: "\(title)\n\(text)")
        return article
    }

    // MARK: - Saving an exchange

    @Test func askingSavesTheQuestionAndTheReply() async throws {
        let setup = try setUp()
        let article = try ArticleLibrary(context: setup.context).add(text: "鸡粪堆肥\n鸡粪和稻壳搅拌。")
        setup.fake.chunks = ["鸡粪 (jī fèn) ", "means chicken manure."]
        _ = try await setup.library.ask("什么是 鸡粪?", about: article, language: .english)
        let messages = try setup.library.messages(for: article)
        #expect(messages.count == 2)
        #expect(messages[0].role == .user)
        #expect(messages[0].text == "什么是 鸡粪?")
        #expect(messages[1].role == .coach)
        #expect(messages[1].text == "鸡粪 (jī fèn) means chicken manure.",
                "chunks must be joined in order into the saved reply")
    }

    @Test func chunksArriveAtTheViewAsTheyStream() async throws {
        let setup = try setUp()
        let article = try ArticleLibrary(context: setup.context).add(text: "示例\n一句话。")
        setup.fake.chunks = ["你", "好", "。"]
        var received: [String] = []
        _ = try await setup.library.ask("打个招呼", about: article, language: .chinese) { chunk in
            received.append(chunk)
        }
        #expect(received == ["你", "好", "。"], "each chunk must reach the view in order")
    }

    @Test func anEmptyQuestionIsRefused() async throws {
        let setup = try setUp()
        let article = try ArticleLibrary(context: setup.context).add(text: "示例\n一句话。")
        await #expect(throws: CoachLibraryError.emptyQuestion) {
            _ = try await setup.library.ask("   ", about: article, language: .both)
        }
        #expect(try setup.library.messages(for: article).isEmpty)
    }

    @Test func aFailedReplyLeavesTheThreadClean() async throws {
        let setup = try setUp()
        let article = try ArticleLibrary(context: setup.context).add(text: "示例\n一句话。")
        setup.fake.errorToThrow = CoachClientError.transport("offline")
        await #expect(throws: CoachClientError.self) {
            _ = try await setup.library.ask("解释一下", about: article, language: .both)
        }
        // The user's turn was rolled back, so a thread that never got an answer doesn't show one.
        #expect(try setup.library.messages(for: article).isEmpty)
    }

    @Test func clearingTheThreadRemovesOnlyThisArticlesMessages() async throws {
        let setup = try setUp()
        let shelf = ArticleLibrary(context: setup.context)
        let a = try shelf.add(text: "一\n鸡粪堆肥。")
        let b = try shelf.add(text: "二\n猪粪发酵。")
        _ = try await setup.library.ask("Q about A", about: a, language: .english)
        _ = try await setup.library.ask("Q about B", about: b, language: .english)
        try setup.library.clearMessages(for: a)
        #expect(try setup.library.messages(for: a).isEmpty)
        #expect(try setup.library.messages(for: b).count == 2)
    }

    // MARK: - The prompt

    @Test func aShortThreadIsSentWholeSoTheCoachRemembers() async throws {
        let setup = try setUp()
        let article = try ArticleLibrary(context: setup.context).add(text: "示例\n一句话。")
        _ = try await setup.library.ask("第一问", about: article, language: .both)
        _ = try await setup.library.ask("第二问", about: article, language: .both)
        let prompt = try #require(setup.fake.lastPrompt)
        // Three turns in the prompt the Coach sees for the second ask: Q1, A1, Q2. The second
        // reply has not been written yet when the client is called.
        #expect(prompt.history.count == 3)
        #expect(prompt.history[0].role == .user)
        #expect(prompt.history[0].text == "第一问")
        #expect(prompt.history[1].role == .assistant)
        #expect(prompt.history.last?.role == .user)
        #expect(prompt.history.last?.text == "第二问")
    }

    @Test func onlyTheLastSixEarlierTurnsTravelWithANewQuestion() async throws {
        let setup = try setUp()
        let article = try ArticleLibrary(context: setup.context).add(text: "示例\n一句话。")
        for question in ["第一问", "第二问", "第三问", "第四问", "第五问"] {
            _ = try await setup.library.ask(question, about: article, language: .both)
        }
        // Eight earlier turns were saved before the fifth ask (Q1 A1 … Q4 A4). The Coach sees the
        // last six of them, Q2 to A4, then the new question. ADR 0011.
        #expect(CoachLibrary.historyLimit == 6)
        let prompt = try #require(setup.fake.lastPrompt)
        #expect(prompt.history.count == 7)
        #expect(prompt.history.first?.role == .user)
        #expect(prompt.history.first?.text == "第二问")
        #expect(prompt.history.last?.text == "第五问")
    }

    @Test func theWindowNeverOpensOnACoachReply() async throws {
        // A question left unanswered (the app killed mid-reply, so the rollback never ran) breaks
        // the question/answer rhythm. Seven earlier rows: Q1 A1 Q-orphan Q2 A2 Q3 A3. The last six
        // would open on A1, a reply to a question the Coach can no longer see.
        let setup = try setUp()
        let article = try ArticleLibrary(context: setup.context).add(text: "示例\n一句话。")
        let start = Date(timeIntervalSince1970: 1_000)
        let rows: [(CoachMessageRole, String)] = [(.user, "Q1"), (.coach, "A1"), (.user, "Q-orphan"),
                                                  (.user, "Q2"), (.coach, "A2"), (.user, "Q3"), (.coach, "A3")]
        for (index, row) in rows.enumerated() {
            setup.context.insert(CoachMessage(role: row.0, text: row.1, article: article, language: .both,
                                              day: Day.today(), createdAt: start.addingTimeInterval(Double(index))))
        }
        try setup.context.save()
        #expect(try setup.library.messages(for: article).count == 7)

        _ = try await setup.library.ask("Q4", about: article, language: .both)
        let prompt = try #require(setup.fake.lastPrompt)
        #expect(prompt.history.first?.role == .user)
        #expect(prompt.history.first?.text == "Q-orphan")
        #expect(prompt.history.last?.text == "Q4")
    }

    @Test func trimmingThePromptNeverHidesASavedMessage() async throws {
        let setup = try setUp()
        let article = try ArticleLibrary(context: setup.context).add(text: "示例\n一句话。")
        for question in ["第一问", "第二问", "第三问", "第四问", "第五问"] {
            _ = try await setup.library.ask(question, about: article, language: .both)
        }
        let messages = try setup.library.messages(for: article)
        #expect(messages.count == 10)
        #expect(messages.first?.text == "第一问")
    }

    @Test func theArticlesTitleSourceAndTextTravelWithTheQuestion() async throws {
        let setup = try setUp()
        let article = try ArticleLibrary(context: setup.context).add(text: "鸡粪堆肥\n鸡粪和稻壳搅拌。")
        article.source = "示例 · 微信"
        try setup.context.save()
        _ = try await setup.library.ask("解释一下", about: article, language: .both)
        let prompt = try #require(setup.fake.lastPrompt)
        #expect(prompt.article.title == "鸡粪堆肥")
        #expect(prompt.article.source == "示例 · 微信")
        #expect(prompt.article.text.contains("鸡粪和稻壳搅拌"))
    }

    @Test func topicWordsInsideTheArticleAreCalledOutToTheCoach() async throws {
        let setup = try setUp()
        let article = try ArticleLibrary(context: setup.context).add(text: "肥料厂\n肥料厂里有造粒机。")
        _ = try await setup.library.ask("解释", about: article, language: .both)
        let prompt = try #require(setup.fake.lastPrompt)
        // 肥料厂 and 造粒机 are on the Topic List (ticket 11).
        #expect(prompt.topicWordsInArticle.contains("肥料厂"))
        #expect(prompt.topicWordsInArticle.contains("造粒机"))
    }

    @Test func onlyKnownHSKWordsThatActuallyAppearInTheArticleAreListed() async throws {
        let setup = try setUp()
        let article = try ArticleLibrary(context: setup.context).add(text: "示例\n我今天去参观肥料厂，看到了许多颗粒。")
        // Mark two HSK Words Known, one of which is in the Article and one of which is not.
        let inArticle = WordProgress(word: "参观", level: .four)
        inArticle.isKnown = true
        let elsewhere = WordProgress(word: "医院", level: .four)
        elsewhere.isKnown = true
        setup.context.insert(inArticle)
        setup.context.insert(elsewhere)
        try setup.context.save()

        _ = try await setup.library.ask("解释", about: article, language: .both)
        let prompt = try #require(setup.fake.lastPrompt)
        #expect(prompt.knownInArticle.contains("参观"))
        #expect(!prompt.knownInArticle.contains("医院"),
                "a Known Word not in the Article is noise and must not travel with the prompt")
    }

    // MARK: - The Coach's house rules

    @Test func theCoachNeverWritesAKnownOrASightingOrALookup() async throws {
        let setup = try setUp()
        let article = try ArticleLibrary(context: setup.context).add(text: "示例\n鸡粪和稻壳。")
        setup.fake.chunks = ["鸡粪 (jī fèn) means chicken manure. 稻壳 (dào ké) is rice husk."]
        _ = try await setup.library.ask("解释这两个词", about: article, language: .both)

        let known = try setup.context.fetch(FetchDescriptor<WordProgress>(predicate: #Predicate { $0.isKnown }))
        #expect(known.isEmpty, "the Coach must never mark a Word Known")
        #expect(try setup.context.fetch(FetchDescriptor<CleanSighting>()).isEmpty,
                "the Coach must never bank a Clean Sighting")
        #expect(try setup.context.fetch(FetchDescriptor<WordLookup>()).isEmpty,
                "the Coach must never record a Lookup")
        #expect(try setup.context.fetch(FetchDescriptor<TopicWordProgress>()).isEmpty,
                "the Coach must never mark a Topic Known")
    }

    // MARK: - The system prompt

    @Test func switchingLanguageLeavesTheSystemPromptIdentical() throws {
        // The system prompt is the start the provider caches. A per-message value inside it would
        // break the cache for everything after it. ADR 0011.
        let base = CoachPrompt(history: [CoachTurn(role: .user, text: "hi")],
                               article: ArticleView(title: "t", source: nil, text: "x"),
                               knownInArticle: [], topicWordsInArticle: [], language: .chinese)
        var english = base; english.language = .english
        var both = base; both.language = .both
        let system = CoachPromptBuilder.systemPrompt(for: base)
        #expect(CoachPromptBuilder.systemPrompt(for: english) == system)
        #expect(CoachPromptBuilder.systemPrompt(for: both) == system)
    }

    @Test func theLanguageLineTravelsWithTheNewQuestionOnly() throws {
        let prompt = CoachPrompt(history: [CoachTurn(role: .user, text: "第一问"),
                                           CoachTurn(role: .assistant, text: "答"),
                                           CoachTurn(role: .user, text: "第二问")],
                                 article: ArticleView(title: "t", source: nil, text: "x"),
                                 knownInArticle: [], topicWordsInArticle: [], language: .english)
        let messages = CoachPromptBuilder.chatMessages(for: prompt)
        #expect(messages.map(\.role) == ["system", "user", "assistant", "user"])
        #expect(messages[0].content == CoachPromptBuilder.systemPrompt(for: prompt))
        #expect(messages[1].content == "第一问", "an earlier question is sent as it was asked")
        #expect(messages[3].content.hasPrefix("第二问"))
        #expect(messages[3].content.contains("English only"))
    }

    @Test func theSystemPromptRunsHouseRulesThenArticleThenWordLists() throws {
        let prompt = CoachPrompt(history: [], article: ArticleView(title: "标题", source: nil, text: "正文"),
                                 knownInArticle: ["参观"], topicWordsInArticle: ["肥料厂"], language: .both)
        let system = CoachPromptBuilder.systemPrompt(for: prompt)
        let rules = try #require(system.range(of: "House rules")).lowerBound
        let article = try #require(system.range(of: "正文")).lowerBound
        let known = try #require(system.range(of: "参观")).lowerBound
        let topic = try #require(system.range(of: "肥料厂")).lowerBound
        #expect(rules < article)
        #expect(article < known)
        #expect(article < topic)
    }

    @Test func theSystemPromptCarriesTheHouseRulesFromADR0008() throws {
        let prompt = CoachPrompt(history: [], article: ArticleView(title: "t", source: nil, text: "x"),
                                 knownInArticle: [], topicWordsInArticle: [], language: .both)
        let system = CoachPromptBuilder.systemPrompt(for: prompt)
        #expect(system.contains("Never mark a word as learned"))
        #expect(system.contains("No streak") || system.contains("no streak"))
    }
}
