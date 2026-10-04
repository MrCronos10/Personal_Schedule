import Foundation
import SwiftData

/// The **Topic List**'s rule book: what a word is, when it is **Topic Known**, how the student adds
/// one of their own. See CONTEXT.md and ADR 0007.
///
/// Lives beside `VocabularyLibrary` rather than inside it. The two measure different things against
/// different totals, and keeping them in separate libraries is the one way the HSK Levels can never
/// move when the Topic List moves — the rule ADR 0007 is built to hold.
///
/// Reading-based **Clean Sightings** against the Topic List are a separate ticket. This library
/// exposes the hand path only, so the student can start learning while the reading path lands.
@MainActor
struct TopicLibrary {
    let context: ModelContext

    // MARK: - Reading the list

    /// Every term the Topic List meter counts: the 125 bundled terms plus every active **Custom
    /// Topic Word**. An archived Custom Topic Word leaves this list, so the denominator falls back
    /// to where it was — and that is why the number can only ever go up again, never finish lower
    /// than it was before archiving.
    func allWords() throws -> [TopicTerm] {
        let customs = try activeCustoms()
        let starter = TopicWordList.all.map {
            TopicTerm(word: $0.word, pinyin: $0.pinyin, english: $0.english, group: $0.group, isCustom: false)
        }
        let extra = customs.map {
            TopicTerm(word: $0.word, pinyin: $0.pinyin, english: $0.english, group: $0.group, isCustom: true)
        }
        return starter + extra
    }

    /// Terms in one **Topic Group**, in the order the Topic List carries them, with the student's
    /// own additions after the bundled ones so a new word is visible where the student just added
    /// it rather than slotted into the alphabet.
    func words(in group: TopicGroup) throws -> [TopicTerm] {
        try allWords().filter { $0.group == group }
    }

    /// The Topic List's own number: how many of its active terms are **Topic Known**, out of all of
    /// them. This never includes HSK state — a word Known for HSK is still Not Known for the Topic
    /// List until the student marks it here (ADR 0007).
    func meter() throws -> TopicMeter {
        let words = try allWords()
        let knownSet = try knownWords()
        let known = words.filter { knownSet.contains($0.word) }.count
        return TopicMeter(known: known, total: words.count)
    }

    /// The Topic List meter restricted to one **Topic Group**. The chip row on the 农业词 screen
    /// shows one of these per group.
    func meter(in group: TopicGroup) throws -> TopicMeter {
        let words = try words(in: group)
        let knownSet = try knownWords()
        let known = words.filter { knownSet.contains($0.word) }.count
        return TopicMeter(known: known, total: words.count)
    }

    /// Whether this term has been marked **Topic Known** by hand (the only path this ticket ships).
    func isKnown(_ word: String) throws -> Bool {
        try knownWords().contains(word)
    }

    // MARK: - Writing

    /// Marks a term **Topic Known** by hand, with 认识. A term from the Topic List or a Custom Topic
    /// Word both go through here. A word that is not on either list is refused: the Topic List
    /// never silently invents a new row from a stray tap, so a typo at the screen edge can't inflate
    /// the meter.
    @discardableResult
    func markKnown(_ word: String, on day: Day = Day.today()) throws -> Bool {
        guard try isInList(word) else { return false }
        let row = try progress(for: word) ?? insertProgress(for: word)
        row.isKnown = true
        row.knownDayNumber = day.number
        try context.save()
        return true
    }

    /// Takes it back, with 其实不认识 — the term is Not Known again. Mirrors ADR 0004's rule for HSK:
    /// an admission the word is not known is honest, not a punishment, so the row is kept so the
    /// student's past interaction with it is remembered rather than silently discarded.
    @discardableResult
    func takeKnownBack(_ word: String) throws -> Bool {
        guard let row = try progress(for: word) else { return false }
        row.isKnown = false
        row.knownDayNumber = nil
        try context.save()
        return true
    }

    // MARK: - Custom Topic Words

    /// Validates and adds a **Custom Topic Word**. Rejected without a change to the store if the
    /// word is empty, carries no Chinese character, has no English, or is already in the list
    /// (bundled or custom, active or archived — a restored word brings its history back, so adding
    /// the same spelling again would race it).
    @discardableResult
    func addCustom(word: String, pinyin: String, english: String, group: TopicGroup,
                   on day: Day = Day.today()) throws -> TopicLibrary.AddResult {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPinyin = pinyin.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEnglish = english.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedWord.isEmpty else { return .refused(.emptyWord) }
        guard trimmedWord.unicodeScalars.contains(where: isHan) else { return .refused(.notChinese) }
        guard !trimmedEnglish.isEmpty else { return .refused(.emptyEnglish) }
        if TopicWordList.entry(for: trimmedWord) != nil { return .refused(.alreadyInList) }
        if try customWord(matching: trimmedWord) != nil { return .refused(.alreadyInList) }
        let row = TopicCustomWord(word: trimmedWord, pinyin: trimmedPinyin, english: trimmedEnglish,
                                  group: group, addedDay: day)
        context.insert(row)
        try context.save()
        return .added
    }

    /// Puts a **Custom Topic Word** away. Only a word the student added can be archived; a term from
    /// the bundled list is refused, so a bad tap on the wrong row can't shrink the Topic List under
    /// the student's feet.
    @discardableResult
    func archiveCustom(_ word: String) throws -> Bool {
        guard let row = try customWord(matching: word), !row.isArchived else { return false }
        row.isArchived = true
        try context.save()
        return true
    }

    /// Brings an archived **Custom Topic Word** back, with any **Topic Known** state it already
    /// earned. The number only ever goes up again, as `TopicWordProgress` was never deleted (ADR
    /// 0007), so a word hastily archived can be restored to the state it had.
    @discardableResult
    func restoreCustom(_ word: String) throws -> Bool {
        guard let row = try customWord(matching: word), row.isArchived else { return false }
        row.isArchived = false
        try context.save()
        return true
    }

    /// Every **Custom Topic Word** the student has put away. The 农业词 screen groups these under a
    /// "put away" label — the same shape as the Archived Categories list, so a student who used
    /// one knows exactly where the other is.
    func archivedCustoms() throws -> [TopicCustomWord] {
        try context.fetch(FetchDescriptor<TopicCustomWord>(predicate: #Predicate { $0.isArchived }))
            .sorted { $0.addedDayNumber > $1.addedDayNumber }
    }

    // MARK: - Internals

    private func activeCustoms() throws -> [TopicCustomWord] {
        try context.fetch(FetchDescriptor<TopicCustomWord>(predicate: #Predicate { !$0.isArchived }))
            .sorted { $0.addedDayNumber < $1.addedDayNumber }
    }

    private func customWord(matching word: String) throws -> TopicCustomWord? {
        try context.fetch(FetchDescriptor<TopicCustomWord>(predicate: #Predicate { $0.word == word })).first
    }

    private func progress(for word: String) throws -> TopicWordProgress? {
        try context.fetch(FetchDescriptor<TopicWordProgress>(predicate: #Predicate { $0.word == word })).first
    }

    private func insertProgress(for word: String) -> TopicWordProgress {
        let row = TopicWordProgress(word: word)
        context.insert(row)
        return row
    }

    /// Whether a Topic Known mark may ever be written for this word. A word must be on the Topic
    /// List or in an active Custom Topic Word row — a word on neither is a stray input the Topic
    /// List refuses to count. An archived Custom Topic Word is excluded on purpose: the student
    /// restores it first, then marks it.
    private func isInList(_ word: String) throws -> Bool {
        if TopicWordList.entry(for: word) != nil { return true }
        if let row = try customWord(matching: word), !row.isArchived { return true }
        return false
    }

    private func knownWords() throws -> Set<String> {
        let rows = try context.fetch(FetchDescriptor<TopicWordProgress>(predicate: #Predicate { $0.isKnown }))
        return Set(rows.map(\.word))
    }

    private func isHan(_ scalar: Unicode.Scalar) -> Bool {
        // The CJK Unified Ideographs block, which covers everything on the Topic List.
        let value = scalar.value
        return (0x4E00...0x9FFF).contains(value)
    }
}

/// One term on the **Topic List**, in a shape SwiftUI rows can render — the bundled entry and the
/// Custom Topic Word drawn alike, with a flag for which it is so the "mine" tag can be shown.
struct TopicTerm: Equatable, Sendable {
    let word: String
    let pinyin: String
    let english: String
    let group: TopicGroup
    let isCustom: Bool
}

/// The Topic List's own number — the one the 农业词 screen shows at the top. Separate from any HSK
/// `LevelProgress`: ADR 0007 keeps the two meters apart on purpose.
struct TopicMeter: Equatable, Sendable {
    let known: Int
    let total: Int

    var share: Double { total == 0 ? 0 : Double(known) / Double(total) }
}

extension TopicLibrary {
    /// What `addCustom` answered with. A refusal names its reason so the screen can show the right
    /// line of help text, rather than a generic "something went wrong" that leaves the student
    /// guessing which field is bad.
    enum AddResult: Equatable {
        case added
        case refused(Reason)

        enum Reason: Equatable {
            case emptyWord
            case notChinese
            case emptyEnglish
            case alreadyInList
        }
    }
}
