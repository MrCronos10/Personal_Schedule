# 04: Brush font (Ma Shan Zheng)

**What to build:** The brush face used for seals and headline grid-cell characters is bundled and made reachable from `Theme`. Ma Shan Zheng (the mockup's face, genuine OFL) is shipped with its licence, registered by `FontRegistry`, and exposed through a `Theme.brush(size:)` accessor. It is reserved for seals and headline cells; word-list grid cells stay Noto Serif SC.

**Blocked by:** None (parallel to 01 — does not depend on token values).

**Status:** ready-for-human

- [x] Ma Shan Zheng is bundled under `PersonalSchedule/Fonts/` with its OFL licence file beside it (`MaShanZheng-Regular.ttf` + `MaShanZheng-OFL.txt`), the same way the Noto faces are.
- [x] `FontRegistry` registers it, handling the `.ttf` extension (the code now tries `.otf` then `.ttf`, at the bundle root or under `Fonts/`).
- [x] Nothing executable (no generator/fetch script) is left inside `PersonalSchedule/` — only the font and its licence (verified by find).
- [x] A `Theme.brush(size:)` accessor returns the brush face, mirroring `Theme.serif(_:_:)`.
- [x] A guard test confirms the brush font family loads (`theBrushFontLoads`, `everyBundledFontLoads`).
- [x] Reserved for seals + headline grid-cell glyphs; word-list cells stay Noto Serif SC. Later tickets (05 读完, 06 词, 07 进度) enforce this at their cells.
- [ ] Brush rendering of the seals and headline cells is left for the student's eye on the phone.

## Comments

**Fetched:** `MaShanZheng-Regular.ttf` (5.8 MB) and `OFL.txt` from the upstream `google/fonts` repo; PostScript name verified as `MaShanZheng-Regular` (so `.custom(...)` / `UIFont(name:)` resolve). The `Theme.brush` accessor is intentionally unused for now — seal/headline-cell rendering lands in tickets 05–07.

**Tested (all green, full suite 359):** red/green proven — `theBrushFontLoads` failed (`UIFont(name:) → nil`) before `FontRegistry` learned `.ttf`, then passed.

**Rule checks:** `Fonts/` holds only the three faces and their two OFL files; no script or executable anywhere under `PersonalSchedule/`.

**/code-review (2 low-severity observations, both deliberately kept):**
- *(kept)* The 5.8 MB face registers synchronously on the main thread at launch, alongside the two Noto faces. This is the existing pattern on purpose: fonts are ready before first render, so there's no flash of unstyled text. Async registration would trade that for FOUT; cold-start tuning is a separate concern, not this ticket.
- *(kept)* Both font tests call `registerBundledFonts()`. Re-registration is idempotent (the already-registered result is discarded) and per-test registration keeps each test independent under parallel execution.

**Not seen running / left for the phone (why this is `ready-for-human`):** how Ma Shan Zheng renders the seal and headline-cell characters on the device.
