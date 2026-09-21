import SwiftData
import SwiftUI

/// The 阅读 tab: the student's **Articles**, newest first, with a **+** to import one.
///
/// The Level meter (ticket 18) and 今日新词 (ticket 19) belong above the list. The space is left
/// empty for them rather than filled with a placeholder.
struct ReadingView: View {
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var context

    @Query(ArticleLibrary.readingDescriptor) private var reading: [Article]
    @Query(ArticleLibrary.archivedDescriptor) private var archived: [Article]

    @State private var isImporting = false
    @State private var isShowingArchived = false

    private var isChinese: Bool { locale.language.languageCode == .chinese }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("\(reading.count) 篇文章")
                        .font(.system(size: 13))
                        .tracking(1)
                        .foregroundStyle(Theme.muted)
                    Spacer()
                    Button { isImporting = true } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(RedButtonStyle())
                    .accessibilityLabel(Text("导入文章"))
                }
                .padding(.top, 12)

                title
                    .padding(.top, 14)

                SectionCaption(title: "我的文章")

                if reading.isEmpty {
                    emptyReadingList
                        .card()
                        .padding(.top, 10)
                } else {
                    VStack(spacing: 0) {
                        ForEach(reading) { article in
                            ArticleRow(article: article) {
                                try? ArticleLibrary(context: context).archive(article)
                            }
                        }
                    }
                    .card()
                    .padding(.top, 10)
                }

                archivedSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.paper)
        .sheet(isPresented: $isImporting) {
            ArticleImportView()
        }
    }

    /// 阅读 in 田字格 boxes, the same practice-book heading 今天 and 进度 use.
    @ViewBuilder
    private var title: some View {
        if isChinese {
            TianZiGeTitle(text: "阅读")
        } else {
            Text("阅读")
                .font(Theme.serif(34, .black))
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
        }
    }

    /// The quiet voice the Daily Checklist already uses: a sentence and a way forward.
    private var emptyReadingList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("还没有文章")
                .font(Theme.serif(16))
                .foregroundStyle(Theme.muted)
            Text("把你遇到的中文贴进来：微信文章、菜单、路牌都行。")
                .font(Theme.meta)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var archivedSection: some View {
        if !archived.isEmpty || isShowingArchived {
            Button {
                isShowingArchived.toggle()
            } label: {
                HStack(spacing: 4) {
                    Text("已归档")
                    Image(systemName: isShowingArchived ? "chevron.up" : "chevron.down")
                }
                .font(Theme.label)
                .tracking(1.4)
                .foregroundStyle(Theme.muted)
            }
            .buttonStyle(.plain)
            .padding(.top, 22)

            if isShowingArchived {
                Group {
                    if archived.isEmpty {
                        Text("没有已归档的文章")
                            .font(Theme.serif(16))
                            .foregroundStyle(Theme.muted)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(archived) { article in
                                ArticleRow(article: article, isArchived: true) {
                                    try? ArticleLibrary(context: context).restore(article)
                                }
                            }
                        }
                    }
                }
                .card()
                .padding(.top, 10)
            }
        }
    }
}

/// One Article in the reading list. Tapping it does nothing yet: ticket 15 opens it.
struct ArticleRow: View {
    @Environment(\.locale) private var locale

    let article: Article
    var isArchived: Bool = false
    let onArchiveAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                // The student's own writing, and the title taken from it: never translated.
                Text(verbatim: article.title)
                    .font(Theme.serif(18))
                    .foregroundStyle(isArchived ? Theme.muted : Theme.ink)
                HStack(spacing: 0) {
                    if let source = article.source {
                        Text(verbatim: source)
                        Text(verbatim: " · ")
                    }
                    Text(verbatim: importedDayText)
                }
                .font(Theme.meta)
                .foregroundStyle(Theme.muted)
                Text(verbatim: preview)
                    .font(Theme.meta)
                    .foregroundStyle(Theme.muted.opacity(0.75))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(isArchived ? "恢复" : "归档", action: onArchiveAction)
                .buttonStyle(MiniButtonStyle())
        }
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.rule).frame(height: 1)
        }
    }

    private var importedDayText: String {
        article.importedDay.date().formatted(.dateTime.month().day().locale(locale))
    }

    /// The opening of the article, with the line the title came from taken off, so the list doesn't
    /// read the same words twice.
    private var preview: String {
        let lines = article.text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return lines.dropFirst().joined(separator: " ")
    }
}

#Preview {
    ReadingView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}
