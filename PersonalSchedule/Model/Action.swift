import Foundation
import SwiftData

/// One thing the student plans to do, such as "学20个新词". See CONTEXT.md.
///
/// Every field has a default or is optional so iCloud sync can be switched on later.
@Model
final class Action {
    var title: String = ""
    var category: Category?
    var plannedDayNumber: Int = 0
    var timeMinutes: Int?
    var defaultMinutes: Int?
    var createdAt: Date = Date()

    init(title: String, plannedDay: Day, time: TimeOfDay?, defaultMinutes: Int?, createdAt: Date = Date()) {
        self.title = title
        self.plannedDayNumber = plannedDay.number
        self.timeMinutes = time?.minutesSinceMidnight
        self.defaultMinutes = defaultMinutes
        self.createdAt = createdAt
    }

    var plannedDay: Day { Day(number: plannedDayNumber) }

    var time: TimeOfDay? { timeMinutes.map(TimeOfDay.init(minutesSinceMidnight:)) }
}
