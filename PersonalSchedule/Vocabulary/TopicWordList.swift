import Foundation

/// One of the six **Topic Groups** the **Topic List** is split into. See CONTEXT.md and ADR 0007.
///
/// A group is how the student browses the list — "words to use when talking to a supplier" vs.
/// "words on a lab report" — and never a locked unit of progress: every term in every group counts
/// toward the one Topic List number from the day it is added.
enum TopicGroup: String, CaseIterable, Codable, Sendable {
    case raw, ferment, soil, safety, plant, trade

    /// The group's Chinese name, as shown in the chip row on the 农业词 screen.
    var chinese: String {
        switch self {
        case .raw: return "粪便与原料"
        case .ferment: return "堆肥与发酵"
        case .soil: return "养分与土壤"
        case .safety: return "质量安全与检测"
        case .plant: return "生产与机械"
        case .trade: return "市场与贸易"
        }
    }

    /// The group's English name, used when the app's Language is set to English. Short, so a long
    /// chip label never pushes the row sideways.
    var english: String {
        switch self {
        case .raw: return "Manure and raw materials"
        case .ferment: return "Composting and fermentation"
        case .soil: return "Nutrients, soil and crops"
        case .safety: return "Quality, safety and lab"
        case .plant: return "Production and machinery"
        case .trade: return "Market and trade"
        }
    }
}

/// One entry in the **Topic List**: the word, its pinyin, its short English, and the **Topic Group**
/// it belongs to. Read from the bundle, never stored. A `TopicWordProgress` row keeps only the word
/// itself, so a gloss can be corrected in a later version without touching the student's history.
struct TopicEntry: Equatable, Sendable {
    let word: String
    let pinyin: String
    let english: String
    let group: TopicGroup
}

/// The bundled **Topic List** — 125 fertilizer-business terms, split into six **Topic Groups**.
///
/// Unlike `HSKWordList` the list is hand-written, not drawn from an upstream repo: no public source
/// carries this vocabulary with the senses the student needs. See `TopicSOURCE.md` next to the JSON.
enum TopicWordList {
    static let all: [TopicEntry] = load()

    private static let byWord: [String: TopicEntry] = Dictionary(uniqueKeysWithValues: all.map { ($0.word, $0) })

    static func words(in group: TopicGroup) -> [TopicEntry] { all.filter { $0.group == group } }

    static func entry(for word: String) -> TopicEntry? { byWord[word] }

    /// The whole list's size: the denominator of the Topic List meter. The matching Swift test
    /// pins this at 125 so a change to the JSON cannot quietly move the number the student watches.
    static var total: Int { all.count }

    // MARK: - Loading

    /// The on-disk shape, kept short because it is repeated 125 times.
    private struct Row: Decodable {
        let w: String
        let p: String
        let e: String
        let g: String
    }

    private static func load() -> [TopicEntry] {
        guard let url = Bundle.main.url(forResource: "TopicWordList", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rows = try? JSONDecoder().decode([Row].self, from: data)
        else {
            // Same reasoning as `HSKWordList`: a missing bundle resource can only mean a broken
            // build, and an empty list would silently record nothing — the Topic List meter would
            // read 0 / 0, no row would show, and nothing would say the list was never loaded.
            fatalError("TopicWordList.json is missing or unreadable in the app bundle")
        }
        return rows.compactMap { row in
            guard let group = TopicGroup(rawValue: row.g) else { return nil }
            return TopicEntry(word: row.w, pinyin: row.p, english: row.e, group: group)
        }
    }
}
