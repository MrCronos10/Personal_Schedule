# 08: Seal Book

**What to build:** `screens/Seals.dc.html`. `SealLibrary` (rules + tests), stamp animation, 下一枚 card, tile grid, hidden seals, and the new-seal strip on 读完.

**Blocked by:** 07, **and ADR 0010 must be marked accepted.** ADR 0010 was accepted by the student on 2026-10-06. **Status:** ready-for-human

## The rule

- [x] A seal, once earned, is stored and never removed, even if its source later changes (`EarnedSeal`; `aSealIsKeptWhenItsSourceLaterChanges` clears the Word Note that earned 问字 and checks the seal stays)
- [x] 百日 counts days with any Completion, not in a row; a test proves a gap does not reset it (`aGapDoesNotResetTheCount`: 60 days, a month off, 40 more is still 100)
- [x] No seal rule needs new tracking beyond a stored earned-date (every rule reads Articles banked, Words Known, Word Notes, Topic Known or Completion days; see "Not built" for the one that would)
- [x] Database fields have defaults, no unique fields (AGENTS.md): `EarnedSeal.sealKey` and `earnedDayNumber` both default; two rows for one seal resolve to the earlier day
- [x] Update CONTEXT.md (Seal, Seal Book) and ADR 0009's wording (done; ADR 0010 marked accepted; "Small Celebration" is now five moments)

## Comments

**Built (TDD at the library):** `Seal` (13 seals, in book order), `EarnedSeal` (the one stored row), and `SealLibrary` with `evaluate` / `earned` / `progress` / `next`. 35 tests, written first (red = `SealLibrary` did not exist); the suite is 403. Fixtures are explicit counts and word lists, never a sentence read by eye.

**Seals and their rules:** 初读 / 十篇 / 五十篇 / 百篇 (Articles banked: 1, 10, 50, 100); 百词 (100 Words Known across HSK 4, HSK 5 and the Topic List); 半程 (300 of HSK 4); 过关 (HSK 4 Passed, 480 of 600, rare); 千字文 (1,000 Words Known in all, rare); 夜读 (an Article finished between 22:00 and 04:59); 问字 (the first Word Note); 农家 (25 农业词); 农场主 (all 125 starter terms, rare; a Custom Topic Word does not stand in for one); 百日 (100 days with any Completion).

**夜读 is earned only at the moment a reading ends.** `evaluate(finishedReadingAt:)` is passed a finish time by the reader and nowhere else, so opening the Seal Book late at night earns nothing, and a reread (which banks nothing) never evaluates.

**/code-review (3 findings):**
- *(fixed, test-first)* 夜读 missed readings finished after midnight, since `hour >= 22` is false at 00:30. The night is now 22:00 to 04:59 (`finishingAfterMidnightStillCountsAsNight`, and `finishingFromFiveInTheMorningDoesNot` as the guard); the seal's line now says "between 10 pm and 5 am". The brief only said "after 22:00", so the 05:00 cut-off is my choice and easy to change.
- *(kept, known)* the reader calls `evaluate` with `try?`, so a failed save earns nothing and the finish time is gone for 夜读. A failed save would also fail `bank`, which already tells the student; I left the call as it is.
- *(by design)* opening the book can earn count-based seals with a stamp, and the 读完 strip only shows seals earned during that reading.

**Screens (phone-checked; the page was also rendered to an image and looked at, Chinese light and English dark):**
- `SealBookView` / `SealBookPage`: lacquer ground, brass count, 下一枚 card with a brass progress bar, three-per-row tiles. Earned = a red brush seal at a fixed tilt with its name and date, rare ones ringed in brass; unearned = a dashed blank, a rule, and `n/target`. A seal earned while the book is open lands with the stamp animation (250 ms, Reduce Motion fades) and one medium haptic.
- A brass-outlined 印章册 button in the Progress night band opens it as a sheet.
- 读完 shows a 新印章 strip under the result only when that reading earned one.
- 32 strings added with English.

**Not built, and why (needs you):**
- **识途 (read a photographed menu or sign).** In the brief, but the model does not record where an Article came from (`source` is free text), so it needs a new field. ADR 0010 and this ticket allow no new tracking beyond an earned day. Say if you want a small `Article` field for it and I'll add it with a test.
- **Which seals are hidden.** The brief asks for one or two "？" tiles but does not name them. The mechanism is built (`Seal.isHidden`, the "？" tile, 隐藏印章 text) and no seal is hidden yet. Tell me which, and it is a one-line change.

**Earned day is the day a seal was first noticed.** Seals are evaluated when a reading finishes and when the Seal Book opens, so a seal earned some other way (a Word Known by the swipe deck, a Word Note) is stamped, and dated, the next time one of those happens. Same-day in practice, but it can be a day late if the book is not opened.

**Not seen running / left for the phone:** opening the book from 进度, the stamp landing and haptic, the 读完 strip after a real seal, brass rings on the three rare seals, light and dark.
