# 08: Seal Book

**What to build:** `screens/Seals.dc.html`. `SealLibrary` (rules + tests), stamp animation, 下一枚 card, tile grid, hidden seals, and the new-seal strip on 读完.

**Blocked by:** 07, **and ADR 0010 must be marked accepted.** If it is not, stop and ask the student. **Status:** blocked

## The rule

- [ ] A seal, once earned, is stored and never removed, even if its source later changes (same reason as a Completion keeping its own copy, ADR 0002)
- [ ] 百日 counts days with any Completion, not in a row; a test proves a gap does not reset it
- [ ] No seal rule needs new tracking beyond a stored earned-date
- [ ] Database fields have defaults, no unique fields (AGENTS.md)
- [ ] Update CONTEXT.md (Seal, Seal Book) and ADR 0009's wording

## Comments
