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

**Status:** ready-for-agent

## The rule

- [ ] The screen scrolls vertically through three shelves in this order:
      难词, HSK Levels, 农业词
- [ ] The 难词 shelf shows **Stubborn Words** (ticket 10) as a dense list
      with their Articles. A red seal marker sits above the shelf header.
      Pull-to-review opens the existing 认识 / 不认识 pass
- [ ] The HSK Levels shelf shows two cards (HSK 4 and HSK 5), each with a
      20-cell sliver of that Level's section from the Collection Grid,
      an SF Mono "128 / 600" count, and a tap that opens Progress scrolled
      to that section
- [ ] The 农业词 shelf is one card, same treatment as a Level card, out
      of 125 + Custom Topic Words (ADR 0007)
- [ ] `BackgroundView` fills the screen
- [ ] A test confirms the three shelves are rendered in order and that
      the HSK card's slice reads from the same `CollectionLibrary` as
      Progress (not a second copy of the rule)

## What is not in this ticket

- Any change to how 难词 is computed (ticket 10 stands) or how Topic
  Words are added or archived (ticket 11, ADR 0007 stand).
- A fourth shelf. Three is the design.

## Comments
