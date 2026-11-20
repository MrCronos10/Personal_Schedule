# Action reminders

An **Action** with a time can remind the student at that time, through a local notification. [ADR 0004](../../docs/adr/0004-known-is-earned-by-reading-not-by-review.md) already says "a reminder to read belongs on the **Daily Checklist** as an ordinary **Routine** the student wrote themselves"; this makes that reminder real.

## Decisions (grilled 2026-11-20)

1. **Any Action with a time** can have a reminder: a **Routine** or a **One-time Action**. An Action with no time has no switch.
2. **One switch per Action, off by default**, for existing Actions and new ones alike. Updating the app changes nothing until the student turns one on.
3. **A reminder fires at the Action's own time, on the days the Action appears in the day plan, and only those.** No reminder on a paused day, none before a Routine's start day, and a late One-time Action that has moved to today reminds again each day it is still there. The day rule decides; reminders never keep a second copy of it.
4. **Ticking cancels that day's reminder; unticking before the time brings it back.** So reminders are scheduled one per day, never as a repeating iOS trigger.
5. **The next 7 days are scheduled**, refreshed whenever the app opens or an Action or Completion changes. iOS holds at most 64 pending notifications per app; if the 7 days would hold more, the nearest ones win. A week without opening the app means reminders stop until it is opened.
6. **Permission is asked the first time a switch is turned on**, never at launch. If it is refused, or later turned off in Settings, the switch shows 通知已关闭 with a button to open Settings.
7. **The notification is the student's own title, verbatim**, with the time as its subtitle. Never translated, no app wording. Tapping it opens 今天.

## Deferred

- **A 完成 button on the notification.** It needs the database reachable from the background and a second path that saves a **Completion**, which must use the same rule as the checklist. Worth a ticket of its own later.
- **A lead time** ("15 minutes before"). Not asked for; the switch's field can gain one later.
- **Background refresh** to top up reminders without opening the app. iOS decides when, if ever, so it is not a rule anything can rely on.

## Tickets

- `01` the reminder rule and scheduling, with the switch
- `02` permission refused, and 通知已关闭
