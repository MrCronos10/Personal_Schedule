import SwiftUI

/// The **Goal** at the top of 今天, so the reason for the day's Actions is the first thing read.
///
/// Fixed text in the code, taken from CONTEXT.md. It is not a record and cannot be edited: the one
/// aim of the year is the thing least likely to change, and a field for it would only invite the
/// student to fiddle with the sentence instead of doing the work under it.
struct GuidingGoalBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("长期目标")
                .font(Theme.label)
                .tracking(1.4)
                .foregroundStyle(Theme.red)
            Text("说一口流利的中文，能和中国人真正地聊天。")
                .font(Theme.serif(17))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.red.opacity(0.06))
        .overlay(alignment: .leading) {
            Rectangle().fill(Theme.red).frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    GuidingGoalBanner()
        .padding()
        .background(Theme.paper)
}
