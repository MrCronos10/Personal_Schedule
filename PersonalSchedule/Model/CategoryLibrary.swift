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
        try saveOrRollBack()
        return category
    }

    func rename(_ category: Category, to newName: String) throws {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CategoryError.emptyName }
        category.name = trimmed
        try saveOrRollBack()
    }

    /// Hides a Category from the active list. Categories are archived, never deleted, so their history stays.
    func archive(_ category: Category) throws {
        category.isArchived = true
        try saveOrRollBack()
    }

    /// Brings an Archived Category back to the active list, in its original place.
    func restore(_ category: Category) throws {
        category.isArchived = false
        try saveOrRollBack()
    }

    /// Archived Categories, oldest first. Screens use this with `@Query` so they list the same Categories as `archived()`.
    nonisolated static var archivedDescriptor: FetchDescriptor<Category> {
        FetchDescriptor<Category>(
            predicate: #Predicate { $0.isArchived },
            sortBy: [SortDescriptor(\.createdAt)]
        )
    }

    func archived() throws -> [Category] {
        try context.fetch(Self.archivedDescriptor)
    }

    private func saveOrRollBack() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func active() throws -> [Category] {
        try context.fetch(Self.activeDescriptor)
    }
}
