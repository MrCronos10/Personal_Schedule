import Foundation
import SwiftData

/// What the student has done about one **Topic Word**: whether they have marked it **Topic Known**
/// by hand, and when. See CONTEXT.md and ADR 0007.
///
/// Written lazily, the same shape as `WordProgress`. A Topic Word never marked has no row and reads
/// as not Known, so the store carries at most 125 rows (plus any **Custom Topic Words** the student
/// added), not one per entry on first install.
///
/// Reading-based evidence lives in a separate ticket. This ticket ships the hand path only (ADR
/// 0007); when the reading path lands, the fields it needs are added here beside `isKnown`.
@Model
final class TopicWordProgress {
    var word: String = ""
    var isKnown: Bool = false
    var knownDayNumber: Int?

    var knownDay: Day? { knownDayNumber.map(Day.init(number:)) }

    init(word: String, isKnown: Bool = false, knownDay: Day? = nil) {
        self.word = word
        self.isKnown = isKnown
        self.knownDayNumber = knownDay?.number
    }
}

/// A **Custom Topic Word**: a term the student added themselves on top of the bundled Topic List.
/// See CONTEXT.md.
///
/// Starter terms belong to `TopicWordList` and are read-only; a Custom Topic Word is editable only
/// in that it can be archived (never deleted), the same rule the rest of the app follows for
/// Categories, Routines and Articles. Progress against a Custom Topic Word uses the ordinary
/// `TopicWordProgress` row, keyed by its `word`.
@Model
final class TopicCustomWord {
    var word: String = ""
    var pinyin: String = ""
    var english: String = ""
    var groupRaw: String = TopicGroup.ferment.rawValue
    /// Archived, never deleted (CONTEXT.md). The Topic List meter counts active Custom Topic Words
    /// toward its total, so taking one back out of the list must leave its past Known state alone
    /// — a restored word still reads as Known, and the number only ever moves up.
    var isArchived: Bool = false
    var addedDayNumber: Int = 0

    var group: TopicGroup { TopicGroup(rawValue: groupRaw) ?? .ferment }
    var addedDay: Day { Day(number: addedDayNumber) }

    init(word: String, pinyin: String, english: String, group: TopicGroup, addedDay: Day) {
        self.word = word
        self.pinyin = pinyin
        self.english = english
        self.groupRaw = group.rawValue
        self.addedDayNumber = addedDay.number
    }
}
