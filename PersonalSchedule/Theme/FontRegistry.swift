import CoreText
import Foundation

/// Loads the Noto Serif SC fonts shipped inside the app (SIL Open Font License, see Fonts/NotoSerifSC-OFL.txt).
/// iPhones have no Song font built in, so the app brings its own.
enum FontRegistry {
    static let bundledFonts = ["NotoSerifSC-Bold", "NotoSerifSC-Black"]

    static func registerBundledFonts() {
        for name in bundledFonts {
            guard let url = Bundle.main.url(forResource: name, withExtension: "otf")
                ?? Bundle.main.url(forResource: name, withExtension: "otf", subdirectory: "Fonts")
            else {
                assertionFailure("Missing font file \(name).otf")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
