import Foundation
import SwiftData

/// Works out which Actions appear on a day, and in what order. See "How a day is worked out" in docs/plan-v1.md.
@MainActor
struct DayPlan {
    let context: ModelContext

    /// Every Action that could appear on a day: the ones planned for it, and the late ones planned earlier.
    /// A late Action's planned day has passed, so the query can't pick the day on its own; `appears(_:on:today:)`
    /// decides. Screens use this with `@Query`, then `plan(_:on:today:)`, so they match `actions(on:today:)`.
    nonisolated static func descriptor(for day: Day, today: Day) -> FetchDescriptor<Action> {
        let latest = max(day.number, today.number)
        return FetchDescriptor<Action>(predicate: #Predicate { $0.plannedDayNumber <= latest })
    }

    /// Whether a One-time Action belongs on a day: a ticked one stays on the day it was ticked; an unticked one
    /// waits on its planned day while that day is still ahead, and moves to today once the day has passed.
    static func appears(_ action: Action, on day: Day, today: Day) -> Bool {
        let completions = action.completions ?? []
        if !completions.isEmpty {
            return completions.contains { $0.dayNumber == day.number }
        }
        if action.plannedDay > today {
            return action.plannedDay == day
        }
        return day == today
    }

    /// An Action that is on this day only because its planned day passed without a tick. It agrees with
    /// `appears(_:on:today:)`, so a day the Action isn't on at all is never late.
    static func isLate(_ action: Action, on day: Day, today: Day) -> Bool {
        guard appears(action, on: day, today: today) else { return false }
        return (action.completions ?? []).isEmpty && action.plannedDay < day
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

    /// The day's Actions, in the order they belong on screen, out of Actions already fetched with
    /// `descriptor(for:today:)`. Screens use this with `@Query`, so there is one copy of the rule.
    static func plan(_ candidates: [Action], on day: Day, today: Day) -> [Action] {
        ordered(candidates.filter { appears($0, on: day, today: today) })
    }

    func actions(on day: Day, today: Day) throws -> [Action] {
        Self.plan(try context.fetch(Self.descriptor(for: day, today: today)), on: day, today: today)
    }
}
