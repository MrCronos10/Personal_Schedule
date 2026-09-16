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
}
