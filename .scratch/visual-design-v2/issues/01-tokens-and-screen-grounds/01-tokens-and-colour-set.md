# 01: Tokens and the v2 colour set

**What to build:** `Theme` carries the full v2 colour vocabulary from `docs/design-v2/brief.md` (Colour table), light and dark, as a single enumerable source of truth. A test iterates that source and proves every token resolves in both schemes, so a token added later can't silently ship without a dark value. No screen changes beyond the one colour value that actually moves (`bamboo`).

**Blocked by:** None (can start immediately).

**Status:** ready-for-human

- [x] Every v2 token exists with a light and a dark value from the brief: `paper`, `ink`, `red`, `sealRed`, `bamboo`, `brass`, `muted`, `lacquer`, `bambooPaper`, and the three `dawnHill` shades (plus the existing surface/role tokens).
- [x] Tokens come from **one enumerable source** (`Theme.Token`); a test walks it and asserts each token resolves in both light and dark — written first (red: `Theme.Token` did not exist), then made green.
- [x] The invariant is *"resolves in both schemes,"* not *"light ≠ dark"*: `onRed` and `lacquer` are deliberately mode-invariant and the test allows that explicitly.
- [x] `bambooGreen` → `bamboo`, value `0x4F6B38` (light) / `0x7FA060` (dark); the one view call site (`DayChecklist`) moved with it.
- [x] The light-only `Palette` enum is retired; its brief-value reference check is folded into the enumerable source's test (one place, light + dark, checked against the brief).
- [x] `red` and `muted` keep their names (= the brief's `gridRed` / `fadedInk`); a one-line comment records the mapping so brief and code reconcile.
- [x] `Theme.paper` etc. still work via named accessors — no churn in views that read tokens.
- [x] No stray hex / `.primary` / `.secondary` in views: grep the diff and report in Comments.

## Comments

**Tested (all green, full suite 351 tests):**
- `everyTokenResolvesInBothSchemes` walks `Theme.Token.allCases`: a token whose light == dark fails unless it is in the mode-invariant allow-list (`onRed`, `lacquer`). This is what makes "none is missing a dark value" true rather than honour-system.
- `theBriefColourTableIsHonoured` checks the brief's hex values off the token source, including the four new tokens and the `bamboo` change.
- `namedAccessorsAreWiredToTheirTokens` (added after review) asserts each `Theme.x` accessor resolves to its `Token`'s light/dark, so a mis-wire (`card = cardHigh.color`) can't ship silently. It passed the moment it was written — kept as a guard.
- Red/green loop: the completeness + brief-value tests were written first and failed to compile (`Theme.Token` absent) before the enum was added.

**Rule checks:**
- `bamboo` used only in a done state — one call site, `DayChecklist` ("今天 — 完成" checkmark).
- No stray hex / `.primary` / `.secondary` in views (grep of the diff). `BackgroundView` reads raw values off `Theme.Token`, not hex literals.

**/code-review findings:**
- *(fixed)* Named accessors were `static var { Token.x.color }`, rebuilding the adaptive `UIColor` on every body eval → back to `static let` (resolved once; still switches at draw time).
- *(fixed)* No accessor→token wiring test → added `namedAccessorsAreWiredToTheirTokens`.
- *(fixed)* `Token`'s unused `: String` raw backing dropped → `enum Token: CaseIterable`.
- *(by design)* `bamboo`'s light value moved `0x6B8E4E` → `0x4F6B38` (grilled decision 6; brief + mockup agree). Visible on the Today checkmark — on the phone-check list below.
- *(deferred to ticket 02)* `BackgroundView` cross-picks `Token.ink.dark` / `Token.red.light` for its grid line. Flagged in-code; ticket 02 gives the grid line its own token read when the view is renamed.

**Not seen running / left for the phone (why this is `ready-for-human`):**
- The proposed dark values for `bambooPaper`, `brass`, and the three `dawnHill` shades (the brief marks these as proposals).
- The `bamboo` light change on the Today completion checkmark (slightly darker, more olive green).
