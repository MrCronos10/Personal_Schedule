import SwiftData
import SwiftUI

/// The Today card: a green Routine ring, the day's reading progress against the goal, and the goal
/// stamp slot — a dashed "再读 N 字" that becomes the 读 seal once the goal is reached (`screens/
/// Today.dc.html`). The stamp's once-a-day landing and haptic are owned by `TodayView`; this view only
/// shows the seal (landing when `stampJustLanded`).
struct TodayCard: View {
    let day: Day
    let today: Day
    let charactersRead: Int
    let goal: Int
    let goalReached: Bool
    let stampJustLanded: Bool

    @Query private var candidateActions: [Action]
    @Query private var dayCompletions: [Completion]

    init(day: Day, today: Day, charactersRead: Int, goal: Int, goalReached: Bool, stampJustLanded: Bool) {
        self.day = day
        self.today = today
        self.charactersRead = charactersRead
        self.goal = goal
        self.goalReached = goalReached
        self.stampJustLanded = stampJustLanded
        _candidateActions = Query(DayPlan.descriptor)
        _dayCompletions = Query(CompletionLibrary.descriptor(for: day))
    }

    var body: some View {
        let plan = DayPlan.plan(candidateActions, on: day, today: today)
        let routines = plan.filter(\.isRoutine)
        let completed = Set(dayCompletions.compactMap { $0.action?.persistentModelID })
        let routinesDone = routines.filter { completed.contains($0.persistentModelID) }.count

        HStack(spacing: 14) {
            RoutineRing(done: routinesDone, total: routines.count)
                .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 6) {
                Text("今日阅读")
                    .font(Theme.meta)
                    .foregroundStyle(Theme.muted)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(verbatim: "\(charactersRead)")
                        .font(Theme.mono(18, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(verbatim: "/ \(goal)")
                        .font(Theme.mono(14))
                        .foregroundStyle(Theme.muted)
                    Text("字")
                        .font(Theme.meta)
                        .foregroundStyle(Theme.muted)
                }
                ReadingBar(fraction: goal > 0 ? min(1, Double(charactersRead) / Double(goal)) : 0)
                    .frame(height: 6)
            }
            .accessibilityElement(children: .combine)

            stampSlot
        }
        .padding(16)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    /// The goal stamp slot: a dashed "再读 N 字" until the goal is reached, then the 读 seal.
    @ViewBuilder private var stampSlot: some View {
        if goalReached {
            RedSealStamp(character: "读", ground: Theme.sealRed, animated: stampJustLanded)
                .frame(width: 56, height: 56)
        } else {
            VStack(spacing: 1) {
                Text("再读")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.muted)
                Text(verbatim: "\(max(0, goal - charactersRead))")
                    .font(Theme.mono(13, .semibold))
                    .foregroundStyle(Theme.sealRed)
                Text("字")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.muted)
            }
            .frame(width: 56, height: 56)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Theme.rule, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            )
            .accessibilityElement(children: .combine)
        }
    }
}

/// The green ring of Routines done out of the day's Routines.
private struct RoutineRing: View {
    let done: Int
    let total: Int

    var body: some View {
        let fraction = total > 0 ? Double(done) / Double(total) : 0
        ZStack {
            Circle().stroke(Theme.cardHigh, lineWidth: 6)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Theme.bamboo, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(verbatim: "\(done)/\(total)")
                .font(Theme.mono(14, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("今日常规"))
        .accessibilityValue(Text(verbatim: "\(done)/\(total)"))
    }
}

/// The day's reading progress, red on cream.
private struct ReadingBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.cardHigh)
                Capsule().fill(Theme.red).frame(width: geo.size.width * fraction)
            }
        }
    }
}
