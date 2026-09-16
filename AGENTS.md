## Agent skills

### Issue tracker

Tickets are local markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Domain docs

Single-context: one `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## How we build a ticket

Tickets 01–05 were built this way. Keep doing it unless the student says otherwise.

### Where tests go

- **At the libraries and the day rule**: `CategoryLibrary`, `ActionLibrary`, `CompletionLibrary`, `DayPlan`. That is where the rules live, so that is where they are tested.
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

- **Screen text** is written in Chinese in the code and translated in `PersonalSchedule/Localizable.xcstrings`. Every new string needs its English, or the translations test fails. The student's own names and Notes are never translated (`Text(verbatim:)`).
- **Database**: every field has a default or is optional, no unique fields, relationships optional with an inverse. iCloud is off until the Apple Developer Program is paid.
- **Nothing is deleted**: Categories are archived, Routines are paused, and a Completion keeps its own copy of the title and Category (ADR 0002).
- **The look** is 田字格 Practice book; see "Look" in `docs/plan-v1.md`.

### Finishing a ticket

- Tick only what was really checked. Leave tap-through items for the student and set `**Status:** ready-for-human`.
- Add a `## Comments` section saying what was tested, what the review found, and what was not seen running.
- One commit per ticket, describing the behaviour. Push only when the student asks.
