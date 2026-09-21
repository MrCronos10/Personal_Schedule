## Agent skills

### Issue tracker

Tickets are local markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Domain docs

Single-context: one `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## How we build a ticket

Tickets 01–05 were built this way. Keep doing it unless the student says otherwise.

### Where tests go

- **At the libraries and the day rule**: `CategoryLibrary`, `ActionLibrary`, `CompletionLibrary`, `DayPlan`, and for reading `HSKWordList`, `ArticleLibrary`, `VocabularyLibrary`, `ReadingSession`. That is where the rules live, so that is where they are tested.
- **Build a fixture from an explicit word list, never from a Chinese sentence you wrote by eye.** 篇, 干净, 软 and many other ordinary-looking words are on the HSK lists, so a sentence holds more measured Words than it appears to. Two counting tests were wrong before the code was for exactly this. Where a test counts, assert what the fixture contains first.
- **Screens are checked by hand** on the student's iPhone, not with UI tests. The simulator can be launched from the command line but not tapped, so anything needing a tap is left for the student.
- Screens must use the same rule as the tests: the shared `descriptor(for:)` / `ordered(_:)` helpers, never a second copy of a filter or sort.

### The loop

1. Write one failing test first and run it, so the failure is seen (red).
2. Write only enough code to pass it, and run it again (green).
3. One rule per cycle. If a test passes the moment it is written, say so plainly and keep it as a guard.
4. Run the whole suite at the end.
5. Run `/code-review`, fix what is real, and run the suite again. If a fix changes a library rule, write its test first.

### Commands

```bash
# which simulators this Mac has (names and OS numbers differ per machine,
# and an OS number must match exactly, e.g. 18.3.1 not 18.3)
xcodebuild -showdestinations -project PersonalSchedule.xcodeproj -scheme PersonalSchedule

# all tests (this Mac, September 2026: iPhone 16, iOS 18.3.1)
xcodebuild test -project PersonalSchedule.xcodeproj -scheme PersonalSchedule \
  -destination 'platform=iOS Simulator,id=1B2000CF-B206-4497-BB25-939DB3128082'

# one test file
... -only-testing:PersonalScheduleTests/DayPlanTests

# see the app (it cannot be tapped from here)
xcrun simctl install booted <path>/PersonalSchedule.app
xcrun simctl launch booted com.kuypav.PersonalSchedule
xcrun simctl io booted screenshot out.png
```

### Rules that must hold

- **Anything inside `PersonalSchedule/` ships inside the app.** It is a file-system synchronized group, so a file dropped there is copied into `PersonalSchedule.app` as a resource without anyone adding it to a target. A generator script lived in the app bundle for one commit this way. Tools and sources belong in `.scratch/`; only what the app reads at runtime goes in `PersonalSchedule/`.
- **`Vocabulary/HSKWordList.json` is generated. Never hand-edit it.** Change `.scratch/reading-and-vocabulary/build-word-list.py` and regenerate, or the next rebuild silently discards the edit. `fetch-sources.sh` pins the upstream commits; `Vocabulary/SOURCE.md` says why each of the three sources is used for the one job it has.
- **The two Level totals are the denominator of the year.** 600 and 1,300 are fixed by [ADR 0005](docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md) and pinned by a test. If a source disagrees with them, stop and say so rather than moving the number the student has been watching.
- **Xcode rewrites `Localizable.xcstrings` into its own format** (spaces before colons, its own ordering) on the next build after the file is edited by hand. That is not a mistake: commit the rewrite so the following diff stays readable. It also marks a key `extractionState: stale` when nothing in the code uses it any more — leave that note, it is accurate.

- **Screen text** is written in Chinese in the code and translated in `PersonalSchedule/Localizable.xcstrings`. Every new string needs its English, or the translations test fails. The student's own names and Notes are never translated (`Text(verbatim:)`).
- **Database**: every field has a default or is optional, no unique fields, relationships optional with an inverse. iCloud is off until the Apple Developer Program is paid.
- **Nothing is deleted**: Categories are archived, Routines are paused, and a Completion keeps its own copy of the title and Category (ADR 0002).
- **The look** is 田字格 Practice book; see "Look" in `docs/plan-v1.md`.

### Finishing a ticket

- Tick only what was really checked. Leave tap-through items for the student and set `**Status:** ready-for-human`.
- Add a `## Comments` section saying what was tested, what the review found, and what was not seen running.
- One commit per ticket, describing the behaviour. Push only when the student asks.
