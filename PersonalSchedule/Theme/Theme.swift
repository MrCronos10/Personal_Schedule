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
    /// One row of the brief's Colour table (docs/design-v2/brief.md): a role and its light/dark hex.
    /// This enum is the single source of truth for colour — the named accessors below (`Theme.paper`,
    /// …) are this table resolved by trait collection, and `ThemeTests.everyTokenResolvesInBothSchemes`
    /// walks `allCases`, so a token added here without a distinct dark value can't ship silently.
    ///
    /// Names keep v1's role vocabulary, which differs from the brief's in two places: `red` is the
    /// brief's gridRed, and `muted` is its fadedInk. Everything else matches the brief by name.
    enum Token: CaseIterable {
        // Surfaces
        case paper, card, cardHigh
        // Ink and lines
        case ink, muted, red, onRed, sealRed, rule, late, error
        // Texture: the 田字格 line (gridRed on cream, lantern cream on night ink). Read raw by its
        // one ground (`PaperGridBackground`), never a general UI role — so it has no `Theme.` accessor.
        case gridLine
        // Done / mastery — `bamboo` is the brief's "done only" green
        case bamboo, done, onDone
        // v2 additions: Seal Book / Progress accents and the per-screen grounds
        case brass, lacquer, bambooPaper, nightBand
        case dawnHill1, dawnHill2, dawnHill3

        var light: UInt32 {
            switch self {
            case .paper: 0xFAF6EC
            case .card: 0xF0EADB
            case .cardHigh: 0xE8E0CD
            case .ink: 0x1C1A17
            case .muted: 0x6B655C
            case .red: 0xC8382E
            case .onRed: 0xFAF6EC
            case .sealRed: 0x8B2A1F
            case .rule: 0xDEC8BA
            case .late: 0x794A07
            case .error: 0xBA1A1A
            case .gridLine: Self.red.light      // the 田字格 line is gridRed on cream — derived, never a copy
            case .bamboo: 0x4F6B38
            case .done: 0xDCE8CF
            case .onDone: 0x3E5A2C
            case .brass: 0xB08A2E
            case .lacquer: 0x2A1F1A
            case .bambooPaper: 0xF1F1E4
            case .nightBand: 0x1C1A17           // ink-black as a surface — its own role, independent of text `ink`
            case .dawnHill1: 0xF6EDDA
            case .dawnHill2: 0xEBDDC0
            case .dawnHill3: 0xF1E6CF
            }
        }

        var dark: UInt32 {
            switch self {
            case .paper: 0x1C1A17
            case .card: 0x26231F
            case .cardHigh: 0x302C27
            case .ink: 0xE8DEC5
            case .muted: 0xA69F93
            case .red: 0xA3362E
            case .onRed: 0xFAF6EC             // deliberately mode-invariant: light cream on any red
            case .sealRed: 0x6E2419
            case .rule: 0x4D443C
            case .late: 0xD4A257
            case .error: 0xFF8A80
            case .gridLine: Self.ink.dark       // lantern cream on night ink — derived from ink, never a copy
            case .bamboo: 0x7FA060
            case .done: 0x2F4A36
            case .onDone: 0xB5D8A0
            case .brass: 0xC9A44A
            case .lacquer: 0x2A1F1A           // deliberately mode-invariant: one lacquer ground
            case .bambooPaper: 0x1F211A
            case .nightBand: 0x2A2622         // proposal: a touch lifted from dark paper so the band reads
            // Dawn hills at night are proposals (brief: "dark equivalents") — judged on the phone.
            case .dawnHill1: 0x2A2622
            case .dawnHill2: 0x322C25
            case .dawnHill3: 0x3A322A
            }
        }

        /// The role resolved to a light or dark value by the trait collection it is drawn in.
        var color: Color { .adaptive(light: light, dark: dark) }
    }

    // The named accessors below are each the token resolved once (`static let`, not a computed
    // `var`): the adaptive `UIColor` still switches light/dark at draw time, but the wrapper is
    // built a single time rather than on every SwiftUI body re-evaluation.

    // MARK: - Surfaces

    static let paper = Token.paper.color
    /// Where a group of rows sits: Category sections, the Level meter, the Weekly Target rows.
    static let card = Token.card.color
    /// A chip or a field sitting on top of a card, which needs to lift off it.
    static let cardHigh = Token.cardHigh.color

    // MARK: - Ink

    static let ink = Token.ink.color
    /// Faded ink (brief's fadedInk): secondary text, metadata, inactive tab icons.
    static let muted = Token.muted.color
    /// Grid red (brief's gridRed): 田字格 lines, the logo, the one highlight colour. Used sparingly.
    static let red = Token.red.color
    /// Text and borders on a red ground (seals, the red button). The same light cream in both modes:
    /// `paper` turns near-black at night, which on a dark red is unreadable.
    static let onRed = Token.onRed.color
    /// Seal red: pressed states, header rules, completion stamps.
    static let sealRed = Token.sealRed.color
    static let rule = Token.rule.color
    /// Late One-time Actions and Missed Routine days. Both are "behind" and share one ink.
    static let late = Token.late.color
    static let error = Token.error.color

    // MARK: - Done / mastery

    /// Bamboo green has one job: something is done or mastered.
    static let bamboo = Token.bamboo.color
    /// A finished thing: the 完 chip, a Passed Level.
    static let done = Token.done.color
    static let onDone = Token.onDone.color

    // MARK: - v2 grounds and accents

    /// Brass: rare seals and a passed line. Dark value is a proposal — checked on the phone.
    static let brass = Token.brass.color
    /// Lacquer: the Seal Book ground, the one dark screen in light mode.
    static let lacquer = Token.lacquer.color
    /// Bamboo paper: the 词 ground. Dark value is a proposal — checked on the phone.
    static let bambooPaper = Token.bambooPaper.color
    /// Night band: the 进度 header surface — ink in light mode, a lifted dark at night (proposal).
    static let nightBand = Token.nightBand.color
    /// The three layered hills of the 今天 Dawn header, far to near. Dark values are proposals.
    static let dawnHill1 = Token.dawnHill1.color
    static let dawnHill2 = Token.dawnHill2.color
    static let dawnHill3 = Token.dawnHill3.color

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
            .foregroundStyle(Theme.onRed)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Theme.red.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
    }
}
