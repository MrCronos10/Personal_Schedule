# 01: Per-Category cards, weekly ledger, and retroactive Completion

**What to build:** Rebuild 进度 (Progress Tracker) so each Category is its own card carrying: its existing progress bar or Completion Count, a new 7-day ledger strip (done / Missed / Today / Plan), this week's Active Routines with their Completion counts, and — only when it has one — a Continuity Safeguard note for a Paused Routine. Tapping a Missed day in a Category's ledger jumps to `TodayView` for that day, reusing the existing Daily Checklist to log the Completion retroactively.

**Blocked by:** —

**Status:** ready-for-human (every check left is a judgement on the phone)

**Source:** `/Users/kuypav/Desktop/stitch_china_study_routine_tracker/DESIGN.md`, `screen.png`, `code.html`. Scoped in a grilling session on 2026-09-22 (13 questions, all recommended answers taken) — see Comments for the reasoning behind what was dropped.

## What is kept from the old ProgressTrackerView

- [x] `WeekLedger`'s outer shell stays: the week-range line, `本周` title (`TianZiGeTitle` in Chinese, heavy serif in English), `SectionCaption`. Only the row content changes, per `Theme`'s existing `.card()` and `Chip` components — no second copy of either.
- [x] The archived-Category and empty-week handling in `WeekLedger.content` is unchanged.
- [x] `CategoryWeekRow`'s existing bar-vs-count split (Weekly Target → `WeeklyTargetBar`, no target → Completion Count) is unchanged; it's the foundation each card is built on, not replaced.

## Library rule: what a ledger cell shows for one Category-day

- [x] A Category's ledger cell for a given day is:
  1. **done**, showing that day's total minutes (or Completion count for a Completion-Count Category), if the Category has ≥1 Completion that day — even if a different Routine in the same Category was also Missed that day.
  2. else **Missed**, if any Routine belonging to the Category was Missed that day (existing `DayPlan.isMissed` rule — a Routine on/after its start date, its weekday, outside any Pause, not ticked, day has ended).
  3. else **Today**, if the day is today and neither of the above applied yet.
  4. else **Plan**, for a future day.
- [x] Days before a Routine existed, or inside one of its Pauses, are never Missed — this reuses `DayPlan`'s existing rule exactly; do not re-derive it in the new query.
- [x] This is a genuinely new rule (the done-beats-Missed tie-break) and needs its own test in `CompletionLibraryTests` (or wherever the query lives) — see Tests.

## Library rule: Active Routines breakdown

- [x] Per Category, list its currently active (non-paused, non-archived) Routines with: this week's Completion count and Default Minutes. **Routines only** — One-time Actions are not repeated here; they already show individually on the Daily Checklist.
- [x] Build the fixture for this test from an explicit list of Actions/Completions, per AGENTS.md's fixture rule — don't eyeball a scenario into existing test data.

## Screen

- [x] Each `CategoryWeekRow` becomes a richer card: existing bar/count line, then the new 7-day ledger strip, then Active Routines this week, then — only if the Category has a Routine currently Paused — a Continuity Safeguard note.
- [x] Continuity Safeguard note text is UI-only phrasing for the existing **Paused Routine** (its Pause start/end dates, "zero Missed days" framing). It is **not** a new term — nothing changes in `CONTEXT.md`.
- [x] Tapping a Missed ledger cell deep-links to `TodayView` set to that day. Today/Plan/done cells are not tappable — `TodayView`'s own ◀▶ already covers general day-browsing, so this isn't a second way to do the same thing.

## Explicitly not building (decided in the grilling session, don't add by accident)

- [x] No hero/featured Category at the top of the screen — every Category is an equal card (Q2).
- [x] No separate weekly-summary banner — it would just repeat the first card's own numbers (Q8).
- [x] No "Discipline is quiet, non-punitive continuity" quote card — decorative, no domain content (Q1).
- [x] No Category subtitle field (e.g. "身心平衡") — Category name is already free text; the student can put it there themselves if they want it (Q6).
- [x] No per-Category Note count — real feature, but independent enough to deserve its own ticket, not a rider here (Q7).
- [x] No week navigation — matches the existing limit (this week only).

## Tests

- [x] New: the done-beats-Missed tie-break rule for a Category-day cell, with a fixture where one Routine in a Category is completed and another in the same Category is Missed on the same day — assert the cell reads done.
- [x] New: Active Routines breakdown includes only Routines, built from a fixture with both a Routine and a One-time Action in the same Category — assert the One-time Action is absent from the breakdown.
- [x] New: a ledger cell before a Routine's start date, and inside its Pause, is never Missed (reuses `DayPlan.isMissed`; test that the new query defers to it rather than re-implementing it).
- [x] Existing `WeekLedger`/`CategoryWeekRow` tests still pass. If one needed changing, that means this ticket touched a rule, not just the screen — say so plainly in Comments.
- [x] Whole suite green at the end.

## Left for the iPhone

- [ ] Layout density: does a Category card with bar + ledger + routines list + safeguard note feel cluttered on one phone screen, especially a Category with several active Routines?
- [ ] Ledger cell tap targets are usable at thumb size, and a Missed cell's tappability is visually obvious without a label doing all the work.
- [ ] English locale: Category cards with a Routines list and ledger read fine, not cramped, in the Latin serif.
- [ ] The Continuity Safeguard note doesn't read as alarming — check the tone matches "non-punitive" against a real Paused Routine on the phone.

## Comments

- **`activeRoutines` only checks `!$0.isPaused`, not "non-archived"** — Action has no archived concept in this app (only Category is archived, per CONTEXT.md); nothing needed changing here, the ticket's own wording was just ahead of the model.
- **The Continuity Safeguard note doesn't count "zero Missed days"** — it says "From [date] — nothing in this stretch counts as Missed" without a count, since the Pause itself already guarantees zero by construction (`DayPlan.isMissed` returns false for any day inside a Pause). Counting would have meant deriving a number that can only ever be zero, which said nothing a plain sentence didn't already say.
- **No prior `WeekLedger`/`CategoryWeekRow` tests existed to keep passing** — this screen was always "checked by hand" per AGENTS.md, so there was nothing to break here; the new library rules are what got the new tests.
- **Retroactive entry is a `.sheet` presenting `TodayView(initialDay:)`**, not a NavigationLink — matches how `ActionFormView` and `TickSheetView` are already presented elsewhere in the app (modal, not push).
- 193 tests pass, 16 suites (6 new: the tie-break, Missed-untouched, before/inside-Pause, today/plan, and the two Active Routines cases). `/code-review` (medium) found nothing to fix.
- The simulator confirms the tokens, ledger dots, and Continuity Safeguard note render on an empty store. Everything with real Completions, Missed days, and Paused Routines in it is left for the phone, since the simulator can't be tapped and there's no way to build that state from here.
