import Foundation
import SwiftData

enum ActionError: Error, Equatable {
    case emptyTitle
    case archivedCategory
    case negativeMinutes
    case tickedAction
    case noRepeatDays
    case routineCantBeDeleted
    case notARoutine
    case notAOneTimeAction
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
        guard !action.isRoutine else { throw ActionError.notAOneTimeAction }
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
        guard action.isRoutine else { throw ActionError.notARoutine }
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
        if category.persistentModelID != existing?.persistentModelID {
            guard !category.isArchived else { throw ActionError.archivedCategory }
        }
        if let defaultMinutes, defaultMinutes < 0 { throw ActionError.negativeMinutes }
        return trimmed
    }

    /// Every Action, oldest first. Screens use this with `@Query` and then `routines(_:)`, so the list they
    /// show is the one `isRoutine` defines rather than a second idea of what a Routine is.
    nonisolated static var oldestFirstDescriptor: FetchDescriptor<Action> {
        FetchDescriptor<Action>(sortBy: [SortDescriptor(\.createdAt)])
    }

    /// The Routines among some Actions, in the order they were given.
    static func routines(_ actions: [Action]) -> [Action] {
        actions.filter(\.isRoutine)
    }

    /// Stops a Routine from a day onwards. Routines are paused, never deleted (CONTEXT.md): its earlier days
    /// and their Completions stay exactly as they were, and it can be resumed later as the same Routine.
    ///
    /// Pausing one that is already paused changes nothing, so a second tap can't open a second pause.
    @discardableResult
    func pause(_ action: Action, from day: Day) throws -> Pause {
        guard action.isRoutine else { throw ActionError.notARoutine }
        if let open = (action.pauses ?? []).first(where: { !$0.hasEnded }) {
            return open
        }
        let pause = Pause(startDay: day)
        context.insert(pause)
        pause.action = action
        try context.saveOrRollBack()
        return pause
    }

    /// Starts a paused Routine again from a day onwards, as the same Routine. The days it was stopped for
    /// keep their place: they show nothing and are never Missed.
    ///
    /// Resuming one that isn't paused changes nothing.
    func resume(_ action: Action, on day: Day) throws {
        guard let open = (action.pauses ?? []).first(where: { !$0.hasEnded }) else { return }
        open.endDayNumber = day.number
        try context.saveOrRollBack()
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
