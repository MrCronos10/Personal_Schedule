# 12: The Stitch look across the app

**What to build:** Replace the 田字格 palette and surfaces in `Theme.swift` with the Stitch *Field Notebook & Editorial Companion* tokens, and carry them through all three existing screens. The two parts of the old look worth keeping are kept: the 田字格 boxed header and the red seal tick. Two small things the Stitch mock gets right are added: the Guiding Goal banner and the "从昨天推到今天" chip.

This ships **before** any reading work, so the app never holds two design languages at once.

**Blocked by:** —

**Status:** ready-for-human (every check left is a judgement on the phone)

**Source:** `/Users/kuypav/Desktop/stitch_china_study_routine_tracker/DESIGN.md` and `screen.png`

## The tokens

- [x] `Theme` gains the Stitch colours, keeping the existing names where they still fit so screens change as little as possible:

  | Role | Old | Stitch |
  | --- | --- | --- |
  | paper / background | `#FBFAF5` | `#FCF9F7` |
  | ink / on-surface | `#231F1C` | `#1C1C1B` |
  | muted / on-surface-variant | `#7E756D` | `#57423C` |
  | red / primary | `#B3312B` | `#973312` |
  | rule / outline-variant | red at 20% | `#DEC0B8` |
  | card / surface-container | — (none) | `#F0EDEB` |
  | card raised / surface-container-high | — | `#EAE8E5` |
  | chip green / secondary-container | — | `#C4E9CB` |
  | chip green ink / on-secondary-container | — | `#496A52` |
  | late / tertiary | `#A8741A` | `#794A07` |
  | error | — | `#BA1A1A` |

- [x] Category inks are re-picked to sit on the new paper without clashing with `primary`. First ink becomes the Stitch primary `#973312`; the other five are adjusted to the same warmth. Creation order is unchanged, so no existing Category changes position
- [x] Corner radius becomes 12 on cards and 8 on buttons and fields (Stitch), replacing the old 4

## Type

- [x] **Noto Serif SC stays the only serif**, for Chinese and Latin alike. Stitch asks for Newsreader, which has no Chinese glyphs at all; adding a second face to render four English words is not worth 400 KB. Write this decision into the ticket's Comments, not an ADR — it is easy to reverse
- [x] The Stitch type scale is followed in size, weight and line height: display 34/40, headline 24/32, title 18/24, body 15/22, label 12/16 with 1.6 tracking

## What is kept from the old look

- [x] `TianZiGeTitle` is untouched: 今天 still sits in dashed 田字格 boxes, and English still falls back to heavy serif. It is the one thing in this app nobody else has, and the Stitch mock has no better idea for it
- [x] The tick stays an ink square that becomes a rotated red 完 seal, in the new primary
- [x] `SectionCaption` keeps its red letters and rule, restyled to the Stitch label scale

## What is taken from the Stitch mock

- [x] ~~**Category sections become cards**, exactly as the mock draws it~~ — **changed.** The day is one card in time order, with each row carrying its Category ink and 【name】. Grouping by Category would have changed the day's ordering rule in `plan-v1.md` and `DayPlanTests`, which this ticket forbids. See Comments
- [x] **Status chips** replace plain coloured text, at the label scale — except the mock's 未完 / 完 pair, which is left out because the seal beside the row already says it. 错过 and the late chip use `tertiary` on a tint of itself
- [x] **Meta chips** above each Action title carry its kind and Default Minutes: `One-time Action · 90 Default Minutes`, in 中文 `一次性 · 90 分钟`
- [x] **Guiding Goal banner** at the top of 今天: the Goal sentence from CONTEXT.md, fixed text in the code, no new record, no editing. Both languages
- [x] **从昨天推到今天** chip on a late One-time Action, in `tertiary`. This names a rule the app already has and has never shown

## What the mock shows and this ticket does not build

Each of these was considered and dropped; say so in Comments so nobody adds them by accident:

- [x] Today's Immersion Focus / Journal Log — a new daily record that would go unfilled by week two
- [x] The field route photo card — images are a whole new problem and buy no study
- [x] The Weekly Target meter on the checklist — it lives on 进度, and a second copy means a second copy of the rule
- [x] The Evening Check card — already queued for a later version, and it needs notifications
- [x] The mock's Timetable and Notes tabs — not built; the tab bar stays at three until ticket 14 makes it four

## Tests

- [x] There is no rule here to test, so no new tests. Say this plainly in Comments rather than writing a test that asserts a hex value
- [x] The whole existing suite still passes, unchanged. If a test needed changing, the re-skin touched a rule and that is a bug in this ticket

## Left for the iPhone

- [ ] Read 今天 in daylight: is `#57423C` on `#FCF9F7` comfortable for the meta lines, or too warm?
- [ ] Check the 完 seal still reads as a stamp in the new primary, which is darker than the old red
- [ ] Check the Category dots are still telling apart 中文, 学习, 健康 and 生活 at a glance
- [ ] Check the Guiding Goal banner does not push the first Action below the fold on your phone
- [ ] Switch to English and check the serif Latin in Noto Serif SC looks deliberate, not like a fallback

## Comments

- **The one real conflict was the day's order, and the ticket lost it.** The Stitch mock groups the day into a card per Category. The app orders a day by time — timed Actions first, earliest first, then untimed — and that rule is written in `plan-v1.md` and tested in `DayPlanTests`. Grouping by Category would have meant changing a tested rule to match a picture, which this ticket forbids in its own Tests section. The day is now one card in time order, and each row carries its Category ink and 【name】, so the grouping reads without the ordering being lost. The mock is a picture of one tidy day; a checklist is something worked down as the day passes.
- **Newsreader was dropped.** Stitch names it for every heading, and it has no Chinese glyphs at all. These screens are Chinese first, Noto Serif SC is already in the bundle, and its Latin is a proper serif. A second 400 KB face to set a few English words is not worth it. Easy to reverse, so it is here rather than in an ADR.
- **The mock's 未完 / 完 chip is not built.** The seal beside the row already says whether the Action is done, and saying it twice is what makes a row look busy. This is a judgement and the best one to overturn first if the phone disagrees.
- **The Guiding Goal banner is fixed text, not a record.** The one aim of the year is the thing least likely to change, and giving it a field would invite editing the sentence instead of doing the work under it. It reads from the code, and its English is in the catalog like any other screen text.
- **No new tests, on purpose.** There is no rule in this ticket — it is colours, spacing and type. A test asserting a hex value would only make the next change noisier without catching anything. The whole existing suite passes untouched, which is the real check that the re-skin stayed on the look side: had a test needed changing, the re-skin would have reached a rule.
- **Three new strings**, all with English: 从昨天推到今天, 长期目标, and the Goal sentence.
- `Chip` and `.card()` are the two new components, and everything on all three tabs is built from them. 进度 and 设置 each put their rows on the same card, so nothing needed a second idea of what a grouped surface looks like.
- The simulator confirms the tokens, the header, the banner and the tab bar render as intended on an empty store. Everything with an Action in it is left for the phone, because the simulator cannot be tapped and there is no way to make a Completion from here.
- 98 tests pass, 9 suites.
