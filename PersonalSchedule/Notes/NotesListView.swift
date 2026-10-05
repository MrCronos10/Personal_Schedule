import SwiftData
import SwiftUI

/// The 笔记 tab: every **Note** newest first, with a search box.
///
/// This is where the student reads back the words they met in real life, which is the whole reason
/// a **Completion** carries a Note. See CONTEXT.md.
struct NotesListView: View {
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss

    @Query(CompletionLibrary.allDescriptor) private var completions: [Completion]
    @Query(CategoryLibrary.allDescriptor) private var allCategories: [Category]

    @State private var searchText = ""
    /// The Note opened to full size. Its own sheet follows it back to its day (`NoteDetailView`).
    @State private var openedNote: Completion?

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
                            .card()
                    } else {
                        VStack(spacing: 16) {
                            ForEach(Array(shown.enumerated()), id: \.element.persistentModelID) { index, completion in
                                NoteCard(
                                    completion: completion,
                                    ink: Theme.categoryInk(for: completion.category, among: allCategories)
                                )
                                .rotationEffect(.degrees(NoteCardStyle.tilt(at: index)))
                                .onTapGesture { openedNote = completion }
                                .accessibilityAddTraits(.isButton)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                    }
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.paper)
        .sheet(item: $openedNote) { note in
            NoteDetailView(
                completion: note,
                ink: Theme.categoryInk(for: note.category, among: allCategories)
            )
        }
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
        // Notes are written when a plan is completed, not from here, so the one action is to go back
        // to Today and do one.
        EmptyState(
            character: "记",
            message: "完成一个计划时可以写一条笔记，新遇到的词就记在这里。",
            actionTitle: "去今天",
            action: { dismiss() }
        )
    }

    /// The search text is left alone, so it can be corrected instead of retyped.
    private var noMatches: some View {
        Text("没有找到")
            .font(Theme.serif(16))
            .foregroundStyle(Theme.muted)
    }
}

#Preview {
    NotesListView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}
