# 10: 难词 stops scanning every Lookup ever made

**What to build:** `VocabularyLibrary.stubbornWords()` currently fetches every **Lookup** ever recorded, every time the 难词 list is asked for, to work out how many distinct **Articles** each **Word** has been looked up in. `WordLookup` rows are never deleted, so that fetch only grows, all year — the exact shape ticket 02 deliberately avoided for **Clean Sightings** in `bank()`, found by ticket 09's round-wide review and deferred rather than patched in.

A **Word**'s count of distinct Articles it has been looked up in moves onto `WordProgress` itself, kept up to date the moment a **Lookup** happens, so `stubbornWords()` becomes a plain filter over rows already in hand — no second fetch, no scan of history.

**Blocked by:** None (can start immediately)

**Status:** ready-for-human (the checks left need an install over real existing history)

## The rule

- [x] `WordProgress` gains a count of distinct Articles this Word has been looked up in
- [x] `lookUp(_:in:on:)` increments it, but only the first time *this* Word is looked up in *this* Article — a second tap on the same Word in the same reading is not a second Article, matching the decision ticket 05 already made and pinned in `CONTEXT.md`'s **Stubborn Word** entry
- [x] The count only ever goes up. `WordLookup` rows are never deleted, so there is nothing that would ever need to bring it back down
- [x] `stubbornWords()` no longer fetches `WordLookup` at all: a **Stubborn Word** is read straight off `WordProgress` — more than one, not **Known**. `WordProgress` is bounded at the size of the two Word Lists (≤1,900 rows, ever), unlike `WordLookup`, so reading it in full is not the shape this ticket exists to avoid
- [x] **A Word already looked up in more than one Article before this ticket must not vanish from 难词.** A backfill computes the true count once from existing `WordLookup` rows, per Word rather than as one table-wide scan, the same way `ArticleLibrary.backfillMeasuredWords()` and `VocabularyLibrary.backfillLevelCongratulations()` already catch up state written before their own fields existed
- [x] The backfill runs once at app start, deferred to after the first frame, and is safe to run again
- [x] **`lookUp` itself never assumes a nil count means zero.** A nil count could be real, unbackfilled history — see Comments for why this had to become a rule of its own rather than resting on the backfill running first

## Tests

At `VocabularyLibrary`:

- [x] A Word looked up in two different Articles has a count of two
- [x] A second Lookup of the same Word in the same Article leaves the count at one
- [x] `stubbornWords()` still returns the right Words, ordered the same way, with no `WordLookup` fetch in the call path — covered by the existing behavioural tests from ticket 05, which continue to pass unchanged
- [x] The backfill computes the correct count for a Word with real Lookup history but no count yet
- [x] Running the backfill twice leaves an already-correct count untouched
- [x] A Word already Known is still excluded, exactly as it is today
- [x] A Word with real, unbackfilled history looked up again in a *new* Article keeps all of its history rather than losing it to a naive "zero plus one" — the regression test for the review's finding

## Left for the iPhone

- [ ] Open 难词 on a real install with real history right after updating, and confirm nothing that was there before has disappeared
- [ ] Look up a Word in a new Article and confirm it climbs the 难词 list exactly as it did before this change
- [ ] Do this on a fresh update, promptly — the very scenario the review caught (looking up an old Word again before the deferred backfill has finished) is exactly what's most likely on the first launch after installing this ticket

## Comments

Built test-first. Whole suite green at **259 tests**, up from 253.

`/code-review` found one real bug, and it's a sharp one: the ticket's own words were wrong. I'd written "难词 reading a stale count for one launch is a cosmetic gap, not a wrong answer stored forever" — reasonable-sounding, and false. `lookUp`'s first implementation assumed a nil count meant zero. A pre-ticket-10 Word with real history (say, looked up in two Articles already) sits at nil until the deferred startup backfill reaches it. If the student looks that Word up again in a *third* Article before that backfill runs — entirely ordinary, and likeliest right after updating, which is exactly when the backfill queue is longest — `lookUp` would compute `(nil ?? 0) + 1 = 1`, discarding the two real Articles. Worse: the backfill's own guard is `stubbornArticleCount == nil`, so once the row reads `1` instead of `nil`, the backfill would skip it forever, having no way left to tell it was ever wrong. "Cosmetic and temporary" was actually "permanent and silent."

Fixed by removing the assumption rather than reordering the startup Task to close the race: `lookUp` now resolves a nil count from the Word's real history — scoped to that one Word, not a table scan — before treating it as a base to add one to, and does so *before* inserting the current Lookup so the resolved count can never double-count the very Article being looked up. This means correctness no longer depends on which order two independent things happen to run in, which is a better guarantee than winning the race would have been. The backfill still exists and still matters: without it, 难词 would only ever repair a Word's count when that Word happens to be looked up again, which could be a long wait for a Word that's simply never revisited. The per-word count logic itself is now shared between `lookUp`'s self-heal and the backfill (`distinctArticleLookupCount(of:)`), so there is exactly one place that answers "how many Articles has this Word really been looked up in."

Not seen running: anything on the phone, and per the note above, the very first launch after this ships is the highest-risk moment to test — looking up an old Word again promptly, before the deferred backfill has necessarily finished, is precisely the scenario that was broken.
