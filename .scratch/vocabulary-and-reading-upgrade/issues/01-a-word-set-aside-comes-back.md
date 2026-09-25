# 01: A Word set aside comes back after thirty days

**What to build:** The fix to a hole that made the **Level** unfinishable. A **Word** that is not **Known** and has not moved for thirty days is offered in **Daily New Words** again — however it stopped: answered 不认识, looked up while reading, or read without reaching three **Clean Sightings**. It keeps the sightings it had.

Why this is not the spaced repetition [ADR 0004](../../../docs/adr/0004-known-is-earned-by-reading-not-by-review.md) turned down: [ADR 0006](../../../docs/adr/0006-a-word-set-aside-comes-back.md).

**Blocked by:** None (can start immediately)

**Status:** ready-for-human (the two checks left need the phone, and one needs edited dates)

## The rule

- [x] A **Set Aside** Word becomes offerable again thirty days after it last moved, and not before
- [x] The clock starts on 不认识, on a **Lookup**, and on finishing an Article that touched the Word
- [x] A Word part-way to Known is included: one stalled at one or two sightings would otherwise never be offered again, which is the same hole reached through reading
- [x] A Word offered again keeps its Clean Sightings — another chance, never a reason to lose earned evidence
- [x] A **Known** Word is never offered, whatever else is true of it
- [x] A row with no set-aside day at all counts as waited out, so the fix reaches Words already sitting in the student's install
- [x] The rule lives in one place (`VocabularyLibrary.isOfferable`), so the screen and the tests cannot disagree about it

## The screen

- [x] 今日新词 tells its two empty days apart: 今天没有新词 when everything left is inside its wait, and 这一级的词都见过了 only when the **Served Level** has nothing left to learn
- [x] Neither line carries a count of what is waiting or a date it returns. A Set Aside Word is never due, and a number there would be the queue ADR 0004 turned down
- [x] Both strings have their English

## Tests

- [x] Set aside the whole of HSK 4 and the pool is empty for twenty-nine days, then full again on the thirtieth
- [x] A Word answered 不认识 leaves today's ten at once
- [x] A part-way Word waits the same thirty days, then is offerable, with its sightings intact
- [x] A Known Word is never offerable, even a year later
- [x] A row with no set-aside day is offerable, exercising that branch rather than "no row at all"
- [x] The day's ten still don't reshuffle when one is answered

## Left for the iPhone

- [ ] Read 今天没有新词 on a real empty day and check it reads calmly rather than broken
- [ ] Confirm a returning Word really appears, which means editing a stored date to fake the thirty days

## Comments

Built test-first, one rule per cycle. Whole suite green at **202 tests**.

`/code-review` found five things, all real, all fixed:

1. **The part-way hole.** The first implementation only re-offered Words at *zero* sightings, which recreated the identical stall for a Word read cleanly once and never met again. Widened to "not Known and not moved for thirty days", which made the rule simpler. ADR 0006 and `CONTEXT.md` were updated to match. Accepted trade-off: 认识 on a two-sighting Word now skips its third Article, which is the manual override ADR 0004 already allows everywhere.
2. **The empty state lied.** 这一级的词都见过了 was shown when the pool was merely waiting. Split into two cases.
3. **Duplicate rows.** The rewrite picked an arbitrary row per Word where the old code was duplicate-safe. Now keeps the most-progressed row, which matters once iCloud sync is on and nothing in the store is unique.
4. **A test could pass vacuously.** The pre-ADR migration test relied on an unsaved insert and could have passed on the wrong branch. Now saves.
5. **Glossary ahead of the code.** Seven new terms had been written into `CONTEXT.md` for work not yet built — the same divergence ADR 0006 exists to condemn. Six were pulled back out; each returns with its own ticket.

Not seen running: anything on the phone. Both items above are untested outside the suite.
