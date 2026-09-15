import Foundation
import SwiftData

/// Works out which Actions appear on a day, and in what order. See "How a day is worked out" in docs/plan-v1.md.
@MainActor
struct DayPlan {
    let context: ModelContext

    /// The Actions planned for a day. Screens use this with `@Query`, then `ordered(_:)`, so they match `actions(on:)`.
    nonisolated static func descriptor(for day: Day) -> FetchDescriptor<Action> {
        let number = day.number
        return FetchDescriptor<Action>(predicate: #Predicate { $0.plannedDayNumber == number })
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

    func actions(on day: Day) throws -> [Action] {
        Self.ordered(try context.fetch(Self.descriptor(for: day)))
    }
}
