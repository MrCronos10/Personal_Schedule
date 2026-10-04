# 23: Notes restyle — index-card stack

**What to build:** The **Notes List** sheet (opened from Today, ticket 22)
as a loose stack of cream index cards. Each **Note** is a card with a thin
grid-red top edge, 宋体 title (the Note's first line), PingFang body. Tap
to expand to full screen; swipe down to collapse. A search bar sits
pinned at the top. Flat paper cream background — no 田字格 watermark; the
cards are the texture.

**Blocked by:** [15](01-palette-and-typography-primitives.md).

**Status:** ready-for-agent

## The rule

- [ ] Notes are read from the existing model (Completion `Note`, ADR
      0002); the content, search, and newest-first order are unchanged
- [ ] Each Note renders as a cream card with a thin grid-red top edge
      (two-pixel bar) and a very thin cream-paper edge shadow (the only
      shadow the whole app allows)
- [ ] Cards are offset ±2° on alternate rows so the stack reads as paper
      pile, not list
- [ ] Note title uses 宋体 SemiBold 17pt (the Note's first line, student's
      own writing — never translated); body uses PingFang 15pt
- [ ] Tap a card to expand to a full-screen view of the Note; swipe down
      collapses back to the stack
- [ ] A search bar is pinned at the top; the search behaviour is
      unchanged
- [ ] Background is flat `Theme.paperCream` (no `BackgroundView`)
- [ ] A test confirms the sort stays newest-first and that search still
      filters by Note text (no regression on the existing behaviour)

## What is not in this ticket

- A change to Note storage, or any extraction of a Note type away from
  Completion. ADR 0002 stands.
- A new place to view Notes (removing or adding entry points beyond the
  Today sheet from ticket 22).

## Comments
