# Design v2 — handoff

Made in Claude Design (canvas "Personal Schedule — 日课 redesign"). This folder is the source of truth for the look; `docs/design-v1.md` is the earlier brief it builds on.

## Read in this order

1. `brief.md` — every decision in words: logo, colours, type, per-screen backgrounds, each screen, motion.
2. `screens/*.dc.html` — one file per screen, 390 × 844 pt. They are plain HTML with inline styles, so colours, sizes, spacing and radii can be read straight off the markup. They need a runtime (`support.js`) to render, so **read them as specs, don't ship them**. Mapping:

   | File | Screen | SwiftUI home |
   | --- | --- | --- |
   | `Main.dc.html` | Logo, palette, grounds, seals | `Theme.swift`, `LogoView`, AppIcon |
   | `Today.dc.html` | 今天 | `Today/` |
   | `Reading.dc.html` | Reader | `Reading/ArticleReaderView.swift` |
   | `Celebrate.dc.html` | 读完 result | `Reading/BankedResultLine.swift`, `RedSealStamp.swift` |
   | `Words.dc.html` | 词 | `Vocabulary/` |
   | `Progress.dc.html` | 进度 collection grid | `Progress/` |
   | `Seals.dc.html` | 印章册 (new) | new `Seals/` folder |

3. `.scratch/visual-design-v2/spec.md` and its tickets — the build order.

## Rules for whoever builds this

- Follow `AGENTS.md`: red/green per rule, tests at the libraries, screens checked by hand on the phone, one commit per ticket, push only when asked.
- **Fonts in the mockups are stand-ins.** Chinese display is Noto Serif SC (already bundled). The brush face (Ma Shan Zheng in the mockup) must be bundled under `PersonalSchedule/Fonts/` with its OFL licence before it is used. Numerals use SF Mono (`.monospaced`).
- Every new Chinese string needs its English in `Localizable.xcstrings`.
- The Seal Book conflicts with ADR 0004 and 0009 (no badges). **ADR 0010 (draft) is where that is decided. Do not build ticket 08 until the student has accepted or rejected it.**
- Backgrounds are flat vector shapes (SwiftUI `Shape`/`Canvas`), no image assets, no gradients.
- Anything in `PersonalSchedule/` ships in the app. Keep these mockups out of it.
