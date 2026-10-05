# 03: The four named grounds

**What to build:** The remaining four per-screen grounds from `docs/design-v2/brief.md` (Screen grounds table) ship as standalone, previewable SwiftUI primitives built from flat `Shape`/`Canvas` only: `DawnHeader`, `BambooBackground`, `NightBand`, `LacquerBackground`. They are not wired into any screen yet — tickets 03 (Today) and 07 (Progress) place them.

**Blocked by:** 01 (tokens and the v2 colour set) — each ground reads tokens.

**Status:** ready-for-human

- [x] `DawnHeader`: cream ground with three layered hills (`dawnHill1–3`) and a low red sun, 250 pt tall, behind the header only. Height pinned by a test.
- [x] `BambooBackground`: `bambooPaper` ground with faint bamboo stems and leaves top-right, green at 14–18% (`stemOpacity` 0.16, `leafOpacity` 0.14). Opacity range pinned by a test.
- [x] `NightBand`: ink header band with rounded bottom corners, over `PaperGridBackground`, sized by a per-caller height with a default.
- [x] `LacquerBackground`: flat `lacquer` (#2A1F1A) ground with a faint cream tile grid — the one dark screen in light mode.
- [x] All four are flat shapes: **no image assets, no gradients** (grep of the diff).
- [x] Each has a test pinning its numeric constant(s) plus a renders-in-both-modes check, the way `PaperGridBackground` is tested.
- [ ] The proposed dark values for `bambooPaper`, `brass`, `dawnHill`, and the new `nightBand` are left for the student's eye on the phone.

## Comments

**New token:** `NightBand` needed a `Theme.nightBand` surface — the text `ink` token inverts to cream at night, so a dark header band can't use it. `nightBand` is ink-black in light mode and a lifted-from-dark-paper proposal at night; it is its own role (independent hex), not derived from `ink`.

**Tested (all green, full suite 357):**
- `GroundsTests`: `dawnHeaderIsTwoHundredFiftyTall`, `bambooFoliageIsFaintGreen` (both opacities in 0.14…0.18), `nightBandHasRoundedBottomCorners`, `lacquerTilesAreFaint`, and `allGroundsRenderInBothModes`.
- `everyTokenResolvesInBothSchemes` / the wiring test now cover `nightBand`.
- Red/green: `GroundsTests` was written first and failed to compile (the four types absent) before the views were added.

**Rule checks:** no gradients or image assets in the four grounds (grep); no stray hex / `.primary` / `.secondary` in views.

**/code-review (4 findings, all addressed):**
- *(fixed)* `nightBand` was derived from the text `ink` token, coupling a surface to a text role → given its own independent hex.
- *(resolved by the above)* missing derivation guard for `nightBand` → no longer derived, so none needed.
- *(fixed)* the grid-line `Canvas` loop was duplicated in `PaperGridBackground` and `LacquerBackground` → extracted a shared `Path.grid(spacing:offset:in:)` helper (identical iteration, no render change).
- *(fixed)* `NightBand` had a static and an instance `headerHeight` with the same name → static renamed to `defaultHeaderHeight`.

**Not seen running / left for the phone (why this is `ready-for-human`):** how each ground looks in isolation (hills/sun composition, bamboo foliage placement, night-band height, lacquer tile faintness) and the proposed dark values.
