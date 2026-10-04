# 15: Palette and typography primitives

**What to build:** The full colour-token set from the design brief lives in
`Theme.swift`, light and dark pairs for every role. **Source Han Serif**
(Regular, SemiBold) is bundled under `PersonalSchedule/Fonts/` and registered
in `Info.plist`. Existing one-off colours and font calls in the views are
swapped for the new tokens. No screen is redesigned in this ticket.

Why this direction: [ADR 0009](../../../docs/adr/0009-visual-design-is-practice-book-hybrid.md).
The full palette and type scale: [docs/design-v1.md](../../../docs/design-v1.md).

**Blocked by:** None.

**Status:** ready-for-human (dark mode and the new warm paper are only seen on the iPhone)

## The rule

- [x] `Theme.Palette` holds the eight named colours (`paperCream`, `nightInk`,
      `inkBlack`, `lanternCream`, `gridRed`, `sealRed`, `bambooGreen`,
      `fadedInk`); the roles screens use (`paper`, `ink`, `red`, `muted`,
      `card`, …, plus new `sealRed` and `bambooGreen`) resolve to the brief's
      light or dark hex
- [x] `Theme.display` (28 serif), `Theme.reading` (17, line height 1.9) and
      `Theme.mono(_:)` (SF Mono for counts) are added. The existing scale
      (headline 24 / title 20 / body 15 / meta 12 / label 11) is kept, since
      resizing it app-wide would reflow every row without being seen
- [x] No new font file: Noto Serif SC (already bundled, registered by
      `FontRegistry`) is Adobe's Source Han Serif under its Google name, so
      shipping both would be 280 KB of the same glyphs
- [x] Every view already read its colours from `Theme`, so the swap is in
      `Theme.swift` alone (grep finds no literal colour outside it)
- [x] A test `theTokensExistInLightAndDark` reads one token through
      `UITraitCollection` for each mode and asserts it isn't the same hex,
      so a future "forgot to add the dark variant" shows up red

## What is not in this ticket

- The 田字格 watermark background (ticket 17).
- The logo and app icon (ticket 16).
- Any screen's layout — only its colours and fonts.
- Dark-mode-specific layout changes. Colours swap, layouts hold.

## Comments

- Red first: `ThemeTests` failed to build (no `Palette`, no `sealRed`), then went green. Full suite passes.
- No `/code-review` run for this ticket on its own; the diff is one file of constants, reviewed with the rest at the end (see ticket 25).
- Not seen running: dark mode on the phone. Every screen now follows the system appearance; if a screen looks wrong at night, it is one that draws a literal colour — none was found by grep.
