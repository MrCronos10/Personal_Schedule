import Foundation
import Testing
@testable import PersonalSchedule

struct ReadingPreferencesTests {
    private func emptyDefaults() -> UserDefaults {
        UserDefaults(suiteName: "ReadingPreferencesTests-\(UUID().uuidString)")!
    }

    @Test func aFreshInstallReads200CharactersAtSize17() {
        let preferences = ReadingPreferences(defaults: emptyDefaults())

        #expect(preferences.dailyGoal == 200)
        #expect(preferences.fontSize == 17)
    }

    @Test func choicesAreRememberedAfterReopening() {
        let defaults = emptyDefaults()
        var preferences = ReadingPreferences(defaults: defaults)
        preferences.dailyGoal = 350
        preferences.fontSize = 20

        let reopened = ReadingPreferences(defaults: defaults)
        #expect(reopened.dailyGoal == 350)
        #expect(reopened.fontSize == 20)
    }

    @Test func valuesOutsideTheRangesAreHeldInside() {
        var preferences = ReadingPreferences(defaults: emptyDefaults())
        preferences.dailyGoal = 5
        preferences.fontSize = 99
        #expect(preferences.dailyGoal == ReadingPreferences.goalRange.lowerBound)
        #expect(preferences.fontSize == ReadingPreferences.fontSizeRange.upperBound)
    }

    /// 1.9 line height at any size, so the slider never makes lines cramped.
    @Test func lineSpacingFollowsTheFontSize() {
        #expect(ReadingPreferences.lineSpacing(forFontSize: 17) == 17 * 0.7)
        #expect(ReadingPreferences.lineSpacing(forFontSize: 20) == 20 * 0.7)
    }
}
