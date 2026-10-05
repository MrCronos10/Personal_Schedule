# 日课 · Personal Schedule — design brief v2

An iPhone app for one student's year of study in China. It plans the day and turns real Chinese reading into visible progress. Goal: talk with Chinese people smoothly. iOS, SwiftUI, 390 × 844 pt frames, light and dark, Chinese UI with English translations.

## Principles

- **Practice-book hybrid** (ADR 0009): native iOS chrome, practice-book moments inside content (田字格, 宋体 headlines, red seals, cream paper).
- **Reward reading, never punish rest.** Everything celebrated is cumulative and cannot be lost. No streaks, no "missed yesterday", no "due".
- **One tap to the next useful thing**: Today always shows the next action as a filled red button.
- **Red is rare, green means done, brass means rare seal.**
- **Each screen has its own ground** so the student knows where they are.
- Touch targets ≥ 44 pt, text contrast ≥ 4.5:1, numbers in a monospaced face.

## Logo and icon

读 brush-written in ink black inside a grid-red 田字格 on paper cream, with a small seal-red **日** chop in the bottom-right corner (from 日课). Character fills ~70% of the cell. Dark: night-ink ground, lantern-cream 读, grid stays red. At ≤ 40 pt drop the dashed cross and the chop. Wordmark: mark + 日课 (Noto Serif SC Black) + "Personal Schedule · 每天读一点".

## Colour (light / dark)

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| paper | `#FAF6EC` | `#1C1A17` | page |
| ink | `#1C1A17` | `#E8DEC5` | text, Known cells |
| gridRed | `#C8382E` | `#A3362E` | 田字格, primary button, seals |
| sealRed | `#8B2A1F` | `#6E2419` | headers rules, 完 chop, pressed |
| bamboo | `#4F6B38` | `#7FA060` | **done only** |
| brass | `#B08A2E` | `#C9A44A` | rare seals, passed line |
| fadedInk | `#6B655C` | `#A69F93` | secondary text |
| lacquer | `#2A1F1A` | `#2A1F1A` | Seal Book ground |
| bambooPaper | `#F1F1E4` | `#1F211A` | 词 ground |
| dawnHill | `#F6EDDA` / `#EBDDC0` / `#F1E6CF` | dark equivalents | 今天 header |

Dark values for bambooPaper, brass and dawnHill are proposals, check them on the phone. Replaces the Stitch palette currently in `Theme.swift`; `docs/design-v1.md` already lists the first eight.

## Type

Display: Noto Serif SC Bold/Black (bundled). Body: PingFang SC / SF Pro 17. Brush (seal characters, grid cells): a kaishu brush face, bundled with licence. Numerals: SF Mono. Scale 28 / 22 / 17 / 13 / 11. Article body 18 pt, line-height ≈ 2.0.

## Screen grounds

| Screen | Ground | Build |
| --- | --- | --- |
| 今天 | **Dawn**: cream with a flat header, three layered hills and a red sun | SwiftUI `Shape`s, 250 pt tall, behind the header only |
| 阅读 | **田字格 paper**: red grid at 6% (dark: cream 4%), 88 pt cells | `BackgroundView` (v1 ticket 03) |
| 读完 | **Ink dim**: reader behind, ink at 78% | overlay |
| 词 | **Bamboo paper** `#F1F1E4` with faint bamboo stems and leaves top-right (green at 14–18%) | `Shape`s |
| 进度 | **Night band**: ink header with rounded bottom corners over 田字格 paper | header + `BackgroundView` |
| 印章册 | **Lacquer** `#2A1F1A`, cream tiles; the only dark screen in light mode | flat |

No photos, no gradients.

## Navigation

Four tabs 今天 · 阅读 · 词 · 进度 (selected = gridRed). Settings = button on Today. Notes = sheet from Today. 读伴 lives in the reader. 印章册 opens from 进度.

## Screens

**今天.** Date, Notes and Settings round buttons. Boxed 今天 title (two 田字格 cells) + goal line. *Today card*: Routine ring (green), reading progress "128 / 200 字" with red bar, and a dashed empty stamp slot "再读 72 字" that receives a seal when the goal is hit. *最近认识*: last 10 Known words as small 田字格 cells, newest right with red glow, taps to 进度. *今天的计划*: Classes (grey 课 chip, not tickable) and Actions in time order, 40 pt tick circles, serif titles, category dot + minutes, notebook rules between rows. The next reading Action has a red 去读 button. Ticked: fades, strikes through, 完 chop, moves down. All Routines done: fold into one "今天 — 完成" card. Red + button floats above the tab bar.

**阅读.** Source chip, serif title, meta (字数 · 可读度 · "N 个快认识了"), thin red scroll bar. Body 18 pt / 2.0. Looked-up words: dotted faded underline. **Near-Known words (two clean sightings, so one away) carry two small red dots** under them. Tap a word: inline card drops below the line (word, pinyin, English, HSK level, 听, 写词记, note "查过 · 干净阅读从零开始"). Bottom dock: 伴 seal avatar + "问读伴…" field, pull up for the thread; red **读完** button.

**读完.** Brush 读 seal stamps in (scale 1.3 → 1.0, −5°, 250 ms, light haptic), "读完了", title, minutes. Result card: +N 认识了 (green), N 更近一步, N 回到零. 刚刚上墨: words that just became Known as 田字格 cells inking one after another (120 ms stagger). New-seal strip only if one was earned. Primary 记下来 · N 分钟 (opens Tick sheet pre-filled), secondary 再看一遍.

**词.** Header 词 in a 田字格. Hero card (ink): 今日新词, "10 个新词，认识就点一下", fanned word cards, red 开始, "约 3 分钟 · 不认识的 30 天后再来". The session is a swipe deck: right = 认识, left = 不认识, tap flips. 难词 shelf with red 难 seal, rows "word · pinyin · meaning · 在 N 篇里查过". Two cards, HSK 4 and 农业词: mono count and a 20-cell mini grid (black Known, grey seen).

**进度.** Night band: title, brass-outlined 印章册 button, stats (+N 今天认识 green, minutes today, total Known). Segmented HSK 4 · HSK 5 · 农业词. Count, "再认识 N 个就过关", bar with brass tick at 80%. Grid, 8 cells per row, 田字格 each: empty = not met, grey brush = seen, black brush = Known, red glow = inked since last visit. Tap a cell: sheet with word, pinyin, English, which Articles earned it. Below the grid: weekly Category cards.

**印章册 (new).** Count "7 / 24" in brass. 下一枚 card with progress. 3-per-row tiles: earned = red seal slightly rotated + name + date; unearned = dashed outline + rule + progress; rare = brass ring; 1–2 hidden ("？"). Seals: 初读, 十篇, 五十篇, 百篇 · 百词, 半程 (300 of HSK 4), 过关 (rare), 千字文 (rare) · 识途 (read a photographed menu/sign), 夜读 (finish after 22:00), 问字 (first Word Note) · 农家 (25 农业词), 农场主 (all 125, rare) · 百日 (100 days with any Completion, **not in a row**). Earned seals are permanent. Stamp animation, medium haptic, no sound.

**Not drawn yet** (use the tokens, keep the v1 notes): Notes index-card pile, Settings, empty states (faint 田字格 + one grey brush character + one sentence + one button).

## Motion

Tick: circle fills green 150 ms, 完 chop stamps, row slides down. Lookup card drops 200 ms. Cell inking 300 ms. Reduce Motion: fades only. Silent app, haptics only.

## Do not

Streak flames, "you missed" copy, leaderboards, points, confetti. Photos or gradients as backgrounds. Locking Articles by difficulty. Emoji in the UI.
