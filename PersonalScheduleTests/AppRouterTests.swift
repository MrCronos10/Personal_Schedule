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
}
