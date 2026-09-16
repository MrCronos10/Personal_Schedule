import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

@MainActor
struct DayPlanTests {
    private let monday = Day(year: 2026, month: 9, day: 14)

    @Test func oneTimeActionAppearsOnItsDayWithItsDetails() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        let actions = ActionLibrary(context: container.mainContext)

        try actions.addOneTime(
            title: "学20个新词",
            category: chinese,
            day: monday,
            time: TimeOfDay(hour: 7, minute: 0),
            defaultMinutes: 20
        )

        let plan = try DayPlan(context: container.mainContext).actions(on: monday, today: monday)
        #expect(plan.count == 1)
        #expect(plan.first?.title == "学20个新词")
        #expect(plan.first?.category?.name == "中文")
        #expect(plan.first?.time == TimeOfDay(hour: 7, minute: 0))
        #expect(plan.first?.defaultMinutes == 20)
    }

    @Test(arguments: ["", "   "])
    func blankTitleIsRefusedAndNothingIsSaved(title: String) throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        let actions = ActionLibrary(context: container.mainContext)

        #expect(throws: ActionError.emptyTitle) {
            try actions.addOneTime(title: title, category: chinese, day: monday)
        }
        #expect(try DayPlan(context: container.mainContext).actions(on: monday, today: monday).isEmpty)
    }

    @Test func archivedCategoryCantBeChosen() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let categories = CategoryLibrary(context: container.mainContext)
        let club = try categories.add(named: "篮球社")
        try categories.archive(club)
        let actions = ActionLibrary(context: container.mainContext)

        #expect(throws: ActionError.archivedCategory) {
            try actions.addOneTime(title: "打篮球", category: club, day: monday)
        }
        #expect(try DayPlan(context: container.mainContext).actions(on: monday, today: monday).isEmpty)
    }

    @Test func negativeDefaultMinutesAreRefusedAndNothingIsSaved() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let life = try CategoryLibrary(context: container.mainContext).add(named: "健康")
        let actions = ActionLibrary(context: container.mainContext)

        #expect(throws: ActionError.negativeMinutes) {
            try actions.addOneTime(title: "健身", category: life, day: monday, defaultMinutes: -30)
        }
        #expect(try DayPlan(context: container.mainContext).actions(on: monday, today: monday).isEmpty)
    }

    /// A day still ahead keeps its Action: nothing moves until the planned day has passed.
    @Test func actionPlannedForALaterDayAppearsOnlyOnThatDay() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let life = try CategoryLibrary(context: container.mainContext).add(named: "生活")
        let tuesday = Day(year: 2026, month: 9, day: 15)
        try ActionLibrary(context: container.mainContext)
            .addOneTime(title: "买SIM卡", category: life, day: tuesday)
        let plan = DayPlan(context: container.mainContext)

        #expect(try plan.actions(on: monday, today: monday).isEmpty)
        #expect(try plan.actions(on: tuesday, today: monday).map(\.title) == ["买SIM卡"])
        #expect(try plan.actions(on: Day(year: 2026, month: 9, day: 16), today: monday).isEmpty)
    }

    @Test func lateOneTimeActionMovesToTodayAndNotToTheDaysBetween() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let life = try CategoryLibrary(context: container.mainContext).add(named: "生活")
        try ActionLibrary(context: container.mainContext)
            .addOneTime(title: "买SIM卡", category: life, day: monday)
        let plan = DayPlan(context: container.mainContext)
        let today = Day(year: 2026, month: 9, day: 17)

        #expect(try plan.actions(on: today, today: today).map(\.title) == ["买SIM卡"])
        #expect(try plan.actions(on: monday, today: today).isEmpty)
        #expect(try plan.actions(on: Day(year: 2026, month: 9, day: 15), today: today).isEmpty)
        #expect(try plan.actions(on: Day(year: 2026, month: 9, day: 16), today: today).isEmpty)
    }

    /// Once ticked, a late Action stops moving: it stays on the day it was ticked, not on later days.
    @Test func tickedOneTimeActionStaysOnTheDayItWasTicked() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let life = try CategoryLibrary(context: container.mainContext).add(named: "生活")
        let action = try ActionLibrary(context: container.mainContext)
            .addOneTime(title: "买SIM卡", category: life, day: monday)
        let wednesday = Day(year: 2026, month: 9, day: 16)
        let friday = Day(year: 2026, month: 9, day: 18)
        try CompletionLibrary(context: container.mainContext).tick(action, on: wednesday, minutes: 30, note: nil)
        let plan = DayPlan(context: container.mainContext)

        #expect(try plan.actions(on: wednesday, today: friday).map(\.title) == ["买SIM卡"])
        #expect(try plan.actions(on: friday, today: friday).isEmpty)
        #expect(try plan.actions(on: monday, today: friday).isEmpty)
    }

    /// The 迟到 mark and the day rule have to agree: only an Action pulled onto today by a planned day
    /// that passed is late, and never on a day it doesn't appear on at all.
    @Test func onlyAnActionPulledOntoTodayIsMarkedLate() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let life = try CategoryLibrary(context: container.mainContext).add(named: "生活")
        let actions = ActionLibrary(context: container.mainContext)
        let tuesday = Day(year: 2026, month: 9, day: 15)
        let wednesday = Day(year: 2026, month: 9, day: 16)
        let late = try actions.addOneTime(title: "买SIM卡", category: life, day: monday)
        let planned = try actions.addOneTime(title: "洗衣服", category: life, day: wednesday)
        let ticked = try actions.addOneTime(title: "健身", category: life, day: monday)
        try CompletionLibrary(context: container.mainContext).tick(ticked, on: monday, minutes: 30, note: nil)

        #expect(DayPlan.isLate(late, on: wednesday, today: wednesday))
        #expect(!DayPlan.isLate(planned, on: wednesday, today: wednesday))
        #expect(!DayPlan.isLate(ticked, on: monday, today: wednesday))
        #expect(!DayPlan.isLate(late, on: tuesday, today: wednesday))
    }

    @Test func untickedOneTimeActionCanBeDeleted() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let life = try CategoryLibrary(context: container.mainContext).add(named: "生活")
        let actions = ActionLibrary(context: container.mainContext)
        let action = try actions.addOneTime(title: "买SIM卡", category: life, day: monday)

        try actions.delete(action)

        #expect(try DayPlan(context: container.mainContext).actions(on: monday, today: monday).isEmpty)
    }

    /// A ticked Action is history: it keeps its Completion, so deleting it is refused (ADR 0002).
    @Test func tickedOneTimeActionCantBeDeleted() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let life = try CategoryLibrary(context: container.mainContext).add(named: "生活")
        let actions = ActionLibrary(context: container.mainContext)
        let action = try actions.addOneTime(title: "买SIM卡", category: life, day: monday)
        try CompletionLibrary(context: container.mainContext).tick(action, on: monday, minutes: 30, note: nil)

        #expect(throws: ActionError.tickedAction) {
            try actions.delete(action)
        }
        let plan = try DayPlan(context: container.mainContext).actions(on: monday, today: monday)
        #expect(plan.map(\.title) == ["买SIM卡"])
    }

    @Test func timedActionsComeFirstEarliestFirstThenUntimedInTheOrderAdded() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let categories = CategoryLibrary(context: container.mainContext)
        let chinese = try categories.add(named: "中文")
        let life = try categories.add(named: "生活")
        let actions = ActionLibrary(context: container.mainContext)

        try actions.addOneTime(title: "洗衣服", category: life, day: monday)
        try actions.addOneTime(title: "健身", category: life, day: monday, time: TimeOfDay(hour: 18, minute: 30))
        try actions.addOneTime(title: "学20个新词", category: chinese, day: monday, time: TimeOfDay(hour: 7, minute: 0))
        try actions.addOneTime(title: "买SIM卡", category: life, day: monday)

        let titles = try DayPlan(context: container.mainContext).actions(on: monday, today: monday).map(\.title)
        #expect(titles == ["学20个新词", "健身", "洗衣服", "买SIM卡"])
    }
}
