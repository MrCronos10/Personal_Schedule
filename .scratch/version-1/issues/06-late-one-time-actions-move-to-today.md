# 06: Late One-time Actions move to today

**What to build:** A One-time Action that was not ticked by the end of its planned date moves forward: it appears only on today, marked as late in a different color, and keeps moving each day until it is ticked or deleted. Once ticked, it stays on the day it was ticked. The student can delete a One-time Action that is not ticked; a ticked one can't be deleted.

**Blocked by:** 05 (Tick and untick an Action)

**Status:** ready-for-human (the tap-through checks on the iPhone are left)

- [x] An unticked One-time Action with a planned date before today appears on today, marked late
- [x] It does not appear on the past days between its planned date and today
- [x] A One-time Action planned for a future date still appears only on that date
- [x] A ticked One-time Action appears on the day it was ticked, as done, and not on later days
- [ ] An unticked One-time Action can be deleted (with confirmation); a ticked one offers no delete
- [x] Tests cover: late Action moves to today, future Action stays on its date, ticked Action stays on its tick day
- [x] All new screen text exists in 中文 and English
- [ ] Verified on the iPhone: create a One-time Action for yesterday, it appears today marked late

## Comments

- The day rule now needs to know what today is, so `DayPlan` takes `today` everywhere: `descriptor(for:today:)` fetches everything planned on or before the day, and `appears(_:on:today:)` decides. A ticked Action sits on its Completion's day; an unticked one waits on its planned day while that day is still ahead, and moves to today once the day has passed.
- Tests at `DayPlan`: a late Action shows only on today and on none of the days between; an Action planned for a later day stays on that day; a ticked Action stays on the day it was ticked. Also `DayPlan.isLate` agrees with `appears`, so a day the Action isn't on is never marked late. At `ActionLibrary`: an unticked Action can be deleted, a ticked one is refused with `ActionError.tickedAction` and is still there afterwards.
- `tickedOneTimeActionStaysOnTheDayItWasTicked` passed the moment it was written — the Completion branch of `appears` already covered it — so it is kept as a guard, not claimed as a rule it drove.
- The existing `DayPlan` tests now pass `today` explicitly, because the rule reads today and the old tests read the real clock. `actionAppearsOnlyOnItsOwnDay` became `actionPlannedForALaterDayAppearsOnlyOnThatDay`, and one call in `CompletionLibraryTests` was updated. `today` has no default on the library any more, so a caller can't silently get clock-dependent results; only the screen fills it in.
- The screen uses the same rule, not a copy: `DayChecklist` queries `DayPlan.descriptor(for:today:)` and then `DayPlan.plan(_:on:today:)`, which is the same filter-and-sort `actions(on:today:)` runs.
- A late row is written in a new `Theme.late` ink with a 迟到 mark and the day it was planned for, and its empty tick box takes the same ink. 删除 is a long-press menu, offered only on unticked rows, behind a confirmation.
- New screen text: 迟到, 删除, 删除这个计划？, “%@”会被删除，不能恢复。 — all with English.
- Splitting `ActionRow` into `row` / `meta` / `tickBox` was needed to build at all: the one-expression body hit "the compiler is unable to type-check this expression in reasonable time".
- All 29 tests pass. The app opens normally in the simulator on an empty database.
- `/code-review` raised 10 findings; 5 were real and are fixed: the delete dialog read the title off an already-deleted Action (the dialog is now closed before the delete, and the message reads a kept copy of the title); the screen had a second copy of the day rule (now `DayPlan.plan`); `today` defaulted to the wall clock in the library; `isLate` could disagree with `appears`; a ticked row still installed an empty long-press menu.
- Left alone on purpose: the fetch is `plannedDayNumber <= max(day, today)` and filters in memory, which is more rows than a two-clause predicate but nothing at one student's scale; `try?` on delete matches how untick already behaves and the menu is only offered when the delete can't be refused; `delete` guards on `action.completions`, the same accessor the tested `appears` uses, rather than a second Completion fetch; the 迟到 date has no year, which only reads oddly for an Action more than a year late.
- Not seen running: the 迟到 ink and mark, the long-press 删除 menu, and both dialogs. The simulator has no data and can't be tapped from the command line, so those are the iPhone checks left.

### For the student to decide

Unticking an Action on a past day makes it leave that day and reappear on today as 迟到. That is what "How a day is worked out" says — unticked plus a planned day that has passed means today only — but it means a mis-tick on Sunday can't be corrected in place on Sunday. Version 1's goal list includes "fix any past day you forgot to tick", so this may want its own ticket. Nothing was changed here; the rule as written is what shipped.
