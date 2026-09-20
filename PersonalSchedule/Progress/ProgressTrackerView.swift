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
        WeekLedger(week: week, rows: rows, categories: categories)
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

    private var isChinese: Bool { locale.language.languageCode == .chinese }

    var body: some View {
        ScrollView {
            content
        }
        .background(Theme.paper)
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
                if categories.isEmpty {
                    emptyText("请先在设置里添加分类")
                } else if rows.isEmpty {
                    emptyText("所有分类都已归档")
                } else {
                    ForEach(rows, id: \.category.persistentModelID) { row in
                        CategoryWeekRow(row: row, ink: Theme.categoryInk(for: row.category, among: categories))
                    }
                }
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

/// One Category's line: its name, what the week holds, and a bar when there is a Weekly Target to aim at.
private struct CategoryWeekRow: View {
    let row: WeekProgress
    let ink: Color

    var body: some View {
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
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.rule).frame(height: 1)
        }
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
