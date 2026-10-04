import SwiftUI

/// The **Collection Sliver** on Today: the last twenty or so cells the student filled, newest on the
/// right. It is how the grid shows up on the home screen without taking it over; tapping opens
/// Progress at the section of the newest one.
struct CollectionStrip: View {
    let recent: [RecentCell]
    let onOpen: (CollectionSection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("最近认识")
                .font(Theme.label)
                .tracking(1.4)
                .foregroundStyle(Theme.red)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 3) {
                        ForEach(Array(recent.enumerated()), id: \.offset) { index, item in
                            CollectionCellView(cell: item.cell, isGlowing: false)
                                .frame(width: 38, height: 38)
                                .id(index)
                        }
                    }
                }
                .onAppear { proxy.scrollTo(recent.count - 1, anchor: .trailing) }
            }
            .frame(height: 38)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let newest = recent.last { onOpen(newest.section) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("最近认识"))
        .accessibilityAddTraits(.isButton)
    }
}
