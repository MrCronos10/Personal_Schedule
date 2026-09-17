import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// Days written before the app pinned its calendar carry the phone's own year, which in Thailand runs 543
/// ahead. They are moved once. See docs/adr/0003-days-are-stored-in-one-calendar.md.
@MainActor
struct DayMigrationTests {
    /// 2569-09-18 in the Thai Buddhist calendar is 2026-09-18.
    private let buddhistNumber = 25_690_918
    private let gregorianNumber = 20_260_918

    @Test func aDayWrittenWithThePhonesOwnEraIsMovedToTheOneWeStoreIn() throws {
        #expect(DayMigration.stored(buddhistNumber) == gregorianNumber)
    }

    @Test func aDayAlreadyStoredInTheRightCalendarIsLeftAlone() throws {
        #expect(DayMigration.stored(gregorianNumber) == gregorianNumber)
        #expect(DayMigration.stored(20_260_101) == 20_260_101)
        #expect(DayMigration.stored(0) == 0)
    }

    /// Only a Buddhist year is moved. A number from a calendar we haven't planned for is left as it is,
    /// because moving it by the wrong number of years would rewrite the day instead of keeping it.
    @Test func aDayFromSomeOtherCalendarIsLeftAlone() throws {
        #expect(DayMigration.stored(57_860_918) == 57_860_918)
        #expect(DayMigration.stored(14_470_918) == 14_470_918)
        #expect(DayMigration.stored(1_150_918) == 1_150_918)
    }

    @Test func everyStoredDayOnEveryRecordIsMoved() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let context = container.mainContext
        let chinese = try CategoryLibrary(context: context).add(named: "中文")

        let action = Action(title: "学20个新词", plannedDay: Day(number: buddhistNumber), time: nil, defaultMinutes: 20)
        action.startDayNumber = buddhistNumber
        context.insert(action)
        action.category = chinese

        let completion = Completion(
            titleWhenTicked: "学20个新词",
            day: Day(number: buddhistNumber),
            minutes: 20,
            note: nil
        )
        context.insert(completion)
        completion.action = action

        let pause = Pause(startDay: Day(number: buddhistNumber))
        pause.endDayNumber = 25_690_920
        context.insert(pause)
        pause.action = action
        try context.saveOrRollBack()

        let moved = try DayMigration(context: context).run()

        #expect(moved == 5)
        #expect(action.plannedDayNumber == gregorianNumber)
        #expect(action.startDayNumber == gregorianNumber)
        #expect(completion.dayNumber == gregorianNumber)
        #expect(pause.startDayNumber == gregorianNumber)
        #expect(pause.endDayNumber == 20_260_920)
    }

    /// It runs at every start, so running it again must do nothing at all.
    @Test func runningItAgainChangesNothing() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let context = container.mainContext
        let chinese = try CategoryLibrary(context: context).add(named: "中文")
        let action = Action(title: "学20个新词", plannedDay: Day(number: buddhistNumber), time: nil, defaultMinutes: nil)
        context.insert(action)
        action.category = chinese
        try context.saveOrRollBack()
        let migration = DayMigration(context: context)

        #expect(try migration.run() == 1)
        #expect(try migration.run() == 0)
        #expect(action.plannedDayNumber == gregorianNumber)
    }

    /// A store written since the calendar was pinned has nothing to move.
    @Test func aStoreWrittenAfterTheFixIsUntouched() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let context = container.mainContext
        let chinese = try CategoryLibrary(context: context).add(named: "中文")
        let actions = ActionLibrary(context: context)
        let routine = try actions.addRoutine(
            title: "学20个新词",
            category: chinese,
            repeatDays: .everyDay,
            startDay: Day(year: 2026, month: 9, day: 14)
        )
        try CompletionLibrary(context: context).tick(routine, on: Day(year: 2026, month: 9, day: 14), minutes: 20, note: nil)

        #expect(try DayMigration(context: context).run() == 0)
        #expect(routine.startDay == Day(year: 2026, month: 9, day: 14))
    }
}
