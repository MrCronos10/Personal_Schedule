import Foundation
import SwiftData

/// One thing the student plans to do, such as "学20个新词". See CONTEXT.md.
///
/// It is either a One-time Action, which has a planned day, or a Routine, which has repeat days and a
/// start day. Every field has a default or is optional so iCloud sync can be switched on later.
@Model
final class Action {
    var title: String = ""
    var category: Category?
    var plannedDayNumber: Int = 0
    var timeMinutes: Int?
    var defaultMinutes: Int?
    var createdAt: Date = Date()
    /// A Routine's repeat days, as one bit per weekday. Empty for a One-time Action.
    var repeatWeekdayMask: Int?
    /// The day a Routine starts repeating. Empty for a One-time Action.
    var startDayNumber: Int?

    @Relationship(deleteRule: .cascade, inverse: \Completion.action)
    var completions: [Completion]? = []

    init(title: String, plannedDay: Day, time: TimeOfDay?, defaultMinutes: Int?, createdAt: Date = Date()) {
        self.title = title
        self.plannedDayNumber = plannedDay.number
        self.timeMinutes = time?.minutesSinceMidnight
        self.defaultMinutes = defaultMinutes
        self.createdAt = createdAt
    }

    init(
        title: String,
        repeatDays: RepeatDays,
        startDay: Day,
        time: TimeOfDay?,
        defaultMinutes: Int?,
        createdAt: Date = Date()
    ) {
        self.title = title
        self.repeatWeekdayMask = repeatDays.mask
        self.startDayNumber = startDay.number
        // A Routine is found by its repeat days, not this, but it is kept as a real day so that an Action
        // left without repeat days falls back to a One-time Action on a real day instead of day zero.
        self.plannedDayNumber = startDay.number
        self.timeMinutes = time?.minutesSinceMidnight
        self.defaultMinutes = defaultMinutes
        self.createdAt = createdAt
    }

    /// The day a One-time Action is planned for. A Routine keeps its start day here as well, so this is
    /// never day zero.
    var plannedDay: Day { Day(number: plannedDayNumber) }

    var time: TimeOfDay? { timeMinutes.map(TimeOfDay.init(minutesSinceMidnight:)) }

    /// A Routine repeats on set days from a start day; a One-time Action happens once. See CONTEXT.md.
    ///
    /// Both halves are required, the same two the day rule asks for, so an Action can never be a Routine
    /// that appears on no day at all while still refusing to be deleted.
    var isRoutine: Bool { repeatDays != nil && startDay != nil }

    /// No repeat days left means no Routine, so an empty set of days reads as nothing at all.
    var repeatDays: RepeatDays? {
        guard let mask = repeatWeekdayMask, mask != 0 else { return nil }
        return RepeatDays(mask: mask)
    }

    var startDay: Day? { startDayNumber.map(Day.init(number:)) }
}
