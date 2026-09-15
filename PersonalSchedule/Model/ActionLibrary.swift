import Foundation
import SwiftData

enum ActionError: Error, Equatable {
    case emptyTitle
    case archivedCategory
    case negativeMinutes
}

/// Creates the student's Actions.
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
}
