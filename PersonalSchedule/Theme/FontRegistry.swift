import CoreText
import Foundation

/// Loads the fonts shipped inside the app, each under the SIL Open Font License (see the matching
/// `*-OFL.txt` in Fonts/). iPhones have no Song or brush face built in, so the app brings its own:
/// the two Noto Serif SC `.otf` faces for display/body, and Ma Shan Zheng (`.ttf`) as the brush face
/// for seals and headline grid cells (`Theme.brush`).
enum FontRegistry {
    static let bundledFonts = ["NotoSerifSC-Bold", "NotoSerifSC-Black", "MaShanZheng-Regular"]

    static func registerBundledFonts() {
        for name in bundledFonts {
            // Faces ship as either .otf (Noto) or .ttf (Ma Shan Zheng); try both, at the bundle root
            // or under Fonts/.
            let url = ["otf", "ttf"].lazy.compactMap { ext in
                Bundle.main.url(forResource: name, withExtension: ext)
                    ?? Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Fonts")
            }.first
            guard let url else {
                assertionFailure("Missing font file \(name)")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
