import SwiftUI

/// The Field Notebook look, from the Stitch design system. See ticket 12 and
/// `/Users/kuypav/Desktop/stitch_china_study_routine_tracker/DESIGN.md`.
///
/// Two things are kept from the 田字格 practice book it replaced: the boxed 今天 header
/// (`TianZiGeTitle`) and the red 完 seal on a ticked Action. They are the app's signature and the
/// Stitch mock has no better idea for either.
///
/// Type stays Noto Serif SC for Chinese and Latin alike. Stitch asks for Newsreader, which has no
/// Chinese glyphs at all, and a second face to render a few English words is not worth its weight.
enum Theme {
    // MARK: - Surfaces

    static let paper = Color(hex: 0xFCF9F7)
    /// Where a group of rows sits: Category sections, the Level meter, the Weekly Target rows.
    static let card = Color(hex: 0xF0EDEB)
    /// A chip or a field sitting on top of a card, which needs to lift off it.
    static let cardHigh = Color(hex: 0xEAE8E5)

    // MARK: - Ink

    static let ink = Color(hex: 0x1C1C1B)
    static let muted = Color(hex: 0x57423C)
    static let red = Color(hex: 0x973312)
    static let rule = Color(hex: 0xDEC0B8)
    /// Late One-time Actions and Missed Routine days. Both are "behind" and share one ink.
    static let late = Color(hex: 0x794A07)
    static let error = Color(hex: 0xBA1A1A)

    /// A finished thing: the 完 chip, a Passed Level.
    static let done = Color(hex: 0xC4E9CB)
    static let onDone = Color(hex: 0x496A52)

    // MARK: - Shape

    static let cardRadius: CGFloat = 12
    static let controlRadius: CGFloat = 8

    // MARK: - Type

    /// The Stitch scale. Sizes are the mobile column; Chinese and Latin share the same serif.
    enum SerifWeight: String {
        case bold = "NotoSerifSC-Bold"
        case black = "NotoSerifSC-Black"
    }

    static func serif(_ size: CGFloat, _ weight: SerifWeight = .bold) -> Font {
        .custom(weight.rawValue, size: size)
    }

    /// 24/32 — a Category's name, an Article's title.
    static let headline = serif(24)
    /// 20/28 — an Action's title.
    static let title = serif(20)
    /// 15/22 — running text.
    static let body = Font.system(size: 15)
    /// 12/18 — meta lines under a title.
    static let meta = Font.system(size: 12)
    /// 11, tracked — chips and captions.
    static let label = Font.system(size: 11, weight: .semibold)

    // MARK: - Category inks

    /// Given out in the order Categories were created, so archiving one never recolors the others.
    /// The first is the Stitch primary, which is where 中文 lands; the rest are warmed to sit on the
    /// same paper without arguing with it.
    private static let categoryInks: [Color] = [
        Color(hex: 0x973312), Color(hex: 0x2F5673), Color(hex: 0x45664E),
        Color(hex: 0x794A07), Color(hex: 0x5E4A7A), Color(hex: 0x3F6A6E),
    ]

    static func categoryInk(at index: Int) -> Color {
        categoryInks[index % categoryInks.count]
    }

    /// Inks follow creation order across all Categories, so archiving one doesn't recolor the others.
    static func categoryInk(for category: Category?, among allCategories: [Category]) -> Color {
        guard let category, let index = allCategories.firstIndex(where: { $0.id == category.id }) else {
            return muted
        }
        return categoryInk(at: index)
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

// MARK: - Components

/// A group of rows on its own surface, the shape the whole app is built from.
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}

/// A small tracked label on its own ground: 未完, 完, 一次性, 从昨天推到今天.
struct Chip: View {
    let text: LocalizedStringKey
    var ink: Color = Theme.muted
    var ground: Color = Theme.cardHigh

    var body: some View {
        Text(text)
            .font(Theme.label)
            .tracking(0.5)
            .foregroundStyle(ink)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(ground)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

/// A small red caption with a heavier red rule under it.
struct SectionCaption: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(Theme.label)
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
            .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.rule))
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
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
    }
}
