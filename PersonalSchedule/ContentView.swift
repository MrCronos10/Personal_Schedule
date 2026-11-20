import SwiftData
import SwiftUI
import Combine
import UserNotifications

/// The four tabs (ADR 0009). Settings and Notes open from Today; the Reading Coach lives inside an
/// Article.
enum AppTab: CaseIterable, Hashable {
    case today, reading, vocabulary, progress

    /// The Chinese text, which is also its translation key.
    var title: String {
        switch self {
        case .today: "今天"
        case .reading: "阅读"
        case .vocabulary: "词"
        case .progress: "进度"
        }
    }

    var symbol: String {
        switch self {
        case .today: "calendar"
        case .reading: "book"
        case .vocabulary: "character.book.closed"
        case .progress: "square.grid.3x3"
        }
    }
}

struct ContentView: View {
    @Environment(LanguageSetting.self) private var language
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var router = AppRouter()

    init() {
        // As early as a view can: iOS wants the delegate before launch finishes, or a tap that
        // cold-launches the app can arrive with nobody listening. Setting it again is harmless.
        UNUserNotificationCenter.current().delegate = ReminderScheduler.shared
    }

    var body: some View {
        TabView(selection: $router.tab) {
            TodayView()
                .tabItem { Label(LocalizedStringKey(AppTab.today.title), systemImage: AppTab.today.symbol) }
                .tag(AppTab.today)
            ReadingView()
                .tabItem { Label(LocalizedStringKey(AppTab.reading.title), systemImage: AppTab.reading.symbol) }
                .tag(AppTab.reading)
            VocabularyView()
                .tabItem { Label(LocalizedStringKey(AppTab.vocabulary.title), systemImage: AppTab.vocabulary.symbol) }
                .tag(AppTab.vocabulary)
            ProgressTrackerView()
                .tabItem { Label(LocalizedStringKey(AppTab.progress.title), systemImage: AppTab.progress.symbol) }
                .tag(AppTab.progress)
        }
        .environment(router)
        .tint(Theme.red)
        .toolbarBackground(Theme.paper, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .environment(\.locale, language.current.locale)
        // Reminders: refreshed when the app opens or comes back, and after every save, which covers an
        // Action or Completion changing anywhere. Tapping one opens 今天.
        .task {
            let scheduler = ReminderScheduler.shared
            scheduler.onOpen = { router.tab = .today }
            scheduler.refresh(context)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { ReminderScheduler.shared.refresh(context) }
        }
        // Saves can be posted from any thread; the scheduler is main-actor only.
        .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave).receive(on: RunLoop.main)) { _ in
            ReminderScheduler.shared.refresh(context)
        }
    }
}

/// A screen shown as a sheet that was a tab before: the screen itself, with 完成 to close it.
struct SheetShell<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .overlay(alignment: .topTrailing) {
                Button("完成") { dismiss() }
                    .buttonStyle(MiniButtonStyle())
                    .padding(.top, 14)
                    .padding(.trailing, 16)
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
        .environment(LanguageSetting(defaults: .standard))
}
