import SwiftData
import SwiftUI

/// The Actions planned for one day, in DayPlan order, with their tick boxes.
struct DayChecklist: View {
    let day: Day

    @Environment(\.modelContext) private var context
    @Query private var plannedActions: [Action]
    @Query private var dayCompletions: [Completion]
    @Query(sort: \Category.createdAt) private var allCategories: [Category]

    @State private var tickTarget: Action?
    @State private var untickTarget: Action?

    init(day: Day) {
        self.day = day
        _plannedActions = Query(DayPlan.descriptor(for: day))
        _dayCompletions = Query(CompletionLibrary.descriptor(for: day))
    }

    var body: some View {
        let actions = DayPlan.ordered(plannedActions)
        let completions = completionsByAction()

        Group {
            if actions.isEmpty {
                Text("还没有计划")
                    .font(Theme.serif(16))
                    .foregroundStyle(Theme.muted)
                    .padding(.vertical, 14)
            } else {
                ForEach(actions) { action in
                    ActionRow(
                        action: action,
                        completion: completions[action.persistentModelID],
                        ink: Theme.categoryInk(for: action.category, among: allCategories)
                    ) {
                        if completions[action.persistentModelID] == nil {
                            tickTarget = action
                        } else {
                            untickTarget = action
                        }
                    }
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
    let onTickBox: () -> Void

    private var isDone: Bool { completion != nil }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(verbatim: action.time?.clockText ?? "—")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.muted)
                .frame(width: 44, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: action.title)
                    .font(Theme.serif(16))
                    .foregroundStyle(isDone ? Theme.muted : Theme.ink)
                    .strikethrough(isDone, color: Theme.rule)
                HStack(spacing: 0) {
                    Text(verbatim: "【\(action.category?.name ?? "")】")
                        .foregroundStyle(ink)
                    Text("一次")
                        .foregroundStyle(Theme.muted)
                    if let minutes = completion?.minutes {
                        Text(verbatim: " · ")
                            .foregroundStyle(Theme.muted)
                        Text("\(minutes)分钟")
                            .foregroundStyle(Theme.muted)
                    }
                }
                .font(.system(size: 12))
            }

            Spacer(minLength: 0)

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
                        .stroke(Theme.ink, lineWidth: 1.5)
                        .frame(width: 34, height: 34)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isDone ? Text("取消完成") : Text("完成"))
        }
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.rule).frame(height: 1)
        }
    }
}
