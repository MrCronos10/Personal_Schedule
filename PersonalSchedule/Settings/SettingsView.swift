import SwiftData
import SwiftUI

/// The 设置 tab: the student's Categories and the app language.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(LanguageSetting.self) private var language
    @Query(CategoryLibrary.activeDescriptor) private var categories: [Category]
    @Query(CategoryLibrary.archivedDescriptor) private var archivedCategories: [Category]
    @Query(sort: \Category.createdAt) private var allCategories: [Category]

    @State private var newName = ""
    @State private var errorMessage: LocalizedStringKey?
    @State private var renaming: Category?
    @State private var isRenaming = false
    @State private var renameText = ""

    var body: some View {
        @Bindable var language = language

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("设置")
                    .font(Theme.serif(30, .black))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 12)

                SectionCaption(title: "分类")

                ForEach(categories) { category in
                    categoryRow(category) {
                        Button("归档") {
                            perform { try $0.archive(category) }
                        }
                        .buttonStyle(MiniButtonStyle())
                    }
                }

                if categories.isEmpty {
                    emptyText("还没有分类")
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

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Theme.red)
                        .padding(.top, 6)
                }

                SectionCaption(title: "已归档")

                ForEach(archivedCategories) { category in
                    categoryRow(category, isArchived: true) {
                        Button("恢复") {
                            perform { try $0.restore(category) }
                        }
                        .buttonStyle(MiniButtonStyle())
                    }
                }

                if archivedCategories.isEmpty {
                    emptyText("没有已归档的分类")
                }

                SectionCaption(title: "语言")

                Picker("语言", selection: $language.current) {
                    ForEach(AppLanguage.allCases) { option in
                        Text(verbatim: option.nativeName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top, 12)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.paper)
        .alert("重命名分类", isPresented: $isRenaming, presenting: renaming) { category in
            TextField("分类名称", text: $renameText)
            Button("取消", role: .cancel) {}
            Button("保存") {
                perform { try $0.rename(category, to: renameText) }
            }
        }
    }

    /// A Category row: tap the name to rename it; the trailing button archives or restores it.
    private func categoryRow<Action: View>(
        _ category: Category,
        isArchived: Bool = false,
        @ViewBuilder action: () -> Action
    ) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.categoryInk(at: inkIndex(of: category)))
                .frame(width: 10, height: 10)
                .opacity(isArchived ? 0.5 : 1)
            Button {
                renameText = category.name
                renaming = category
                isRenaming = true
            } label: {
                Text(verbatim: category.name)
                    .font(Theme.serif(17))
                    .foregroundStyle(isArchived ? Theme.muted : Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("重命名"))
            action()
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.rule).frame(height: 1)
        }
    }

    private func emptyText(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(Theme.serif(16))
            .foregroundStyle(Theme.muted)
            .padding(.vertical, 12)
    }

    /// Inks follow creation order across all Categories, so archiving one doesn't recolor the others.
    private func inkIndex(of category: Category) -> Int {
        allCategories.firstIndex { $0.id == category.id } ?? 0
    }

    private func addCategory() {
        if perform({ try $0.add(named: newName) }) {
            newName = ""
        }
    }

    @discardableResult
    private func perform(_ change: (CategoryLibrary) throws -> Void) -> Bool {
        do {
            try change(CategoryLibrary(context: context))
            errorMessage = nil
            return true
        } catch CategoryError.emptyName {
            errorMessage = "名称不能为空"
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
        }
        return false
    }
}

#Preview {
    SettingsView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
        .environment(LanguageSetting(defaults: .standard))
}
