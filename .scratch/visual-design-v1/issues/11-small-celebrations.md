# 25: Small Celebrations — the four quiet moments

**What to build:** Four moments the app marks, each with a different
visual vocabulary so they stay distinct. No sound on any of them.

1. **Reading Session banks** — a brush-stroke 读 seal fades up from the
   bottom of the reader, holds for 600ms, fades out. Light haptic.
2. **A Word crosses to Known** — the cell inks itself on the Collection
   Grid with the 300ms brush-stroke animation (shipped in ticket 18); if
   the student isn't on Progress at the time, the next visit shows a
   1s grid-red glow around the freshly-inked cells.
3. **Daily reading goal hit** — the first time per day the student
   crosses the goal set in Settings (default 200 字), a seal-red seal
   stamps the Today header. Medium haptic.
4. **All today's Routines done** — the Daily Checklist's routine rows
   fold into a single "今天 — 完成" cream card with a thin bamboo-green
   tick. The card stays until tomorrow. Light haptic.

Vocabulary: **Small Celebration** in [CONTEXT.md](../../../CONTEXT.md).
Why no streaks or badges: [ADR 0004](../../../docs/adr/0004-known-is-earned-by-reading-not-by-review.md),
[ADR 0009](../../../docs/adr/0009-visual-design-is-practice-book-hybrid.md).

**Blocked by:** [18](04-collection-grid.md),
[20](06-reading-restyle.md),
[22](08-today-restyle.md).

**Status:** ready-for-agent

## The rule

- [ ] On 读完 banking a `ReadingSession`, the reader renders a brush-
      stroke 读 seal that fades up over 200ms, holds for 600ms, fades
      out over 200ms. A light `UIImpactFeedbackGenerator` fires once
- [ ] The cell-ink animation and the next-visit glow are the ticket 18
      implementation — this ticket only confirms the glow fires once
      per freshly-inked cell per visit, not every time Progress reopens
- [ ] On the first `ReadingSession` of the day whose cumulative characters
      cross the Settings reading goal, a seal-red seal stamps the Today
      header. The stamp fires once per day — the next session the same
      day fires nothing. A medium haptic fires with it
- [ ] On the moment the last Routine for the day is ticked, the Daily
      Checklist's routine rows animate into a single cream card with a
      bamboo-green tick and the text "今天 — 完成". A light haptic fires.
      Untick a Routine and the fold undoes
- [ ] A rule `celebrationsFiredToday` lives at the library (not in the
      view) so the "once per day" condition is tested, not peeked at
- [ ] Nothing in this ticket touches `WordProgress`, `CleanSighting`,
      `WordLookup` or `TopicWordProgress` — celebrations are a surface,
      never evidence

## What is not in this ticket

- A streak day, a weekly review celebration, or a badge collection.
  ADR 0004 and ADR 0009 are explicit about these not shipping.
- A sound. The app stays silent.
- An opt-out setting for haptics. If the student mutes haptics
  system-wide, iOS handles it.

## Comments
