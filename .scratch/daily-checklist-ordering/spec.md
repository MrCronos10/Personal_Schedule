# Daily Checklist Ordering

Words in **bold** are defined in [CONTEXT.md](../../CONTEXT.md).

## What this is for

The student asked for ideas on what would make Personal Schedule more inviting to open every day. One idea that survived grilling: the **Daily Checklist** should show what's left to do before what's already done, so a glance at 今天 reads as "here's what's outstanding" rather than a flat chronological list. Everything else from the original "morning glance" idea (a separate view, a time-of-day cutoff, a new domain noun) was dropped during grilling — it collapsed into a small, low-risk ordering change with no new screen and no new concept.

## The change

`DayPlan.ordered(_:)` (`PersonalSchedule/Model/DayPlan.swift:73`) moves from a flat sort to a two-tier sort:

1. Actions with no **Completion** on the day being shown, first.
2. Actions with a Completion on that day, after.

Within each tier, the existing rule is unchanged: timed Actions first (earliest first), then untimed Actions in the order they were added.

Ticked Actions are never hidden — they still appear, just at the bottom, so the student still sees today's progress.

This applies wherever `DayPlan.ordered`/`DayPlan.plan` is already called:

- `PersonalSchedule/Today/DayChecklist.swift:44` — the 今天 tab's checklist.
- `PersonalSchedule/Reading/ArticleReaderView.swift:187` — the Action picker offered when finishing a Reading Session.

No other screen calls `DayPlan.ordered`/`.plan` today.

## What "ticked" means

An Action is ticked, for ordering purposes, when a **Completion** exists for it on the day being shown — the same lookup `DayChecklist.completionsByAction()` already does. `DayPlan.ordered(_:)` doesn't currently see Completions, so its signature needs to grow to take that information in; the exact shape (a `Set` of ticked identifiers, a lookup closure, or completions passed alongside candidates) is an implementation decision for the ticket, not a domain one — nothing about the Daily Checklist definition depends on it.

## Doc update

`CONTEXT.md`'s **Daily Checklist** entry already carries the one-sentence behavior note (added during grilling): "Outstanding Actions show before ticked ones, so ticking one off moves it out of the way rather than off the screen."

## Tickets

| # | Ticket | Blocked by |
| --- | --- | --- |
| 23 | [Outstanding Actions sort before ticked ones](issues/23-outstanding-actions-first.md) | — |

## Not in this feature

- A separate "morning" screen, notification, or time-of-day cutoff — dropped during grilling; this is a permanent ordering rule, not a time-gated one.
- Timetable/Class UI and a Daily New Words screen — neither exists yet in the app; they're their own future tickets, not prerequisites for this one.
- An ADR — this isn't hard to reverse, isn't surprising, and wasn't a real trade-off between alternatives.
