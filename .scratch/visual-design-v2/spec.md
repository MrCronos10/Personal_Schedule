# Visual Design v2 — 日课 refresh

Builds on [visual-design-v1](../visual-design-v1/spec.md) and [docs/design-v1.md](../../docs/design-v1.md). The new design is in [docs/design-v2/](../../docs/design-v2/README.md): read `brief.md` and the matching `screens/*.dc.html` before each ticket.

What v2 changes over v1: a named ground for each screen, a Today card with a reading-goal stamp slot, near-Known dots in the reader, a 读完 result screen, a swipe deck for Daily New Words, a Collection Grid with a night-band header, and the new Seal Book (ADR 0010, proposed).

## Order

1. `01` tokens and screen grounds
2. `02` logo and app icon (supersedes v1 ticket 02 where they differ)
3. `03` Today
4. `04` Reader
5. `05` 读完 result
6. `06` Vocabulary and swipe deck
7. `07` Progress grid
8. `08` Seal Book — **blocked until ADR 0010 is accepted**
9. `09` Notes, Settings, empty states

`01` blocks all. `05` is blocked by `04`. `08` is blocked by `07` and ADR 0010. If a v1 ticket (`../visual-design-v1/issues/`) is already built, extend it; do not redo it.

## Out of scope

No change to Known, Clean Sighting, Lookup, Set Aside, Topic Known (ADRs 0004–0008). No sound. No image-asset backgrounds. No streaks.
