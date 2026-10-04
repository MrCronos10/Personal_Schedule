# 21: Vocabulary restyle — three Shelves

**What to build:** The 词 tab as three **Shelves**, scrolling vertically:
**难词** on top (dense do-today list with a red seal marker), **HSK
Levels** middle (two large tappable cards, each a 20-cell sliver of its
Collection Grid section plus the SF Mono count), **农业词** bottom (one
card, same treatment). Different jobs, different visual weight on one
screen.

Vocabulary: **Shelf** in [CONTEXT.md](../../../CONTEXT.md).

**Blocked by:** [15](01-palette-and-typography-primitives.md),
[17](03-tianzige-watermark-background.md),
[18](04-collection-grid.md),
[19](05-four-tab-nav.md).

**Status:** ready-for-human (taps: 全部, a 难词 row, each HSK card into Progress, the 农业词 card)

## The rule

- [x] The screen scrolls vertically through three shelves in this order:
      难词, HSK Levels, 农业词
- [x] The 难词 shelf shows **Stubborn Words** (ticket 10) as a dense list
      with their Articles. A red seal marker sits above the shelf header.
      A row opens the Word sheet, where 认识 / 其实不认识 live. (No pull-to-review: the only
      existing 认识 / 不认识 pass is 今日新词, which sits under the HSK cards; a pull gesture to reach it
      would be a gimmick, and ADR 0004 wants no review queue.)
- [x] The HSK Levels shelf shows two cards (HSK 4 and HSK 5), each with a
      20-cell sliver of that Level's section from the Collection Grid,
      an SF Mono "128 / 600" count, and a tap that opens Progress scrolled
      to that section
- [x] The 农业词 shelf is one card with the same sliver and an SF Mono count, out of 125 + Custom
      Topic Words (ADR 0007). It opens the Topic List itself, not Progress: that screen is where words
      are marked and added, so it must stay reachable
- [x] `BackgroundView` fills the screen
- [x] `AppRouterTests` pin "open Progress at a section". The cards' slivers are the first 20 cells of `CollectionLibrary.cells(for:)`, the same call Progress makes, so there is no second copy of the rule. The shelf order is a layout, checked by looking

## What is not in this ticket

- Any change to how 难词 is computed (ticket 10 stands) or how Topic
  Words are added or archived (ticket 11, ADR 0007 stand).
- A fourth shelf. Three is the design.

## Comments

- Red first (no `AppRouter`), then green; full suite passes. The screen was rendered to PNG and looked at.
- New `AppRouter` (selected tab + the Collection Grid section to open) is shared with ticket 22's sliver. The Progress tab expands that section and scrolls to it.
- `StubbornWordRow` and `CollectionSliver` are shared views, so the shelf and the full 难词 screen cannot drift apart.
- Not seen running: tapping into Progress from a card and landing on the section.
