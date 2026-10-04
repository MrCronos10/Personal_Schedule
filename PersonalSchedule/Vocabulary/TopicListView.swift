import SwiftData
import SwiftUI

/// 农业词: the **Topic List** screen. The student's second word-list meter, beside the HSK Levels.
/// See CONTEXT.md and ADR 0007.
///
/// What this ships: hand-marking, Custom Topic Words, group filtering. Reading-based evidence is a
/// separate ticket — the Topic List is a parallel structure, not a reshape of the reading pipeline.
struct TopicListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale

    @Query(filter: #Predicate<TopicWordProgress> { $0.isKnown }) private var knownRows: [TopicWordProgress]
    @Query(filter: #Predicate<TopicCustomWord> { !$0.isArchived }, sort: \.addedDayNumber) private var customs: [TopicCustomWord]
    @Query(filter: #Predicate<TopicCustomWord> { $0.isArchived }, sort: \.addedDayNumber, order: .reverse) private var archived: [TopicCustomWord]

    @State private var filter: TopicGroup? = nil
    @State private var isAdding = false
    @State private var isShowingArchived = false

    private var isChinese: Bool { locale.language.languageCode == .chinese }

    private var library: TopicLibrary { TopicLibrary(context: modelContext) }

    private var allTerms: [TopicTerm] {
        let starter = TopicWordList.all.map {
            TopicTerm(word: $0.word, pinyin: $0.pinyin, english: $0.english, group: $0.group, isCustom: false)
        }
        let extras = customs.map {
            TopicTerm(word: $0.word, pinyin: $0.pinyin, english: $0.english, group: $0.group, isCustom: true)
        }
        return starter + extras
    }

    private var knownSet: Set<String> { Set(knownRows.map(\.word)) }

    private var shown: [TopicTerm] {
        guard let filter else { return allTerms }
        return allTerms.filter { $0.group == filter }
    }

    private func meter(in group: TopicGroup?) -> TopicMeter {
        let scope = group == nil ? allTerms : allTerms.filter { $0.group == group }
        let known = scope.filter { knownSet.contains($0.word) }.count
        return TopicMeter(known: known, total: scope.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                title
                    .padding(.top, 14)

                meterRow

                groupChips

                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(shown, id: \.word) { term in
                        TopicRow(term: term, isKnown: knownSet.contains(term.word),
                                 onMark: { mark(term, known: true) },
                                 onTakeBack: { mark(term, known: false) },
                                 onArchive: term.isCustom ? { archiveCustom(term.word) } : nil)
                        Divider().background(Theme.rule.opacity(0.5))
                    }
                }

                Button {
                    isAdding = true
                } label: {
                    Label(isChinese ? "添加自己的词" : "Add my own word", systemImage: "plus")
                        .font(Theme.body)
                        .foregroundStyle(Theme.red)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                archivedSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Theme.paper.ignoresSafeArea())
        .sheet(isPresented: $isAdding) {
            AddCustomTopicWordSheet(initialGroup: filter ?? .ferment) { word, pinyin, english, group in
                (try? library.addCustom(word: word, pinyin: pinyin, english: english, group: group)) ?? .refused(.emptyWord)
            }
        }
    }

    @ViewBuilder
    private var title: some View {
        if isChinese {
            TianZiGeTitle(text: "农业词")
        } else {
            Text("Farming Words")
                .font(Theme.serif(34, .black))
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var meterRow: some View {
        let overall = meter(in: nil)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(overall.known)")
                    .font(Theme.serif(34, .black))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                Text(isChinese ? "/ \(overall.total) 已认识" : "/ \(overall.total) known")
                    .font(Theme.body)
                    .foregroundStyle(Theme.muted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Theme.card)
                    Rectangle().fill(Theme.red)
                        .frame(width: geo.size.width * CGFloat(overall.share))
                }
            }
            .frame(height: 8)
            .clipShape(RoundedRectangle(cornerRadius: 2))
        }
    }

    private var groupChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TopicChip(label: isChinese ? "全部" : "All",
                          counter: "\(meter(in: nil).known)/\(meter(in: nil).total)",
                          isOn: filter == nil) { filter = nil }
                ForEach(TopicGroup.allCases, id: \.self) { g in
                    let m = meter(in: g)
                    TopicChip(label: isChinese ? g.chinese : g.english,
                              counter: "\(m.known)/\(m.total)",
                              isOn: filter == g) { filter = g }
                }
            }
        }
    }

    @ViewBuilder
    private var archivedSection: some View {
        if !archived.isEmpty {
            Button { isShowingArchived.toggle() } label: {
                HStack(spacing: 4) {
                    Text(isChinese ? "已归档" : "Put away")
                    Image(systemName: isShowingArchived ? "chevron.up" : "chevron.down")
                }
                .font(Theme.label)
                .tracking(1.4)
                .foregroundStyle(Theme.muted)
            }
            .buttonStyle(.plain)
            .padding(.top, 20)

            if isShowingArchived {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(archived, id: \.word) { row in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.word).font(Theme.title).foregroundStyle(Theme.ink)
                                Text(row.english).font(Theme.meta).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Button(isChinese ? "恢复" : "Restore") { restoreCustom(row.word) }
                                .font(Theme.body)
                                .foregroundStyle(Theme.red)
                        }
                        .padding(.vertical, 8)
                        Divider().background(Theme.rule.opacity(0.5))
                    }
                }
            }
        }
    }

    private func mark(_ term: TopicTerm, known: Bool) {
        if known { try? library.markKnown(term.word) }
        else { try? library.takeKnownBack(term.word) }
    }

    private func archiveCustom(_ word: String) { try? library.archiveCustom(word) }
    private func restoreCustom(_ word: String) { try? library.restoreCustom(word) }
}

private struct TopicChip: View {
    let label: String
    let counter: String
    let isOn: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(label).font(Theme.body)
                Text(counter).font(Theme.meta).foregroundStyle(Theme.muted).monospacedDigit()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.controlRadius)
                    .stroke(isOn ? Theme.red : Theme.rule, lineWidth: isOn ? 1.5 : 1)
            )
            .foregroundStyle(isOn ? Theme.red : Theme.ink)
        }
        .buttonStyle(.plain)
    }
}

private struct TopicRow: View {
    let term: TopicTerm
    let isKnown: Bool
    let onMark: () -> Void
    let onTakeBack: () -> Void
    let onArchive: (() -> Void)?

    @State private var isOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { isOpen.toggle() }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(term.word)
                                .font(Theme.title)
                                .foregroundStyle(Theme.ink)
                                .strikethrough(isKnown, color: Theme.red.opacity(0.6))
                            if term.isCustom {
                                Text("mine")
                                    .font(.system(size: 10)).tracking(1)
                                    .foregroundStyle(Theme.muted)
                                    .padding(.horizontal, 5).padding(.vertical, 1)
                                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.rule))
                            }
                        }
                        Text(term.pinyin).font(Theme.meta).foregroundStyle(Theme.muted)
                        Text(term.english).font(.system(size: 13)).foregroundStyle(Theme.ink)
                    }
                    Spacer(minLength: 8)
                    if isKnown {
                        Text("完")
                            .font(Theme.serif(16, .black))
                            .foregroundStyle(Theme.onRed)
                            .frame(width: 28, height: 28)
                            .background(Theme.red)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .rotationEffect(.degrees(-6))
                            .accessibilityLabel(Text("已认识"))
                    } else {
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Theme.ink, lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                    }
                }
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if isOpen {
                HStack(spacing: 10) {
                    if isKnown {
                        Button("其实不认识") { onTakeBack() }
                            .font(Theme.body)
                            .foregroundStyle(Theme.muted)
                    } else {
                        Button {
                            onMark()
                        } label: {
                            Text("认识")
                                .font(Theme.body)
                                .foregroundStyle(Theme.onRed)
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .background(Theme.red)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
                        }
                        .buttonStyle(.plain)
                    }
                    if let onArchive {
                        Button("归档") { onArchive() }
                            .font(Theme.body)
                            .foregroundStyle(Theme.muted)
                    }
                    Spacer()
                }
                .padding(.bottom, 10)
            }
        }
    }
}

private struct AddCustomTopicWordSheet: View {
    let initialGroup: TopicGroup
    /// Hands the typed fields back and takes the library's answer. A refusal keeps the sheet open
    /// and shows the reason, so the student is never left tapping Add with nothing happening.
    let onAdd: (String, String, String, TopicGroup) -> TopicLibrary.AddResult

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var word = ""
    @State private var pinyin = ""
    @State private var english = ""
    @State private var group: TopicGroup
    @State private var errorText: String?

    init(initialGroup: TopicGroup,
         onAdd: @escaping (String, String, String, TopicGroup) -> TopicLibrary.AddResult) {
        self.initialGroup = initialGroup
        self.onAdd = onAdd
        _group = State(initialValue: initialGroup)
    }

    private var isChinese: Bool { locale.language.languageCode == .chinese }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(isChinese ? "中文" : "Chinese", text: $word)
                    TextField(isChinese ? "拼音（可选）" : "Pinyin (optional)", text: $pinyin)
                    TextField(isChinese ? "英文" : "English", text: $english)
                }
                Section {
                    Picker(isChinese ? "分组" : "Group", selection: $group) {
                        ForEach(TopicGroup.allCases, id: \.self) { g in
                            Text(isChinese ? g.chinese : g.english).tag(g)
                        }
                    }
                }
                if let errorText {
                    Section {
                        Text(errorText).font(Theme.body).foregroundStyle(Theme.error)
                    }
                }
            }
            .navigationTitle(isChinese ? "添加自己的词" : "Add my own word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isChinese ? "取消" : "Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isChinese ? "添加" : "Add") {
                        switch onAdd(word, pinyin, english, group) {
                        case .added: dismiss()
                        case .refused(let reason): errorText = message(for: reason)
                        }
                    }
                    .disabled(word.trimmingCharacters(in: .whitespaces).isEmpty ||
                              english.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func message(for reason: TopicLibrary.AddResult.Reason) -> String {
        switch reason {
        case .emptyWord: return isChinese ? "请写中文词" : "Write the Chinese word."
        case .notChinese: return isChinese ? "请用中文字" : "Use Chinese characters."
        case .emptyEnglish: return isChinese ? "请写英文" : "Add the English meaning."
        case .alreadyInList: return isChinese ? "这个词已经在列表里了" : "This word is already in the list."
        }
    }
}
