import SwiftData
import SwiftUI

/// The Collection Grid: every Word on the HSK Word Lists and the Topic List as one 田字格 cell, empty
/// until met, faded once seen, inked once Known. It is the app's one achievement surface (ADR 0009).
///
/// The state of each cell comes from `CollectionLibrary`; this view only draws it.
struct CollectionGridView: View {
    @Environment(\.modelContext) private var context
    /// Set by another screen that wants this grid opened at a section (the 词 cards, the Today sliver).
    @Environment(AppRouter.self) private var router: AppRouter?

    /// Watched so the grid follows what reading, lookups and 认识 change.
    @Query private var progressRows: [WordProgress]
    @Query private var lookups: [WordLookup]
    @Query private var sightings: [CleanSighting]
    @Query private var topicRows: [TopicWordProgress]
    @Query private var customs: [TopicCustomWord]

    @State private var four: [CollectionCell] = []
    @State private var five: [CollectionCell] = []
    @State private var topic: [CollectionCell] = []
    @State private var expanded: Set<CollectionSection> = []
    @State private var hasOpenedASection = false
    @State private var selected: SelectedCell?
    @State private var glowing: Set<String> = []
    /// The last router request this grid acted on, so coming back to the tab later does not replay it.
    @State private var handledFocusToken = 0

    private static let lastSeenKnownKey = "collectionGrid.knownWords"
    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 10)

    private struct SelectedCell: Identifiable {
        let word: String
        let isTopic: Bool
        var id: String { (isTopic ? "topic:" : "hsk:") + word }
    }

    /// One value covering every way a cell can change, so a single change runs `refresh()` once.
    private var signature: Int {
        var value = progressRows.count
        value = value &* 31 &+ progressRows.count { $0.isKnown }
        value = value &* 31 &+ lookups.count
        value = value &* 31 &+ sightings.count
        value = value &* 31 &+ topicRows.count { $0.isKnown }
        value = value &* 31 &+ customs.count { !$0.isArchived }
        return value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            section(.four, title: Text(verbatim: "HSK 4"), cells: four, isTopic: false)
            section(.five, title: Text(verbatim: "HSK 5"), cells: five, isTopic: false)
            section(.topic, title: Text("农业词"), cells: topic, isTopic: true)
        }
        .onAppear {
            refresh()
            settleGlow()
        }
        .onChange(of: signature) { refresh() }
        .onChange(of: router?.focusToken) { openFocusedSection() }
        .sheet(item: $selected) { cell in
            Group {
                if cell.isTopic {
                    TopicCellSheet(word: cell.word)
                } else {
                    WordLookupSheet(word: cell.word)
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func section(_ id: CollectionSection, title: Text, cells: [CollectionCell], isTopic: Bool) -> some View {
        let known = cells.filter { $0.state == .known }.count
        let isOpen = expanded.contains(id)
        return VStack(alignment: .leading, spacing: 10) {
            Color.clear.frame(height: 0).id(id)
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    if isOpen { expanded.remove(id) } else { expanded.insert(id) }
                }
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    title
                        .font(Theme.title)
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(verbatim: "\(known) / \(cells.count)")
                        .font(Theme.mono(14, .semibold))
                        .foregroundStyle(Theme.muted)
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.muted)
                }
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isHeader)

            if isOpen {
                LazyVGrid(columns: Self.columns, spacing: 3) {
                    ForEach(cells) { cell in
                        Button {
                            selected = SelectedCell(word: cell.word, isTopic: isTopic)
                        } label: {
                            CollectionCellView(cell: cell, isGlowing: glowing.contains(cell.word))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func openFocusedSection() {
        guard let router, router.focusToken != handledFocusToken, let section = router.focusedSection else { return }
        handledFocusToken = router.focusToken
        withAnimation(.easeOut(duration: 0.2)) { _ = expanded.insert(section) }
    }

    private func refresh() {
        if let all = try? CollectionLibrary(context: context).allCells() {
            four = all.four
            five = all.five
            topic = all.topic
        }
        if !hasOpenedASection {
            hasOpenedASection = true
            let fourKnown = four.filter { $0.state == .known }.count
            expanded = [VocabularyLibrary.servedLevel(four: LevelProgress(level: .four, known: fourKnown)) == .four ? .four : .five]
            openFocusedSection()
        }
    }

    /// Cells that turned Known since the grid was last on screen glow for a second. The very first
    /// visit has nothing to compare with, so it glows nothing rather than everything.
    private func settleGlow() {
        let knownNow = Set((four + five + topic).filter { $0.state == .known }.map(\.word))
        let defaults = UserDefaults.standard
        if let last = defaults.array(forKey: Self.lastSeenKnownKey) as? [String] {
            let fresh = CollectionLibrary.freshlyKnown(current: knownNow, lastSeen: Set(last))
            if !fresh.isEmpty {
                glowing = fresh
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    withAnimation(.easeOut(duration: 0.4)) { glowing = [] }
                }
            }
        }
        // Written only when it changed: it is up to ~1,900 strings, and this runs on every visit.
        if (defaults.array(forKey: Self.lastSeenKnownKey) as? [String]).map(Set.init) != knownNow {
            defaults.set(Array(knownNow), forKey: Self.lastSeenKnownKey)
        }
    }
}

/// A few cells of a section, for the cards on the 词 tab and the strip on Today.
struct CollectionSliver: View {
    let cells: [CollectionCell]
    var columns = 10

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: columns), spacing: 3) {
            ForEach(cells) { cell in
                CollectionCellView(cell: cell, isGlowing: false)
            }
        }
        .accessibilityHidden(true)
    }
}

/// One 田字格 cell. Not met is empty; seen is the word in faded ink; Known is the word inked in,
/// over 300ms, so a Word becoming Known while the grid is open is something the student can watch.
struct CollectionCellView: View {
    let cell: CollectionCell
    let isGlowing: Bool

    private var fontSize: CGFloat {
        switch cell.word.count {
        case 1: 18
        case 2: 15
        default: 12
        }
    }

    var body: some View {
        ZStack {
            Rectangle().fill(Theme.card.opacity(cell.state == .known ? 0.9 : 0.4))
            Cross()
                .stroke(Theme.rule.opacity(0.7), style: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
            Text(verbatim: cell.word)
                .font(Theme.serif(fontSize, cell.state == .known ? .black : .bold))
                .minimumScaleFactor(0.35)
                .lineLimit(1)
                .padding(2)
                .foregroundStyle(cell.state == .known ? Theme.ink : Theme.muted)
                .opacity(cell.state == .notMet ? 0 : (cell.state == .seen ? 0.5 : 1))
                .scaleEffect(cell.state == .known ? 1 : 0.9)
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(Rectangle().stroke(Theme.red.opacity(0.55), lineWidth: 0.75))
        .overlay {
            if isGlowing {
                Rectangle().stroke(Theme.red, lineWidth: 2)
                    .shadow(color: Theme.red.opacity(0.7), radius: 4)
            }
        }
        .animation(.easeOut(duration: 0.3), value: cell.state)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: cell.state == .notMet ? "" : cell.word))
    }
}

private struct Cross: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

/// What a Topic Word cell opens: the term and the hand-marked 认识, the only way a Topic Word
/// becomes Known (ADR 0007).
private struct TopicCellSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.locale) private var locale

    let word: String
    @Query private var progress: [TopicWordProgress]

    init(word: String) {
        self.word = word
        _progress = Query(filter: #Predicate<TopicWordProgress> { $0.word == word })
    }

    private var isKnown: Bool { progress.first?.isKnown ?? false }
    private var isChinese: Bool { locale.language.languageCode == .chinese }
    private var term: TopicTerm? {
        (try? TopicLibrary(context: context).allWords())?.first { $0.word == word }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(verbatim: word)
                    .font(Theme.serif(40, .black))
                    .foregroundStyle(Theme.ink)
                SpeakerButton(text: word)
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.red)
            }
            if let term {
                Text(verbatim: term.pinyin)
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.red)
                Text(verbatim: term.english)
                    .font(Theme.body)
                    .foregroundStyle(Theme.ink)
                Text(verbatim: isChinese ? term.group.chinese : term.group.english)
                    .font(Theme.label)
                    .tracking(1.4)
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 4)
            }
            Spacer(minLength: 16)
            if isKnown {
                Button("其实不认识") {
                    try? TopicLibrary(context: context).takeKnownBack(word)
                    dismiss()
                }
                .buttonStyle(MiniButtonStyle())
            } else {
                Button("认识") {
                    try? TopicLibrary(context: context).markKnown(word)
                    dismiss()
                }
                .buttonStyle(MiniButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .background(Theme.paper)
        .onDisappear { SpeechPlayer.shared.stop(ifPlaying: word) }
    }
}
