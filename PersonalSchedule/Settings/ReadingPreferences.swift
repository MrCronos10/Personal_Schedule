import CoreGraphics
import Foundation

/// What the student has chosen about reading: the day's goal in characters, and the size of the
/// text in the reader. Kept in `UserDefaults`; the Settings screen and the reader both bind to the
/// same keys with `@AppStorage`, and this type is the one place the defaults and ranges are written.
struct ReadingPreferences {
    static let goalKey = "reading.dailyGoal"
    static let fontSizeKey = "reading.fontSize"
    static let defaultGoal = 200
    static let defaultFontSize = 17.0
    static let goalRange = 50...1000
    static let fontSizeRange = 15.0...24.0

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    var dailyGoal: Int {
        get { defaults.object(forKey: Self.goalKey) as? Int ?? Self.defaultGoal }
        set { defaults.set(min(max(newValue, Self.goalRange.lowerBound), Self.goalRange.upperBound), forKey: Self.goalKey) }
    }

    var fontSize: Double {
        get { defaults.object(forKey: Self.fontSizeKey) as? Double ?? Self.defaultFontSize }
        set { defaults.set(min(max(newValue, Self.fontSizeRange.lowerBound), Self.fontSizeRange.upperBound), forKey: Self.fontSizeKey) }
    }

    /// Line height 1.9 at any size: SwiftUI adds this to the font's own ~1.2, so 0.7 more makes 1.9.
    static func lineSpacing(forFontSize size: Double) -> CGFloat {
        CGFloat(size * 0.7)
    }
}
