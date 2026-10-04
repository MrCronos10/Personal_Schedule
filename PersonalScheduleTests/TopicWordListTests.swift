import Foundation
import Testing
@testable import PersonalSchedule

/// The bundled **Topic List**: 125 terms the student needs for their family's manure-to-fertilizer
/// business in Cambodia, split into six **Topic Groups**. See CONTEXT.md and ADR 0007.
///
/// The totals are the denominator of the Topic List's own number — a second meter beside the HSK
/// Levels, never folded into them — so they are tested, not assumed, the same way HSK 4's 600 is.
struct TopicWordListTests {
    @Test func theListHoldsOneHundredAndTwentyFiveTerms() throws {
        #expect(TopicWordList.all.count == 125)
    }

    @Test func sixGroupsEachHoldTheirKnownNumberOfTerms() throws {
        let expected: [TopicGroup: Int] = [
            .raw: 18, .ferment: 17, .soil: 27, .safety: 18, .plant: 22, .trade: 23,
        ]
        for group in TopicGroup.allCases {
            #expect(TopicWordList.words(in: group).count == expected[group],
                    "\(group) should hold \(expected[group]!) terms")
        }
    }

    @Test func everyTermTheStudentNamedIsInTheList() throws {
        // The thirteen words called out when this feature was agreed. Each must be findable by its
        // exact spelling, so the screen that lists them can tap on each one.
        let named = ["农业", "土壤", "肥料", "有机肥", "鸡粪", "猪粪", "堆肥",
                     "发酵", "氮磷钾", "微生物", "肥料生产", "肥料厂", "农业机械"]
        for word in named {
            #expect(TopicWordList.entry(for: word) != nil, "\(word) should be in the Topic List")
        }
    }

    @Test func noTermAppearsTwice() throws {
        let words = TopicWordList.all.map(\.word)
        #expect(Set(words).count == words.count)
    }

    @Test func everyEntryHasChinesePinyinAndEnglish() throws {
        for entry in TopicWordList.all {
            #expect(!entry.word.isEmpty)
            #expect(!entry.pinyin.isEmpty)
            #expect(!entry.english.isEmpty)
            #expect(!entry.english.contains("\n"))
        }
    }

    /// A term is in the Topic List because the student needs it for the fertilizer business, not
    /// because it is on an HSK list. Fourteen of them happen to be on both — 农业, 市场, 技术… — and
    /// those keep their own Topic entry here. Their HSK state is kept separate on purpose (ADR 0007),
    /// so what moves one number must not quietly move the other.
    @Test func aTermAlsoInHSKKeepsItsOwnEntry() throws {
        #expect(TopicWordList.entry(for: "农业") != nil)
        #expect(TopicWordList.entry(for: "市场") != nil)
        #expect(HSKWordList.entry(for: "农业") != nil)
        // Both lists carry the word, and they do so independently.
        #expect(TopicWordList.entry(for: "农业")?.group == .soil)
        #expect(TopicWordList.entry(for: "市场")?.group == .trade)
    }
}
