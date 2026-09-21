# 17: A Reading Session saves a Completion

**What to build:** The join between reading and everything the app already does. A **Reading Session** counts the minutes an **Article** was on screen, and 读完 opens the existing Tick sheet with those minutes and the words met already filled in. The **Completion** it saves is an ordinary Completion in an ordinary Category, so the 进度 tab and **Weekly Targets** gain reading for free.

**Blocked by:** 16

**Status:** ready-for-agent

## The minutes

- [ ] Time accrues only while the reading screen is actually on screen: it starts when the screen appears, stops on `scenePhase` leaving `.active`, stops when the screen goes away, and resumes when it comes back. Leaving the phone on the table with the app open still counts — the app cannot tell reading from staring, and pretending otherwise would need a stopwatch the student has to remember
- [ ] Seconds are rounded to the nearest minute, with a floor of 1
- [ ] There is **no visible timer** while reading. A number counting up changes how you read, and the figure is editable at the end anyway
- [ ] The minutes are not a record. They live with the screen and are handed to the Tick sheet; if the app is killed mid-article they are gone, and the student types the number in

## Choosing the Action

- [ ] 读完 asks which of today's **Actions** the session ticks off, as a short list of today's unticked Actions with the 中文 ones first
- [ ] If exactly one of today's unticked Actions is a **Routine** whose Category is the one most Completions have come from, it is preselected. No new setting and no "reading Action" field on anything — the student's existing Routine, such as 读一篇文章, is the one that gets ticked
- [ ] 不记录 is always there, for reading that is not part of the plan. The evidence from ticket 16 is already banked either way: **Clean Sightings never depend on a Completion being saved**
- [ ] The app never creates an Action by itself. An Action the student cannot edit would break the rule that they own their own Categories and Actions

## The Tick sheet

- [ ] The **existing** `TickSheetView` is reused, not copied. It opens with minutes prefilled from the session instead of the Action's **Default Minutes**, and both are editable as before
- [ ] The Note is prefilled with the Article's title and the words met: `《西湖龙井》· 新词：安排、印象、保证`. Words met means the HSK 4/5 Words in the Article that are not yet **Known**, at most eight, then `…`
- [ ] The prefilled Note is the student's text from that moment on: editable, deletable, and never translated (`Text(verbatim:)`)
- [ ] Saving writes a normal Completion, with its title and Category copy, exactly as ticking from the Daily Checklist does ([ADR 0002](../../../docs/adr/0002-completion-keeps-copy-of-action.md)). The 进度 tab needs **no new code at all** — if it does, the join has been built in the wrong place

## Tests

At `CompletionLibrary` and `VocabularyLibrary`:

- [ ] A Completion saved from a Reading Session is indistinguishable from one saved from the Daily Checklist: same fields, same title and Category copy, and it counts the same way in the week
- [ ] Its minutes reach that Category's **Weekly Target** for the week
- [ ] Banking evidence and saving a Completion are independent: 不记录 leaves the Clean Sightings from ticket 16 exactly as they were
- [ ] The Note prefill lists only not-yet-Known HSK 4/5 Words, caps at eight, and separates them with 、
- [ ] An Article whose Words are all Known prefills a Note with the title and no 新词 clause, not a dangling 新词：
- [ ] The preselected Action is today's unticked Routine in the most-used Category; with no such Routine, nothing is preselected and 不记录 is still available

## Left for the iPhone

- [ ] Read for a real ten minutes and check the minutes handed to the Tick sheet are close to the truth
- [ ] Leave the article, take a call, come back, and check the time did not run while the app was in the background
- [ ] Tick your 读一篇文章 Routine this way and watch the 中文 bar on 进度 move
- [ ] Read the prefilled Note the next day in the Notes List and judge whether it is worth keeping or just noise
- [ ] Press 不记录 once and confirm your 掌握 count still went up
