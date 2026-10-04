import SwiftUI

/// The layout rules for a Note drawn as an index card.
enum NoteCardStyle {
    /// A Note's first non-blank line is the card's title; whatever follows is its body.
    static func split(_ note: String) -> (title: String, body: String) {
        let lines = note.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard let first = lines.firstIndex(where: { !$0.isEmpty }) else { return ("", "") }
        let body = lines[(first + 1)...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return (lines[first], body)
    }

    /// The stack leans a little each way, so it reads as paper rather than a list.
    static func tilt(at index: Int) -> Double {
        index.isMultiple(of: 2) ? -2 : 2
    }
}

/// One **Note** as a cream index card with a thin red top edge: the day it was written, what it was
/// written under, and the Note itself.
///
/// The title is what the Completion copied when it was ticked, so a renamed or moved Action never
/// rewrites a finished day (ADR 0002). The Category is shown by its **current** name, because
/// renaming one corrects what it is called rather than making it a different Category.
struct NoteCard: View {
    @Environment(\.locale) private var locale

    let completion: Completion
    let ink: Color
    /// The card in the stack shortens a long Note; the expanded one shows all of it.
    var isExpanded = false

    var body: some View {
        let note = NoteCardStyle.split(completion.note ?? "")
        VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(Theme.red).frame(height: 3)
            VStack(alignment: .leading, spacing: 6) {
                meta
                // The student's own writing: never translated.
                if !note.title.isEmpty {
                    Text(verbatim: note.title)
                        .font(Theme.serif(isExpanded ? 22 : 17))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !note.body.isEmpty {
                    Text(verbatim: note.body)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(isExpanded ? nil : 3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        // The one shadow the app allows: the edge of a card lying on paper.
        .shadow(color: .black.opacity(0.1), radius: 1.5, y: 1)
        .contentShape(Rectangle())
    }

    private var meta: some View {
        HStack(spacing: 0) {
            Text(verbatim: dayText)
                .foregroundStyle(Theme.muted)
                .layoutPriority(1)
            Text(verbatim: " · ")
                .foregroundStyle(Theme.muted)
            // The title is free text the student typed, so it is the piece that gives way; without
            // this the date and the minutes shrink alongside it and the line turns into ellipses.
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
    }

    private var dayText: String {
        completion.day.date().formatted(.dateTime.month().day().locale(locale))
    }
}

/// A Note opened to full size. Swipe down to put it back on the stack; 看这一天 follows it to its own
/// Daily Checklist, the same sheet the Progress ledger opens for a Missed day.
struct NoteDetailView: View {
    let completion: Completion
    let ink: Color
    @State private var isShowingDay = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                NoteCard(completion: completion, ink: ink, isExpanded: true)
                    .padding(.top, 24)
                Button("看这一天") { isShowingDay = true }
                    .buttonStyle(MiniButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.paper)
        .sheet(isPresented: $isShowingDay) {
            TodayView(initialDay: completion.day, showsShortcuts: false)
        }
    }
}
