import SwiftUI

/// How a **Seal** is written on screen. Kept apart from `Seal` so the rules stay free of text.
extension Seal {
    /// The characters cut into the seal itself. Chinese in both languages, like the 完 and 读 seals:
    /// a seal is a stamp, not a caption.
    var glyph: String {
        switch self {
        case .firstRead: "初读"
        case .tenArticles: "十篇"
        case .fiftyArticles: "五十篇"
        case .hundredArticles: "百篇"
        case .hundredWords: "百词"
        case .halfway: "半程"
        case .passedLevel: "过关"
        case .thousandWords: "千字文"
        case .nightReading: "夜读"
        case .askAboutAWord: "问字"
        case .farmer: "农家"
        case .farmOwner: "农场主"
        case .hundredDays: "百日"
        }
    }

    /// The seal's name under it, which follows the app language.
    var name: LocalizedStringKey {
        switch self {
        case .firstRead: "初读"
        case .tenArticles: "十篇"
        case .fiftyArticles: "五十篇"
        case .hundredArticles: "百篇"
        case .hundredWords: "百词"
        case .halfway: "半程"
        case .passedLevel: "过关"
        case .thousandWords: "千字文"
        case .nightReading: "夜读"
        case .askAboutAWord: "问字"
        case .farmer: "农家"
        case .farmOwner: "农场主"
        case .hundredDays: "百日"
        }
    }

    /// What earns it, in a line. For 百日 this says plainly that the days need not be in a row.
    var detail: LocalizedStringKey {
        switch self {
        case .firstRead: "第一篇文章"
        case .tenArticles: "读完 10 篇"
        case .fiftyArticles: "读完 50 篇"
        case .hundredArticles: "读完 100 篇"
        case .hundredWords: "认识 100 个词"
        case .halfway: "HSK 4 认识 300 个"
        case .passedLevel: "HSK 4 认识五分之四"
        case .thousandWords: "一共认识 1000 个词"
        case .nightReading: "晚上十点到凌晨五点读完一篇"
        case .askAboutAWord: "写下第一条词记"
        case .farmer: "认识 25 个农业词"
        case .farmOwner: "认识全部农业词"
        case .hundredDays: "100 个有完成的日子，不必连续"
        }
    }

    /// The tilt each seal is stamped at, a few degrees either way, fixed per seal so the book does not
    /// reshuffle itself every time it is opened.
    var tilt: Double {
        let tilts: [Double] = [-5, 3, -3, 5, -4, 4, -6, 2]
        return tilts[(Self.allCases.firstIndex(of: self) ?? 0) % tilts.count]
    }
}
