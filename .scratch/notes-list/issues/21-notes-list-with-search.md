# 21: The Notes List, with search

**What to build:** A fifth tab, 笔记, showing every **Note** newest first, with a search box. This is where the student reads back the words they met in real life — which is the whole reason a **Completion** carries a Note, and there is currently nowhere to see one after the day it was written.

Words in **bold** are defined in [CONTEXT.md](../../../CONTEXT.md).

**Blocked by:** — (20 is done; this needs nothing new from it)

**Status:** ready-for-agent

## Why now

Ticket 17 made every **Reading Session** write a Note naming the **Words** met: `《西湖龙井》· 新词：安排、印象、保证`. The app now generates these faster than the student can read them, and they are visible only on the day they were written, by unticking the Action. The Notes List was already next in [plan-v1.md](../../../docs/plan-v1.md); reading is what made it urgent.

## One decision made without asking

**It is a fifth tab, not a screen pushed from somewhere.** 今天 · 阅读 · 笔记 · 进度 · 设置. Five is the most iOS shows without an overflow, and each label is two characters, so they fit.

The alternatives and why not: inside 进度 is wrong, because progress counts minutes and this is about words; pushed from 阅读 is wrong, because Notes come from every Category, not only reading; pushed from 设置 is wrong, because nobody reviews their week from a settings screen. A review surface behind a push is a review surface that doesn't get used.

The Stitch mock also drew Notes as a tab, which is the same conclusion reached from the design side.

**If five tabs is too many on the phone, say so and this becomes a push from 今天 instead** — the rest of the ticket is unchanged either way.

## The record

- [ ] **Nothing new.** A Note is already `Completion.note`, optional free text. No migration, no new model, no new field

## The list

- [ ] The tab's header is 笔记 in 田字格 boxes using the existing `TianZiGeTitle`, with the number of Notes in small muted type beneath. English falls back to heavy serif, as the other tabs do
- [ ] One row per Completion that **has** a Note, newest first, on the Stitch card the other tabs use
- [ ] Each row: the day, the **title copy** and 【Category】 in the Category's ink, the minutes if there are any, and the Note itself
- [ ] The Note and the title copy are the student's own writing: `Text(verbatim:)`, never translated
- [ ] A row shows what the Completion **copied when it was ticked**, not what the Action says now ([ADR 0002](../../../docs/adr/0002-completion-keeps-copy-of-action.md)). A Note written under 中文 stays under 中文 even if the Action moved
- [ ] Tapping a row does nothing in this ticket. Jumping to that day on 今天 is worth having and is its own ticket
- [ ] Completions with no Note, or an empty one, are not listed at all — this is the Notes List, not a list of everything done

## Search

- [ ] A search field at the top, always visible
- [ ] It matches the **Note text**, the **title copy**, and the **Category name**, so 龙井, 读一篇文章 and 中文 all find the same row
- [ ] Case-insensitive, for the English that ends up in Notes. Chinese has no case, so this only matters for the Latin half
- [ ] An empty search shows everything. There is no "search" button and nothing to submit: the list narrows as it is typed
- [ ] Search is a rule, so it lives at `CompletionLibrary` and the screen calls the same function the tests do — not a filter written into the view

## Empty states

In the quiet voice the other tabs use — a sentence and a way forward, never a blank screen:

- [ ] No Notes at all: say that a Note is written when an Action is ticked off, so the student knows where they come from
- [ ] A search that matches nothing: say so, and leave the search text alone so it can be corrected rather than retyped

## Nothing is deleted

- [ ] There is **no delete** in this tab and nothing suggesting one. A Note goes away only when its Completion is unticked, which already exists on 今天
- [ ] There is no editing here either. A Note is corrected by re-ticking the day it belongs to

## Tests

At `CompletionLibrary`, which is where the rule lives and what the screen must call:

- [ ] `notes(_:)` returns only Completions with a Note, newest first
- [ ] A Completion with `nil` note, and one with an empty or whitespace-only note, are both left out
- [ ] Two Notes written on the same day come back in a stable order rather than whatever the store feels like
- [ ] `search(_:in:)` with empty text returns everything, unchanged
- [ ] Search matches inside the Note text
- [ ] Search matches the title copy, and the Category name
- [ ] Search is case-insensitive for Latin text
- [ ] A Note keeps the title and Category it copied: an Action renamed or moved afterwards does not change what the row shows or what the search finds (ADR 0002)

## Language

- [ ] Every new string in 中文 with its English, or the translations test fails: 笔记, the count line, the search placeholder, and both empty states
- [ ] The Note, the title copy and the Category name are the student's own and are never translated

## Left for the iPhone

- [ ] Do five tabs fit and read on your phone, or is 笔记 one too many? This is the decision this ticket made for you
- [ ] Read back a week of reading Notes and judge whether `《西湖龙井》· 新词：安排、印象、保证` is worth keeping or is just noise. If it is noise, the fix is in ticket 17's prefill, not here
- [ ] Search for a word you remember meeting and see whether you can actually find the day you met it. That is the one thing this tab exists to do
- [ ] Check the list is still quick to open after a few hundred Notes
