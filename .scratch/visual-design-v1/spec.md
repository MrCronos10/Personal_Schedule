# Visual Design v1 — the practice-book hybrid

Turn the design brief at [docs/design-v1.md](../../docs/design-v1.md) into
shippable screens. The direction and the hard-to-reverse decisions are
pinned by [ADR 0009](../../docs/adr/0009-visual-design-is-practice-book-hybrid.md);
new vocabulary (Practice-book Hybrid, Collection Grid, Cell State, Collection
Sliver, Coach Dock, Shelf, Small Celebration) is in [CONTEXT.md](../../CONTEXT.md).

## The order, and why

System first, screens after, celebrations last. Each ticket is one
red-green cycle's worth of rule, kept to one job so a tap-through on the
student's iPhone can tell "did this ticket land" without reading the diff.

- `15` palette + typography primitives — the token set, Source Han Serif
  bundled, existing one-off colours swapped for tokens. No visual redesign.
- `16` logo + app icon — the **读** 田字格 mark, light + dark, plus a
  `LogoView` for in-app use.
- `17` 田字格 watermark background — one `BackgroundView` content screens
  use, no screen rebuilt yet.
- `18` collection grid — the new **Progress** screen with three **Cell
  States** (not met, seen, Known) and the fill animation.
- `19` four-tab nav restructure — Settings leaves the tab bar, Progress
  takes its place; the gear moves to Today's top-right.
- `20` reading restyle — three zones, inline lookup card, **Coach Dock**.
- `21` vocabulary restyle — three **Shelves** (难词, HSK, 农业词).
- `22` today restyle — **Collection Sliver**, notebook-rule Daily
  Checklist, Timetable.
- `23` notes restyle — index-card stack.
- `24` settings restyle — grouped list + 关于 with ADR links.
- `25` small celebrations — the four moments, one pass so they stay a
  family.

## Blocking edges

```
15 palette  ──┬── 17 watermark ──┬── 20 reading ──┬── 25 celebrations
              │                   │                │
              ├── 18 grid ────────┼── 21 vocab    ─┤
              │                   │                │
              ├── 19 nav ─────────┼── 22 today ───┘
              │                   │
              ├── 23 notes        │
              └── 24 settings     │
                                  │
16 logo (independent) ────────────┘
```

- `17`, `18`, `23`, `24` are blocked only by `15`.
- `19` is independent of `15` in theory (nav structure doesn't need
  colours) but sequencing it after `15` keeps PRs small.
- `20` is blocked by `15`, `17`, `19`.
- `21` is blocked by `15`, `17`, `18`, `19`.
- `22` is blocked by `15`, `18`, `19`.
- `25` is blocked by `18`, `20`, `22` (that's where its four moments fire).
- `16` is independent and can land any time.

So the student can pick up `15` or `16` first; the rest unblock from there.

## Out of scope for v1

- A new animation library. SwiftUI's own `.animation` and `withAnimation`
  are enough; no Lottie.
- A dark-mode-specific layout. Colours swap, layouts hold.
- Any change to Known, Clean Sighting, Lookup, Set Aside, Topic Known
  (ADRs 0004–0008 stand).
- A sound. The app is silent.
