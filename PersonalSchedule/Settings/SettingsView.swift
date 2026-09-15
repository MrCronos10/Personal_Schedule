import SwiftData
import SwiftUI

/// The 设置 tab: the student's Categories and the app language.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(LanguageSetting.self) private var language
    @Query(CategoryLibrary.activeDescriptor) private var categories: [Category]

    @State private var newName = ""
    @State private var errorMessage: LocalizedStringKey?

    var body: some View {
        @Bindable var language = language

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
                        Text(verbatim: category.name)
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

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Theme.red)
                        .padding(.top, 6)
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
    }

    private func addCategory() {
        do {
            try CategoryLibrary(context: context).add(named: newName)
            newName = ""
            errorMessage = nil
        } catch CategoryError.emptyName {
            errorMessage = "名称不能为空"
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
        .environment(LanguageSetting(defaults: .standard))
}
