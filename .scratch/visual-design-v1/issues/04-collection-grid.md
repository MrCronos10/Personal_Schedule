# 18: Collection Grid — the Progress screen

**What to build:** The new **Progress** screen's main surface: every
**Word** on the HSK **Word Lists** and every **Topic Word** on the **Topic
List** as a 田字格 cell, in one of three **Cell States** — not met, seen,
Known. Three sections pinned by ADR 0005 and ADR 0007: HSK 4 out of 600,
HSK 5 out of 1,300, 农业词 out of 125 (plus Custom Topic Words). The
existing Progress Tracker (Weekly Targets) moves below it, less visually
loud.

Why this is the achievement surface, and why there are no streaks or badges:
[ADR 0004](../../../docs/adr/0004-known-is-earned-by-reading-not-by-review.md),
[ADR 0009](../../../docs/adr/0009-visual-design-is-practice-book-hybrid.md).
Vocabulary: **Collection Grid** and **Cell State** in [CONTEXT.md](../../../CONTEXT.md).

**Blocked by:** [15](01-palette-and-typography-primitives.md),
[17](03-tianzige-watermark-background.md).

**Status:** ready-for-human (taps: expand/collapse a section, tap a cell, watch a cell ink in)

## The rule

- [x] A `CellState` enum has exactly three cases: `.notMet`,
      `.seen`, `.known` — any attempt to add a fourth is rejected in
      review
- [x] The rule lives at `CollectionLibrary.cells(for:)` / `topicCells()`, not in
      the view: `.known` when the Word is **Known**, `.seen` when it has
      a `WordLookup` or a `CleanSighting` and is not Known, `.notMet` otherwise.
      Topic Words map `.known` from **Topic Known** and `.notMet`
      otherwise (no `.seen` for them — the Topic List is hand-marked only
      per ADR 0007)
- [x] The grid lays ~10 cells per row on iPhone, cell size scales with
      screen width. SF Mono headers above each section carry the count
      ("HSK 4 — 128 / 600") in matched monospaced digits
- [x] Tapping a cell opens a bottom sheet with the Word, its pinyin and
      English, its Clean Sightings (and which Articles earned them), and
      a 其实不认识 button for Topic Words
- [x] When a Word transitions to `.known`, the cell inks itself with a
      300ms brush-stroke animation. If the student is not on Progress
      when it happens, the next visit shows a 1s grid-red glow around the
      freshly-inked cells
- [x] `BackgroundView` (ticket 17) fills the Progress screen
- [x] The existing Progress Tracker (Weekly Targets per Category) moves
      below the Collection Grid on the same screen as a scrollable row
      of cream cards; it is not removed
- [x] `CollectionLibraryTests` cover the three Cell States, the 600 / 1,300 / 125 totals, and that a Lookup leaves a Known cell Known (only 其实不认识 takes it back)

## What is not in this ticket

- The Collection Sliver on Today (ticket 22). The sliver reads from the
  same `CollectionLibrary`, so the library is shared from here.
- The small celebrations beyond the cell-ink animation. The seal moment
  on reading, the Today stamp and the routines fold live in ticket 25.
- A re-ordering of cells by frequency or recency. Cells are in Word-List
  order so a Word stays in the same spot.

## Comments

- Red first (no `CollectionLibrary`), then green; full suite passes. The grid was also rendered to a PNG in light and dark through a hosting window and looked at: cells, fonts and the three states read correctly.
- Sections HSK 4 / HSK 5 / 农业词 are collapsible (the served Level starts open), because 1,900 open cells would push the weekly ledger several screens down.
- The cell sheet reuses `WordLookupSheet` for HSK words (now also listing the Articles that earned the Word a Clean Sighting) and a small Topic sheet with 认识 / 其实不认识.
- Not seen running: the 300ms ink-in and the 1s glow on the next visit (animation, phone only).
