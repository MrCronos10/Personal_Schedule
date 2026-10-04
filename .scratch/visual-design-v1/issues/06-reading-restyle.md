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

**Status:** ready-for-human (taps: tap a word, pull the dock up and down, scroll for the progress bar)

## The rule

- [x] Top chrome carries the Article title (宋体 SemiBold 22pt), source
      line (faded ink 13pt, student's own writing, never translated) and
      a one-pixel grid-red reading-progress bar driven by scroll offset
- [x] Body text is the system face (PingFang for Chinese) at 17pt, line height 1.9, on `BackgroundView`
- [x] Tapping a Word opens an inline lookup card **below the paragraph
      line it sits on**, pushing following paragraphs down; the tapped
      paragraph stays visible. The Lookup is still recorded as before
      (ADR 0004)
- [x] A looked-up Word in the body text gains a faded-ink one-pixel
      underline — matches the `.seen` state in the Collection Grid, so
      the vocabulary of "state" is consistent across screens
- [x] The Coach Dock is persistent at the bottom. Collapsed it is one
      line ("读伴 在想…" when writing, "问读伴" otherwise). Pull-up
      expands to the Coach Session; pull-down collapses. Expanded, the
      dock covers no more than ~40% of the screen unless pulled further
- [x] The old 问 button in the header is removed
- [x] `ReaderLayoutTests` pin the progress fraction and the paragraph split the card relies on. The tap itself goes through the same `lookUp` call as before (covered by the library tests); the card appearing is a tap, left for the phone

## What is not in this ticket

- The Coach's house rules or model (ADR 0008 stands verbatim). Only his
  placement changes — the sheet becomes a dock.
- Streaming the Coach reply differently (ticket 13 shipped that; the
  dock just hosts the same streamed thread).
- A reader font-size slider — that lives in Settings (ticket 24).

## Comments

- Red first (no `ReadingProgress` / `ArticleParagraphs`), then green; full suite passes. The reader and the card were rendered to PNG and looked at; that showed 0.9 extra line spacing made lines ~2.05x, so it is 0.7 (SwiftUI adds spacing to the font's own ~1.2).
- "Below the line": the text is drawn paragraph by paragraph and the card opens under the *paragraph* that was tapped, not under the exact line. SwiftUI gives no position for a link inside flowing text, so a per-line card would need the text re-laid-out by hand.
- `WordLookupSheet` was split into `WordLookupContent` (shared) plus a thin sheet, so the inline card and the sheet used by 难词 and the grid cannot drift apart. Memory trick and 我认识这个词 work in the card.
- `CoachSheetView` became `CoachThreadView` (no NavigationStack, a 清除对话 button in its context line); the dock keeps it alive at zero height when collapsed so a streaming reply is not cancelled.
- The progress bar reads full for an Article that fits on the screen (nothing to scroll).
- Not seen running: dragging the dock, scroll progress, the card dropping in.
- A Word looked up in this Article gets a darker (faded-ink) underline than an unlooked measured Word; the reader redraws after each tap.
