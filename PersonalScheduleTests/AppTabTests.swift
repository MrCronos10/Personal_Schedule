import Testing
@testable import PersonalSchedule

/// ADR 0009: four tabs, in this order. Settings and Notes are reached from Today, the Coach from
/// inside an Article, so none of them is a tab.
struct AppTabTests {
    @Test func thereAreExactlyFourTabsInOrder() {
        #expect(AppTab.allCases.map(\.title) == ["今天", "阅读", "词", "进度"])
        #expect(AppTab.allCases.map(\.symbol) == ["calendar", "book", "character.book.closed", "square.grid.3x3"])
    }
}
