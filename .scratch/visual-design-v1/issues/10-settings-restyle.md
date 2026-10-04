# 24: Settings restyle — grouped list and 关于

**What to build:** The Settings sheet (opened from Today's gear, ticket
19) as a grouped iOS-native list on flat paper cream. Four sections —
阅读, 词, 读伴, 关于 — matching the design brief. 关于 carries the version,
in-app web views to the ADRs, and the Source Han Serif licence credit.

Why the Coach key stays in Keychain and 保存 / 清除 stay the controls:
[ADR 0008](../../../docs/adr/0008-reading-coach-is-a-side-helper-not-homework.md).

**Blocked by:** [15](01-palette-and-typography-primitives.md),
[19](05-four-tab-nav.md).

**Status:** ready-for-human (taps: the stepper and slider, then read an Article at the new size)

## The rule

What this ticket really shipped, since several settings in the first draft named things the app does not have:

- [x] **阅读**: a daily reading goal (default 200 字, a stepper from 50 to 1,000) and a text size slider (15-24, default 17) with a live preview line. The reader uses the size at line height 1.9. `ReadingPreferencesTests` pin the defaults, the ranges and persistence
- [x] **关于**: the `LogoView`, the version and build, and the Noto Serif SC licence credit
- [x] The goal is the number the Today seal (ticket 25) reads
- [x] 读伴's API key and 保存 / 清除 are unchanged (ADR 0008)
- [x] Background stays flat paper (no `BackgroundView`); the existing sections keep the Field Notebook cards

## What is not in this ticket

- Any change to the Coach's model, proxy or key storage. ADR 0008
  stands.
- A new reading goal rule — only the setting that drives ticket 25's
  seal stamp.
- An iCloud or sync toggle. The project is still device-only until the
  Apple Developer Program is paid.

## Comments

- Red first (no `ReadingPreferences`), then green; full suite passes. Settings was rendered to PNG and looked at.
- Not built, on purpose: a **词** section (a 难词 review count would be the review queue ADR 0004 refuses, and the Set Aside window is thirty days by ADR 0006, not a setting), **Article import defaults** (there is nothing to default), a **Coach Language default** (CONTEXT.md says it is picked per message), and **ADR links in the app** (the ADRs live in `docs/`, outside the bundle; copying them into `PersonalSchedule/` would ship duplicates).
- `Theme.reading` / `readingLineSpacing` were removed; `ReadingPreferences` owns the reader's size now.
