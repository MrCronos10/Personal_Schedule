import SwiftData
import SwiftUI

/// The sheet shown when an Action is ticked off: minutes (filled in from Default Minutes) and an optional Note.
struct TickSheetView: View {
    let action: Action
    let day: Day

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var minutesText: String
    @State private var note = ""
    @State private var errorMessage: LocalizedStringKey?

    init(action: Action, day: Day) {
        self.action = action
        self.day = day
        _minutesText = State(initialValue: action.defaultMinutes.map(String.init) ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 10) {
                        TextField("分钟", text: $minutesText)
                            .keyboardType(.numberPad)
                        // Symbols, the same in both languages, so they are never translated.
                        Button { changeMinutes(by: -5) } label: {
                            Text(verbatim: "−5")
                        }
                        .buttonStyle(MiniButtonStyle())
                        Button { changeMinutes(by: 5) } label: {
                            Text(verbatim: "+5")
                        }
                        .buttonStyle(MiniButtonStyle())
                    }
                }

                Section {
                    TextField("新词、难的地方…", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("笔记（可选）")
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
            .navigationTitle(Text(verbatim: action.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成", action: save)
                }
            }
        }
    }

    private func changeMinutes(by amount: Int) {
        let current = Int(minutesText.trimmingCharacters(in: .whitespaces)) ?? 0
        minutesText = String(max(0, current + amount))
    }

    private func save() {
        let trimmed = minutesText.trimmingCharacters(in: .whitespaces)
        let minutes = trimmed.isEmpty ? nil : Int(trimmed)
        if !trimmed.isEmpty, minutes == nil {
            errorMessage = "请输入数字"
            return
        }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try CompletionLibrary(context: context).tick(
                action,
                on: day,
                minutes: minutes,
                note: trimmedNote.isEmpty ? nil : trimmedNote
            )
            dismiss()
        } catch ActionError.negativeMinutes {
            errorMessage = "分钟不能是负数"
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
        }
    }
}
