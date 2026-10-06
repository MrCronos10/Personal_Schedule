import SwiftData
import SwiftUI

/// 印章册: the Seal Book, opened from 进度 (ADR 0010). Loads what the student has earned, earns
/// anything newly due, and hands the result to `SealBookPage` to draw.
///
/// A seal earned while the book is open lands with the stamp animation and one medium haptic. No
/// sound, and nothing here counts a run of days or shows anything as owed.
struct SealBookView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var progress: [SealLibrary.Progress] = []
    @State private var next: SealLibrary.Progress?
    @State private var newlyEarned: Set<Seal> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.onRed.opacity(0.8))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(Text("关闭"))
                }
                SealBookPage(progress: progress, next: next, newlyEarned: newlyEarned)
            }
            .padding(.bottom, 32)
        }
        .background(LacquerBackground())
        .task { load() }
        .sensoryFeedback(.impact(weight: .medium), trigger: newlyEarned) { _, earned in !earned.isEmpty }
    }

    /// Earns what is now due first, so the book never shows a seal as 29 of 30 that the rules say is
    /// already earned.
    private func load() {
        let library = SealLibrary(context: context)
        newlyEarned = Set((try? library.evaluate(on: Day.today())) ?? [])
        progress = (try? library.progress()) ?? []
        next = try? library.next()
    }
}

/// The Seal Book as drawn, given what it holds. Kept apart from the database so it can be looked at
/// with any state in front of it.
struct SealBookPage: View {
    let progress: [SealLibrary.Progress]
    let next: SealLibrary.Progress?
    var newlyEarned: Set<Seal> = []

    @Environment(\.locale) private var locale

    private var earnedCount: Int { progress.filter(\.isEarned).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            if let next {
                nextCard(next)
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: 3),
                spacing: 22
            ) {
                ForEach(progress) { tile($0) }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("印章册")
                    .font(Theme.serif(28, .black))
                    .foregroundStyle(Theme.onRed)
                    .accessibilityAddTraits(.isHeader)
                Text("读出来的印章，永远不会失去。")
                    .font(Theme.meta)
                    .foregroundStyle(Theme.onRed.opacity(0.7))
            }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(verbatim: "\(earnedCount)")
                    .font(Theme.mono(30, .semibold))
                    .foregroundStyle(Theme.brass)
                Text(verbatim: "/ \(progress.count)")
                    .font(Theme.mono(14))
                    .foregroundStyle(Theme.onRed.opacity(0.6))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: "\(earnedCount) / \(progress.count)"))
        }
    }

    // MARK: - 下一枚

    /// The seal furthest along, with how far. Progress and nothing about what is late.
    private func nextCard(_ next: SealLibrary.Progress) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("下一枚")
                .font(Theme.label)
                .tracking(1.6)
                .foregroundStyle(Theme.brass)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(next.seal.name)
                    .font(Theme.serif(18))
                    .foregroundStyle(Theme.onRed)
                Text(next.seal.detail)
                    .font(Theme.meta)
                    .foregroundStyle(Theme.onRed.opacity(0.7))
                Spacer(minLength: 0)
                Text(verbatim: "\(next.current)/\(next.target)")
                    .font(Theme.mono(13, .semibold))
                    .foregroundStyle(Theme.onRed)
            }
            GeometryReader { bar in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.onRed.opacity(0.15))
                    Capsule().fill(Theme.brass).frame(width: bar.size.width * next.fraction)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(Theme.onRed.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Tiles

    @ViewBuilder
    private func tile(_ item: SealLibrary.Progress) -> some View {
        VStack(spacing: 6) {
            sealArea(item)
                .frame(height: 78)

            if item.seal.isHidden && !item.isEarned {
                Text("隐藏印章")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.onRed.opacity(0.75))
                Text("读着读着，就会出现")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.onRed.opacity(0.5))
                    .multilineTextAlignment(.center)
            } else {
                Text(item.seal.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(item.isEarned ? Theme.onRed : Theme.onRed.opacity(0.75))
                Text(item.seal.detail)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.onRed.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                footer(item)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func sealArea(_ item: SealLibrary.Progress) -> some View {
        if item.isEarned {
            SealMark(seal: item.seal, animated: newlyEarned.contains(item.seal))
        } else {
            // Not earned yet: a dashed outline with a rule through it, the practice-book blank.
            let ink = item.seal.isRare ? Theme.brass : Theme.onRed
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(ink.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .frame(width: 60, height: 60)
                if item.seal.isHidden {
                    Text(verbatim: "？")
                        .font(Theme.brush(30))
                        .foregroundStyle(Theme.onRed.opacity(0.55))
                } else {
                    Rectangle()
                        .fill(ink.opacity(0.35))
                        .frame(width: 26, height: 1.5)
                }
            }
        }
    }

    /// The date it was earned, or how far along it is. Never a deadline.
    @ViewBuilder
    private func footer(_ item: SealLibrary.Progress) -> some View {
        if let day = item.earnedDay {
            Text(verbatim: day.date().formatted(.dateTime.month().day().locale(locale)))
                .font(Theme.mono(11))
                .foregroundStyle(Theme.brass)
        } else {
            Text(verbatim: "\(item.current)/\(item.target)")
                .font(Theme.mono(11))
                .foregroundStyle(Theme.onRed.opacity(0.6))
        }
    }
}

#Preview {
    SealBookPage(
        progress: Seal.allCases.enumerated().map { index, seal in
            SealLibrary.Progress(
                seal: seal,
                current: index * 3,
                earnedDay: index < 4 ? Day(number: 20260902 + index) : nil
            )
        },
        next: SealLibrary.Progress(seal: .fiftyArticles, current: 32, earnedDay: nil)
    )
    .background(LacquerBackground())
}
