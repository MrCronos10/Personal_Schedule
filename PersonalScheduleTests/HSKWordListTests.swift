import Foundation
import Testing
@testable import PersonalSchedule

/// The bundled Word Lists. HSK 4 is 600 words and HSK 5 is 1,300, counting each level's new words
/// only: these totals are the denominator of the year's Known count, so they are tested, not assumed.
/// See CONTEXT.md and ADR 0005.
struct HSKWordListTests {
    @Test func hskFourHoldsSixHundredWords() throws {
        #expect(HSKWordList.words(at: .four).count == 600)
    }

    @Test func hskFiveHoldsThirteenHundredWords() throws {
        #expect(HSKWordList.words(at: .five).count == 1300)
    }

    /// A Level's total is the denominator of the year's Known count, and ADR 0005 fixes it at 600
    /// and 1,300. Nothing may hold a second copy of those numbers: a Level reporting 612 / 600, or
    /// Passed landing at the wrong point, is the failure this guards.
    @Test func aLevelsTotalIsWhatItsListActuallyHolds() throws {
        for level in HSKLevel.allCases {
            #expect(level.total == HSKWordList.words(at: level).count)
        }
        #expect(HSKLevel.four.total == 600)
        #expect(HSKLevel.five.total == 1300)
    }

    /// A third of these lists is single characters, and a character's reading depends on which
    /// sense is meant. A wrong pinyin teaches the student the wrong word, which they then bank
    /// three Clean Sightings on, so the readings that were once wrong are held down by name.
    @Test func polyphonicCharactersCarryTheReadingHSKMeans() throws {
        let expected: [String: String] = [
            "圈": "quān",  // not juān, a pen for animals
            "切": "qiē",   // not qiè, "definitely"
            "趟": "tàng",  // not tāng, to wade
            "吓": "xià",   // not hè
            "薄": "báo",   // not bó
            "朝": "cháo",
            "当": "dāng",
            "丑": "chǒu",
            "台": "tái",
            "重": "zhòng", // not chóng, to repeat
            "空": "kōng",
            "干": "gàn",
        ]
        for (word, pinyin) in expected {
            #expect(HSKWordList.entry(for: word)?.pinyin == pinyin, "\(word) should read \(pinyin)")
        }
    }

    /// The same characters, on the meaning side: 克 is a gram, not "to subdue"; 丑 is ugly, not a
    /// clown. These came from CC-CEDICT senses that HSK does not mean.
    @Test func charactersCarryTheSenseHSKMeans() throws {
        #expect(HSKWordList.entry(for: "克")?.english.contains("gram") == true)
        #expect(HSKWordList.entry(for: "丑")?.english.contains("ugly") == true)
        #expect(HSKWordList.entry(for: "咸")?.english.contains("salty") == true)
        #expect(HSKWordList.entry(for: "刚")?.english.contains("just now") == true)
        #expect(HSKWordList.entry(for: "云")?.english.contains("cloud") == true)
    }

    /// A gloss is a reminder, not a dictionary entry: no surnames, no cross-references, no hanzi
    /// left inside the English, and no bracket cut open by the length limit.
    @Test func everyGlossReadsAsAReminder() throws {
        for entry in HSKWordList.all {
            #expect(entry.english.count <= 71, "\(entry.word): \(entry.english)")
            #expect(
                entry.english.filter { $0 == "(" }.count
                    == entry.english.filter { $0 == ")" }.count,
                "\(entry.word) has an unclosed bracket: \(entry.english)"
            )
            #expect(!entry.english.contains("CL:"), "\(entry.word) carries a classifier note")
            #expect(!entry.english.lowercased().hasPrefix("variant of"), "\(entry.word)")
            #expect(!entry.english.lowercased().hasPrefix("surname "), "\(entry.word)")
            #expect(
                !entry.english.contains(where: { $0.unicodeScalars.contains { (0x4E00...0x9FFF).contains($0.value) } }),
                "\(entry.word) carries hanzi in its English: \(entry.english)"
            )
        }
    }

    @Test func noWordIsInBothLists() throws {
        let four = Set(HSKWordList.words(at: .four).map(\.word))
        let five = Set(HSKWordList.words(at: .five).map(\.word))
        #expect(four.intersection(five).isEmpty)
    }

    @Test func anHSKFourWordResolvesWithItsPinyinAndEnglish() throws {
        let entry = try #require(HSKWordList.entry(for: "厕所"))
        #expect(entry.level == .four)
        #expect(entry.pinyin == "cè suǒ")
        #expect(entry.english.contains("toilet"))
    }

    @Test func anHSKFiveWordResolvesAtLevelFive() throws {
        #expect(HSKWordList.level(of: "被子") == .five)
    }

    /// The boundary in ADR 0005: HSK 1-3 is assumed known and is not measured. This is the test
    /// that catches a cumulative list being bundled by mistake, which would look like nothing at all.
    @Test func anHSKOneToThreeWordIsNotInAnyList() throws {
        #expect(HSKWordList.level(of: "很") == nil)
        #expect(HSKWordList.level(of: "学习") == nil)
        #expect(HSKWordList.entry(for: "很") == nil)
    }

    @Test func somethingThatIsNotAWordResolvesToNothing() throws {
        #expect(HSKWordList.level(of: "") == nil)
        #expect(HSKWordList.level(of: "hello") == nil)
        #expect(HSKWordList.level(of: "。") == nil)
    }

    @Test func everyEntryCarriesAWordAPinyinAndAnEnglish() throws {
        for entry in HSKWordList.all {
            #expect(!entry.word.isEmpty)
            #expect(!entry.pinyin.isEmpty)
            #expect(!entry.english.isEmpty)
        }
    }

    /// The official list separates a grammar word's senses: 得（助动词）is HSK 4 while bare 得 is not.
    /// The annotation is kept, so these never match a word split out of an Article and are only ever
    /// met in Daily New Words, where the annotation says which sense is meant.
    @Test func grammarEntriesKeepTheirAnnotationAndAreMarked() throws {
        let grammar = HSKWordList.all.filter(\.isGrammarEntry)
        #expect(grammar.count == 2)
        #expect(grammar.allSatisfy { $0.word.contains("（") })
        #expect(HSKWordList.level(of: "得") == nil)
        #expect(HSKWordList.level(of: "等") == nil)
    }
}
