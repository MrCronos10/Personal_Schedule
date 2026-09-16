# 05: Tick and untick an Action

**What to build:** On the Daily Checklist, tapping an Action's circle opens a Tick sheet. Minutes are filled in from the Action's Default Minutes; the student can change them or leave them empty, and add an optional Note. Saving creates a Completion for that day, and the Action shows as done. The Completion keeps a copy of the Action's title and Category as they were when ticked (ADR 0002). Tapping a ticked circle asks for confirmation, then removes the Completion.

**Blocked by:** 04 (Plan a One-time Action and see it on the Daily Checklist)

**Status:** ready-for-human (the tap-through checks on the iPhone are left)

- [x] Tapping an unticked Action opens the Tick sheet with Minutes pre-filled from Default Minutes (empty if the Action has none)
- [x] Minutes can be changed or cleared; the Note is optional
- [x] Saving creates a Completion for the day shown, and the Action shows as done
- [x] The Completion stores its own copy of the title and Category
- [x] Tapping a ticked Action asks for confirmation; confirming removes the Completion and the Action is no longer done
- [x] Completions are kept after reopening the app
- [x] Tests cover: ticking with default minutes, with changed minutes, with no minutes, and unticking
- [x] All new screen text exists in 中文 and English
- [ ] Verified on the iPhone: tick an Action with 25 minutes and a Note, reopen the app, it is still done

## Comments

- Tests are at the Completion library: ticking records the minutes plus copies of the title and Category; ticking with no minutes still counts as done and adds no time; the Note is saved; unticking removes the Completion; negative minutes are refused; the copy survives a later rename of the Action; Completions are still there after the database is reopened.
- An Action has at most one Completion per day. Ticking again updates that Completion instead of adding a second one.
- On the checklist, a done Action shows the red 完 seal, a struck-through title and its minutes; an unticked one shows an empty ink square.
- The Tick sheet has a minutes field with −5 / +5 buttons and an optional Note field. Saving with letters in the minutes field shows 请输入数字.
- The screen uses the same day rule as the tests (`CompletionLibrary.descriptor(for:)`).
- Code review found one real bug: ticking twice (a double tap) created two Completions, and unticking then removed only one, so the Action still looked done. A test was written first, then ticking was changed to update the existing Completion. It also noted one redundant piece of state in the checklist, which was removed. All 24 tests passed afterwards.
- Not seen running: the tick box, the Tick sheet and the 完 seal, because the simulator has no data and can't be tapped from the command line. The app opens normally.
