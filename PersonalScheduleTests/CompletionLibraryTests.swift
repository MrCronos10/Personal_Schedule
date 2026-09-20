import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

@MainActor
struct CompletionLibraryTests {
    private let monday = Day(year: 2026, month: 9, day: 14)

    /// A container with one Category and one One-time Action planned for Monday at 07:00, 20 minutes.
    private func makeMondayAction(
        defaultMinutes: Int? = 20
    ) throws -> (container: ModelContainer, action: Action) {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        let action = try ActionLibrary(context: container.mainContext).addOneTime(
            title: "学20个新词",
            category: chinese,
            day: monday,
            time: TimeOfDay(hour: 7, minute: 0),
            defaultMinutes: defaultMinutes
        )
        return (container, action)
    }

    @Test func tickingRecordsACompletionWithMinutesAndCopies() throws {
        let (container, action) = try makeMondayAction()
        let completions = CompletionLibrary(context: container.mainContext)

        try completions.tick(action, on: monday, minutes: 20, note: nil)

        let completion = try completions.completion(for: action, on: monday)
        #expect(completion?.minutes == 20)
        #expect(completion?.note == nil)
        #expect(completion?.titleWhenTicked == "学20个新词")
        #expect(completion?.category?.name == "中文")
    }

    @Test func tickingWithoutMinutesStillCountsAsDoneAndAddsNoTime() throws {
        let (container, action) = try makeMondayAction(defaultMinutes: nil)
        let completions = CompletionLibrary(context: container.mainContext)

        try completions.tick(action, on: monday, minutes: nil, note: "报销、来不及")

        let completion = try completions.completion(for: action, on: monday)
        #expect(completion != nil)
        #expect(completion?.minutes == nil)
        #expect(completion?.note == "报销、来不及")
    }

    @Test func tickingTwiceOnTheSameDayKeepsOneCompletion() throws {
        let (container, action) = try makeMondayAction()
        let completions = CompletionLibrary(context: container.mainContext)

        try completions.tick(action, on: monday, minutes: 20, note: nil)
        try completions.tick(action, on: monday, minutes: 35, note: "第二次")

        let onMonday = try container.mainContext.fetch(CompletionLibrary.descriptor(for: monday))
        #expect(onMonday.count == 1)
        #expect(onMonday.first?.minutes == 35)
        #expect(onMonday.first?.note == "第二次")

        try completions.untick(action, on: monday)
        #expect(try completions.completion(for: action, on: monday) == nil)
    }

    @Test func untickingRemovesTheCompletion() throws {
        let (container, action) = try makeMondayAction()
        let completions = CompletionLibrary(context: container.mainContext)
        try completions.tick(action, on: monday, minutes: 20, note: "很难")

        try completions.untick(action, on: monday)

        #expect(try completions.completion(for: action, on: monday) == nil)
    }

    @Test func tickingWithNegativeMinutesIsRefusedAndNothingIsSaved() throws {
        let (container, action) = try makeMondayAction()
        let completions = CompletionLibrary(context: container.mainContext)

        #expect(throws: ActionError.negativeMinutes) {
            try completions.tick(action, on: monday, minutes: -20, note: nil)
        }
        #expect(try completions.completion(for: action, on: monday) == nil)
    }

    @Test func completionsAreStillThereAfterReopening() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let storeURL = folder.appendingPathComponent("schedule.store")

        do {
            let container = try ScheduleStore.makeContainer(url: storeURL)
            let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
            let action = try ActionLibrary(context: container.mainContext)
                .addOneTime(title: "学20个新词", category: chinese, day: monday, defaultMinutes: 20)
            try CompletionLibrary(context: container.mainContext)
                .tick(action, on: monday, minutes: 25, note: "报销")
        }

        let reopened = try ScheduleStore.makeContainer(url: storeURL)
        let action = try #require(try DayPlan(context: reopened.mainContext).actions(on: monday, today: monday).first)
        let completion = try CompletionLibrary(context: reopened.mainContext).completion(for: action, on: monday)
        #expect(completion?.minutes == 25)
        #expect(completion?.note == "报销")
    }

    @Test func theCompletionKeepsItsOwnTitleWhenTheActionIsRenamedLater() throws {
        let (container, action) = try makeMondayAction()
        let completions = CompletionLibrary(context: container.mainContext)
        try completions.tick(action, on: monday, minutes: 20, note: nil)

        action.title = "学30个新词"
        try container.mainContext.saveOrRollBack()

        #expect(try completions.completion(for: action, on: monday)?.titleWhenTicked == "学20个新词")
    }

    // MARK: - The week's progress

    /// Ticks a fresh One-time Action in a Category on a day, so a week can be filled in quickly.
    private func tick(
        _ title: String,
        in category: PersonalSchedule.Category,
        on day: Day,
        minutes: Int?,
        container: ModelContainer
    ) throws {
        let action = try ActionLibrary(context: container.mainContext).addOneTime(
            title: title,
            category: category,
            day: day,
            time: nil,
            defaultMinutes: minutes
        )
        try CompletionLibrary(context: container.mainContext).tick(action, on: day, minutes: minutes, note: nil)
    }

    @Test func theWeeksMinutesAreSummedForOneCategory() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        try tick("晨读", in: chinese, on: monday, minutes: 60, container: container)
        try tick("听力", in: chinese, on: monday.adding(days: 2), minutes: 45, container: container)

        let progress = try CompletionLibrary(context: container.mainContext)
            .progress(for: chinese, in: Week(containing: monday))

        #expect(progress.minutes == 105)
        #expect(progress.completions == 2)
    }

    @Test func sundayAndTheNextMondayCountInDifferentWeeks() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        let sunday = monday.adding(days: 6)
        try tick("周日复习", in: chinese, on: sunday, minutes: 60, container: container)
        try tick("周一早读", in: chinese, on: sunday.adding(days: 1), minutes: 30, container: container)

        let completions = CompletionLibrary(context: container.mainContext)

        #expect(try completions.progress(for: chinese, in: Week(containing: monday)).minutes == 60)
        #expect(try completions.progress(for: chinese, in: Week(containing: sunday.adding(days: 1))).minutes == 30)
    }

    @Test func aCompletionWithNoMinutesIsCountedButAddsNoTime() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let life = try CategoryLibrary(context: container.mainContext).add(named: "生活")
        try tick("买SIM卡", in: life, on: monday, minutes: nil, container: container)
        try tick("取快递", in: life, on: monday, minutes: nil, container: container)

        let progress = try CompletionLibrary(context: container.mainContext)
            .progress(for: life, in: Week(containing: monday))

        #expect(progress.minutes == 0)
        #expect(progress.completions == 2)
    }

    /// ADR 0002: a Completion counts where it was filed when it was ticked, not where the Action lives now.
    @Test func movingAnActionToAnotherCategoryLeavesItsCompletionsWhereTheyWere() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let categories = CategoryLibrary(context: container.mainContext)
        let chinese = try categories.add(named: "中文")
        let study = try categories.add(named: "学习")
        let action = try ActionLibrary(context: container.mainContext).addOneTime(
            title: "翻译练习",
            category: chinese,
            day: monday,
            time: nil,
            defaultMinutes: 80
        )
        let completions = CompletionLibrary(context: container.mainContext)
        try completions.tick(action, on: monday, minutes: 80, note: nil)

        action.category = study
        try container.mainContext.saveOrRollBack()

        let week = Week(containing: monday)
        #expect(try completions.progress(for: chinese, in: week).minutes == 80)
        #expect(try completions.progress(for: study, in: week).minutes == 0)
    }

    @Test func aCategoryArchivedPartwayThroughTheWeekStillReportsThatWeeksMinutes() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let categories = CategoryLibrary(context: container.mainContext)
        let study = try categories.add(named: "学习")
        try tick("看书", in: study, on: monday, minutes: 60, container: container)

        try categories.archive(study)

        let progress = try CompletionLibrary(context: container.mainContext)
            .progress(for: study, in: Week(containing: monday))
        #expect(progress.minutes == 60)
        #expect(progress.completions == 1)
    }

    /// ADR 0002 again, on the path that actually happens: the student fixes Monday's minutes on Wednesday,
    /// after the Action has been edited. Changing what a finished day recorded must not re-file it.
    @Test func correctingAFinishedDaysMinutesLeavesItsCopiesAlone() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let categories = CategoryLibrary(context: container.mainContext)
        let chinese = try categories.add(named: "中文")
        let study = try categories.add(named: "学习")
        let action = try ActionLibrary(context: container.mainContext).addOneTime(
            title: "翻译练习",
            category: chinese,
            day: monday,
            time: nil,
            defaultMinutes: 80
        )
        let completions = CompletionLibrary(context: container.mainContext)
        try completions.tick(action, on: monday, minutes: 80, note: nil)

        action.category = study
        action.title = "翻译练习（改）"
        try container.mainContext.saveOrRollBack()
        try completions.tick(action, on: monday, minutes: 95, note: "记错了")

        let completion = try #require(try completions.completion(for: action, on: monday))
        #expect(completion.minutes == 95)
        #expect(completion.note == "记错了")
        #expect(completion.titleWhenTicked == "翻译练习")
        #expect(completion.category?.name == "中文")

        let week = Week(containing: monday)
        #expect(try completions.progress(for: chinese, in: week).minutes == 95)
        #expect(try completions.progress(for: study, in: week).minutes == 0)
    }

    // MARK: - Which Categories the week shows

    @Test func theWeekShowsActiveCategoriesInCreationOrder() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let categories = CategoryLibrary(context: container.mainContext)
        try categories.add(named: "中文")
        try categories.add(named: "健康")
        try categories.add(named: "生活")

        let rows = try CompletionLibrary(context: container.mainContext).week(containing: monday)

        #expect(rows.map(\.category.name) == ["中文", "健康", "生活"])
    }

    @Test func anArchivedCategoryShowsOnlyInAWeekItHasCompletions() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let categories = CategoryLibrary(context: container.mainContext)
        let chinese = try categories.add(named: "中文")
        let study = try categories.add(named: "学习")
        try tick("看书", in: study, on: monday, minutes: 60, container: container)
        try categories.archive(study)

        let completions = CompletionLibrary(context: container.mainContext)
        let thisWeek = try completions.week(containing: monday)
        let nextWeek = try completions.week(containing: monday.adding(days: 7))

        #expect(thisWeek.map(\.category.name) == ["中文", "学习"])
        #expect(thisWeek.last?.isArchived == true)
        #expect(nextWeek.map(\.category.name) == ["中文"])
        #expect(chinese.isArchived == false)
    }
}
