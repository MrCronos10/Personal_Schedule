# 21: The Notes List, with search

**What to build:** A fifth tab, 笔记, showing every **Note** newest first, with a search box. This is where the student reads back the words they met in real life — which is the whole reason a **Completion** carries a Note, and there is currently nowhere to see one after the day it was written.

Words in **bold** are defined in [CONTEXT.md](../../../CONTEXT.md).

**Blocked by:** — (20 is done; this needs nothing new from it)

**Status:** ready-for-human (every check left needs a tap)

## Why now

Ticket 17 made every **Reading Session** write a Note naming the **Words** met: `《西湖龙井》· 新词：安排、印象、保证`. The app now generates these faster than the student can read them, and they are visible only on the day they were written, by unticking the Action. The Notes List was already next in [plan-v1.md](../../../docs/plan-v1.md); reading is what made it urgent.

## One decision made without asking

**It is a fifth tab, not a screen pushed from somewhere.** 今天 · 阅读 · 笔记 · 进度 · 设置. Five is the most iOS shows without an overflow, and each label is two characters, so they fit.

The alternatives and why not: inside 进度 is wrong, because progress counts minutes and this is about words; pushed from 阅读 is wrong, because Notes come from every Category, not only reading; pushed from 设置 is wrong, because nobody reviews their week from a settings screen. A review surface behind a push is a review surface that doesn't get used.

The Stitch mock also drew Notes as a tab, which is the same conclusion reached from the design side.

**If five tabs is too many on the phone, say so and this becomes a push from 今天 instead** — the rest of the ticket is unchanged either way.

## The record

- [x] **Nothing new.** A Note is already `Completion.note`, optional free text. No migration, no new model, no new field

## The list

- [x] The tab's header is 笔记 in 田字格 boxes using the existing `TianZiGeTitle`, with the number of Notes in small muted type beneath. English falls back to heavy serif, as the other tabs do
- [x] One row per Completion that **has** a Note, newest first, on the Stitch card the other tabs use
- [x] Each row: the day, the **title copy** and 【Category】 in the Category's ink, the minutes if there are any, and the Note itself
- [x] The Note and the title copy are the student's own writing: `Text(verbatim:)`, never translated
- [x] A row shows the **title** the Completion copied when it was ticked, not what the Action says now ([ADR 0002](../../../docs/adr/0002-completion-keeps-copy-of-action.md)). A Note ticked under 中文 stays under 中文 even if the Action is moved to another Category. The Category's **name** is not copied: renaming 中文 to 语文 relabels past Notes, because that renames the same Category rather than making a new one — the same way 进度 behaves. `/code-review` caught the first draft of this line claiming otherwise
- [x] Tapping a row does nothing in this ticket. Jumping to that day on 今天 is worth having and is its own ticket
- [x] Completions with no Note, or an empty one, are not listed at all — this is the Notes List, not a list of everything done

## Search

- [x] A search field at the top, always visible
- [x] It matches the **Note text**, the **title copy**, and the **Category name**, so 龙井, 读一篇文章 and 中文 all find the same row
- [x] Case-insensitive, for the English that ends up in Notes. Chinese has no case, so this only matters for the Latin half
- [x] An empty search shows everything. There is no "search" button and nothing to submit: the list narrows as it is typed
- [x] Search is a rule, so it lives at `CompletionLibrary` and the screen calls the same function the tests do — not a filter written into the view

## Empty states

In the quiet voice the other tabs use — a sentence and a way forward, never a blank screen:

- [x] No Notes at all: say that a Note is written when an Action is ticked off, so the student knows where they come from
- [x] A search that matches nothing: say so, and leave the search text alone so it can be corrected rather than retyped

## Nothing is deleted

- [x] There is **no delete** in this tab and nothing suggesting one. A Note goes away only when its Completion is unticked, which already exists on 今天
- [x] There is no editing here either. A Note is corrected by re-ticking the day it belongs to

## Tests

At `CompletionLibrary`, which is where the rule lives and what the screen must call:

- [x] `notes(_:)` returns only Completions with a Note, newest first
- [x] A Completion with `nil` note, and one with an empty or whitespace-only note, are both left out
- [x] Two Notes written on the same day come back in a stable order rather than whatever the store feels like
- [x] `search(_:in:)` with empty text returns everything, unchanged
- [x] Search matches inside the Note text
- [x] Search matches the title copy, and the Category name
- [x] Search is case-insensitive for Latin text
- [x] A Note keeps the title and Category it copied: an Action renamed or moved afterwards does not change what the row shows or what the search finds (ADR 0002)
- [x] Renaming a **Category** *does* relabel past Notes and change what the search finds — pinned by its own test, because it is the opposite of the line above and easy to "fix" by mistake

## Language

- [x] Every new string in 中文 with its English, or the translations test fails: 笔记, the count line, the search placeholder, and both empty states
- [x] The Note, the title copy and the Category name are the student's own and are never translated

## Left for the iPhone

- [x] ~~Do five tabs fit~~ — checked in the simulator: 今天 · 阅读 · 笔记 · 进度 · 设置 all render with no truncation and comfortable spacing. **Still yours to judge in the hand**, which is the part a screenshot cannot answer
- [ ] Read back a week of reading Notes and judge whether `《西湖龙井》· 新词：安排、印象、保证` is worth keeping or is just noise. If it is noise, the fix is in ticket 17's prefill, not here
- [ ] Search for a word you remember meeting and see whether you can actually find the day you met it. That is the one thing this tab exists to do
- [ ] Check the list is still quick to open after a few hundred Notes

## Comments

- **Nothing was added to the database.** A Note has been `Completion.note` since ticket 05; this ticket is a screen and two rules over what the app has been recording all along. No migration, no new model, no new field.
- **Both rules live at `CompletionLibrary`** — `notes(_:)` and `search(_:in:)` — taking plain arrays, so the screen hands them `@Query` results and the tests hand them fetched ones. There is no filter or sort written into the view.
- **`createdAt` settles the order within a day.** A `Day` is a day number with no time in it, so two Notes written on one day would otherwise come back in whatever order the store felt like that morning. The test reverses the input and asserts the same answer.
- **The header counts what is on screen.** While a search is active it reads `3 / 40 条笔记` rather than `40 条笔记`, which would contradict the one row under it.
- Five tabs render without truncation in the simulator — 今天 · 阅读 · 笔记 · 进度 · 设置 — but whether five is one too many is a judgement in the hand, and it stays on the iPhone list.

### After `/code-review`

Three findings. The first was a **comment that lied about the code**, and the fix was the words, not the behaviour:

- The doc comment and this ticket both claimed search runs on "the copies". Only `titleWhenTicked` is a copy — `completion.category?.name` reads the live Category, so renaming 中文 to 语文 relabels every past Note and makes a search for 中文 come back empty. The review proposed copying the name at tick time. **That would be wrong.** A rename corrects what one Category is called; it does not make it a different Category, and 进度 already follows a rename the same way. Freezing the name here would have made two screens disagree about the same Category. The comment and the ticket are corrected instead, and `renamingACategoryRelabelsTheNotesUnderIt` pins the real behaviour so nobody "fixes" it later.
- The header counted every Note while the list showed the matches, so a search left `40 条笔记` sitting above one row.
- `NoteRow`'s meta line gave every piece equal layout priority, so a long title shrank the date and the minutes alongside it and the whole line turned to ellipses. The title now gives way on its own.

187 tests pass, 16 suites.
