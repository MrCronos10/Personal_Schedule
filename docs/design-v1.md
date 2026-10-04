# Design v1 — the practice-book hybrid

A single brief for how the app looks and feels, so later tickets build in one
voice. Written against the current seven surfaces: Today, Reading, Vocabulary,
Progress, Notes, Coach, Settings.

The direction is **hybrid**: modern chrome (clean nav, iOS-native lists and
sheets), with **practice-book moments** inside content (田字格 grid lines on
Reading and Vocabulary, red seals on completion, 宋体 headlines). The scholar's
notebook is the identity; the chrome keeps it from reading as a worksheet.

[ADR 0009](adr/0009-visual-design-is-practice-book-hybrid.md) records the
hard-to-reverse pieces: hybrid over pure practice-book, four-tab nav, the
collection grid as the achievement surface.

## The logo — 读 in a 田字格

A single character, **读** (dú, to read), brush-written in **ink black** inside
a **grid red** 田字格, on **paper cream**. Reading is the heart of the app
(ADR 0004, ADR 0005; tickets 10–14 all orbit it), so the mark says what the
app does without a word of English.

- The character fills about 70% of its cell; the four quadrants of the 田 are
  visible around it.
- Brush stroke, not geometric type — the mark is handwritten, so a hairline
  wobble is correct, not a defect.
- App icon export: the 田字格 is the icon bounds, no outer padding, the grid
  red line reads as the icon's edge. Dark-mode icon: cream character on ink
  background, same grid, grid red stays grid red.

## Palette

| Role              | Light hex | Dark hex   | Where it lives                                           |
| ----------------- | --------- | ---------- | -------------------------------------------------------- |
| Paper cream       | `#FAF6EC` | —          | Primary background in light.                              |
| Night ink         | —         | `#1C1A17`  | Primary background in dark.                               |
| Ink black         | `#1C1A17` | —          | Primary text in light; brush strokes.                     |
| Lantern cream     | —         | `#E8DEC5`  | Primary text in dark.                                     |
| Grid red          | `#C8382E` | `#A3362E`  | 田字格 lines, logo accent, achievement highlight.         |
| Seal red          | `#8B2A1F` | `#6E2419`  | Pressed states, header rules, completion stamps.          |
| Bamboo green      | `#6B8E4E` | `#7FA060`  | Success only: completion ticks, mastered words.           |
| Faded ink         | `#6B655C` | `#A69F93`  | Secondary text, metadata, inactive tab icons.             |

Rules:

- **Red is sparse.** Grid lines, logo, the seal moments on completion.
  Everything else that wants to be "important" uses weight or size, not red.
- **Green has one job.** It only appears when something is done or mastered.
  Never as a general brand color, never on buttons that aren't "completed."
- **No gradients.** The practice-book metaphor is flat. One shadow allowed:
  the thin cream-paper edge on the Notes index cards.

Dark mode translates the identity rather than switching to a generic dark
theme. The 田字格 watermark on content screens stays visible — faint lantern
cream grid on night ink.

## Typography

| Role                 | Chinese                 | Latin             |
| -------------------- | ----------------------- | ----------------- |
| Display / headlines  | Source Han Serif (宋体) | New York (serif)  |
| Body                 | PingFang SC             | SF Pro Text       |
| Metadata / UI chrome | PingFang SC             | SF Pro Text       |
| Numerals             | SF Mono                 | SF Mono           |

- **Scale** (points): display 28 / title 22 / body 17 / metadata 13 / caption 11.
- **Line height** on article body: **1.9** (reading is slow and chewy; cramped
  Chinese body text is the single most common hostile-looking choice).
- **Numerals are monospaced everywhere counts appear** ("128 / 600", "3 of 7
  routines done") so the grid cells and progress rows line up when numbers
  change.
- Source Han Serif ships free; bundle the Regular and SemiBold weights only.
  Add to `PersonalSchedule/Fonts/` and register in Info.plist.

## Backgrounds

Two rules, by screen job:

- **Content screens** — **Reading, Vocabulary, Progress** — paper cream with a
  **田字格 watermark**: faint grid red at **5% opacity** in light, faint
  lantern cream at **4% opacity** in dark. The watermark is a repeating 田字格
  pattern sized so one cell is 88pt — big enough that the grid reads as paper
  texture, not as UI.
- **Chrome screens** — **Today, Notes, Coach, Settings** — flat paper cream in
  light, flat night ink in dark. No watermark. These screens are about doing,
  not reading; the content provides the visual interest.

No photographic backgrounds anywhere. No ink-wash paintings in headers. The
app's professionalism comes from restraint, not scenery.

## Navigation — four tabs

A `TabView` with four tabs. Chinese labels, SF Symbols with practice-book
tint: **grid red** when selected, **faded ink** when not.

| Tab       | Label | Symbol              | Lives inside                                             |
| --------- | ----- | ------------------- | -------------------------------------------------------- |
| Today     | 今天   | `calendar`          | Daily Checklist, Timetable, Evening Check. Notes open here. |
| Reading   | 阅读   | `book`              | Article list, reader, Reading Coach dock.                 |
| Vocabulary| 词     | `character.book.closed` | 难词, HSK Levels, 农业词 shelves.                     |
| Progress  | 进度   | `square.grid.3x3`   | The collection grid (HSK + Topic), Progress Tracker.      |

Settings is a gear in Today's top-right corner. Coach lives inside Reading
(ADR 0008). Notes open as a sheet from Today, not a tab.

## Collection grid — the achievement surface

Progress is where "achievement feels fun" lives. The design is a dense grid of
田字格 cells, one per Word in the Word List, in three states:

- **Not met** — empty cream cell, grid red lines, no character inside.
- **Seen** — character written in **faded ink** (looked up at least once but
  not Known). The grid feels alive weeks before anything is Known.
- **Known** — character in full **ink black**, brush-stroked.

Layout:

- **~10 cells per row** on iPhone (cell size scales with screen width).
- Two sections pinned above by ADR 0005 totals: **HSK 4 — 128 / 600** and
  **HSK 5 — 0 / 1,300**. SF Mono numerals in the header row above the grid.
- **农业词** section below, same cell treatment, out of 125 (plus Custom
  Topic Words) per ADR 0007. Topic Known uses ink black too; the state model
  is shared with Known, since ADR 0007 says it has one state 认识/not.
- **Tap a cell** → bottom sheet with the Word, its pinyin and English, its
  Clean Sightings (which Articles earned them), and a 其实不认识 button for
  Topic Words.
- **Fill animation**: when a Word crosses to Known, the cell inks itself with
  a 300ms brush-stroke animation. If the student is not on Progress at that
  moment, the next time they visit, newly-inked cells have a 1s "freshly
  inked" grid-red glow around them.

The grid is **the primary achievement surface** of the app. Streaks, badges
and ranks are intentionally absent (ADR 0004: no streaks, nothing due).

## Small celebrations

Four moments, each a different visual vocabulary so they don't blur. No sound
on any of them.

1. **Finish a reading session** (student presses 读完 and the session banks) —
   a brush-stroke **读** seal fades up from the bottom of the reader, holds
   for 600ms, fades out. Light haptic (`UIImpactFeedbackGenerator(.light)`).
2. **Master a Word** (a Word crosses to Known) — the cell inks itself on the
   collection grid (see above). No haptic, since this often fires outside the
   student's attention; the glow on next visit is the moment.
3. **Hit the daily reading goal** (configurable in Settings; default 200 字
   read in a day) — a small **seal red** seal stamps the Today header once,
   first time per day. Medium haptic.
4. **Complete all of today's Routines** — the Daily Checklist's routine rows
   fold up into a single "今天 — 完成" cream card with a thin **bamboo green**
   tick. Light haptic. The card stays until tomorrow.

What is **not** celebrated: opening the app, reading one word, a streak day,
a weekly review. Celebrating noise trains the student to ignore the signal.

## Per-screen notes

### Today — 今天

- **Collection sliver on top**: a thin horizontal strip showing the last ~20
  cells the student filled (across HSK 4, HSK 5, and 农业词 together), newest
  on the right. Taps through to Progress with the matching section scrolled
  into view.
- **Timetable** block next, then **Daily Checklist**. Daily Checklist uses
  the practice-book line rule — a one-pixel **faded ink** horizontal line
  between rows, like a notebook page.
- **Gear** in top-right opens Settings.
- **Evening Check** uses a cream sheet, not a full screen.
- Background: **flat paper cream**, no watermark.

### Reading — 阅读

Three zones, from the earlier round:

- **Top chrome** — article title in **宋体 SemiBold 22pt**, author/source
  (optional, student's own writing, never translated) in **faded ink** 13pt.
  Below those, a thin **grid red** reading-progress bar (how far into the
  article the student has scrolled).
- **Body** — Chinese text at **PingFang 17pt, 1.9 line-height**, paper cream
  with 田字格 watermark. Tap a Word → inline lookup card **drops down below
  the line**, not as an overlay; the paragraph stays visible. Looked-up Words
  gain a **faded ink** underline (matches the "seen" state in the collection
  grid, so the vocabulary is consistent).
- **Coach dock** — persistent at the bottom. Collapsed state (default) is one
  line: "读伴 在想…" in faded ink when he's writing, "问读伴" otherwise.
  Pull-up expands to the full thread (ticket 12, 13). Pull-down collapses.
  The dock never covers more than ~40% of the screen when expanded unless the
  student pulls it to full.

### Vocabulary — 词

Three shelves, scrolling vertically:

- **难词** (Stubborn Words, ticket 10) on top. Red seal marker above the
  shelf header. Dense list of looked-up Words with their Articles. Pull-to-
  review opens a quick 认识/不认识 pass.
- **HSK Levels** — two large tappable cards, one per Level. Each card shows a
  **20-cell sliver** of that Level's collection grid, the Level's current
  "128 / 600" count in **SF Mono**, and a one-word readability hint from the
  current Article if the student is mid-read.
- **农业词** — one card, same treatment as HSK Levels, out of 125 + custom.

Background: 田字格 watermark.

### Progress — 进度

The collection grid (described above) is the whole screen, with a thin
summary row at the very top: today's new Known count, today's reading
minutes.

The pre-existing Progress Tracker (Weekly Targets per Category) is below the
collection grid, in a less visually loud treatment — a scrollable row of
cream cards, one per Category, each with its minutes-vs-target bar in grid
red (or Completion Count number for Categories without a Target).

Background: 田字格 watermark.

### Notes — Notes List

Opened as a sheet from Today, not a tab.

- Each Note is a **cream index card** stacked loosely (a 2° rotation offset
  on alternate cards gives the "pile" feel). Thin **grid red** top edge.
- Note title in **宋体 SemiBold 17pt** (first line of the Note), body in
  **PingFang 15pt**.
- Tap a card to expand to full screen; swipe down to collapse back to the
  stack.
- Search bar pinned top.
- Background: flat paper cream, no watermark (the cards are the texture).

### Coach — inside Reading

Not a tab. Lives in the Reading dock. See **Reading** above and ADR 0008 for
the house rules the Coach never breaks (never counts, never says "due").

Visual details:

- Student messages right-aligned in **ink black** on a thin **grid red** card
  edge.
- Coach replies left-aligned in **ink black** on paper cream. Chinese and
  English lines separated by a one-pixel **faded ink** rule when the student
  asked for both (per Coach Language, ADR 0008).
- Pinyin always under new Chinese words, **faded ink** 11pt.
- Streaming text (ticket 13) uses a caret '▍' that fades at the end of the
  stream.

### Settings — 更多

Grouped iOS-native lists. Flat paper cream, no watermark.

Sections:

- **阅读** — daily reading goal (defaults to 200 字), font size slider,
  Article import defaults.
- **词** — daily 难词 review count, Set Aside window (default 30 days per
  ADR 0006).
- **读伴** — SecureField for the Anthropic API key (per ADR 0008), 保存 and
  清除, a one-line "本地保存，不上传" note under it. Language mode default.
- **关于** — version, ADR links as in-app web views for the curious student,
  licence credits for Source Han Serif.

## Implementation order

System-first, per the round-3 scope decision. Ship as separate tickets:

1. **Palette + typography primitives** — add fonts to `PersonalSchedule/Fonts/`,
   extend `Theme.swift` with the full color token set, swap existing uses of
   `.primary` / `.secondary` for the semantic tokens. One PR, no visual
   redesigns yet.
2. **Logo + app icon** — the 读 田字格 mark as `AppIcon.appiconset`, plus a
   `LogoView` for in-app use (About screen, Evening Check sheet header).
3. **田字格 watermark** — one `BackgroundView` used by content screens.
4. **Collection grid** — the new Progress screen with three-state cells, the
   fill animation, and the sliver component Today reuses.
5. **Four-tab nav** — restructure the TabView, move Settings into Today's
   gear, promote Progress to a peer tab if it isn't already.
6. **Reading restyle** — three zones, inline lookup card, Coach dock.
7. **Vocabulary restyle** — three shelves.
8. **Today restyle** — sliver, Timetable, Daily Checklist with notebook rule.
9. **Notes restyle** — index-card stack.
10. **Settings restyle** — sectioned list + 关于.
11. **Celebrations** — four small moments, in one pass so they stay a family.

Each becomes its own ticket under `.scratch/`, built the way tickets 01–14
were built: red / green / rule-per-cycle, tap-through on the student's
iPhone.

## What this brief does not do

- It does not pick an animation library (SwiftUI's own transitions and
  `.animation` modifiers are enough; no Lottie).
- It does not design a dark-mode-specific layout — colors swap, layouts hold.
- It does not touch any Word List, HSK total, or counting rule (those are
  ADRs 0004, 0005, 0006, 0007).
- It does not add a sound. The app is silent.
