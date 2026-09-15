import Foundation
import Testing
@testable import PersonalSchedule

struct LanguageSettingTests {
    private func emptyDefaults() -> UserDefaults {
        let suite = "LanguageSettingTests-\(UUID().uuidString)"
        return UserDefaults(suiteName: suite)!
    }

    @Test func freshInstallUsesChinese() {
        let setting = LanguageSetting(defaults: emptyDefaults())

        #expect(setting.current == .chinese)
    }

    @Test func choosingEnglishIsRememberedAfterReopening() {
        let defaults = emptyDefaults()
        LanguageSetting(defaults: defaults).current = .english

        let reopened = LanguageSetting(defaults: defaults)

        #expect(reopened.current == .english)
    }
}
