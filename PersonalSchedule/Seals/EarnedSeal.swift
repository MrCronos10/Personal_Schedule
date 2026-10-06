import Foundation
import SwiftData

/// The record that a **Seal** was earned, and on which day (ADR 0010).
///
/// This is the only thing the Seal Book stores. Every rule that earns a seal reads facts the model
/// already holds; the row exists so an earned seal is kept for ever even when what earned it later
/// changes — a cleared Word Note, a Word taken back with 其实不认识 — the same reason a Completion
/// keeps its own copy of the title and Category (ADR 0002). Nothing deletes or edits one.
///
/// Every field has a default and none is unique, so iCloud sync can be switched on later. Two rows
/// for one seal are therefore possible, and readers treat the earliest as the real one.
@Model
final class EarnedSeal {
    /// `Seal.rawValue`: a stable key, not the Chinese name, so renaming a seal never orphans a row.
    var sealKey: String = ""
    var earnedDayNumber: Int = 0

    var earnedDay: Day { Day(number: earnedDayNumber) }

    init(sealKey: String, earnedDay: Day) {
        self.sealKey = sealKey
        self.earnedDayNumber = earnedDay.number
    }
}
