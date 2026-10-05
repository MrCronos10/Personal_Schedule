# 04: Brush font (Ma Shan Zheng)

**What to build:** The brush face used for seals and headline grid-cell characters is bundled and made reachable from `Theme`. Ma Shan Zheng (the mockup's face, genuine OFL) is shipped with its licence, registered by `FontRegistry`, and exposed through a `Theme.brush(size:)` accessor. It is reserved for seals and headline cells; word-list grid cells stay Noto Serif SC.

**Blocked by:** None (parallel to 01 — does not depend on token values).

**Status:** ready-for-agent

- [ ] Ma Shan Zheng is bundled under `PersonalSchedule/Fonts/` with its OFL licence file beside it, the same way the Noto faces are.
- [ ] `FontRegistry` registers it, handling the `.ttf` extension (the current code assumes `.otf`).
- [ ] Nothing executable (no generator/fetch script) is left inside `PersonalSchedule/` — only the font and its licence. (AGENTS.md: anything under `PersonalSchedule/` ships in the app.)
- [ ] A `Theme.brush(size:)` accessor returns the brush face, mirroring `Theme.serif(_:_:)`.
- [ ] A guard test confirms the brush font family loads (non-nil `UIFont`).
- [ ] Reserved for seals + headline grid-cell glyphs; word-list cells stay Noto Serif SC. Later tickets (05 读完, 06 词, 07 进度) enforce this at their cells.
- [ ] Brush rendering of the seals and headline cells is left for the student's eye on the phone.

## Comments
