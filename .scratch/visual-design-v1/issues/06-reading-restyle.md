# 20: Reading restyle — three zones and the Coach Dock

**What to build:** The Reading screen in three zones. Top chrome: 宋体
title, faded-ink source line, thin grid-red reading-progress bar. Body:
PingFang 17pt at 1.9 line-height on the 田字格 watermark; tap-a-word opens
an inline lookup card that **drops down below the line** rather than
overlaying the paragraph. Bottom: the **Coach Dock**, persistent and
collapsed by default, pull-up to expand.

The Coach's house rules do not change: [ADR 0008](../../../docs/adr/0008-reading-coach-is-a-side-helper-not-homework.md).
Vocabulary: **Coach Dock** in [CONTEXT.md](../../../CONTEXT.md).

**Blocked by:** [15](01-palette-and-typography-primitives.md),
[17](03-tianzige-watermark-background.md),
[19](05-four-tab-nav.md).

**Status:** ready-for-agent

## The rule

- [ ] Top chrome carries the Article title (宋体 SemiBold 22pt), source
      line (faded ink 13pt, student's own writing, never translated) and
      a one-pixel grid-red reading-progress bar driven by scroll offset
- [ ] Body text is PingFang 17pt at 1.9 line-height on `BackgroundView`
- [ ] Tapping a Word opens an inline lookup card **below the paragraph
      line it sits on**, pushing following paragraphs down; the tapped
      paragraph stays visible. The Lookup is still recorded as before
      (ADR 0004)
- [ ] A looked-up Word in the body text gains a faded-ink one-pixel
      underline — matches the `.seen` state in the Collection Grid, so
      the vocabulary of "state" is consistent across screens
- [ ] The Coach Dock is persistent at the bottom. Collapsed it is one
      line ("读伴 在想…" when writing, "问读伴" otherwise). Pull-up
      expands to the Coach Session; pull-down collapses. Expanded, the
      dock covers no more than ~40% of the screen unless pulled further
- [ ] The old 问 button in the header is removed
- [ ] A test confirms the inline lookup card appears below the line and
      a Lookup is still recorded when the card opens

## What is not in this ticket

- The Coach's house rules or model (ADR 0008 stands verbatim). Only his
  placement changes — the sheet becomes a dock.
- Streaming the Coach reply differently (ticket 13 shipped that; the
  dock just hosts the same streamed thread).
- A reader font-size slider — that lives in Settings (ticket 24).

## Comments
