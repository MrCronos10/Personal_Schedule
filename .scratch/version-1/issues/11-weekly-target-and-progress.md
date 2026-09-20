# 11: Weekly Targets and this week's progress

**What to build:** A Category can be given an optional **Weekly Target** in minutes. A third tab, 进度, shows one row per Category for the current week (Monday to Sunday): a bar of the week's minutes against the Weekly Target, or a **Completion Count** where there is no target. This week only — no moving between weeks, and no Mon–Sun grid. Both come later.

**Blocked by:** 10 (Pause and resume a Routine)

**Status:** ready-for-human (the tap-through checks on the iPhone are left)

## Setting the Weekly Target

- [x] `Category` gains `weeklyTargetMinutes: Int?`, following the database rules (optional, no default needed beyond nil, no unique)
- [x] Each Category row in 设置 carries its Weekly Target under its name, and tapping it opens a 每周目标 sheet with an optional 每周目标（分钟） field; empty means no Weekly Target. (Ticket 03's rename is an alert, which can't hold a live hint, so the target got its own sheet and rename was left alone.)
- [x] While typing, a muted line underneath reads the same number in hours (420 → `7 小时`). It is a label only: nothing is parsed or converted, and minutes are what is stored
- [x] A target of zero or less is refused; the message sits with the other Category errors
- [x] Tests at `CategoryLibrary`: a target is saved and read back, an empty target stays nil, zero and negative are refused

## The 进度 tab

- [x] A third tab between 今天 and 设置, labelled 进度, icon `chart.bar`
- [x] Header: 本周 in 田字格 boxes using the existing `TianZiGeTitle`, with the week's date range in small muted type beneath. English falls back to heavy serif without boxes, as 今天 already does
- [x] One row per Category, in creation order — the same order `Theme.categoryInk(at:)` hands out the inks
- [x] A Category **with** a Weekly Target shows its name in its own ink, a bar, and `310 / 420` in muted type
- [x] A Category **without** a Weekly Target shows its name and `本周4次`, with no bar (**Completion Count**)
- [x] An **Archived Category** appears only in a week it has Completions, marked as archived, and keeps its bar if it has a Weekly Target
- [x] Tapping a row does nothing
- [x] Empty states: no Categories at all points at 设置 in the same quiet voice the checklist uses; Categories with nothing ticked yet show rows at zero, not a blank screen
- [x] All new screen text exists in 中文 and English

## The bar

- [x] The track represents the Weekly Target and stops at about 80% of the row's width. The remaining width is the **overflow lane**: empty paper that only takes ink when the week is over target
- [x] At or under target: solid `Theme.red` filling the track in proportion
- [x] Over target: the track is full and the surplus continues into the overflow lane, in proportion, capped at the lane's end (about 25% over). The numbers carry anything beyond that
- [x] No new colour and no new component: red ink on paper, the same as everything else

## What counts

- [x] The week is Monday to Sunday of today's date, worked out with the existing `Day`
- [x] A Completion counts toward the Category it **copied when it was ticked**, not the Action's Category now (ADR 0002)
- [x] A Completion with no minutes counts toward a **Completion Count** but adds no minutes to a bar
- [x] Tests at `CompletionLibrary`: minutes summed for a week; Sunday and the following Monday land in different weeks; a Completion with no minutes adds no minutes but is still counted; an Action moved to another Category leaves its old Completions where they were; a Category archived mid-week still reports that week's minutes

## Left for the iPhone

- [ ] Give 中文 a target of 420 and check the hint reads 7 小时
- [ ] Tick something in 中文 and watch the bar and the numbers move
- [ ] Leave 生活 without a target and check it shows a count and no bar
- [ ] Go past a target and look at the overflow lane — a Category exactly at target stops short of the row's edge, and this is the first thing to judge on the phone
- [ ] Archive a Category you have already ticked in this week and check its row stays

## Comments

- `Week` is a new value type next to `Day`: the Monday of the week a day falls in, and the Sunday six days later. Monday is written into the code rather than read from the phone, because `Calendar.current.firstWeekday` is Sunday in this Mac's region and a Weekly Target cut on a Sunday would total the same Completions differently after a change of region. That is the same reasoning as [ADR 0003](../../../docs/adr/0003-days-are-stored-in-one-calendar.md), one level up.
- `Category` gained `weeklyTargetMinutes: Int?`. Adding it migrated the store the simulator already had without losing anything, which the app opening afterwards confirms. It follows the database rules: optional, no default needed, not unique.
- **Completion Count** and the archived-mid-week rule went into CONTEXT.md while they were being settled, not afterwards. Both came out of questions the mockups raised and the glossary had never answered: what a Category without a Weekly Target shows, and whether archiving on Thursday hides Monday's work.
- The rule the screen draws from and the rule the tests check are the same function. `CompletionLibrary.week(_:categories:completions:)` takes plain arrays, so the 进度 tab hands it `@Query` results and the tests hand it fetched ones. There is no second copy of the week filter or the creation-order sort.
- 84 tests pass, 8 suites. Five were real red-green cycles: a Weekly Target saved and read back; zero and negative refused with the old target left alone; a week running Monday to Sunday across a month end and across the Sunday/Monday join; the week's minutes summed per Category, with the no-minutes case, the moved-Action case (ADR 0002) and the archived-mid-week case; and 420 reading back as `7`, 450 as `7.5`, never `7,5`.
- New screen text: 进度, 本周, 本周的进度, 每周目标, 每周目标（分钟）, 未设每周目标, 每周 %lld 分钟, 本周%lld次, 约 %@ 小时, 目标要大于零 — all with English.
- Ticket 03's rename is an alert, and an alert can't hold the live 小时 hint. Rather than rebuild rename, the Weekly Target sits under each Category's name in 设置 and opens its own sheet. Rename is untouched, so ticket 03 does not need checking again.

### What I got wrong, and how it was caught

- The 进度 header first came out as `M09 14 – M09 20` in a rendering I made to look at the screen from here, so I "fixed" the date formatting with a `DateFormatter` template. That fix was wrong and is not in the code. Printing the candidates showed `.month().day()` had been right the whole time; the fault was my rendering harness, which read the view's content outside SwiftUI and so never received the locale. The giveaway was a stray `2569 BE` — this Mac's Thai calendar leaking in where the app's locale should have been. The running app was screenshotted afterwards and reads `9月14日 – 9月20日`.

### What the review found

- **The empty state asked the wrong question.** It was `categories.isEmpty`, but an Archived Category only appears in a week it has Completions, so archiving every Category left Categories behind and no rows — a heading with nothing under it, which is the exact blank screen the ticket's empty-state line was written to prevent. It now asks `rows.isEmpty`.
- **An Archived Category could be given a Weekly Target.** The Category row is shared by the active and 已归档 lists, so the new target button appeared on retired Categories too. Nothing could ever be worked toward it, because an Archived Category can't be chosen for new Actions. An archived row now shows the target it kept, as ticket 11 decided, but has no button.
- A refused target left its red line under the field while a good number was being typed, because the message was only ever cleared on a successful save. It now goes as soon as the text changes, which is what 设置 already does for Category errors.
- `Week.days` was written and never called. The Mon–Sun grid it was for is deliberately not in this ticket, so it is gone until something needs it.
- `locale` and `isChinese` on `ProgressTrackerView` were dead: the real uses are on `WeekLedger`, which reads the environment itself.
- Rewriting `Localizable.xcstrings` with a script reformatted the whole file — 516 lines changed to add 12 strings — and Xcode would have churned it straight back. It was re-emitted in Xcode's own format and ordering, and the diff is now 110 added lines and nothing deleted.

### What the second review found

- **Correcting a finished day re-filed it.** This is the one that matters, and it was a real bug in the app, not a theoretical one. `tick` re-copied the Action's title and Category onto a Completion that already existed, and the tick sheet goes through `tick` whenever minutes or a Note are changed on a day already ticked. So: tick 翻译练习 (中文) on Monday for 80 minutes, edit the Action into 学习 on Wednesday, then open Monday and fix the minutes — and Monday's 80 minutes walked out of 中文 and into 学习 on the 进度 tab, with the row relabelled to the new title. ADR 0002 exists to stop exactly this. Ticket 11's own test passed the whole time because it never re-ticked. The copies are now left alone when a Completion already exists; unticking still deletes it, so a day genuinely done again takes its copies fresh. The test was written first and did fail on all four counts, including the minutes moving between Categories.
- **The empty state answered the wrong question after the first review's fix.** Keying it on `rows.isEmpty` alone meant a student who had archived every Category was told 请先在设置里添加分类 — "add a Category in Settings first" — while their Categories sat in 已归档, so following the instruction would have made a duplicate instead of restoring. The two empty weeks are now told apart: nothing at all says add one, everything archived says 所有分类都已归档.
- The English for the Completion Count read "4 this week", which dropped the unit that 本周4次 carries; it is now "Completions: 4". The hours hint read "about 1 hours" at 60 minutes, and is now "about 1 h". Plural forms would have been the proper fix for both, but a plural entry in the catalog has no `stringUnit`, which is what `TranslationTests` checks for, so the wording dodges the plural instead.
- Typing 7.5 into the target field — the exact number the hint shows for 450 — was refused with a bare 请输入数字 that never mentioned minutes, and the hint line vanished at the same moment, leaving nothing on screen to explain it. The message now names them: 请输入整分钟.

### Left alone on purpose

- **The 进度 tab reads every Completion, not just this week's.** The review is right that a week's worth would be enough. It stays as it is for now, for the reason ticket 10 left the same kind of scan alone: a day filter on the query is what caused two bugs in ticket 09, and here the fix interacts with the midnight roll-over, since the week a predicate is built from is fixed when the screen is made. At a year of daily ticking this is a few hundred rows, which is nothing on a phone. If it ever feels slow, bound `dayNumber` to the week **and** make sure the screen is rebuilt when the day changes.
- **A Weekly Target has no upper limit.** A mistyped 99999 saves, though a week only holds 10080 minutes, and leaves a bar that can never fill. Refusing it is a change to what a Weekly Target *is*, which is glossary language and the student's decision, not mine. Worth deciding before the Mon–Sun grid ticket.

### For the iPhone check

- The overflow lane is the thing to judge. 健康 at 210 / 180 runs correctly into the lane, but once the red passes the target the pale track is covered, so you can't see where 180 was — over-target and at-target look alike at a glance, and only the numbers separate them. If that bothers you, the answer is the 1pt target mark from the option that wasn't chosen.
- A Category exactly at its target stops short of the row's right edge, because the last fifth of the row is the overflow lane. Judge whether that reads as "done".
