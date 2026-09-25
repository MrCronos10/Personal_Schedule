import Foundation
import NaturalLanguage
import SwiftData

/// One word split out of an **Article**, with where it sits in the text it came from.
///
/// The range matters: the reading screen draws the Article exactly as it was written and marks
/// words in place, so the student reads the real thing rather than a list of tokens.
struct SegmentedWord: Equatable {
    let text: String
    let range: Range<String.Index>
    /// The **Word List** entry, when this is a Word the app measures. HSK 1-3 and everything else
    /// can still be tapped, but carries no state.
    let entry: HSKEntry?

    var isMeasured: Bool { entry != nil }
}

/// Splits Articles into Words, and records what the student did about one.
@MainActor
struct VocabularyLibrary {
    let context: ModelContext

    // MARK: - Splitting

    /// Splits Chinese text into words, each with its place in the original.
    ///
    /// `NLTokenizer` is built into iOS, so this needs no library and no network.
    nonisolated static func segment(_ text: String) -> [SegmentedWord] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.setLanguage(.simplifiedChinese)
        tokenizer.string = text

        var ranges: [Range<String.Index>] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            // The tokenizer hands back punctuation and whitespace as tokens too. They are part of
            // the Article and must be drawn, but they are not words to look up.
            if text[range].contains(where: { $0.isLetter || $0.isNumber }) {
                ranges.append(range)
            }
            return true
        }
        return join(ranges, in: text)
    }

    /// The most words one entry in the **Word Lists** can be split across by the tokenizer.
    /// 名胜古迹 arrives as 名胜 + 古迹, 弹钢琴 as 弹 + 钢琴.
    private static let longestWordInTokens = 4

    /// Puts back together the Words the tokenizer took apart.
    ///
    /// `NLTokenizer` splits by its own idea of a word, which is not the **Word List**'s: 不过 comes
    /// back as 不 + 过 and 百分之 as 百分 + 之. Thirty-three entries are unreachable without this, and
    /// unreachable means invisible — never underlined, never looked up, never counted, with nothing
    /// on screen to say a word is missing from the year's number.
    ///
    /// Only neighbouring tokens are joined, and only where the join is itself a Word. Working from
    /// the tokenizer's boundaries outward rather than scanning the raw text keeps 国王 from being
    /// found inside 中国王子.
    private nonisolated static func join(
        _ ranges: [Range<String.Index>],
        in text: String
    ) -> [SegmentedWord] {
        var words: [SegmentedWord] = []
        var index = 0
        while index < ranges.count {
            var taken = 1
            var match: (range: Range<String.Index>, entry: HSKEntry)?
            for span in stride(from: min(longestWordInTokens, ranges.count - index), to: 0, by: -1) {
                let range = ranges[index].lowerBound..<ranges[index + span - 1].upperBound
                // Only a run with nothing dropped between its tokens can be one word: a space or a
                // comma inside the span means these were never neighbours.
                let joined = String(text[range])
                guard joined.count == ranges[index..<(index + span)].reduce(0, { $0 + text[$1].count })
                else { continue }
                if let entry = HSKWordList.entry(for: joined) {
                    match = (range, entry)
                    taken = span
                    break
                }
            }
            if let match {
                words.append(
                    SegmentedWord(text: String(text[match.range]), range: match.range, entry: match.entry)
                )
            } else {
                let range = ranges[index]
                let token = String(text[range])
                words.append(
                    SegmentedWord(text: token, range: range, entry: HSKWordList.entry(for: token))
                )
            }
            index += taken
        }
        return words
    }

    /// The HSK 4/5 Words an Article holds, each once however often it appears. This is what one
    /// reading can move, and a Word repeated nine times is still one Article's worth of evidence.
    nonisolated static func hskWords(in text: String) -> [HSKEntry] {
        var seen = Set<String>()
        return segment(text).compactMap { word in
            guard let entry = word.entry, seen.insert(entry.word).inserted else { return nil }
            return entry
        }
    }

    // MARK: - Reading a word

    /// Records that the student tapped a Word to see what it means.
    ///
    /// A Lookup is evidence of *not* knowing, so it returns the Word to zero **Clean Sightings**,
    /// whenever it happens — needing help with a word already banked is real (ADR 0004). A Word the
    /// student has said they know stays Known: only 其实不认识 takes that back.
    ///
    /// A word outside HSK 4 and 5 records nothing at all. It can still be looked up.
    func lookUp(_ word: String, in article: Article, on day: Day = Day.today()) throws {
        guard let entry = HSKWordList.entry(for: word) else { return }
        context.insert(WordLookup(word: entry.word, article: article, day: day))
        if let progress = try progressCreatingIfNeeded(for: entry.word) {
            // The evidence is genuinely gone, not merely uncounted (ADR 0004), so the records go
            // with the count: a list of Articles outliving it would be arguing with it.
            try forgetCleanSightings(of: entry.word)
            // Needing help with a Word is the same admission as 不认识, so it starts the same
            // thirty-day clock rather than parking the Word out of Daily New Words for good.
            progress.setAsideDayNumber = day.number
        }
        try context.saveOrRollBack()
    }

    /// The student saying they already know a Word, without waiting for three Articles to prove it.
    func markKnown(_ word: String, on day: Day = Day.today()) throws {
        guard let progress = try progressCreatingIfNeeded(for: word) else { return }
        progress.isKnown = true
        progress.knownDayNumber = day.number
        try context.saveOrRollBack()
    }

    /// Taking that back. The **Clean Sightings** go too: leaving three behind would make the Word
    /// Known again at the very next 读完, which would read as the app arguing with the student.
    func markNotKnown(_ word: String, on day: Day = Day.today()) throws {
        guard let progress = try progress(for: word) else { return }
        progress.isKnown = false
        progress.knownDayNumber = nil
        try forgetCleanSightings(of: word)
        progress.setAsideDayNumber = day.number
        try context.saveOrRollBack()
    }

    /// Throws away a Word's **Clean Sightings**, so it is back to nothing and every Article has to
    /// be earned again (ADR 0004).
    private func forgetCleanSightings(of word: String) throws {
        for sighting in try cleanSightings(of: word) {
            context.delete(sighting)
        }
    }

    // MARK: - Finishing an Article

    /// What one 读完 moved, for the line the screen shows afterwards.
    struct BankResult: Equatable {
        /// Words that reached three **Clean Sightings** and are now **Known**.
        var newlyKnown = 0
        /// Words that gained a sighting without reaching three yet. A Word the student already
        /// knows is not counted: it has not moved toward anything.
        var advanced = 0
        /// Words sent back to zero by a **Lookup** in this Article. An Article whose Words were all
        /// looked up is not an Article with nothing in it.
        var returnedToZero = 0
        /// This Article had already been banked, so nothing moved. Rereading proves nothing new.
        var wasReread = false
    }

    /// Counts what reading this **Article** to the end proves.
    ///
    /// Every HSK 4/5 Word in it, once however often it appears: a Word looked up *in this Article*
    /// goes back to zero, and a Word not looked up gains one **Clean Sighting**. Three makes it
    /// **Known**. See ADR 0004.
    ///
    /// An Article may only ever bank once. Rereading is worth doing and proves nothing new, so a
    /// second 读完 moves no Word and says so.
    @discardableResult
    func bank(_ article: Article, on day: Day = Day.today()) throws -> BankResult {
        guard !article.isBanked else { return BankResult(wasReread: true) }

        let lookedUpHere = Set(try lookups(in: article).map(\.word))
        var result = BankResult()
        // Every Word's sightings in one fetch, grouped by Word. An Article can hold hundreds of
        // measured Words, and asking the store per Word would be that many queries per 读完.
        var sightingsByWord = Dictionary(
            grouping: try context.fetch(FetchDescriptor<CleanSighting>()),
            by: \.word
        )

        for entry in Self.hskWords(in: article.text) {
            guard let progress = try progressCreatingIfNeeded(for: entry.word) else { continue }
            // Whatever this reading proved about the Word, it moved today, so the thirty-day wait
            // before Daily New Words may offer it again runs from here (ADR 0006). Without this a
            // Word stalled at one or two Clean Sightings would never be offerable again.
            progress.setAsideDayNumber = day.number

            let earned = sightingsByWord[entry.word] ?? []

            if lookedUpHere.contains(entry.word) {
                // Evidence of not knowing. A Word the student has said they know stays Known:
                // only 其实不认识 takes that back.
                if !earned.isEmpty || !progress.isKnown {
                    result.returnedToZero += 1
                }
                for sighting in earned { context.delete(sighting) }
                sightingsByWord[entry.word] = []
                continue
            }

            let wasKnown = progress.isKnown
            // One record per Word per Article: `hskWords(in:)` already answers each Word once
            // however often it appears, and an Article may only ever bank once.
            context.insert(CleanSighting(word: entry.word, article: article, day: day))
            if earned.count + 1 >= Self.sightingsForKnown, !wasKnown {
                // A Word already Known keeps the day it was first known on, so the record says when
                // the student got it, not when they last read it.
                progress.isKnown = true
                progress.knownDayNumber = day.number
                result.newlyKnown += 1
            } else if !wasKnown {
                result.advanced += 1
            }
        }

        article.isBanked = true
        try context.saveOrRollBack()
        return result
    }

    /// Three different Articles, none of them looked up. See ADR 0004 for why three.
    static let sightingsForKnown = 3

    /// How many Words a Note names before it gives up and says "…". A Note is a reminder of the
    /// sitting, not an inventory of it.
    static let wordsNamedInNote = 8

    /// The Note the Tick sheet opens with: the Article, and the Words met that aren't **Known** yet.
    ///
    /// It is the student's own text from that moment on — editable, deletable, and never translated.
    /// An Article with nothing new in it names itself and stops, rather than leaving a 新词： with
    /// nothing after it.
    func noteForSession(with article: Article) throws -> String {
        let known = Set(
            try context.fetch(
                FetchDescriptor<WordProgress>(predicate: #Predicate { $0.isKnown })
            ).map(\.word)
        )
        let met = Self.hskWords(in: article.text)
            .map(\.word)
            .filter { !known.contains($0) }

        let title = "《\(article.title)》"
        guard !met.isEmpty else { return title }
        let named = met.prefix(Self.wordsNamedInNote).joined(separator: "、")
        let ellipsis = met.count > Self.wordsNamedInNote ? "…" : ""
        return "\(title) · 新词：\(named)\(ellipsis)"
    }

    // MARK: - Levels

    /// How far one **Level** has come: **Known** Words out of the whole **Word List**.
    ///
    /// The denominator is the whole List, never the Words that happened to appear in the student's
    /// Articles — a number that fell every time something new was imported would punish the exact
    /// behaviour the feature is built to reward. So this only ever goes up, except when the student
    /// themselves says 其实不认识. See ADR 0005.
    func level(_ level: HSKLevel) throws -> LevelProgress {
        let words = Set(HSKWordList.words(at: level).map(\.word))
        let known = try context.fetch(
            FetchDescriptor<WordProgress>(predicate: #Predicate { $0.isKnown })
        ).filter { words.contains($0.word) }.count
        return LevelProgress(level: level, known: known)
    }

    /// The Level **Daily New Words** are drawn from: HSK 4 until it is **Passed**, then HSK 5.
    ///
    /// This is the only thing passing a Level changes. No Article is ever locked, and a Word of the
    /// unserved Level still counts the moment it turns up in something the student read.
    func servedLevel() throws -> HSKLevel {
        Self.servedLevel(four: try level(.four))
    }

    nonisolated static func servedLevel(four: LevelProgress) -> HSKLevel {
        four.isPassed ? .five : .four
    }

    // MARK: - Daily New Words

    /// How many unmet Words are offered a day. Small on purpose: this is a top-up, not a queue.
    static let dailyNewWordCount = 10

    /// How long a **Set Aside** Word waits before it may be offered again. See ADR 0006.
    ///
    /// Blunt on purpose: not tuned, not per-Word and not earned. A Word answered 不认识 four times
    /// running waits exactly as long as one answered once, because anything cleverer is an interval
    /// schedule wearing a different hat, and ADR 0004 turned that down.
    static let daysSetAside = 30

    /// Whether a Word may be offered in **Daily New Words** on this day.
    ///
    /// Nil progress is a Word never met at all. Otherwise: any Word that isn't **Known** and hasn't
    /// moved for thirty days. A Word part-way to Known is included on purpose — one that gained a
    /// **Clean Sighting** and never turned up in an Article again would otherwise be stalled at one
    /// or two forever, which is the hole ADR 0006 exists to close, reached through reading instead
    /// of 不认识. Its sightings are kept either way: being offered again is another chance, never a
    /// reason to lose evidence already earned.
    static func isOfferable(_ progress: WordProgress?, on day: Day) -> Bool {
        guard let progress else { return true }
        guard !progress.isKnown else { return false }
        // No clock was ever started, so the wait has trivially elapsed. This is what carries the fix
        // onto rows written before ADR 0006 rather than leaving them parked for good.
        guard let setAside = progress.setAsideDay else { return true }
        return setAside.adding(days: daysSetAside) <= day
    }

    /// Ten Words of the **Served Level** that may be offered today.
    ///
    /// The same ten all day, worked out from the day itself, so leaving the tab and coming back
    /// doesn't reshuffle them.
    ///
    /// There is deliberately no notion of due, no streak and no debt. A **Set Aside** Word coming
    /// back is offered like any other unmet Word, and a day not opened leaves nothing behind
    /// (ADR 0004, ADR 0006).
    func dailyNewWords(on day: Day = Day.today()) throws -> [HSKEntry] {
        let rows = Dictionary(
            try context.fetch(FetchDescriptor<WordProgress>()).map { ($0.word, $0) },
            // No field in the store is unique and iCloud sync is switched on later, so two rows for
            // one Word is possible. Keep whichever has come furthest rather than an arbitrary
            // winner: losing a Known row here would offer the student a Word they already have.
            uniquingKeysWith: { left, right in
                if left.isKnown != right.isKnown { return left.isKnown ? left : right }
                return (left.setAsideDayNumber ?? 0) >= (right.setAsideDayNumber ?? 0) ? left : right
            }
        )
        let all = HSKWordList.words(at: try servedLevel())
        guard !all.isEmpty else { return [] }

        // Walk the whole List from a place the day decides, skipping what can't be offered. The
        // offset is taken from the List's own length, never from what is left of it: seeding off the
        // remaining pool would move the window every time a Word was answered or tapped, and the
        // student would watch the day's ten reshuffle under their hand.
        let start = abs(day.number) % all.count
        var words: [HSKEntry] = []
        for offset in 0..<all.count {
            let entry = all[(start + offset) % all.count]
            guard Self.isOfferable(rows[entry.word], on: day) else { continue }
            words.append(entry)
            if words.count == Self.dailyNewWordCount { break }
        }
        return words
    }

    /// 不认识: the Word is **Set Aside**. It leaves the daily pool for thirty days and is then
    /// offerable again (ADR 0006). Nothing is held against the student for saying so, and nothing
    /// is owed in the meantime: a Set Aside Word is never due and never shown as waiting.
    func setAside(_ word: String, on day: Day = Day.today()) throws {
        guard let progress = try progressCreatingIfNeeded(for: word) else { return }
        progress.setAsideDayNumber = day.number
        try context.saveOrRollBack()
    }

    // MARK: - Reading what is recorded

    func progress(for word: String) throws -> WordProgress? {
        var descriptor = FetchDescriptor<WordProgress>(predicate: #Predicate { $0.word == word })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// The row for a Word, made if it isn't there yet. Rows are written lazily, so a fresh install
    /// doesn't carry 1,900 empty ones. Returns nil for a word the app doesn't measure.
    @discardableResult
    func progressCreatingIfNeeded(for word: String) throws -> WordProgress? {
        if let existing = try progress(for: word) { return existing }
        guard let entry = HSKWordList.entry(for: word) else { return nil }
        let progress = WordProgress(word: entry.word, level: entry.level)
        context.insert(progress)
        return progress
    }

    /// The Articles that earned one **Word** its **Clean Sightings**, oldest first.
    ///
    /// This is the Word's evidence, and its count: there is no separate number to drift from it.
    func cleanSightings(of word: String) throws -> [CleanSighting] {
        try context.fetch(
            FetchDescriptor<CleanSighting>(
                predicate: #Predicate { $0.word == word },
                sortBy: [SortDescriptor(\.dayNumber)]
            )
        )
    }

    /// Every Lookup made inside one Article: the Words this reading does not get to count.
    ///
    /// Read off the Article's own relationship rather than fetched and filtered, so there is no
    /// query that could quietly lose its article filter and freeze every Word the student ever
    /// tapped.
    func lookups(in article: Article) throws -> [WordLookup] {
        article.lookups ?? []
    }

    /// Every Lookup of one Word inside one Article.
    func lookups(of word: String, in article: Article) throws -> [WordLookup] {
        try lookups(in: article).filter { $0.word == word }
    }
}
