# Version 1 Plan

Words in **bold** are defined in [CONTEXT.md](../CONTEXT.md). Why we build a native Swift app: [ADR 0001](adr/0001-native-swift-app-first.md).

## Goal of version 1

Within about 1 month (about 4 hours a week), have an app on your iPhone that you use every day to:

- plan **One-time Actions** and **Routines** in your own **Categories**
- tick them off on the **Daily Checklist** with minutes and an optional **Note**
- fix any past day you forgot to tick

Everything else waits for a later version (see the end of this file).

## Tools

| Tool | Use |
| --- | --- |
| Xcode (free, Mac) | write, run and install the app |
| Swift + SwiftUI | language and screens |
| SwiftData | database on the iPhone |
| String Catalog | Chinese and English text |
| Free Apple ID | install on your own iPhone (reinstall every 7 days) |

- Minimum iOS version: **iOS 17** (SwiftData needs it).
- iCloud is **off** in version 1, because a free Apple ID can't turn it on.

## Look: 田字格 Practice book

Chosen from the four looks in [docs/prototypes/schedule-looks.html](prototypes/schedule-looks.html) (option B). Open that file in a browser to see and click it.

- **Feeling:** a Chinese character practice book. Paper-white ground, red ink rules, no cards or shadows.
- **Colors:**

  | Role | Hex |
  | --- | --- |
  | Paper (background) | `#FBFAF5` |
  | Ink (text) | `#231F1C` |
  | Muted text | `#7E756D` |
  | Red ink (accent, seal, rules at 20% opacity) | `#B3312B` |
  | Category inks | 中文 `#B3312B`, 学习 `#2E5A88`, 健康 `#3E7A4E`, 生活 `#946519`; new Categories get a color from a small fixed set |

- **Type:** titles and Action titles in Noto Serif SC (Bold and Black), shipped inside the app because iPhones have no Song font built in (about 24 MB, SIL Open Font License); labels and meta text in the system sans; times in a monospaced face.
- **Today header:** in 中文, each character of 今天 sits in its own 田字格 box (square with a dashed cross); in English, "Today" in heavy serif without boxes.
- **Rows:** time on the left (— when there is none), title and 【Category】 meta in the middle, tick box on the right; a thin red rule under each row; section captions in small red letters with a heavier red underline.
- **Tick:** an empty square with an ink border; when done it becomes a red seal with 完, rotated slightly, and the title gets a faint strike-through.
- **Corners:** small (about 4 px) on buttons and fields; the tick sheet uses the same paper color.

## Database (version 1)

Only 4 records. Class and No-class Day come in a later version.

| Record | Fields |
| --- | --- |
| **Category** | name, weekly target minutes (optional, used later), archived (yes/no), created date |
| **Action** | title, category, kind (one-time / routine), time (optional), default minutes (optional), planned date (one-time), repeat weekdays (routine), start date (routine), created date |
| **Pause** | action, start date, end date (empty while still paused) |
| **Completion** | action, day, minutes (optional), note (optional), title copy, category copy |

### Rules the code must follow now, so iCloud can be switched on later

- Every field has a default value or is optional.
- No "unique" fields.
- Every link between records is optional and has a link back (for example Action ↔ Completion).
- Nothing is ever deleted in a way that breaks history: Categories are archived, Routines are paused, and a Completion keeps its own title and Category copy ([ADR 0002](adr/0002-completion-keeps-copy-of-action.md)).

## How a day is worked out

For any day **D**, the Daily Checklist shows:

1. **Routines** where D is on or after the start date, D's weekday is a repeat day, and D is not inside a Pause.
   - Ticked on D → done.
   - Not ticked and D is before today → **Missed**.
2. **One-time Actions**:
   - Not ticked, planned date is D (in the future) → shows on D.
   - Not ticked, planned date is today or earlier → shows only on **today**, marked as late if the planned date has passed.
   - Ticked → shows on the day it was ticked, as done.

Order on screen: Actions with a time first (earliest first), then Actions without a time.

## Screens

The app has 2 tabs. Chinese text is shown first, with English in brackets.

### 1. 今天 (Today): Daily Checklist
- The date at the top, with ◀ ▶ to go to other days and a "今天" button to jump back to today.
- A list of the day's Actions with a check circle, title, time, and Category.
- Tap the circle to open the **Tick sheet**:
  - Minutes, filled in from the Action's default minutes, changeable or left empty
  - Note (optional)
  - Save
- Tap a ticked circle to untick (asks first, then removes the Completion).
- Missed and late items are shown in a different color.
- A **+** button adds an Action.

### 2. 设置 (Settings)
- **Categories**: list, add, rename, archive / restore
- **Routines**: list of all Routines, open one to edit, pause / resume
- **Language**: 中文 / English (default 中文)

### Action form (add or edit)
- Title, Category (active Categories only), kind (One-time / Routine)
- One-time: date. Routine: repeat days (every day / weekdays / pick days), start date
- Time (optional), default minutes (optional)
- Editing a Routine changes today and later days only. Past ticked days keep their copy.
- Deleting is allowed only for a One-time Action that isn't ticked. Routines are paused instead.

## Build steps

Each step ends with something you can see working on your iPhone.

### Step 0: Setup (week 1, about 2 h)
- [x] Update Xcode, and sign in with your Apple ID (Xcode → Settings → Accounts)
- [x] Create a new iOS App project: name `PersonalSchedule`, interface SwiftUI (SwiftData is added in Step 1)
- [x] `git init` in this folder and make the first commit
- [ ] Turn on Developer Mode on your iPhone, then run the empty app on it
- [ ] **Done when:** the app opens on your iPhone

### Step 1: Database and Categories (week 1, about 2 h)
- [ ] Create the 4 records (Category, Action, Pause, Completion) following the iCloud rules above
- [ ] Settings tab → Categories screen: add, rename, archive, restore
- [ ] **Done when:** you create "中文", "学习", "健康", "生活", close the app, reopen it, and they're still there

### Step 2: Actions (week 2, about 4 h)
- [ ] Action form for One-time and Routine
- [ ] Routines list with pause / resume (saves a Pause record)
- [ ] **Done when:** you create "学20个新词, 7:00, 20 min, 中文, every day" and "买SIM卡, one-time, tomorrow"

### Step 3: Daily Checklist (week 3, about 4 h)
- [ ] Today tab showing the day's Actions using the rules in "How a day is worked out"
- [ ] ◀ ▶ day navigation
- [ ] Tick sheet saves a Completion with minutes, note, and title / Category copy
- [ ] Untick, Missed and late colors
- [ ] **Done when:**
  - a Routine ticked today shows as done
  - yesterday's unticked Routine shows as Missed, and ticking it there removes Missed
  - an unticked One-time Action from yesterday appears today
  - a paused Routine doesn't show, and its paused days aren't Missed

### Step 4: Language and daily use (week 4, about 4 h)
- [ ] Put all screen text in the String Catalog in Chinese and English
- [ ] Language switch in Settings (saved on the phone and applied to the whole app)
- [ ] Fix whatever annoys you after using it for a few days
- [ ] **Done when:** you've used only this app for your schedule for 3 days in a row

## Not in version 1

Planned later, one at a time, in this order unless real use says otherwise:

1. ~~**Progress Tracker** with **Weekly Targets**~~ — built, ticket 11
2. **Notes List** with search — **wanted now**: reading writes a Note naming the Words met, and there is still nowhere to read one back after the day it was written
3. Reminders at timed Actions + **Evening Check**
4. **Timetable** view, **Classes**, **No-class Days**
5. Export and import a data file (import only into an empty app)
6. Pay the $99 Apple Developer fee → iCloud sync to iPad

## Risks

- **7-day reinstall:** with a free Apple ID, the app stops opening after 7 days. Set a weekly phone reminder to reinstall it from Xcode. Your data stays as long as you don't delete the app.
- **No backup before sync:** keep iCloud Backup on in iPhone Settings.
- **Learning curve:** if a step takes more than twice its time, make it smaller rather than giving up practice time.
- **Known limitation:** changing a Routine's repeat days also changes which past unticked days show as Missed (only ticked days are protected by their copy).
