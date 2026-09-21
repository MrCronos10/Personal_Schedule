# 18: The Level meter

**What to build:** The year's headline number, at the top of the 阅读 tab. Two rows — HSK 4 out of 600 and HSK 5 out of 1,300 — each showing how many **Words** are **Known**. A **Level** is **Passed** at four fifths, and passing HSK 4 makes HSK 5 the **Served Level**. Nothing is ever locked.

**Blocked by:** 16

**Status:** ready-for-human (every check left needs a tap)

## The rule

`VocabularyLibrary.level(_:progress:)` returns known, total and whether it is Passed:

- [x] Known is counted against the **whole Word List**, not against the Words that happened to appear in the student's Articles. A Word with no `WordProgress` row counts as not Known ([ADR 0005](../../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md))
- [x] HSK 4 is out of 600 and HSK 5 out of 1,300 — new words at that level, not cumulative
- [x] Passed is `known * 5 >= total * 4`. Integer arithmetic, so 479/600 is not Passed and 480/600 is
- [x] `servedLevel(progress:)` is HSK 4 until HSK 4 is Passed, then HSK 5. That is the **only** thing passing changes
- [x] The number can only go up, except when the student says 其实不认识 themselves

## The screen

- [x] Two rows at the top of the 阅读 tab, above the Article list, on a Stitch card
- [x] Each row: the list's name, a bar, and `412 / 600 · 69%` in muted type. The bar is the same red-ink-on-paper idea as the 进度 tab's, at the same weight — **no new colour and no new component**
- [x] A Passed Level carries 已过 in the green chip introduced in ticket 12, and keeps its bar full
- [x] The Level that is **not** served sits at lower contrast, with a quiet line: `HSK 4 掌握八成后开始`. It is not greyed out, not locked, and carries no lock icon. Its bar still moves whenever one of its Words turns up in an Article and is learned
- [x] Tapping a row does nothing. A browsable word list is a later ticket
- [x] The word for a Known Word on screen is 掌握. The word "exam", in either language, appears nowhere

## Tests

At `VocabularyLibrary`:

- [x] An empty store reports `0 / 600` and `0 / 1300`, not a crash and not an empty screen
- [x] Known Words at level 4 do not count toward level 5
- [x] 479/600 is not Passed; 480/600 is
- [x] The served level is HSK 4 at 479 and HSK 5 at 480
- [x] The served level is still HSK 5 once HSK 5 is itself Passed — there is no level 6 to fall off the end into
- [x] A Word Known at HSK 5 while HSK 4 is unpassed still counts toward HSK 5's number. Words are never held back from counting, only from being served
- [x] Marking a Known Word 其实不认识 lowers the count by one and can un-Pass a Level

## Left for the iPhone

- [ ] Look at the two rows on a fresh install and judge whether `0 / 600` reads as a start or as a rebuke
- [ ] Check the unserved HSK 5 row reads as *later*, not as *forbidden* — this is the single most important judgement in the ticket
- [ ] Check the bar is legible at very low percentages, where a year of real reading will actually sit
- [ ] Switch to English and check `已过` and the served-level hint both read naturally
