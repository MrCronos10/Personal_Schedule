import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(LanguageSetting.self) private var language

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("今天", systemImage: "calendar") }
            ProgressTrackerView()
                .tabItem { Label("进度", systemImage: "chart.bar") }
            SettingsView()
                .tabItem { Label("设置", systemImage: "slider.horizontal.3") }
        }
        .tint(Theme.red)
        .toolbarBackground(Theme.paper, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .environment(\.locale, language.current.locale)
    }
}

#Preview {
    ContentView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
        .environment(LanguageSetting(defaults: .standard))
}
