import Foundation
import SwiftData

/// Ticks Actions off and looks up what was ticked on a day.
@MainActor
struct CompletionLibrary {
    let context: ModelContext

    /// The Completions made on a day. Screens use this with `@Query` so they match `completion(for:on:)`.
    nonisolated static func descriptor(for day: Day) -> FetchDescriptor<Completion> {
        let number = day.number
        return FetchDescriptor<Completion>(predicate: #Predicate { $0.dayNumber == number })
    }

    /// Ticks an Action off for a day. An Action has at most one Completion per day: ticking again updates it.
    @discardableResult
    func tick(_ action: Action, on day: Day, minutes: Int?, note: String?) throws -> Completion {
        if let minutes, minutes < 0 { throw ActionError.negativeMinutes }
        if let existing = try completion(for: action, on: day) {
            existing.titleWhenTicked = action.title
            existing.category = action.category
            existing.minutes = minutes
            existing.note = note
            try context.saveOrRollBack()
            return existing
        }
        let completion = Completion(titleWhenTicked: action.title, day: day, minutes: minutes, note: note)
        context.insert(completion)
        completion.action = action
        completion.category = action.category
        try context.saveOrRollBack()
        return completion
    }

    /// Removes the day's Completion, so the Action is no longer done. Nothing happens if it wasn't ticked.
    func untick(_ action: Action, on day: Day) throws {
        guard let completion = try completion(for: action, on: day) else { return }
        context.delete(completion)
        try context.saveOrRollBack()
    }

    func completion(for action: Action, on day: Day) throws -> Completion? {
        try context.fetch(Self.descriptor(for: day))
            .first { $0.action?.persistentModelID == action.persistentModelID }
    }
}
