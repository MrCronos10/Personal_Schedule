# Where HSKWordList.json came from

Taken on **21 September 2026**. Regenerate with [`.scratch/reading-and-vocabulary/build-word-list.py`](../../.scratch/reading-and-vocabulary/build-word-list.py).

The list is the **HSK 2.0** standard, levels 4 and 5, counting each level's **new** words only: 600 and 1,300. Why HSK 2.0 and not HSK 3.0, and why new rather than cumulative: [ADR 0005](../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md).

## Two sources, each for one job

| | Repo | Licence | Used for |
| --- | --- | --- | --- |
| Membership | [leonsilicon/hsk2.0](https://github.com/leonsilicon/hsk2.0) | MIT | which words are at which level |
| Pinyin and English | [drkameleon/complete-hsk-vocabulary](https://github.com/drkameleon/complete-hsk-vocabulary) | MIT | what each word means |

**Membership does not come from drkameleon**, although that repo also publishes HSK 2.0 lists. Its "old" lists give 598 and 1,298, and every level is a few words short: 150 / 297 / 595 / 1,193 / 2,491 / 4,991 against the standard's 150 / 300 / 600 / 1,200 / 2,500 / 5,000. The two repos also disagree about the level of roughly 90 words per band, so this is drift, not rounding. leonsilicon's lists total exactly 5,000 across six levels and match the standard, so they decide what is in the list; drkameleon's richer entries only say what the words mean.

## What the script does to the meanings

A tapped word gets a reminder, not a dictionary entry, so each gloss is at most 70 characters and holds one or two senses. Getting there needed four corrections, each one visible in the script:

- **Proper nouns are listed first.** CC-CEDICT gives 孙子 as "Sun Tzu" before "grandson", and capitalises the pinyin when it does. An ordinary reading is preferred.
- **Readings are grouped.** One word's senses are split across forms; where the reading is the same they belong together.
- **The richest reading wins.** 重 is zhòng "heavy" long before it is chóng "to repeat".
- **Surnames, cross-references and place names are dropped.** CC-CEDICT writes place names with hanzi inside the English — "Youhao district of Yichun city 市, Heilongjiang" — which makes them easy to spot and remove.

Ten words are written by hand in the script, where CC-CEDICT had no entry or only a sense HSK 4/5 does not mean: 弹钢琴, 百分之, 冰激凌, 名胜古迹, 后背, 拼音, 模特, 咸, 重, 空, 亚洲, 欧洲, 大厦, 纪录, 呀.

## The two grammar entries

`得（助动词）` and `等（助词）` keep their part-of-speech annotation, because that is how the official list separates them from bare 得 and 等, which belong to lower levels. Stripping the annotation would put 得 into the HSK 4 list, where it would be underlined in nearly every sentence the student ever reads and reach **Known** after three articles without meaning anything. Kept whole, they never match a word split out of an Article, and are met only in **Daily New Words**. `HSKEntry.isGrammarEntry` marks them.
