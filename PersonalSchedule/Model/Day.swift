import Foundation

/// A calendar day, independent of time zone. Stored as yyyymmdd (20260914), so days compare and sort as numbers.
struct Day: Hashable, Comparable {
    let number: Int

    init(number: Int) {
        self.number = number
    }

    init(year: Int, month: Int, day: Int) {
        number = year * 10_000 + month * 100 + day
    }

    /// The day a moment falls on, in the phone's calendar and time zone.
    init(_ date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 0, month: parts.month ?? 0, day: parts.day ?? 0)
    }

    static func today(calendar: Calendar = .current) -> Day {
        Day(Date(), calendar: calendar)
    }

    var year: Int { number / 10_000 }
    var month: Int { number / 100 % 100 }
    var dayOfMonth: Int { number % 100 }

    /// Midnight at the start of this day.
    func date(calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: dayOfMonth)) ?? Date()
    }

    /// The day of the week this day falls on, in the phone's calendar.
    func weekday(calendar: Calendar = .current) -> Weekday {
        let number = calendar.component(.weekday, from: date(calendar: calendar))
        return Weekday(rawValue: number) ?? .sunday
    }

    func adding(days: Int, calendar: Calendar = .current) -> Day {
        Day(calendar.date(byAdding: .day, value: days, to: date(calendar: calendar)) ?? date(calendar: calendar), calendar: calendar)
    }

    static func < (lhs: Day, rhs: Day) -> Bool {
        lhs.number < rhs.number
    }
}

/// A day of the week, numbered the way calendars number them, so Sunday is 1.
enum Weekday: Int, CaseIterable, Identifiable, Hashable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    /// This weekday's place in the Action's stored repeat days.
    var bit: Int { 1 << (rawValue - 1) }
}

/// The days a Routine repeats on: 每天, 工作日 (Monday to Friday), or the days the student chose.
///
/// Kept on the Action as one Int with a bit per weekday, so the database holds a plain number
/// with a default, and no new record is needed. See CONTEXT.md for what a Routine is.
struct RepeatDays: Hashable {
    let days: Set<Weekday>

    init(_ days: Set<Weekday>) {
        self.days = days
    }

    init(mask: Int) {
        days = Set(Weekday.allCases.filter { mask & $0.bit != 0 })
    }

    static let everyDay = RepeatDays(Set(Weekday.allCases))
    static let weekdays = RepeatDays([.monday, .tuesday, .wednesday, .thursday, .friday])

    var mask: Int { days.reduce(0) { $0 | $1.bit } }

    var isEmpty: Bool { days.isEmpty }

    /// Whether a Routine with these repeat days repeats on that day.
    func contains(_ day: Day, calendar: Calendar = .current) -> Bool {
        days.contains(day.weekday(calendar: calendar))
    }
}

/// A time on the clock, such as 07:00. Stored as minutes since midnight.
struct TimeOfDay: Hashable {
    let hour: Int
    let minute: Int

    init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    init(minutesSinceMidnight: Int) {
        hour = minutesSinceMidnight / 60
        minute = minutesSinceMidnight % 60
    }

    var minutesSinceMidnight: Int { hour * 60 + minute }

    /// "07:00"
    var clockText: String { String(format: "%02d:%02d", hour, minute) }
}
