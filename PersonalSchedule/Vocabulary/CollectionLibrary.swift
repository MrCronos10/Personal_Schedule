import Foundation
import SwiftData

/// What one cell on the **Collection Grid** looks like. See CONTEXT.md and ADR 0009.
enum CellState: Equatable, Sendable {
    /// Never met: an empty cell.
    case notMet
    /// Met in an Article, by a Lookup or a Clean Sighting, and not yet Known.
    case seen
    case known
}

/// A cell that turned Known, with the Collection Grid section it lives in.
struct RecentCell: Equatable, Sendable {
    let cell: CollectionCell
    let section: CollectionSection

    var key: String { "\(section)-\(cell.word)" }
}

struct CollectionCell: Equatable, Identifiable, Sendable {
    let word: String
    let state: CellState
    var id: String { word }
}

/// The Collection Grid's one rule: which of three states each Word is in. Read-only: it never
/// writes progress, so a screen showing the grid can never change what the grid says.
@MainActor
struct CollectionLibrary {
    let context: ModelContext

    /// Every Word of one Level, in the Word List's own order so a Word stays where the student last
    /// saw it. `limit` builds only the first cells, for the cards that show a sliver.
    func cells(for level: HSKLevel, limit: Int? = nil) throws -> [CollectionCell] {
        try cells(for: level, limit: limit, known: knownHSKWords(), met: metWords())
    }

    /// All three sections from one read of the progress tables, rather than one read each.
    func allCells() throws -> (four: [CollectionCell], five: [CollectionCell], topic: [CollectionCell]) {
        let known = try knownHSKWords()
        let met = try metWords()
        return (
            try cells(for: .four, limit: nil, known: known, met: met),
            try cells(for: .five, limit: nil, known: known, met: met),
            try topicCells()
        )
    }

    private func cells(for level: HSKLevel, limit: Int?, known: Set<String>, met: Set<String>) -> [CollectionCell] {
        let entries = HSKWordList.words(at: level)
        return (limit.map { Array(entries.prefix($0)) } ?? entries).map { entry in
            let state: CellState = known.contains(entry.word) ? .known : (met.contains(entry.word) ? .seen : .notMet)
            return CollectionCell(word: entry.word, state: state)
        }
    }

    /// The Topic List, customs after the bundled terms. Hand-marked only (ADR 0007), so a Topic
    /// Word is Known or not met and never seen.
    func topicCells() throws -> [CollectionCell] {
        let known = Set(
            try context.fetch(FetchDescriptor<TopicWordProgress>(predicate: #Predicate { $0.isKnown })).map(\.word)
        )
        return try TopicLibrary(context: context).allWords().map {
            CollectionCell(word: $0.word, state: known.contains($0.word) ? .known : .notMet)
        }
    }

    /// The newest `limit` Known cells across both HSK Levels and the Topic List, oldest first, so the
    /// strip on Today reads left to right and ends on the latest. A Word taken back leaves it.
    func recentlyKnown(limit: Int = 20) throws -> [RecentCell] {
        var found: [(day: Int, cell: RecentCell)] = []
        let progress = try context.fetch(FetchDescriptor<WordProgress>(predicate: #Predicate { $0.isKnown }))
        for row in progress {
            guard let entry = HSKWordList.entry(for: row.word) else { continue }
            found.append((row.knownDayNumber ?? 0, RecentCell(
                cell: CollectionCell(word: row.word, state: .known),
                section: entry.level == .four ? .four : .five
            )))
        }
        let topicKnown = try context.fetch(FetchDescriptor<TopicWordProgress>(predicate: #Predicate { $0.isKnown }))
        let topicWords = Set(try TopicLibrary(context: context).allWords().map(\.word))
        for row in topicKnown where topicWords.contains(row.word) {
            found.append((row.knownDayNumber ?? 0, RecentCell(
                cell: CollectionCell(word: row.word, state: .known), section: .topic
            )))
        }
        return found
            .sorted { $0.day != $1.day ? $0.day < $1.day : $0.cell.cell.word < $1.cell.cell.word }
            .suffix(limit)
            .map(\.cell)
    }

    /// The Words that are Known now and were not the last time the grid was looked at: these get
    /// the one-second glow on the next visit.
    nonisolated static func freshlyKnown(current: Set<String>, lastSeen: Set<String>) -> Set<String> {
        current.subtracting(lastSeen)
    }

    private func knownHSKWords() throws -> Set<String> {
        Set(try context.fetch(FetchDescriptor<WordProgress>(predicate: #Predicate { $0.isKnown })).map(\.word))
    }

    private func metWords() throws -> Set<String> {
        let looked = try context.fetch(FetchDescriptor<WordLookup>()).map(\.word)
        let sighted = try context.fetch(FetchDescriptor<CleanSighting>()).map(\.word)
        return Set(looked).union(sighted)
    }
}
