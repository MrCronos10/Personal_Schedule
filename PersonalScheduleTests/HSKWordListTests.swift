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
