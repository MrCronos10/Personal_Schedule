import SwiftUI
import Testing
import UIKit
@testable import PersonalSchedule

struct ThemeTests {
    private func hex(_ color: Color, in style: UIUserInterfaceStyle) -> UInt32 {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let r = UInt32((red * 255).rounded()), g = UInt32((green * 255).rounded()), b = UInt32((blue * 255).rounded())
        return r << 16 | g << 8 | b
    }

    /// The one rule that makes "no token is missing a dark value" true rather than honour-system:
    /// walk every case of the single `Theme.Token` source. A token whose light equals its dark is a
    /// bug — someone forgot the dark value — unless it is one of the two deliberately mode-invariant
    /// tokens (`onRed` stays light on red in both modes; `lacquer` is one lacquer in both).
    @Test func everyTokenResolvesInBothSchemes() {
        let modeInvariant: Set<Theme.Token> = [.onRed, .lacquer]
        for token in Theme.Token.allCases {
            if modeInvariant.contains(token) {
                #expect(token.light == token.dark, "\(token) is meant to be mode-invariant")
            } else {
                #expect(token.light != token.dark, "\(token) is missing a distinct dark value")
            }
        }
    }

    /// The brief's Colour table (docs/design-v2/brief.md), read straight off the single token source.
    /// Folds in the old light-only `Palette` reference check.
    @Test func theBriefColourTableIsHonoured() {
        #expect(Theme.Token.paper.light == 0xFAF6EC); #expect(Theme.Token.paper.dark == 0x1C1A17)
        #expect(Theme.Token.ink.light == 0x1C1A17);   #expect(Theme.Token.ink.dark == 0xE8DEC5)
        #expect(Theme.Token.muted.light == 0x6B655C)                                   // brief's fadedInk
        #expect(Theme.Token.red.light == 0xC8382E);   #expect(Theme.Token.red.dark == 0xA3362E)   // gridRed
        #expect(Theme.Token.sealRed.light == 0x8B2A1F); #expect(Theme.Token.sealRed.dark == 0x6E2419)
        // bamboo: renamed from bambooGreen, light value moved to the brief's 0x4F6B38
        #expect(Theme.Token.bamboo.light == 0x4F6B38); #expect(Theme.Token.bamboo.dark == 0x7FA060)
        // new v2 tokens
        #expect(Theme.Token.brass.light == 0xB08A2E);  #expect(Theme.Token.brass.dark == 0xC9A44A)
        #expect(Theme.Token.lacquer.light == 0x2A1F1A); #expect(Theme.Token.lacquer.dark == 0x2A1F1A)
        #expect(Theme.Token.bambooPaper.light == 0xF1F1E4); #expect(Theme.Token.bambooPaper.dark == 0x1F211A)
        #expect(Theme.Token.dawnHill1.light == 0xF6EDDA)
        #expect(Theme.Token.dawnHill2.light == 0xEBDDC0)
        #expect(Theme.Token.dawnHill3.light == 0xF1E6CF)
    }

    /// Every named accessor is wired to the right `Token`, in both schemes. Without this a mis-wire
    /// such as `static let card = Token.cardHigh.color` would pass every other test and ship the wrong
    /// surface colour. The list is exhaustive against the UI-role accessors; texture-only tokens such
    /// as `gridLine` have no `Theme.` accessor (read raw by their one ground) and so are absent here,
    /// still covered by `everyTokenResolvesInBothSchemes`.
    @Test func namedAccessorsAreWiredToTheirTokens() {
        let wiring: [(Color, Theme.Token)] = [
            (Theme.paper, .paper), (Theme.card, .card), (Theme.cardHigh, .cardHigh),
            (Theme.ink, .ink), (Theme.muted, .muted), (Theme.red, .red), (Theme.onRed, .onRed),
            (Theme.sealRed, .sealRed), (Theme.rule, .rule), (Theme.late, .late), (Theme.error, .error),
            (Theme.bamboo, .bamboo), (Theme.done, .done), (Theme.onDone, .onDone),
            (Theme.brass, .brass), (Theme.lacquer, .lacquer), (Theme.bambooPaper, .bambooPaper),
            (Theme.nightBand, .nightBand),
            (Theme.dawnHill1, .dawnHill1), (Theme.dawnHill2, .dawnHill2), (Theme.dawnHill3, .dawnHill3),
        ]
        for (color, token) in wiring {
            #expect(hex(color, in: .light) == token.light, "\(token) accessor is mis-wired (light)")
            #expect(hex(color, in: .dark) == token.dark, "\(token) accessor is mis-wired (dark)")
        }
    }

    /// The 田字格 line is defined as gridRed on cream and lantern cream on night ink, so its token is
    /// derived from `red` and `ink` rather than copying their hex. This guards that: retuning red or
    /// ink moves the grid line with them instead of leaving a stale duplicate behind.
    @Test func gridLineTracksGridRedAndLanternCream() {
        #expect(Theme.Token.gridLine.light == Theme.Token.red.light)
        #expect(Theme.Token.gridLine.dark == Theme.Token.ink.dark)
    }

    /// The named accessors are the token source resolved by trait collection: paper stays warm and ink
    /// stays light at night rather than switching to a generic theme.
    @Test func darkModeKeepsThePaperWarmAndTheInkLight() {
        #expect(hex(Theme.paper, in: .light) == 0xFAF6EC)
        #expect(hex(Theme.paper, in: .dark) == 0x1C1A17)
        #expect(hex(Theme.ink, in: .light) == 0x1C1A17)
        #expect(hex(Theme.ink, in: .dark) == 0xE8DEC5)
        #expect(hex(Theme.red, in: .light) == 0xC8382E)
        #expect(hex(Theme.red, in: .dark) == 0xA3362E)
    }

    /// Text on a red ground (seals, 难, the red button) must stay light in both modes: `paper` turns
    /// near-black at night, which on a dark red is unreadable.
    @Test func textOnRedIsLightInBothModes() {
        #expect(hex(Theme.onRed, in: .light) == 0xFAF6EC)
        #expect(hex(Theme.onRed, in: .dark) == 0xFAF6EC)
    }
}
