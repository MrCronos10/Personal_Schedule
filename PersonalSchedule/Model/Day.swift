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

    func adding(days: Int, calendar: Calendar = .current) -> Day {
        Day(calendar.date(byAdding: .day, value: days, to: date(calendar: calendar)) ?? date(calendar: calendar), calendar: calendar)
    }

    static func < (lhs: Day, rhs: Day) -> Bool {
        lhs.number < rhs.number
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
