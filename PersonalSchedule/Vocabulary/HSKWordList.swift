import Foundation

/// A **Level**: one bundled **Word List**, seen as progress. See CONTEXT.md.
///
/// HSK 1-3 is not carried. Those words are assumed known and are not measured, which is why
/// `HSKWordList.level(of:)` answers nil for them rather than a level. See ADR 0005.
enum HSKLevel: Int, CaseIterable, Codable, Sendable {
    case four = 4
    case five = 5

    /// How many Words the Level holds: the denominator of its share of the year's Known count.
    ///
    /// Read from the bundled list rather than written here, so there is one source of truth. A
    /// second copy would let a Level report 612 / 600, or make Passed land at the wrong point,
    /// if the bundle ever drifted from the number in ADR 0005.
    var total: Int { HSKWordList.total(at: self) }
}

/// One entry in a **Word List**: the word as it is written, its pinyin and its English.
///
/// This is read from the bundle, never stored. A `WordProgress` row keeps only the word itself,
/// so a Word's meaning can be corrected in a later version without touching the student's history.
struct HSKEntry: Equatable, Sendable {
    let word: String
    let pinyin: String
    let english: String
    let level: HSKLevel

    /// The official list separates a grammar word's senses by part of speech: 得（助动词）is HSK 4
    /// while bare 得 belongs to a lower level. The annotation is part of the word here, so these
    /// entries never match a word split out of an Article — bare 得 would otherwise be underlined
    /// in nearly every sentence and reach Known for nothing. They are met in Daily New Words only.
    ///
    /// Marked by the generator, not guessed at from the word's spelling: a later entry carrying a
    /// full-width bracket for some other reason must not quietly become a grammar entry.
    let isGrammarEntry: Bool
}

/// The two **Word Lists** bundled with the app: HSK 4 and HSK 5 of the HSK 2.0 standard.
///
/// Read-only and never edited by the app. Changing what it holds would move the denominator under
/// a number the student has been watching for a year. See `SOURCE.md` for where it came from.
enum HSKWordList {
    /// Both lists, HSK 4 first, each in the list's own order, which is roughly by frequency.
    static let all: [HSKEntry] = load()

    private static let byWord: [String: HSKEntry] = Dictionary(
        all.map { ($0.word, $0) },
        uniquingKeysWith: { first, _ in first }
    )

    private static let byLevel: [HSKLevel: [HSKEntry]] = Dictionary(grouping: all, by: \.level)

    static func words(at level: HSKLevel) -> [HSKEntry] {
        byLevel[level] ?? []
    }

    /// Cached, because a Level's total is read several times per row per render and scanning all
    /// 1,900 entries each time is work the screen does not need to repeat.
    static func total(at level: HSKLevel) -> Int {
        words(at: level).count
    }

    static func entry(for word: String) -> HSKEntry? {
        byWord[word]
    }

    static func level(of word: String) -> HSKLevel? {
        byWord[word]?.level
    }

    // MARK: - Loading

    /// The shape on disk, kept short because it is repeated 1,900 times.
    private struct Row: Decodable {
        let w: String
        let p: String
        let e: String
        let l: Int
        /// Present, and true, only on a grammar entry.
        let g: Bool?
    }

    private static func load() -> [HSKEntry] {
        guard let url = Bundle.main.url(forResource: "HSKWordList", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rows = try? JSONDecoder().decode([Row].self, from: data)
        else {
            // The list is bundled with the app, so this can only mean a broken build. It has to
            // stop here and in a release build too: an empty list is not an error the student
            // would ever see as one. Every Level would read 0 / 600, no word would be underlined,
            // and no Clean Sighting would ever be banked — a year of reading silently recording
            // nothing, which is far worse than not starting.
            fatalError("HSKWordList.json is missing or unreadable in the app bundle")
        }
        return rows.compactMap { row in
            guard let level = HSKLevel(rawValue: row.l) else { return nil }
            return HSKEntry(
                word: row.w,
                pinyin: row.p,
                english: row.e,
                level: level,
                isGrammarEntry: row.g ?? false
            )
        }
    }
}

/// How far one **Level** has come. See CONTEXT.md and ADR 0005.
struct LevelProgress: Equatable {
    let level: HSKLevel
    /// Words **Known** at this Level.
    let known: Int

    /// Every Word the Level holds: 600 at HSK 4, 1,300 at HSK 5.
    var total: Int { level.total }

    /// **Passed** at four fifths. Integer arithmetic, so 479/600 is not Passed and 480/600 is —
    /// a rounded percentage would make the boundary wobble.
    var isPassed: Bool { known * 5 >= total * 4 }

    /// How full the bar is, 0 to 1.
    var share: Double { total == 0 ? 0 : Double(known) / Double(total) }
}
