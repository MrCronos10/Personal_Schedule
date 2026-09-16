import Foundation
import SwiftData

enum ActionError: Error, Equatable {
    case emptyTitle
    case archivedCategory
    case negativeMinutes
    case tickedAction
}

/// Creates and deletes the student's Actions.
@MainActor
struct ActionLibrary {
    let context: ModelContext

    @discardableResult
    func addOneTime(
        title: String,
        category: Category,
        day: Day,
        time: TimeOfDay? = nil,
        defaultMinutes: Int? = nil
    ) throws -> Action {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ActionError.emptyTitle }
        guard !category.isArchived else { throw ActionError.archivedCategory }
        if let defaultMinutes, defaultMinutes < 0 { throw ActionError.negativeMinutes }
        let action = Action(title: trimmed, plannedDay: day, time: time, defaultMinutes: defaultMinutes)
        context.insert(action)
        action.category = category
        try context.saveOrRollBack()
        return action
    }

    /// Deletes a One-time Action the student isn't going to do. A ticked Action is history and keeps its
    /// Completion, so deleting it is refused (ADR 0002).
    func delete(_ action: Action) throws {
        guard (action.completions ?? []).isEmpty else { throw ActionError.tickedAction }
        context.delete(action)
        try context.saveOrRollBack()
    }
}
