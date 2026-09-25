# 22: Tap a Note to open its day

**What to build:** Tapping a row in the 笔记 tab opens **Today's** Daily Checklist for the day that Note was written, the same way a Missed cell on the Progress Tracker already opens a day. Ticket 21 built the list and left this for later: "Jumping to that day on 今天 is worth having and is its own ticket."

Words in **bold** are defined in [CONTEXT.md](../../../CONTEXT.md).

**Blocked by:** 21 (done)

**Status:** ready-for-human (the tap itself needs a finger)

## Why now

The Notes List is read-only by design (ticket 21) — no edit, no delete. The one thing worth adding is a way back to the day the Note came from, so a word met while reading can be followed to the plan it was ticked under, and corrected there if it needs to be (the existing "uncheck / recheck" path on 今天, not a new one here).

## The decision

**Reuse `TodayView(initialDay:)`, not a new detail view.** The Progress Tracker already opens a chosen day this way, as a sheet, for exactly the same reason: reuse the Daily Checklist's own tick logic rather than a second copy of it ([ProgressTrackerView.swift](../../../PersonalSchedule/Progress/ProgressTrackerView.swift)). A Note's day is shown, not a bespoke "note detail" screen — there is nothing about a Note that isn't already on that day's checklist.

## The list

- [x] Tapping a `NoteRow` presents `TodayView(initialDay: completion.day)` as a sheet, matching the Progress Tracker's retroactive-day sheet
- [x] The row shows it is tappable: `.accessibilityAddTraits(.isButton)`, matching the Progress Tracker's Missed cell
- [x] No new string: the sheet is the existing 今天 screen, already fully translated

## Not in scope

- [x] No edit or delete added to the Notes tab itself — correcting a Note still happens by unticking/re-ticking on 今天, unchanged from ticket 21
- [x] No change to `CompletionLibrary`: this ticket wires an existing screen to an existing initializer, and adds no rule

## Tests

There is no new rule to pin at a library: this is a screen calling an initializer (`TodayView(initialDay:)`) that ticket 20's Progress Tracker already exercises. Per [AGENTS.md](../../../AGENTS.md), screens are checked by hand, not with UI tests.

## Left for the iPhone

- [ ] Tap a Note and confirm it opens the right day, with that day's Actions and ticks intact
- [ ] Dismiss the sheet and confirm the Notes list is unchanged underneath
- [ ] Tap a Note for a day whose Action has since been renamed or moved, and confirm today's checklist for that day still opens correctly (it shows the Action as it is now, which is expected — only the Note itself is a frozen copy)

## Comments

- Tapping a `NoteRow` opens `TodayView(initialDay: completion.day)` as a sheet, the same `.contentShape(Rectangle())` + `.onTapGesture` + `.accessibilityAddTraits(.isButton)` idiom the Progress Tracker's Missed cell already uses — no new pattern, no new library rule.
- While running the full suite, `TranslationTests.everyScreenTextHasAnEnglishTranslation` failed on a pre-existing, unrelated bug: `ProgressTrackerView` had `Text(" ")` (translatable) instead of `Text(verbatim: " ")` for a separator space in an accessibility label, and the checked-in `Localizable.xcstrings` carried that `" "` key with no English translation. Fixed both — the code now uses `verbatim`, and the catalog entry got its translation — since it blocked a green suite; it is unrelated to this ticket's own change.
- `/code-review` (medium) found no issues.
- 193 tests pass, 16 suites.

### Left for the iPhone
The three checks above are unchecked — they need a tap on device and are the student's to confirm.

