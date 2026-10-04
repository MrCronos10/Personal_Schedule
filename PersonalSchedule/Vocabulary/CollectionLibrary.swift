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
    /// saw it.
    func cells(for level: HSKLevel) throws -> [CollectionCell] {
        let known = try knownHSKWords()
        let met = try metWords()
        return HSKWordList.words(at: level).map { entry in
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
