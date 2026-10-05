import SwiftUI
import Testing
import UIKit
@testable import PersonalSchedule

@MainActor
struct FontRegistryTests {
    /// Every bundled face registers and is reachable by its PostScript name — the two Noto `.otf`
    /// faces and the Ma Shan Zheng brush `.ttf`.
    @Test func everyBundledFontLoads() {
        FontRegistry.registerBundledFonts()
        for name in FontRegistry.bundledFonts {
            #expect(UIFont(name: name, size: 17) != nil, "\(name) did not register")
        }
    }

    /// The brush face specifically: seals and headline grid cells use it, so it must load.
    @Test func theBrushFontLoads() {
        FontRegistry.registerBundledFonts()
        #expect(UIFont(name: "MaShanZheng-Regular", size: 17) != nil)
    }
}
