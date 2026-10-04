import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// The rules behind the four quiet moments (ADR 0009): when "all of today's Routines" is true, how
/// many characters were read today, and that the reading-goal stamp lands once a day.
@MainActor
struct CelebrationTests {
    private struct Shelf {
        let context: ModelContext
        let actions: ActionLibrary
        let completions: CompletionLibrary
        let categories: CategoryLibrary
        let vocabulary: VocabularyLibrary
        let articles: ArticleLibrary
    }

    private func shelf() throws -> Shelf {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        return Shelf(
            context: context,
            actions: ActionLibrary(context: context),
            completions: CompletionLibrary(context: context),
            categories: CategoryLibrary(context: context),
            vocabulary: VocabularyLibrary(context: context),
            articles: ArticleLibrary(context: context)
        )
    }

    private let day = Day(number: 20260921)

    private func routine(_ shelf: Shelf, _ title: String) throws -> Action {
        let category = try shelf.categories.active().first ?? shelf.categories.add(named: "中文")
        return try shelf.actions.addRoutine(
            title: title, category: category, repeatDays: .everyDay, startDay: Day(number: 20260101)
        )
    }

    private func plan(_ shelf: Shelf) throws -> [Action] {
        try DayPlan(context: shelf.context).actions(on: day, today: day)
    }

    // MARK: - All of today's Routines

    @Test func aDayWithNoRoutinesIsNotAllDone() throws {
        let shelf = try shelf()
        #expect(!DayPlan.routinesAllDone(try plan(shelf), on: day))
    }

    @Test func oneRoutineLeftMeansNotAllDone() throws {
        let shelf = try shelf()
        let read = try routine(shelf, "读一篇文章")
        _ = try routine(shelf, "背十个词")
        try shelf.completions.tick(read, on: day, minutes: 20, note: nil)

        #expect(!DayPlan.routinesAllDone(try plan(shelf), on: day))
    }

    @Test func everyRoutineTickedIsAllDoneAndUntickingUndoesIt() throws {
        let shelf = try shelf()
        let read = try routine(shelf, "读一篇文章")
        let words = try routine(shelf, "背十个词")
        try shelf.completions.tick(read, on: day, minutes: 20, note: nil)
        try shelf.completions.tick(words, on: day, minutes: 10, note: nil)
        #expect(DayPlan.routinesAllDone(try plan(shelf), on: day))

        try shelf.completions.untick(words, on: day)
        #expect(!DayPlan.routinesAllDone(try plan(shelf), on: day))
    }

    // MARK: - Characters read today

    @Test func charactersReadCountsHanCharactersOfArticlesBankedThatDay() throws {
        let shelf = try shelf()
        let today = try shelf.articles.add(text: "标题\n我们去茶馆。")      // 2 + 5 Han characters
        let yesterday = try shelf.articles.add(text: "旧文\n你好")          // 2 + 2
        let unbanked = try shelf.articles.add(text: "没读完\n还在读")
        try shelf.vocabulary.bank(yesterday, on: Day(number: 20260920))
        try shelf.vocabulary.bank(today, on: day)

        #expect(try shelf.articles.charactersRead(on: day) == 7)
        #expect(try shelf.articles.charactersRead(on: Day(number: 20260920)) == 4)
        #expect(!unbanked.isBanked)
    }

    @Test func nothingBankedMeansZeroCharacters() throws {
        #expect(try shelf().articles.charactersRead(on: day) == 0)
    }

    // MARK: - The stamp lands once a day

    private func emptyDefaults() -> UserDefaults {
        UserDefaults(suiteName: "CelebrationTests-\(UUID().uuidString)")!
    }

    @Test func theGoalStampIsDueOnlyOnceTheGoalIsReached() {
        let celebrations = Celebrations(defaults: emptyDefaults())
        #expect(!celebrations.readingGoalStampIsDue(charactersToday: 199, goal: 200, on: day))
        #expect(celebrations.readingGoalStampIsDue(charactersToday: 200, goal: 200, on: day))
    }

    @Test func theGoalStampLandsOncePerDay() {
        var celebrations = Celebrations(defaults: emptyDefaults())
        #expect(celebrations.readingGoalStampIsDue(charactersToday: 500, goal: 200, on: day))
        celebrations.markReadingGoalStamped(on: day)

        #expect(!celebrations.readingGoalStampIsDue(charactersToday: 900, goal: 200, on: day))
        #expect(celebrations.readingGoalStampIsDue(charactersToday: 500, goal: 200, on: day.adding(days: 1)))
    }

    @Test func theStampIsRememberedAfterReopening() {
        let defaults = emptyDefaults()
        var first = Celebrations(defaults: defaults)
        first.markReadingGoalStamped(on: day)

        #expect(!Celebrations(defaults: defaults).readingGoalStampIsDue(charactersToday: 500, goal: 200, on: day))
    }
}
