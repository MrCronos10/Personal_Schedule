import SwiftData
import SwiftUI

/// The 进度 tab: this week's Completions for each Category, against its Weekly Target where it has one.
/// Monday to Sunday of today's week only — there is no way back to an earlier week yet.
struct ProgressTrackerView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query(CategoryLibrary.allDescriptor) private var categories: [Category]
    @Query(CompletionLibrary.allDescriptor) private var completions: [Completion]
    @State private var today = Day.today()

    private var week: Week { Week(containing: today) }

    private var rows: [WeekProgress] {
        CompletionLibrary.week(week, categories: categories, completions: completions)
    }

    var body: some View {
        WeekLedger(week: week, rows: rows, categories: categories, today: today, completions: completions)
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                today = Day.today()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    today = Day.today()
                }
            }
    }
}

/// The week as it is drawn, given what the week holds. Kept apart from the database so it can be looked at
/// with any week's data in front of it.
struct WeekLedger: View {
    @Environment(\.locale) private var locale

    let week: Week
    let rows: [WeekProgress]
    let categories: [Category]
    let today: Day
    let completions: [Completion]

    /// The day a Missed ledger cell was tapped for. Opened as `TodayView(initialDay:)` so retroactively
    /// logging the Completion reuses the Daily Checklist's own tick logic rather than a second copy of it.
    @State private var retroactiveDay = Day.today()
    @State private var isShowingRetroactiveDay = false

    private var isChinese: Bool { locale.language.languageCode == .chinese }

    var body: some View {
        ScrollView {
            content
        }
        .background(Theme.paper)
        .sheet(isPresented: $isShowingRetroactiveDay) {
            TodayView(initialDay: retroactiveDay)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: weekRange)
                    .font(.system(size: 13))
                    .tracking(1)
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 12)

                weekTitle
                    .padding(.top, 14)

                SectionCaption(title: "本周的进度")

                // Two different empty weeks, and they need different answers: no Categories at all means
                // make one, while every Category archived means restore one — telling that student to add
                // a Category would have them make a duplicate of one sitting in 已归档.
                Group {
                    if categories.isEmpty {
                        emptyText("请先在设置里添加分类")
                    } else if rows.isEmpty {
                        emptyText("所有分类都已归档")
                    } else {
                        ForEach(rows, id: \.category.persistentModelID) { row in
                            CategoryWeekRow(
                                row: row,
                                ink: Theme.categoryInk(for: row.category, among: categories),
                                week: week,
                                today: today,
                                completions: completions,
                                onTapMissedDay: { day in
                                    retroactiveDay = day
                                    isShowingRetroactiveDay = true
                                }
                            )
                        }
                    }
                }
                .card()
                .padding(.top, 10)
            }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    /// 本周 in 田字格 boxes, the same practice-book heading the 今天 tab uses. It says which week this is,
    /// which matters because the screen never shows another one.
    @ViewBuilder
    private var weekTitle: some View {
        if isChinese {
            TianZiGeTitle(text: "本周")
        } else {
            Text("本周")
                .font(Theme.serif(38, .black))
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private func emptyText(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(Theme.serif(16))
            .foregroundStyle(Theme.muted)
            .padding(.vertical, 12)
    }

    private var weekRange: String {
        // 9月14日 in 中文, Sep 14 in English.
        let style = Date.FormatStyle.dateTime.month().day().locale(locale)
        return "\(week.monday.date().formatted(style)) – \(week.sunday.date().formatted(style))"
    }
}

/// One Category's card: its name and week total, a 7-day ledger, this week's Active Routines, and a
/// Continuity Safeguard note for any Routine currently Paused.
///
/// An Archived Category keeps only its name and total — the ledger and Routines beneath it belong to a
/// Category still being worked at, and an archived one has nothing left to look ahead or behind at.
private struct CategoryWeekRow: View {
    let row: WeekProgress
    let ink: Color
    let week: Week
    let today: Day
    let completions: [Completion]
    let onTapMissedDay: (Day) -> Void

    private var activeRoutines: [CompletionLibrary.RoutineWeekActivity] {
        CompletionLibrary.activeRoutines(for: row.category, in: week, completions: completions)
    }

    private var pausedRoutines: [Action] {
        (row.category.actions ?? []).filter { $0.isRoutine && $0.isPaused }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if !row.isArchived {
                LedgerStrip(
                    category: row.category,
                    week: week,
                    today: today,
                    completions: completions,
                    ink: ink,
                    onTapMissedDay: onTapMissedDay
                )

                if !activeRoutines.isEmpty {
                    ActiveRoutinesList(activities: activeRoutines)
                }

                ForEach(pausedRoutines, id: \.persistentModelID) { routine in
                    ContinuitySafeguardNote(routine: routine)
                }
            }
        }
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.rule).frame(height: 1)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: row.category.name)
                    .font(Theme.serif(17))
                    .foregroundStyle(row.isArchived ? Theme.muted : ink)
                if row.isArchived {
                    Text("已归档")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                if let target = row.weeklyTargetMinutes {
                    Text(verbatim: "\(row.minutes) / \(target)")
                        .font(.system(size: 13).monospacedDigit())
                        .foregroundStyle(Theme.muted)
                } else {
                    Text("本周\(row.completions)次")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.muted)
                }
            }

            if let target = row.weeklyTargetMinutes {
                WeeklyTargetBar(minutes: row.minutes, target: target)
            }
        }
    }
}

/// The Category's Mon–Sun strip: what each day of the week looks like for it. Tapping a Missed day opens
/// the Daily Checklist on that day, to log a Completion retroactively.
private struct LedgerStrip: View {
    let category: Category
    let week: Week
    let today: Day
    let completions: [Completion]
    let ink: Color
    let onTapMissedDay: (Day) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { offset in
                let day = week.monday.adding(days: offset)
                LedgerDayCell(
                    day: day,
                    state: CompletionLibrary.dayState(for: category, on: day, today: today, completions: completions),
                    ink: ink,
                    onTapMissed: { onTapMissedDay(day) }
                )
            }
        }
    }
}

/// One day in a Category's ledger strip: its weekday letter, and a glyph for what that day was.
private struct LedgerDayCell: View {
    let day: Day
    let state: CompletionLibrary.CategoryDayState
    let ink: Color
    let onTapMissed: () -> Void

    @Environment(\.locale) private var locale

    private var isMissed: Bool {
        if case .missed = state { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 3) {
            Text(weekdayLetter)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Theme.muted)
            glyph
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            if isMissed { onTapMissed() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: weekdayLetter) + Text(verbatim: " ") + stateText)
        .accessibilityAddTraits(isMissed ? .isButton : [])
    }

    @ViewBuilder
    private var glyph: some View {
        switch state {
        case .done:
            Circle().fill(ink).frame(width: 8, height: 8)
        case .missed:
            Circle().strokeBorder(Theme.late, lineWidth: 1.5).frame(width: 8, height: 8)
        case .today:
            Circle().strokeBorder(Theme.ink, lineWidth: 1.5).frame(width: 8, height: 8)
        case .plan:
            Circle().fill(Theme.rule).frame(width: 6, height: 6)
        }
    }

    private var stateText: Text {
        switch state {
        case .done: Text("完成")
        case .missed: Text("错过，可以补记")
        case .today: Text("今天")
        case .plan: Text(verbatim: "")
        }
    }

    private var weekdayLetter: String {
        day.date().formatted(.dateTime.weekday(.narrow).locale(locale))
    }
}

/// This week's Active Routines in the Category, each with how many times it was completed.
private struct ActiveRoutinesList: View {
    let activities: [CompletionLibrary.RoutineWeekActivity]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(activities, id: \.action.persistentModelID) { activity in
                HStack(spacing: 6) {
                    Text(verbatim: activity.action.title)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Spacer()
                    Chip(text: "本周\(activity.completions)次")
                    if let minutes = activity.action.defaultMinutes {
                        Chip(text: "\(minutes)分钟")
                    }
                }
            }
        }
    }
}

/// A note for a Routine currently Paused: it stays 已暂停 rather than turning up as Missed, and this says so.
private struct ContinuitySafeguardNote: View {
    let routine: Action

    @Environment(\.locale) private var locale

    private var openPause: Pause? {
        (routine.pauses ?? []).first { !$0.hasEnded }
    }

    var body: some View {
        if let openPause {
            HStack(spacing: 6) {
                Chip(text: "已暂停", ink: Theme.muted, ground: Theme.cardHigh)
                Text("从\(startDateText(openPause.startDay))起 · 这段时间不算错过")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
            }
        }
    }

    private func startDateText(_ day: Day) -> String {
        day.date().formatted(.dateTime.month().day().locale(locale))
    }
}

/// The week's minutes against the Weekly Target.
///
/// The track is the Weekly Target and stops short of the row's edge. The paper left over is the overflow
/// lane: it only takes ink when the week has gone past its target, so going over is something you can see
/// rather than a bar that just stops.
private struct WeeklyTargetBar: View {
    let minutes: Int
    let target: Int

    /// How far past the target the lane can show before the numbers have to carry it alone.
    private static let laneCoversOver = 0.25
    private static let trackShareOfRow = 0.8

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let track = width * Self.trackShareOfRow
            let lane = width - track
            let done = target > 0 ? Double(minutes) / Double(target) : 0
            let overflow = min(max(done - 1, 0), Self.laneCoversOver) / Self.laneCoversOver

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Theme.rule)
                    .frame(width: track, height: 6)
                Rectangle()
                    .fill(Theme.red)
                    .frame(width: min(done, 1) * track + overflow * lane, height: 6)
            }
            .frame(width: width, alignment: .leading)
        }
        .frame(height: 6)
        .accessibilityElement()
        .accessibilityLabel(Text("本周 \(minutes) 分钟，目标 \(target) 分钟"))
    }
}

#Preview("中文") {
    ProgressTrackerView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}

#Preview("English") {
    ProgressTrackerView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
        .environment(\.locale, AppLanguage.english.locale)
}
