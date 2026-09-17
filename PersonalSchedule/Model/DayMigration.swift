import Foundation
import SwiftData

/// Moves days that were stored with the phone's own calendar into the one the app stores in.
///
/// Before the app pinned its calendar, a day was numbered with whatever calendar the phone used. In
/// Thailand that is the Buddhist calendar, whose year runs 543 ahead, so today was written as 25690918
/// rather than 20260918. See docs/adr/0003-days-are-stored-in-one-calendar.md.
///
/// It is safe to run at every start: the two eras are far apart, so a day already stored in the right
/// calendar is left alone and there is nothing to move the second time.
@MainActor
struct DayMigration {
    let context: ModelContext

    /// The Thai Buddhist calendar runs this many years ahead of the one the app stores in.
    private static let buddhistYearsAhead = 543

    /// The years a day written with the phone's Buddhist calendar could plausibly carry. Only these are
    /// moved, so a number from some other calendar is left exactly as it is rather than guessed at: the
    /// Hebrew calendar's year 5786, for example, is not a Buddhist year and is none of our business.
    private static let buddhistYears = 2500...2700

    /// A stored day number, in the calendar the app stores in.
    static func stored(_ number: Int) -> Int {
        guard buddhistYears.contains(number / 10_000) else { return number }
        return number - buddhistYearsAhead * 10_000
    }

    /// Moves every stored day that needs it, and says how many were moved.
    ///
    /// Everything is read before anything is changed, so a failure can't leave half the days moved: a
    /// half-moved store would hide days that were ticked and, worse, look finished to the next start.
    @discardableResult
    func run() throws -> Int {
        let actions = try context.fetch(FetchDescriptor<Action>())
        let completions = try context.fetch(FetchDescriptor<Completion>())
        let pauses = try context.fetch(FetchDescriptor<Pause>())

        var moved = 0
        for action in actions {
            moved += move(&action.plannedDayNumber)
            moved += move(&action.startDayNumber)
        }
        for completion in completions {
            moved += move(&completion.dayNumber)
        }
        for pause in pauses {
            moved += move(&pause.startDayNumber)
            moved += move(&pause.endDayNumber)
        }

        if moved > 0 {
            try context.saveOrRollBack()
        }
        return moved
    }

    private func move(_ number: inout Int) -> Int {
        let wanted = Self.stored(number)
        guard wanted != number else { return 0 }
        number = wanted
        return 1
    }

    private func move(_ number: inout Int?) -> Int {
        guard let current = number else { return 0 }
        let wanted = Self.stored(current)
        guard wanted != current else { return 0 }
        number = wanted
        return 1
    }
}
