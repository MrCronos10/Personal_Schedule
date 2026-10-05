# 03: The four named grounds

**What to build:** The remaining four per-screen grounds from `docs/design-v2/brief.md` (Screen grounds table) ship as standalone, previewable SwiftUI primitives built from flat `Shape`/`Canvas` only: `DawnHeader`, `BambooBackground`, `NightBand`, `LacquerBackground`. They are not wired into any screen yet — tickets 03 (Today) and 07 (Progress) place them.

**Blocked by:** 01 (tokens and the v2 colour set) — each ground reads tokens.

**Status:** ready-for-agent

- [ ] `DawnHeader`: cream ground with three layered hills and a red sun, 250 pt tall, behind the header only. Height pinned by a test.
- [ ] `BambooBackground`: `bambooPaper` ground with faint bamboo stems and leaves top-right, green at 14–18%. Opacity range pinned by a test.
- [ ] `NightBand`: ink header band with rounded bottom corners, sized to sit over the paper grid.
- [ ] `LacquerBackground`: flat `lacquer` (#2A1F1A) ground with cream tiles — the one dark screen in light mode.
- [ ] All four are flat shapes: **no image assets, no gradients.**
- [ ] Each has a test pinning its numeric constant(s) plus a renders-in-both-modes check, the way `PaperGridBackground` is tested. Assertions that pass the moment written are kept as guards and said so plainly.
- [ ] The proposed dark values for `bambooPaper`, `brass`, and `dawnHill` are left for the student's eye on the phone.

## Comments
