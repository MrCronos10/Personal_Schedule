import Foundation
import SwiftData

/// One sitting with one **Article**: how long it was on screen, and which **Action** that time
/// should be ticked against. See CONTEXT.md.
///
/// The minutes are not a record. They live with the screen and are handed to the Tick sheet, which
/// saves an ordinary **Completion** — so the Progress Tracker and **Weekly Targets** need no new
/// code at all. If the app is killed mid-article the minutes are gone and the student types them in.
enum ReadingSession {
    /// The minutes a session is worth. Rounded to the nearest, never below one: the student did
    /// read it, and a session worth nothing would be a lie in the other direction.
    static func minutes(forSeconds seconds: TimeInterval) -> Int {
        max(1, Int((seconds / 60).rounded()))
    }

    /// Today's unticked **Actions**, in the order 读完 offers them: the Category most of the
    /// student's **Completions** have come from first, since that is where reading almost always
    /// belongs, then everything else in the order the day already has.
    ///
    /// The list may be empty, and that is a fine answer — 不记录 is always there. The app never
    /// creates an Action by itself: an Action the student can't edit would break the rule that they
    /// own their own Categories and Actions.
    static func offer(
        among actions: [Action],
        completions: [Completion],
        on day: Day
    ) -> [Action] {
        let tickedToday = Set(
            completions
                .filter { $0.dayNumber == day.number }
                .compactMap { $0.action?.persistentModelID }
        )
        let open = actions.filter { !tickedToday.contains($0.persistentModelID) }
        let usual = usualCategory(completions: completions)

        // Partitioned, not sorted: `sorted(by:)` is not guaranteed stable, and "everything else in
        // the order the day already has" is exactly what an unstable sort would scramble.
        let isUsual = { (action: Action) in action.category?.persistentModelID == usual }
        return open.filter(isUsual) + open.filter { !isUsual($0) }
    }

    /// Where the student's Completions have actually been coming from. Counted from the copies the
    /// Completions kept, so a Category renamed or an Action moved doesn't rewrite history (ADR 0002).
    private static func usualCategory(completions: [Completion]) -> PersistentIdentifier? {
        var byCategory: [PersistentIdentifier: Int] = [:]
        for completion in completions {
            guard let id = completion.category?.persistentModelID else { continue }
            byCategory[id, default: 0] += 1
        }
        return byCategory.max { $0.value < $1.value }?.key
    }
}
