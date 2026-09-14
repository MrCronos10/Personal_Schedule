# 06: Late One-time Actions move to today

**What to build:** A One-time Action that was not ticked by the end of its planned date moves forward: it appears only on today, marked as late in a different color, and keeps moving each day until it is ticked or deleted. Once ticked, it stays on the day it was ticked. The student can delete a One-time Action that is not ticked; a ticked one can't be deleted.

**Blocked by:** 05 (Tick and untick an Action)

**Status:** ready-for-agent

- [ ] An unticked One-time Action with a planned date before today appears on today, marked late
- [ ] It does not appear on the past days between its planned date and today
- [ ] A One-time Action planned for a future date still appears only on that date
- [ ] A ticked One-time Action appears on the day it was ticked, as done, and not on later days
- [ ] An unticked One-time Action can be deleted (with confirmation); a ticked one offers no delete
- [ ] Tests cover: late Action moves to today, future Action stays on its date, ticked Action stays on its tick day
- [ ] All new screen text exists in 中文 and English
- [ ] Verified on the iPhone: create a One-time Action for yesterday, it appears today marked late
