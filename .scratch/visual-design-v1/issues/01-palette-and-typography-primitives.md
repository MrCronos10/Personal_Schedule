# 15: Palette and typography primitives

**What to build:** The full colour-token set from the design brief lives in
`Theme.swift`, light and dark pairs for every role. **Source Han Serif**
(Regular, SemiBold) is bundled under `PersonalSchedule/Fonts/` and registered
in `Info.plist`. Existing one-off colours and font calls in the views are
swapped for the new tokens. No screen is redesigned in this ticket.

Why this direction: [ADR 0009](../../../docs/adr/0009-visual-design-is-practice-book-hybrid.md).
The full palette and type scale: [docs/design-v1.md](../../../docs/design-v1.md).

**Blocked by:** None.

**Status:** ready-for-agent

## The rule

- [ ] `Theme.swift` exposes eight tokens: `paperCream`, `nightInk`,
      `inkBlack`, `lanternCream`, `gridRed`, `sealRed`, `bambooGreen`,
      `fadedInk`. Each resolves correctly in light and dark — the hex pairs
      in `docs/design-v1.md` are the single source
- [ ] `Theme.swift` exposes a type scale: `display` (28), `title` (22),
      `body` (17), `metadata` (13), `caption` (11), each with its Chinese
      face (宋体 for display, PingFang below), its Latin pairing (New York
      for display, SF Pro below), and `.monospacedDigit()` on counts
- [ ] Source Han Serif Regular and SemiBold ship inside the app bundle
      and are registered in Info.plist's `UIAppFonts`
- [ ] Every existing use of `.primary`, `.secondary`, `Color.red`,
      `Color.gray` and literal hex colours in `PersonalSchedule/` is swapped
      for the matching token (grep passes with no stragglers)
- [ ] A test `theTokensExistInLightAndDark` reads one token through
      `UITraitCollection` for each mode and asserts it isn't the same hex,
      so a future "forgot to add the dark variant" shows up red

## What is not in this ticket

- The 田字格 watermark background (ticket 17).
- The logo and app icon (ticket 16).
- Any screen's layout — only its colours and fonts.
- Dark-mode-specific layout changes. Colours swap, layouts hold.

## Comments
