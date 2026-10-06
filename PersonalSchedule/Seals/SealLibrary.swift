import Foundation
import SwiftData

/// When each **Seal** is earned, and what has been earned (ADR 0010).
///
/// Every rule reads facts the model already holds — Articles banked, Words Known, Word Notes, days
/// with a Completion — so the only thing stored is `EarnedSeal`'s day. Evaluating only ever adds: a
/// seal that was earned stays earned, whatever its source later does.
@MainActor
struct SealLibrary {
    let context: ModelContext

    /// Where one seal stands: how far along it is, and the day it was earned if it has been.
    struct Progress: Equatable, Identifiable {
        let seal: Seal
        let current: Int
        let earnedDay: Day?

        var id: String { seal.id }
        var target: Int { seal.target }
        var isEarned: Bool { earnedDay != nil }
        /// 0 to 1. An earned seal is full, however its source has moved since.
        var fraction: Double { isEarned ? 1 : min(1, Double(current) / Double(max(1, target))) }
    }

    // MARK: - What has been earned

    /// Every seal earned, with the day. Two rows for one seal (possible, since nothing is unique)
    /// resolve to the earlier day.
    func earned() throws -> [Seal: Day] {
        var result: [Seal: Day] = [:]
        for row in try context.fetch(FetchDescriptor<EarnedSeal>()) {
            guard let seal = Seal(rawValue: row.sealKey) else { continue }
            if let existing = result[seal], existing.number <= row.earnedDayNumber { continue }
            result[seal] = row.earnedDay
        }
        return result
    }

    // MARK: - Earning

    /// Earns every seal whose rule is now met and that is not already earned, and returns those, in
    /// the order the book shows them.
    ///
    /// `finishedReadingAt` is set only by the moment an Article is finished: 夜读 is about *when a
    /// reading ended*, so opening the Seal Book late at night, with no reading just finished, earns
    /// nothing.
    @discardableResult
    func evaluate(
        on day: Day,
        finishedReadingAt: Date? = nil,
        calendar: Calendar = .current
    ) throws -> [Seal] {
        let alreadyEarned = try earned()
        let facts = try Facts(context: context)

        let newlyEarned = Seal.allCases.filter { seal in
            guard alreadyEarned[seal] == nil else { return false }
            if seal == .nightReading {
                guard let finishedReadingAt else { return false }
                return Self.isNight(hour: calendar.component(.hour, from: finishedReadingAt))
            }
            return facts.count(for: seal) >= seal.target
        }
        guard !newlyEarned.isEmpty else { return [] }

        for seal in newlyEarned {
            context.insert(EarnedSeal(sealKey: seal.rawValue, earnedDay: day))
        }
        try context.saveOrRollBack()
        return newlyEarned
    }

    /// 夜读 is a reading finished from ten at night until five in the morning. The night runs past
    /// midnight, so a reading that ends at 1 a.m. counts.
    static let nightStartsAtHour = 22
    static let nightEndsBeforeHour = 5

    static func isNight(hour: Int) -> Bool {
        hour >= nightStartsAtHour || hour < nightEndsBeforeHour
    }

    // MARK: - The book

    /// Every seal, in the order the book shows them, each with how far along it is.
    func progress() throws -> [Progress] {
        let earnedDays = try earned()
        let facts = try Facts(context: context)
        return Seal.allCases.map { seal in
            Progress(
                seal: seal,
                current: min(facts.count(for: seal), seal.target),
                earnedDay: earnedDays[seal]
            )
        }
    }

    /// 下一枚: the seal not yet earned that is furthest along. Hidden seals are never offered, and
    /// when two are level the one earlier in the book comes first.
    func next() throws -> Progress? {
        try progress()
            .filter { !$0.isEarned && !$0.seal.isHidden }
            .reduce(nil as Progress?) { best, candidate in
                guard let best else { return candidate }
                return candidate.fraction > best.fraction ? candidate : best
            }
    }

    // MARK: - The facts

    /// The handful of counts every rule reads, fetched once per call rather than once per seal.
    private struct Facts {
        var articlesBanked = 0
        var fourKnown = 0
        var fiveKnown = 0
        var topicKnown = 0
        var starterTopicKnown = 0
        var wordNotes = 0
        var completionDays = 0

        @MainActor
        init(context: ModelContext) throws {
            articlesBanked = try context.fetchCount(
                FetchDescriptor<Article>(predicate: #Predicate { $0.isBanked })
            )

            // Sets of words, not row counts: no field is unique, so a Word with two rows is one Word.
            let knownRows = try context.fetch(
                FetchDescriptor<WordProgress>(predicate: #Predicate { $0.isKnown })
            )
            fourKnown = Set(knownRows.filter { $0.levelValue == HSKLevel.four.rawValue }.map(\.word)).count
            fiveKnown = Set(knownRows.filter { $0.levelValue == HSKLevel.five.rawValue }.map(\.word)).count

            let topicWords = Set(
                try context.fetch(
                    FetchDescriptor<TopicWordProgress>(predicate: #Predicate { $0.isKnown })
                ).map(\.word)
            )
            topicKnown = topicWords.count
            // Only the starter terms: a Custom Topic Word does not stand in for one of them.
            starterTopicKnown = TopicWordList.all.filter { topicWords.contains($0.word) }.count

            wordNotes = try context.fetchCount(
                FetchDescriptor<WordProgress>(predicate: #Predicate { $0.noteText != nil })
            )

            var completions = FetchDescriptor<Completion>()
            completions.propertiesToFetch = [\.dayNumber]
            completionDays = Set(try context.fetch(completions).map(\.dayNumber)).count
        }

        var totalKnown: Int { fourKnown + fiveKnown + topicKnown }

        /// How far along a seal is. 夜读 has no count: it happens at the moment a reading ends.
        func count(for seal: Seal) -> Int {
            switch seal {
            case .firstRead, .tenArticles, .fiftyArticles, .hundredArticles: articlesBanked
            case .hundredWords, .thousandWords: totalKnown
            case .halfway, .passedLevel: fourKnown
            case .nightReading: 0
            case .askAboutAWord: wordNotes
            case .farmer: topicKnown
            case .farmOwner: starterTopicKnown
            case .hundredDays: completionDays
            }
        }
    }
}
