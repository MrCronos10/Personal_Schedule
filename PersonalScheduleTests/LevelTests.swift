import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// The year's headline number. Known Words against the whole **Word List**, never against the Words
/// that happened to turn up in the student's Articles. See
/// [ADR 0005](../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md).
@MainActor
struct LevelTests {
    private func library() throws -> VocabularyLibrary {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        return VocabularyLibrary(context: ModelContext(container))
    }

    private let day = Day(number: 20260921)

    @Test func afreshInstallReportsZeroOutOfTheWholeList() throws {
        let shelf = try library()
        let four = try shelf.level(.four)
        #expect(four.known == 0)
        #expect(four.total == 600)
        #expect(!four.isPassed)
        #expect(try shelf.level(.five).total == 1300)
    }

    @Test func aKnownWordCountsTowardItsOwnLevelOnly() throws {
        let shelf = try library()
        try shelf.markKnown("厕所", on: day)   // HSK 4
        #expect(try shelf.level(.four).known == 1)
        #expect(try shelf.level(.five).known == 0)
    }

    /// Integer arithmetic, so the boundary is exact rather than a rounded percentage.
    @Test func aLevelPassesAtFourFifths() throws {
        #expect(!LevelProgress(level: .four, known: 479).isPassed)
        #expect(LevelProgress(level: .four, known: 480).isPassed)
        #expect(!LevelProgress(level: .five, known: 1039).isPassed)
        #expect(LevelProgress(level: .five, known: 1040).isPassed)
    }

    @Test func theServedLevelIsFourUntilFourIsPassed() throws {
        #expect(VocabularyLibrary.servedLevel(four: LevelProgress(level: .four, known: 479)) == .four)
        #expect(VocabularyLibrary.servedLevel(four: LevelProgress(level: .four, known: 480)) == .five)
    }

    /// There is no level 6 to fall off the end into.
    @Test func theServedLevelStaysFiveOnceFiveIsPassedToo() throws {
        #expect(VocabularyLibrary.servedLevel(four: LevelProgress(level: .four, known: 600)) == .five)
    }

    /// Words are never held back from counting, only from being served.
    @Test func anHSKFiveWordCountsWhileFourIsStillUnpassed() throws {
        let shelf = try library()
        try shelf.markKnown("被子", on: day)   // HSK 5
        #expect(try shelf.level(.five).known == 1)
        #expect(try shelf.servedLevel() == .four)
    }

    @Test func takingKnownBackLowersTheCount() throws {
        let shelf = try library()
        try shelf.markKnown("厕所", on: day)
        #expect(try shelf.level(.four).known == 1)
        try shelf.markNotKnown("厕所")
        #expect(try shelf.level(.four).known == 0)
    }

    @Test func theShareIsReportedForTheBar() throws {
        #expect(LevelProgress(level: .four, known: 0).share == 0)
        #expect(LevelProgress(level: .four, known: 300).share == 0.5)
        #expect(LevelProgress(level: .four, known: 600).share == 1)
    }
}
