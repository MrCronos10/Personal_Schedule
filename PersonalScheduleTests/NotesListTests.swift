import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// The **Notes List**: every **Note** newest first, searchable, used to read back the words met in
/// real life. See CONTEXT.md.
@MainActor
struct NotesListTests {
    private struct Shelf {
        let context: ModelContext
        let completions: CompletionLibrary
        let categories: CategoryLibrary
        let actions: ActionLibrary
    }

    private func shelf() throws -> Shelf {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        return Shelf(
            context: context,
            completions: CompletionLibrary(context: context),
            categories: CategoryLibrary(context: context),
            actions: ActionLibrary(context: context)
        )
    }

    private let day = Day(number: 20260921)

    /// One Action in one Category, so a test can get straight to the Notes.
    private func routine(_ shelf: Shelf, _ title: String, _ categoryName: String) throws -> Action {
        let category = try shelf.categories.active().first { $0.name == categoryName }
            ?? shelf.categories.add(named: categoryName)
        return try shelf.actions.addRoutine(
            title: title, category: category, repeatDays: .everyDay, startDay: Day(number: 20260101)
        )
    }

    // MARK: - What is listed

    @Test func onlyCompletionsWithANoteAreListed() throws {
        let shelf = try shelf()
        let reading = try routine(shelf, "读一篇文章", "中文")
        let jog = try routine(shelf, "跑步", "健康")

        try shelf.completions.tick(reading, on: day, minutes: 20, note: "《西湖龙井》· 新词：安排")
        try shelf.completions.tick(jog, on: day, minutes: 30, note: nil)

        let all = try shelf.context.fetch(CompletionLibrary.allDescriptor)
        #expect(CompletionLibrary.notes(all).map(\.note) == ["《西湖龙井》· 新词：安排"])
    }

    @Test func anEmptyOrBlankNoteIsNotANote() throws {
        let shelf = try shelf()
        let reading = try routine(shelf, "读一篇文章", "中文")
        try shelf.completions.tick(reading, on: day, minutes: 20, note: "")
        try shelf.completions.tick(reading, on: day.adding(days: -1), minutes: 20, note: "   \n ")

        let all = try shelf.context.fetch(CompletionLibrary.allDescriptor)
        #expect(CompletionLibrary.notes(all).isEmpty)
    }

    @Test func notesComeBackNewestFirst() throws {
        let shelf = try shelf()
        let reading = try routine(shelf, "读一篇文章", "中文")
        try shelf.completions.tick(reading, on: day.adding(days: -2), minutes: 20, note: "最早")
        try shelf.completions.tick(reading, on: day, minutes: 20, note: "最新")
        try shelf.completions.tick(reading, on: day.adding(days: -1), minutes: 20, note: "中间")

        let all = try shelf.context.fetch(CompletionLibrary.allDescriptor)
        #expect(CompletionLibrary.notes(all).map(\.note) == ["最新", "中间", "最早"])
    }

    /// Two Notes on one day must not come back in whatever order the store feels like.
    @Test func twoNotesOnOneDayKeepAStableOrder() throws {
        let shelf = try shelf()
        let reading = try routine(shelf, "读一篇文章", "中文")
        let listening = try routine(shelf, "听力", "中文")
        try shelf.completions.tick(reading, on: day, minutes: 20, note: "先写的")
        try shelf.completions.tick(listening, on: day, minutes: 20, note: "后写的")

        let all = try shelf.context.fetch(CompletionLibrary.allDescriptor)
        let once = CompletionLibrary.notes(all).map(\.note)
        let again = CompletionLibrary.notes(all.reversed()).map(\.note)
        #expect(once == again)
        // Later within the same day reads first, the same way the days themselves run.
        #expect(once == ["后写的", "先写的"])
    }

    // MARK: - Search

    @Test func anEmptySearchShowsEverything() throws {
        let shelf = try shelf()
        let reading = try routine(shelf, "读一篇文章", "中文")
        try shelf.completions.tick(reading, on: day, minutes: 20, note: "《西湖龙井》")

        let notes = CompletionLibrary.notes(try shelf.context.fetch(CompletionLibrary.allDescriptor))
        #expect(CompletionLibrary.search("", in: notes).count == 1)
        #expect(CompletionLibrary.search("   ", in: notes).count == 1)
    }

    @Test func searchMatchesInsideTheNote() throws {
        let shelf = try shelf()
        let reading = try routine(shelf, "读一篇文章", "中文")
        try shelf.completions.tick(reading, on: day, minutes: 20, note: "《西湖龙井》· 新词：安排")
        try shelf.completions.tick(reading, on: day.adding(days: -1), minutes: 20, note: "别的")

        let notes = CompletionLibrary.notes(try shelf.context.fetch(CompletionLibrary.allDescriptor))
        #expect(CompletionLibrary.search("龙井", in: notes).map(\.note) == ["《西湖龙井》· 新词：安排"])
    }

    @Test func searchMatchesTheTitleAndTheCategory() throws {
        let shelf = try shelf()
        let reading = try routine(shelf, "读一篇文章", "中文")
        let jog = try routine(shelf, "跑步", "健康")
        try shelf.completions.tick(reading, on: day, minutes: 20, note: "甲")
        try shelf.completions.tick(jog, on: day.adding(days: -1), minutes: 30, note: "乙")

        let notes = CompletionLibrary.notes(try shelf.context.fetch(CompletionLibrary.allDescriptor))
        #expect(CompletionLibrary.search("读一篇", in: notes).map(\.note) == ["甲"])
        #expect(CompletionLibrary.search("健康", in: notes).map(\.note) == ["乙"])
    }

    /// Chinese has no case; the Latin that ends up in a Note does.
    @Test func searchIgnoresCaseForLatin() throws {
        let shelf = try shelf()
        let reading = try routine(shelf, "读一篇文章", "中文")
        try shelf.completions.tick(reading, on: day, minutes: 20, note: "met a WeChat article")

        let notes = CompletionLibrary.notes(try shelf.context.fetch(CompletionLibrary.allDescriptor))
        #expect(CompletionLibrary.search("wechat", in: notes).count == 1)
        #expect(CompletionLibrary.search("WECHAT", in: notes).count == 1)
    }

    @Test func aSearchThatMatchesNothingComesBackEmpty() throws {
        let shelf = try shelf()
        let reading = try routine(shelf, "读一篇文章", "中文")
        try shelf.completions.tick(reading, on: day, minutes: 20, note: "《西湖龙井》")

        let notes = CompletionLibrary.notes(try shelf.context.fetch(CompletionLibrary.allDescriptor))
        #expect(CompletionLibrary.search("没有这个", in: notes).isEmpty)
    }

    /// ADR 0002: a Note shows, and is found by, what its Completion copied when it was ticked.
    @Test func aNoteKeepsTheTitleAndCategoryItWasTickedUnder() throws {
        let shelf = try shelf()
        let reading = try routine(shelf, "读一篇文章", "中文")
        try shelf.completions.tick(reading, on: day, minutes: 20, note: "甲")

        let health = try shelf.categories.add(named: "健康")
        try shelf.actions.updateRoutine(
            reading,
            title: "看书",
            category: health,
            repeatDays: .everyDay,
            startDay: Day(number: 20260101),
            time: nil,
            defaultMinutes: nil
        )

        let notes = CompletionLibrary.notes(try shelf.context.fetch(CompletionLibrary.allDescriptor))
        #expect(notes.first?.titleWhenTicked == "读一篇文章")
        #expect(notes.first?.category?.name == "中文")
        #expect(CompletionLibrary.search("读一篇", in: notes).count == 1)
        #expect(CompletionLibrary.search("看书", in: notes).isEmpty)
    }
}

extension NotesListTests {
    /// The other half of the rule, and the half the doc comment used to get wrong: a Category's
    /// **name** is not copied. Renaming 中文 corrects what one Category is called rather than making
    /// it a different one, so past Notes follow the new name — the same way the Progress Tracker's
    /// rows do. Only the title is frozen (ADR 0002).
    @Test func renamingACategoryRelabelsTheNotesUnderIt() throws {
        let shelf = try shelf()
        let reading = try routine(shelf, "读一篇文章", "中文")
        try shelf.completions.tick(reading, on: day, minutes: 20, note: "甲")

        let chinese = try #require(try shelf.categories.active().first { $0.name == "中文" })
        try shelf.categories.rename(chinese, to: "语文")

        let notes = CompletionLibrary.notes(try shelf.context.fetch(CompletionLibrary.allDescriptor))
        #expect(notes.first?.category?.name == "语文")
        #expect(CompletionLibrary.search("语文", in: notes).count == 1)
        #expect(CompletionLibrary.search("中文", in: notes).isEmpty)
        // The title stays as it was ticked, whatever happens to the Category.
        #expect(notes.first?.titleWhenTicked == "读一篇文章")
    }
}
