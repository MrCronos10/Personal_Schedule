import Foundation
import SwiftData

/// What one Category did in one week: the minutes its Completions add up to, and how many there were.
///
/// A Category with a Weekly Target is shown against it; one without is shown as a Completion Count, which
/// is why the count is kept even when the minutes are what's being aimed at. See CONTEXT.md.
struct WeekProgress {
    let category: Category
    let minutes: Int
    let completions: Int

    init(category: Category, from completions: [Completion]) {
        self.category = category
        minutes = completions.reduce(0) { $0 + ($1.minutes ?? 0) }
        self.completions = completions.count
    }

    var weeklyTargetMinutes: Int? { category.weeklyTargetMinutes }
    var isArchived: Bool { category.isArchived }
}

/// Ticks Actions off and looks up what was ticked on a day.
@MainActor
struct CompletionLibrary {
    let context: ModelContext

    /// Every Completion, newest last. Screens use this with `@Query` and hand the result to the rules below,
    /// so a screen and a test work out a week the same way instead of each filtering for itself.
    nonisolated static var allDescriptor: FetchDescriptor<Completion> {
        FetchDescriptor<Completion>(sortBy: [SortDescriptor(\.dayNumber)])
    }

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
            // The title and Category copies are left as they were: this is the student correcting what a
            // finished day recorded, not doing it again, and a day already ticked must not be re-filed by
            // an edit made to the Action afterwards (ADR 0002). Unticking deletes the Completion, so a day
            // genuinely done again takes its copies fresh through the branch below.
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

    /// One Category's week. Completions count toward the Category they copied when they were ticked, so an
    /// Action moved to another Category later leaves its finished days where they were (ADR 0002).
    func progress(for category: Category, in week: Week) throws -> WeekProgress {
        Self.progress(for: category, in: week, completions: try context.fetch(Self.allDescriptor))
    }

    /// Every Category the Progress Tracker shows for the week holding that day, in creation order.
    func week(containing day: Day) throws -> [WeekProgress] {
        Self.week(
            Week(containing: day),
            categories: try context.fetch(CategoryLibrary.allDescriptor),
            completions: try context.fetch(Self.allDescriptor)
        )
    }

    // MARK: - The Notes List

    /// Every Completion carrying a **Note**, newest first.
    ///
    /// A Completion with no Note, or one that is only spaces, is not listed: this is the Notes List,
    /// not a list of everything done. Kept apart from the database so the screen and the tests run
    /// the same rule.
    static func notes(_ completions: [Completion]) -> [Completion] {
        completions
            .filter { !($0.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            // A Day has no time in it, so two Notes written on one day need `createdAt` to settle
            // their order, or they come back however the store feels like that morning.
            .sorted {
                $0.dayNumber == $1.dayNumber
                    ? $0.createdAt > $1.createdAt
                    : $0.dayNumber > $1.dayNumber
            }
    }

    /// The Notes matching what the student typed.
    ///
    /// Matches the Note itself, the title the Completion **copied when it was ticked**, and the
    /// Category it counted toward **by its current name** — so 龙井, 读一篇文章 and 中文 all find the
    /// same row. Empty text matches everything, because a search that hasn't been typed yet isn't a
    /// filter.
    ///
    /// The title is a copy, so renaming an Action never moves a finished day out from under the
    /// words used to look for it (ADR 0002). The Category name is **not** a copy, and that is
    /// deliberate: a rename corrects what one Category is called rather than making it a different
    /// Category, so past Notes follow it, exactly as the Progress Tracker's rows do.
    static func search(_ text: String, in completions: [Completion]) -> [Completion] {
        let needle = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return completions }
        return completions.filter { completion in
            [completion.note, completion.titleWhenTicked, completion.category?.name]
                .compactMap { $0 }
                // Chinese has no case; the Latin that ends up in a Note does.
                .contains { $0.localizedCaseInsensitiveContains(needle) }
        }
    }

    /// The rule the Progress Tracker is drawn from, kept apart from the database so the screen and the
    /// tests run the same one.
    ///
    /// Active Categories are always listed, at zero if nothing was ticked. An Archived Category is listed
    /// only in a week it has Completions, so work already done is never hidden by a later decision, and it
    /// drops off once that week has passed.
    static func week(_ week: Week, categories: [Category], completions: [Completion]) -> [WeekProgress] {
        var byCategory: [PersistentIdentifier: [Completion]] = [:]
        for completion in completions where week.contains(completion.day) {
            guard let id = completion.category?.persistentModelID else { continue }
            byCategory[id, default: []].append(completion)
        }
        return categories.compactMap { category in
            let mine = byCategory[category.persistentModelID] ?? []
            guard !category.isArchived || !mine.isEmpty else { return nil }
            return WeekProgress(category: category, from: mine)
        }
    }

    static func progress(for category: Category, in week: Week, completions: [Completion]) -> WeekProgress {
        let mine = completions.filter {
            week.contains($0.day) && $0.category?.persistentModelID == category.persistentModelID
        }
        return WeekProgress(category: category, from: mine)
    }
}
