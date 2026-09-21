# 13: The bundled HSK 2.0 Word Lists

**What to build:** Two **Word Lists** shipped inside the app as one read-only JSON file: HSK 4 (600 new words) and HSK 5 (1,300 new words) from the HSK 2.0 standard, each word with pinyin and English. A small `HSKWordList` type loads it once and answers two questions: what level is this word, and what does it mean.

No network, no dictionary API, nothing the student can edit. Why this list and not HSK 3.0, and why new words rather than cumulative: [ADR 0005](../../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md).

**Blocked by:** —

**Status:** ready-for-human (nothing to tap; the size check is left)

## Getting the list

- [x] ~~Take the HSK 2.0 **exclusive** lists from [drkameleon/complete-hsk-vocabulary](https://github.com/drkameleon/complete-hsk-vocabulary)~~ — **changed during the work.** Membership comes from [leonsilicon/hsk2.0](https://github.com/leonsilicon/hsk2.0); drkameleon supplies only pinyin and English. See Comments and `SOURCE.md`
- [x] **Verify the counts before going further.** This ticket assumes HSK 4 = 600 and HSK 5 = 1,300. If the source disagrees, stop and say so: the totals are the denominator of the year's headline number, and ADR 0005 and CONTEXT.md both name them — **the first source disagreed, and that is why it was changed**
- [x] Reduce to exactly what is needed and commit it as `PersonalSchedule/Vocabulary/HSKWordList.json`:
  ```json
  [ { "w": "安排", "p": "ānpái", "e": "to arrange; arrangement", "l": 4 } ]
  ```
- [x] Simplified characters only. If an entry carries several English senses, keep the first two and drop the rest: this is a reminder while reading, not a dictionary
- [x] Record the source repo, its licence and the day it was taken in a `PersonalSchedule/Vocabulary/SOURCE.md`, so a future disagreement about a word can be traced

## The loader

- [x] `HSKWordList` loads the JSON from the bundle once, lazily, and holds it in a dictionary keyed by word
- [x] `HSKWordList.level(of: "安排")` → `4`, and `nil` for a word not in either list
- [x] `HSKWordList.entry(for:)` → pinyin and English, or `nil`
- [x] `HSKWordList.words(at: .four)` → all 600, in the list's own order
- [x] It is a value read from disk, not a SwiftData record. Nothing in the database ever stores a word's pinyin or English: a **WordProgress** row stores only the word itself

## Tests

At `HSKWordList`, which is where the rule lives:

- [x] HSK 4 holds exactly 600 words and HSK 5 exactly 1,300
- [x] No word appears in both lists
- [x] A known HSK 4 word resolves to level 4 with non-empty pinyin and English
- [x] A known HSK 5 word resolves to level 5
- [x] An HSK 1–3 word such as 很 resolves to `nil`, not to a level. This is ADR 0005's boundary and is the test most likely to catch a cumulative list being loaded by mistake
- [x] A word that is not Chinese at all resolves to `nil`
- [x] Every entry has a non-empty word, pinyin and English: no blanks smuggled in by the reduction step

## Left for the iPhone

- [x] Nothing. There is no screen in this ticket
- [x] Check the app's installed size after the JSON is added, and note it in Comments. If it is over about 1 MB, the reduction step kept too much — **124 KB**, checked from here, no phone needed

## Comments

- **The source named in the ticket was wrong, and the ticket's own stop-and-say-so check caught it.** `drkameleon/complete-hsk-vocabulary`'s "old" lists give 598 and 1,298, and every HSK 2.0 level there is short: 150 / 297 / 595 / 1,193 / 2,491 / 4,991 against the standard's 150 / 300 / 600 / 1,200 / 2,500 / 5,000. The two repos also disagree about the level of roughly 90 words per band, so it is drift rather than rounding. `leonsilicon/hsk2.0` totals exactly 5,000 across six levels. Membership now comes from leonsilicon and the meanings from drkameleon; both are MIT. `SOURCE.md` records this so the next disagreement about a word can be traced.
- **The denominators in ADR 0005 and CONTEXT.md did not move.** 600 and 1,300 were right; only the repo that could supply them changed. Had the real number been 598, this ticket would have stopped rather than quietly rewriting the year's headline figure.
- **Four passes over the meanings, each one a real defect found by reading the output.** CC-CEDICT lists proper nouns first (孙子 was "Sun Tzu", not "grandson"); one word's senses are split across forms that need grouping; the richest reading has to win (重 was chóng "to repeat", not zhòng "heavy"); and surnames, cross-references and place names had to go — those are easy to spot because CC-CEDICT writes them with hanzi inside the English, as in "Youhao district of Yichun city 市, Heilongjiang". Fifteen words are written by hand where there was no entry or only a sense HSK 4/5 does not mean.
- **The two grammar entries were a judgement, not a rule the ticket gave.** The official list separates 得（助动词）from bare 得 by part of speech. Stripping the annotation would have put 得 in the HSK 4 list, underlined in nearly every sentence and **Known** after three articles for nothing. They are kept whole, marked by `HSKEntry.isGrammarEntry`, so they never match a word split out of an Article and are met only in **Daily New Words**. This holds HSK 4 at 600. It is two words out of 1,900 and cheap to reverse, so no ADR.
- **The generator was shipping inside the app.** `PersonalSchedule/` is a file-system synchronized group, so `build_list.py` was copied into `PersonalSchedule.app` as a resource. It now lives at `.scratch/reading-and-vocabulary/build-word-list.py`, outside the target. The bundle was checked afterwards: the JSON is there, the script is not. Anything dropped into `PersonalSchedule/` ships, which is worth remembering for later tickets.
- **Size:** `HSKWordList.json` is 124 KB, well under the 1 MB the ticket set. The app is 45 MB, almost all of it the two Noto Serif SC faces.
- **One red-green cycle, not several.** The nine tests were written first and failed to compile, which is the red; `HSKWordList` was then written once and all nine passed. There is only one rule here — what is in the list and what it says — so splitting it into smaller cycles would have been theatre. The test that matters most is `anHSKOneToThreeWordIsNotInAnyList`: it is what catches a cumulative list being bundled by mistake, which is a failure that otherwise looks like nothing at all.
- 94 tests pass, 9 suites, up from 84 in 8.
- No screen and no new strings, so `Localizable.xcstrings` is untouched and the translations test is unaffected.
