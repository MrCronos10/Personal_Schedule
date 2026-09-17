import SwiftData
import SwiftUI

@main
struct PersonalScheduleApp: App {
    private let container: ModelContainer
    @State private var language = LanguageSetting(defaults: .standard)

    init() {
        FontRegistry.registerBundledFonts()
        do {
            let container = try ScheduleStore.makeContainer()
            // Days written before the app pinned its calendar are moved before any screen reads them.
            // This must not be allowed to fail quietly: days left in the old calendar all sort after
            // today, so every screen would come up empty and a year of work would look deleted. Nothing
            // is actually lost when this stops the app, and the days are left as they were.
            try MainActor.assumeIsolated {
                let migration = DayMigration(context: container.mainContext)
                try migration.run()
            }
            self.container = container
        } catch {
            fatalError("Could not open the database: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(language)
        }
        .modelContainer(container)
    }
}
