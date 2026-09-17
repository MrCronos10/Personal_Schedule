import SwiftData
import SwiftUI

/// The form for planning a new One-time Action or Routine, and for changing one that already exists.
struct ActionFormView: View {
    /// A One-time Action happens once; a Routine repeats on set days. See CONTEXT.md.
    private enum Kind: Hashable {
        case oneTime, routine
    }

    /// How a Routine repeats: every day, Monday to Friday, or the days the student picks.
    private enum RepeatChoice: Hashable {
        case everyDay, weekdays, chosen
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Query(CategoryLibrary.activeDescriptor) private var categories: [Category]

    /// The Action being changed, or nothing when planning a new one.
    private let editing: Action?

    @State private var title = ""
    @State private var category: Category?
    @State private var kind: Kind = .oneTime
    @State private var repeatChoice: RepeatChoice = .everyDay
    @State private var chosenDays: Set<Weekday> = []
    @State private var date: Date
    @State private var hasTime = false
    @State private var time = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var defaultMinutes: Int?
    @State private var errorMessage: LocalizedStringKey?

    init(day: Day) {
        editing = nil
        _date = State(initialValue: day.date())
    }

    /// Opens an Action for changing. An Action keeps its kind, so 类型 isn't offered here.
    init(editing action: Action) {
        editing = action
        _title = State(initialValue: action.title)
        // An Action keeps the Category it has, even one archived since: nothing is deleted in this app, so
        // changing an Action's time shouldn't force it out of a Category the student has retired.
        _category = State(initialValue: action.category)
        _defaultMinutes = State(initialValue: action.defaultMinutes)

        if let repeatDays = action.repeatDays, let startDay = action.startDay {
            _kind = State(initialValue: .routine)
            _date = State(initialValue: startDay.date())
            if repeatDays == .everyDay {
                _repeatChoice = State(initialValue: .everyDay)
            } else if repeatDays == .weekdays {
                _repeatChoice = State(initialValue: .weekdays)
            } else {
                _repeatChoice = State(initialValue: .chosen)
                _chosenDays = State(initialValue: repeatDays.days)
            }
        } else {
            _kind = State(initialValue: .oneTime)
            _date = State(initialValue: action.plannedDay.date())
        }

        if let clock = action.time {
            _hasTime = State(initialValue: true)
            let onTheClock = Calendar.current.date(
                bySettingHour: clock.hour,
                minute: clock.minute,
                second: 0,
                of: Date()
            )
            _time = State(initialValue: onTheClock ?? Date())
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("标题", text: $title)
                    categoryPicker
                }

                Section {
                    if editing == nil {
                        kindPicker
                    }
                    if kind == .routine {
                        repeatPicker
                        if repeatChoice == .chosen {
                            weekdayPicker
                        }
                    }
                    DatePicker(
                        kind == .routine ? "开始日期" : "日期",
                        selection: $date,
                        displayedComponents: .date
                    )
                    Toggle("有时间", isOn: $hasTime)
                    if hasTime {
                        DatePicker("时间", selection: $time, displayedComponents: .hourAndMinute)
                    }
                    TextField("默认分钟（可选）", value: $defaultMinutes, format: .number)
                        .keyboardType(.numberPad)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(Theme.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.paper)
            .tint(Theme.red)
            .navigationTitle(Text(editing == nil ? "新计划" : "改计划"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                }
            }
        }
    }

    @ViewBuilder
    private var categoryPicker: some View {
        let options = pickableCategories
        if options.isEmpty {
            Text("请先在设置里添加分类")
                .foregroundStyle(Theme.muted)
        } else {
            Picker("选择分类", selection: $category) {
                Text("未选择").tag(Category?.none)
                ForEach(options) { option in
                    Text(verbatim: option.name).tag(Optional(option))
                }
            }
        }
    }

    /// The active Categories, plus the one this Action already has when that has since been archived, so it
    /// can be kept. A new Action only ever offers active Categories.
    private var pickableCategories: [Category] {
        guard let current = editing?.category, current.isArchived else { return categories }
        return categories + [current]
    }

    private var kindPicker: some View {
        Picker("类型", selection: $kind) {
            Text("一次").tag(Kind.oneTime)
            Text("重复").tag(Kind.routine)
        }
        .pickerStyle(.segmented)
    }

    private var repeatPicker: some View {
        Picker("重复", selection: $repeatChoice) {
            Text("每天").tag(RepeatChoice.everyDay)
            Text("工作日").tag(RepeatChoice.weekdays)
            Text("选择日子").tag(RepeatChoice.chosen)
        }
    }

    /// One square per weekday, in the week order of the student's language.
    private var weekdayPicker: some View {
        HStack(spacing: 6) {
            ForEach(weekdaysInWeekOrder) { weekday in
                weekdayButton(weekday)
            }
        }
        .padding(.vertical, 4)
    }

    private func weekdayButton(_ weekday: Weekday) -> some View {
        let isChosen: Bool = chosenDays.contains(weekday)
        return Button {
            if isChosen {
                chosenDays.remove(weekday)
            } else {
                chosenDays.insert(weekday)
            }
        } label: {
            Text(verbatim: shortName(for: weekday))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isChosen ? Theme.paper : Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(isChosen ? Theme.red : Color.clear, in: RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.rule))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChosen ? [.isButton, .isSelected] : .isButton)
    }

    /// The week in the order the student's language starts it.
    ///
    /// The first day comes from the locale itself: a `Calendar` keeps the `firstWeekday` it was made with,
    /// so assigning a locale to `Calendar.current` never changes where its week starts.
    private var weekdaysInWeekOrder: [Weekday] {
        let first = firstWeekdayNumber
        return (0..<7).compactMap { Weekday(rawValue: (first - 1 + $0) % 7 + 1) }
    }

    private var firstWeekdayNumber: Int {
        switch locale.firstDayOfWeek {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        default: return 1
        }
    }

    /// 日, 一, 二… in Chinese; Sun, Mon, Tue… in English. The student's own language, never translated by us.
    private func shortName(for weekday: Weekday) -> String {
        var calendar = Calendar.current
        calendar.locale = locale
        let symbols = calendar.shortWeekdaySymbols
        let index = weekday.rawValue - 1
        return index < symbols.count ? symbols[index] : ""
    }

    private var repeatDays: RepeatDays {
        switch repeatChoice {
        case .everyDay:
            return .everyDay
        case .weekdays:
            return .weekdays
        case .chosen:
            return RepeatDays(chosenDays)
        }
    }

    private func save() {
        guard let category else {
            errorMessage = "请选择分类"
            return
        }
        let calendar = Calendar.current
        let clock = calendar.dateComponents([.hour, .minute], from: time)
        let chosenTime = hasTime ? TimeOfDay(hour: clock.hour ?? 0, minute: clock.minute ?? 0) : nil
        let day = Day(date, calendar: calendar)
        do {
            try write(category: category, day: day, time: chosenTime)
            dismiss()
        } catch ActionError.emptyTitle {
            errorMessage = "请输入标题"
        } catch ActionError.archivedCategory {
            errorMessage = "这个分类已归档"
        } catch ActionError.noRepeatDays {
            errorMessage = "请选择重复的日子"
        } catch ActionError.negativeMinutes {
            errorMessage = "分钟不能是负数"
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
        }
    }

    private func write(category: Category, day: Day, time: TimeOfDay?) throws {
        let library = ActionLibrary(context: context)
        switch (editing, kind) {
        case (let action?, .routine):
            try library.updateRoutine(
                action,
                title: title,
                category: category,
                repeatDays: repeatDays,
                startDay: day,
                time: time,
                defaultMinutes: defaultMinutes
            )
        case (let action?, .oneTime):
            try library.updateOneTime(
                action,
                title: title,
                category: category,
                day: day,
                time: time,
                defaultMinutes: defaultMinutes
            )
        case (nil, .routine):
            try library.addRoutine(
                title: title,
                category: category,
                repeatDays: repeatDays,
                startDay: day,
                time: time,
                defaultMinutes: defaultMinutes
            )
        case (nil, .oneTime):
            try library.addOneTime(
                title: title,
                category: category,
                day: day,
                time: time,
                defaultMinutes: defaultMinutes
            )
        }
    }
}

#Preview {
    ActionFormView(day: Day.today())
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}
