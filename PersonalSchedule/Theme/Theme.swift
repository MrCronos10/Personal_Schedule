import SwiftUI

/// The 田字格 Practice book look. See "Look" in docs/plan-v1.md.
enum Theme {
    static let paper = Color(hex: 0xFBFAF5)
    static let ink = Color(hex: 0x231F1C)
    static let muted = Color(hex: 0x7E756D)
    static let red = Color(hex: 0xB3312B)
    static let rule = red.opacity(0.2)

    /// Category inks, given out in the order Categories were created.
    private static let categoryInks: [Color] = [
        Color(hex: 0xB3312B), Color(hex: 0x2E5A88), Color(hex: 0x3E7A4E),
        Color(hex: 0x946519), Color(hex: 0x6A4F8C), Color(hex: 0x4F6F75),
    ]

    static func categoryInk(at index: Int) -> Color {
        categoryInks[index % categoryInks.count]
    }

    enum SerifWeight: String {
        case bold = "NotoSerifSC-Bold"
        case black = "NotoSerifSC-Black"
    }

    static func serif(_ size: CGFloat, _ weight: SerifWeight = .bold) -> Font {
        .custom(weight.rawValue, size: size)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// A small red caption with a heavier red rule under it.
struct SectionCaption: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .tracking(1.6)
            .foregroundStyle(Theme.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.red).frame(height: 1.5)
            }
            .padding(.top, 20)
    }
}

/// A small ink-outlined button for row actions such as 归档 and 恢复.
struct MiniButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.red.opacity(configuration.isPressed ? 0.08 : 0))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.rule))
    }
}

/// The red "stamp" button used for primary actions.
struct RedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Theme.paper)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Theme.red.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
