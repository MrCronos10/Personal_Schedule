import SwiftUI
import Testing
@testable import PersonalSchedule

@MainActor
struct BackgroundViewTests {
    @Test func theWatermarkIsFaint() {
        #expect(BackgroundView.gridOpacity(for: .light) == 0.05)
        #expect(BackgroundView.gridOpacity(for: .dark) == 0.04)
    }

    @Test func oneCellIsEightyEightPoints() {
        #expect(BackgroundView.cellSize == 88)
    }

    @Test func theBackgroundRendersInBothModes() throws {
        for scheme in [ColorScheme.light, .dark] {
            let renderer = ImageRenderer(content: BackgroundView().frame(width: 200, height: 200).environment(\.colorScheme, scheme))
            renderer.scale = 1
            #expect(renderer.uiImage != nil)
        }
    }
}
