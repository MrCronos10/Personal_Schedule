import SwiftData
import SwiftUI

/// The 设置 tab: the student's Categories.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(CategoryLibrary.activeDescriptor) private var categories: [Category]

    @State private var newName = ""
    @State private var errorText: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("设置")
                    .font(Theme.serif(30, .black))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 12)

                SectionCaption(title: "分类")

                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.categoryInk(at: index))
                            .frame(width: 10, height: 10)
                        Text(category.name)
                            .font(Theme.serif(17))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Theme.rule).frame(height: 1)
                    }
                }

                if categories.isEmpty {
                    Text("还没有分类")
                        .font(Theme.serif(16))
                        .foregroundStyle(Theme.muted)
                        .padding(.vertical, 12)
                }

                HStack(spacing: 8) {
                    TextField("新分类名称", text: $newName)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.rule))
                        .submitLabel(.done)
                        .onSubmit(addCategory)
                    Button("添加", action: addCategory)
                        .buttonStyle(RedButtonStyle())
                }
                .padding(.top, 14)

                if let errorText {
                    Text(errorText)
                        .font(.footnote)
                        .foregroundStyle(Theme.red)
                        .padding(.top, 6)
                }
            }
            .padding(.horizontal, 16)
        }
        .background(Theme.paper)
    }

    private func addCategory() {
        do {
            try CategoryLibrary(context: context).add(named: newName)
            newName = ""
            errorText = nil
        } catch CategoryError.emptyName {
            errorText = "名称不能为空"
        } catch {
            errorText = "保存失败：\(error.localizedDescription)"
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}
