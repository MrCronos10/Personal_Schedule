import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

@MainActor
struct CategoryLibraryTests {
    @Test func addedCategoryAppearsInTheList() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let library = CategoryLibrary(context: container.mainContext)

        try library.add(named: "中文")

        #expect(try library.active().map(\.name) == ["中文"])
    }

    @Test(arguments: ["", "   "])
    func blankNameIsRefusedAndNothingIsSaved(name: String) throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let library = CategoryLibrary(context: container.mainContext)

        #expect(throws: CategoryError.emptyName) {
            try library.add(named: name)
        }
        #expect(try library.active().isEmpty)
    }

    @Test func categoriesAreStillThereAfterReopening() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let storeURL = folder.appendingPathComponent("schedule.store")

        do {
            let container = try ScheduleStore.makeContainer(url: storeURL)
            let library = CategoryLibrary(context: container.mainContext)
            try library.add(named: "中文")
            try library.add(named: "学习")
        }

        let reopened = try ScheduleStore.makeContainer(url: storeURL)
        let library = CategoryLibrary(context: reopened.mainContext)
        #expect(try library.active().map(\.name) == ["中文", "学习"])
    }

    @Test func renamedCategoryShowsItsNewName() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let library = CategoryLibrary(context: container.mainContext)
        let category = try library.add(named: "中文")

        try library.rename(category, to: "汉语")

        #expect(try library.active().map(\.name) == ["汉语"])
    }

    @Test(arguments: ["", "   "])
    func blankRenameIsRefusedAndTheOldNameStays(name: String) throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let library = CategoryLibrary(context: container.mainContext)
        let category = try library.add(named: "中文")

        #expect(throws: CategoryError.emptyName) {
            try library.rename(category, to: name)
        }
        #expect(try library.active().map(\.name) == ["中文"])
    }

    @Test func archivedCategoryMovesFromActiveToArchived() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let library = CategoryLibrary(context: container.mainContext)
        try library.add(named: "中文")
        let life = try library.add(named: "生活")

        try library.archive(life)

        #expect(try library.active().map(\.name) == ["中文"])
        #expect(try library.archived().map(\.name) == ["生活"])
    }

    @Test func restoredCategoryReturnsToActiveInItsOriginalPlace() throws {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let library = CategoryLibrary(context: container.mainContext)
        let chinese = try library.add(named: "中文")
        try library.add(named: "生活")
        try library.archive(chinese)

        try library.restore(chinese)

        #expect(try library.active().map(\.name) == ["中文", "生活"])
        #expect(try library.archived().isEmpty)
    }
}
