import Foundation
import Testing

/// Every piece of screen text lives in PersonalSchedule/Localizable.xcstrings.
/// The keys are the Chinese text; each one needs an English translation.
struct TranslationTests {
    private struct StringCatalog: Decodable {
        struct Entry: Decodable {
            struct Localization: Decodable {
                struct StringUnit: Decodable {
                    let state: String
                    let value: String
                }
                let stringUnit: StringUnit?
            }
            let shouldTranslate: Bool?
            let localizations: [String: Localization]?
        }
        let sourceLanguage: String
        let strings: [String: Entry]
    }

    private func loadCatalog() throws -> StringCatalog {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("PersonalSchedule/Localizable.xcstrings")
        return try JSONDecoder().decode(StringCatalog.self, from: Data(contentsOf: url))
    }

    @Test func screenTextIsWrittenInChinese() throws {
        let catalog = try loadCatalog()

        #expect(catalog.sourceLanguage == "zh-Hans")
        #expect(!catalog.strings.isEmpty)
    }

    @Test func everyScreenTextHasAnEnglishTranslation() throws {
        let catalog = try loadCatalog()

        let missing = catalog.strings
            .filter { _, entry in
                guard entry.shouldTranslate != false else { return false }
                guard let unit = entry.localizations?["en"]?.stringUnit else { return true }
                return unit.state != "translated" || unit.value.isEmpty
            }
            .keys
            .sorted()

        #expect(missing.isEmpty, "Missing English for: \(missing.joined(separator: ", "))")
    }
}
