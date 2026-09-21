import Foundation
import SwiftData

/// Creates the app's database. iCloud stays off until the Apple Developer Program is paid.
enum ScheduleStore {
    static let schema = Schema([
        Category.self, Action.self, Completion.self, Pause.self,
        Article.self, WordLookup.self, WordProgress.self,
    ])

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: configuration)
    }

    static func makeContainer(url: URL) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            url: url,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
