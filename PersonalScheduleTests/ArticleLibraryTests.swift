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
}
