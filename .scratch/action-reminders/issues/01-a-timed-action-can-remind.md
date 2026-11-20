# 01: A timed Action can remind

**What to build:** A reminder switch on any **Action** with a time. When it is on, a local notification arrives at that time on each day the Action is on the **Daily Checklist** and not yet ticked. See `../spec.md` for the decisions.

**Blocked by:** None (can start immediately)

**Status:** ready-for-human (delivery, the prompt and taps need the phone)

## The rule

The rule lives in a library beside `DayPlan`, not in the screen or the scheduler. Given the Actions, their Completions and a day, it answers: which reminders should exist for that day and the six after it, each as (Action, day, time).

- [x] Only Actions with a time and the switch on
- [x] Only on days the Action appears in the day plan, using the same rule `DayPlan` uses, never a second copy: no paused day, nothing before a Routine's start day, a late One-time Action again on each day it has moved to
- [x] Not on a day the Action is already ticked
- [x] Not at a time already passed today
- [x] At most 64, the nearest first

## Scheduling

- [x] A thin scheduler replaces all of the app's pending notifications with what the rule says, so ticking, unticking, editing, pausing or turning the switch off are all just "refresh"
- [x] It refreshes when the app opens and whenever an Action or Completion changes
- [x] The notification's title is the Action's title verbatim, its subtitle the time; tapping it opens 今天
- [x] The first time a switch is turned on, iOS is asked for permission

## Database

- [x] One new field on `Action`, a Bool defaulting to `false`. No unique field, nothing else changes

## Tests

Fixtures are built from explicit days and Actions; assert what each fixture contains before asserting the answer.

- [x] A Routine with the switch on gives one reminder per repeat day in the 7 days
- [x] Switch off, or no time: none
- [x] A paused stretch gives none inside it
- [x] A ticked day gives none; unticking gives it back
- [x] A late One-time Action gives one on each day it has moved to
- [x] Today's reminder whose time has passed is not given
- [x] More than 64 keeps the nearest 64

## Screen text

- [x] The switch label gets its English in `Localizable.xcstrings`

## Left for the iPhone

- [ ] Turn a switch on, see the permission prompt, and get a reminder at the time
- [ ] Tick the Action before its time and get no reminder
- [ ] Tap a reminder and land on 今天
- [ ] Pause a Routine and get none the next day

## Comments

Built test-first in `ReminderPlanTests`. Whole suite green at **429 tests**, up from 417.

- **Red → green:** one reminder per repeat day; a ticked day gets none and unticking brings it back; a late One-time Action reminds on each day it carries over to; a One-time Action ahead reminds from its planned day; today's passed time is skipped; more than 64 keeps the nearest; the switch can't be on without a time, and removing the time turns it off.
- **Passed on first run, kept as guards:** the switch starts off; switched off or untimed gives none; a paused stretch gives none; nothing before a Routine's start day.
- **The day rule:** `ReminderPlan` asks `DayPlan.appears(action, on: day, today: day)` — each day *as of that day* — so a late One-time Action is on each coming day, as decision 3 says, without a second copy of the rule. `DayPlan.isTicked` went from private to internal so the tick check is reused, not copied.
- **One consequence to know:** a One-time Action planned for Wednesday also reminds Thursday to Sunday, because unticked it *will* carry over to those days. Ticking it takes them all away.

`/code-review`, two axes:

- **Spec:** nothing missing. Fixed: no test covered the start day (added). Noted, kept: the banner shows while the app is open, and the reminder has the default sound — neither was decided in the grilling.
- **Standards:** fixed —
  - the tap delegate is set in `ContentView.init`, not `.task`, and a tap that arrives before 今天 is ready is kept and run once it is (cold launch);
  - refreshes coalesce, so a burst of saves runs at most one more, and saves are received on the main thread;
  - "no time, no reminder" moved from the form into `ActionLibrary`, and the form saves once instead of twice;
  - only the app's own `reminder-` notifications are cleared;
  - the trigger has no time zone pinned, and the subtitle uses the phone's own clock style;
  - today and the minute are read from one calendar; ties at the 64 limit break by when the Action was added;
  - `ReminderPlan.days` renamed `daysAhead`; **Reminder** added to CONTEXT.md, kept apart from **Evening Check**.
  - Kept: a refresh on every save, not only Action/Completion saves — coalescing makes it cheap, and filtering by model would be a second list of what matters.

The delegate would be earliest in `PersonalScheduleApp.init`; that file still has the stray `///`, so it was left alone.

Not seen running: a reminder arriving, the permission prompt, a tap, and a cold launch from a tap.

## Left for the iPhone (from review)

- [ ] With the app closed completely, tap a reminder and land on 今天
- [ ] Open a sheet, get a reminder, tap it, and see whether the sheet staying on top is acceptable
- [ ] Decide whether a reminder while the app is open should show a banner and sound
