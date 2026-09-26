import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// 读完: what one reading proves. The core rule of the whole feature, so every case here is a rule
/// from [ADR 0004](../docs/adr/0004-known-is-earned-by-reading-not-by-review.md) and none of them
/// should be softened to make the code simpler.
@MainActor
struct BankingTests {
    private struct Shelf {
        let vocabulary: VocabularyLibrary
        let articles: ArticleLibrary
    }

    private func shelf() throws -> Shelf {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        return Shelf(
            vocabulary: VocabularyLibrary(context: context),
            articles: ArticleLibrary(context: context)
        )
    }

    private let day = Day(number: 20260921)

    /// An Article whose measured vocabulary is exactly `words`, so a test that counts what moved is
    /// counting something known. The title is a bare number: a Chinese title would smuggle its own
    /// HSK Words into the text — 篇 and 干净 are both on the lists, which is how the first draft of
    /// these counting tests got their numbers wrong.
    private func text(_ id: Int, _ words: [String]) -> String {
        "\(id)\n" + words.map { "\($0)。" }.joined()
    }

    /// Guards the helper above: if the segmenter ever finds more or fewer Words than the fixture
    /// names, the counting tests below are measuring the wrong thing and should fail here first.
    @Test func theFixtureContainsExactlyTheWordsItNames() throws {
        #expect(VocabularyLibrary.hskWords(in: text(1, ["厕所"])).map(\.word) == ["厕所"])
        #expect(
            VocabularyLibrary.hskWords(in: text(2, ["厕所", "被子"])).map(\.word)
                == ["厕所", "被子"]
        )
    }

    // MARK: - A Clean Sighting remembers its Article

    /// A Word can say *where* it was earned, not merely how often. Its sightings are its count, so
    /// there is no separate number that could drift from the Articles explaining it.
    @Test func aCleanSightingRemembersItsArticle() throws {
        let shelf = try shelf()
        let first = try shelf.articles.add(text: text(1, ["厕所"]))
        let second = try shelf.articles.add(text: text(2, ["厕所"]))
        try shelf.vocabulary.bank(first, on: day)
        try shelf.vocabulary.bank(second, on: day)

        let sightings = try shelf.vocabulary.cleanSightings(of: "厕所")
        #expect(sightings.count == 2)
        #expect(Set(sightings.compactMap { $0.article?.title }) == ["1", "2"])
    }

    /// A **Known** Word can say which three readings earned it. This is the whole point of keeping
    /// records rather than a number.
    @Test func aKnownWordNamesTheThreeArticlesThatEarnedIt() throws {
        let shelf = try shelf()
        for index in 1...3 {
            let article = try shelf.articles.add(text: text(index, ["厕所"]))
            try shelf.vocabulary.bank(article, on: day)
        }

        let sightings = try shelf.vocabulary.cleanSightings(of: "厕所")
        #expect(try shelf.vocabulary.progress(for: "厕所")?.isKnown == true)
        // Compared as a set: all three were banked on one day, and the sort key is the day, so the
        // order between them is not something the store promises.
        #expect(Set(sightings.compactMap { $0.article?.title }) == ["1", "2", "3"])
    }

    /// **Known** is three *different* Articles, not three records. Nothing in the store stops two
    /// rows describing one reading — no field is unique and iCloud sync is due later — and two
    /// copies of one sighting must not be worth two Articles.
    @Test func twoRecordsOfOneArticleAreNotTwoArticles() throws {
        let shelf = try shelf()
        let first = try shelf.articles.add(text: text(1, ["厕所"]))
        try shelf.vocabulary.bank(first, on: day)
        // A second copy of the same reading, as a sync between two devices could produce.
        shelf.vocabulary.context.insert(CleanSighting(word: "厕所", article: first, day: day))
        try shelf.vocabulary.context.save()

        let second = try shelf.articles.add(text: text(2, ["厕所"]))
        try shelf.vocabulary.bank(second, on: day)

        #expect(try shelf.vocabulary.progress(for: "厕所")?.isKnown == false)
    }

    /// A Word the app does not measure is not evidence of anything and records nothing (ADR 0005).
    @Test func anUnmeasuredWordEarnsNoCleanSighting() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "1\n很好。")
        try shelf.vocabulary.bank(article, on: day)
        #expect(try shelf.vocabulary.cleanSightings(of: "很").isEmpty)
    }

    // MARK: - What an Article proved

    /// An Article keeps what its reading was worth, so a finished Article is not indistinguishable
    /// from one never opened.
    @Test func anArticleRemembersWhatItProved() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: text(1, ["厕所", "被子"]))
        try shelf.vocabulary.bank(article, on: day)

        #expect(article.bankedDay?.number == day.number)
        #expect(article.bankedResult == VocabularyLibrary.BankResult(advanced: 2))
    }

    /// An Article banked before this feature existed has nothing to say either.
    ///
    /// Those Articles are already `isBanked`, and the counters added here arrive at their default of
    /// zero, so keying off `isBanked` would have every finished Article in the student's install
    /// announce 这篇没有新的词 on the first launch — telling them a reading that really did make Words
    /// Known proved nothing. The banked day is what tells the two apart.
    @Test func anArticleBankedBeforeThisFeatureHasNoBankedResult() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: text(1, ["厕所"]))
        try shelf.vocabulary.bank(article, on: day)
        // Exactly what lightweight migration leaves behind for a previously banked Article.
        article.bankedDayNumber = nil
        article.bankedNewlyKnown = 0
        article.bankedAdvanced = 0
        article.bankedReturnedToZero = 0

        #expect(article.isBanked)
        #expect(article.bankedResult == nil)
    }

    /// An Article never finished has nothing to say, and must not say zeros.
    @Test func anArticleNeverFinishedHasNoBankedResult() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: text(1, ["厕所"]))
        #expect(article.bankedDay == nil)
        #expect(article.bankedResult == nil)
    }

    /// An Article whose Words were all looked up proved something: that they were not known. It is
    /// not an Article with nothing in it (ADR 0004).
    @Test func anArticleWhoseWordsWereAllLookedUpStillProvedSomething() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: text(1, ["厕所"]))
        try shelf.vocabulary.lookUp("厕所", in: article, on: day)
        try shelf.vocabulary.bank(article, on: day)

        #expect(article.bankedResult == VocabularyLibrary.BankResult(returnedToZero: 1))
    }

    /// Kept from the moment it was earned, not worked out again later. A Word looked up next week
    /// must not rewrite what this Article proved today.
    @Test func aLaterLookupDoesNotRewriteWhatAnEarlierArticleProved() throws {
        let shelf = try shelf()
        let first = try shelf.articles.add(text: text(1, ["厕所"]))
        try shelf.vocabulary.bank(first, on: day)
        #expect(first.bankedAdvanced == 1)

        let second = try shelf.articles.add(text: text(2, ["厕所"]))
        try shelf.vocabulary.lookUp("厕所", in: second, on: day.adding(days: 7))
        try shelf.vocabulary.bank(second, on: day.adding(days: 7))

        #expect(first.bankedAdvanced == 1)
        #expect(first.bankedDay?.number == day.number)
    }

    /// Rereading proves nothing new, and must not overwrite what the first reading proved.
    @Test func aRereadLeavesTheBankedResultAlone() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: text(1, ["厕所"]))
        try shelf.vocabulary.bank(article, on: day)
        try shelf.vocabulary.bank(article, on: day.adding(days: 3))

        #expect(article.bankedAdvanced == 1)
        #expect(article.bankedDay?.number == day.number)
    }

    @Test func archivingAndRestoringLeavesTheBankedResultAlone() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: text(1, ["厕所"]))
        try shelf.vocabulary.bank(article, on: day)
        try shelf.articles.archive(article)
        #expect(article.bankedAdvanced == 1)
        try shelf.articles.restore(article)
        #expect(article.bankedAdvanced == 1)
        #expect(article.bankedDay?.number == day.number)
    }

    // MARK: - One Article, one sighting

    /// A Word repeated nine times in one text is still one Article's worth of evidence.
    @Test func aWordRepeatedInOneArticleGainsOneSighting() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "厕所\n厕所很干净。厕所。")
        try shelf.vocabulary.bank(article, on: day)
        #expect(try shelf.vocabulary.cleanSightings(of: "厕所").count == 1)
    }

    @Test func threeDifferentArticlesMakeAWordKnown() throws {
        let shelf = try shelf()
        for index in 1...3 {
            let article = try shelf.articles.add(text: "第\(index)篇\n厕所很干净。")
            try shelf.vocabulary.bank(article, on: day)
        }
        let progress = try #require(try shelf.vocabulary.progress(for: "厕所"))
        #expect(try shelf.vocabulary.cleanSightings(of: "厕所").count == 3)
        #expect(progress.isKnown)
        #expect(progress.knownDay?.number == day.number)
    }

    @Test func twoArticlesAreNotEnough() throws {
        let shelf = try shelf()
        for index in 1...2 {
            let article = try shelf.articles.add(text: "第\(index)篇\n厕所很干净。")
            try shelf.vocabulary.bank(article, on: day)
        }
        #expect(try shelf.vocabulary.progress(for: "厕所")?.isKnown == false)
    }

    // MARK: - A Lookup is destructive

    /// The rule that makes an untapped Word mean something: two sightings and a tap is zero, not
    /// three.
    @Test func aLookupInThisArticleReturnsTheWordToZero() throws {
        let shelf = try shelf()
        for index in 1...2 {
            let article = try shelf.articles.add(text: "第\(index)篇\n厕所很干净。")
            try shelf.vocabulary.bank(article, on: day)
        }

        let third = try shelf.articles.add(text: "第三篇\n厕所很干净。")
        try shelf.vocabulary.lookUp("厕所", in: third, on: day)
        try shelf.vocabulary.bank(third, on: day)

        let progress = try #require(try shelf.vocabulary.progress(for: "厕所"))
        #expect(try shelf.vocabulary.cleanSightings(of: "厕所").isEmpty)
        #expect(!progress.isKnown)
    }

    /// The test that catches a lookup query missing its article filter, which would silently freeze
    /// every Word the student ever tapped.
    @Test func aLookupInAnotherArticleDoesNotBlockThisOne() throws {
        let shelf = try shelf()
        let first = try shelf.articles.add(text: "第一篇\n厕所很干净。")
        let second = try shelf.articles.add(text: "第二篇\n厕所很干净。")

        try shelf.vocabulary.lookUp("厕所", in: first, on: day)
        try shelf.vocabulary.bank(first, on: day)
        try shelf.vocabulary.bank(second, on: day)

        #expect(try shelf.vocabulary.cleanSightings(of: "厕所").count == 1)
    }

    @Test func aWordLookedUpInOneArticleStillEarnsFromTheNext() throws {
        let shelf = try shelf()
        let first = try shelf.articles.add(text: "第一篇\n厕所很干净。")
        try shelf.vocabulary.lookUp("厕所", in: first, on: day)
        try shelf.vocabulary.bank(first, on: day)
        #expect(try shelf.vocabulary.cleanSightings(of: "厕所").count == 0)

        let second = try shelf.articles.add(text: "第二篇\n厕所很干净。")
        try shelf.vocabulary.bank(second, on: day)
        #expect(try shelf.vocabulary.cleanSightings(of: "厕所").count == 1)
    }

    /// A Known Word is not taken back by one tap: only 其实不认识 does that.
    @Test func aKnownWordLookedUpAgainStaysKnown() throws {
        let shelf = try shelf()
        try shelf.vocabulary.markKnown("厕所", on: Day(number: 20260901))

        let article = try shelf.articles.add(text: "第一篇\n厕所很干净。")
        try shelf.vocabulary.lookUp("厕所", in: article, on: day)
        try shelf.vocabulary.bank(article, on: day)

        let progress = try #require(try shelf.vocabulary.progress(for: "厕所"))
        #expect(progress.isKnown)
        #expect(progress.knownDay?.number == 20260901)
    }

    // MARK: - Rereading proves nothing

    @Test func bankingTheSameArticleTwiceChangesNothing() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "第一篇\n厕所很干净。")
        try shelf.vocabulary.bank(article, on: day)
        try shelf.vocabulary.bank(article, on: day)
        #expect(try shelf.vocabulary.cleanSightings(of: "厕所").count == 1)
        #expect(article.isBanked)
    }

    @Test func aRereadReportsThatNothingMoved() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: text(1, ["厕所"]))
        let first = try shelf.vocabulary.bank(article, on: day)
        #expect(!first.wasReread)
        #expect(first.advanced == 1)

        let again = try shelf.vocabulary.bank(article, on: day)
        #expect(again.wasReread)
        #expect(again.advanced == 0)
        #expect(again.newlyKnown == 0)
    }

    /// A Lookup made while rereading still counts. Needing help with a word already banked is real
    /// evidence, whenever it happens.
    @Test func aLookupDuringARereadStillReturnsTheWordToZero() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "第一篇\n厕所很干净。")
        try shelf.vocabulary.bank(article, on: day)
        #expect(try shelf.vocabulary.cleanSightings(of: "厕所").count == 1)

        try shelf.vocabulary.lookUp("厕所", in: article, on: day)
        #expect(try shelf.vocabulary.cleanSightings(of: "厕所").count == 0)
    }

    // MARK: - What is left alone

    @Test func wordsOutsideTheListGetNoRow() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "第一篇\n他很好，我们学习。")
        try shelf.vocabulary.bank(article, on: day)
        #expect(try shelf.vocabulary.progress(for: "很") == nil)
        #expect(try shelf.vocabulary.progress(for: "学习") == nil)
    }

    @Test func aWordMarkedKnownByHandIsNotDisturbed() throws {
        let shelf = try shelf()
        try shelf.vocabulary.markKnown("厕所", on: Day(number: 20260901))

        let article = try shelf.articles.add(text: "第一篇\n厕所很干净。")
        try shelf.vocabulary.bank(article, on: day)

        let progress = try #require(try shelf.vocabulary.progress(for: "厕所"))
        #expect(progress.isKnown)
        #expect(progress.knownDay?.number == 20260901)
    }

    @Test func anArchivedArticleKeepsWhatItBanked() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "第一篇\n厕所很干净。")
        try shelf.vocabulary.bank(article, on: day)
        try shelf.articles.archive(article)
        #expect(try shelf.vocabulary.cleanSightings(of: "厕所").count == 1)
    }

    // MARK: - What the screen says

    /// A Word the student already knows has not moved toward anything, and saying it did would be
    /// the app inventing progress.
    @Test func anAlreadyKnownWordIsNotCountedAsMoving() throws {
        let shelf = try shelf()
        try shelf.vocabulary.markKnown("厕所", on: Day(number: 20260901))

        let article = try shelf.articles.add(text: text(1, ["厕所"]))
        let result = try shelf.vocabulary.bank(article, on: day)

        #expect(result.newlyKnown == 0)
        #expect(result.advanced == 0)
    }

    /// An Article whose Words were all looked up is not an Article with nothing in it. The student
    /// has just lost ground, and the line must not read as though nothing happened.
    @Test func wordsSentBackToZeroAreCounted() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: text(1, ["厕所", "被子"]))
        try shelf.vocabulary.lookUp("厕所", in: article, on: day)
        try shelf.vocabulary.lookUp("被子", in: article, on: day)

        let result = try shelf.vocabulary.bank(article, on: day)
        #expect(result.newlyKnown == 0)
        #expect(result.advanced == 0)
        #expect(result.returnedToZero == 2)
    }

    @Test func anArticleWithNoMeasuredWordsMovesNothingAtAll() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "1\n他很好。")
        let result = try shelf.vocabulary.bank(article, on: day)
        #expect(result.newlyKnown == 0)
        #expect(result.advanced == 0)
        #expect(result.returnedToZero == 0)
    }

    @Test func theResultCountsWhatMoved() throws {
        let shelf = try shelf()
        // 厕所 and 被子 reach two sightings; 危险 starts fresh in the third Article.
        for index in 1...2 {
            let article = try shelf.articles.add(text: text(index, ["厕所", "被子"]))
            try shelf.vocabulary.bank(article, on: day)
        }

        let third = try shelf.articles.add(text: text(3, ["厕所", "被子", "危险"]))
        let result = try shelf.vocabulary.bank(third, on: day)

        #expect(result.newlyKnown == 2)
        // 危险 moved, but is not Known yet: it is counted as advanced, not as newly Known.
        #expect(result.advanced == 1)
    }
}
