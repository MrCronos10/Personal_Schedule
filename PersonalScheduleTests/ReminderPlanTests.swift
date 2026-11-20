import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// Which reminders should exist for today and the six days after it. See
/// `.scratch/action-reminders/spec.md`: a reminder fires at an Action's own time, only on the days the
/// day rule puts it on, and not on a day it is already ticked.
@MainActor
struct ReminderPlanTests {
    /// 2026-09-14 is a Monday, so the 7 days run Monday to Sunday.
    private let monday = Day(year: 2026, month: 9, day: 14)
    private let nine = 9 * 60

    @MainActor private struct Store {
        /// Held so the in-memory store outlives the test; letting it go resets the context.
        let container: ModelContainer
        let category: PersonalSchedule.Category
        var context: ModelContext { container.mainContext }
        var actions: ActionLibrary { ActionLibrary(context: context) }
    }

    private func store() throws -> Store {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let category = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        return Store(container: container, category: category)
    }

    private func all(_ store: Store) throws -> [Action] {
        try store.context.fetch(DayPlan.descriptor)
    }

    /// Each reminder as "day@hh:mm title", so a test reads as the list it expects.
    private func described(_ reminders: [Reminder]) -> [String] {
        reminders.map { "\($0.day.number)@\($0.time.hour):\($0.time.minute) \($0.action.title)" }
    }

    @Test func aRoutineWithItsSwitchOnRemindsOnEachRepeatDay() throws {
        let store = try store()
        let routine = try store.actions.addRoutine(
            title: "读一篇文章",
            category: store.category,
            repeatDays: RepeatDays([.monday, .wednesday, .friday]),
            startDay: monday,
            time: TimeOfDay(hour: 21, minute: 0)
        )
        try store.actions.setReminder(routine, on: true)

        let reminders = ReminderPlan.reminders(try all(store), today: monday, nowMinutes: nine)
        #expect(described(reminders) == [
            "20260914@21:0 读一篇文章",
            "20260916@21:0 读一篇文章",
            "20260918@21:0 读一篇文章",
        ])
    }

    /// A routine every day at 21:00 with its switch on: the fixture most rules below start from.
    private func everyDayAtNine(in store: Store, title: String = "读一篇文章") throws -> Action {
        let routine = try store.actions.addRoutine(
            title: title,
            category: store.category,
            repeatDays: .everyDay,
            startDay: monday,
            time: TimeOfDay(hour: 21, minute: 0)
        )
        try store.actions.setReminder(routine, on: true)
        return routine
    }

    @Test func aTickedDayGetsNoReminderAndUntickingBringsItBack() throws {
        let store = try store()
        let routine = try everyDayAtNine(in: store)
        let completions = CompletionLibrary(context: store.context)
        #expect(ReminderPlan.reminders(try all(store), today: monday, nowMinutes: nine).count == 7)

        try completions.tick(routine, on: monday, minutes: nil, note: nil)
        let ticked = ReminderPlan.reminders(try all(store), today: monday, nowMinutes: nine)
        #expect(ticked.count == 6)
        #expect(!ticked.contains { $0.day == monday })

        try completions.untick(routine, on: monday)
        let unticked = ReminderPlan.reminders(try all(store), today: monday, nowMinutes: nine)
        #expect(unticked.contains { $0.day == monday })
    }

    /// Planned for last Friday and never ticked, it is on today's list and will move to each day after
    /// it until ticked — so it reminds on every one of the 7 days, not only today.
    @Test func aLateOneTimeActionRemindsOnEachDayItCarriesOverTo() throws {
        let store = try store()
        let late = try store.actions.addOneTime(
            title: "交作业",
            category: store.category,
            day: monday.adding(days: -3),
            time: TimeOfDay(hour: 15, minute: 0)
        )
        try store.actions.setReminder(late, on: true)
        #expect(DayPlan.isLate(late, on: monday, today: monday))

        let days = ReminderPlan.reminders(try all(store), today: monday, nowMinutes: nine).map(\.day)
        #expect(days == (0..<7).map { monday.adding(days: $0) })
    }

    /// Planned for Wednesday: nothing before it, then Wednesday and each day after while unticked.
    @Test func aOneTimeActionAheadRemindsFromItsPlannedDay() throws {
        let store = try store()
        let wednesday = monday.adding(days: 2)
        let ahead = try store.actions.addOneTime(
            title: "交作业",
            category: store.category,
            day: wednesday,
            time: TimeOfDay(hour: 15, minute: 0)
        )
        try store.actions.setReminder(ahead, on: true)

        let days = ReminderPlan.reminders(try all(store), today: monday, nowMinutes: nine).map(\.day)
        #expect(days == (2..<7).map { monday.adding(days: $0) })
    }

    /// At 21:00 exactly the moment has come, so today's reminder is gone; tomorrow's still stands.
    @Test func todaysReminderWhoseTimeHasPassedIsNotGiven() throws {
        let store = try store()
        _ = try everyDayAtNine(in: store)
        #expect(ReminderPlan.reminders(try all(store), today: monday, nowMinutes: 21 * 60 - 1).count == 7)

        let days = ReminderPlan.reminders(try all(store), today: monday, nowMinutes: 21 * 60).map(\.day)
        #expect(days == (1..<7).map { monday.adding(days: $0) })
    }

    /// iOS holds at most 64. Ten every-day Routines at 08:00…17:00 make 70; the 6 dropped are the
    /// latest of the last day, so Sunday keeps only its four earliest.
    @Test func moreThanSixtyFourKeepsTheNearest() throws {
        let store = try store()
        for hour in 8...17 {
            let routine = try store.actions.addRoutine(
                title: "r\(hour)",
                category: store.category,
                repeatDays: .everyDay,
                startDay: monday,
                time: TimeOfDay(hour: hour, minute: 0)
            )
            try store.actions.setReminder(routine, on: true)
        }
        #expect(try all(store).count == 10)

        let reminders = ReminderPlan.reminders(try all(store), today: monday, nowMinutes: 0)
        #expect(reminders.count == 64)
        let sunday = monday.adding(days: 6)
        #expect(reminders.filter { $0.day == sunday }.map(\.action.title) == ["r8", "r9", "r10", "r11"])
    }

    // MARK: - The switch needs a time

    /// No time, no switch (spec decision 1): it can't be turned on for an Action without one.
    @Test func theSwitchCannotBeOnWithoutATime() throws {
        let store = try store()
        let untimed = try store.actions.addRoutine(
            title: "背单词",
            category: store.category,
            repeatDays: .everyDay,
            startDay: monday
        )
        try store.actions.setReminder(untimed, on: true)
        #expect(untimed.remindsAtTime == false)
    }

    /// Taking the time away turns the switch off, so it can't come back on unseen when a time is added.
    @Test func removingTheTimeTurnsTheSwitchOff() throws {
        let store = try store()
        let routine = try everyDayAtNine(in: store)
        #expect(routine.remindsAtTime == true)

        try store.actions.updateRoutine(
            routine,
            title: routine.title,
            category: store.category,
            repeatDays: .everyDay,
            startDay: monday,
            time: nil,
            defaultMinutes: nil
        )
        #expect(routine.remindsAtTime == false)
    }

    // MARK: - Guards: these held from the start, and are kept so they go on holding

    /// Off by default for a new Action, so updating the app or adding one never asks for anything.
    @Test func theSwitchStartsOff() throws {
        let store = try store()
        let routine = try store.actions.addRoutine(
            title: "读一篇文章",
            category: store.category,
            repeatDays: .everyDay,
            startDay: monday,
            time: TimeOfDay(hour: 21, minute: 0)
        )
        #expect(routine.remindsAtTime == false)
        #expect(ReminderPlan.reminders(try all(store), today: monday, nowMinutes: nine).isEmpty)
    }

    @Test func switchedOffOrWithNoTimeGivesNone() throws {
        let store = try store()
        let routine = try everyDayAtNine(in: store)
        try store.actions.setReminder(routine, on: false)
        let untimed = try store.actions.addRoutine(
            title: "背单词",
            category: store.category,
            repeatDays: .everyDay,
            startDay: monday
        )
        try store.actions.setReminder(untimed, on: true)
        #expect(try all(store).count == 2)

        #expect(ReminderPlan.reminders(try all(store), today: monday, nowMinutes: nine).isEmpty)
    }

    /// Starting Thursday: nothing on Monday to Wednesday.
    @Test func nothingBeforeARoutinesStartDay() throws {
        let store = try store()
        let thursday = monday.adding(days: 3)
        let routine = try store.actions.addRoutine(
            title: "读一篇文章",
            category: store.category,
            repeatDays: .everyDay,
            startDay: thursday,
            time: TimeOfDay(hour: 21, minute: 0)
        )
        try store.actions.setReminder(routine, on: true)

        let days = ReminderPlan.reminders(try all(store), today: monday, nowMinutes: nine).map(\.day)
        #expect(days == (3..<7).map { monday.adding(days: $0) })
    }

    /// Paused from Wednesday: Monday and Tuesday only.
    @Test func aPausedStretchGivesNone() throws {
        let store = try store()
        let routine = try everyDayAtNine(in: store)
        try store.actions.pause(routine, from: monday.adding(days: 2))

        let days = ReminderPlan.reminders(try all(store), today: monday, nowMinutes: nine).map(\.day)
        #expect(days == [monday, monday.adding(days: 1)])
    }
}
