import SwiftData
import SwiftUI

/// The form for planning a new One-time Action.
struct ActionFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(CategoryLibrary.activeDescriptor) private var categories: [Category]

    @State private var title = ""
    @State private var category: Category?
    @State private var date: Date
    @State private var hasTime = false
    @State private var time = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var defaultMinutes: Int?
    @State private var errorMessage: LocalizedStringKey?

    init(day: Day) {
        _date = State(initialValue: day.date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("标题", text: $title)
                    if categories.isEmpty {
                        Text("请先在设置里添加分类")
                            .foregroundStyle(Theme.muted)
                    } else {
                        Picker("选择分类", selection: $category) {
                            Text("未选择").tag(Category?.none)
                            ForEach(categories) { option in
                                Text(verbatim: option.name).tag(Optional(option))
                            }
                        }
                    }
                }

                Section {
                    DatePicker("日期", selection: $date, displayedComponents: .date)
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
            .navigationTitle(Text("新计划"))
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

    private func save() {
        guard let category else {
            errorMessage = "请选择分类"
            return
        }
        let calendar = Calendar.current
        let clock = calendar.dateComponents([.hour, .minute], from: time)
        do {
            try ActionLibrary(context: context).addOneTime(
                title: title,
                category: category,
                day: Day(date, calendar: calendar),
                time: hasTime ? TimeOfDay(hour: clock.hour ?? 0, minute: clock.minute ?? 0) : nil,
                defaultMinutes: defaultMinutes
            )
            dismiss()
        } catch ActionError.emptyTitle {
            errorMessage = "请输入标题"
        } catch ActionError.archivedCategory {
            errorMessage = "这个分类已归档"
        } catch ActionError.negativeMinutes {
            errorMessage = "分钟不能是负数"
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
        }
    }
}

#Preview {
    ActionFormView(day: Day.today())
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}
