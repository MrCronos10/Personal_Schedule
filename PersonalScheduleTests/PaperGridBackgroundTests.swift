import SwiftUI
import Testing
@testable import PersonalSchedule

@MainActor
struct PaperGridBackgroundTests {
    @Test func theWatermarkIsFaint() {
        #expect(PaperGridBackground.gridOpacity(for: .light) == 0.06)
        #expect(PaperGridBackground.gridOpacity(for: .dark) == 0.04)
    }

    @Test func oneCellIsEightyEightPoints() {
        #expect(PaperGridBackground.cellSize == 88)
    }

    @Test func theBackgroundRendersInBothModes() throws {
        for scheme in [ColorScheme.light, .dark] {
            let renderer = ImageRenderer(content: PaperGridBackground().frame(width: 200, height: 200).environment(\.colorScheme, scheme))
            renderer.scale = 1
            #expect(renderer.uiImage != nil)
        }
    }
}
