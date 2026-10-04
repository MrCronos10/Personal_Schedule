import Testing
@testable import PersonalSchedule

@MainActor
struct AppRouterTests {
    @Test func theAppOpensOnToday() {
        let router = AppRouter()
        #expect(router.tab == .today)
        #expect(router.focusedSection == nil)
    }

    @Test func showingASectionOpensProgressAtIt() {
        let router = AppRouter()
        router.showProgress(at: .five)

        #expect(router.tab == .progress)
        #expect(router.focusedSection == .five)
    }

    @Test func aLaterSectionReplacesTheEarlierOne() {
        let router = AppRouter()
        router.showProgress(at: .four)
        router.showProgress(at: .topic)

        #expect(router.focusedSection == .topic)
    }

    /// Asking for the same section twice is two requests: the second must still open it, even if the
    /// student collapsed it in between, so each request carries its own number.
    @Test func eachRequestGetsANewTokenEvenForTheSameSection() {
        let router = AppRouter()
        let start = router.focusToken
        router.showProgress(at: .four)
        let first = router.focusToken
        router.showProgress(at: .four)

        #expect(first == start + 1)
        #expect(router.focusToken == first + 1)
    }
}
