import Foundation
import SwiftData

/// A piece of real Chinese writing the student pasted into the app. See CONTEXT.md.
///
/// Every field has a default or is optional, so iCloud sync can be switched on later.
@Model
final class Article {
    /// Taken from the first line of the text, not typed: import is one paste and one button.
    var title: String = ""
    var text: String = ""
    /// Where it came from, in the student's own words. Never translated.
    var source: String?
    var importedDayNumber: Int = 0
    /// Archived, never deleted, so the Clean Sightings it banked can't be taken back (ADR 0005).
    var isArchived: Bool = false
    /// Whether 读完 has already counted this Article's evidence. Set by ticket 16; rereading an
    /// Article proves nothing new, so it may only ever bank once.
    var isBanked: Bool = false

    @Relationship(deleteRule: .nullify, inverse: \WordLookup.article)
    var lookups: [WordLookup]? = []

    var importedDay: Day { Day(number: importedDayNumber) }

    init(title: String, text: String, source: String? = nil, importedDay: Day) {
        self.title = title
        self.text = text
        self.source = source
        self.importedDayNumber = importedDay.number
    }
}

/// The record that the student tapped a Word to see what it means: evidence of *not* knowing it.
/// See CONTEXT.md.
@Model
final class WordLookup {
    var word: String = ""
    var article: Article?
    var dayNumber: Int = 0

    var day: Day { Day(number: dayNumber) }

    init(word: String, article: Article?, day: Day) {
        self.word = word
        self.article = article
        self.dayNumber = day.number
    }
}

/// What the student has done about one **Word**: how close it is to **Known**. See CONTEXT.md.
///
/// Written lazily. A Word never met has no row and counts as not Known, so the store doesn't carry
/// 1,900 empty rows on a fresh install.
@Model
final class WordProgress {
    var word: String = ""
    var levelValue: Int = 4
    /// Articles read to the end without looking this Word up. Three makes it Known.
    var cleanSightings: Int = 0
    var isKnown: Bool = false
    var knownDayNumber: Int?

    var level: HSKLevel { HSKLevel(rawValue: levelValue) ?? .four }
    var knownDay: Day? { knownDayNumber.map(Day.init(number:)) }

    init(word: String, level: HSKLevel) {
        self.word = word
        self.levelValue = level.rawValue
    }
}
