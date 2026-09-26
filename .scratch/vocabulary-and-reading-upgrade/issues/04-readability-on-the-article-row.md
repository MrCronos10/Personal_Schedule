# 04: Readability on the Article row

**What to build:** Each **Article** row says what share of its measured **Words** the student already has **Known**. A menu with twenty-five unknown HSK 5 Words is the most discouraging possible sitting — twenty-five **Lookups** and no progress — and today there is no way to see it coming, or to watch the same Article get easier across the year.

**Readability** is information and never a gate. No Article is locked, hidden, reordered or marked too hard: [ADR 0005](../../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md) rejected that outright, and an app that refused to open the menu in the student's hand would be absurd.

**Blocked by:** None (can start immediately)

**Status:** ready-for-human (the checks left need the phone)

## The rule

**Recomputed differently from how this was written, and better.** "After each 读完" was in the original text, but an Article can only ever bank once, so that would freeze Readability the moment an Article was first finished — even as its Words later turn Known through **Daily New Words** or another Article. That directly breaks "so it moves as the year goes on," so Readability is instead derived live from whatever is Known *right now*, every time it's asked, over a Word list cached once at import (the part actually worth caching, since text never changes after that).

- [x] Readability is the share of an Article's measured Words that are **Known**, counted once per distinct Word however often it appears
- [x] Words the app does not measure — HSK 1–3, names, numbers — are not in the denominator
- [x] An Article with no measured Words at all has no Readability, and says nothing rather than 0%
- [x] The expensive part — tokenizing the text — is stored, not redone on every render; the cheap part — which of those Words are Known now — is derived live, so a Word turning Known anywhere raises the share of every Article holding it, immediately
- [x] An Article with no cached word list (imported before this field existed) still answers correctly, by falling back to tokenizing on the spot rather than reading as unmeasured
- [x] That fallback is backfilled once at app start (`ArticleLibrary.backfillMeasuredWords()`, alongside `DayMigration`), so it is a one-time gap, not a standing cost paid on every render for the rest of the year

## The screen

- [x] The share sits on the Article's row, quiet, next to the existing meta — worded exactly as `LevelMeterView` already words a share (`· 65%`), so the app doesn't invent a second way to say the same kind of number
- [x] Nothing in the list is ordered, greyed, badged or hidden by it
- [x] Archived rows show it too
- [x] No new strings: the percentage is a bare number, `Text(verbatim:)`, the same as the Level meter

## Tests

Build the fixture from an explicit word list, and check what it actually contains: 干净 turned out **not** to be on the bundled list despite looking exactly like the ordinary-looking words this warning is about — the first draft of these tests trusted it by eye and got 0.333 instead of 0.25.

- [x] The fixture is checked against `VocabularyLibrary.hskWords` before any share built from it is trusted
- [x] An Article of four measured Words with one Known reads one quarter
- [x] A Word repeated nine times counts once — checked with a *second*, unrepeated, unknown Word in the fixture, since a single repeated Word can't tell dedup apart from not dedup (both read 1)
- [x] Unmeasured words change neither numerator nor denominator
- [x] An Article with no measured Words has no Readability rather than zero
- [x] A Word turning Known raises the share of every Article holding it, live, with no rebuild step
- [x] An Article with no cached word list still computes correctly
- [x] The backfill fills in exactly the Articles missing the cache, and running it again touches nothing already cached

## Glossary

- [x] **Readability** goes into `CONTEXT.md` once it exists

## Left for the iPhone

- [ ] Check the number reads as encouragement rather than as a grade
- [ ] Confirm the reading list still reads as a list of things to read, not a scoreboard
- [ ] Confirm the meta line still wraps sensibly at a large Dynamic Type size with a source, a date and a percentage all on it
- [ ] Watch an Article's share actually rise after answering a shared Word in 今日新词, without reopening that Article

## Comments

Built test-first. Whole suite green at **222 tests**, up from 213.

The ticket's own text asked for something that would have broken its own goal: "recomputed after each 读完" cannot work once an Article can only bank once, since that freezes the number the moment it's first earned. Rewritten before implementation, not discovered by review this time — the last two tickets' bugs were both a value going stale the instant something changed elsewhere, and this ticket was written with that shape already in mind. Readability is now derived live from a cached Word list plus whatever's Known right now, so it moves the moment any reading anywhere makes a shared Word Known.

`/code-review` still found two things:

1. **The migration gap I did leave.** The fallback for an Article with no cached word list was correct but never backfilled, so it would have re-tokenized that Article's full text on every render, forever — for every Article already in the student's install. Fixed with `ArticleLibrary.backfillMeasuredWords()`, wired into `PersonalScheduleApp.init()` next to `DayMigration`, best-effort rather than fatal since a missing cache is slow, not wrong.
2. **A test that couldn't fail.** `aWordRepeatedNineTimesCountsOnce` used one Known word repeated nine times, which reads 1 whether or not repeats are deduplicated. Fixed by adding a second, unrepeated, unknown word, so the deduped and non-deduped answers actually differ (0.5 vs 0.9).

Not seen running: anything on the phone, including whether the meta line wraps sensibly with a source, a date and a percentage all competing for one line at a large Dynamic Type size.
