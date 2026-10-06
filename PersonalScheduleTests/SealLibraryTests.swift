import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// The Seal Book's rules (ADR 0010): which seals exist, when each is earned, and that an earned seal
/// is kept for ever. Every fixture is built from explicit counts and word lists, never from a sentence
/// read by eye (AGENTS.md).
@MainActor
struct SealLibraryTests {
    private let day = Day(number: 20261006)

    private func shelf() throws -> (seals: SealLibrary, context: ModelContext) {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        return (SealLibrary(context: context), context)
    }

    /// `count` Articles already banked, written straight into the store in one save. The reader's own
    /// `bank` is used once below, to show the two agree.
    private func bankedArticles(_ count: Int, in context: ModelContext) throws {
        for index in 0..<count {
            let article = Article(title: "\(index)", text: "\(index)", importedDay: day)
            article.isBanked = true
            context.insert(article)
        }
        try context.save()
    }

    private func knownWords(_ count: Int, at level: HSKLevel, in context: ModelContext) throws {
        for entry in HSKWordList.words(at: level).prefix(count) {
            let progress = WordProgress(word: entry.word, level: level)
            progress.isKnown = true
            context.insert(progress)
        }
        try context.save()
    }

    @Test func nothingIsEarnedAtTheStart() throws {
        let (seals, _) = try shelf()
        #expect(try seals.evaluate(on: day).isEmpty)
        #expect(try seals.earned().isEmpty)
    }

    /// Real reading, through `bank`, earns the first seal: the shortcut fixtures below describe a
    /// state the app can actually reach.
    @Test func finishingTheFirstArticleEarnsTheFirstRead() throws {
        let (seals, context) = try shelf()
        let article = try ArticleLibrary(context: context).add(text: "1\n厕所。")
        try VocabularyLibrary(context: context).bank(article, on: day)

        #expect(try seals.evaluate(on: day) == [.firstRead])
        #expect(try seals.earned()[.firstRead] == day)
    }

    @Test func tenBankedArticlesEarnTenArticlesAndTheFirstRead() throws {
        let (seals, context) = try shelf()
        try bankedArticles(10, in: context)
        #expect(try seals.evaluate(on: day) == [.firstRead, .tenArticles])
    }

    @Test func nineBankedArticlesDoNotEarnTenArticles() throws {
        let (seals, context) = try shelf()
        try bankedArticles(9, in: context)
        #expect(try !seals.evaluate(on: day).contains(.tenArticles))
    }

    /// Only a banked Article counts: one opened and never finished proves nothing (ADR 0004).
    @Test func anArticleNeverFinishedEarnsNothing() throws {
        let (seals, context) = try shelf()
        context.insert(Article(title: "1", text: "1", importedDay: day))
        try context.save()
        #expect(try seals.evaluate(on: day).isEmpty)
    }

    @Test func fiftyAndAHundredBankedArticlesEarnTheirSeals() throws {
        let (seals, context) = try shelf()
        try bankedArticles(100, in: context)
        let earned = try seals.evaluate(on: day)
        #expect(earned.contains(.fiftyArticles))
        #expect(earned.contains(.hundredArticles))
    }

    /// A seal is told about once. Evaluating again returns nothing and writes nothing.
    @Test func anEarnedSealIsReportedOnlyOnce() throws {
        let (seals, context) = try shelf()
        try bankedArticles(1, in: context)
        #expect(try seals.evaluate(on: day) == [.firstRead])
        #expect(try seals.evaluate(on: day.adding(days: 1)).isEmpty)
        // Its earned day stays the day it was first earned.
        #expect(try seals.earned()[.firstRead] == day)
    }

    // MARK: - Kept for ever (ADR 0002's reason, applied to seals)

    /// The Word Note that earned 问字 is later cleared. The seal stays: what was earned was earned.
    @Test func aSealIsKeptWhenItsSourceLaterChanges() throws {
        let (seals, context) = try shelf()
        let vocabulary = VocabularyLibrary(context: context)
        try vocabulary.setNote("记得是茶", for: "厕所")
        #expect(try seals.evaluate(on: day) == [.askAboutAWord])

        try vocabulary.setNote("", for: "厕所")
        #expect(try seals.evaluate(on: day.adding(days: 1)).isEmpty)
        #expect(try seals.earned()[.askAboutAWord] == day)
    }

    @Test func aWordNoteEarnsAskAboutAWord() throws {
        let (seals, context) = try shelf()
        try VocabularyLibrary(context: context).setNote("记得是茶", for: "厕所")
        #expect(try seals.evaluate(on: day) == [.askAboutAWord])
    }

    // MARK: - 百日: days with any Completion, not in a row

    private func completions(onDays days: [Int], in context: ModelContext) throws {
        for number in days {
            context.insert(Completion(titleWhenTicked: "读", day: Day(number: number), minutes: nil, note: nil))
        }
        try context.save()
    }

    /// Calendar-valid day numbers: consecutive days from a start, so a "gap" is a real gap.
    private func days(_ range: Range<Int>) -> [Int] {
        range.map { day.adding(days: $0).number }
    }

    @Test func aHundredDaysWithACompletionEarnTheHundredDays() throws {
        let (seals, context) = try shelf()
        try completions(onDays: days(0..<100), in: context)
        #expect(try seals.evaluate(on: day).contains(.hundredDays))
    }

    @Test func ninetyNineDaysDoNot() throws {
        let (seals, context) = try shelf()
        try completions(onDays: days(0..<99), in: context)
        #expect(try !seals.evaluate(on: day).contains(.hundredDays))
    }

    /// The rule that makes it not a streak: sixty days, a month off, forty more is still one hundred.
    @Test func aGapDoesNotResetTheCount() throws {
        let (seals, context) = try shelf()
        try completions(onDays: days(0..<60) + days(90..<130), in: context)
        #expect(try seals.evaluate(on: day).contains(.hundredDays))
    }

    /// Two Completions on one day are one day.
    @Test func twoCompletionsOnOneDayCountOnce() throws {
        let (seals, context) = try shelf()
        try completions(onDays: days(0..<99) + days(0..<99), in: context)
        #expect(try !seals.evaluate(on: day).contains(.hundredDays))
    }

    // MARK: - 夜读: finished after 22:00

    private func time(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 6, hour: hour, minute: minute))!
    }

    @Test func finishingAfterTenAtNightEarnsNightReading() throws {
        let (seals, _) = try shelf()
        #expect(try seals.evaluate(on: day, finishedReadingAt: time(hour: 22, minute: 30)) == [.nightReading])
    }

    @Test func finishingBeforeTenDoesNot() throws {
        let (seals, _) = try shelf()
        #expect(try seals.evaluate(on: day, finishedReadingAt: time(hour: 21, minute: 59)).isEmpty)
    }

    /// The night runs past midnight: a reading that ends at 00:30 or 04:59 is the clearest night
    /// reading there is. The night ends at five in the morning.
    @Test func finishingAfterMidnightStillCountsAsNight() throws {
        for finish in [time(hour: 0, minute: 30), time(hour: 1), time(hour: 4, minute: 59)] {
            let (seals, _) = try shelf()
            #expect(try seals.evaluate(on: day, finishedReadingAt: finish) == [.nightReading])
        }
    }

    @Test func finishingFromFiveInTheMorningDoesNot() throws {
        let (seals, _) = try shelf()
        #expect(try seals.evaluate(on: day, finishedReadingAt: time(hour: 5)).isEmpty)
    }

    /// With no reading just finished there is no finish time, so the seal can't be earned by opening
    /// the Seal Book late at night.
    @Test func openingTheBookAtNightEarnsNothing() throws {
        let (seals, _) = try shelf()
        #expect(try seals.evaluate(on: day).isEmpty)
    }

    // MARK: - Words Known

    @Test func aHundredWordsKnownEarnsTheHundredWords() throws {
        let (seals, context) = try shelf()
        try knownWords(100, at: .four, in: context)
        #expect(try seals.evaluate(on: day).contains(.hundredWords))
    }

    @Test func ninetyNineWordsDoNot() throws {
        let (seals, context) = try shelf()
        try knownWords(99, at: .four, in: context)
        #expect(try !seals.evaluate(on: day).contains(.hundredWords))
    }

    /// Words Known across HSK 4, HSK 5 and the Topic List all count towards the thousand.
    @Test func aThousandWordsAcrossAllListsEarnTheThousandWords() throws {
        let (seals, context) = try shelf()
        try knownWords(600, at: .four, in: context)
        try knownWords(399, at: .five, in: context)
        context.insert(TopicWordProgress(word: TopicWordList.all[0].word, isKnown: true))
        try context.save()
        #expect(try seals.evaluate(on: day).contains(.thousandWords))
    }

    @Test func nineHundredNinetyNineWordsDoNot() throws {
        let (seals, context) = try shelf()
        try knownWords(600, at: .four, in: context)
        try knownWords(399, at: .five, in: context)
        #expect(try !seals.evaluate(on: day).contains(.thousandWords))
    }

    // MARK: - Levels

    @Test func threeHundredHSKFourWordsEarnHalfway() throws {
        let (seals, context) = try shelf()
        try knownWords(300, at: .four, in: context)
        #expect(try seals.evaluate(on: day).contains(.halfway))
    }

    @Test func twoHundredNinetyNineDoNot() throws {
        let (seals, context) = try shelf()
        try knownWords(299, at: .four, in: context)
        #expect(try !seals.evaluate(on: day).contains(.halfway))
    }

    /// 过关 is a seal for passing HSK 4, never a gate (ADR 0005). Four fifths of 600 is 480.
    @Test func passingHSKFourEarnsTheLevelSeal() throws {
        let (seals, context) = try shelf()
        try knownWords(480, at: .four, in: context)
        #expect(try seals.evaluate(on: day).contains(.passedLevel))
    }

    @Test func fourHundredSeventyNineDoNotPassTheLevel() throws {
        let (seals, context) = try shelf()
        try knownWords(479, at: .four, in: context)
        #expect(try !seals.evaluate(on: day).contains(.passedLevel))
    }

    // MARK: - 农业词

    @Test func twentyFiveTopicWordsEarnTheFarmer() throws {
        let (seals, context) = try shelf()
        for entry in TopicWordList.all.prefix(25) {
            context.insert(TopicWordProgress(word: entry.word, isKnown: true))
        }
        try context.save()
        let earned = try seals.evaluate(on: day)
        #expect(earned.contains(.farmer))
        #expect(!earned.contains(.farmOwner))
    }

    @Test func twentyFourTopicWordsDoNot() throws {
        let (seals, context) = try shelf()
        for entry in TopicWordList.all.prefix(24) {
            context.insert(TopicWordProgress(word: entry.word, isKnown: true))
        }
        try context.save()
        #expect(try !seals.evaluate(on: day).contains(.farmer))
    }

    /// All 125 starter terms. A Custom Topic Word the student added does not stand in for one of them.
    @Test func everyStarterTopicWordEarnsTheFarmOwner() throws {
        let (seals, context) = try shelf()
        #expect(TopicWordList.total == 125)
        for entry in TopicWordList.all {
            context.insert(TopicWordProgress(word: entry.word, isKnown: true))
        }
        try context.save()
        #expect(try seals.evaluate(on: day).contains(.farmOwner))
    }

    @Test func aCustomWordDoesNotStandInForAStarterTerm() throws {
        let (seals, context) = try shelf()
        for entry in TopicWordList.all.dropLast() {
            context.insert(TopicWordProgress(word: entry.word, isKnown: true))
        }
        context.insert(TopicWordProgress(word: "自己加的词", isKnown: true))
        try context.save()
        #expect(try !seals.evaluate(on: day).contains(.farmOwner))
    }

    // MARK: - The book

    /// The three rare seals are the ones the brief names: 过关, 千字文, 农场主.
    @Test func theRareSealsAreTheOnesTheBriefNames() {
        #expect(Set(Seal.allCases.filter(\.isRare)) == [.passedLevel, .thousandWords, .farmOwner])
    }

    @Test func everySealHasAPositiveTarget() {
        for seal in Seal.allCases {
            #expect(seal.target > 0, "\(seal) has no target")
        }
    }

    @Test func progressReportsEverySealInCatalogueOrder() throws {
        let (seals, context) = try shelf()
        try bankedArticles(7, in: context)
        let progress = try seals.progress()
        #expect(progress.map(\.seal) == Seal.allCases)
        #expect(progress.first { $0.seal == .tenArticles }?.current == 7)
    }

    /// 下一枚: the unearned seal furthest along. 7 of 10 Articles beats everything else here.
    @Test func theNextSealIsTheUnearnedOneFurthestAlong() throws {
        let (seals, context) = try shelf()
        try bankedArticles(7, in: context)
        try seals.evaluate(on: day)   // earns 初读
        #expect(try seals.next()?.seal == .tenArticles)
    }

    @Test func thereIsNoNextSealOnceEverythingIsEarned() throws {
        let (seals, context) = try shelf()
        try bankedArticles(100, in: context)
        try knownWords(600, at: .four, in: context)
        try knownWords(500, at: .five, in: context)
        for entry in TopicWordList.all { context.insert(TopicWordProgress(word: entry.word, isKnown: true)) }
        try VocabularyLibrary(context: context).setNote("x", for: "厕所")
        try completions(onDays: days(0..<100), in: context)
        try seals.evaluate(on: day, finishedReadingAt: time(hour: 23))
        #expect(try seals.next() == nil)
    }
}
