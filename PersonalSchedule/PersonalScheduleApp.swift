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
                // Cheap — a handful of fetches and integer comparisons, no tokenization — and it has
                // to finish before the first screen can read `hasCongratulated`, or a Level Passed
                // before this feature existed would fire its stamp as though it just happened.
                try? VocabularyLibrary(context: container.mainContext).backfillLevelCongratulations()
            }
            self.container = container
            // Deliberately not run inline above, unlike the backfill next to it: this one tokenizes
            // every previously imported Article's full text, and none of that is needed before the
            // first frame draws — `Article.readability(known:)` already falls back to computing it on
            // the spot for an Article with no cache yet (ticket 04). Running it in init() would have
            // the whole reading list re-tokenized before the student ever sees a screen.
            Task { @MainActor in
                try? ArticleLibrary(context: container.mainContext).backfillMeasuredWords()
            }
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
