import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// Importing an **Article**: the title comes from the first line, and an Article is archived, never
/// deleted, so the **Clean Sightings** it has already banked can never be taken back. See CONTEXT.md.
@MainActor
struct ArticleLibraryTests {
    private func library() throws -> ArticleLibrary {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        return ArticleLibrary(context: ModelContext(container))
    }

    @Test func theTitleIsTheFirstLine() throws {
        let article = try library().add(text: "西湖龙井的故事\n这是第一段。\n这是第二段。")
        #expect(article.title == "西湖龙井的故事")
        #expect(article.text == "西湖龙井的故事\n这是第一段。\n这是第二段。")
    }

    @Test func theTitleIsTrimmed() throws {
        let article = try library().add(text: "  　西湖龙井  \n正文")
        #expect(article.title == "西湖龙井")
    }

    /// A pasted article often starts with a blank line, or three.
    @Test func aBlankFirstLineIsSkipped() throws {
        let article = try library().add(text: "\n\n   \n真正的标题\n正文")
        #expect(article.title == "真正的标题")
    }

    @Test func aLongFirstLineIsCut() throws {
        let long = String(repeating: "长", count: 60)
        let article = try library().add(text: long + "\n正文")
        #expect(article.title.count == 31)
        #expect(article.title.hasSuffix("…"))
        // The text itself is never cut: only the title it is named by.
        #expect(article.text.hasPrefix(long))
    }

    @Test func aFirstLineExactlyAtTheLimitKeepsAllOfIt() throws {
        let exact = String(repeating: "长", count: 30)
        let article = try library().add(text: exact + "\n正文")
        #expect(article.title == exact)
        #expect(!article.title.hasSuffix("…"))
    }

    @Test func emptyTextIsRefused() throws {
        #expect(throws: ArticleError.emptyText) { try library().add(text: "") }
    }

    @Test func whitespaceOnlyTextIsRefused() throws {
        #expect(throws: ArticleError.emptyText) { try library().add(text: "  \n\n　\n  ") }
    }

    @Test func aSourceIsKeptAndAnEmptyOneIsNothing() throws {
        let shelf = try library()
        let withSource = try shelf.add(text: "标题\n正文", source: " 微信公众号 ")
        #expect(withSource.source == "微信公众号")

        let without = try shelf.add(text: "标题\n正文", source: "   ")
        #expect(without.source == nil)

        let none = try shelf.add(text: "标题\n正文")
        #expect(none.source == nil)
    }

    @Test func readingListsUnarchivedNewestFirst() throws {
        let shelf = try library()
        let first = try shelf.add(text: "第一篇\n正文", importedDay: Day(number: 20260901))
        let second = try shelf.add(text: "第二篇\n正文", importedDay: Day(number: 20260910))
        let third = try shelf.add(text: "第三篇\n正文", importedDay: Day(number: 20260920))
        try shelf.archive(second)

        #expect(try shelf.reading().map(\.title) == [third.title, first.title])
        #expect(try shelf.archived().map(\.title) == [second.title])
    }

    /// Archiving must never take back the evidence an Article has already banked, which is why it is
    /// archived rather than deleted (ADR 0005). Nothing about the Article itself may change.
    @Test func archivingAndRestoringChangeOnlyTheFlag() throws {
        let shelf = try library()
        let article = try shelf.add(text: "标题\n正文", source: "菜单", importedDay: Day(number: 20260915))
        article.isBanked = true

        try shelf.archive(article)
        #expect(article.isArchived)
        #expect(article.title == "标题")
        #expect(article.text == "标题\n正文")
        #expect(article.source == "菜单")
        #expect(article.importedDayNumber == 20260915)
        #expect(article.isBanked)

        try shelf.restore(article)
        #expect(!article.isArchived)
        #expect(article.isBanked)
        #expect(try shelf.reading().count == 1)
    }

    /// A new Article has banked nothing yet. Ticket 16 is what sets this.
    @Test func aNewArticleHasNotBankedItsEvidence() throws {
        #expect(try library().add(text: "标题\n正文").isBanked == false)
    }

    // MARK: - Readability

    /// An Article whose measured vocabulary is exactly `words`, so a test that reads a share is
    /// reading something known. The title is a bare number: a Chinese title would smuggle its own
    /// HSK Words into the text, which is how BankingTests' fixture got its numbers wrong at first.
    private func text(_ id: Int, _ words: [String]) -> String {
        "\(id)\n" + words.map { "\($0)。" }.joined()
    }

    /// Guards the fixture below: 干净 turned out not to be on the bundled list despite looking exactly
    /// like the ordinary-looking words AGENTS.md warns about, which is precisely why this fixture is
    /// checked before its share is trusted, rather than assumed from four words picked by eye.
    @Test func theFixtureContainsExactlyFourMeasuredWords() throws {
        #expect(
            VocabularyLibrary.hskWords(in: text(1, ["厕所", "被子", "软", "热闹"])).map(\.word)
                == ["厕所", "被子", "软", "热闹"]
        )
    }

    @Test func fourMeasuredWordsWithOneKnownReadsOneQuarter() throws {
        let article = try library().add(text: text(1, ["厕所", "被子", "软", "热闹"]))
        #expect(article.readability(known: ["厕所"]) == 0.25)
    }

    /// A single repeated Word can't tell dedup apart from not dedup: nine copies of the one Known
    /// Word reads 1 whether or not they were folded into one. A second, unrepeated, unknown Word
    /// makes the two answers differ (1/2 deduped, 9/10 not), so this is what actually tests it.
    @Test func aWordRepeatedNineTimesCountsOnce() throws {
        let repeated = String(repeating: "厕所", count: 9)
        let article = try library().add(text: "1\n\(repeated)。被子。")
        #expect(article.readability(known: ["厕所"]) == 0.5)
    }

    /// Unmeasured words (HSK 1-3, names, numbers) are not in the denominator, so they cannot dilute
    /// or pad a share that is supposed to answer one question: how much of the *measured* text is
    /// already Known.
    @Test func unmeasuredWordsAreNotInTheDenominator() throws {
        let article = try library().add(text: text(1, ["厕所"]) + "很好，我是学生。")
        #expect(article.readability(known: ["厕所"]) == 1)
        #expect(article.readability(known: []) == 0)
    }

    /// No measured Words means no Readability, not zero: there is nothing to say, not "0% known".
    @Test func noMeasuredWordsMeansNoReadability() throws {
        let article = try library().add(text: "1\n很好，我是学生。")
        #expect(article.readability(known: []) == nil)
    }

    /// Readability is derived live from whatever is Known right now, not recomputed and frozen at
    /// import or at 读完 — a Word can turn Known anywhere (Daily New Words, another Article), and an
    /// Article that already banked once must still be able to read as easier later.
    @Test func aWordTurningKnownRaisesTheShareOfEveryArticleHoldingIt() throws {
        let article = try library().add(text: text(1, ["厕所", "被子"]))
        #expect(article.readability(known: []) == 0)
        #expect(article.readability(known: ["厕所"]) == 0.5)
    }

    /// An Article imported before this feature existed has no cached word list at all. It must still
    /// answer correctly rather than reading as unmeasured.
    @Test func anArticleWithNoCachedWordListStillComputesCorrectly() throws {
        let article = try library().add(text: text(1, ["厕所", "被子"]))
        article.measuredWordsText = nil
        #expect(article.readability(known: ["厕所"]) == 0.5)
    }

    /// The fallback above must not become the permanent state for an old Article: falling back on
    /// every render is exactly the "run the tokenizer over the reading list every time a tap changed
    /// one Word" cost this feature was built to avoid. `backfillMeasuredWords` catches such an
    /// Article up once, the same way `DayMigration` catches up a Day written in the wrong calendar.
    @Test func backfillFillsInArticlesWithNoCachedWordList() throws {
        let shelf = try library()
        let article = try shelf.add(text: text(1, ["厕所", "被子"]))
        article.measuredWordsText = nil
        try shelf.context.saveOrRollBack()

        #expect(try shelf.backfillMeasuredWords() == 1)
        #expect(article.measuredWordsText == "厕所\n被子")
    }

    /// Run at every start, so running it again must do nothing and touch nothing already cached.
    @Test func runningTheBackfillAgainChangesNothing() throws {
        let shelf = try library()
        let cached = try shelf.add(text: text(1, ["厕所"]))
        let uncached = try shelf.add(text: text(2, ["被子"]))
        uncached.measuredWordsText = nil
        try shelf.context.saveOrRollBack()

        #expect(try shelf.backfillMeasuredWords() == 1)
        #expect(try shelf.backfillMeasuredWords() == 0)
        #expect(cached.measuredWordsText == "厕所")
    }
}
