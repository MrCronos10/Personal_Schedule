# 02: Logo and app icon

**What to build:** The 读 田字格 mark with the 日 chop (`screens/Main.dc.html`, `brief.md` Logo): `AppIcon.appiconset` (light, dark), and `LogoView(size:)` which drops the cross and chop at ≤ 40 pt. Use it in the Settings About row and the Evening Check header. Brush-written 读, not geometric type.

**Blocked by:** 01. **Status:** ready-for-human

## The rule

- [x] All iOS icon sizes present, light and dark; no iOS 18 tinted variant (one 1024 universal per appearance; Xcode scales the rest; `Contents.json` has no `tinted` appearance).
- [x] `LogoView` small-size variant has no cross or chop (gated by `LogoView.showsDetails(at:)`, `size > 40`).
- [x] A test renders `LogoView` at 128 pt in both modes and asserts both exist.

## Comments

**LogoView (v2):** brush-written 读 (`Theme.brush`, ~70% of the cell) in the red 田字格, with the seal-red 日 chop (from 日课) bottom-right. Dark mode: lantern-cream 读 on night ink, grid stays red. The dashed cross and the chop drop at ≤ 40 pt via `showsDetails(at:)`. It flows into the **Settings About row** (the only live placement). The v1 "Evening Check sheet" no longer exists — the 读完 result screen is ticket 05, so there's no second placement to wire here.

**App icon:** regenerated as the brush mark (full-bleed 田字格, brush 读, 日 chop), light and dark, by `.scratch/visual-design-v2/make-app-icon.swift` (a one-off CoreText tool kept out of `PersonalSchedule/`). The PNGs are RGB with **no alpha channel** (App Store rejects a 1024 marketing icon that has one). The icon's reds/chop match `LogoView`'s per-mode tokens so the home-screen mark and the in-app mark are the same drawing.

**Tested (full suite 360):** `detailsShowOnlyAboveFortyPoints` (red→green — `showsDetails` was added for it) and `theLogoRendersInLightAndDark` (128 pt, both modes).

**Rule checks:** no generator/script under `PersonalSchedule/`; the icon generator lives in `.scratch` and is committed beside the assets it produces.

**/code-review (4 findings, all fixed):**
- *(fixed)* regenerated icon had an alpha channel → would fail App Store validation; now rendered opaque (`noneSkipLast`).
- *(fixed)* dark icon used light-mode reds → aligned to `LogoView`'s dark tokens (grid `0xA3362E`, chop `0x6E2419`).
- *(fixed)* dark chop 日 was near-black on red → now cream (`onRed`) in both modes, matching `LogoView`.
- *(fixed)* the generator (source-of-truth for the committed PNGs) was untracked → committed with the assets.

**Not seen running / left for the phone (why this is `ready-for-human`):** the icon on the home screen in light and dark, and the brush mark in the About row on the device.
