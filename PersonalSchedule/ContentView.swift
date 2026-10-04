import SwiftData
import SwiftUI

/// The four tabs (ADR 0009). Settings and Notes open from Today; the Reading Coach lives inside an
/// Article.
enum AppTab: CaseIterable {
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

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label(LocalizedStringKey(AppTab.today.title), systemImage: AppTab.today.symbol) }
            ReadingView()
                .tabItem { Label(LocalizedStringKey(AppTab.reading.title), systemImage: AppTab.reading.symbol) }
            VocabularyView()
                .tabItem { Label(LocalizedStringKey(AppTab.vocabulary.title), systemImage: AppTab.vocabulary.symbol) }
            ProgressTrackerView()
                .tabItem { Label(LocalizedStringKey(AppTab.progress.title), systemImage: AppTab.progress.symbol) }
        }
        .tint(Theme.red)
        .toolbarBackground(Theme.paper, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .environment(\.locale, language.current.locale)
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
