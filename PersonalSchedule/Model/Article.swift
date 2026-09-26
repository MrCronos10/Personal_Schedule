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

    /// The Article's **Banked Result**: what this reading proved, kept from the moment it proved it.
    ///
    /// Written once, when 读完 first banks the Article, and never recomputed. A **Word** looked up
    /// next week must not rewrite what an Article proved in March — the point of keeping this is to
    /// say what that reading was worth, not what its Words are worth now.
    var bankedDayNumber: Int?
    var bankedNewlyKnown: Int = 0
    var bankedAdvanced: Int = 0
    var bankedReturnedToZero: Int = 0

    var bankedDay: Day? { bankedDayNumber.map(Day.init(number:)) }

    /// What this Article proved, as recorded when 读完 first banked it, or nil when there is nothing
    /// to say.
    ///
    /// Keyed off the banked day rather than `isBanked`, and that is the whole point of storing the
    /// day. An Article finished before this was built is already `isBanked`, and its counters arrive
    /// at their default of zero, so reading `isBanked` here would have every finished Article in the
    /// student's install announce that it proved nothing.
    var bankedResult: VocabularyLibrary.BankResult? {
        guard bankedDayNumber != nil else { return nil }
        return VocabularyLibrary.BankResult(
            newlyKnown: bankedNewlyKnown,
            advanced: bankedAdvanced,
            returnedToZero: bankedReturnedToZero
        )
    }

    @Relationship(deleteRule: .nullify, inverse: \WordLookup.article)
    var lookups: [WordLookup]? = []

    @Relationship(deleteRule: .nullify, inverse: \CleanSighting.article)
    var cleanSightings: [CleanSighting]? = []

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

/// One **Article** the student read to the end without looking a **Word** up: evidence of knowing
/// it. Three of them, in three different Articles, makes the Word **Known**. See CONTEXT.md.
///
/// A record rather than a number, so a Word can say *where* it was earned. A **Lookup** deletes
/// these along with the count they made up, because ADR 0004 means the evidence is genuinely gone
/// and a list that outlived the count would be arguing with it.
@Model
final class CleanSighting {
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
    var isKnown: Bool = false
    var knownDayNumber: Int?
    /// The day this Word was **Set Aside**: answered 不认识, looked up while reading, or taken back
    /// with 其实不认识. **Daily New Words** offers it again thirty days later (ADR 0006).
    ///
    /// Nil means no clock was ever started. Rows written before ADR 0006 are all like this, and they
    /// are treated as eligible rather than parked: a wait that was never recorded has, trivially,
    /// elapsed, and leaving them out would keep the very hole the ADR exists to close.
    var setAsideDayNumber: Int?

    var level: HSKLevel { HSKLevel(rawValue: levelValue) ?? .four }
    var knownDay: Day? { knownDayNumber.map(Day.init(number:)) }
    var setAsideDay: Day? { setAsideDayNumber.map(Day.init(number:)) }

    init(word: String, level: HSKLevel) {
        self.word = word
        self.levelValue = level.rawValue
    }
}
