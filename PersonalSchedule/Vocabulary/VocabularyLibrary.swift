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
            progress.cleanSightings = 0
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
    func markNotKnown(_ word: String) throws {
        guard let progress = try progress(for: word) else { return }
        progress.isKnown = false
        progress.knownDayNumber = nil
        progress.cleanSightings = 0
        try context.saveOrRollBack()
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

        for entry in Self.hskWords(in: article.text) {
            guard let progress = try progressCreatingIfNeeded(for: entry.word) else { continue }
            if lookedUpHere.contains(entry.word) {
                // Evidence of not knowing. A Word the student has said they know stays Known:
                // only 其实不认识 takes that back.
                if progress.cleanSightings > 0 || !progress.isKnown {
                    result.returnedToZero += 1
                }
                progress.cleanSightings = 0
                continue
            }
            let wasKnown = progress.isKnown
            progress.cleanSightings += 1
            if progress.cleanSightings >= Self.sightingsForKnown, !wasKnown {
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
