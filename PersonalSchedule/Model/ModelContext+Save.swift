import SwiftData

extension ModelContext {
    /// Saves, or undoes every unsaved change if saving fails, so the screens never show data that wasn't stored.
    func saveOrRollBack() throws {
        do {
            try save()
        } catch {
            rollback()
            throw error
        }
    }
}
