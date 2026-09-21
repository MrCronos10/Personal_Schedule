import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// A **Reading Session** ends in an ordinary **Completion**, so the Progress Tracker and **Weekly
/// Targets** need no new code at all. See CONTEXT.md.
@MainActor
struct ReadingSessionTests {
    private struct Shelf {
        let context: ModelContext
        let vocabulary: VocabularyLibrary
        let articles: ArticleLibrary
        let completions: CompletionLibrary
        let categories: CategoryLibrary
        let actions: ActionLibrary
    }

    private func shelf() throws -> Shelf {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        return Shelf(
            context: context,
            vocabulary: VocabularyLibrary(context: context),
            articles: ArticleLibrary(context: context),
            completions: CompletionLibrary(context: context),
            categories: CategoryLibrary(context: context),
            actions: ActionLibrary(context: context)
        )
    }

    private let day = Day(number: 20260921)

    // MARK: - Minutes

    @Test func secondsRoundToTheNearestMinute() throws {
        #expect(ReadingSession.minutes(forSeconds: 0) == 1)
        #expect(ReadingSession.minutes(forSeconds: 20) == 1)
        #expect(ReadingSession.minutes(forSeconds: 89) == 1)
        #expect(ReadingSession.minutes(forSeconds: 90) == 2)
        #expect(ReadingSession.minutes(forSeconds: 600) == 10)
    }

    /// A session is never worth nothing: the student did read it.
    @Test func aSessionIsNeverZeroMinutes() throws {
        #expect(ReadingSession.minutes(forSeconds: -5) == 1)
    }

    // MARK: - The Note

    @Test func theNotePrefillNamesTheArticleAndTheWordsMet() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "西湖龙井\n厕所。被子。")
        let note = try shelf.vocabulary.noteForSession(with: article)
        #expect(note.contains("西湖龙井"))
        #expect(note.contains("厕所"))
        #expect(note.contains("被子"))
        #expect(note.contains("、"))
    }

    /// Words already Known aren't new, so they don't belong in a note about what was met.
    @Test func theNoteLeavesOutWordsAlreadyKnown() throws {
        let shelf = try shelf()
        try shelf.vocabulary.markKnown("厕所", on: day)
        let article = try shelf.articles.add(text: "西湖龙井\n厕所。被子。")
        let note = try shelf.vocabulary.noteForSession(with: article)
        #expect(!note.contains("厕所"))
        #expect(note.contains("被子"))
    }

    @Test func anArticleWithNothingNewLeavesNoDanglingClause() throws {
        let shelf = try shelf()
        try shelf.vocabulary.markKnown("厕所", on: day)
        let article = try shelf.articles.add(text: "西湖龙井\n厕所。")
        let note = try shelf.vocabulary.noteForSession(with: article)
        #expect(note.contains("西湖龙井"))
        #expect(!note.contains("新词"))
        #expect(!note.hasSuffix("："))
    }

    @Test func theNoteStopsAtEightWords() throws {
        let shelf = try shelf()
        let words = [
            "厕所", "被子", "危险", "方向", "困难", "解释", "拒绝",
            "温柔", "厉害", "规定", "不过", "名胜古迹",
        ]
        let article = try shelf.articles.add(text: "很多词\n" + words.map { "\($0)。" }.joined())
        // The test only means something if the Article really holds more Words than a Note names.
        let met = VocabularyLibrary.hskWords(in: article.text).count
        #expect(met > VocabularyLibrary.wordsNamedInNote, "fixture holds only \(met) measured Words")

        let note = try shelf.vocabulary.noteForSession(with: article)
        #expect(note.components(separatedBy: "、").count == VocabularyLibrary.wordsNamedInNote)
        #expect(note.hasSuffix("…"))
    }

    // MARK: - The Completion

    /// The whole point of the join: nothing about a reading Completion is special.
    @Test func aReadingCompletionIsAnOrdinaryCompletion() throws {
        let shelf = try shelf()
        let chinese = try shelf.categories.add(named: "中文")
        try shelf.categories.setWeeklyTarget(420, on: chinese)
        let action = try shelf.actions.addRoutine(
            title: "读一篇文章", category: chinese, repeatDays: .everyDay, startDay: day
        )

        let completion = try shelf.completions.tick(action, on: day, minutes: 18, note: "《西湖龙井》")
        #expect(completion.titleWhenTicked == "读一篇文章")
        #expect(completion.category?.name == "中文")
        #expect(completion.minutes == 18)

        let week = CompletionLibrary.week(
            Week(containing: day),
            categories: [chinese],
            completions: [completion]
        )
        #expect(week.first?.minutes == 18)
        #expect(week.first?.weeklyTargetMinutes == 420)
    }

    /// 不记录 must leave the evidence exactly as it was: banking and ticking are independent.
    @Test func decliningToRecordLeavesTheEvidenceAlone() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "西湖龙井\n厕所。")
        try shelf.vocabulary.bank(article, on: day)
        #expect(try shelf.vocabulary.progress(for: "厕所")?.cleanSightings == 1)

        // No Completion is saved at all.
        #expect(try shelf.context.fetch(CompletionLibrary.allDescriptor).isEmpty)
        #expect(try shelf.vocabulary.progress(for: "厕所")?.cleanSightings == 1)
    }

    // MARK: - Which Action it offers

    @Test func todaysUntickedRoutineInTheUsualCategoryIsOfferedFirst() throws {
        let shelf = try shelf()
        let chinese = try shelf.categories.add(named: "中文")
        let health = try shelf.categories.add(named: "健康")
        let reading = try shelf.actions.addRoutine(
            title: "读一篇文章", category: chinese, repeatDays: .everyDay, startDay: day
        )
        let jog = try shelf.actions.addRoutine(
            title: "跑步", category: health, repeatDays: .everyDay, startDay: day
        )
        // 中文 is where the student's Completions have been coming from.
        try shelf.completions.tick(jog, on: day.adding(days: -1), minutes: 30, note: nil)
        try shelf.completions.tick(reading, on: day.adding(days: -2), minutes: 20, note: nil)
        try shelf.completions.tick(reading, on: day.adding(days: -3), minutes: 20, note: nil)

        let offered = ReadingSession.offer(
            among: [jog, reading],
            completions: try shelf.context.fetch(CompletionLibrary.allDescriptor),
            on: day
        )
        #expect(offered.first?.title == "读一篇文章")
    }

    @Test func aOneTimeActionIsOfferedToo() throws {
        let shelf = try shelf()
        let chinese = try shelf.categories.add(named: "中文")
        // A One-time Action is still offered: the student may well want to tick it. What matters is
        // that nothing is invented and 不记录 is always there.
        let oneTime = try shelf.actions.addOneTime(title: "买SIM卡", category: chinese, day: day)
        let offered = ReadingSession.offer(among: [oneTime], completions: [], on: day)
        #expect(offered.map(\.title) == ["买SIM卡"])
    }

    @Test func aRoutineAlreadyTickedTodayIsNotOffered() throws {
        let shelf = try shelf()
        let chinese = try shelf.categories.add(named: "中文")
        let reading = try shelf.actions.addRoutine(
            title: "读一篇文章", category: chinese, repeatDays: .everyDay, startDay: day
        )
        try shelf.completions.tick(reading, on: day, minutes: 20, note: nil)

        let offered = ReadingSession.offer(
            among: [reading],
            completions: try shelf.context.fetch(CompletionLibrary.allDescriptor),
            on: day
        )
        #expect(offered.isEmpty)
    }
}

extension ReadingSessionTests {
    /// 不记录 is always available, so the offer may be empty and that is not an error.
    @Test func theOfferPutsTheUsualCategoryFirstAndLeavesOutWhatIsDone() throws {
        let shelf = try shelf()
        let chinese = try shelf.categories.add(named: "中文")
        let health = try shelf.categories.add(named: "健康")
        let jog = try shelf.actions.addRoutine(
            title: "跑步", category: health, repeatDays: .everyDay, startDay: day
        )
        let reading = try shelf.actions.addRoutine(
            title: "读一篇文章", category: chinese, repeatDays: .everyDay, startDay: day
        )
        let done = try shelf.actions.addRoutine(
            title: "听力", category: chinese, repeatDays: .everyDay, startDay: day
        )
        try shelf.completions.tick(reading, on: day.adding(days: -1), minutes: 20, note: nil)
        try shelf.completions.tick(done, on: day, minutes: 10, note: nil)

        let offered = ReadingSession.offer(
            among: [jog, reading, done],
            completions: try shelf.context.fetch(CompletionLibrary.allDescriptor),
            on: day
        )
        #expect(offered.map(\.title) == ["读一篇文章", "跑步"])
    }
}
