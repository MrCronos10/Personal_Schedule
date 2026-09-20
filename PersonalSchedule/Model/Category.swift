import Foundation
import SwiftData

/// A group that Actions belong to, such as 中文 or 健康. See CONTEXT.md.
///
/// Every field has a default so iCloud sync can be switched on later.
@Model
final class Category {
    var name: String = ""
    var isArchived: Bool = false
    var createdAt: Date = Date()

    /// The Weekly Target: minutes aimed at in this Category each week. Empty means no Weekly Target,
    /// and the Progress Tracker shows a Completion Count instead. See CONTEXT.md.
    var weeklyTargetMinutes: Int?

    @Relationship(deleteRule: .nullify, inverse: \Action.category)
    var actions: [Action]? = []

    @Relationship(deleteRule: .nullify, inverse: \Completion.category)
    var completions: [Completion]? = []

    init(name: String, createdAt: Date = Date()) {
        self.name = name
        self.createdAt = createdAt
    }
}
