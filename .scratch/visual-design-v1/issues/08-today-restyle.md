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

**Status:** ready-for-agent

## The rule

- [ ] The Collection Sliver shows the last ~20 cells the student filled
      across all **Word Lists** and the **Topic List**, newest on the
      right. Tap opens Progress scrolled to the matching section
- [ ] The sliver reads from the same `CollectionLibrary` as the full
      Collection Grid — never a second copy of the rule
- [ ] The Timetable block is below the sliver (unchanged content, just
      the new type and colour tokens from ticket 15)
- [ ] The Daily Checklist is below the Timetable. Outstanding Actions
      show above ticked ones (unchanged), with a one-pixel faded-ink
      horizontal rule between rows — the notebook-page rule
- [ ] A gear button in the top-right opens Settings as a sheet
- [ ] A "Notes" button in the top-right opens Notes as a sheet
- [ ] Background is flat `Theme.paperCream` (no `BackgroundView` — Today
      is a chrome screen per the design brief)
- [ ] A test confirms the Collection Sliver's cells match the newest 20
      transitions in `CollectionLibrary`, in reverse chronological order

## What is not in this ticket

- The Collection Grid itself (ticket 18); the sliver only reuses its
  library.
- The Notes index-card restyle (ticket 23); only the entry point moves
  here.
- Any new "Today" celebration — the seal stamp on daily reading goal is
  ticket 25.

## Comments
