import SwiftData
import SwiftUI

@main
struct PersonalScheduleApp: App {
    private let container: ModelContainer

    init() {
        FontRegistry.registerBundledFonts()
        do {
            container = try ScheduleStore.makeContainer()
        } catch {
            fatalError("Could not open the database: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
