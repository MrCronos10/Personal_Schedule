import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

@MainActor
struct DayPlanTests {
    private let monday = Day(year: 2026, month: 9, day: 14)
    /// Weekday rules are tested in the Gregorian calendar, so "Monday" means Monday on any Mac.
    private let gregorian = Calendar(identifier: .gregorian)

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

    /// 每天 matches every day, 工作日 only Monday to Friday, and chosen days only those days.
    ///
    /// The days are read in the Gregorian calendar, because this Mac's calendar is the Thai Buddhist one,
    /// where year 2026 is 1483 in the Gregorian calendar and falls on other weekdays.
    @Test func repeatDaysMatchEveryDayWeekdaysAndChosenDays() throws {
        let sunday = Day(year: 2026, month: 9, day: 13)
        let tuesday = Day(year: 2026, month: 9, day: 15)
        let thursday = Day(year: 2026, month: 9, day: 17)
        let saturday = Day(year: 2026, month: 9, day: 19)

        #expect(RepeatDays.everyDay.contains(monday, calendar: gregorian))
        #expect(RepeatDays.everyDay.contains(sunday, calendar: gregorian))
        #expect(RepeatDays.weekdays.contains(monday, calendar: gregorian))
        #expect(!RepeatDays.weekdays.contains(sunday, calendar: gregorian))
        #expect(!RepeatDays.weekdays.contains(saturday, calendar: gregorian))

        let tuesdaysAndThursdays = RepeatDays([.tuesday, .thursday])
        #expect(tuesdaysAndThursdays.contains(tuesday, calendar: gregorian))
        #expect(tuesdaysAndThursdays.contains(thursday, calendar: gregorian))
        #expect(!tuesdaysAndThursdays.contains(monday, calendar: gregorian))
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

    /// Routines are paused, never deleted (CONTEXT.md), so the library refuses to delete one even on a day
    /// it hasn't been ticked. Pausing is ticket 10.
    @Test func routineCantBeDeleted() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        let actions = ActionLibrary(context: container.mainContext)
        let routine = try actions.addRoutine(
            title: "学20个新词",
            category: chinese,
            repeatDays: .everyDay,
            startDay: monday
        )

        #expect(throws: ActionError.routineCantBeDeleted) {
            try actions.delete(routine)
        }
        let plan = DayPlan(context: container.mainContext)
        #expect(try plannedTitles(plan, on: monday, today: monday) == ["学20个新词"])
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

    /// A 每天 Routine is on every day from its start day onwards, and on no day before it.
    @Test func routineAppearsEveryDayFromItsStartDayAndNotBefore() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        try ActionLibrary(context: container.mainContext).addRoutine(
            title: "学20个新词",
            category: chinese,
            repeatDays: .everyDay,
            startDay: monday,
            time: TimeOfDay(hour: 7, minute: 0),
            defaultMinutes: 20
        )
        let plan = DayPlan(context: container.mainContext)
        let sunday = Day(year: 2026, month: 9, day: 13)
        let tuesday = Day(year: 2026, month: 9, day: 15)
        let nextSunday = Day(year: 2026, month: 9, day: 20)

        #expect(try plan.actions(on: monday, today: monday, calendar: gregorian).map(\.title) == ["学20个新词"])
        #expect(try plan.actions(on: tuesday, today: monday, calendar: gregorian).map(\.title) == ["学20个新词"])
        #expect(try plan.actions(on: nextSunday, today: monday, calendar: gregorian).map(\.title) == ["学20个新词"])
        #expect(try plan.actions(on: sunday, today: monday, calendar: gregorian).isEmpty)

        let routine = try #require(try plan.actions(on: monday, today: monday, calendar: gregorian).first)
        #expect(routine.category?.name == "中文")
        #expect(routine.time == TimeOfDay(hour: 7, minute: 0))
        #expect(routine.defaultMinutes == 20)
        #expect(routine.repeatDays == .everyDay)
        #expect(routine.startDay == monday)
    }

    /// 工作日 is Monday to Friday only, and chosen days repeat on just those weekdays.
    @Test func weekdayRoutineSkipsTheWeekendAndAChosenDaysRoutineOnlyRepeatsOnThoseDays() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let categories = CategoryLibrary(context: container.mainContext)
        let study = try categories.add(named: "学习")
        let health = try categories.add(named: "健康")
        let actions = ActionLibrary(context: container.mainContext)
        try actions.addRoutine(title: "上课", category: study, repeatDays: .weekdays, startDay: monday)
        try actions.addRoutine(
            title: "健身",
            category: health,
            repeatDays: RepeatDays([.tuesday, .thursday]),
            startDay: monday
        )
        let plan = DayPlan(context: container.mainContext)

        #expect(try plannedTitles(plan, on: monday, today: monday) == ["上课"])
        #expect(try plannedTitles(plan, on: Day(year: 2026, month: 9, day: 15), today: monday) == ["上课", "健身"])
        #expect(try plannedTitles(plan, on: Day(year: 2026, month: 9, day: 16), today: monday) == ["上课"])
        #expect(try plannedTitles(plan, on: Day(year: 2026, month: 9, day: 17), today: monday) == ["上课", "健身"])
        #expect(try plannedTitles(plan, on: Day(year: 2026, month: 9, day: 19), today: monday).isEmpty)
        #expect(try plannedTitles(plan, on: Day(year: 2026, month: 9, day: 20), today: monday).isEmpty)
    }

    /// Each day a Routine appears is ticked separately, with its own Completion.
    @Test func tickingARoutineOnOneDayLeavesItsOtherDaysUnticked() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        let routine = try ActionLibrary(context: container.mainContext).addRoutine(
            title: "学20个新词",
            category: chinese,
            repeatDays: .everyDay,
            startDay: monday,
            defaultMinutes: 20
        )
        let completions = CompletionLibrary(context: container.mainContext)
        let tuesday = Day(year: 2026, month: 9, day: 15)

        try completions.tick(routine, on: monday, minutes: 20, note: nil)

        #expect(try completions.completion(for: routine, on: monday)?.minutes == 20)
        #expect(try completions.completion(for: routine, on: tuesday) == nil)
        let plan = DayPlan(context: container.mainContext)
        #expect(try plannedTitles(plan, on: tuesday, today: monday) == ["学20个新词"])
    }

    @Test func routineWithNoRepeatDaysIsRefusedAndNothingIsSaved() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let health = try CategoryLibrary(context: container.mainContext).add(named: "健康")
        let actions = ActionLibrary(context: container.mainContext)

        #expect(throws: ActionError.noRepeatDays) {
            try actions.addRoutine(title: "健身", category: health, repeatDays: RepeatDays([]), startDay: monday)
        }
        let plan = DayPlan(context: container.mainContext)
        #expect(try plannedTitles(plan, on: monday, today: monday).isEmpty)
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

    /// The day's Actions by title, read in the Gregorian calendar so weekdays mean what they say.
    private func plannedTitles(_ plan: DayPlan, on day: Day, today: Day) throws -> [String] {
        try plan.actions(on: day, today: today, calendar: gregorian).map(\.title)
    }
}
