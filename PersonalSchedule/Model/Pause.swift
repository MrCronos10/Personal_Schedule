import Foundation
import SwiftData

/// A stretch of days a Routine was stopped for. See "Paused Routine" in CONTEXT.md.
///
/// It covers the days from its start day up to, but not including, the day the Routine was resumed, so
/// resuming on a day puts the Routine back on that day. While the Routine is still paused there is no end
/// day yet. Every field has a default or is optional so iCloud sync can be switched on later.
@Model
final class Pause {
    var action: Action?
    var startDayNumber: Int = 0
    /// Empty while the Routine is still paused.
    var endDayNumber: Int?
    var createdAt: Date = Date()

    init(startDay: Day, createdAt: Date = Date()) {
        self.startDayNumber = startDay.number
        self.createdAt = createdAt
    }

    var startDay: Day { Day(number: startDayNumber) }

    var endDay: Day? { endDayNumber.map(Day.init(number:)) }

    var hasEnded: Bool { endDayNumber != nil }

    /// Whether this pause covers a day.
    func contains(_ day: Day) -> Bool {
        guard day >= startDay else { return false }
        guard let endDay else { return true }
        return day < endDay
    }
}
