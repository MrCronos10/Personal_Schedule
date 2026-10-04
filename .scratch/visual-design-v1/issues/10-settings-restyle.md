# 24: Settings restyle — grouped list and 关于

**What to build:** The Settings sheet (opened from Today's gear, ticket
19) as a grouped iOS-native list on flat paper cream. Four sections —
阅读, 词, 读伴, 关于 — matching the design brief. 关于 carries the version,
in-app web views to the ADRs, and the Source Han Serif licence credit.

Why the Coach key stays in Keychain and 保存 / 清除 stay the controls:
[ADR 0008](../../../docs/adr/0008-reading-coach-is-a-side-helper-not-homework.md).

**Blocked by:** [15](01-palette-and-typography-primitives.md),
[19](05-four-tab-nav.md).

**Status:** ready-for-agent

## The rule

- [ ] Four sections in order: **阅读** (daily reading goal — defaults to
      200 字 — font size slider, Article import defaults), **词** (daily
      难词 review count, Set Aside window defaulting to 30 days per ADR
      0006), **读伴** (SecureField for the API key, 保存 and 清除, a one-line
      "本地保存，不上传" note under it, Coach Language default picker), **关于**
      (version, in-app web views for each ADR, Source Han Serif licence)
- [ ] The 关于 web views open the ADR markdown files bundled with the
      app, rendered as plain text; no external links
- [ ] The daily reading goal from this screen is the number the Today
      seal stamp (ticket 25) reads
- [ ] Background is flat `Theme.paperCream` (no `BackgroundView`)
- [ ] A test confirms the daily reading goal round-trips through
      `UserDefaults` and that an empty 读伴 key still lets Settings
      render (no crash on first launch)

## What is not in this ticket

- Any change to the Coach's model, proxy or key storage. ADR 0008
  stands.
- A new reading goal rule — only the setting that drives ticket 25's
  seal stamp.
- An iCloud or sync toggle. The project is still device-only until the
  Apple Developer Program is paid.

## Comments
