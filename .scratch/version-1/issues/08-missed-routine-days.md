# 08: Missed Routine days and fixing past days

**What to build:** When the student goes back to a past day, any Routine that should have appeared that day but has no Completion shows as Missed, in a different color. Missed days stay on their own day and never move forward. The student can still tick a Routine on any past day; once ticked there, that day is no longer Missed.

**Blocked by:** 07 (Routines appear on their repeat days)

**Status:** ready-for-agent

- [ ] On a past day, an unticked Routine shows as Missed
- [ ] On today, an unticked Routine is not Missed
- [ ] A Missed Routine does not appear on later days because it was missed
- [ ] Ticking a Routine on a past day creates a Completion for that day and removes Missed
- [ ] Tests cover: Missed on a past day, not Missed today, ticking a past day removes Missed
- [ ] All new screen text exists in 中文 and English
- [ ] Verified on the iPhone: with a daily Routine started before yesterday and not ticked yesterday, press ◀, it shows Missed; tick it, Missed is gone
