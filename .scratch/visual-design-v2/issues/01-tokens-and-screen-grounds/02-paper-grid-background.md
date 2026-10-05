# 02: The 田字格 ground — PaperGridBackground

**What to build:** The existing `BackgroundView` (v1 ticket 03) becomes `PaperGridBackground`, the named 田字格 ground in the v2 grounds family. It reads its grid-line colour from `Theme` tokens and sits at the brief's faintness of 6% (light) / 4% (dark). Reading, Vocabulary, and Progress keep rendering unchanged.

**Blocked by:** 01 (tokens and the v2 colour set) — the grid-line colour is read from a token.

**Status:** ready-for-human

- [x] `BackgroundView` renamed to `PaperGridBackground` (view file + test file + the 3 call sites), API otherwise unchanged. The git diff reads as a rename, not a rewrite.
- [x] Grid-line colour read from `Theme` tokens, not from the retired `Palette`: a dedicated `Token.gridLine`, *derived* from `red` (gridRed on cream) and `ink` (lantern cream on night ink) so the two can't drift.
- [x] Opacity moves to **0.06 light / 0.04 dark**: `theWatermarkIsFaint` flipped to `0.06` first (genuine red — `0.05 == 0.06` failed), then the value changed (green).
- [x] Cell size stays 88 pt; the view still renders in both modes.
- [ ] Faintness at 6% left for the student's eye on the phone.

## Comments

**Tested (all green, full suite 352):**
- The three ground tests moved with the rename (`theWatermarkIsFaint`, `oneCellIsEightyEightPoints`, `theBackgroundRendersInBothModes`).
- `gridLine` is covered automatically by `everyTokenResolvesInBothSchemes` (light 0xC8382E ≠ dark 0xE8DEC5), and a new `gridLineTracksGridRedAndLanternCream` pins its derivation from `red`/`ink`.
- Red/green loop on the opacity: test flipped to 0.06 first and failed, then the code moved to 0.06.

**Rule checks:** no leftover `BackgroundView` references; no stray hex / `.primary` / `.secondary` in views.

**/code-review:** one low-severity note — `gridLine` hand-copied `red.light`/`ink.dark` as literals, which could drift. Fixed by making `gridLine` *derive* from those tokens (`Self.red.light` / `Self.ink.dark`) and adding the guard test above. No correctness bugs found.

**Not seen running / left for the phone (why this is `ready-for-human`):** how faint the grid looks at 6% on the actual iPhone.
