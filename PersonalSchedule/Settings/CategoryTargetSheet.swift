import SwiftData
import SwiftUI

/// Sets a Category's Weekly Target, in minutes. Empty means no Weekly Target, and the Progress Tracker
/// shows that Category as a Completion Count instead. See CONTEXT.md.
struct CategoryTargetSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let category: Category

    @State private var minutesText = ""
    @State private var errorMessage: LocalizedStringKey?

    var body: some View {
        NavigationStack {
            Form {
                Section("每周目标（分钟）") {
                    TextField("分钟", text: $minutesText)
                        .keyboardType(.numberPad)
                        // A refusal is about what was typed, so it goes as soon as that changes.
                        .onChange(of: minutesText) { errorMessage = nil }
                    if let hint {
                        Text("约 \(hint) 小时")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.muted)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(Theme.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.paper)
            .tint(Theme.red)
            .navigationTitle("每周目标")
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
        .onAppear {
            minutesText = category.weeklyTargetMinutes.map(String.init) ?? ""
        }
    }

    /// The same minutes read back in hours, while they are being typed. A label only: nothing is parsed
    /// from it, so 420 can never be saved as 7.
    private var hint: String? {
        guard let minutes = Int(minutesText.trimmingCharacters(in: .whitespaces)), minutes > 0 else {
            return nil
        }
        return WeeklyTarget.hoursText(forMinutes: minutes)
    }

    private func save() {
        let trimmed = minutesText.trimmingCharacters(in: .whitespaces)
        var minutes: Int?
        if !trimmed.isEmpty {
            // Named as minutes on purpose: the 小时 line invites hour-thinking, so 7.5 is a likely thing
            // to type, and a bare 请输入数字 wouldn't say what was wrong with it.
            guard let typed = Int(trimmed) else {
                errorMessage = "请输入整分钟"
                return
            }
            minutes = typed
        }
        do {
            try CategoryLibrary(context: context).setWeeklyTarget(minutes, on: category)
            dismiss()
        } catch CategoryError.targetNotPositive {
            errorMessage = "目标要大于零"
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
        }
    }
}
