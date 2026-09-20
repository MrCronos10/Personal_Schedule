import Foundation
import Testing
@testable import PersonalSchedule

/// A Weekly Target is stored and typed in minutes, but thought about in hours, so the form shows the
/// same number back in hours while it is being typed. See CONTEXT.md.
struct WeeklyTargetTests {
    @Test func wholeHoursLoseTheirDecimal() throws {
        #expect(WeeklyTarget.hoursText(forMinutes: 420) == "7")
        #expect(WeeklyTarget.hoursText(forMinutes: 60) == "1")
    }

    @Test func halfHoursKeepTheirDecimal() throws {
        #expect(WeeklyTarget.hoursText(forMinutes: 450) == "7.5")
        #expect(WeeklyTarget.hoursText(forMinutes: 30) == "0.5")
    }

    @Test func oddMinutesRoundToOneDecimal() throws {
        #expect(WeeklyTarget.hoursText(forMinutes: 425) == "7.1")
    }

    /// The decimal point must not follow the phone's region, or a comma would appear mid-sentence.
    @Test func theDecimalPointIsTheSameEverywhere() throws {
        #expect(!WeeklyTarget.hoursText(forMinutes: 450).contains(","))
    }
}
