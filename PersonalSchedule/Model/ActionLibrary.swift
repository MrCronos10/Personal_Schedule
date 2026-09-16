import Foundation
import SwiftData

enum ActionError: Error, Equatable {
    case emptyTitle
    case archivedCategory
    case negativeMinutes
    case tickedAction
    case noRepeatDays
    case routineCantBeDeleted
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

    /// Adds a Routine, which repeats on its repeat days from its start day. Each day it appears is ticked
    /// separately, with its own Completion.
    @discardableResult
    func addRoutine(
        title: String,
        category: Category,
        repeatDays: RepeatDays,
        startDay: Day,
        time: TimeOfDay? = nil,
        defaultMinutes: Int? = nil
    ) throws -> Action {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ActionError.emptyTitle }
        guard !category.isArchived else { throw ActionError.archivedCategory }
        guard !repeatDays.isEmpty else { throw ActionError.noRepeatDays }
        if let defaultMinutes, defaultMinutes < 0 { throw ActionError.negativeMinutes }
        let action = Action(
            title: trimmed,
            repeatDays: repeatDays,
            startDay: startDay,
            time: time,
            defaultMinutes: defaultMinutes
        )
        context.insert(action)
        action.category = category
        try context.saveOrRollBack()
        return action
    }

    /// Deletes a One-time Action the student isn't going to do.
    ///
    /// A Routine is paused, never deleted (CONTEXT.md), and a ticked Action is history that keeps its own
    /// Completion (ADR 0002). Both are refused here, so the rule holds even if a screen forgets it.
    func delete(_ action: Action) throws {
        guard !action.isRoutine else { throw ActionError.routineCantBeDeleted }
        guard (action.completions ?? []).isEmpty else { throw ActionError.tickedAction }
        context.delete(action)
        try context.saveOrRollBack()
    }
}
