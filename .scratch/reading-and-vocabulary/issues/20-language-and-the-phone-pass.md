# 20: Language, empty states and the phone pass

**What to build:** The finish of the feature. Every new string in 中文 and English, an empty state on every new screen, the whole suite green, `/code-review` done, and a real week of use on the phone.

**Blocked by:** 14, 15, 16, 17, 18, 19

**Status:** ready-for-agent

## Language

- [ ] Every string added in tickets 12 and 14–19 exists in `Localizable.xcstrings` with its English, or the translations test fails. At least: 阅读, 导入文章, 来源, 读完, 重读 · 没有新的记录, %lld 个词已掌握, %lld 个词更近一步, 归档, 恢复, 已归档, 掌握, 已过, 今日新词, 认识, 不认识, 今天的新词看完了, 我认识这个词, 其实不认识, 不记录, 新词, HSK 4 掌握八成后开始
- [ ] The student's own writing is never translated: an Article's text, its auto-title, its 来源, and a Note. All `Text(verbatim:)`
- [ ] A **Word**'s pinyin and English come from the bundled list and are not translated either — the English *is* the content
- [ ] The word "exam", 考试, HSK as a qualification: nowhere. HSK appears only as the name of a **Word List** ([ADR 0005](../../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md), and **Goal** in CONTEXT.md)

## Empty states

Each in the same quiet voice the Daily Checklist already uses — a sentence and a way forward, never a blank screen:

- [ ] 阅读 with no Articles: what to paste and where the **+** is
- [ ] The reading screen with an Article of no HSK 4/5 Words: the text reads normally, nothing is underlined, 读完 still works
- [ ] 今日新词 with an empty pool
- [ ] The Level meter at zero (ticket 18 already covers this; check it here on a real fresh install)
- [ ] 已归档 with nothing archived

## The pass

- [ ] Run the whole suite. Note the number of tests and suites in Comments
- [ ] Run `/code-review`, fix what is real, run the suite again. If a fix changes a rule in `VocabularyLibrary`, `ArticleLibrary` or `HSKWordList`, write its test first
- [ ] Check no screen holds a second copy of a rule: every filter, sort, level count and Known check goes through the library that the tests call. This is the thing most likely to have drifted across nine tickets
- [ ] Check the database rules still hold for `Article`, `WordLookup` and `WordProgress`: every field defaulted or optional, nothing unique, relationships optional with an inverse
- [ ] Check nothing added a delete. Articles archive, Words are never removed

## Left for the iPhone

This is the real test of the feature, and none of it can be done from here:

- [ ] Use it for a week. Import something you actually met — a 微信 post, a menu, a sign
- [ ] Do you reach for the app when you find Chinese you want to read, or does it feel like homework? If it is homework, say which part
- [ ] Is 三次干净的相遇 (three clean sightings) too easy or too hard in practice? After a week you will have an opinion, and the number in ticket 16 is one line to change
- [ ] Is ten Daily New Words right?
- [ ] Does 掌握 on the Level meter match what you feel you actually know? If the app says you know a word and you cannot use it in 茶馆, ADR 0004's bet is wrong and we should know early
- [ ] Reinstall from Xcode inside seven days and check the Articles and the Known count survived
