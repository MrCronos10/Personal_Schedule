import Foundation
import SwiftData

/// Works out which Actions appear on a day, and in what order. See "How a day is worked out" in docs/plan-v1.md.
@MainActor
struct DayPlan {
    let context: ModelContext

    /// Every Action, so that one rule decides what a day shows.
    ///
    /// The day rule puts Actions on days their stored day numbers never mention: a late Action on today, a
    /// Routine on each of its repeat days, a ticked Action on the day it was ticked even after its date was
    /// changed. Narrowing this by day would be a second rule that has to agree with the first, and it didn't:
    /// a ticked Action moved to a later day dropped off the day it was ticked. Screens use this with `@Query`,
    /// then `plan(_:on:today:calendar:)`, so they match `actions(on:today:calendar:)`.
    nonisolated static var descriptor: FetchDescriptor<Action> {
        FetchDescriptor<Action>()
    }

    /// Whether an Action belongs on a day.
    ///
    /// A day that was ticked always shows what was ticked on it, whatever the Action says now. That holds for
    /// every kind: a Routine edited to stop repeating on a day it was already ticked on still shows there, so
    /// its Completion can still be seen and undone.
    ///
    /// Otherwise a Routine is on every one of its repeat days from its start day onwards; a ticked One-time
    /// Action belongs to its tick day and no other; and an unticked one waits on its planned day while that
    /// day is still ahead, moving to today once the day has passed.
    static func appears(_ action: Action, on day: Day, today: Day, calendar: Calendar = .current) -> Bool {
        let completions = action.completions ?? []
        if completions.contains(where: { $0.dayNumber == day.number }) {
            return true
        }
        if let repeatDays = action.repeatDays, let startDay = action.startDay {
            return day >= startDay && repeatDays.contains(day, calendar: calendar)
        }
        if !completions.isEmpty {
            return false
        }
        if action.plannedDay > today {
            return action.plannedDay == day
        }
        return day == today
    }

    /// A One-time Action that is on this day only because its planned day passed without a tick. It agrees
    /// with `appears(_:on:today:calendar:)`, so a day the Action isn't on at all is never late. A Routine is
    /// never late: a repeat day it missed is Missed on that day, which ticket 08 builds.
    static func isLate(_ action: Action, on day: Day, today: Day, calendar: Calendar = .current) -> Bool {
        guard !action.isRoutine, appears(action, on: day, today: today, calendar: calendar) else { return false }
        return (action.completions ?? []).isEmpty && action.plannedDay < day
    }

    /// A Routine's repeat day that ended without a Completion. It stays Missed on its own day and never
    /// moves forward. Today is not over yet, so today is never Missed, and a day the Routine was never on
    /// can't be Missed. A One-time Action is never Missed: it moves to today as 迟到 instead.
    ///
    /// A Routine can't have missed a day it didn't exist for, so days before it was created are never
    /// Missed however far back its start day reaches. Those days still show the Routine, so a day the
    /// student really did can be ticked in afterwards.
    ///
    /// Ticket 10 adds the last part of this rule: days inside a Pause are never Missed.
    static func isMissed(_ action: Action, on day: Day, today: Day, calendar: Calendar = .current) -> Bool {
        guard action.isRoutine, day < today else { return false }
        guard day >= Day(action.createdAt, calendar: calendar) else { return false }
        guard appears(action, on: day, today: today, calendar: calendar) else { return false }
        return !(action.completions ?? []).contains { $0.dayNumber == day.number }
    }

    /// Actions with a time first, earliest first; then Actions without a time, in the order they were added.
    static func ordered(_ actions: [Action]) -> [Action] {
        actions.sorted { first, second in
            switch (first.timeMinutes, second.timeMinutes) {
            case let (firstTime?, secondTime?) where firstTime != secondTime:
                return firstTime < secondTime
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            default:
                return first.createdAt < second.createdAt
            }
        }
    }

    /// The day's Actions, in the order they belong on screen, out of the Actions already fetched with
    /// `descriptor`. Screens use this with `@Query`, so there is one copy of the rule.
    static func plan(_ candidates: [Action], on day: Day, today: Day, calendar: Calendar = .current) -> [Action] {
        ordered(candidates.filter { appears($0, on: day, today: today, calendar: calendar) })
    }

    func actions(on day: Day, today: Day, calendar: Calendar = .current) throws -> [Action] {
        Self.plan(try context.fetch(Self.descriptor), on: day, today: today, calendar: calendar)
    }
}
