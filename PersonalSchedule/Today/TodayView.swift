import SwiftData
import SwiftUI

/// The 今天 tab: a Dawn header, the day's Today card (Routine ring, reading progress, goal stamp slot),
/// the 最近认识 sliver, and the Daily Checklist. ◀ ▶ move between days; a floating + adds an Action.
struct TodayView: View {
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase
    @State private var day: Day
    /// The last day this screen saw as today. If the student was on it, the checklist follows to the new day after midnight.
    @State private var lastSeenToday = Day.today()
    @State private var isAddingAction = false
    @Environment(\.modelContext) private var context
    @Environment(AppRouter.self) private var router: AppRouter?
    @State private var recent: [RecentCell] = []
    @AppStorage(ReadingPreferences.goalKey) private var readingGoal = ReadingPreferences.defaultGoal
    /// Today's characters read, the same count the Reading Session banks (ArticleLibrary.charactersRead).
    @State private var charactersToday = 0
    /// The day's reading has reached the goal; the seal stays in the card for the rest of the day.
    @State private var goalReached = false
    /// True only on the visit where the seal is first stamped: it lands with a haptic, once.
    @State private var stampJustLanded = false
    @State private var isShowingNotes = false
    @State private var isShowingSettings = false

    /// `initialDay` lets another screen open straight onto a chosen day — the Progress Tracker's ledger
    /// does this to jump onto a Missed day so it can be logged retroactively (see WeekLedger).
    init(initialDay: Day = .today(), showsShortcuts: Bool = true) {
        _day = State(initialValue: initialDay)
        self.showsShortcuts = showsShortcuts
    }

    /// The 笔记 and 设置 doors belong to the Today tab; a Today opened as a sheet from the ledger or a
    /// Note has them off, so it can't open a Notes list from inside a Notes list.
    private let showsShortcuts: Bool

    /// Only the Today tab itself shows the card and the seal; a Today opened as a sheet from the ledger
    /// or a Note must not spend the day's stamp on a screen the student is not looking at, and neither
    /// may the tab while another tab is showing.
    private func refreshForTab() {
        guard showsShortcuts, router?.tab ?? .today == .today else { return }
        refreshRecent()
        refreshGoal()
    }

    /// Whether today's reading has reached the goal, and whether the seal is due to land right now.
    private func refreshGoal() {
        let today = Day.today()
        charactersToday = (try? ArticleLibrary(context: context).charactersRead(on: today)) ?? 0
        goalReached = charactersToday >= readingGoal
        var celebrations = Celebrations(defaults: .standard)
        if celebrations.readingGoalStampIsDue(charactersToday: charactersToday, goal: readingGoal, on: today) {
            celebrations.markReadingGoalStamped(on: today)
            stampJustLanded = true
            Task {
                // Landed: any later visit today shows the seal already in place, without the landing.
                try? await Task.sleep(for: .seconds(2))
                stampJustLanded = false
            }
        }
    }

    private func refreshRecent() {
        recent = (try? CollectionLibrary(context: context).recentlyKnown()) ?? []
    }

    private var isToday: Bool { day == Day.today() }
    private var isChinese: Bool { locale.language.languageCode == .chinese }
    private var showsTodayExtras: Bool { showsShortcuts && isToday }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                dawnBlock

                if showsTodayExtras {
                    TodayCard(
                        day: day, today: Day.today(),
                        charactersRead: charactersToday, goal: readingGoal,
                        goalReached: goalReached, stampJustLanded: stampJustLanded
                    )
                    .padding(.top, 16)
                }

                if showsShortcuts && !recent.isEmpty {
                    CollectionStrip(recent: recent) { router?.showProgress(at: $0) }
                        .padding(.top, 18)
                }

                SectionCaption(title: isToday ? "今天的计划" : "这一天的计划")

                DayChecklist(day: day)
                    .card()
                    .padding(.top, 10)
            }
            .padding(.horizontal, 16)
            // Clears the floating + so the last checklist row's tick box stays tappable.
            .padding(.bottom, 88)
        }
        .background(Theme.paper)
        // Adding an Action applies to any day, including a Today opened as a sheet from the ledger.
        .overlay(alignment: .bottomTrailing) {
            Button { isAddingAction = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Theme.onRed)
                    .frame(width: 56, height: 56)
                    .background(Theme.red)
                    .clipShape(Circle())
                    .shadow(color: Theme.red.opacity(0.35), radius: 10, y: 6)
            }
            .accessibilityLabel(Text("新计划"))
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        }
        .sheet(isPresented: $isAddingAction) {
            ActionFormView(day: day)
        }
        .sheet(isPresented: $isShowingNotes) {
            SheetShell { NotesListView() }
        }
        .sheet(isPresented: $isShowingSettings) {
            SheetShell { SettingsView() }
        }
        // Refreshed when this tab comes into view rather than by watching every progress row: words
        // turn Known and Articles bank on other tabs, and returning here is when it can be seen.
        .onAppear { refreshForTab() }
        .onChange(of: router?.tab) { refreshForTab() }
        .onChange(of: readingGoal) { refreshForTab() }
        .sensoryFeedback(.impact(weight: .medium), trigger: stampJustLanded) { _, landed in landed }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            followToday()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                followToday()
            }
        }
    }

    /// The top of the screen: the Dawn ground, the date and doors, the boxed 今天 title with the goal,
    /// and (on today) the Today card. The dawn scrolls with this block rather than staying behind the
    /// whole screen, so it is a header ground and not a wash behind the checklist.
    private var dawnBlock: some View {
        ZStack(alignment: .top) {
            if showsTodayExtras {
                DawnHeader()
                    .padding(.horizontal, -16)   // full-bleed past the screen's 16 pt gutter
            }
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                    .padding(.top, 12)
                titleAndGoal
                    .padding(.top, 14)
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 8) {
            Text(day.date().formatted(.dateTime.month().day().weekday(.abbreviated).locale(locale)))
                .font(.system(size: 13))
                .tracking(1)
                .foregroundStyle(Theme.muted)
            Spacer()
            if !isToday {
                Button("今天") { day = Day.today() }
                    .buttonStyle(MiniButtonStyle())
            }
            Button { day = day.adding(days: -1) } label: { Image(systemName: "chevron.left") }
                .buttonStyle(MiniButtonStyle())
                .accessibilityLabel(Text("前一天"))
            Button { day = day.adding(days: 1) } label: { Image(systemName: "chevron.right") }
                .buttonStyle(MiniButtonStyle())
                .accessibilityLabel(Text("后一天"))
            if showsShortcuts {
                roundDoor("note.text", label: "笔记") { isShowingNotes = true }
                roundDoor("gearshape", label: "设置") { isShowingSettings = true }
            }
        }
    }

    /// A round door button (笔记, 设置) on a translucent cream disc, as in the Dawn header.
    private func roundDoor(_ systemName: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17))
                .foregroundStyle(Theme.ink)
                .frame(width: 40, height: 40)
                .background(Theme.paper.opacity(0.85))
                .clipShape(Circle())
                .overlay(Circle().stroke(Theme.rule))
        }
        .accessibilityLabel(Text(label))
    }

    /// The boxed 今天 title with the year's goal below it. The goal is kept to the left so it clears the
    /// Dawn sun in the top-right corner.
    private var titleAndGoal: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { dayTitle; Spacer(minLength: 0) }
            VStack(alignment: .leading, spacing: 3) {
                Text("长期目标")
                    .font(Theme.label)
                    .tracking(1.2)
                    .foregroundStyle(Theme.red)
                Text("说一口流利的中文，能和中国人真正地聊天。")
                    .font(Theme.meta)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 250, alignment: .leading)
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
        // Yesterday's seal must not carry into a new day.
        refreshForTab()
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
