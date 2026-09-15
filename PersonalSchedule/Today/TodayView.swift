import SwiftUI

/// The 今天 tab. The Daily Checklist arrives in ticket 04; for now it shows the header.
struct TodayView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(Date.now.formatted(.dateTime.month().day().weekday(.abbreviated)
                    .locale(Locale(identifier: "zh_Hans"))))
                    .font(.system(size: 13))
                    .tracking(1)
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 12)

                TianZiGeTitle(text: "今天")
                    .padding(.top, 14)

                SectionCaption(title: "今天的计划")

                Text("还没有计划")
                    .font(Theme.serif(16))
                    .foregroundStyle(Theme.muted)
                    .padding(.vertical, 14)
            }
            .padding(.horizontal, 16)
        }
        .background(Theme.paper)
    }
}

#Preview {
    TodayView()
}
