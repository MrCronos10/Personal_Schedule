import SwiftData
import SwiftUI

/// The Actions that appear on one day, in DayPlan order, with their tick boxes.
struct DayChecklist: View {
    let day: Day
    let today: Day

    @Environment(\.modelContext) private var context
    /// Every Action; `DayPlan.plan(_:on:today:)` picks out the ones this day shows, because a day's Actions
    /// can't be found by their stored day numbers alone.
    @Query private var candidateActions: [Action]
    @Query private var dayCompletions: [Completion]
    @Query(sort: \Category.createdAt) private var allCategories: [Category]

    @State private var sheet: Sheet?
    @State private var untickTarget: Action?
    @State private var deleteTarget: Action?
    /// Kept beside `deleteTarget` so the dialog's message never reads a title off a deleted Action.
    @State private var deleteTitle = ""

    /// What the checklist shows over itself: the Tick sheet, or the form for changing an Action. One sheet
    /// holding both, because two `sheet` modifiers on the same view get in each other's way.
    private enum Sheet: Identifiable {
        case tick(Action)
        case edit(Action)

        var id: String {
            switch self {
            case .tick(let action): return "tick-\(String(describing: action.persistentModelID))"
            case .edit(let action): return "edit-\(String(describing: action.persistentModelID))"
            }
        }
    }

    init(day: Day, today: Day = Day.today()) {
        self.day = day
        self.today = today
        _candidateActions = Query(DayPlan.descriptor)
        _dayCompletions = Query(CompletionLibrary.descriptor(for: day))
    }

    var body: some View {
        let actions: [Action] = DayPlan.plan(candidateActions, on: day, today: today)
        let completions: [PersistentIdentifier: Completion] = completionsByAction()

        Group {
            if actions.isEmpty {
                Text("还没有计划")
                    .font(Theme.serif(16))
                    .foregroundStyle(Theme.muted)
                    .padding(.vertical, 14)
            } else {
                ForEach(actions) { action in
                    row(for: action, completion: completions[action.persistentModelID])
                }
            }
        }
        .sheet(item: $sheet) { showing in
            switch showing {
            case .tick(let action):
                TickSheetView(action: action, day: day)
            case .edit(let action):
                ActionFormView(editing: action)
            }
        }
        .confirmationDialog(
            Text("取消完成？"),
            isPresented: Binding(
                get: { untickTarget != nil },
                set: { isShowing in if !isShowing { untickTarget = nil } }
            ),
            titleVisibility: .visible,
            presenting: untickTarget
        ) { action in
            Button("取消完成", role: .destructive) {
                try? CompletionLibrary(context: context).untick(action, on: day)
            }
            Button("保留", role: .cancel) {}
        } message: { action in
            Text("“\(action.title)”的分钟和笔记会被删除。")
        }
        .confirmationDialog(
            Text("删除这个计划？"),
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { isShowing in if !isShowing { deleteTarget = nil } }
            ),
            titleVisibility: .visible,
            presenting: deleteTarget
        ) { action in
            Button("删除", role: .destructive) {
                // Closed first: once the Action is gone, the dialog must not read it again.
                deleteTarget = nil
                try? ActionLibrary(context: context).delete(action)
            }
            Button("保留", role: .cancel) {}
        } message: { _ in
            Text("“\(deleteTitle)”会被删除，不能恢复。")
        }
    }

    private func row(for action: Action, completion: Completion?) -> ActionRow {
        let isDone: Bool = completion != nil
        // A ticked Action keeps its Completion, and a Routine is paused rather than deleted (CONTEXT.md),
        // so only an unticked One-time Action offers 删除.
        let canDelete: Bool = !isDone && !action.isRoutine
        let onDelete: (() -> Void)? = canDelete ? {
            deleteTitle = action.title
            deleteTarget = action
        } : nil
        return ActionRow(
            action: action,
            completion: completion,
            // A ticked day is shown as it was ticked, so its ink comes from the Category its Completion
            // copied, not from wherever the Action has been moved since (ADR 0002).
            ink: Theme.categoryInk(for: completion?.category ?? action.category, among: allCategories),
            isLate: DayPlan.isLate(action, on: day, today: today),
            isMissed: DayPlan.isMissed(action, on: day, today: today),
            onTickBox: {
                if isDone {
                    untickTarget = action
                } else {
                    sheet = .tick(action)
                }
            },
            onOpen: { sheet = .edit(action) },
            onDelete: onDelete
        )
    }

    private func completionsByAction() -> [PersistentIdentifier: Completion] {
        Dictionary(
            dayCompletions.compactMap { completion in
                completion.action.map { ($0.persistentModelID, completion) }
            },
            uniquingKeysWith: { first, _ in first }
        )
    }
}

/// One Action on the Daily Checklist: time on the left, title and 【Category】 in the middle, tick box on the right.
struct ActionRow: View {
    let action: Action
    let completion: Completion?
    let ink: Color
    let isLate: Bool
    let isMissed: Bool
    let onTickBox: () -> Void
    /// Tapping the title opens the Action for changing; the tick box keeps its own tap.
    let onOpen: () -> Void
    /// Nothing to offer for a ticked Action, so it gets no long-press menu at all.
    let onDelete: (() -> Void)?

    @Environment(\.locale) private var locale

    private var isDone: Bool { completion != nil }

    var body: some View {
        if let onDelete {
            row.contextMenu {
                Button("删除", role: .destructive, action: onDelete)
            }
        } else {
            row
        }
    }

    private var row: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(verbatim: action.time?.clockText ?? "—")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.muted)
                .frame(width: 44, alignment: .leading)

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: shownTitle)
                        .font(Theme.serif(16))
                        .foregroundStyle(titleInk)
                        .strikethrough(isDone, color: Theme.rule)
                    meta
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("修改"))

            tickBox
        }
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.rule).frame(height: 1)
        }
        .contentShape(Rectangle())
    }

    private var meta: some View {
        HStack(spacing: 0) {
            Text(verbatim: "【\(shownCategoryName)】")
                .foregroundStyle(ink)
            Text(kindLabel)
                .foregroundStyle(Theme.muted)
            if isLate {
                Text(verbatim: " · ")
                    .foregroundStyle(Theme.muted)
                Text("迟到")
                    .foregroundStyle(Theme.late)
                Text(verbatim: " \(plannedDayText)")
                    .foregroundStyle(Theme.late)
            }
            if isMissed {
                Text(verbatim: " · ")
                    .foregroundStyle(Theme.muted)
                Text("错过")
                    .foregroundStyle(Theme.late)
            }
            if let minutes = completion?.minutes {
                Text(verbatim: " · ")
                    .foregroundStyle(Theme.muted)
                Text("\(minutes)分钟")
                    .foregroundStyle(Theme.muted)
            }
        }
        .font(.system(size: 12))
    }

    private var tickBox: some View {
        Button(action: onTickBox) {
            if isDone {
                // The seal on a finished day. It is the same character in both languages.
                Text(verbatim: "完")
                    .font(Theme.serif(19, .black))
                    .foregroundStyle(Theme.paper)
                    .frame(width: 36, height: 36)
                    .background(Theme.red)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .inset(by: 2.5)
                            .stroke(Theme.paper, lineWidth: 1.5)
                    )
                    .rotationEffect(.degrees(-8))
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isBehind ? Theme.late : Theme.ink, lineWidth: 1.5)
                    .frame(width: 34, height: 34)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isDone ? Text("取消完成") : Text("完成"))
    }

    /// A ticked day shows the title its Completion copied when it was ticked, so changing an Action later
    /// never rewrites a finished day (ADR 0002). Days that aren't ticked show the Action as it is now.
    private var shownTitle: String {
        if let ticked = completion?.titleWhenTicked, !ticked.isEmpty {
            return ticked
        }
        return action.title
    }

    /// The Category a ticked day counted towards, which is the one its Completion copied.
    private var shownCategoryName: String {
        (completion?.category ?? action.category)?.name ?? ""
    }

    /// 一次 for a One-time Action; for a Routine, how often it repeats.
    private var kindLabel: LocalizedStringKey {
        guard let repeatDays = action.repeatDays else { return "一次" }
        if repeatDays == .everyDay { return "每天" }
        if repeatDays == .weekdays { return "工作日" }
        return "自选日子"
    }

    /// 迟到 and 错过 are both "behind", and share one ink. See "Look" in docs/plan-v1.md.
    private var isBehind: Bool { isLate || isMissed }

    private var titleInk: Color {
        if isDone { return Theme.muted }
        return isBehind ? Theme.late : Theme.ink
    }

    /// The day it was planned for, so a late Action says how far behind it is.
    private var plannedDayText: String {
        action.plannedDay.date().formatted(.dateTime.month().day().locale(locale))
    }
}
