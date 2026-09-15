# 04: Plan a One-time Action and see it on the Daily Checklist

**What to build:** From the 今天 tab, a + button opens the Action form. The student creates a One-time Action with a title, a Category (active Categories only), a date, an optional time and optional Default Minutes. The 今天 tab becomes the Daily Checklist: it shows the chosen day's date at the top, ◀ ▶ buttons to move between days, a 今天 button to jump back to today, and the day's Actions with title, time and Category.

The rule for "which Actions appear on a day" starts here, as one piece of logic tested on its own, and later tickets extend it.

**Blocked by:** 02 (Chinese / English language switch)

**Status:** ready-for-human (the tap-through checks on the iPhone are left)

- [x] The Action form saves a One-time Action with title, Category, date, optional time and optional Default Minutes
- [x] Title and Category are required
- [x] Only active Categories can be chosen; Archived Categories are not offered
- [x] The Daily Checklist shows the Actions planned for the chosen day
- [x] Actions with a time come first, earliest first, then Actions without a time
- [ ] ◀ ▶ move one day back or forward; the 今天 button returns to today
- [x] Tests cover: an Action appears only on its planned date, and the ordering rule
- [x] All new screen text exists in 中文 and English
- [ ] Verified on the iPhone: create "买SIM卡" for tomorrow, it is not on today, press ▶ and it is there

## Comments

- Tests are at the Action library and the day plan rule: a One-time Action appears on its day with its title, Category, time and minutes; a blank title, an Archived Category, or negative Default Minutes is refused and nothing is saved; an Action appears only on its own day; timed Actions come first (earliest first), then untimed ones in the order added.
- A day is stored as a yyyymmdd number and a time as minutes since midnight, so days compare as numbers and don't shift with time zones.
- The Daily Checklist screen uses the same day filter and ordering as the tests (`DayPlan.descriptor(for:)` and `DayPlan.ordered(_:)`).
- "Category is required" is checked by the form (保存 with no Category shows 请选择分类); the library takes a Category, so it can't be missing there. The form only offers active Categories, and the library also refuses Archived ones.
- On other days the 田字格 title shows the weekday (for example 周三); in English it shows the weekday name. The 今天 tab moves to the new day after midnight or when the app comes back, unless the student chose another day on purpose.
- First code review (whole diff) found no clear bugs but four points, all fixed: removed a leftover save wrapper; a Category missing from the list now gets grey instead of the first Category's color; negative Default Minutes are refused (test added first); the checklist follows today past midnight. All 17 tests passed afterwards.
- A second review only read the first 500 lines of the diff and found nothing there; it did not reach the form, the checklist rows or the midnight-follow code.
- Checked in the simulator: the 今天 tab opens with the date, ◀ ▶ and + in the header and the empty checklist. Not seen running: the Action form, a planned Action on the list, and moving between days, since the simulator can't be tapped from the command line.
