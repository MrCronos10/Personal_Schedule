# 02: The 田字格 ground — PaperGridBackground

**What to build:** The existing `BackgroundView` (v1 ticket 03) becomes `PaperGridBackground`, the named 田字格 ground in the v2 grounds family. It reads its grid-line colour from `Theme` tokens and sits at the brief's faintness of 6% (light) / 4% (dark). Reading, Vocabulary, and Progress keep rendering unchanged.

**Blocked by:** 01 (tokens and the v2 colour set) — the grid-line colour is read from a token.

**Status:** ready-for-agent

- [ ] `BackgroundView` renamed to `PaperGridBackground` (view file + test file + the 3 call sites), API otherwise unchanged. The git diff reads as a rename, not a rewrite.
- [ ] Grid-line colour read from `Theme` tokens, not from the retired `Palette`.
- [ ] Opacity moves to **0.06 light / 0.04 dark**: flip `theWatermarkIsFaint` to `0.06` first (red), then change the value (green).
- [ ] Cell size stays 88 pt; the view still renders in both modes.
- [ ] Faintness at 6% is left for the student's eye on the phone (this is why the ticket ends `ready-for-human`).

## Comments
