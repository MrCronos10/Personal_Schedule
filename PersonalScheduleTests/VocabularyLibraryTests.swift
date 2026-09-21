import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// Splitting an **Article** into Words, and what a **Lookup** does to one. See CONTEXT.md,
/// and ADR 0004 for why a Lookup is destructive.
@MainActor
struct VocabularyLibraryTests {
    private func library() throws -> VocabularyLibrary {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        return VocabularyLibrary(context: ModelContext(container))
    }

    // MARK: - Splitting

    @Test func aSentenceSplitsIntoWordsNotCharacters() throws {
        let words = VocabularyLibrary.segment("我是中国人").map(\.text)
        #expect(words.contains("中国"))
        #expect(!words.contains("中"))
        #expect(!words.contains("国"))
    }

    /// How much of the two Word Lists the tokenizer can reach at all. A Word that cannot be found
    /// even on its own can never be underlined, looked up, or reach Known — it would be missing
    /// from the year's count with nothing on screen to say so. This is the floor; the test below
    /// checks words inside real prose, which is the harder case.
    @Test func everyWordInTheListCanBeFoundAtAll() throws {
        let missed = HSKWordList.all
            .filter { !$0.isGrammarEntry }
            .filter { entry in
                !VocabularyLibrary.hskWords(in: entry.word).contains(entry)
            }
        #expect(missed.isEmpty, "\(missed.count) words cannot be found: \(missed.prefix(25).map(\.word))")
    }

    @Test func punctuationAndNumbersAreNotOfferedAsWords() throws {
        let words = VocabularyLibrary.segment("今天是2026年，天气很好。").map(\.text)
        #expect(!words.contains("，"))
        #expect(!words.contains("。"))
        #expect(words.contains("今天"))
    }

    /// The screen draws the Article as it was written and underlines words in place, so every word
    /// has to point back at the characters it came from.
    @Test func eachWordPointsBackAtTheTextItCameFrom() throws {
        let text = "我喜欢喝茶。"
        for word in VocabularyLibrary.segment(text) {
            #expect(String(text[word.range]) == word.text)
        }
    }

    @Test func latinAndSpacesSurviveSegmentation() throws {
        let words = VocabularyLibrary.segment("我用 iPhone 看书").map(\.text)
        #expect(words.contains("看书") || words.contains("书"))
        #expect(!words.contains(" "))
    }

    // MARK: - Which words count

    @Test func onlyHSKFourAndFiveWordsCount() throws {
        // 厕所 is HSK 4, 被子 is HSK 5, 很 is HSK 1-3 and is not measured.
        let found = VocabularyLibrary.hskWords(in: "厕所很干净，被子很软。").map(\.word)
        #expect(found.contains("厕所"))
        #expect(found.contains("被子"))
        #expect(!found.contains("很"))
    }

    @Test func aWordRepeatedInOneArticleIsCountedOnce() throws {
        let found = VocabularyLibrary.hskWords(in: "厕所。厕所。厕所。").map(\.word)
        #expect(found == ["厕所"])
    }

    /// The same question, inside real sentences rather than on their own, which is where the
    /// tokenizer makes its own choices about where a word ends.
    @Test func wordsAreFoundInsideRealProse() throws {
        let prose = """
        今天下午我去了杭州的茶馆，跟老板聊了很久。他说这种龙井的味道特别香，        建议我买一点带回去。我觉得价格有点贵，不过质量确实不错。离开的时候，        我顺便参观了旁边的名胜古迹，还听见有人在弹钢琴。
        """
        let found = Set(VocabularyLibrary.hskWords(in: prose).map(\.word))
        for word in ["建议", "价格", "不过", "质量", "顺便", "参观", "名胜古迹", "弹钢琴", "味道"] {
            #expect(found.contains(word), "\(word) was not found in ordinary prose")
        }
    }

    /// The tokenizer's idea of a word is not the Word List's: these arrive in pieces and have to be
    /// put back together, or they are invisible for the whole year.
    @Test func wordsTheTokenizerSplitsAreFoundAnyway() throws {
        #expect(VocabularyLibrary.hskWords(in: "这不过是个小问题。").map(\.word).contains("不过"))
        #expect(VocabularyLibrary.hskWords(in: "她会弹钢琴。").map(\.word).contains("弹钢琴"))
        #expect(VocabularyLibrary.hskWords(in: "杭州有很多名胜古迹。").map(\.word).contains("名胜古迹"))
    }

    /// Joining must work from the tokenizer's boundaries, never by scanning the raw text, or a Word
    /// would be found straddling two real words.
    @Test func joiningDoesNotInventWordsAcrossABoundary() throws {
        // 国王 is HSK 5. It must not be found inside 中国 + 王子.
        #expect(!VocabularyLibrary.hskWords(in: "中国王子").map(\.word).contains("国王"))
    }

    /// A grammar entry keeps its 词性 annotation, so no word split out of an Article can ever match
    /// it. Bare 得 must not be underlined in every sentence the student reads.
    @Test func grammarEntriesNeverMatchAWordInAnArticle() throws {
        let found = VocabularyLibrary.hskWords(in: "我得走了，等一下。").map(\.word)
        #expect(!found.contains("得"))
        #expect(!found.contains("等"))
        #expect(!found.contains("得（助动词）"))
    }

    // MARK: - Looking a word up

    @Test func aLookupIsRecordedAgainstItsArticle() throws {
        let shelf = try library()
        let article = try ArticleLibrary(context: shelf.context).add(text: "厕所\n正文")
        try shelf.lookUp("厕所", in: article, on: Day(number: 20260921))

        let lookups = try shelf.lookups(of: "厕所", in: article)
        #expect(lookups.count == 1)
        #expect(lookups.first?.day.number == 20260921)
    }

    @Test func aLookupOnAWordOutsideTheListRecordsNothing() throws {
        let shelf = try library()
        let article = try ArticleLibrary(context: shelf.context).add(text: "很\n正文")
        try shelf.lookUp("很", in: article, on: Day(number: 20260921))
        #expect(try shelf.lookups(of: "很", in: article).isEmpty)
        #expect(try shelf.progress(for: "很") == nil)
    }

    /// ADR 0004: a Lookup is evidence of not knowing. It returns the Word to zero, whenever it
    /// happens, so an untapped Word means something.
    @Test func aLookupReturnsAWordToZeroCleanSightings() throws {
        let shelf = try library()
        let article = try ArticleLibrary(context: shelf.context).add(text: "厕所\n正文")
        let progress = try #require(try shelf.progressCreatingIfNeeded(for: "厕所"))
        progress.cleanSightings = 2

        try shelf.lookUp("厕所", in: article, on: Day(number: 20260921))
        #expect(try shelf.progress(for: "厕所")?.cleanSightings == 0)
    }

    /// A Known Word is not taken back by one tap: only the student saying so does that.
    @Test func aLookupLeavesAKnownWordKnown() throws {
        let shelf = try library()
        let article = try ArticleLibrary(context: shelf.context).add(text: "厕所\n正文")
        try shelf.markKnown("厕所", on: Day(number: 20260901))

        try shelf.lookUp("厕所", in: article, on: Day(number: 20260921))
        let progress = try #require(try shelf.progress(for: "厕所"))
        #expect(progress.isKnown)
        #expect(progress.knownDay?.number == 20260901)
    }

    // MARK: - Saying so by hand

    @Test func markingAWordKnownByHandRecordsTheDay() throws {
        let shelf = try library()
        try shelf.markKnown("厕所", on: Day(number: 20260921))
        let progress = try #require(try shelf.progress(for: "厕所"))
        #expect(progress.isKnown)
        #expect(progress.knownDay?.number == 20260921)
        #expect(progress.level == .four)
    }

    @Test func markingAWordKnownLeavesItsCleanSightingsAlone() throws {
        let shelf = try library()
        let progress = try #require(try shelf.progressCreatingIfNeeded(for: "厕所"))
        progress.cleanSightings = 2
        try shelf.markKnown("厕所", on: Day(number: 20260921))
        #expect(try shelf.progress(for: "厕所")?.cleanSightings == 2)
    }

    /// 其实不认识 must clear the sightings too. Leaving three behind would make the Word Known again
    /// at the very next 读完, which would look like the app arguing with the student.
    @Test func takingKnownBackAlsoClearsTheEvidence() throws {
        let shelf = try library()
        let progress = try #require(try shelf.progressCreatingIfNeeded(for: "厕所"))
        progress.cleanSightings = 3
        try shelf.markKnown("厕所", on: Day(number: 20260921))

        try shelf.markNotKnown("厕所")
        let after = try #require(try shelf.progress(for: "厕所"))
        #expect(!after.isKnown)
        #expect(after.knownDay == nil)
        #expect(after.cleanSightings == 0)
    }

    @Test func aWordNeverMetHasNoRow() throws {
        #expect(try library().progress(for: "厕所") == nil)
    }

    @Test func aProgressRowRemembersItsLevel() throws {
        let shelf = try library()
        #expect(try shelf.progressCreatingIfNeeded(for: "被子")?.level == .five)
        #expect(try shelf.progressCreatingIfNeeded(for: "很") == nil)
    }
}
