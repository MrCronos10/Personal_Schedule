# The visual design is a practice-book hybrid

The app has grown to seven surfaces — Today, Reading, Vocabulary, Progress,
Notes, Coach, Settings — and three distinct kinds of content (daily plan,
Chinese reading, word lists). It needs one visual direction so the student
isn't reading seven apps.

The direction is **hybrid**: modern iOS chrome (tab bar, lists, sheets, SF
Symbols, iOS-native type scale) with **practice-book moments** inside
content — 田字格 grid lines on Reading and Vocabulary, 宋体 headlines, red
seals on completion, cream paper backgrounds, bamboo green for success.

[docs/design-v1.md](../design-v1.md) is the brief; this ADR records the
pieces that are expensive to change later.

## The three decisions this ADR pins

1. **Hybrid over pure practice-book, and over generic modern.** The pure
   practice-book look reads as "worksheet / toy" at a glance to anyone who
   isn't already inside the app's world. Pure modern loses what makes the
   app recognizable at all. Hybrid chrome keeps the app feeling professional
   on first open; practice-book moments inside keep the identity visible
   where the student lives (reading and vocabulary).

2. **Four-tab navigation.** 今天 · 阅读 · 词 · 进度. Settings is a gear in
   Today's top-right corner. Coach lives inside Reading (ADR 0008). Notes
   open as a sheet from Today. Seven top-level destinations is more than any
   iOS tab bar should carry, and a "More" catch-all tab reads as filler.

3. **The collection grid is the achievement surface.** Progress shows every
   Word in the HSK and Topic Lists as a 田字格 cell, in three states (empty,
   seen, Known). There are no streaks, no badges, no ranks. The grid grows
   because the student read, which is the only thing the app ever says they
   should do (ADR 0004).

## Why not the alternatives

- **Deepen the practice-book look everywhere** (red grid chrome, paper
  textures on nav bars). Rejected: nav chrome made to look like paper reads
  as toy UI the moment the student opens the Timetable at a bus stop. The
  identity needs *restraint*, not saturation.
- **Replace the practice-book look with pure modern minimal.** Rejected:
  the 田字格 is already the project's visual signature in `Theme.swift` and
  the current reader; throwing it away loses the one thing that makes the
  app not look like every other HSK app.
- **Streaks, badges, or 秀才 → 举人 ranks for "fun."** Rejected on ADR 0004
  grounds: streaks punish a sick day, badges mark the student as behind on a
  metric they didn't ask for, ranks turn reading into a competition with
  oneself. The collection grid shows growth without any of those.
- **Five tabs with a "More" catch-all.** Rejected: Settings is rarely
  touched (iOS convention: gear icon), Notes is a support surface not a
  destination, Coach is bound to an Article by ADR 0008. Promoting any of
  them to a peer tab contradicts how they are used.

## Consequences

- `Theme.swift` grows a full color token set (paper cream, ink black, grid
  red, seal red, bamboo green, faded ink; plus their dark-mode pairs). The
  existing one-off colors in views are swapped for tokens, one ticket.
- Source Han Serif is bundled under `PersonalSchedule/Fonts/`. The project
  gains two font files (Regular, SemiBold) and the licence note that lives
  on the Settings 关于 screen.
- The app icon is replaced with the **读 in 田字格** mark.
- The TabView loses one tab (Settings) and gains one (Progress as a peer,
  if it wasn't already). Coach stops being referenced as a top-level
  destination anywhere in the design.
- The collection grid becomes a new Progress screen. The existing Progress
  Tracker (Weekly Targets per Category) moves below it on the same screen,
  with less visual weight; it is not removed.
- A new "seen" state is introduced for Words — faded ink in the grid, faded
  ink underline on looked-up Words in the reader. The underlying model
  already distinguishes looked-up-but-not-Known from Known (ADR 0004,
  Stubborn Word); the design surfaces it.
- Dark mode is designed, not deferred. Colors swap, layouts hold.
- No sound. The app is silent.

## What this ADR does not change

- The HSK totals (ADR 0005), what counts as Known (ADR 0004), the Set Aside
  window (ADR 0006), the Topic List's place beside the HSK Levels (ADR 0007),
  and the Reading Coach's house rules (ADR 0008) all stand. The design wraps
  these; it never bends them.
- No Article is ever locked or hidden for difficulty. Readability stays
  information, never a gate (ADR 0005).
- The Coach stays inside an Article; the design does not promote him to a
  tab or a floating button (ADR 0008).
