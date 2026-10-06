# The Seal Book: permanent seals, never streaks

**Status:** accepted by the student, 2026-10-06. Ticket 08 of `visual-design-v2` may be built.

[ADR 0004](0004-known-is-earned-by-reading-not-by-review.md) and [ADR 0009](0009-visual-design-is-practice-book-hybrid.md) rejected badges, ranks and streaks: they punish a sick day, mark the student as behind, and turn reading into a competition. The Collection Grid is the only achievement surface.

The student asked for more fun. This ADR proposes one addition that keeps the reasons for that rejection.

## Proposal

A **Seal Book** (印章册), opened from 进度: a collection of red seals earned by things the student really did.

- **Cumulative only.** A seal is earned once and kept for ever. Nothing counts a run of days; 百日 is "100 days with any Completion", not in a row.
- **Never taken away, never time-limited, never shown as owed.** An unearned seal shows its progress and nothing about what is late.
- **Earned from facts the model already holds**: Articles banked, Words Known, Lookups, Word Notes, Topic Known, finish time. No new tracking, no new counts.
- **No points, no ranks, no comparison, no sound.** Earning one is the stamp animation and a medium haptic.
- **Passing a Level is still never a gate** (ADR 0005). 过关 is a seal, not an unlock.

## Why not the alternatives

- **Nothing new (keep ADR 0009).** Safe, but the student asked for more fun and the grid alone is quiet.
- **Streaks.** Rejected again, same grounds as 0004.

## Consequences

- CONTEXT.md gains **Seal** and **Seal Book**; the "Small Celebration" list gains a fifth moment (a seal is earned).
- ADR 0009's "no badges" is narrowed: no streak or rank badges, and seals are the one permitted collectible.
- A seal's rule lives in a library (`SealLibrary`) and is tested there, like `VocabularyLibrary`.
- If the student rejects this, delete ticket 08 and the Seal Book rows in the briefs; nothing else depends on it.
