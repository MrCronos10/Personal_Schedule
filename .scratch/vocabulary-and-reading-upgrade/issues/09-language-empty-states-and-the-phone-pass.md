# 09: Language, empty states and the phone pass

**What to build:** The finish of the round, the same way ticket 20 finished the last one. Every new string in 中文 and English, an empty state on every new screen, the whole suite green, `/code-review` done, and a real week of use on the phone.

**Blocked by:** 02, 03, 04, 05, 06, 07, 08

**Status:** ready-for-agent

## Language

- [ ] Every string added this round has its English, and the translations test is green
- [ ] The student's own writing is never translated: **Article** titles, **Source**, **Notes**, and **Word Notes**
- [ ] A Word's English gloss is content, not screen text, and stays as it is in both languages
- [ ] Nothing anywhere calls HSK an exam, a test, a qualification or a goal. HSK 4 and HSK 5 appear as list names and nowhere else (**Goal** in `CONTEXT.md`)
- [ ] Commit the rewrite Xcode makes of the string catalog, and leave any `stale` marks it adds — they are accurate

## Empty states

Each in the quiet voice the rest of the app uses — a sentence, and a way forward where there is one:

- [ ] A Word with no **Clean Sightings** yet (02)
- [ ] An Article never finished, on its row (03)
- [ ] An Article with no measured Words, so no **Readability** (04)
- [ ] No **Stubborn Words**, which is good news (05)
- [ ] A Word with no **Word Note** (05)
- [ ] Nothing recognised in a photo (07)
- [ ] The reading list with nothing in it, still reading correctly after the import sheet changed (07)

## The whole thing

- [ ] Whole suite green
- [ ] `/code-review`, and fix what is real. If a fix changes a library rule, write its test first
- [ ] `CONTEXT.md` holds exactly the terms that now exist, and no term for anything unbuilt
- [ ] Every ADR touched this round still describes what the code does

## Left for the iPhone

- [ ] Use it for a real week: import by photo, read, tap, listen, answer the day's words
- [ ] Check the 阅读 tab still opens onto *reading* — the Level meter, 今日新词, 难词 and the new Article rows all want the top of that screen, and reading is the point of it
- [ ] Switch to English and walk every new screen
- [ ] Check every new screen at a large Dynamic Type size, especially anything with a long English gloss
- [ ] Judge the round honestly: is it more inviting to open than before? If some part of it is decoration, say so and take it out
