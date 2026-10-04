# 19: Four-tab navigation

**What to build:** Restructure the TabView down to four tabs — 今天, 阅读,
词, 进度 — with grid-red selected tint and faded-ink inactive. Settings
leaves the tab bar and becomes a gear in Today's top-right. Notes stops
being a destination and opens as a sheet from Today. Coach stays inside
Reading (ADR 0008).

Why four and not five or seven: [ADR 0009](../../../docs/adr/0009-visual-design-is-practice-book-hybrid.md).

**Blocked by:** [15](01-palette-and-typography-primitives.md).

**Status:** ready-for-human (taps: each tab, the Today notes/gear buttons, 完成 on both sheets)

## The rule

- [x] `ContentView` carries exactly four `TabView` tabs, in this order:
      今天 (`calendar`), 阅读 (`book`), 词 (`character.book.closed`),
      进度 (`square.grid.3x3`)
- [x] Selected tab icon tint is `Theme.gridRed`; inactive is
      `Theme.fadedInk`
- [x] Settings is reached only from Today's top-right gear button, which
      presents it as a sheet
- [x] The Notes tab is removed; Notes open as a sheet from Today (the
      ticket 22 restyle finishes the Notes layout, but the entry point
      moves here)
- [x] No reference to Coach as a top-level destination exists anywhere
      in `ContentView` or the tab bar
- [x] `AppTabTests` pins the four tabs and symbols; the review note below confirms the Timetable, Daily Checklist,
      Settings and Notes are all still reachable (no screen is orphaned
      by the restructure)

## What is not in this ticket

- The Today layout changes (Collection Sliver, notebook-rule rows) —
  that's ticket 22.
- The Notes index-card restyle — ticket 23.
- The Settings sectioned list — ticket 24.

## Comments

- Red first (no `AppTab`), then green; full suite passes. Screens were rendered to PNG through a hosting window (Today, 词, Settings and Notes as sheets) and looked at.
- The 词 tab did not exist, so this ticket also moved the Level meter, 今日新词, 难词 and 农业词 out of 阅读 into a new `VocabularyView` (a move, no logic change). Ticket 21 restyles it into Shelves. ADR 0007 and CONTEXT.md now say 农业词 is reached from 词.
- A Today opened as a sheet (from a Missed ledger day or a Note) has the notes/gear buttons off, so it cannot open a Notes list from inside Notes.
- Reachable: Timetable/Daily Checklist (Today tab), Settings (gear), Notes (button), Coach (inside an Article, unchanged).
