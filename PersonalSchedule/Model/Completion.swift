import Foundation
import SwiftData

/// The record made when an Action is ticked off on a day: the minutes spent, plus an optional Note.
///
/// It keeps its own copy of the Action's title and Category, so editing the Action later never
/// rewrites finished days. See docs/adr/0002-completion-keeps-copy-of-action.md.
@Model
final class Completion {
    var action: Action?
    var category: Category?
    var titleWhenTicked: String = ""
    var dayNumber: Int = 0
    var minutes: Int?
    var note: String?
    var createdAt: Date = Date()

    init(titleWhenTicked: String, day: Day, minutes: Int?, note: String?, createdAt: Date = Date()) {
        self.titleWhenTicked = titleWhenTicked
        self.dayNumber = day.number
        self.minutes = minutes
        self.note = note
        self.createdAt = createdAt
    }

    var day: Day { Day(number: dayNumber) }
}
