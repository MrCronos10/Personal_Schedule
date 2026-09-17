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

    /// 每天 matches every day, 工作日 only Monday to Friday, and chosen days only those days.
    ///
    /// A Day carries its own calendar, so 2026-09-14 is Monday here whatever the machine is set to.
    @Test func repeatDaysMatchEveryDayWeekdaysAndChosenDays() throws {
        let sunday = Day(year: 2026, month: 9, day: 13)
        let tuesday = Day(year: 2026, month: 9, day: 15)
        let thursday = Day(year: 2026, month: 9, day: 17)
        let saturday = Day(year: 2026, month: 9, day: 19)

        #expect(RepeatDays.everyDay.contains(monday))
        #expect(RepeatDays.everyDay.contains(sunday))
        #expect(RepeatDays.weekdays.contains(monday))
        #expect(!RepeatDays.weekdays.contains(sunday))
        #expect(!RepeatDays.weekdays.contains(saturday))

        let tuesdaysAndThursdays = RepeatDays([.tuesday, .thursday])
        #expect(tuesdaysAndThursdays.contains(tuesday))
        #expect(tuesdaysAndThursdays.contains(thursday))
        #expect(!tuesdaysAndThursdays.contains(monday))
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

    /// A Routine is repeat days *and* a start day. An Action with neither in place is not a Routine, so it
    /// can't become a row that appears on no day at all and still refuses to be deleted.
    @Test func anActionWithNoRepeatDaysLeftIsNotTreatedAsARoutine() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let action = Action(title: "空的", repeatDays: RepeatDays([]), startDay: monday, time: nil, defaultMinutes: nil)
        container.mainContext.insert(action)
        try container.mainContext.saveOrRollBack()

        #expect(action.repeatDays == nil)
        #expect(!action.isRoutine)
        // It falls back to a One-time Action, so its planned day has to be a real day, not day zero.
        #expect(action.plannedDay == monday)

        let plan = DayPlan(context: container.mainContext)
        let today = Day(year: 2026, month: 9, day: 21)
        #expect(try plannedTitles(plan, on: today, today: today) == ["空的"])

        // It isn't a Routine, so the 删除 rule for Routines doesn't trap it.
        try ActionLibrary(context: container.mainContext).delete(action)
        #expect(try plannedTitles(plan, on: today, today: today).isEmpty)
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

        #expect(try plan.actions(on: monday, today: monday).map(\.title) == ["学20个新词"])
        #expect(try plan.actions(on: tuesday, today: monday).map(\.title) == ["学20个新词"])
        #expect(try plan.actions(on: nextSunday, today: monday).map(\.title) == ["学20个新词"])
        #expect(try plan.actions(on: sunday, today: monday).isEmpty)

        let routine = try #require(try plan.actions(on: monday, today: monday).first)
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

    /// A repeat day that ended without a Completion is Missed on that day. Today is not over yet, so it is
    /// never Missed, and a day the Routine was never on can't be Missed either.
    @Test func untickedRoutineIsMissedOnAPastDayButNotTodayOrLater() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let categories = CategoryLibrary(context: container.mainContext)
        let chinese = try categories.add(named: "中文")
        let study = try categories.add(named: "学习")
        let actions = ActionLibrary(context: container.mainContext)
        let daily = try addRoutineCreatedOnItsStartDay(
            title: "学20个新词",
            category: chinese,
            repeatDays: .everyDay,
            startDay: monday,
            context: container.mainContext
        )
        let onWeekdays = try addRoutineCreatedOnItsStartDay(
            title: "上课",
            category: study,
            repeatDays: .weekdays,
            startDay: monday,
            context: container.mainContext
        )
        let oneTime = try actions.addOneTime(title: "买SIM卡", category: chinese, day: monday)
        let today = Day(year: 2026, month: 9, day: 21)

        #expect(DayPlan.isMissed(daily, on: monday, today: today))
        #expect(DayPlan.isMissed(daily, on: Day(year: 2026, month: 9, day: 20), today: today))
        #expect(!DayPlan.isMissed(daily, on: today, today: today))
        #expect(!DayPlan.isMissed(daily, on: Day(year: 2026, month: 9, day: 22), today: today))
        #expect(!DayPlan.isMissed(daily, on: Day(year: 2026, month: 9, day: 13), today: today))

        // Saturday is not one of 工作日, so it was never a day this Routine was on.
        #expect(DayPlan.isMissed(onWeekdays, on: Day(year: 2026, month: 9, day: 18), today: today))
        #expect(!DayPlan.isMissed(onWeekdays, on: Day(year: 2026, month: 9, day: 19), today: today))

        // A One-time Action is never Missed: it moves to today as 迟到 instead.
        #expect(!DayPlan.isMissed(oneTime, on: monday, today: today))
    }

    /// A Routine can't have missed a day it didn't exist for, even when its start day is earlier. Those days
    /// still show the Routine, so a day the student really did can be ticked in afterwards.
    @Test func daysBeforeARoutineWasCreatedAreNotMissed() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        let routine = try ActionLibrary(context: container.mainContext).addRoutine(
            title: "学20个新词",
            category: chinese,
            repeatDays: .everyDay,
            startDay: monday
        )
        let wednesday = Day(year: 2026, month: 9, day: 16)
        routine.createdAt = wednesday.date()
        try container.mainContext.saveOrRollBack()
        let today = Day(year: 2026, month: 9, day: 21)

        #expect(!DayPlan.isMissed(routine, on: monday, today: today))
        #expect(!DayPlan.isMissed(routine, on: Day(year: 2026, month: 9, day: 15), today: today))
        #expect(DayPlan.isMissed(routine, on: wednesday, today: today))
        #expect(DayPlan.isMissed(routine, on: Day(year: 2026, month: 9, day: 20), today: today))

        let plan = DayPlan(context: container.mainContext)
        #expect(try plannedTitles(plan, on: monday, today: today) == ["学20个新词"])
    }

    /// A past day can still be ticked, and that day is then no longer Missed. Other days keep their own state.
    @Test func tickingARoutineOnAPastDayRemovesMissedForThatDayOnly() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        let routine = try addRoutineCreatedOnItsStartDay(
            title: "学20个新词",
            category: chinese,
            repeatDays: .everyDay,
            startDay: monday,
            defaultMinutes: 20,
            context: container.mainContext
        )
        let completions = CompletionLibrary(context: container.mainContext)
        let tuesday = Day(year: 2026, month: 9, day: 15)
        let today = Day(year: 2026, month: 9, day: 21)
        #expect(DayPlan.isMissed(routine, on: monday, today: today))

        try completions.tick(routine, on: monday, minutes: 20, note: nil)

        #expect(!DayPlan.isMissed(routine, on: monday, today: today))
        #expect(try completions.completion(for: routine, on: monday)?.minutes == 20)
        #expect(DayPlan.isMissed(routine, on: tuesday, today: today))
    }

    /// Missing a day changes nothing about the other days: the Routine is on each repeat day once, no more.
    @Test func aMissedRoutineDayAddsNothingToLaterDays() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        try ActionLibrary(context: container.mainContext).addRoutine(
            title: "学20个新词",
            category: chinese,
            repeatDays: .everyDay,
            startDay: monday
        )
        let plan = DayPlan(context: container.mainContext)
        let today = Day(year: 2026, month: 9, day: 21)

        #expect(try plannedTitles(plan, on: monday, today: today) == ["学20个新词"])
        #expect(try plannedTitles(plan, on: Day(year: 2026, month: 9, day: 15), today: today) == ["学20个新词"])
        #expect(try plannedTitles(plan, on: today, today: today) == ["学20个新词"])
    }

    /// Editing an Action changes the days that aren't ticked. A day already ticked keeps the title and
    /// Category it copied when it was ticked (ADR 0002), so finished days never change under the student.
    @Test func editingARoutineLeavesTickedDaysWithTheirOwnCopy() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let categories = CategoryLibrary(context: container.mainContext)
        let chinese = try categories.add(named: "中文")
        let study = try categories.add(named: "学习")
        let routine = try addRoutineCreatedOnItsStartDay(
            title: "学20个新词",
            category: chinese,
            repeatDays: .everyDay,
            startDay: monday,
            defaultMinutes: 20,
            context: container.mainContext
        )
        let completions = CompletionLibrary(context: container.mainContext)
        try completions.tick(routine, on: monday, minutes: 20, note: nil)

        try ActionLibrary(context: container.mainContext).updateRoutine(
            routine,
            title: "学30个新词",
            category: study,
            repeatDays: .everyDay,
            startDay: monday,
            time: TimeOfDay(hour: 7, minute: 0),
            defaultMinutes: 30
        )

        let ticked = try #require(try completions.completion(for: routine, on: monday))
        #expect(ticked.titleWhenTicked == "学20个新词")
        #expect(ticked.category?.name == "中文")
        #expect(ticked.minutes == 20)

        #expect(routine.title == "学30个新词")
        #expect(routine.category?.name == "学习")
        #expect(routine.defaultMinutes == 30)
        #expect(routine.time == TimeOfDay(hour: 7, minute: 0))

        let plan = DayPlan(context: container.mainContext)
        let tuesday = Day(year: 2026, month: 9, day: 15)
        #expect(try plannedTitles(plan, on: tuesday, today: monday) == ["学30个新词"])
    }

    /// Editing a One-time Action that isn't ticked moves it to the day it now says, and off the old one.
    @Test func editingAOneTimeActionMovesItToItsNewDayWithItsNewDetails() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let categories = CategoryLibrary(context: container.mainContext)
        let life = try categories.add(named: "生活")
        let study = try categories.add(named: "学习")
        let actions = ActionLibrary(context: container.mainContext)
        let action = try actions.addOneTime(title: "买SIM卡", category: life, day: monday)
        let tuesday = Day(year: 2026, month: 9, day: 15)

        try actions.updateOneTime(
            action,
            title: "买电话卡",
            category: study,
            day: tuesday,
            time: TimeOfDay(hour: 9, minute: 30),
            defaultMinutes: 15
        )

        let plan = DayPlan(context: container.mainContext)
        #expect(try plannedTitles(plan, on: monday, today: monday).isEmpty)
        #expect(try plannedTitles(plan, on: tuesday, today: monday) == ["买电话卡"])
        #expect(action.category?.name == "学习")
        #expect(action.time == TimeOfDay(hour: 9, minute: 30))
        #expect(action.defaultMinutes == 15)
    }

    @Test(arguments: ["", "   "])
    func anEditWithABlankTitleIsRefusedAndTheActionKeepsWhatItHad(title: String) throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let life = try CategoryLibrary(context: container.mainContext).add(named: "生活")
        let actions = ActionLibrary(context: container.mainContext)
        let action = try actions.addOneTime(title: "买SIM卡", category: life, day: monday)

        #expect(throws: ActionError.emptyTitle) {
            try actions.updateOneTime(
                action,
                title: title,
                category: life,
                day: monday,
                time: nil,
                defaultMinutes: nil
            )
        }
        #expect(action.title == "买SIM卡")
    }

    @Test func anEditIntoAnArchivedCategoryIsRefusedAndTheActionKeepsItsCategory() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let categories = CategoryLibrary(context: container.mainContext)
        let life = try categories.add(named: "生活")
        let club = try categories.add(named: "篮球社")
        try categories.archive(club)
        let actions = ActionLibrary(context: container.mainContext)
        let action = try actions.addOneTime(title: "买SIM卡", category: life, day: monday)

        #expect(throws: ActionError.archivedCategory) {
            try actions.updateOneTime(
                action,
                title: "打篮球",
                category: club,
                day: monday,
                time: nil,
                defaultMinutes: nil
            )
        }
        #expect(action.title == "买SIM卡")
        #expect(action.category?.name == "生活")
    }

    /// Editing is the one way a Routine could lose every repeat day, which would leave it on no day at all.
    @Test func editingARoutineDownToNoRepeatDaysIsRefusedAndItKeepsItsDays() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        let actions = ActionLibrary(context: container.mainContext)
        let routine = try actions.addRoutine(
            title: "学20个新词",
            category: chinese,
            repeatDays: .everyDay,
            startDay: monday
        )

        #expect(throws: ActionError.noRepeatDays) {
            try actions.updateRoutine(
                routine,
                title: "学20个新词",
                category: chinese,
                repeatDays: RepeatDays([]),
                startDay: monday,
                time: nil,
                defaultMinutes: nil
            )
        }
        #expect(routine.repeatDays == .everyDay)
        #expect(routine.isRoutine)
    }

    /// A ticked day is where the Action was done, so moving its date afterwards doesn't move the record.
    @Test func aTickedOneTimeActionStaysOnItsTickDayWhenItsDateIsEdited() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let life = try CategoryLibrary(context: container.mainContext).add(named: "生活")
        let actions = ActionLibrary(context: container.mainContext)
        let action = try actions.addOneTime(title: "买SIM卡", category: life, day: monday)
        try CompletionLibrary(context: container.mainContext).tick(action, on: monday, minutes: 15, note: nil)
        let tuesday = Day(year: 2026, month: 9, day: 15)

        try actions.updateOneTime(
            action,
            title: "买SIM卡",
            category: life,
            day: tuesday,
            time: nil,
            defaultMinutes: nil
        )

        let plan = DayPlan(context: container.mainContext)
        #expect(try plannedTitles(plan, on: monday, today: monday) == ["买SIM卡"])
        #expect(try plannedTitles(plan, on: tuesday, today: monday).isEmpty)
    }

    /// A day that was ticked keeps showing what was ticked on it, even after the Routine stops repeating on
    /// that day. Otherwise its Completion stays in the database with no way to see it or undo it.
    @Test func daysAlreadyTickedStayVisibleAfterARoutineStopsRepeatingOnThem() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        let actions = ActionLibrary(context: container.mainContext)
        let routine = try addRoutineCreatedOnItsStartDay(
            title: "学20个新词",
            category: chinese,
            repeatDays: .everyDay,
            startDay: monday,
            context: container.mainContext
        )
        let completions = CompletionLibrary(context: container.mainContext)
        let tuesday = Day(year: 2026, month: 9, day: 15)
        let wednesday = Day(year: 2026, month: 9, day: 16)
        try completions.tick(routine, on: monday, minutes: 20, note: nil)
        try completions.tick(routine, on: tuesday, minutes: 20, note: nil)

        try actions.updateRoutine(
            routine,
            title: "学20个新词",
            category: chinese,
            repeatDays: RepeatDays([.wednesday]),
            startDay: wednesday,
            time: nil,
            defaultMinutes: nil
        )

        let plan = DayPlan(context: container.mainContext)
        let today = Day(year: 2026, month: 9, day: 21)
        #expect(try plannedTitles(plan, on: monday, today: today) == ["学20个新词"])
        #expect(try plannedTitles(plan, on: tuesday, today: today) == ["学20个新词"])
        #expect(try plannedTitles(plan, on: wednesday, today: today) == ["学20个新词"])
        // A day it never repeated on and was never ticked on stays empty.
        #expect(try plannedTitles(plan, on: Day(year: 2026, month: 9, day: 17), today: today).isEmpty)
        // The Completions are still reachable, so they can still be undone.
        #expect(try completions.completion(for: routine, on: monday)?.minutes == 20)
    }

    /// Nothing is deleted in this app, so an Action outlives its Category's active life. Changing such an
    /// Action must not force the student to move it out of the Category it belongs to.
    @Test func anActionCanKeepACategoryThatHasSinceBeenArchived() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let categories = CategoryLibrary(context: container.mainContext)
        let club = try categories.add(named: "篮球社")
        let actions = ActionLibrary(context: container.mainContext)
        let action = try actions.addOneTime(title: "打篮球", category: club, day: monday)
        try categories.archive(club)

        try actions.updateOneTime(
            action,
            title: "打篮球",
            category: club,
            day: monday,
            time: TimeOfDay(hour: 18, minute: 0),
            defaultMinutes: 60
        )

        #expect(action.time == TimeOfDay(hour: 18, minute: 0))
        #expect(action.defaultMinutes == 60)
        #expect(action.category?.name == "篮球社")

        // Moving it into a different archived Category is still refused.
        let old = try categories.add(named: "旧的")
        try categories.archive(old)
        #expect(throws: ActionError.archivedCategory) {
            try actions.updateOneTime(
                action,
                title: "打篮球",
                category: old,
                day: monday,
                time: nil,
                defaultMinutes: nil
            )
        }
        #expect(action.category?.name == "篮球社")
    }

    /// A paused Routine stops appearing from the day it was paused. The days before it are untouched.
    @Test func aPausedRoutineStopsAppearingFromTheDayItWasPaused() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        let actions = ActionLibrary(context: container.mainContext)
        let routine = try addRoutineCreatedOnItsStartDay(
            title: "学20个新词",
            category: chinese,
            repeatDays: .everyDay,
            startDay: monday,
            context: container.mainContext
        )
        let tuesday = Day(year: 2026, month: 9, day: 15)
        let wednesday = Day(year: 2026, month: 9, day: 16)

        try actions.pause(routine, from: wednesday)

        let plan = DayPlan(context: container.mainContext)
        #expect(try plannedTitles(plan, on: monday, today: wednesday) == ["学20个新词"])
        #expect(try plannedTitles(plan, on: tuesday, today: wednesday) == ["学20个新词"])
        #expect(try plannedTitles(plan, on: wednesday, today: wednesday).isEmpty)
        #expect(try plannedTitles(plan, on: Day(year: 2026, month: 9, day: 17), today: wednesday).isEmpty)
        #expect(routine.isPaused)
    }

    /// Resuming brings the Routine back from the day it was resumed. The days it was stopped for stay empty.
    @Test func aResumedRoutineComesBackFromTheDayItWasResumed() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        let actions = ActionLibrary(context: container.mainContext)
        let routine = try addRoutineCreatedOnItsStartDay(
            title: "学20个新词",
            category: chinese,
            repeatDays: .everyDay,
            startDay: monday,
            context: container.mainContext
        )
        let tuesday = Day(year: 2026, month: 9, day: 15)
        let wednesday = Day(year: 2026, month: 9, day: 16)
        let thursday = Day(year: 2026, month: 9, day: 17)
        let friday = Day(year: 2026, month: 9, day: 18)

        try actions.pause(routine, from: wednesday)
        try actions.resume(routine, on: friday)

        let plan = DayPlan(context: container.mainContext)
        #expect(try plannedTitles(plan, on: tuesday, today: friday) == ["学20个新词"])
        #expect(try plannedTitles(plan, on: wednesday, today: friday).isEmpty)
        #expect(try plannedTitles(plan, on: thursday, today: friday).isEmpty)
        #expect(try plannedTitles(plan, on: friday, today: friday) == ["学20个新词"])
        #expect(!routine.isPaused)
    }

    /// Each pause is remembered on its own, so stopping and starting again as often as the student likes
    /// leaves every stretch of days where it was.
    @Test func aRoutineCanBePausedAndResumedMoreThanOnce() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        let actions = ActionLibrary(context: container.mainContext)
        let routine = try addRoutineCreatedOnItsStartDay(
            title: "学20个新词",
            category: chinese,
            repeatDays: .everyDay,
            startDay: monday,
            context: container.mainContext
        )
        let today = Day(year: 2026, month: 9, day: 25)

        try actions.pause(routine, from: Day(year: 2026, month: 9, day: 16))
        try actions.resume(routine, on: Day(year: 2026, month: 9, day: 18))
        try actions.pause(routine, from: Day(year: 2026, month: 9, day: 21))
        try actions.resume(routine, on: Day(year: 2026, month: 9, day: 23))

        let plan = DayPlan(context: container.mainContext)
        #expect(try plannedTitles(plan, on: Day(year: 2026, month: 9, day: 15), today: today) == ["学20个新词"])
        #expect(try plannedTitles(plan, on: Day(year: 2026, month: 9, day: 16), today: today).isEmpty)
        #expect(try plannedTitles(plan, on: Day(year: 2026, month: 9, day: 17), today: today).isEmpty)
        #expect(try plannedTitles(plan, on: Day(year: 2026, month: 9, day: 18), today: today) == ["学20个新词"])
        #expect(try plannedTitles(plan, on: Day(year: 2026, month: 9, day: 20), today: today) == ["学20个新词"])
        #expect(try plannedTitles(plan, on: Day(year: 2026, month: 9, day: 21), today: today).isEmpty)
        #expect(try plannedTitles(plan, on: Day(year: 2026, month: 9, day: 22), today: today).isEmpty)
        #expect(try plannedTitles(plan, on: Day(year: 2026, month: 9, day: 23), today: today) == ["学20个新词"])
        #expect((routine.pauses ?? []).count == 2)
        #expect(!routine.isPaused)
    }

    /// Only a Routine is paused; a One-time Action is deleted instead. The guard went in with `pause`, so
    /// this test came after it rather than driving it.
    @Test func aOneTimeActionCantBePaused() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let life = try CategoryLibrary(context: container.mainContext).add(named: "生活")
        let actions = ActionLibrary(context: container.mainContext)
        let action = try actions.addOneTime(title: "买SIM卡", category: life, day: monday)

        #expect(throws: ActionError.notARoutine) {
            try actions.pause(action, from: monday)
        }
        #expect(!action.isPaused)
        let plan = DayPlan(context: container.mainContext)
        #expect(try plannedTitles(plan, on: monday, today: monday) == ["买SIM卡"])
    }

    /// Days inside a pause are never Missed, and stay that way once the Routine is going again. The days on
    /// either side keep their own state.
    @Test func daysInsideAPauseAreNeverMissedEvenAfterResuming() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        let actions = ActionLibrary(context: container.mainContext)
        let routine = try addRoutineCreatedOnItsStartDay(
            title: "学20个新词",
            category: chinese,
            repeatDays: .everyDay,
            startDay: monday,
            context: container.mainContext
        )
        let wednesday = Day(year: 2026, month: 9, day: 16)
        let thursday = Day(year: 2026, month: 9, day: 17)
        let friday = Day(year: 2026, month: 9, day: 18)
        let today = Day(year: 2026, month: 9, day: 21)

        try actions.pause(routine, from: wednesday)
        try actions.resume(routine, on: friday)

        #expect(DayPlan.isMissed(routine, on: monday, today: today))
        #expect(!DayPlan.isMissed(routine, on: wednesday, today: today))
        #expect(!DayPlan.isMissed(routine, on: thursday, today: today))
        #expect(DayPlan.isMissed(routine, on: friday, today: today))
    }

    /// An Action keeps its kind. Only the form was stopping an edit from turning a One-time Action into a
    /// Routine, which would also have left it undeletable.
    @Test func editingCantChangeWhetherAnActionIsARoutine() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let categories = CategoryLibrary(context: container.mainContext)
        let life = try categories.add(named: "生活")
        let chinese = try categories.add(named: "中文")
        let actions = ActionLibrary(context: container.mainContext)
        let oneTime = try actions.addOneTime(title: "买SIM卡", category: life, day: monday)
        let routine = try actions.addRoutine(
            title: "学20个新词",
            category: chinese,
            repeatDays: .everyDay,
            startDay: monday
        )

        #expect(throws: ActionError.notARoutine) {
            try actions.updateRoutine(
                oneTime,
                title: "买SIM卡",
                category: life,
                repeatDays: .everyDay,
                startDay: monday,
                time: nil,
                defaultMinutes: nil
            )
        }
        #expect(!oneTime.isRoutine)

        #expect(throws: ActionError.notAOneTimeAction) {
            try actions.updateOneTime(
                routine,
                title: "学20个新词",
                category: chinese,
                day: monday,
                time: nil,
                defaultMinutes: nil
            )
        }
        #expect(routine.isRoutine)
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
        try plan.actions(on: day, today: today).map(\.title)
    }

    /// A Routine the student created on the day it starts, so every repeat day since could be Missed.
    private func addRoutineCreatedOnItsStartDay(
        title: String,
        category: PersonalSchedule.Category,
        repeatDays: RepeatDays,
        startDay: Day,
        defaultMinutes: Int? = nil,
        context: ModelContext
    ) throws -> Action {
        let routine = try ActionLibrary(context: context).addRoutine(
            title: title,
            category: category,
            repeatDays: repeatDays,
            startDay: startDay,
            defaultMinutes: defaultMinutes
        )
        routine.createdAt = startDay.date()
        try context.saveOrRollBack()
        return routine
    }
}
