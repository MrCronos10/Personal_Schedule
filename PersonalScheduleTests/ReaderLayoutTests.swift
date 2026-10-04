import CoreGraphics
import Testing
@testable import PersonalSchedule

/// The two rules the reader's layout leans on, kept out of the view so they can be tested.
struct ReaderLayoutTests {
    // MARK: - Reading progress

    @Test func progressIsZeroAtTheTopAndOneAtTheBottom() {
        #expect(ReadingProgress.fraction(scrolled: 0, content: 2000, viewport: 800) == 0)
        #expect(ReadingProgress.fraction(scrolled: 1200, content: 2000, viewport: 800) == 1)
        #expect(ReadingProgress.fraction(scrolled: 600, content: 2000, viewport: 800) == 0.5)
    }

    @Test func overscrollNeverLeavesTheBar() {
        #expect(ReadingProgress.fraction(scrolled: -50, content: 2000, viewport: 800) == 0)
        #expect(ReadingProgress.fraction(scrolled: 1500, content: 2000, viewport: 800) == 1)
    }

    /// A short Article fits on the screen: there is nothing to scroll, and an empty bar would read
    /// as a page not started.
    @Test func anArticleThatFitsIsFullyRead() {
        #expect(ReadingProgress.fraction(scrolled: 0, content: 500, viewport: 800) == 1)
    }

    // MARK: - Paragraphs

    @Test func paragraphsAreTheNonEmptyLinesInOrder() {
        let text = "标题\n第一段。\n\n第二段。\n"
        let lines = ArticleParagraphs.ranges(in: text).map { String(text[$0]) }
        #expect(lines == ["标题", "第一段。", "第二段。"])
    }

    @Test func aLineOfOnlySpacesIsNotAParagraph() {
        let text = "甲\n   \n乙"
        #expect(ArticleParagraphs.ranges(in: text).map { String(text[$0]) } == ["甲", "乙"])
    }

    @Test func everySegmentedWordLandsInExactlyOneParagraph() {
        let text = "我去厕所。\n你好吗？\n"
        let paragraphs = ArticleParagraphs.ranges(in: text)
        #expect(paragraphs.count == 2)
        for word in VocabularyLibrary.segment(text) {
            #expect(paragraphs.filter { $0.contains(word.range.lowerBound) && word.range.upperBound <= $0.upperBound }.count == 1)
        }
    }
}
