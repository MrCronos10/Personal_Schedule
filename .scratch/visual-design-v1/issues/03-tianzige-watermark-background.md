# 17: 田字格 watermark background

**What to build:** One `BackgroundView` that renders paper cream with a
faint repeating 田字格 pattern — 5% grid-red in light, 4% lantern-cream in
dark. One cell = 88pt. Content screens (Reading, Vocabulary, Progress) use
it; chrome screens (Today, Notes, Coach, Settings) stay flat. No screen is
rebuilt in this ticket — only the view is added.

Why this rule: [docs/design-v1.md](../../../docs/design-v1.md) — "Backgrounds".

**Blocked by:** [15](01-palette-and-typography-primitives.md).

**Status:** ready-for-human (how faint it looks is judged on the phone)

## The rule

- [x] `BackgroundView` is a SwiftUI view that fills its parent and tiles
      one 田字格 cell at 88pt. The cell is grid red at 5% in light,
      lantern cream at 4% in dark
- [x] The watermark is drawn with `Canvas` or a repeating `Path`, not a
      bitmap asset — so it stays crisp at every scale
- [x] A test `theWatermarkOpacityIsFaint` reads the alpha of the stroke
      colour and asserts it is `0.05` (light) and `0.04` (dark), so a
      later "I'll just bump this to 10% to see it better" shows up red
- [x] `BackgroundView` is referenced in the project but not applied to
      any screen yet — the following tickets wire it in one by one

## What is not in this ticket

- Applying the background to Reading, Vocabulary or Progress. Each is its
  own ticket (20, 21, 18 respectively) and the application is one line
  there.
- A background image. The watermark is drawn, not photographed.

## Comments

- Red first (no `BackgroundView`), then green; full suite passes. The pattern is drawn with `Canvas`: solid lines on the cell edge, dashed lines through each cell's middle. Wired into screens by tickets 18, 20, 21.
