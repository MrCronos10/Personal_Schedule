import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

@MainActor
struct DayPlanTests {
    private let monday = Day(year: 2026, month: 9, day: 14)

    @Test func oneTimeActionAppearsOnItsDayWithItsDetails() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        let actions = ActionLibrary(context: container.mainContext)

        try actions.addOneTime(
            title: "学20个新词",
            category: chinese,
            day: monday,
            time: TimeOfDay(hour: 7, minute: 0),
            defaultMinutes: 20
        )

        let plan = try DayPlan(context: container.mainContext).actions(on: monday)
        #expect(plan.count == 1)
        #expect(plan.first?.title == "学20个新词")
        #expect(plan.first?.category?.name == "中文")
        #expect(plan.first?.time == TimeOfDay(hour: 7, minute: 0))
        #expect(plan.first?.defaultMinutes == 20)
    }

    @Test(arguments: ["", "   "])
    func blankTitleIsRefusedAndNothingIsSaved(title: String) throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let chinese = try CategoryLibrary(context: container.mainContext).add(named: "中文")
        let actions = ActionLibrary(context: container.mainContext)

        #expect(throws: ActionError.emptyTitle) {
            try actions.addOneTime(title: title, category: chinese, day: monday)
        }
        #expect(try DayPlan(context: container.mainContext).actions(on: monday).isEmpty)
    }

    @Test func archivedCategoryCantBeChosen() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let categories = CategoryLibrary(context: container.mainContext)
        let club = try categories.add(named: "篮球社")
        try categories.archive(club)
        let actions = ActionLibrary(context: container.mainContext)

        #expect(throws: ActionError.archivedCategory) {
            try actions.addOneTime(title: "打篮球", category: club, day: monday)
        }
        #expect(try DayPlan(context: container.mainContext).actions(on: monday).isEmpty)
    }

    @Test func negativeDefaultMinutesAreRefusedAndNothingIsSaved() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let life = try CategoryLibrary(context: container.mainContext).add(named: "健康")
        let actions = ActionLibrary(context: container.mainContext)

        #expect(throws: ActionError.negativeMinutes) {
            try actions.addOneTime(title: "健身", category: life, day: monday, defaultMinutes: -30)
        }
        #expect(try DayPlan(context: container.mainContext).actions(on: monday).isEmpty)
    }

    @Test func actionAppearsOnlyOnItsOwnDay() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let life = try CategoryLibrary(context: container.mainContext).add(named: "生活")
        try ActionLibrary(context: container.mainContext)
            .addOneTime(title: "买SIM卡", category: life, day: Day(year: 2026, month: 9, day: 15))
        let plan = DayPlan(context: container.mainContext)

        #expect(try plan.actions(on: monday).isEmpty)
        #expect(try plan.actions(on: Day(year: 2026, month: 9, day: 15)).map(\.title) == ["买SIM卡"])
        #expect(try plan.actions(on: Day(year: 2026, month: 9, day: 16)).isEmpty)
    }

    @Test func timedActionsComeFirstEarliestFirstThenUntimedInTheOrderAdded() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let categories = CategoryLibrary(context: container.mainContext)
        let chinese = try categories.add(named: "中文")
        let life = try categories.add(named: "生活")
        let actions = ActionLibrary(context: container.mainContext)

        try actions.addOneTime(title: "洗衣服", category: life, day: monday)
        try actions.addOneTime(title: "健身", category: life, day: monday, time: TimeOfDay(hour: 18, minute: 30))
        try actions.addOneTime(title: "学20个新词", category: chinese, day: monday, time: TimeOfDay(hour: 7, minute: 0))
        try actions.addOneTime(title: "买SIM卡", category: life, day: monday)

        let titles = try DayPlan(context: container.mainContext).actions(on: monday).map(\.title)
        #expect(titles == ["学20个新词", "健身", "洗衣服", "买SIM卡"])
    }
}
