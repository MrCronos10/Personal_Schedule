# A Topic List sits beside the HSK Levels

The student is preparing for a family business in Cambodia: turning chicken and
pig manure into organic fertilizer. That gives them a working vocabulary of
roughly 125 Chinese words — 鸡粪, 堆肥, 发酵, 氮磷钾, 肥料厂, 农业机械 — that are
not on the HSK 4 and HSK 5 lists the app measures by, and that the HSK lists
will not deliver even eventually. The app adds a **Topic List**, with its own
meter, next to the HSK **Levels**.

[ADR 0005](0005-levels-measure-a-fixed-list-and-never-gate-reading.md) said in
writing that adding the student's own words would be "a separate feature with a
separate number, not this one." This is that feature.

## The two meters never mix

The HSK number is the student's year. Six hundred Words out of 600, 1,300 out
of 1,300: a denominator fixed for the year, so the number can only ever go up.
Folding fertilizer words in would change what that number means. So the Topic
List is a separate structure end to end — its own bundle, its own progress
rows, its own screen, its own library — and nothing it does writes to a
`WordProgress` row or moves a `LevelProgress`. A word on both lists, such as
农业, keeps independent state in each.

The matching Swift test
`TopicLibraryTests.markingATopicWordNeverTouchesTheHSKRow`
is the one that fails first if that line is ever crossed.

## Hand first; reading next

The Topic List ships with the hand path only: 认识 marks a term **Topic Known**,
其实不认识 takes it back. The reason is practical. Reading-based evidence —
tokenising an Article for Topic Words, banking Clean Sightings against the
Topic List, flowing through 读完 — reaches deep into the reading pipeline and
is a ticket of its own. The student wants to start learning now, and the hand
path lets them.

ADR 0004's reasoning for not building a flashcard deck does not break here: the
Topic List is 125 words the student chose, not a 1,900-word deck. The daily
"20 new words" machine that ADR 0004 was afraid of is nowhere in sight. If a
tap-only list turns out to be the quiet-abandonment thing ADR 0004 warned
about, we add the reading path and ADR this change again.

## A hybrid list

The 125 bundled terms are hand-written in `.scratch/topic-list/build-topic-list.py`
and shipped as `PersonalSchedule/Vocabulary/TopicWordList.json`, the same
shape as `HSKWordList.json`. Unlike that list, no public repo carries this
vocabulary with the right senses, so the script writes them itself. The totals
(125 overall; 18 / 17 / 27 / 18 / 22 / 23 across six **Topic Groups**) are
asserted in the script and pinned by `TopicWordListTests`.

The student can add **Custom Topic Words** on top. A Custom Topic Word raises
the denominator by one and the Known count by none, and is archived rather
than deleted — the same rule Categories, Routines and Articles follow. A term
from the bundled list is never archived or edited: the student restores a word
they put away themselves.

## Considered Options

- **Fold fertilizer words into the HSK Levels.** The simplest possible build.
  Rejected: it changes the HSK denominator mid-year, which is the one thing
  ADR 0005 fixed.
- **A standalone glossary outside the app.** A doc of 125 words the student
  reads elsewhere. Rejected: the student explicitly wants this in the app, and
  the whole value is the hand-marked progress against a known total.
- **Build reading-based evidence immediately.** The honest version of the
  Topic List: finish an Article, bank Clean Sightings against the Topic List
  too. Deferred, not rejected. Reading touches `VocabularyLibrary.segment`,
  `ArticleLibrary.add`, 读完 banking, and the reader screen; it is a ticket of
  its own, with its own test fixtures.

## Consequences

- The schema grows by two tables: `TopicWordProgress` (one row per Known term)
  and `TopicCustomWord` (one per added term). Both have defaults on every
  field, so turning iCloud on later needs no migration.
- A new tab, 农业词, sits between 阅读 and 笔记. It is the only place the Topic
  List is shown.
- The HSK code is untouched. The two libraries have no coupling; one can be
  rewritten without the other.
- The student never writes the HSK word 农业 twice: that word has a Topic row
  and an HSK row, each with its own history. Deliberately parallel, so the
  rule they are each measured by stays simple.
