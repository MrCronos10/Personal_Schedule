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

    /// This Article's distinct measured Words, cached at import as one newline-joined string — a
    /// Word never contains a newline, so this needs no encoding heavier than that.
    ///
    /// Nil rather than an empty default, and the two must not be confused: nil means "never cached",
    /// which `readability(known:)` falls back to working out on the spot rather than reading as
    /// unmeasured. `ArticleLibrary.backfillMeasuredWords()` fills this in for any Article left this
    /// way — imported before this field existed — so the fallback is a one-time gap at start, not a
    /// standing cost paid on every render. An empty string means "cached, and there is nothing
    /// measured in it" — the ordinary answer for prose with no HSK 4/5 Word at all.
    ///
    /// `text` is never edited after import, so the list is cached once and stands for the Article's
    /// whole life: rebuilding it on every render would run the tokenizer over the reading list every
    /// time a tap changed one Word's `WordProgress` row.
    var measuredWordsText: String?

    /// What share of this Article's measured **Words** are already **Known**, out of the `known` set
    /// handed in — this asks nothing of the store itself, so it is always as current as whatever the
    /// caller just fetched, and never a number frozen at import or at 读完 (**Readability**; see
    /// CONTEXT.md).
    ///
    /// Nil when the Article has no measured Words: "no Readability" and "0% known" are different
    /// claims, and there is real Chinese prose with nothing on the HSK 4/5 lists in it.
    func readability(known: Set<String>) -> Double? {
        let words = measuredWordsText.map { cached in
            cached.isEmpty ? [] : cached.split(separator: "\n").map(String.init)
        } ?? VocabularyLibrary.hskWords(in: text).map(\.word)
        guard !words.isEmpty else { return nil }
        let knownHere = words.filter(known.contains).count
        return Double(knownHere) / Double(words.count)
    }

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
