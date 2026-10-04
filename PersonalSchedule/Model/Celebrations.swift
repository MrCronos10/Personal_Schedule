import Foundation

/// Remembers which quiet moments have already landed today, so each one lands once. The moments are
/// a surface and never evidence (ADR 0009): nothing here is a streak, and a day not opened leaves
/// nothing behind.
struct Celebrations {
    static let goalStampDayKey = "celebrations.readingGoalStampDay"

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    /// The stamp is due the first time the day's reading reaches the goal, and not again that day.
    func readingGoalStampIsDue(charactersToday: Int, goal: Int, on day: Day) -> Bool {
        charactersToday >= goal && defaults.object(forKey: Self.goalStampDayKey) as? Int != day.number
    }

    mutating func markReadingGoalStamped(on day: Day) {
        defaults.set(day.number, forKey: Self.goalStampDayKey)
    }
}
