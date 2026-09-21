import SwiftData
import SwiftUI

/// 导入文章: paste the text, name where it came from if you like, save.
///
/// The title is not asked for. It is taken from the first line, so importing is one paste and one
/// button — the point is to catch Chinese the student just met, before the moment passes.
struct ArticleImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var text = ""
    @State private var source = ""
    @State private var errorMessage: LocalizedStringKey?

    @FocusState private var isTextFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionCaption(title: "文章")

                    TextEditor(text: $text)
                        .font(Theme.serif(17))
                        .foregroundStyle(Theme.ink)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 260)
                        .padding(8)
                        .background(Theme.paper)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.rule)
                        )
                        .padding(.top, 10)
                        .focused($isTextFocused)
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("把文章贴在这里")
                                    .font(Theme.serif(17))
                                    .foregroundStyle(Theme.muted.opacity(0.6))
                                    .padding(.horizontal, 14)
                                    .padding(.top, 26)
                                    .allowsHitTesting(false)
                            }
                        }

                    Text("标题会用第一行。")
                        .font(Theme.meta)
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 6)

                    SectionCaption(title: "来源")

                    TextField("微信公众号、菜单、路牌…", text: $source)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Theme.paper)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.rule)
                        )
                        .padding(.top, 10)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Theme.error)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Theme.paper)
            .navigationTitle(Text("导入文章"))
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
        .onAppear { isTextFocused = true }
    }

    private func save() {
        do {
            try ArticleLibrary(context: context).add(text: text, source: source)
            dismiss()
        } catch ArticleError.emptyText {
            errorMessage = "先贴一段文章"
        } catch {
            errorMessage = "没能保存"
        }
    }
}

#Preview {
    ArticleImportView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}
