# 16: 读完 banks Clean Sightings

**What to build:** The rule the whole feature rests on. Pressing 读完 on an **Article** for the first time gives every HSK 4/5 **Word** in it that was not looked up one **Clean Sighting**, and returns every Word that was looked up to zero. Three Clean Sightings makes a Word **Known**.

This is the heaviest test file in the feature. Why it works this way rather than with spaced repetition: [ADR 0004](../../../docs/adr/0004-known-is-earned-by-reading-not-by-review.md).

**Blocked by:** 15

**Status:** ready-for-human (every check left needs a tap)

## The rule

`VocabularyLibrary.bank(article:lookups:progress:)`:

- [x] For every HSK 4/5 Word in the Article, counted **once** however often it appears:
  - [x] a `WordLookup` exists for that Word **and that Article** → clean sightings to `0`, and if it was Known it stays Known (a Known Word is not taken back by one tap; only 其实不认识 does that)
  - [x] no Lookup for it in this Article → clean sightings `+1`
- [x] Clean sightings reaching `3` sets known and today's known day
- [x] The Article is marked `banked`
- [x] **An Article already banked banks nothing.** Rereading proves nothing new. The 读完 button still works and still ends the **Reading Session** (ticket 17); it just moves no Word
- [x] A Lookup made during a *reread* still returns that Word to zero. Needing help with a word you had banked is real evidence, whenever it happens
- [x] Words with no `HSKWordList` entry are skipped entirely — no row is created for them

## The screen

- [x] 读完 asks nothing and shows no confirmation. ~~It hands straight on to ticket 17's Tick sheet~~ — the Tick sheet is ticket 17; for now it banks and shows the line
- [x] Above the sheet, a single quiet line says what moved: `3 个词已掌握 · 12 个词更近一步`. No animation, no celebration, no sound
- [x] Rereading a banked Article says `重读 · 没有新的记录` in the same muted voice. Not a warning

## Tests

At `VocabularyLibrary`. Every one of these is a rule from ADR 0004 and none of them should be softened to make the code simpler:

- [x] A Word appearing three times in one Article gains **one** clean sighting, not three
- [x] A Word met in three different Articles, never looked up, becomes Known on the third 读完, with a known day
- [x] A Word at two clean sightings that is looked up in the third Article goes to zero, not to three
- [x] Banking the same Article a second time changes no Word
- [x] A Word looked up in Article A but not in Article B gains its sighting from B
- [x] A Lookup belonging to a different Article does not block a sighting in this one — this is the test that catches a lookup query missing its article filter, which would silently freeze every Word the student ever tapped
- [x] A Known Word looked up again stays Known and keeps its known day
- [x] An HSK 1–3 word in the text creates no `WordProgress` row at all
- [x] A Word marked Known by hand in ticket 15 is not disturbed by a later 读完
- [x] An **Archived Article** that was banked leaves its sightings in place

## Left for the iPhone

- [ ] Read three different short articles that share a word you don't know, and watch it reach 掌握 on the third
- [ ] Tap a word on purpose in the third one and confirm it does **not** reach 掌握
- [ ] Reopen an article you have finished, press 读完 again, and check the 重读 line reads as calm rather than as an error
- [ ] Judge the `3 个词已掌握` line: is it satisfying enough without being a celebration you would tire of?

## Comments

- **The rule came out almost exactly as the ticket wrote it**, which is what a ticket written during the grilling is for. One reading, each HSK 4/5 Word once; looked up here means zero; not looked up means one more; three means **Known**; an Article banks once and no more.
- **Lookups are read off the Article's own relationship, not fetched and filtered.** The ticket warned that a lookup query missing its article filter would silently freeze every Word the student ever tapped. Rather than write that query carefully and test it, `article.lookups` removes the possibility — there is no filter to lose. `aLookupInAnotherArticleDoesNotBlockThisOne` still guards it.
- **The known day is the day the Word was got, not the day it was last read.** A Word already Known keeps its original date when a later 读完 counts it again, so the record can answer "when did I learn this" for the whole year.
- **Two counting tests were wrong before the code was.** The fixtures used Chinese titles and filler — 第一篇, 很干净 — and 篇, 干净 and 软 are all on the lists, so the sentences held more measured Words than they looked like they did. They are built from an explicit word list now, with `theFixtureContainsExactlyTheWordsItNames` guarding the helper so a future change to segmentation fails there first rather than quietly changing what the counting tests mean.
- The ticket's `bank(article:lookups:progress:)` became `bank(_:on:)` on the context-holding library, matching `lookUp` and `markKnown` beside it. The rule reads the same; passing arrays in would have meant the screen assembling them, which is where a second copy of the rule starts.

### After `/code-review`

Four findings, all taken. Two were rule changes, so their tests were written first:

- **`advanced` counted Words the student already knew.** A Word marked Known by hand sits below three sightings, so reading an Article full of them reported "10 个词更近一步" when nothing had moved and nothing on screen was underlined. The app inventing progress is the worst thing this feature could do, given the whole year is measured by one number. Now guarded, with `anAlreadyKnownWordIsNotCountedAsMoving` holding it.
- **An Article whose Words were all looked up read as "这篇没有新的词".** Both counters stay at zero when every Word is sent back, so the line said nothing happened at the exact moment the student lost the most ground. `BankResult` now carries `returnedToZero` and the line says `N 个词要重新开始`.
- **`try?` swallowed a save failure**, leaving 读完 looking like a dead button with no line and no explanation. It reports now.
- **The result line survived into the next Article.** SwiftUI reuses this screen, which is what the `task(id:)` is for; the line is cleared there with the rest of the per-Article state.

147 tests pass, 12 suites, up from 129 in 11.
