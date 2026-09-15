import Foundation
import SwiftData

enum CategoryError: Error, Equatable {
    case emptyName
}

/// Adds and lists the student's Categories.
@MainActor
struct CategoryLibrary {
    let context: ModelContext

    /// Active Categories, oldest first. Screens use this with `@Query` so they list the same Categories as `active()`.
    nonisolated static var activeDescriptor: FetchDescriptor<Category> {
        FetchDescriptor<Category>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.createdAt)]
        )
    }

    @discardableResult
    func add(named name: String) throws -> Category {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CategoryError.emptyName }
        let category = Category(name: trimmed)
        context.insert(category)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        return category
    }

    func active() throws -> [Category] {
        try context.fetch(Self.activeDescriptor)
    }
}
