import Foundation
import SwiftData

enum ArticleError: Error, Equatable {
    case emptyText
}

/// Imports, lists and archives the student's **Articles**.
@MainActor
struct ArticleLibrary {
    let context: ModelContext

    /// How long a title may run before it is cut. A title names an Article in a list; the text it
    /// was taken from is never shortened.
    static let titleLimit = 30

    /// The reading list: unarchived Articles, newest first.
    nonisolated static var readingDescriptor: FetchDescriptor<Article> {
        FetchDescriptor<Article>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.importedDayNumber, order: .reverse), SortDescriptor(\.title)]
        )
    }

    nonisolated static var archivedDescriptor: FetchDescriptor<Article> {
        FetchDescriptor<Article>(
            predicate: #Predicate { $0.isArchived },
            sortBy: [SortDescriptor(\.importedDayNumber, order: .reverse), SortDescriptor(\.title)]
        )
    }

    /// The title an Article gets: its first line with anything in it, cut to `titleLimit`.
    ///
    /// A pasted 微信 article often begins with blank lines, so the first line that is only spaces is
    /// not the title. Returns nil when there is nothing to name the Article by at all.
    static func title(from text: String) -> String? {
        let firstLine = text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .lazy
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
        guard let firstLine else { return nil }
        guard firstLine.count > titleLimit else { return firstLine }
        return String(firstLine.prefix(titleLimit)) + "…"
    }

    @discardableResult
    func add(
        text: String,
        source: String? = nil,
        importedDay: Day = Day.today()
    ) throws -> Article {
        guard let title = Self.title(from: text) else { throw ArticleError.emptyText }
        let trimmedSource = source?.trimmingCharacters(in: .whitespacesAndNewlines)
        let article = Article(
            title: title,
            text: text,
            // An empty 来源 is no 来源, not an empty string to render as a blank line.
            source: (trimmedSource?.isEmpty ?? true) ? nil : trimmedSource,
            importedDay: importedDay
        )
        context.insert(article)
        try context.saveOrRollBack()
        return article
    }

    /// Takes an Article out of the reading list. Articles are archived, never deleted: the Clean
    /// Sightings it has banked must never be taken back by tidying up (ADR 0005).
    func archive(_ article: Article) throws {
        article.isArchived = true
        try context.saveOrRollBack()
    }

    func restore(_ article: Article) throws {
        article.isArchived = false
        try context.saveOrRollBack()
    }

    func reading() throws -> [Article] {
        try context.fetch(Self.readingDescriptor)
    }

    func archived() throws -> [Article] {
        try context.fetch(Self.archivedDescriptor)
    }
}
