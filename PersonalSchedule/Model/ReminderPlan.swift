import Foundation

/// One reminder: an Action, the day it fires and the time it fires at.
struct Reminder {
    let action: Action
    let day: Day
    let time: TimeOfDay
}

/// Which reminders should exist from today through the six days after it.
///
/// A reminder fires at an Action's own time on the days `DayPlan` puts it on, and only those. This holds
/// no day rule of its own: it asks `DayPlan.appears` about each day, as of that day.
@MainActor
enum ReminderPlan {
    /// How many days ahead are scheduled, today included.
    static let daysAhead = 7
    /// The most pending notifications iOS keeps for one app.
    static let limit = 64

    /// Soonest first, and at most `limit` of them, so if the days would hold more the nearest win.
    static func reminders(_ actions: [Action], today: Day, nowMinutes: Int) -> [Reminder] {
        let all = (0..<daysAhead).flatMap { offset -> [Reminder] in
            let day = today.adding(days: offset)
            return actions.compactMap { action in
                guard action.remindsAtTime, let time = action.time else { return nil }
                // A moment already reached today can't be reminded of.
                guard offset > 0 || time.minutesSinceMidnight > nowMinutes else { return nil }
                // Asked as of that day: "when it comes, unticked, will it be on its list?" A late
                // One-time Action moves to whatever day is today, so it is on each coming day too.
                guard DayPlan.appears(action, on: day, today: day) else { return nil }
                // Done already: a reminder for it is noise.
                guard !DayPlan.isTicked(action, on: day) else { return nil }
                return Reminder(action: action, day: day, time: time)
            }
        }
        // Ties at one time break by when the Action was added, so which ones the limit cuts is
        // always the same.
        let soonestFirst = all.sorted { first, second in
            if first.day != second.day { return first.day < second.day }
            if first.time != second.time {
                return first.time.minutesSinceMidnight < second.time.minutesSinceMidnight
            }
            return first.action.createdAt < second.action.createdAt
        }
        return Array(soonestFirst.prefix(limit))
    }
}
