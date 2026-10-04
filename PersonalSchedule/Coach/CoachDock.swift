import SwiftUI

/// The **Coach Dock**: 读伴 as a strip at the bottom of the reader. Collapsed it is one line; pulled
/// up (or tapped) it opens the thread over about two fifths of the screen, with the Article still
/// showing above. See CONTEXT.md and ADR 0008 — the Coach still lives inside an Article and nowhere
/// else, and still says nothing about streaks or what is due.
struct CoachDock: View {
    let article: Article

    @State private var isExpanded = false
    @State private var isWriting = false

    private var expandedHeight: CGFloat { max(300, UIScreen.main.bounds.height * 0.4) }

    var body: some View {
        VStack(spacing: 0) {
            handle
            // Kept in the tree while collapsed, at no height, so a reply that is still streaming in
            // is not cancelled by folding the dock away.
            CoachThreadView(article: article, isWriting: $isWriting)
                .frame(height: isExpanded ? expandedHeight : 0)
                .clipped()
                .allowsHitTesting(isExpanded)
                .accessibilityHidden(!isExpanded)
        }
        .background(Theme.card)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.red).frame(height: 1.5)
        }
    }

    private var handle: some View {
        Button {
            withAnimation(.easeOut(duration: 0.22)) { isExpanded.toggle() }
        } label: {
            HStack(spacing: 10) {
                Text(isWriting ? "读伴 在想…" : "问读伴")
                    .font(Theme.serif(16))
                    .foregroundStyle(isWriting ? Theme.muted : Theme.red)
                Spacer()
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 12).onEnded { drag in
                withAnimation(.easeOut(duration: 0.22)) {
                    if drag.translation.height < -20 { isExpanded = true }
                    if drag.translation.height > 20 { isExpanded = false }
                }
            }
        )
        .accessibilityLabel(Text("问读伴"))
        .accessibilityAddTraits(.isButton)
    }
}
