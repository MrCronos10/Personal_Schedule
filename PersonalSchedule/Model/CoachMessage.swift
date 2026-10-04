import Foundation
import SwiftData

/// One line in a **Coach Session**: either what the student asked or what the Coach answered. See
/// CONTEXT.md and ADR 0008.
///
/// Pinned to the **Article** it was about, so a student rereading last month's article sees the
/// same chat they already had with the Coach rather than a fresh page every time.
@Model
final class CoachMessage {
    /// Which side wrote the message. Stored as its raw string so the schema can be read without
    /// knowing the Swift enum.
    var roleRaw: String = "user"
    var text: String = ""
    var article: Article?
    var dayNumber: Int = 0
    /// When the message was saved. Needed to sort two messages written on the same day: without it
    /// the thread sometimes shows the Coach's reply before the student's question, which reads as
    /// nonsense. Not a record for the student to see, only the thread order.
    var createdAt: Date = Date()
    /// Which language mode the student picked for that message (both, Chinese only, English only).
    /// Kept so a reread of the thread shows the same tags without inferring them from the content.
    var languageRaw: String = "both"

    var role: CoachMessageRole { CoachMessageRole(rawValue: roleRaw) ?? .user }
    var language: CoachLanguage { CoachLanguage(rawValue: languageRaw) ?? .both }
    var day: Day { Day(number: dayNumber) }

    init(role: CoachMessageRole, text: String, article: Article?, language: CoachLanguage, day: Day,
         createdAt: Date = Date()) {
        self.roleRaw = role.rawValue
        self.text = text
        self.article = article
        self.languageRaw = language.rawValue
        self.dayNumber = day.number
        self.createdAt = createdAt
    }
}

enum CoachMessageRole: String, Codable, Sendable {
    case user, coach
}
