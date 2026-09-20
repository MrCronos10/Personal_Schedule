import Foundation
import Testing
@testable import PersonalSchedule

/// A Day is a calendar day the app stores as a number, and that number must mean the same thing whatever
/// calendar the phone is set to. See docs/adr/0003-days-are-stored-in-one-calendar.md.
@MainActor
struct DayTests {
    @Test func todayIsNumberedInTheSameCalendarWhateverThePhoneIsSetTo() throws {
        let now = Date()
        let gregorian = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: now)

        let today = Day.today()

        #expect(today.year == gregorian.year)
        #expect(today.month == gregorian.month)
        #expect(today.dayOfMonth == gregorian.day)
    }

    /// This Mac is set to the Thai Buddhist calendar, where the year runs 543 ahead. A day must not be
    /// numbered with that year, or the same stored number would mean two different days on two phones.
    @Test func aDayIsNotNumberedWithThePhonesOwnEra() throws {
        let phoneYear = Calendar.current.dateComponents([.year], from: Date()).year ?? 0

        let today = Day.today()

        #expect(today.year != phoneYear || Calendar.current.identifier == .gregorian)
        #expect(today.year > 1900)
        #expect(today.year < 2400)
    }

    @Test func aDayKnowsItsWeekdayWithoutBeingToldACalendar() throws {
        #expect(Day(year: 2026, month: 9, day: 14).weekday() == .monday)
        #expect(Day(year: 2026, month: 9, day: 13).weekday() == .sunday)
        #expect(Day(year: 2026, month: 9, day: 19).weekday() == .saturday)
    }

    /// The number goes out to a moment and comes back as the same day.
    @Test func aDayMadeFromItsOwnDateIsTheSameDay() throws {
        let day = Day(year: 2026, month: 9, day: 14)

        #expect(Day(day.date()) == day)
    }

    @Test func daysStayInOrderAcrossAMonthEnd() throws {
        let endOfMonth = Day(year: 2026, month: 9, day: 30)

        #expect(endOfMonth.adding(days: 1) == Day(year: 2026, month: 10, day: 1))
        #expect(endOfMonth.adding(days: -30) == Day(year: 2026, month: 8, day: 31))
    }

    /// A Weekly Target is measured Monday to Sunday, whatever day the phone's locale calls the first one.
    /// This Mac's locale starts its week on Sunday, so borrowing `firstWeekday` would split the week wrongly.
    @Test func aWeekRunsMondayToSunday() throws {
        let week = Week(containing: Day(year: 2026, month: 9, day: 17))

        #expect(week.monday == Day(year: 2026, month: 9, day: 14))
        #expect(week.sunday == Day(year: 2026, month: 9, day: 20))
    }

    @Test func mondayAndSundayAreTheEdgesOfTheirOwnWeek() throws {
        #expect(Week(containing: Day(year: 2026, month: 9, day: 14)).monday == Day(year: 2026, month: 9, day: 14))
        #expect(Week(containing: Day(year: 2026, month: 9, day: 20)).sunday == Day(year: 2026, month: 9, day: 20))
    }

    @Test func sundayAndTheNextMondayAreDifferentWeeks() throws {
        let sunday = Day(year: 2026, month: 9, day: 20)
        let monday = sunday.adding(days: 1)

        #expect(Week(containing: sunday) != Week(containing: monday))
        #expect(Week(containing: monday).monday == monday)
    }

    @Test func aWeekHoldsItsOwnDaysAndNoOthers() throws {
        let week = Week(containing: Day(year: 2026, month: 9, day: 17))

        #expect(week.contains(Day(year: 2026, month: 9, day: 14)))
        #expect(week.contains(Day(year: 2026, month: 9, day: 20)))
        #expect(!week.contains(Day(year: 2026, month: 9, day: 13)))
        #expect(!week.contains(Day(year: 2026, month: 9, day: 21)))
    }

    @Test func aWeekSpansAMonthEnd() throws {
        let week = Week(containing: Day(year: 2026, month: 10, day: 1))

        #expect(week.monday == Day(year: 2026, month: 9, day: 28))
        #expect(week.sunday == Day(year: 2026, month: 10, day: 4))
    }
}
