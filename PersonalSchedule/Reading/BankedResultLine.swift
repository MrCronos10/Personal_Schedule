import SwiftUI

/// One quiet line saying what a reading was worth: an Article's **Banked Result**.
///
/// Shown twice — under 读完 the moment it happens, and on the Article's row for as long as the
/// Article is kept — and phrased here once, so the two can never come to word the same numbers
/// differently.
///
/// No animation, no celebration, no sound: this happens every time the student finishes something,
/// and anything louder would wear out in a week.
struct BankedResultLine: View {
    let result: VocabularyLibrary.BankResult

    var body: some View {
        if result.wasReread {
            Text("重读 · 没有新的记录")
                .font(Theme.meta)
                .foregroundStyle(Theme.muted)
        } else {
            // Wrapped, because this is a list row as well as a line under a button: three parts at a
            // large Dynamic Type size will not sit on one line on a phone.
            HStack(spacing: 6) {
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    if index > 0 {
                        Text(verbatim: "·").foregroundStyle(Theme.muted)
                    }
                    Text(part.text).foregroundStyle(part.ink)
                }
            }
            .font(Theme.meta)
        }
    }

    private struct Part {
        let text: LocalizedStringKey
        let ink: Color
    }

    /// Everything this reading proved, each part only when it happened.
    ///
    /// **Words sent back to zero are named even when something else advanced.** As a line that
    /// flashed under 读完 it was enough to show the good news and leave the rest, but this is the
    /// Article's permanent record: an Article that moved one Word along and sent ten back would
    /// otherwise read "1 个词更近一步" for ever, indistinguishable from a reading with no **Lookups**
    /// in it at all — and losing ten Words is the more interesting half of what happened.
    private var parts: [Part] {
        var parts: [Part] = []
        if result.newlyKnown > 0 {
            parts.append(Part(text: "\(result.newlyKnown) 个词已掌握", ink: Theme.onDone))
        }
        if result.advanced > 0 {
            parts.append(Part(text: "\(result.advanced) 个词更近一步", ink: Theme.muted))
        }
        if result.returnedToZero > 0 {
            parts.append(Part(text: "\(result.returnedToZero) 个词要重新开始", ink: Theme.late))
        }
        // An Article that moved nothing still says so, rather than leaving a blank where a line goes.
        if parts.isEmpty {
            parts.append(Part(text: "这篇没有新的词", ink: Theme.muted))
        }
        return parts
    }
}

#Preview("two known, three advanced") {
    BankedResultLine(result: .init(newlyKnown: 2, advanced: 3))
}

/// The case the old line hid: one Word along, ten lost.
#Preview("advanced and lost together") {
    BankedResultLine(result: .init(advanced: 1, returnedToZero: 10))
}

#Preview("all three") {
    BankedResultLine(result: .init(newlyKnown: 2, advanced: 3, returnedToZero: 4))
}

#Preview("all looked up") {
    BankedResultLine(result: .init(returnedToZero: 4))
}

#Preview("nothing measured") {
    BankedResultLine(result: .init())
}
