# 10: 难词 stops scanning every Lookup ever made

**What to build:** `VocabularyLibrary.stubbornWords()` currently fetches every **Lookup** ever recorded, every time the 难词 list is asked for, to work out how many distinct **Articles** each **Word** has been looked up in. `WordLookup` rows are never deleted, so that fetch only grows, all year — the exact shape ticket 02 deliberately avoided for **Clean Sightings** in `bank()`, found by ticket 09's round-wide review and deferred rather than patched in.

A **Word**'s count of distinct Articles it has been looked up in moves onto `WordProgress` itself, kept up to date the moment a **Lookup** happens, so `stubbornWords()` becomes a plain filter over rows already in hand — no second fetch, no scan of history.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

## The rule

- [ ] `WordProgress` gains a count of distinct Articles this Word has been looked up in
- [ ] `lookUp(_:in:on:)` increments it, but only the first time *this* Word is looked up in *this* Article — a second tap on the same Word in the same reading is not a second Article, matching the decision ticket 05 already made and pinned in `CONTEXT.md`'s **Stubborn Word** entry
- [ ] The count only ever goes up. `WordLookup` rows are never deleted, so there is nothing that would ever need to bring it back down
- [ ] `stubbornWords()` no longer fetches `WordLookup` at all: a **Stubborn Word** is read straight off `WordProgress` — more than one, not **Known**
- [ ] **A Word already looked up in more than one Article before this ticket must not vanish from 难词.** The count is a new field with a default of zero, and every `WordProgress` row written before this ticket has real Lookup history the count knows nothing about. This is the same shape three earlier tickets in this round got wrong the first time — a new field's default being indistinguishable from a real answer — so a backfill computes the true count once from existing `WordLookup` rows, the same way `ArticleLibrary.backfillMeasuredWords()` and `VocabularyLibrary.backfillLevelCongratulations()` already catch up state written before their own fields existed
- [ ] The backfill runs once at app start, is safe to run again (a Word already carrying a real count is left alone), and does not need to finish before the first frame draws — 难词 reading a stale count for one launch is a cosmetic gap, not a wrong answer stored forever

## Tests

At `VocabularyLibrary`:

- [ ] A Word looked up in two different Articles has a count of two
- [ ] A second Lookup of the same Word in the same Article leaves the count at one
- [ ] `stubbornWords()` still returns the right Words, ordered the same way, with no `WordLookup` fetch in the call path (assert behaviour, not implementation, the same way the rest of this round tests library rules)
- [ ] The backfill computes the correct count for a Word with real Lookup history but no count yet
- [ ] Running the backfill twice leaves an already-correct count untouched
- [ ] A Word already Known is still excluded, exactly as it is today

## Left for the iPhone

- [ ] Open 难词 on a real install with real history right after updating, and confirm nothing that was there before has disappeared
- [ ] Look up a Word in a new Article and confirm it climbs the 难词 list exactly as it did before this change
