import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// The Level stamp: fires once when a Level reaches **Passed**, never again while it stays there, and
/// re-arms if the Level is taken back below **Passed**. See ticket 08 and CONTEXT.md.
@MainActor
struct LevelCongratulationTests {
    private func library() throws -> VocabularyLibrary {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        return VocabularyLibrary(context: ModelContext(container))
    }

    @Test func aLevelNeverPassedHasNotBeenCongratulated() throws {
        #expect(try library().hasCongratulated(.four) == false)
    }

    // MARK: - Backfilling a Level already Passed before this feature existed

    /// A Level Passed before this feature shipped must not stamp itself the first time the student
    /// opens the tab after updating: that would celebrate an achievement from months ago as though it
    /// just happened. Backfilling it as already-congratulated, silently, is what keeps it quiet.
    @Test func aLevelAlreadyPassedIsBackfilledAsCongratulated() throws {
        let shelf = try library()
        for entry in HSKWordList.words(at: .four).prefix(480) {
            try shelf.markKnown(entry.word)
        }
        #expect(try shelf.level(.four).isPassed)
        #expect(try shelf.hasCongratulated(.four) == false)

        #expect(try shelf.backfillLevelCongratulations() == 1)
        #expect(try shelf.hasCongratulated(.four))
    }

    @Test func aLevelNotYetPassedIsNotBackfilled() throws {
        let shelf = try library()
        #expect(try shelf.backfillLevelCongratulations() == 0)
        #expect(try shelf.hasCongratulated(.four) == false)
    }

    /// Run at every start, so running it again must do nothing — the same rule `DayMigration` and
    /// `backfillMeasuredWords` both follow.
    @Test func runningTheBackfillAgainChangesNothing() throws {
        let shelf = try library()
        for entry in HSKWordList.words(at: .four).prefix(480) {
            try shelf.markKnown(entry.word)
        }
        #expect(try shelf.backfillLevelCongratulations() == 1)
        #expect(try shelf.backfillLevelCongratulations() == 0)
    }

    /// A Level already congratulated live — the ordinary way, not backfilled — must not be
    /// double-counted or disturbed by a later backfill run.
    @Test func aLevelAlreadyCongratulatedIsNotTouchedByTheBackfill() throws {
        let shelf = try library()
        for entry in HSKWordList.words(at: .four).prefix(480) {
            try shelf.markKnown(entry.word)
        }
        try shelf.markCongratulated(.four)
        #expect(try shelf.backfillLevelCongratulations() == 0)
        #expect(try shelf.hasCongratulated(.four))
    }

    @Test func markingCongratulatedIsRemembered() throws {
        let shelf = try library()
        try shelf.markCongratulated(.four)
        #expect(try shelf.hasCongratulated(.four))
    }

    /// Marking twice must not create two rows, or a single re-arm would need two clears to undo it.
    @Test func markingCongratulatedTwiceIsIdempotent() throws {
        let shelf = try library()
        try shelf.markCongratulated(.four)
        try shelf.markCongratulated(.four)
        #expect(try shelf.hasCongratulated(.four))
    }

    /// The two Levels are independent: congratulating one says nothing about the other.
    @Test func theTwoLevelsAreCongratulatedIndependently() throws {
        let shelf = try library()
        try shelf.markCongratulated(.four)
        #expect(try shelf.hasCongratulated(.four))
        #expect(try shelf.hasCongratulated(.five) == false)
    }

    @Test func clearingAnUncongratulatedLevelDoesNothing() throws {
        let shelf = try library()
        try shelf.clearCongratulation(.four)
        #expect(try shelf.hasCongratulated(.four) == false)
    }

    @Test func clearingReArmsTheStamp() throws {
        let shelf = try library()
        try shelf.markCongratulated(.four)
        try shelf.clearCongratulation(.four)
        #expect(try shelf.hasCongratulated(.four) == false)
    }

    /// Taking a Word's Known status back with 其实不认识 re-arms its Level's stamp once the Level
    /// actually drops below Passed — not on every 其实不认识 regardless of whether it mattered.
    @Test func takingALevelBackBelowPassedReArmsIt() throws {
        let shelf = try library()
        for entry in HSKWordList.words(at: .four).prefix(480) {
            try shelf.markKnown(entry.word)
        }
        #expect(try shelf.level(.four).isPassed)
        try shelf.markCongratulated(.four)

        let firstWord = HSKWordList.words(at: .four)[0].word
        try shelf.markNotKnown(firstWord)

        #expect(try !shelf.level(.four).isPassed)
        #expect(try shelf.hasCongratulated(.four) == false)
    }

    /// The whole round trip: dropped below Passed, re-armed, earned back, and worth marking again.
    @Test func droppingBelowPassedThenPassingAgainReCongratulates() throws {
        let shelf = try library()
        let words = HSKWordList.words(at: .four)
        for entry in words.prefix(480) {
            try shelf.markKnown(entry.word)
        }
        try shelf.markCongratulated(.four)

        try shelf.markNotKnown(words[0].word)
        #expect(try shelf.hasCongratulated(.four) == false)

        try shelf.markKnown(words[0].word)
        #expect(try shelf.level(.four).isPassed)
        #expect(try shelf.hasCongratulated(.four) == false)
        try shelf.markCongratulated(.four)
        #expect(try shelf.hasCongratulated(.four))
    }

    /// 其实不认识 on a Word that doesn't move the Level below Passed must not re-arm it: only actually
    /// dropping below four fifths is worth marking again.
    @Test func aWordTakenBackThatDoesNotDropTheLevelLeavesTheStampArmed() throws {
        let shelf = try library()
        // 481 Known, one more than Passed needs, so taking one back still leaves it Passed.
        for entry in HSKWordList.words(at: .four).prefix(481) {
            try shelf.markKnown(entry.word)
        }
        #expect(try shelf.level(.four).isPassed)
        try shelf.markCongratulated(.four)

        let firstWord = HSKWordList.words(at: .four)[0].word
        try shelf.markNotKnown(firstWord)

        #expect(try shelf.level(.four).isPassed)
        #expect(try shelf.hasCongratulated(.four))
    }
}
