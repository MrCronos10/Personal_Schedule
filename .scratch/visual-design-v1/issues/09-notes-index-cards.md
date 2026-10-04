# 23: Notes restyle — index-card stack

**What to build:** The **Notes List** sheet (opened from Today, ticket 22)
as a loose stack of cream index cards. Each **Note** is a card with a thin
grid-red top edge, 宋体 title (the Note's first line), PingFang body. Tap
to expand to full screen; swipe down to collapse. A search bar sits
pinned at the top. Flat paper cream background — no 田字格 watermark; the
cards are the texture.

**Blocked by:** [15](01-palette-and-typography-primitives.md).

**Status:** ready-for-human (taps: open a card, swipe it down, 看这一天)

## The rule

- [x] Notes are read from the existing model (Completion `Note`, ADR
      0002); the content, search, and newest-first order are unchanged
- [x] Each Note renders as a cream card with a thin grid-red top edge
      (two-pixel bar) and a very thin cream-paper edge shadow (the only
      shadow the whole app allows)
- [x] Cards are offset ±2° on alternate rows so the stack reads as paper
      pile, not list
- [x] Note title uses 宋体 SemiBold 17pt (the Note's first line, student's
      own writing — never translated); body uses PingFang 15pt
- [x] Tap a card to open it to full size (a sheet, so swiping down puts it back on the stack). It carries
      看这一天, which keeps the old tap-a-Note-to-see-its-day behaviour
- [x] A search bar is pinned at the top; the search behaviour is
      unchanged
- [x] Background is flat `Theme.paperCream` (no `BackgroundView`)
- [x] Sort and search are untouched (`NotesListTests` still pass); `NoteCardTests` pin the title/body split and the alternating tilt

## What is not in this ticket

- A change to Note storage, or any extraction of a Note type away from
  Completion. ADR 0002 stands.
- A new place to view Notes (removing or adding entry points beyond the
  Today sheet from ticket 22).

## Comments

- Red first (no `NoteCardStyle`), then green; full suite passes. The stack was rendered to PNG and looked at.
- The card title is the Note's first line (the Note has no title of its own); a one-line Note is all title.
- Cards lean -2 / +2 degrees alternately and have the app's one allowed shadow.
- Not seen running: opening and swiping a card down.
