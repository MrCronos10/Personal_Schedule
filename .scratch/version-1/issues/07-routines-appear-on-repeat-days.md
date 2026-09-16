# 07: Routines appear on their repeat days

**What to build:** In the Action form the student can choose Routine instead of One-time. A Routine has repeat days (every day, weekdays, or chosen weekdays) and a start date, plus the usual title, Category, optional time and optional Default Minutes. The Routine appears on the Daily Checklist on every matching day from its start date, and each day is ticked separately with its own Completion.

**Blocked by:** 05 (Tick and untick an Action)

**Status:** ready-for-human (the tap-through checks on the iPhone are left)

- [x] The Action form offers One-time or Routine
- [x] A Routine can repeat every day, on weekdays, or on chosen weekdays, from a start date
- [x] A Routine appears on every day that matches its repeat days, on or after its start date, and on no other day
- [x] Ticking a Routine on one day does not tick it on any other day
- [x] Tests cover: every day, weekdays, chosen days, before the start date, and ticking one day only
- [x] All new screen text exists in 中文 and English
- [ ] Verified on the iPhone: create "学20个新词, 7:00, 20分钟, 中文, 每天", tick it today, press ▶, tomorrow it is not ticked

## Comments

- An Action is now either a One-time Action, which keeps its planned day, or a Routine, which has `repeatWeekdayMask` and `startDayNumber`. Both new fields are optional, so the database follows the iCloud rules and the store the app already had opened without a migration step. `startDayNumber` is kept separate from `plannedDayNumber` on purpose: CONTEXT.md treats a planned date and a start date as different things, and tickets 09 and 10 both touch that difference.
- `Weekday` and `RepeatDays` live in `Day.swift` beside `Day` and `TimeOfDay`, because they are the same kind of calendar value. `RepeatDays` is stored as one Int with a bit per weekday, so no new record was needed. 每天 and 工作日 are named values on it, and anything else is the set the student picked.
- The day rule gained one branch: a Routine is on every one of its repeat days from its start day onwards. A ticked Routine still appears on its other days, because each day is ticked separately with its own Completion. `DayPlan.isLate` now returns false for a Routine — a repeat day it missed is Missed on that day, which is ticket 08.
- 35 tests pass. Three were real red-green cycles: `RepeatDays` matching (每天 / 工作日 / chosen), a Routine appearing every day from its start day and not before, and the Routine delete rule below. Three passed the moment they were written and are kept as guards, not claimed as cycles: 工作日 and chosen days on a real Routine (the same branch the second cycle proved), ticking one day leaving the others unticked (`CompletionLibrary` was already keyed by day), and a Routine with no repeat days being refused (that guard was written alongside `addRoutine`, so its test came second).
- The form now has a 类型 choice (一次 / 重复). Choosing 重复 shows 每天 / 工作日 / 选择日子, and 选择日子 shows seven squares in the week order of the student's language. The date row becomes 开始日期 for a Routine. On the checklist a Routine's row says 每天, 工作日 or 重复 where a One-time Action says 一次.
- New screen text: 类型, 重复, 每天, 工作日, 开始日期, 选择日子, 请选择重复的日子 — all with English.
- `/code-review` raised 4 findings. Three were real and are fixed. The important one was mine: the 删除 long-press menu from ticket 06 was offered on Routine rows, and `ActionLibrary.delete` only checked for Completions, so confirming it would have destroyed a Routine and every future day it would have appeared on. CONTEXT.md says Routines are paused, never deleted. The library now refuses it (`ActionError.routineCantBeDeleted`, tested first) and the row no longer offers the menu, so the rule holds even if a screen forgets it. The third fix was the weekday squares ignoring where the week starts, which showed 日一二三四五六 in 中文 instead of 一二三四五六日.
- Left alone on purpose: `try?` still swallows a refused 删除. With the menu now withheld from Routines and from ticked rows, and a ticked One-time Action only ever appearing on its tick day, the guard can't be reached from the screen; it is there so the rule can't be broken by a future screen, not as something the student can hit.
- Not seen running: the 类型 and 重复 pickers, the weekday squares, and the Routine row labels. The simulator can be launched from here but not tapped. The app does open with the two new fields in place, which is the database migration working on a store made before they existed.

### For the student to decide

This Mac runs in Thailand's region (`en_TH`), so `Calendar.current` is the Thai Buddhist calendar. That means `Day.today()` returns 2569-09-16 rather than 2026-09-16, and a day written as 2026-09-14 in a test is really 1483 in the Gregorian calendar, which is a Sunday and not a Monday. That is what made the first weekday test fail, shifted by one day.

The app itself is consistent, because day numbers and weekday reading both go through the same calendar, so Routines will land on the right days on the iPhone. The weekday tests now name the Gregorian calendar so they mean what they say on any Mac.

The risk is the stored numbers: your history is written in Buddhist years. If the iPhone's region ever changes to a Gregorian one, every stored day would be read 543 years out and the history would look empty. Fixing that means storing days in one calendar regardless of region, which changes data already on the phone, so it needs your decision and probably an ADR. Nothing was changed here.
