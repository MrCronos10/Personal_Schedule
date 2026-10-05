# 03: Today restyle

**What to build:** `screens/Today.dc.html`. Dawn header, boxed 今天 title, Today card (Routine ring, reading progress, stamp slot), 最近认识 sliver, notebook-rule checklist, 去读 button on the next reading Action, floating + button. Move Settings to a button on Today and Notes to a sheet if v1 ticket 05 has not already.

**Blocked by:** 01. **Status:** ready-for-human

## The rule

- [x] The sliver reads the last 10 Words that became Known across all lists, newest right; the query lives in a library with a test (`CollectionLibrary.recentlyKnown`, `CollectionLibraryTests`).
- [x] Today's characters read use the same count the Reading Session saves; one rule, not a second copy (`ArticleLibrary.charactersRead`, shown by the Today card).
- [x] The stamp slot fills once per day when the goal (default 200 字, in Settings) is first reached; medium haptic, first time only (`Celebrations.readingGoalStampIsDue` / `markReadingGoalStamped`, `CelebrationTests`).
- [x] All Routines done folds into one "今天 — 完成" card (`DayChecklist`).
- [x] Outstanding Actions still show before ticked ones (`DayPlan.plan` / `ordered`).
- [x] New strings translated; student's own text uses `Text(verbatim:)`.

## Comments

This was mostly a **visual restyle**: the library rules above were already built and tested in earlier work (tickets 22/25), so no new red/green cycle was needed here — the screen is checked by hand/screenshot.

**Built (verified on the simulator by screenshot, not tapped):**
- Full-bleed **Dawn ground** (`DawnHeader`) with the red sun, behind the header and title.
- **Boxed 今天** title (`TianZiGeTitle`) with the year's goal below it (the goal text moved inline; the standalone `GuidingGoalBanner` is removed).
- **Today card** (`TodayCard`, new): green Routine ring (routines done/total), "今日阅读 N / 200 字" with a red bar, and the **goal stamp slot** — dashed "再读 N 字" that becomes the 读 seal when the goal is first reached (landing + medium haptic owned by `TodayView`, once per day).
- **Floating + button**; round 笔记 / 设置 doors; the `最近认识` sliver and notebook-rule checklist kept.
- Four new strings (今日阅读, 再读, 字, 今日常规) with English; full suite **360**.

**/code-review (5 findings, all fixed):** FAB covering the last row's tick box (bottom inset raised); FAB wrongly gated so a ledger sheet couldn't add an Action (ungated); the 最近认识 strip narrowed to today-only (restored to any day); the reading block not grouped for VoiceOver (combined); and the xcstrings trailing newline (restored).

**Deferred (open question, not guessed):**
- **`去读` button on the next reading Action** — there is no rule for *which* Action is "the reading Action," and `AppRouter` has no `showReading`. Worth a short grill before building, so it routes from the right row.
- Row-level **tick-circle / category-dot** restyle and the caption's done/total count (smaller polish).

**Not seen running / left for the phone:** the goal stamp landing on-device; the Dawn ground, card, and checklist against real data; light/dark.
