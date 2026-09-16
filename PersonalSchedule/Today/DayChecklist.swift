import SwiftData
import SwiftUI

/// The Actions that appear on one day, in DayPlan order, with their tick boxes.
struct DayChecklist: View {
    let day: Day
    let today: Day

    @Environment(\.modelContext) private var context
    /// Everything planned for this day or earlier; `DayPlan.plan(_:on:today:)` picks out the day's Actions,
    /// because a late Action's planned day has passed.
    @Query private var candidateActions: [Action]
    @Query private var dayCompletions: [Completion]
    @Query(sort: \Category.createdAt) private var allCategories: [Category]

    @State private var tickTarget: Action?
    @State private var untickTarget: Action?
    @State private var deleteTarget: Action?
    /// Kept beside `deleteTarget` so the dialog's message never reads a title off a deleted Action.
    @State private var deleteTitle = ""

    init(day: Day, today: Day = Day.today()) {
        self.day = day
        self.today = today
        _candidateActions = Query(DayPlan.descriptor(for: day, today: today))
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
        .sheet(item: $tickTarget) { action in
            TickSheetView(action: action, day: day)
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
            ink: Theme.categoryInk(for: action.category, among: allCategories),
            isLate: DayPlan.isLate(action, on: day, today: today),
            onTickBox: {
                if isDone {
                    untickTarget = action
                } else {
                    tickTarget = action
                }
            },
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
    let onTickBox: () -> Void
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

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: action.title)
                    .font(Theme.serif(16))
                    .foregroundStyle(titleInk)
                    .strikethrough(isDone, color: Theme.rule)
                meta
            }

            Spacer(minLength: 0)

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
            Text(verbatim: "【\(action.category?.name ?? "")】")
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
                Text("完")
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
                    .stroke(isLate ? Theme.late : Theme.ink, lineWidth: 1.5)
                    .frame(width: 34, height: 34)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isDone ? Text("取消完成") : Text("完成"))
    }

    /// 一次 for a One-time Action; for a Routine, how often it repeats.
    private var kindLabel: LocalizedStringKey {
        guard let repeatDays = action.repeatDays else { return "一次" }
        if repeatDays == .everyDay { return "每天" }
        if repeatDays == .weekdays { return "工作日" }
        return "重复"
    }

    private var titleInk: Color {
        if isDone { return Theme.muted }
        return isLate ? Theme.late : Theme.ink
    }

    /// The day it was planned for, so a late Action says how far behind it is.
    private var plannedDayText: String {
        action.plannedDay.date().formatted(.dateTime.month().day().locale(locale))
    }
}
