import Foundation

/// One **Seal** in the Seal Book (ADR 0010): a red stamp earned once, for something the student
/// really did, and kept for ever.
///
/// Declared in the order the Seal Book shows them. Nothing here counts a run of days, scores, ranks
/// or compares: a seal is a fact about the reading and the words, and never about what is late.
///
/// 识途 (read a photographed menu or sign) is in the brief but is not here: the model does not record
/// where an Article came from, and a seal may not need new tracking beyond its earned day.
enum Seal: String, CaseIterable, Identifiable {
    // Articles finished with 读完
    case firstRead, tenArticles, fiftyArticles, hundredArticles
    // Words Known, across HSK 4, HSK 5 and the Topic List
    case hundredWords, halfway, passedLevel, thousandWords
    // How and when the student reads
    case nightReading, askAboutAWord
    // 农业词
    case farmer, farmOwner
    // Days with any Completion — not in a row
    case hundredDays

    var id: String { rawValue }

    /// What the seal counts up to. For 夜读 it is one reading finished after ten at night.
    var target: Int {
        switch self {
        case .firstRead: 1
        case .tenArticles: 10
        case .fiftyArticles: 50
        case .hundredArticles: 100
        case .hundredWords: 100
        case .halfway: 300
        // Four fifths of HSK 4 (480 of 600): the same line `LevelProgress.isPassed` draws.
        case .passedLevel: (HSKLevel.four.total * 4 + 4) / 5
        case .thousandWords: 1000
        case .nightReading: 1
        case .askAboutAWord: 1
        case .farmer: 25
        case .farmOwner: TopicWordList.total
        case .hundredDays: 100
        }
    }

    /// The three seals ringed in brass: passing HSK 4, a thousand words, and the whole Topic List.
    var isRare: Bool {
        switch self {
        case .passedLevel, .thousandWords, .farmOwner: true
        default: false
        }
    }

    /// A hidden seal shows as "？" until it is earned. None are hidden yet: the brief asks for one or
    /// two but does not say which, so that is the student's to choose.
    var isHidden: Bool { false }
}
