import Foundation

/// A calendar day. Stored as yyyymmdd (20260914), so days compare and sort as numbers.
struct Day: Hashable, Comparable {
    /// The calendar every Day is measured in. See docs/adr/0003-days-are-stored-in-one-calendar.md.
    ///
    /// Fixed to the Gregorian calendar on purpose. The phone's own calendar can be another one — in
    /// Thailand it is the Buddhist calendar, whose year runs 543 ahead — so a day numbered with whatever
    /// the phone happens to use would mean a different day after a change of region. Days on screen are
    /// still shown in the student's own calendar, because that formats a real moment instead of reading
    /// this number.
    ///
    /// The time zone is the phone's, read every time, because which day a moment falls on really is local
    /// and the screens format dates in that same live time zone. Holding on to one would let the day a
    /// student sees drift a day away from the day being stored after they travel.
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    let number: Int

    init(number: Int) {
        self.number = number
    }

    init(year: Int, month: Int, day: Int) {
        number = year * 10_000 + month * 100 + day
    }

    /// The day a moment falls on.
    init(_ date: Date) {
        let parts = Self.calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 0, month: parts.month ?? 0, day: parts.day ?? 0)
    }

    static func today() -> Day {
        Day(Date())
    }

    var year: Int { number / 10_000 }
    var month: Int { number / 100 % 100 }
    var dayOfMonth: Int { number % 100 }

    /// Midnight at the start of this day.
    func date() -> Date {
        date(in: Self.calendar)
    }

    /// The day of the week this day falls on.
    func weekday() -> Weekday {
        let calendar = Self.calendar
        let number = calendar.component(.weekday, from: date(in: calendar))
        return Weekday(rawValue: number) ?? .sunday
    }

    func adding(days: Int) -> Day {
        let calendar = Self.calendar
        let moment = date(in: calendar)
        return Day(calendar.date(byAdding: .day, value: days, to: moment) ?? moment)
    }

    /// One operation reads the time zone once, so a day can't be worked out half in one zone and half in
    /// another if the phone changes zone in the middle of it.
    private func date(in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: dayOfMonth)) ?? Date()
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
    func contains(_ day: Day) -> Bool {
        days.contains(day.weekday())
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
