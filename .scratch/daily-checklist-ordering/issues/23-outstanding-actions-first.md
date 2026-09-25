# 23: Outstanding Actions sort before ticked ones

**What to build:** `DayPlan.ordered(_:)` moves from a flat sort to a two-tier sort — Actions with no **Completion** on the day being shown, then Actions with one — so the **Daily Checklist** reads as "what's left" first, with what's already done pushed to the bottom rather than mixed through the list.

Words in **bold** are defined in [CONTEXT.md](../../../CONTEXT.md).

**Blocked by:** — (no dependency on anything unbuilt)

**Status:** ready-for-human (only the two "Left for the iPhone" taps remain)

## Why now

The student was asked for ideas to make the app more inviting to open every day. This one survived a full grilling session in `/grill-with-docs`: the original idea (a separate "morning" screen pulling in a Timetable and Daily New Words that don't exist yet) collapsed down to a small, safe ordering change once the two-tier sort was pushed into `DayPlan.ordered(_:)` itself, per the repo rule that screens reuse the shared `ordered(_:)`/`plan(_:on:today:)` helpers rather than a second copy of a sort. `CONTEXT.md`'s **Daily Checklist** entry already carries the one-line result of that grilling.

## One decision made without asking

**"Ticked" means a Completion exists for that Action on the day being shown — nothing more.** A Routine day inside a **Pause**, or a day before the Routine existed, simply doesn't appear on the day's Action list at all (existing `DayPlan.appears` behaviour, unchanged), so there's no third state to sort. **Missed** isn't a display state either — a Missed day is just an unticked Action on a past day, and it sorts into the outstanding tier exactly like an unticked Action today.

## The change

- [x] `DayPlan.ordered(_:)` → `DayPlan.ordered(_:on:)` (`PersonalSchedule/Model/DayPlan.swift:73`) now takes the `Day` it's ordering for, and checks ticked status the same way `appears(_:on:today:)` already does: `action.completions?.contains { $0.dayNumber == day.number }`, via a new private `isTicked(_:on:)` helper. Simpler than the lookup-passing shape sketched in this ticket — see Comments.
- [x] Sort is two-tier: Actions with no Completion for the day, first; Actions with one, after.
- [x] Within each tier, the existing rule is unchanged: timed Actions first (earliest first), then untimed Actions in the order they were added.
- [x] `DayPlan.plan(_:on:today:)` (`PersonalSchedule/Model/DayPlan.swift:90`) passes `day` through to `ordered(_:on:)`.
- [x] `DayChecklist.swift:44` and `ArticleReaderView.swift:187` need no change at all — both already call `DayPlan.plan`/`.actions` with the day, and `ordered`'s new day-based check reads `Action.completions` directly rather than needing a completions lookup passed in.
- [x] Ticked Actions are never hidden. They still render, at the bottom of the list.

## Tests

At `DayPlanTests`, since the rule lives in `DayPlan` (per AGENTS.md's "Where tests go"):

- [x] An unticked, untimed Action sorts before a ticked, untimed Action, even though the ticked one was added first — `untickedActionsSortBeforeTickedOnesEvenWhenTickedWasAddedFirst`
- [x] A ticked, timed Action (e.g. 6am) still sorts after an unticked, untimed Action — the ticked tier is strictly after the unticked tier, timed or not — `aTickedTimedActionStillSortsAfterAnUntickedUntimedAction` (passed the moment it was written; kept as a guard)
- [x] Within the unticked tier, the existing time-then-added-order rule holds — `withinTheUntickedTierTimedActionsComeFirstEarliestFirstThenUntimedInTheOrderAdded` (guard, passed immediately)
- [x] Within the ticked tier, the same time-then-added-order rule holds — `withinTheTickedTierTimedActionsComeFirstEarliestFirstThenUntimedInTheOrderAdded` (guard, passed immediately)
- [x] A day with every Action ticked, or every Action unticked, returns them in the existing time-then-added-order — covered by the two tests above plus the pre-existing `timedActionsComeFirstEarliestFirstThenUntimedInTheOrderAdded`, which is all-unticked and still passes unchanged
- [x] A Missed Routine day sorts in the unticked tier, same as an unticked Action on today — `aMissedRoutineDaySortsInTheUntickedTier` (guard, passed immediately)
- [x] Every pre-existing `DayPlanTests` test still passes — full suite run, 198 tests / 16 suites green

## Screens

- [x] `DayChecklist` (今天 tab): outstanding Actions above ticked ones, visually unchanged otherwise — falls out of the `DayPlan.plan` change with no screen edit
- [x] `ArticleReaderView`'s Action picker: same ordering, since it calls the same `DayPlan.plan` — no screen edit needed here either

## Left for the iPhone

- [ ] Tick an Action and watch it move to the bottom rather than disappear — confirm the motion doesn't feel jarring (no animation is required by this ticket, but check the default SwiftUI diff behavior isn't distracting)
- [ ] Confirm a Missed day's checklist (opened via the Progress Tracker's ledger, per `TodayView`'s `initialDay`) shows the same outstanding-first ordering

## Not in this feature

- Any new screen, notification, or time-of-day logic — dropped during grilling
- Timetable/Class UI and a Daily New Words screen — don't exist yet, not built here
- An ADR — not hard to reverse, not surprising, not a real trade-off between alternatives

## Comments

- **Simpler than planned.** The ticket sketched `DayChecklist` and `ArticleReaderView` passing a Completions lookup into `DayPlan.ordered(_:)`. That turned out unnecessary: `appears(_:on:today:)` already reads `action.completions` directly to decide what's on a day, so `ordered(_:on:)` does the same thing to decide *where* on the day — one pattern, not two. Neither screen needed a line changed.
- **`isMissed` now calls the new `isTicked(_:on:)` helper instead of its own copy of the same completion check.** `/code-review` (medium) caught that `isMissed` and the freshly-added `isTicked` encoded the identical "was this Action ticked on this day" rule as two separate expressions in the same file — exactly the kind of duplicate the repo's "never a second copy of a filter or sort" convention is meant to catch, just inside one file rather than across screens. Fixed by having `isMissed` call `!isTicked(action, on: day)`.
- **Four of the six new tests passed the moment they were written.** Only the first test (unticked-before-ticked) actually drove new code; the rest — tier beating time, within-tier ordering for both tiers, and the Missed-day case — followed for free from that one change and are kept as regression guards, per AGENTS.md's "if a test passes the moment it is written, say so plainly."
- 198 tests pass, 16 suites, after the `/code-review` fix.
- **Not seen running:** the two "Left for the iPhone" checks (the tick-to-bottom motion in the simulator, and a Missed day's ordering via the Progress Tracker's ledger) need a tap and are left for the student.
