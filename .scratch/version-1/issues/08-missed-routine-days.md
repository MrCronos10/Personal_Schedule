# 08: Missed Routine days and fixing past days

**What to build:** When the student goes back to a past day, any Routine that should have appeared that day but has no Completion shows as Missed, in a different color. Missed days stay on their own day and never move forward. The student can still tick a Routine on any past day; once ticked there, that day is no longer Missed.

**Blocked by:** 07 (Routines appear on their repeat days)

**Status:** ready-for-human (the tap-through checks on the iPhone are left)

- [x] On a past day, an unticked Routine shows as Missed
- [x] On today, an unticked Routine is not Missed
- [x] A Missed Routine does not appear on later days because it was missed
- [x] Ticking a Routine on a past day creates a Completion for that day and removes Missed
- [x] Tests cover: Missed on a past day, not Missed today, ticking a past day removes Missed
- [x] All new screen text exists in 中文 and English
- [ ] Verified on the iPhone: with a daily Routine started before yesterday and not ticked yesterday, press ◀, it shows Missed; tick it, Missed is gone

## Comments

- `DayPlan.isMissed` is the whole rule: a Routine, on a day before today, on a day it actually appears on, with no Completion for that day. Today is never Missed because today isn't over. A day before the start day, or a day that isn't one of the repeat days, was never a day the Routine was on, so it can't be Missed either. A One-time Action is never Missed — it moves to today as 迟到 instead. The rule sits in one function so ticket 10 can add its last part there: days inside a Pause are never Missed.
- Nothing about Missed is stored. It is worked out from the Completions each time, so ticking a past day clears it and unticking a past day brings it back, with no extra bookkeeping. That also means Missed can never "move": it is a fact about one day.
- 39 tests pass. Two were real red-green cycles: the Missed rule itself, and the tightened Routine identity below. Two passed the moment they were written and are kept as guards: ticking a past day clearing Missed for that day only (ticking any shown day already worked from ticket 05, and Missed is derived), and a missed day adding nothing to later days.
- On the checklist a Missed row says 错过 and is written in the same ink as 迟到, behind one `isBehind` accessor, because the plan asks for "Missed and late items in a different color" rather than two different colors.
- New screen text: 错过, plus 自选日子 (see below) — both with English.
- `/code-review` ran twice and raised eight findings between them. Four were real and are fixed:
  - The weekday order fix from ticket 07 **did not work**. Assigning a locale to `Calendar.current` never changes its `firstWeekday`, so the 选择日子 squares followed the phone's region instead of the app language, and the doc comment claimed otherwise. The order now comes from the locale's own first day of the week.
  - A Routine was "repeat days" alone, but the day rule needs repeat days *and* a start day, and an empty set of days still counted as a Routine. Such an Action appeared on no day at all and also refused to be deleted, so it could only be removed by deleting the app. Not reachable through the form today, but ticket 09 edits an Action's repeat days, which is exactly where it would have appeared. `isRoutine` now needs both halves and an empty set of days reads as none, tested first.
  - 重复 was doing two jobs: the form's picker label, where it means "Repeat", and a chosen-days Routine's label on the checklist, where it means "Repeating". One English translation had to serve both. The row now says 自选日子 / "Chosen days".
  - A new Routine's 开始日期 defaults to whichever day the student was browsing, so adding a daily Routine while looking back at last Monday reported every day since as 错过 — invented history. This was first patched in the form, by starting a new Routine today. That patch has since been removed: it silently rewrote a date the student had chosen, so tapping 重复 to look at the options and then 一次 again re-planned a One-time Action for today instead of the day being browsed. The Missed rule below is what actually fixes the problem, so the form now leaves the date alone.
  - An Action left with no repeat days fell back to a One-time Action whose planned day was day zero, which would have shown on today in the 迟到 ink with a nonsense date. A Routine now keeps its start day as its planned day too, so the fallback lands on a real day. The test for it checks the row, not just that the Action can be deleted — it passed while the row misbehaved.
- Left alone on purpose: the fetch keeps `|| $0.startDayNumber != nil` even though a Routine's unused `plannedDayNumber` stays 0 and already satisfies the other clause. It reads as dead code, and it is, but it is the clause that says what the fetch means, so the query stops depending on that 0 staying 0.
- Not seen running: the 错过 label and its ink, the reordered weekday squares, and the 自选日子 row label. The simulator can be launched from here but not tapped. No database fields were added in this ticket, so there was no migration to check.
- One for the iPhone check, noticed during review: creating a 工作日 Routine while browsing a Saturday saves and closes the form, and then nothing appears on the day the student was looking at, because Saturday isn't one of its days. That is correct, but it looks like nothing happened.

### Decided and done

**A Routine started on a past day used to report every day since as 错过.** The student chose to fix it, so Missed now ignores days before the Routine was created, using the `createdAt` that was already stored on every Action. The Routine still appears on those earlier days, so a day they really did can be ticked in afterwards; it just isn't counted against them. `CONTEXT.md` carries the new wording, because this changes what the word Missed means. Three tests that relied on "created just now, so every past day counts" now say when the Routine was created.

**The day a Routine is created can itself be Missed**, and that is on purpose. Create a Routine at 07:00, leave it unticked, and once the day is over it shows 错过 — which is the point of the mark. The cost is the other end of the day: a Routine created at 23:50 shows 错过 for that day ten minutes later. Counting from the day after creation would trade a useful mark for a rare annoyance, so the day itself counts. `CONTEXT.md` says "on or after the day the Routine was created" so the choice is written down rather than implied.

### For the student to decide

**The calendar risk from ticket 07 is worse than it first looked.** This Mac (and your phone, in Thailand's region) uses the Thai Buddhist calendar, so days are stored as Buddhist years: today is 25690917. Ticket 07 noted that a change of region would make history look empty. Reviewing this ticket sharpened it: a Routine's `startDayNumber` of 25690917 would be read as the year 2569, which sorts *after* today, so the Routine would silently stop appearing at all, and 工作日 Routines would resolve to unrelated weekdays. Storing days in one calendar regardless of region would fix it, and it touches data already on your phone, so it needs a decision and probably an ADR before there is much history to migrate.
