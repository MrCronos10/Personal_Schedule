import SwiftData
import SwiftUI

/// The 笔记 tab: every **Note** newest first, with a search box.
///
/// This is where the student reads back the words they met in real life, which is the whole reason
/// a **Completion** carries a Note. See CONTEXT.md.
struct NotesListView: View {
    @Environment(\.locale) private var locale

    @Query(CompletionLibrary.allDescriptor) private var completions: [Completion]
    @Query(CategoryLibrary.allDescriptor) private var allCategories: [Category]

    @State private var searchText = ""

    private var isChinese: Bool { locale.language.languageCode == .chinese }

    /// Both rules come from `CompletionLibrary`, which is what the tests call: no filter or sort is
    /// written into this view.
    private var notes: [Completion] { CompletionLibrary.notes(completions) }
    private var shown: [Completion] { CompletionLibrary.search(searchText, in: notes) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     ? "\(notes.count) 条笔记"
                     : "\(shown.count) / \(notes.count) 条笔记")
                    .font(.system(size: 13))
                    .tracking(1)
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 12)

                title
                    .padding(.top, 14)

                searchField
                    .padding(.top, 16)

                SectionCaption(title: "笔记")

                Group {
                    if notes.isEmpty {
                        emptyList
                    } else if shown.isEmpty {
                        noMatches
                    } else {
                        VStack(spacing: 0) {
                            ForEach(shown) { completion in
                                NoteRow(
                                    completion: completion,
                                    ink: Theme.categoryInk(
                                        for: completion.category, among: allCategories
                                    )
                                )
                            }
                        }
                    }
                }
                .card()
                .padding(.top, 10)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.paper)
    }

    /// 笔记 in 田字格 boxes, the same practice-book heading the other tabs use.
    @ViewBuilder
    private var title: some View {
        if isChinese {
            TianZiGeTitle(text: "笔记")
        } else {
            Text("笔记")
                .font(Theme.serif(34, .black))
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
        }
    }

    /// The list narrows as it is typed. There is nothing to submit.
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.muted)
            TextField("找一个词、计划或分类", text: $searchText)
                .font(.system(size: 15))
                .foregroundStyle(Theme.ink)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.muted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("清空"))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
    }

    private var emptyList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("还没有笔记")
                .font(Theme.serif(16))
                .foregroundStyle(Theme.muted)
            Text("完成一个计划时可以写一条笔记，新遇到的词就记在这里。")
                .font(Theme.meta)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The search text is left alone, so it can be corrected instead of retyped.
    private var noMatches: some View {
        Text("没有找到")
            .font(Theme.serif(16))
            .foregroundStyle(Theme.muted)
    }
}

/// One Note: the day it was written, what it was written under, and the Note itself.
///
/// The title is what the Completion copied when it was ticked, so a renamed or moved Action never
/// rewrites a finished day (ADR 0002). The Category is shown by its **current** name, because
/// renaming one corrects what it is called rather than making it a different Category — the
/// Progress Tracker's rows follow a rename the same way.
struct NoteRow: View {
    @Environment(\.locale) private var locale

    let completion: Completion
    let ink: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text(verbatim: dayText)
                    .foregroundStyle(Theme.muted)
                    .layoutPriority(1)
                Text(verbatim: " · ")
                    .foregroundStyle(Theme.muted)
                // The student's own writing, and the Category it counted toward: never translated.
                // The title is free text the student typed, so it is the piece that gives way.
                // Without this the date and the minutes shrink alongside it and the whole line
                // turns into ellipses.
                Text(verbatim: completion.titleWhenTicked)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(-1)
                if let name = completion.category?.name {
                    Text(verbatim: "【\(name)】")
                        .foregroundStyle(ink)
                }
                if let minutes = completion.minutes {
                    Text(verbatim: " · ")
                        .foregroundStyle(Theme.muted)
                    Text("\(minutes)分钟")
                        .foregroundStyle(Theme.muted)
                        .layoutPriority(1)
                }
            }
            .font(Theme.meta)

            Text(verbatim: completion.note ?? "")
                .font(Theme.serif(16))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.rule).frame(height: 1)
        }
    }

    private var dayText: String {
        completion.day.date().formatted(.dateTime.month().day().locale(locale))
    }
}

#Preview {
    NotesListView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}
