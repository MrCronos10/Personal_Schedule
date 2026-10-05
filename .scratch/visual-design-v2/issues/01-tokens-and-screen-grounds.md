# 01: Tokens and screen grounds

**Split into four sub-tickets** (see `01-tokens-and-screen-grounds/`). Tickets `02–09` that are "blocked by 01" are blocked by **all four** below.

**What it covers:** the v2 token set in `Theme.swift` (`docs/design-v2/brief.md`, Colour table), the per-screen grounds as reusable flat-shape SwiftUI views, and the bundled brush font.

**Status:** split

## Sub-tickets and order

| # | Ticket | Blocked by |
| --- | --- | --- |
| 01 | Tokens and the v2 colour set | None — start now |
| 02 | The 田字格 ground → `PaperGridBackground` | 01 |
| 03 | The four named grounds (`DawnHeader`, `BambooBackground`, `NightBand`, `LacquerBackground`) | 01 |
| 04 | Brush font (Ma Shan Zheng) | None — parallel to 01 |

Frontier: sub-tickets 01 and 04 can start immediately; 02 and 03 unlock once 01 lands.

## Rules that must hold across all four (from the brief and AGENTS.md)

- [ ] Every colour in views comes from a `Theme` token; no stray hex or `.primary`/`.secondary` (grep the diff).
- [ ] Each token has a light and a dark value; a test asserts none is missing.
- [ ] `bamboo` is only used for done states (grep the diff and say so).
- [ ] Grounds take no image assets and no gradients.
- [ ] Fonts live in `PersonalSchedule/Fonts/` with their licence; the generator-in-bundle mistake from AGENTS.md is not repeated.

## Decisions (from the grilling session, 2026-10-05)

1. Brush face = **Ma Shan Zheng (OFL)**, reserved for seals + headline grid-cell glyphs; word-list cells stay Noto Serif SC.
2. 田字格 opacity moves to the brief's **6% / 4%** (was 5% / 4%).
3. `BackgroundView` is **renamed** to `PaperGridBackground`, API unchanged.
4. Tokens become **one enumerable source**; completeness test = "resolves in both schemes," with `onRed`/`lacquer` deliberately mode-invariant.
5. All five grounds ship as **standalone primitives**; screen wiring is deferred to tickets 03/07.
6. `bambooGreen` → `bamboo` = `0x4F6B38 / 0x7FA060`; the light-only `Palette` is retired, folded into the enumerable source.
7. Token names `red` / `muted` are kept (= brief's `gridRed` / `fadedInk`), with a mapping comment.

## Comments
