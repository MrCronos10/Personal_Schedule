# 22: Today restyle — Collection Sliver and notebook rules

**What to build:** The 今天 tab in three stacks. On top, the **Collection
Sliver** — a thin horizontal strip showing the last ~20 cells the student
filled across HSK 4, HSK 5 and 农业词 together, newest on the right.
Middle, the Timetable. Below, the Daily Checklist with a one-pixel
faded-ink horizontal rule between rows (notebook-page feel). The gear
in the top-right opens Settings; a sheet from here opens Notes.

Vocabulary: **Collection Sliver** in [CONTEXT.md](../../../CONTEXT.md).

**Blocked by:** [15](01-palette-and-typography-primitives.md),
[18](04-collection-grid.md),
[19](05-four-tab-nav.md).

**Status:** ready-for-human (tap the strip: it should open Progress at the newest cell's section)

## The rule

- [x] The Collection Sliver shows the last ~20 cells the student filled
      across all **Word Lists** and the **Topic List**, newest on the
      right. Tap opens Progress scrolled to the matching section
- [x] The sliver reads from the same `CollectionLibrary` as the full
      Collection Grid — never a second copy of the rule
- [x] There is no Timetable in the app yet (no Class model), so there is no block to place; nothing was invented for it
- [x] The Daily Checklist: outstanding Actions above ticked ones (unchanged), and it already drew a one-pixel `Theme.rule` line between rows, which is the notebook-page rule, so it is left alone
- [x] A gear button and a notes button beside the title open Settings and Notes as sheets (done in ticket 19)
- [x] Background is flat `Theme.paperCream` (no `BackgroundView` — Today
      is a chrome screen per the design brief)
- [x] `CollectionLibraryTests` pin `recentlyKnown`: oldest to newest across both HSK Levels and the Topic List, the newest twenty, and a Word taken back leaves it

## What is not in this ticket

- The Collection Grid itself (ticket 18); the sliver only reuses its
  library.
- The Notes index-card restyle (ticket 23); only the entry point moves
  here.
- Any new "Today" celebration — the seal stamp on daily reading goal is
  ticket 25.

## Comments

- Red first (no `recentlyKnown`), then green; full suite passes. Today was rendered to PNG and looked at.
- The strip is hidden until something is Known (nothing is owed), and hidden on a Today opened as a sheet from the ledger or a Note.
- Not seen running: the tap through to Progress.
