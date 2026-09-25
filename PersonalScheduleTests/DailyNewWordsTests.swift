import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// 今日新词: how a **Level** gets finished, because real Articles will never hold all 600 Words.
///
/// It must stay small and unpunishing. The moment it nags it is the abandoned flashcard deck
/// [ADR 0004](../docs/adr/0004-known-is-earned-by-reading-not-by-review.md) exists to avoid.
@MainActor
struct DailyNewWordsTests {
    private func library() throws -> VocabularyLibrary {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        return VocabularyLibrary(context: ModelContext(container))
    }

    private let day = Day(number: 20260921)

    @Test func tenUnmetWordsOfTheServedLevelComeBack() throws {
        let shelf = try library()
        let words = try shelf.dailyNewWords(on: day)
        #expect(words.count == 10)
        #expect(words.allSatisfy { $0.level == .four })
        #expect(Set(words.map(\.word)).count == 10)
    }

    /// The same ten all day, so leaving the tab and coming back doesn't reshuffle them.
    @Test func theSameDayGivesTheSameTen() throws {
        let shelf = try library()
        let first = try shelf.dailyNewWords(on: day).map(\.word)
        let again = try shelf.dailyNewWords(on: day).map(\.word)
        #expect(first == again)
    }

    /// Answering one Word must not move the other nine. The window is seeded off the whole Word
    /// List, not the pool, because the pool shrinks the moment anything is answered — or the moment
    /// a word is tapped while reading.
    @Test func answeringOneWordDoesNotReshuffleTheRest() throws {
        let shelf = try library()
        let before = try shelf.dailyNewWords(on: day).map(\.word)
        try shelf.markKnown(before[0], on: day)

        let after = try shelf.dailyNewWords(on: day).map(\.word)
        #expect(Array(after.prefix(9)) == Array(before.dropFirst()))
    }

    @Test func aDifferentDayGivesDifferentWords() throws {
        let shelf = try library()
        let today = try shelf.dailyNewWords(on: day).map(\.word)
        let tomorrow = try shelf.dailyNewWords(on: day.adding(days: 1)).map(\.word)
        #expect(today != tomorrow)
    }

    /// A Word answered 不认识 leaves today's ten at once. It is **Set Aside**, not banished.
    @Test func aWordSetAsideLeavesTodaysTen() throws {
        let shelf = try library()
        let first = try #require(try shelf.dailyNewWords(on: day).first)
        try shelf.setAside(first.word, on: day)

        #expect(try !shelf.dailyNewWords(on: day).map(\.word).contains(first.word))
    }

    /// The hole ADR 0006 closes. Every Word the student admitted to not knowing used to leave the
    /// daily pool for good, and reading alone will never finish a Level (ADR 0005) — so the Words
    /// most in need of being offered again were the exact ones that never were.
    ///
    /// Set aside the whole of HSK 4 and the pool is empty for twenty-nine days, then full again.
    @Test func aWordSetAsideComesBackAfterThirtyDays() throws {
        let shelf = try library()
        for entry in HSKWordList.words(at: .four) {
            try shelf.setAside(entry.word, on: day)
        }

        #expect(try shelf.dailyNewWords(on: day.adding(days: 29)).isEmpty)
        #expect(try shelf.dailyNewWords(on: day.adding(days: 30)).count == 10)
    }

    /// A Word part-way to **Known** waits like any other, and then comes back.
    ///
    /// Reading is what earns a Word, but a Word that gained one **Clean Sighting** and never turned
    /// up in an Article again would be stalled for good — the same hole ADR 0006 closes for 不认识,
    /// reached through reading instead. Its sightings are kept: coming back here is another chance
    /// to be offered, never a reason to lose evidence already earned.
    @Test func aPartWayWordAlsoComesBackAfterThirtyDays() throws {
        let shelf = try library()
        let first = try #require(try shelf.dailyNewWords(on: day).first)
        let progress = try #require(try shelf.progressCreatingIfNeeded(for: first.word))
        progress.cleanSightings = 1
        progress.setAsideDayNumber = day.number
        try shelf.context.save()

        #expect(!VocabularyLibrary.isOfferable(progress, on: day.adding(days: 29)))
        #expect(VocabularyLibrary.isOfferable(progress, on: day.adding(days: 30)))
        #expect(progress.cleanSightings == 1)
    }

    /// A **Known** Word is never offered, whatever else is true of it.
    @Test func aKnownWordIsNeverOfferable() throws {
        let shelf = try library()
        let first = try #require(try shelf.dailyNewWords(on: day).first)
        try shelf.markKnown(first.word, on: day)
        let progress = try #require(try shelf.progress(for: first.word))

        #expect(!VocabularyLibrary.isOfferable(progress, on: day.adding(days: 365)))
    }

    /// Rows written before ADR 0006 carry no set-aside day at all. They are treated as eligible
    /// rather than parked, so the fix reaches the Words already sitting in the student's install.
    @Test func aRowWithNoSetAsideDayIsOfferable() throws {
        let shelf = try library()
        let first = try #require(try shelf.dailyNewWords(on: day).first)
        // Set aside and then clear the day, saved both times, so the row certainly exists with no
        // clock on it. Reaching for `progressCreatingIfNeeded` alone would leave the insert pending
        // and let this pass on "no row at all" — the wrong branch, and the one already covered.
        try shelf.setAside(first.word, on: day)
        let progress = try #require(try shelf.progress(for: first.word))
        progress.setAsideDayNumber = nil
        try shelf.context.save()

        #expect(VocabularyLibrary.isOfferable(progress, on: day))
        #expect(try shelf.dailyNewWords(on: day).map(\.word).contains(first.word))
    }

    @Test func markingAWordKnownRaisesTheLevelCount() throws {
        let shelf = try library()
        let first = try #require(try shelf.dailyNewWords(on: day).first)
        try shelf.markKnown(first.word, on: day)
        #expect(try shelf.level(.four).known == 1)
        #expect(try !shelf.dailyNewWords(on: day).map(\.word).contains(first.word))
    }

    /// The pool empties at HSK 5, because finishing HSK 4 moves the Served Level on rather than
    /// running the pool down — which is the behaviour, not a gap in it.
    @Test func fewerThanTenLeftIsFineAndNoneLeftIsFine() throws {
        let shelf = try library()
        for entry in HSKWordList.words(at: .four) {
            try shelf.markKnown(entry.word, on: day)
        }
        let five = HSKWordList.words(at: .five)
        for entry in five.dropLast(4) {
            try shelf.markKnown(entry.word, on: day)
        }
        #expect(try shelf.dailyNewWords(on: day).count == 4)

        for entry in five.suffix(4) {
            try shelf.markKnown(entry.word, on: day)
        }
        #expect(try shelf.dailyNewWords(on: day).isEmpty)
    }

    /// Once HSK 4 is Passed the pool becomes HSK 5. Passing changes this and nothing else.
    @Test func onceFourIsPassedTheWordsComeFromFive() throws {
        let shelf = try library()
        for entry in HSKWordList.words(at: .four).prefix(480) {
            try shelf.markKnown(entry.word, on: day)
        }
        #expect(try shelf.servedLevel() == .five)
        #expect(try shelf.dailyNewWords(on: day).allSatisfy { $0.level == .five })
    }

    /// A grammar entry is met here or nowhere: no word split out of an Article can ever match it,
    /// so the daily pool has to be willing to offer one.
    @Test func grammarEntriesAreOfferedHere() throws {
        let shelf = try library()
        let grammarEntry = HSKWordList.words(at: .four).first(where: \.isGrammarEntry)
        let grammar = try #require(grammarEntry)
        for entry in HSKWordList.words(at: .four) where entry.word != grammar.word {
            try shelf.setAside(entry.word, on: day)
        }
        #expect(try shelf.dailyNewWords(on: day).map(\.word) == [grammar.word])
    }
}
