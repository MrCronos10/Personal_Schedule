# 14: Import an Article, and the 阅读 tab

**What to build:** A fourth tab, 阅读, holding the list of **Articles** and a **+** that imports one by pasting text. The title comes from the first line, the **Source** is optional, and an Article is **archived, never deleted**.

**Blocked by:** 12 (the Stitch look), 13 (the Word Lists)

**Status:** ready-for-agent

## The record

- [ ] `Article`: title, text, source (optional), imported day, archived (yes/no), banked (yes/no). Following the database rules in [plan-v1.md](../../../docs/plan-v1.md): every field has a default or is optional, nothing unique
- [ ] `banked` belongs to ticket 16 and is written now only so the store is not migrated twice. Nothing reads it yet

## Importing

- [ ] **+** opens a 导入文章 sheet: a large text box, an optional 来源 field, and 保存
- [ ] The title is the first line of the pasted text, trimmed, cut at 30 characters with an ellipsis. It is **not** editable in this ticket: import must be one paste and one button
- [ ] If the text has no first line worth using — empty, or whitespace only — 保存 is refused with the message sitting where the Category errors sit
- [ ] The student's own 来源 text is never translated: `Text(verbatim:)`
- [ ] Nothing is segmented and no Word is touched at import. That is ticket 15

## The list

- [ ] The 阅读 tab's header is 阅读 in 田字格 boxes, using the existing `TianZiGeTitle`, with the count of Articles in small muted type beneath. English falls back to heavy serif, as 今天 already does
- [ ] Articles newest first, each a Stitch card: title at title size, 来源 and the imported day in muted meta type, and the first line or two of the text in one faint line
- [ ] Tapping an Article does nothing yet. Ticket 15 opens it
- [ ] Space is left above the list for the Level meter (ticket 18) and 今日新词 (ticket 19). Leave it empty, not filled with a placeholder

## Archive and restore

- [ ] Each Article row carries 归档, matching how a Category is archived in 设置
- [ ] An **Archived Article** leaves the list. A 已归档 toggle at the bottom of the tab reveals them, each with 恢复
- [ ] There is no delete, anywhere, and nothing in the UI suggests one. An Article's **Clean Sightings** have already been banked into `WordProgress` and must never be undone by tidying up ([ADR 0005](../../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md))

## Tests

At a new `ArticleLibrary`, which the screen must also call — no second copy of the sort or the filter:

- [ ] A title is taken from the first line and trimmed
- [ ] A long first line is cut at 30 characters
- [ ] Text with a blank first line takes the first line that has something in it
- [ ] Empty and whitespace-only text is refused
- [ ] An Article with no 来源 saves with it nil, not an empty string
- [ ] `ArticleLibrary.reading(_:)` returns unarchived Articles newest first; `archived(_:)` returns the rest
- [ ] Archiving and restoring an Article changes only its flag: its text, title, imported day and banked flag are untouched

## Left for the iPhone

- [ ] Paste a real 微信 article and check the auto-title is something you recognise in the list
- [ ] Paste something with a very long first line and check the cut does not land mid-word in a way that reads badly
- [ ] Check the four tabs still fit their labels on your phone — 今天 · 阅读 · 进度 · 设置
- [ ] Archive an Article and bring it back
