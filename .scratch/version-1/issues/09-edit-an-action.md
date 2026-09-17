# 09: Edit an Action

**What to build:** The student can open an existing Action (One-time or Routine) and change its title, Category, time, Default Minutes, date, or repeat days. Days already ticked keep the title and Category copied into their Completion, so past progress does not change (ADR 0002). Days not ticked show the new values.

Known limitation, accepted: changing a Routine's repeat days also changes which past unticked days show as Missed.

**Blocked by:** 07 (Routines appear on their repeat days)

**Status:** ready-for-human (the tap-through checks on the iPhone are left)

- [x] Tapping an Action (not its circle) opens it in the Action form for editing
- [x] Title, Category, time, Default Minutes, date (One-time) and repeat days (Routine) can be changed and saved
- [x] Only active Categories can be chosen when editing
- [x] A day ticked before the edit still shows the old title and still counts toward the old Category
- [x] Days not ticked, and future days, show the new values
- [x] Tests cover: renaming an Action keeps ticked days' copy; changing Category keeps ticked days in the old Category
- [x] All new screen text exists in 中文 and English
- [ ] Verified on the iPhone: tick "学20个新词" today, rename it to "学30个新词", today still shows 20, tomorrow shows 30

## Comments

- `ActionLibrary` gained `updateOneTime` and `updateRoutine`, mirroring the two `add` methods. The title, Category and minutes checks the four of them share are now in one place, so an edit can't validate differently from an add.
- An Action keeps its kind. The 类型 choice is hidden when editing, because letting a ticked Routine become a One-time Action raises questions this ticket doesn't answer (what happens to its other ticked days). Changing kind isn't in the ticket either.
- The form is the same screen: `ActionFormView(editing:)` fills itself in from the Action and saves through the update methods. Tapping a row's title opens it; the tick box keeps its own tap. The Tick sheet and the form are one `sheet` holding two cases, rather than two `sheet` modifiers on the same view, which is a known way to get neither.
- 48 tests pass. Two were real red-green cycles: changing a Routine (a ticked day keeps the title and Category it copied, while unticked and future days show the new values) and changing a One-time Action (it moves to the day it now says, and off the old one). Four more were written as guards, and one of them wasn't a guard at all — see below.
- New screen text: 改计划 and 修改, both with English.

### The two bugs this ticket found

- **A ticked Action dropped off the day it was ticked.** The guard test for it failed instead of passing. The Actions fetched for a day were those with `plannedDayNumber <= max(day, today)`, so moving a ticked Action's date forward pushed it out of the query for the day it was ticked: the row vanished from a finished day while its Completion stayed in the database. A review in ticket 08 had spotted that bound and judged it unreachable from the screens; editing an Action is what made it reachable. The fetch now has no day filter at all. The day rule puts Actions on days their stored numbers never mention, so any filter on the query is a second rule that has to agree with the first, and it didn't. One rule decides now, and the fetch is no larger than before, since the old bound already pulled in every past day.
- **Editing a Routine hid days that were already ticked.** Found by `/code-review`, and the comment above made it worse: dropping the query filter protected One-time Actions only, because the day rule answered for Routines before it ever looked at Completions. Ticking Monday and Tuesday on a 每天 Routine and then editing it to Wednesday-only left Monday and Tuesday empty with their Completions still stored, invisible and impossible to untick. A day that was ticked now shows what was ticked on it whatever the Action says now, for every kind. The first edit test only changed the title, Category and time, never the days, which is why it passed over this.

### Also changed

- An Action in an archived Category could not be changed at all. Archiving 篮球社 and then trying to move "打篮球" to a new time gave 请选择分类, because only active Categories were offered and an archived one was refused. Nothing is deleted in this app, so an Action outliving its Category's active life is normal. Keeping the Category an Action already has is now allowed, and the form offers it; moving an Action into any other archived Category is still refused, with a test for both halves.
- The sheet's identity was built from a hash of the Action's id. It now uses the id itself, so two Actions can't be mistaken for one sheet.

### Left alone on purpose

- The fetch now reads every Action on every day shown, and the day rule touches each one's Completions. That is fine at one student's scale and it is the price of having a single rule. If it ever matters, a filter that is a strict superset of the rule (planned day, or a start day, or any Completion at all) would keep one rule and fetch less.
- Moving a Routine's 开始日期 backwards gives days that show the Routine but never say 错过, because Missed still counts only from the day the Routine was created. That follows the decision taken in ticket 08: moving the start date doesn't change when the Routine existed.

### For the iPhone check

- The 删除 long-press menu sits on the whole row while the title is now a button. Please check that long-pressing the title still brings up 删除, not only the time column or the space around it.
- Tapping a title should open 改计划 filled in, and the 类型 choice should not be there.
