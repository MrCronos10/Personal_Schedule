import SwiftUI

/// A screen with nothing in it yet: one faint 田字格 holding a single grey brush character, a sentence,
/// and — where there is something to do about it — one action. The shape every empty state in the app
/// takes (`docs/design-v2/brief.md`: empty states).
struct EmptyState: View {
    /// One brush character that stands for the empty screen (记 for Notes, 读 for reading, …).
    let character: String
    let message: LocalizedStringKey
    /// An empty state names at most one thing to do. A screen whose emptiness has no action (nothing
    /// to add from here) leaves these nil and shows the sentence alone.
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            cell
            Text(message)
                .font(Theme.serif(16))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(RedButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
    }

    /// The single faint 田字格 cell: a dashed red cross inside a red outline, with the grey brush
    /// character sitting in it.
    private var cell: some View {
        Text(verbatim: character)
            .font(Theme.brush(46))
            .foregroundStyle(Theme.muted.opacity(0.55))
            .frame(width: 96, height: 96)
            .background(
                GeometryReader { geo in
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                        path.move(to: CGPoint(x: geo.size.width / 2, y: 0))
                        path.addLine(to: CGPoint(x: geo.size.width / 2, y: geo.size.height))
                    }
                    .stroke(Theme.red.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
            )
            .overlay(Rectangle().stroke(Theme.red.opacity(0.4), lineWidth: 1.5))
            .accessibilityHidden(true)
    }
}

#Preview {
    EmptyState(
        character: "记",
        message: "完成一个计划时可以写一条笔记，新遇到的词就记在这里。",
        actionTitle: "去今天",
        action: {}
    )
    .background(Theme.paper)
}
