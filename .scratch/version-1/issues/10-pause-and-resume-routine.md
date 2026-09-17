# 10: Pause and resume a Routine

**What to build:** 设置 has a Routines screen listing all Routines, showing which are paused. The student can pause a Routine and later resume it as the same Routine. Each pause is remembered with its start and end dates. While paused, the Routine doesn't appear on the Daily Checklist, and days inside any pause are never Missed, even after resuming. Routines can't be deleted, only paused.

**Blocked by:** 08 (Missed Routine days and fixing past days)

**Status:** ready-for-human (the tap-through checks on the iPhone are left)

- [x] 设置 has a Routines screen listing every Routine, with paused ones clearly marked
- [x] The student can pause a Routine from today; it no longer appears from today on
- [x] The student can resume a paused Routine; it appears again from today on
- [x] Days inside a past pause show no Routine and are not Missed
- [x] Days before and after the pause behave as before (ticked, or Missed if unticked)
- [x] A Routine can be paused and resumed more than once
- [x] There is no way to delete a Routine
- [x] Tests cover: paused days don't appear, paused days are never Missed after resuming, two separate pauses
- [x] All new screen text exists in 中文 and English
- [ ] Verified on the iPhone: pause a daily Routine, it disappears from today; resume it, it is back today

## Comments

- `Pause` is the fourth record: the Routine it belongs to, a start day, and an end day that is empty while the Routine is still stopped. It follows the database rules — optional fields, an optional relationship with an inverse — and adding it to the schema migrated the store the simulator already had without losing anything, which the app opening afterwards confirms.
- A pause covers its start day up to, but not including, the day the Routine was resumed. That is what makes 继续 today put the Routine back on today rather than tomorrow.
- Pausing a Routine that is already paused returns the pause it already has instead of opening a second one, so a double tap can't leave two open pauses behind.
- 设置 has a 重复计划 section listing every Routine oldest first, each with 暂停 or 继续 and a 已暂停 mark under its title. The list uses the same `isRoutine` the day rule uses, so it can't drift into a second idea of what a Routine is. There is no delete, and `ActionLibrary.delete` refuses a Routine anyway, tested since ticket 07.
- 54 tests pass. Two were real red-green cycles: pausing (the Routine stops appearing from that day, earlier days untouched) and resuming (it comes back from that day, the stopped stretch stays empty), the second covering two separate pauses in one Routine. Two more were guards: a One-time Action can't be paused (that guard went in with `pause`, so the test came after it), and **days inside a pause are never Missed, which needed no new code at all** — `isMissed` asks `appears`, and `appears` now leaves a paused day empty, so the rule arrives for free. That closes the note left in `isMissed` in ticket 08 without writing the pause rule a second time.
- New screen text: 重复计划, 暂停, 继续, 已暂停, 还没有重复计划 — all with English.

### What the review found

- **Ticked days were showing the Action as it is now, not as it was ticked.** This is the one that matters, and it means a box in ticket 09 was ticked wrongly: that ticket asks for "a day ticked before the edit still shows the old title", and the screen never did. `Completion.titleWhenTicked` and its Category copy were being written and read by nothing. So ticking 学20个新词 every day for a month and then renaming the Routine rewrote every finished day on screen to 学30个新词 in the new Category's colour, while the stored Completions were correct all along. The row now shows the title and Category its Completion copied whenever a day is ticked, which is what ADR 0002 was for. Ticket 09's box is only honestly ticked as of this change.
- **`updateRoutine` had no kind guard**, so editing could silently turn a One-time Action into a Routine and thereby make it undeletable, while `updateOneTime`'s own comment claimed an Action keeps its kind. Only the form hiding the 类型 picker was enforcing it. Both update methods now refuse the wrong kind (`notARoutine`, `notAOneTimeAction`), with the test written first — and that test confirmed the bug was real, not theoretical: `isRoutine` came back true on a One-time Action.
- Pause and resume errors were being written into the same message the 分类 section shows, which put a failed 暂停 far above the row the student tapped, and wiped any Category error on the way. Routine errors now have their own place under the Routines.
- The archived-Category exemption compared objects by reference. It now compares `persistentModelID`, which is what the rest of the code uses, so the exemption can't quietly stop working if the Picker ever hands back a separately loaded Category.
- Xcode rewrote `Localizable.xcstrings` during a build and pulled in `+5`, `−5` and `完` as strings needing translation. They are symbols, identical in both languages, so they are now `Text(verbatim:)` and the three entries are gone rather than carrying an English "translation" of a plus sign.

### Left alone on purpose

- The Daily Checklist reads every Action and scans each one's Completions three times over (`appears`, then `isLate` and `isMissed`, which each ask `appears` again). At a year of daily Routines that is a few hundred comparisons per redraw, which is fine on a phone. If it ever feels slow, the fix is to hand the day's Completions — already fetched for the checklist — into the rule, **not** to put a day filter back on the query. That filter is what caused two bugs in ticket 09.

### For the iPhone check

- 暂停 a daily Routine in 设置: it should show 已暂停 and disappear from 今天. 继续 should bring it back on today.
- Long-press a Routine's row on the checklist: there should be no 删除, ever.
- A day you ticked before renaming an Action should still show the old title. This is the one the review caught, so it is worth checking on the phone rather than trusting the test.
