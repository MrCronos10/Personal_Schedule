import Foundation
import Observation

/// The language of the app's screen text. The student's own names and Notes are never translated.
enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }

    var locale: Locale { Locale(identifier: rawValue) }

    /// Each language is always shown in its own script, so it can be found from either language.
    var nativeName: String {
        switch self {
        case .chinese: "中文"
        case .english: "English"
        }
    }
}

/// Remembers which language the student chose. 中文 until they pick another.
/// The app shares one instance through the SwiftUI environment, so screens update as soon as it changes.
@Observable
final class LanguageSetting {
    static let key = "appLanguage"
    static let defaultLanguage = AppLanguage.chinese

    @ObservationIgnored private let defaults: UserDefaults

    var current: AppLanguage {
        didSet { defaults.set(current.rawValue, forKey: Self.key) }
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        current = defaults.string(forKey: Self.key).flatMap(AppLanguage.init(rawValue:)) ?? Self.defaultLanguage
    }
}
