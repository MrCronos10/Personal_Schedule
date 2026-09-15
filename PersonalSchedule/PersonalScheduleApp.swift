import SwiftData
import SwiftUI

@main
struct PersonalScheduleApp: App {
    private let container: ModelContainer
    @State private var language = LanguageSetting(defaults: .standard)

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
                .environment(language)
        }
        .modelContainer(container)
    }
}
