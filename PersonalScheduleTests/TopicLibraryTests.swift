import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// The **Topic List**'s rules: hand-marked **Topic Known**, the Topic List meter, and **Custom
/// Topic Words**. See CONTEXT.md and ADR 0007.
@MainActor
struct TopicLibraryTests {
    private func library() throws -> TopicLibrary {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        return TopicLibrary(context: ModelContext(container))
    }

    // MARK: - Separate from HSK

    /// Hand-marking a Topic Word writes to the Topic List's own row and nothing else. The HSK
    /// `WordProgress` for the same word, when there is one, stays as it was — ADR 0007's whole
    /// point. The HSK 4/5 totals pinned by `HSKWordListTests` are the independent guard, so this
    /// test proves the write path doesn't reach across.
    @Test func markingATopicWordNeverTouchesTheHSKRow() throws {
        let shelf = try library()
        // 农业 is on both lists.
        try shelf.markKnown("农业")
        let hskRows = try shelf.context.fetch(FetchDescriptor<WordProgress>(predicate: #Predicate { $0.word == "农业" }))
        #expect(hskRows.isEmpty, "the HSK row for 农业 must not be written by the Topic Library")
        #expect(try shelf.isKnown("农业"))
    }

    // MARK: - The meter

    @Test func theMeterStartsEmptyWithTheBundledTotal() throws {
        let m = try library().meter()
        #expect(m.known == 0)
        #expect(m.total == 125)
    }

    @Test func markingOneTermMovesTheMeterByOne() throws {
        let shelf = try library()
        try shelf.markKnown("堆肥")
        #expect(try shelf.meter().known == 1)
    }

    @Test func takingATermBackReturnsItToNotKnown() throws {
        let shelf = try library()
        try shelf.markKnown("堆肥")
        try shelf.takeKnownBack("堆肥")
        #expect(try shelf.isKnown("堆肥") == false)
        #expect(try shelf.meter().known == 0)
    }

    @Test func markingTheSameTermTwiceCountsOnce() throws {
        let shelf = try library()
        try shelf.markKnown("发酵")
        try shelf.markKnown("发酵")
        #expect(try shelf.meter().known == 1)
    }

    @Test func aWordNotOnTheListIsNeverCountedOrWritten() throws {
        let shelf = try library()
        let didMark = try shelf.markKnown("不存在的词")
        #expect(didMark == false)
        #expect(try shelf.meter().known == 0)
    }

    @Test func theGroupMeterShowsOnlyOneGroup() throws {
        let shelf = try library()
        try shelf.markKnown("鸡粪")   // raw
        try shelf.markKnown("堆肥")   // ferment
        #expect(try shelf.meter(in: .raw).known == 1)
        #expect(try shelf.meter(in: .ferment).known == 1)
        #expect(try shelf.meter(in: .plant).known == 0)
    }

    // MARK: - Custom Topic Words

    @Test func addingACustomWordRaisesTheTotalByOne() throws {
        let shelf = try library()
        let before = try shelf.meter()
        let result = try shelf.addCustom(word: "蚯蚓堆肥", pinyin: "qiū yǐn duī féi",
                                         english: "vermicompost", group: .ferment)
        #expect(result == .added)
        let after = try shelf.meter()
        #expect(after.total == before.total + 1)
        #expect(after.known == before.known)
    }

    @Test func aCustomWordCanBeMarkedKnown() throws {
        let shelf = try library()
        try shelf.addCustom(word: "蚯蚓堆肥", pinyin: "", english: "vermicompost", group: .ferment)
        try shelf.markKnown("蚯蚓堆肥")
        #expect(try shelf.isKnown("蚯蚓堆肥"))
        #expect(try shelf.meter().known == 1)
    }

    @Test func aDuplicateOfAStarterWordIsRefused() throws {
        let shelf = try library()
        let result = try shelf.addCustom(word: "鸡粪", pinyin: "", english: "x", group: .raw)
        #expect(result == .refused(.alreadyInList))
    }

    @Test func anEmptyOrNonChineseWordIsRefused() throws {
        let shelf = try library()
        #expect(try shelf.addCustom(word: "   ", pinyin: "", english: "x", group: .raw) == .refused(.emptyWord))
        #expect(try shelf.addCustom(word: "manure", pinyin: "", english: "x", group: .raw) == .refused(.notChinese))
        #expect(try shelf.addCustom(word: "新词", pinyin: "", english: "", group: .raw) == .refused(.emptyEnglish))
    }

    @Test func anArchivedCustomWordLeavesTheMeterAndComesBackWithItsKnownState() throws {
        let shelf = try library()
        try shelf.addCustom(word: "蚯蚓堆肥", pinyin: "", english: "vermicompost", group: .ferment)
        try shelf.markKnown("蚯蚓堆肥")
        let full = try shelf.meter()
        try shelf.archiveCustom("蚯蚓堆肥")
        let archived = try shelf.meter()
        #expect(archived.total == 125, "an archived Custom Topic Word leaves the denominator")
        #expect(archived.known == 0, "and leaves the known count")
        try shelf.restoreCustom("蚯蚓堆肥")
        #expect(try shelf.meter() == full, "a restored Custom Topic Word brings its Known state back")
    }

    @Test func aStarterWordCannotBeArchived() throws {
        let shelf = try library()
        let didArchive = try shelf.archiveCustom("鸡粪")
        #expect(didArchive == false)
        #expect(try shelf.meter().total == 125)
    }

    @Test func anArchivedCustomWordCannotBeMarkedKnown() throws {
        let shelf = try library()
        try shelf.addCustom(word: "蚯蚓堆肥", pinyin: "", english: "vermicompost", group: .ferment)
        try shelf.archiveCustom("蚯蚓堆肥")
        let didMark = try shelf.markKnown("蚯蚓堆肥")
        #expect(didMark == false)
    }
}
