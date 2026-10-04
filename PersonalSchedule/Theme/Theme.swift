import SwiftUI

/// The practice-book hybrid, from docs/design-v1.md and ADR 0009. Every colour below is a role that
/// resolves to a light or a dark value, so a screen written against `Theme.paper` is already right at
/// night: dark mode keeps the paper warm and the ink light rather than switching to a generic theme.
///
/// Two things are kept from the 田字格 practice book: the boxed 今天 header (`TianZiGeTitle`) and the
/// red 完 seal on a ticked Action.
///
/// Type stays Noto Serif SC for Chinese and Latin alike. It is the same typeface as Source Han Serif
/// (Adobe's name for it), already bundled, and a second face to render a few English words is not
/// worth its weight.
enum Theme {
    /// The brief's eight named colours, as light-mode values. The roles below are built from these.
    enum Palette {
        static let paperCream = Color(hex: 0xFAF6EC)
        static let nightInk = Color(hex: 0x1C1A17)
        static let inkBlack = Color(hex: 0x1C1A17)
        static let lanternCream = Color(hex: 0xE8DEC5)
        static let gridRed = Color(hex: 0xC8382E)
        static let sealRed = Color(hex: 0x8B2A1F)
        static let bambooGreen = Color(hex: 0x6B8E4E)
        static let fadedInk = Color(hex: 0x6B655C)
    }

    // MARK: - Surfaces

    static let paper = Color.adaptive(light: 0xFAF6EC, dark: 0x1C1A17)
    /// Where a group of rows sits: Category sections, the Level meter, the Weekly Target rows.
    static let card = Color.adaptive(light: 0xF0EADB, dark: 0x26231F)
    /// A chip or a field sitting on top of a card, which needs to lift off it.
    static let cardHigh = Color.adaptive(light: 0xE8E0CD, dark: 0x302C27)

    // MARK: - Ink

    static let ink = Color.adaptive(light: 0x1C1A17, dark: 0xE8DEC5)
    /// Faded ink: secondary text, metadata, inactive tab icons.
    static let muted = Color.adaptive(light: 0x6B655C, dark: 0xA69F93)
    /// Grid red: 田字格 lines, the logo, the one highlight colour. Used sparingly.
    static let red = Color.adaptive(light: 0xC8382E, dark: 0xA3362E)
    /// Seal red: pressed states, header rules, completion stamps.
    static let sealRed = Color.adaptive(light: 0x8B2A1F, dark: 0x6E2419)
    static let rule = Color.adaptive(light: 0xDEC8BA, dark: 0x4D443C)
    /// Late One-time Actions and Missed Routine days. Both are "behind" and share one ink.
    static let late = Color.adaptive(light: 0x794A07, dark: 0xD4A257)
    static let error = Color.adaptive(light: 0xBA1A1A, dark: 0xFF8A80)

    /// Bamboo green has one job: something is done or mastered.
    static let bambooGreen = Color.adaptive(light: 0x6B8E4E, dark: 0x7FA060)
    /// A finished thing: the 完 chip, a Passed Level.
    static let done = Color.adaptive(light: 0xDCE8CF, dark: 0x2F4A36)
    static let onDone = Color.adaptive(light: 0x3E5A2C, dark: 0xB5D8A0)

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

    /// 28 — the largest heading inside a screen's content.
    static let display = serif(28)
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
    /// 17 at line height 1.9 — Chinese reading text, where cramped lines are the first thing that
    /// makes a page feel hostile. Pair with `readingLineSpacing`.
    static let reading = Font.system(size: 17)
    static let readingLineSpacing: CGFloat = 17 * 0.9
    /// SF Mono for counts ("128 / 600"), so digits keep one width and a row doesn't jitter as it grows.
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

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
    /// A colour that resolves to `light` or `dark` by the trait collection it is drawn in.
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }

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
