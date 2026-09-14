# 04: Plan a One-time Action and see it on the Daily Checklist

**What to build:** From the 今天 tab, a + button opens the Action form. The student creates a One-time Action with a title, a Category (active Categories only), a date, an optional time and optional Default Minutes. The 今天 tab becomes the Daily Checklist: it shows the chosen day's date at the top, ◀ ▶ buttons to move between days, a 今天 button to jump back to today, and the day's Actions with title, time and Category.

The rule for "which Actions appear on a day" starts here, as one piece of logic tested on its own, and later tickets extend it.

**Blocked by:** 02 (Chinese / English language switch)

**Status:** ready-for-agent

- [ ] The Action form saves a One-time Action with title, Category, date, optional time and optional Default Minutes
- [ ] Title and Category are required
- [ ] Only active Categories can be chosen; Archived Categories are not offered
- [ ] The Daily Checklist shows the Actions planned for the chosen day
- [ ] Actions with a time come first, earliest first, then Actions without a time
- [ ] ◀ ▶ move one day back or forward; the 今天 button returns to today
- [ ] Tests cover: an Action appears only on its planned date, and the ordering rule
- [ ] All new screen text exists in 中文 and English
- [ ] Verified on the iPhone: create "买SIM卡" for tomorrow, it is not on today, press ▶ and it is there
