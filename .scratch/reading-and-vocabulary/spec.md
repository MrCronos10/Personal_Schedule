# Reading and Vocabulary

Words in **bold** are defined in [CONTEXT.md](../../CONTEXT.md). Two decisions behind this feature: [ADR 0004](../../docs/adr/0004-known-is-earned-by-reading-not-by-review.md) (Known is earned by reading) and [ADR 0005](../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md) (Levels measure a fixed list).

## What this is for

The student pastes real Chinese they meet in Hangzhou into the app, reads it, taps what they don't know, and presses 读完. Over the year that reading turns into one number: how many HSK 4 and HSK 5 Words are **Known**. Nothing is ever locked, nothing is ever due.

## The shape

```
                 ┌──────────── bundled, read-only ───────────┐
                 │  HSKWordList.json  (HSK 2.0, level 4 + 5) │
                 │  word · pinyin · english · level          │
                 └───────────────────┬───────────────────────┘
                                     │
  paste text                         ▼
      │            ┌──────────────────────────────────┐
      ▼            │        VocabularyLibrary         │  ← the rules live here,
 ┌─────────┐       │  segment(text) → [String]        │     so the tests live here
 │ Article │──────▶│  hskWords(in:) → [Word]          │
 │ title   │       │  bank(article:) clean sightings  │
 │ text    │       │  isKnown(word) = sightings ≥ 3   │
 │ source  │       │  level(_) → known / total, 80%   │
 │ archived│       │  dailyNewWords(10)               │
 └────┬────┘       └───────┬──────────────────┬───────┘
      │                    │                  │
      │ 读完               ▼                  ▼
      │            ┌──────────────┐   ┌──────────────┐
 ┌────▼────────┐   │ WordProgress │   │  Level meter │
 │ WordLookup  │   │ word         │   │  今日新词     │
 │ word·article│   │ sightings    │   └──────────────┘
 │ day         │   │ known / day  │
 └─────────────┘   └──────────────┘
      │ a Lookup returns sightings to 0
      │
      └──── minutes + words met ───▶ existing Tick sheet
                                          │
                                          ▼
                                 ┌──────────────────┐
                                 │    Completion    │  ← unchanged
                                 └────────┬─────────┘
                                          ▼
                                进度 tab / Weekly Target
                                    (no new code)
```

The load-bearing idea: **a Reading Session ends in an ordinary Completion**, so the Progress Tracker, Weekly Targets and the 进度 tab need no changes at all. The new work is one library of rules and one tab.

## The workflow

1. **Import** — paste a 微信 article, the title comes from its first line, an optional **Source**, saved.
2. **Read** — the text is split into words; HSK 4 and 5 Words are faintly underlined. Tapping any word shows pinyin and English and writes a **Lookup**. Minutes accrue while the Article is on screen.
3. **读完** — every HSK 4/5 Word not looked up in this Article gains a **Clean Sighting**; every Word looked up returns to zero. Three Clean Sightings makes a Word **Known**. The Tick sheet opens with the minutes and the words met already filled in.
4. **Tick** — save, and the **Completion** lands in 中文 like any other.
5. **今日新词** — ten unmet Words of the **Served Level**, marked 认识 or 不认识. No streak, no debt.
6. **Measure** — the Level meter: `HSK 4 · 412 / 600 · 69%`, **Passed** at 80%, after which HSK 5 becomes the Served Level.

## Database

Following the rules in [plan-v1.md](../../docs/plan-v1.md): every field has a default or is optional, no unique fields, relationships optional with an inverse, nothing deleted.

| Record | Fields |
| --- | --- |
| **Article** | title, text, source (optional), imported day, archived (yes/no), banked (yes/no) |
| **WordLookup** | word, article (optional link), day |
| **WordProgress** | word, level, clean sightings, known (yes/no), known day (optional) |

`WordProgress` rows are written lazily: a Word the student has never met has no row, and is counted as not Known. The **Word List** itself is a bundled JSON file, not a record.

## Screens

The app goes to four tabs: **今天 · 阅读 · 进度 · 设置**.

The 阅读 tab holds the Level meter at the top, 今日新词 under it, then the list of Articles with a **+** to import. Opening an Article is the reading screen. The look is the Stitch design system, applied to the whole app first in ticket 12.

## Tickets

| # | Ticket | Blocked by |
| --- | --- | --- |
| 12 | [Stitch look across the app](issues/12-stitch-look-across-the-app.md) | — |
| 13 | [Bundled HSK 2.0 Word Lists](issues/13-bundled-hsk-word-lists.md) | — |
| 14 | [Import an Article, and the 阅读 tab](issues/14-import-an-article.md) | 12, 13 |
| 15 | [Read an Article and tap a word](issues/15-read-an-article-and-tap-a-word.md) | 14 |
| 16 | [读完 banks Clean Sightings](issues/16-finish-an-article-banks-evidence.md) | 15 |
| 17 | [A Reading Session saves a Completion](issues/17-reading-session-saves-a-completion.md) | 16 |
| 18 | [The Level meter](issues/18-the-level-meter.md) | 16 |
| 19 | [今日新词](issues/19-daily-new-words.md) | 18 |
| 20 | [Language, empty states and the phone pass](issues/20-language-and-the-phone-pass.md) | 14–19 |

## Not in this feature

- A Share Extension to import straight from Safari or 微信. Wanted, but it is a second app target with its own signing, which is painful under the 7-day free-Apple-ID reinstall.
- OCR from a photo, and fetching an Article from a URL.
- The student's own Words outside HSK 4 and 5 (ADR 0005).
- Anything the Stitch mock shows that is not in ticket 12: the Immersion Focus journal, the route photo card, the Weekly Target meter on the checklist, the Evening Check.
