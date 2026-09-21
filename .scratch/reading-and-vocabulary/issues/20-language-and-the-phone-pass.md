# 20: Language, empty states and the phone pass

**What to build:** The finish of the feature. Every new string in 中文 and English, an empty state on every new screen, the whole suite green, `/code-review` done, and a real week of use on the phone.

**Blocked by:** 14, 15, 16, 17, 18, 19

**Status:** ready-for-human (every check left needs a tap)

## Language

- [x] Every string added in tickets 12 and 14–19 exists in `Localizable.xcstrings` with its English, or the translations test fails. At least: 阅读, 导入文章, 来源, 读完, 重读 · 没有新的记录, %lld 个词已掌握, %lld 个词更近一步, 归档, 恢复, 已归档, 掌握, 已过, 今日新词, 认识, 不认识, 今天的新词看完了, 我认识这个词, 其实不认识, 不记录, 新词, HSK 4 掌握八成后开始
- [x] The student's own writing is never translated: an Article's text, its auto-title, its 来源, and a Note. All `Text(verbatim:)`
- [x] A **Word**'s pinyin and English come from the bundled list and are not translated either — the English *is* the content
- [x] The word "exam", 考试, HSK as a qualification: nowhere. HSK appears only as the name of a **Word List** ([ADR 0005](../../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md), and **Goal** in CONTEXT.md)

## Empty states

Each in the same quiet voice the Daily Checklist already uses — a sentence and a way forward, never a blank screen:

- [x] 阅读 with no Articles: what to paste and where the **+** is
- [x] The reading screen with an Article of no HSK 4/5 Words: the text reads normally, nothing is underlined, 读完 still works
- [x] 今日新词 with an empty pool
- [x] The Level meter at zero (ticket 18 already covers this; check it here on a real fresh install)
- [x] 已归档 with nothing archived

## The pass

- [x] Run the whole suite. Note the number of tests and suites in Comments
- [x] Run `/code-review`, fix what is real, run the suite again. If a fix changes a rule in `VocabularyLibrary`, `ArticleLibrary` or `HSKWordList`, write its test first
- [x] Check no screen holds a second copy of a rule: every filter, sort, level count and Known check goes through the library that the tests call. This is the thing most likely to have drifted across nine tickets
- [x] Check the database rules still hold for `Article`, `WordLookup` and `WordProgress`: every field defaulted or optional, nothing unique, relationships optional with an inverse
- [x] Check nothing added a delete. Articles archive, Words are never removed

## Left for the iPhone

This is the real test of the feature, and none of it can be done from here:

- [ ] Use it for a week. Import something you actually met — a 微信 post, a menu, a sign
- [ ] Do you reach for the app when you find Chinese you want to read, or does it feel like homework? If it is homework, say which part
- [ ] Is 三次干净的相遇 (three clean sightings) too easy or too hard in practice? After a week you will have an opinion, and the number in ticket 16 is one line to change
- [ ] Is ten Daily New Words right?
- [ ] Does 掌握 on the Level meter match what you feel you actually know? If the app says you know a word and you cannot use it in 茶馆, ADR 0004's bet is wrong and we should know early
- [ ] Reinstall from Xcode inside seven days and check the Articles and the Known count survived

## Comments

- **The feature is closed on this machine and open on the phone.** 176 tests pass in 15 suites, up from 84 in 8 when the feature started. Everything that can be checked without a finger has been.
- **Ticket 20's own checks, each actually run rather than assumed:** no 考试 and no "exam" anywhere in the app; no `context.delete` added by this feature (the only two are the pre-existing untick and delete-Action); no screen holding a second copy of a rule — every Known check, level count, filter and sort goes through `VocabularyLibrary`, `ArticleLibrary` or `HSKWordList`, which is what the tests call; and every new field on `Article`, `WordLookup` and `WordProgress` defaulted or optional, nothing unique, the one relationship optional with an inverse.
- **Empty states** exist on all four new surfaces: 阅读 with no Articles points at the **+** and says what to paste, 今日新词 says when the pool is finished, the Level meter reads 0 / 600 rather than being hidden, and 已归档 says when there is nothing in it. An Article with no HSK 4/5 Words reads normally with nothing underlined, and 读完 still works.
- **The one thing left undone on purpose:** the Notes List. It was already on the "not in version 1" list, and it is where the prefilled reading Notes will be read back. Until it exists those Notes are only visible on the day they were written, by unticking.

### After `/code-review`

Eleven findings across tickets 17–20. The first was a real bug:

- **Answering one Word reshuffled the other nine.** The day's window was seeded off the *remaining* pool, and the pool shrinks the moment anything is answered — or the moment a word is tapped while reading. `20260921 % 600` and `20260921 % 599` land in completely different places, so the "same ten all day" the card promises broke the instant the student used it. The window is seeded off the whole Word List now and met Words are skipped, with `answeringOneWordDoesNotReshuffleTheRest` holding it.
- **今日新词 could hide ten words the student never saw.** The "all answered" check compared a dictionary that accumulates for ever against a list that is replaced after every answer, so after ten taps it declared a fresh, untouched ten already finished.
- **`try?` on 认识 / 不认识** settled the row whether or not anything was written — the same silent failure 读完 was fixed for in ticket 16.
- **The reading clock stopped and never restarted** after an offer was declined, so a second 读完 ten minutes later still reported the first figure.
- `sorted(by:)` isn't guaranteed stable, and the offer relied on stability to keep the day's order; it partitions now.
- `suggestedAction` had become unreachable once the dialog replaced preselection. Removed rather than left to drift out of step with `offer`, and its three tests moved onto `offer`.
- `HSKLevel.total` rescanned all 1,900 entries several times per row per render; per-level lists are grouped once now.
- Two `onChange` handlers fired `refresh()` twice on a single tap; one signature covers both.
- The dialog and the Tick sheet were being dismissed and presented in the same turn, which classically drops the sheet. The dialog dismisses itself now — **left on the iPhone list to confirm**.

Two low findings are **not** fixed and are written down rather than hidden: `ReadingView` still materialises every `WordProgress` row to derive a count, and the reading screen loads the whole Completion history to find today's ticks. Both are correct, both grow slowly, and both want a counting query rather than a fetch. Neither is worth churning the screens for before the phone has had a week with the feature.
