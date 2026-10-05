import SwiftUI
import Testing
import UIKit
@testable import PersonalSchedule

@MainActor
struct LogoViewTests {
    private func render(_ scheme: ColorScheme) -> UIImage? {
        let renderer = ImageRenderer(content: LogoView(size: 128).environment(\.colorScheme, scheme))
        renderer.scale = 1
        return renderer.uiImage
    }

    @Test func theLogoRendersInLightAndDark() throws {
        let light = try #require(render(.light))
        let dark = try #require(render(.dark))

        #expect(light.size == CGSize(width: 128, height: 128))
        #expect(dark.size == CGSize(width: 128, height: 128))
        #expect(light.pngData() != dark.pngData())
    }

    /// The dashed cross and the 日 chop show only above 40 pt (brief: "At ≤ 40 pt drop the dashed
    /// cross and the chop"). At small sizes the mark is just 读 in its box.
    @Test func detailsShowOnlyAboveFortyPoints() {
        #expect(LogoView.showsDetails(at: 128))
        #expect(LogoView.showsDetails(at: 41))
        #expect(!LogoView.showsDetails(at: 40))
        #expect(!LogoView.showsDetails(at: 24))
    }
}
