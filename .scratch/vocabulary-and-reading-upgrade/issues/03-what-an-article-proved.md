# 03: What an Article proved

**What to build:** An **Article** remembers its **Banked Result** — the **Words** it made **Known**, the **Clean Sightings** it advanced, the **Lookups** made in it — and shows it on its row. Today that answer exists for one screen after 读完 and is then gone, so an Article finished in March is indistinguishable from one never opened.

This is what gives a finished Article, and an **Archived Article**, a reason to be on the shelf.

**Blocked by:** 02 (the per-Article Clean Sighting records are what this reads; without them it would be a second count to keep in step)

**Status:** ready-for-human (the checks left need the phone)

## The rule

- [x] Finishing an Article for the first time stores what it proved, alongside the fact that it was banked
- [x] Rereading changes nothing, including this: the stored result is from the reading that earned it
- [x] The result survives archiving and restoring
- [x] It is a record of that moment, not a live query: a Word looked up next week does not rewrite what an Article proved in March
- [x] An Article banked *before this was built* has no result rather than a result of zeros — it is already banked, and the new counters arrive at their default

## The screen

- [x] An Article's row says what it gave, in a quiet line under its existing meta
- [x] An Article never finished says nothing there rather than showing zeros
- [x] Archived Articles show theirs too — it is most of the reason to look at the archived list
- [x] The student's own titles and **Source** are never translated
- [x] **Words sent back to zero are named even when something else advanced.** Under 读完 it was enough to show the good news; as a permanent record, an Article that moved one Word along and sent ten back would read "1 个词更近一步" for ever, indistinguishable from a reading with no **Lookups** in it
- [x] Phrased in one place (`BankedResultLine`), used by both the reader and the row, so the two can never word the same numbers differently. No new strings: the three the reader already had now serve both

## Tests

- [x] An Article banked with two Words reaching three sightings records two made Known
- [x] An Article whose Words were all looked up records that, and is not recorded as empty
- [x] A second 读完 leaves the stored result untouched
- [x] Archiving and restoring leaves it untouched
- [x] A Word looked up in a *later* Article does not change what an earlier one recorded
- [x] An Article banked before this feature has no result

## Glossary

- [x] **Banked Result** goes into `CONTEXT.md` once it exists

## Left for the iPhone

- [ ] **Look at the reading list as a list.** One quiet line under a button is not the same as twenty of them stacked up: if the 阅读 tab starts reading as a spreadsheet, the line belongs somewhere else, and reading is the point of that tab
- [ ] Check an Article finished before this was built shows no line at all, rather than 这篇没有新的词
- [ ] Finish an Article and check the line reads like something worth having, not like a receipt
- [ ] Check the three-part line at a large Dynamic Type size, where it has to wrap
- [ ] Open the archived list and see whether the results make it worth keeping

## Comments

Built test-first. Whole suite green at **213 tests**, up from 206.

`/code-review` found four things, and the first was the same mistake as ticket 02's, one ticket later: **a confidently wrong claim about data that already exists.** `bankedResult` keyed off `isBanked`, but every Article the student has already finished is `isBanked` with the new counters at their default of zero — so the first launch would have each of them announce 这篇没有新的词, telling the student that a reading which really did make Words Known proved nothing. Keyed off the banked day instead, which is what storing the day is for, with a test that reproduces exactly what lightweight migration leaves behind.

Worth noting the pattern, since it has now happened twice: both bugs came from a new field's default value being indistinguishable from a real answer. Any further field added to an existing record in this round wants the same question asked of it before it reaches a screen.

Also from the review:

- **Words sent back to zero were hidden** whenever anything advanced. Tolerable for a line that flashed; wrong for a permanent record, and it contradicted the `CONTEXT.md` entry added in the same change. All three parts now show when they happened.
- **The new file was untracked.** The ticket's commit would not have compiled for anyone checking it out — two screens and the tests all reference it.
- **A persisted field no screen read.** `bankedDayNumber` looked like dead weight; the fix above makes it the field the whole rule turns on.
- **A model rule living in a view file.** `bankedResult` moved onto `Article`, next to the fields it reads and the record it describes.

Not seen running: anything on the phone. The list-of-twenty question at the top of the checks above is the one I would most expect to come back needing a change.
