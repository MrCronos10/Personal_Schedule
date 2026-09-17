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
        let trimmed = try checked(title: title, category: category, keeping: nil, defaultMinutes: defaultMinutes)
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
        let trimmed = try checked(title: title, category: category, keeping: nil, defaultMinutes: defaultMinutes)
        guard !repeatDays.isEmpty else { throw ActionError.noRepeatDays }
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

    /// Changes a One-time Action. Days already ticked keep the title and Category copied into their
    /// Completion (ADR 0002), and a ticked Action stays on the day it was ticked whatever day it now says.
    ///
    /// An Action keeps its kind: this never turns a Routine into a One-time Action.
    func updateOneTime(
        _ action: Action,
        title: String,
        category: Category,
        day: Day,
        time: TimeOfDay?,
        defaultMinutes: Int?
    ) throws {
        let trimmed = try checked(
            title: title,
            category: category,
            keeping: action.category,
            defaultMinutes: defaultMinutes
        )
        action.title = trimmed
        action.category = category
        action.plannedDayNumber = day.number
        action.timeMinutes = time?.minutesSinceMidnight
        action.defaultMinutes = defaultMinutes
        try context.saveOrRollBack()
    }

    /// Changes a Routine. Days already ticked keep the title and Category copied into their Completion
    /// (ADR 0002), so only the days that aren't ticked show the new values.
    func updateRoutine(
        _ action: Action,
        title: String,
        category: Category,
        repeatDays: RepeatDays,
        startDay: Day,
        time: TimeOfDay?,
        defaultMinutes: Int?
    ) throws {
        let trimmed = try checked(
            title: title,
            category: category,
            keeping: action.category,
            defaultMinutes: defaultMinutes
        )
        guard !repeatDays.isEmpty else { throw ActionError.noRepeatDays }
        action.title = trimmed
        action.category = category
        action.repeatWeekdayMask = repeatDays.mask
        action.startDayNumber = startDay.number
        action.plannedDayNumber = startDay.number
        action.timeMinutes = time?.minutesSinceMidnight
        action.defaultMinutes = defaultMinutes
        try context.saveOrRollBack()
    }

    /// What every Action needs, whether it is being added or changed: a title with something in it, a
    /// Category the student can still choose, and minutes that aren't negative.
    ///
    /// `keeping` is the Category the Action already has. Keeping that one is allowed even after it has been
    /// archived, because nothing is deleted in this app and an Action outlives its Category's active life.
    /// Moving an Action into any other archived Category is still refused.
    private func checked(
        title: String,
        category: Category,
        keeping existing: Category?,
        defaultMinutes: Int?
    ) throws -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ActionError.emptyTitle }
        if category !== existing {
            guard !category.isArchived else { throw ActionError.archivedCategory }
        }
        if let defaultMinutes, defaultMinutes < 0 { throw ActionError.negativeMinutes }
        return trimmed
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
