import SwiftUI
import Testing
@testable import PersonalSchedule

/// The four named grounds from docs/design-v2/brief.md (Screen grounds). Each pins the one or two
/// numeric values the brief fixes, plus "renders in both modes" — the same shape as
/// `PaperGridBackgroundTests`. Everything else about how they look is judged on the phone.
@MainActor
struct GroundsTests {
    @Test func dawnHeaderIsTwoHundredFiftyTall() {
        #expect(DawnHeader.height == 250)
    }

    /// Foliage sits at 14–18% green so it reads as texture, never UI.
    @Test func bambooFoliageIsFaintGreen() {
        #expect((0.14...0.18).contains(BambooBackground.stemOpacity))
        #expect((0.14...0.18).contains(BambooBackground.leafOpacity))
    }

    @Test func nightBandHasRoundedBottomCorners() {
        #expect(NightBand.cornerRadius == 20)
        #expect(NightBand.defaultHeaderHeight == 150)
    }

    @Test func lacquerTilesAreFaint() {
        #expect(LacquerBackground.tileSize == 64)
        #expect(LacquerBackground.tileOpacity <= 0.08)
    }

    @Test func allGroundsRenderInBothModes() throws {
        let grounds: [AnyView] = [
            AnyView(DawnHeader()), AnyView(BambooBackground()),
            AnyView(NightBand()), AnyView(LacquerBackground()),
        ]
        for scheme in [ColorScheme.light, .dark] {
            for ground in grounds {
                let renderer = ImageRenderer(content: ground.frame(width: 200, height: 300).environment(\.colorScheme, scheme))
                renderer.scale = 1
                #expect(renderer.uiImage != nil)
            }
        }
    }
}
