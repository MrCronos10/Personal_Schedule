# Where HSKWordList.json came from

Taken on **21 September 2026**. Rebuild it byte for byte with:

```sh
cd .scratch/reading-and-vocabulary
./fetch-sources.sh && python3 build-word-list.py
```

`fetch-sources.sh` pins the upstream commit of each source, so a change made to one of those repos tomorrow cannot quietly change the student's word list.

The list is the **HSK 2.0** standard, levels 4 and 5, counting each level's **new** words only: 600 and 1,300. Why HSK 2.0 and not HSK 3.0, and why new rather than cumulative: [ADR 0005](../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md).

## Three sources, each for one job

| | Repo | Licence | Used for |
| --- | --- | --- | --- |
| Membership | [leonsilicon/hsk2.0](https://github.com/leonsilicon/hsk2.0) | MIT | which words are at which level |
| Readings | [clem109/hsk-vocabulary](https://github.com/clem109/hsk-vocabulary) | MIT | the pinyin and sense HSK means |
| Fallback | [drkameleon/complete-hsk-vocabulary](https://github.com/drkameleon/complete-hsk-vocabulary) | MIT | the 44 words clem109 doesn't carry |

**Membership comes from leonsilicon**, although drkameleon also publishes HSK 2.0 lists. Its "old" lists give 598 and 1,298, and every level is short: 150 / 297 / 595 / 1,193 / 2,491 / 4,991 against the standard's 150 / 300 / 600 / 1,200 / 2,500 / 5,000. The two also disagree about the level of roughly 90 words per band, so this is drift, not rounding. leonsilicon totals exactly 5,000 across six levels.

**Readings come from clem109**, and this matters more than it looks. Nearly a third of HSK 4 and 5 is single characters, and a character's pronunciation depends on which sense is meant. CC-CEDICT lists every reading with no idea which one HSK wants, so choosing from it alone produced 圈 as `juān` (a pen for animals) rather than `quān` (a circle), 切 as `qiè` rather than `qiē`, 数 as `shǔ` rather than `shù`, 丑 as "clown" rather than "ugly", and 克 as "to subdue" rather than "gram". **A wrong pinyin is worse than none**: it teaches the student the wrong word, and they then bank three **Clean Sightings** on it without ever finding out. clem109's lists are already split per HSK level, so someone has already chosen the reading. `HSKWordListTests` holds the once-wrong readings down by name.

## What the script does to the meanings

A tapped word gets a reminder, not a dictionary entry, so each gloss is at most 70 characters and holds one or two senses. Three things have to be cleaned up:

- **clem109 split its senses on commas**, including the commas inside brackets, so "to hold (a meeting, ceremony etc)" arrives in two pieces. They are put back together rather than thrown away.
- **Surnames, cross-references, classifier notes and place names are dropped.** CC-CEDICT writes place names with hanzi inside the English — "Youhao district of Yichun city 市, Heilongjiang" — which makes them easy to spot.
- **A gloss cut at the length limit never ends mid-bracket.** An unclosed parenthetical is dropped rather than truncated into.

Forty-one words are written by hand in the script: seven that no source carries, two whose only entry was "variant of" itself, and the single characters whose ambiguity the fallback would otherwise have to guess at. Each of those was checked against its HSK sense one at a time. The build **stops** rather than shipping a word with no usable gloss, and asserts the two totals before it writes anything.

## The two grammar entries

`得（助动词）` and `等（助词）` keep their part-of-speech annotation, because that is how the official list separates them from bare 得 and 等, which belong to lower levels. Stripping the annotation would put 得 into the HSK 4 list, where it would be underlined in nearly every sentence the student ever reads and reach **Known** after three articles without meaning anything. Kept whole, they never match a word split out of an Article, and are met only in **Daily New Words**. The generator marks them with `"g": true` and `HSKEntry.isGrammarEntry` reads that flag, rather than guessing from the word's spelling.
