# 14: Import an Article, and the 阅读 tab

**What to build:** A fourth tab, 阅读, holding the list of **Articles** and a **+** that imports one by pasting text. The title comes from the first line, the **Source** is optional, and an Article is **archived, never deleted**.

**Blocked by:** 12 (the Stitch look), 13 (the Word Lists)

**Status:** ready-for-human (every check left needs a tap)

## The record

- [x] `Article`: title, text, source (optional), imported day, archived (yes/no), banked (yes/no). Following the database rules in [plan-v1.md](../../../docs/plan-v1.md): every field has a default or is optional, nothing unique
- [x] `banked` belongs to ticket 16 and is written now only so the store is not migrated twice. Nothing reads it yet

## Importing

- [x] **+** opens a 导入文章 sheet: a large text box, an optional 来源 field, and 保存
- [x] The title is the first line of the pasted text, trimmed, cut at 30 characters with an ellipsis. It is **not** editable in this ticket: import must be one paste and one button
- [x] If the text has no first line worth using — empty, or whitespace only — 保存 is refused with the message sitting where the Category errors sit
- [x] The student's own 来源 text is never translated: `Text(verbatim:)`
- [x] Nothing is segmented and no Word is touched at import. That is ticket 15

## The list

- [x] The 阅读 tab's header is 阅读 in 田字格 boxes, using the existing `TianZiGeTitle`, with the count of Articles in small muted type beneath. English falls back to heavy serif, as 今天 already does
- [x] Articles newest first, each a Stitch card: title at title size, 来源 and the imported day in muted meta type, and the first line or two of the text in one faint line
- [x] Tapping an Article does nothing yet. Ticket 15 opens it
- [x] Space is left above the list for the Level meter (ticket 18) and 今日新词 (ticket 19). Leave it empty, not filled with a placeholder

## Archive and restore

- [x] Each Article row carries 归档, matching how a Category is archived in 设置
- [x] An **Archived Article** leaves the list. A 已归档 toggle at the bottom of the tab reveals them, each with 恢复
- [x] There is no delete, anywhere, and nothing in the UI suggests one. An Article's **Clean Sightings** have already been banked into `WordProgress` and must never be undone by tidying up ([ADR 0005](../../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md))

## Tests

At a new `ArticleLibrary`, which the screen must also call — no second copy of the sort or the filter:

- [x] A title is taken from the first line and trimmed
- [x] A long first line is cut at 30 characters
- [x] Text with a blank first line takes the first line that has something in it
- [x] Empty and whitespace-only text is refused
- [x] An Article with no 来源 saves with it nil, not an empty string
- [x] `ArticleLibrary.reading(_:)` returns unarchived Articles newest first; `archived(_:)` returns the rest
- [x] Archiving and restoring an Article changes only its flag: its text, title, imported day and banked flag are untouched

## Left for the iPhone

- [ ] Paste a real 微信 article and check the auto-title is something you recognise in the list
- [ ] Paste something with a very long first line and check the cut does not land mid-word in a way that reads badly
- [ ] Check the four tabs still fit their labels on your phone — 今天 · 阅读 · 进度 · 设置
- [ ] Archive an Article and bring it back

## Comments

- **Three records arrived at once, not one.** `Article` is what this ticket needs, but `WordLookup` and `WordProgress` went into the schema with it. SwiftData migrates the store when the schema changes, and doing that three times across tickets 14, 15 and 16 is three chances to lose the student's data for no gain. They are defined and empty; tickets 15 and 16 fill them. The app was launched afterwards against the simulator's existing store and opened with its Categories and Completions intact, which is the check that the migration was clean.
- **`isBanked` is on `Article` already, for the same reason**, and nothing reads it yet. Ticket 16 is what sets it.
- **The title is taken, not typed, and it is not editable.** Import has to be one paste and one button or it won't be used in the moment it is meant for — standing in a teahouse with a menu. The rule that a blank first line is skipped came out of the tests: a pasted 微信 article almost always starts with one.
- **The text is never cut, only the title.** `aLongFirstLineIsCut` checks both halves of that, because a title limit that quietly truncated the article would destroy the thing being imported.
- **`ArticleLibrary.title(from:)` is a static function on the library**, so the import sheet and the tests call the same one. There is no second copy of the first-line rule.
- **Sorting is by imported day, then title.** `Day` is a day number with no time in it, so several Articles imported on one day would otherwise come back in whatever order the store felt like. Title is a stable tie-break.
- **An empty 来源 is stored as nil, not "".** An empty string would render as a stray separator in the row's meta line.
- The 阅读 tab leaves the space above the list empty for the Level meter and 今日新词. A placeholder would have to be designed and then deleted.
- Tapping an Article does nothing yet, as the ticket says. Ticket 15 opens it.
- 11 new tests at `ArticleLibrary`, written first and failing to compile before the record existed. 109 tests pass, 10 suites, up from 98 in 9.
- 14 new strings, all with English.
