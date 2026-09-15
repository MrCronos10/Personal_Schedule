import SwiftData
import SwiftUI

/// The 今天 tab: the Daily Checklist for the chosen day, with ◀ ▶ to move between days.
struct TodayView: View {
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase
    @State private var day = Day.today()
    /// The last day this screen saw as today. If the student was on it, the checklist follows to the new day after midnight.
    @State private var lastSeenToday = Day.today()
    @State private var isAddingAction = false

    private var isToday: Bool { day == Day.today() }
    private var isChinese: Bool { locale.language.languageCode == .chinese }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text(day.date().formatted(.dateTime.month().day().weekday(.abbreviated).locale(locale)))
                        .font(.system(size: 13))
                        .tracking(1)
                        .foregroundStyle(Theme.muted)
                    Spacer()
                    if !isToday {
                        Button("今天") { day = Day.today() }
                            .buttonStyle(MiniButtonStyle())
                    }
                    Button { day = day.adding(days: -1) } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(MiniButtonStyle())
                    .accessibilityLabel(Text("前一天"))
                    Button { day = day.adding(days: 1) } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(MiniButtonStyle())
                    .accessibilityLabel(Text("后一天"))
                    Button { isAddingAction = true } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(RedButtonStyle())
                    .accessibilityLabel(Text("新计划"))
                }
                .padding(.top, 12)

                dayTitle
                    .padding(.top, 14)

                SectionCaption(title: isToday ? "今天的计划" : "这一天的计划")

                DayChecklist(day: day)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.paper)
        .sheet(isPresented: $isAddingAction) {
            ActionFormView(day: day)
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            followToday()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                followToday()
            }
        }
    }

    /// After midnight (or when the app comes back), move from the old today to the new one.
    /// A day the student chose on purpose stays where it is.
    private func followToday() {
        let today = Day.today()
        if day == lastSeenToday {
            day = today
        }
        lastSeenToday = today
    }

    /// 今天 in 田字格 boxes for today; the weekday for other days. English uses heavy serif without boxes.
    @ViewBuilder
    private var dayTitle: some View {
        if isToday {
            if isChinese {
                TianZiGeTitle(text: "今天")
            } else {
                Text("今天")
                    .font(Theme.serif(38, .black))
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
            }
        } else {
            let weekday = day.date().formatted(.dateTime.weekday(isChinese ? .abbreviated : .wide).locale(locale))
            if isChinese {
                TianZiGeTitle(text: weekday)
            } else {
                Text(verbatim: weekday)
                    .font(Theme.serif(38, .black))
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
            }
        }
    }
}

#Preview("中文") {
    TodayView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}

#Preview("English") {
    TodayView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
        .environment(\.locale, AppLanguage.english.locale)
}
