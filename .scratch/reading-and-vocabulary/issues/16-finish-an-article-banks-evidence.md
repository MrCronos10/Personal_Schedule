# 16: 读完 banks Clean Sightings

**What to build:** The rule the whole feature rests on. Pressing 读完 on an **Article** for the first time gives every HSK 4/5 **Word** in it that was not looked up one **Clean Sighting**, and returns every Word that was looked up to zero. Three Clean Sightings makes a Word **Known**.

This is the heaviest test file in the feature. Why it works this way rather than with spaced repetition: [ADR 0004](../../../docs/adr/0004-known-is-earned-by-reading-not-by-review.md).

**Blocked by:** 15

**Status:** ready-for-agent

## The rule

`VocabularyLibrary.bank(article:lookups:progress:)`:

- [ ] For every HSK 4/5 Word in the Article, counted **once** however often it appears:
  - [ ] a `WordLookup` exists for that Word **and that Article** → clean sightings to `0`, and if it was Known it stays Known (a Known Word is not taken back by one tap; only 其实不认识 does that)
  - [ ] no Lookup for it in this Article → clean sightings `+1`
- [ ] Clean sightings reaching `3` sets known and today's known day
- [ ] The Article is marked `banked`
- [ ] **An Article already banked banks nothing.** Rereading proves nothing new. The 读完 button still works and still ends the **Reading Session** (ticket 17); it just moves no Word
- [ ] A Lookup made during a *reread* still returns that Word to zero. Needing help with a word you had banked is real evidence, whenever it happens
- [ ] Words with no `HSKWordList` entry are skipped entirely — no row is created for them

## The screen

- [ ] 读完 asks nothing and shows no confirmation. It hands straight on to ticket 17's Tick sheet
- [ ] Above the sheet, a single quiet line says what moved: `3 个词已掌握 · 12 个词更近一步`. No animation, no celebration, no sound
- [ ] Rereading a banked Article says `重读 · 没有新的记录` in the same muted voice. Not a warning

## Tests

At `VocabularyLibrary`. Every one of these is a rule from ADR 0004 and none of them should be softened to make the code simpler:

- [ ] A Word appearing three times in one Article gains **one** clean sighting, not three
- [ ] A Word met in three different Articles, never looked up, becomes Known on the third 读完, with a known day
- [ ] A Word at two clean sightings that is looked up in the third Article goes to zero, not to three
- [ ] Banking the same Article a second time changes no Word
- [ ] A Word looked up in Article A but not in Article B gains its sighting from B
- [ ] A Lookup belonging to a different Article does not block a sighting in this one — this is the test that catches a lookup query missing its article filter, which would silently freeze every Word the student ever tapped
- [ ] A Known Word looked up again stays Known and keeps its known day
- [ ] An HSK 1–3 word in the text creates no `WordProgress` row at all
- [ ] A Word marked Known by hand in ticket 15 is not disturbed by a later 读完
- [ ] An **Archived Article** that was banked leaves its sightings in place

## Left for the iPhone

- [ ] Read three different short articles that share a word you don't know, and watch it reach 掌握 on the third
- [ ] Tap a word on purpose in the third one and confirm it does **not** reach 掌握
- [ ] Reopen an article you have finished, press 读完 again, and check the 重读 line reads as calm rather than as an error
- [ ] Judge the `3 个词已掌握` line: is it satisfying enough without being a celebration you would tire of?
