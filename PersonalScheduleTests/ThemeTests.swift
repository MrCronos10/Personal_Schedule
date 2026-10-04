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

    @Test func theEightPaletteColoursMatchTheBrief() {
        #expect(hex(Theme.Palette.paperCream, in: .light) == 0xFAF6EC)
        #expect(hex(Theme.Palette.nightInk, in: .light) == 0x1C1A17)
        #expect(hex(Theme.Palette.inkBlack, in: .light) == 0x1C1A17)
        #expect(hex(Theme.Palette.lanternCream, in: .light) == 0xE8DEC5)
        #expect(hex(Theme.Palette.gridRed, in: .light) == 0xC8382E)
        #expect(hex(Theme.Palette.sealRed, in: .light) == 0x8B2A1F)
        #expect(hex(Theme.Palette.bambooGreen, in: .light) == 0x6B8E4E)
        #expect(hex(Theme.Palette.fadedInk, in: .light) == 0x6B655C)
    }

    @Test func theTokensExistInLightAndDark() {
        let roles: [(String, Color)] = [
            ("paper", Theme.paper), ("card", Theme.card), ("cardHigh", Theme.cardHigh),
            ("ink", Theme.ink), ("muted", Theme.muted), ("red", Theme.red), ("rule", Theme.rule),
            ("late", Theme.late), ("error", Theme.error), ("done", Theme.done), ("onDone", Theme.onDone),
            ("sealRed", Theme.sealRed), ("bambooGreen", Theme.bambooGreen),
        ]
        for (name, color) in roles {
            #expect(hex(color, in: .light) != hex(color, in: .dark), "\(name) has no dark variant")
        }
    }

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
