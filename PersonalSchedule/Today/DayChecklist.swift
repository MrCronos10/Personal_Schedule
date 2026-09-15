import SwiftData
import SwiftUI

/// The Actions planned for one day, in DayPlan order.
struct DayChecklist: View {
    @Query private var plannedActions: [Action]
    @Query(sort: \Category.createdAt) private var allCategories: [Category]

    init(day: Day) {
        _plannedActions = Query(DayPlan.descriptor(for: day))
    }

    var body: some View {
        let actions = DayPlan.ordered(plannedActions)
        if actions.isEmpty {
            Text("还没有计划")
                .font(Theme.serif(16))
                .foregroundStyle(Theme.muted)
                .padding(.vertical, 14)
        } else {
            ForEach(actions) { action in
                ActionRow(action: action, ink: Theme.categoryInk(for: action.category, among: allCategories))
            }
        }
    }
}

/// One Action on the Daily Checklist: time on the left, title and 【Category】 in the middle.
struct ActionRow: View {
    let action: Action
    let ink: Color

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(verbatim: action.time?.clockText ?? "—")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.muted)
                .frame(width: 44, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: action.title)
                    .font(Theme.serif(16))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 0) {
                    Text(verbatim: "【\(action.category?.name ?? "")】")
                        .foregroundStyle(ink)
                    Text("一次")
                        .foregroundStyle(Theme.muted)
                }
                .font(.system(size: 12))
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.rule).frame(height: 1)
        }
    }
}
