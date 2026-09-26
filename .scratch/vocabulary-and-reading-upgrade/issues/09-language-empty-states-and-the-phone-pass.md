# 09: Language, empty states and the phone pass

**What to build:** The finish of the round, the same way ticket 20 finished the last one. Every new string in 中文 and English, an empty state on every new screen, the whole suite green, `/code-review` done, and a real week of use on the phone.

**Blocked by:** 02, 03, 04, 05, 06, 07, 08

**Status:** ready-for-human (the checks left need a real week on the phone)

## Language

- [x] Every string added this round has its English, and the translations test is green
- [x] The student's own writing is never translated: **Article** titles, **Source**, **Notes**, and **Word Notes** — audited every new display site across all eight tickets, all use `Text(verbatim:)`
- [x] A Word's English gloss is content, not screen text, and stays as it is in both languages — same audit, `entry.pinyin`/`entry.english` are `verbatim` everywhere they're shown
- [x] Nothing anywhere calls HSK an exam, a test, a qualification or a goal — audited every `HSK` mention in the codebase; the only two are pre-existing list-name uses from before this round
- [x] Two now-orphaned strings marked `extractionState: stale` by hand (see Comments — Xcode's own rewrite isn't available from here)

## Empty states

- [x] A Word with no **Clean Sightings** yet (02) — by design, shows nothing at all rather than a sentence (ticket 02's own corrected design: "there is nothing to say")
- [x] An Article never finished, on its row (03) — `bankedResult` is nil, the row shows nothing
- [x] An Article with no measured Words, so no **Readability** (04) — `readability(known:)` is nil, the row shows nothing
- [x] No **Stubborn Words**, which is good news (05) — already has its own quiet line
- [x] A Word with no **Word Note** (05) — the field's placeholder already covers it
- [x] Nothing recognised in a photo (07) — found stale here: the import sheet's placeholder still said "paste it here" even though 拍照/从相册选择 now sit right above it, which would have read as though a photo had been forgotten rather than come back blank. Reworded to cover all three ways in
- [x] The reading list with nothing in it, still reading correctly after the import sheet changed (07) — same gap, same fix: its guidance text only mentioned pasting

## The whole thing

- [x] Whole suite green — **253 tests**
- [x] `/code-review`, and fix what is real — a round-wide review against the pre-round baseline (`c6e8eed..HEAD`), separate from each ticket's own review. See Comments for the five findings and what happened to each
- [x] `CONTEXT.md` holds exactly the terms that now exist, and no term for anything unbuilt — read the full glossary top to bottom against what actually shipped
- [x] Every ADR touched this round still describes what the code does — found ADR 0006 still naming `markNotKnownToday`, the function ticket 01 itself renamed to `setAside`. Fixed

## Left for the iPhone

- [ ] Use it for a real week: import by photo, read, tap, listen, answer the day's words
- [ ] Check the 阅读 tab still opens onto *reading* — the Level meter, 今日新词, 难词 and the new Article rows all want the top of that screen, and reading is the point of it
- [ ] Switch to English and walk every new screen
- [ ] Check every new screen at a large Dynamic Type size, especially anything with a long English gloss
- [ ] Judge the round honestly: is it more inviting to open than before? If some part of it is decoration, say so and take it out
- [ ] Confirm passing a Level plays exactly one haptic, not two — the bug this ticket fixed
- [ ] If there's an existing install with a Level already Passed, confirm opening the tab after this update does *not* show a Passed stamp — the false-positive this ticket fixed

## Comments

This ticket's own job — language, empty states, ADR/glossary consistency — turned up two small real gaps (both fixed): a stale import-sheet placeholder from before ticket 07 added photo capture, and `docs/adr/0006` still naming a function ticket 01 renamed before it ever merged.

The larger part of this ticket was a round-wide `/code-review` against the whole diff since before ticket 01 (`c6e8eed..HEAD`, ~2,700 insertions across 39 files) — something no single ticket's own review could see, since each only looked at its own changes. Took two attempts to actually complete (a rate limit, then a stall on the first try); the third run finished with 8 parallel sub-agents and independent verification. Five findings, all real or already-known:

1. **A Level already Passed before this round shipped would get a false congratulation stamp** the first time the student opened the tab after updating — nothing seeded `LevelCongratulation` rows for a pass that already happened. Fixed with `backfillLevelCongratulations()`, run synchronously at app start (it's cheap — a few fetches and integer comparisons, no tokenization) so it always finishes before any screen can read `hasCongratulated`.
2. **Passing a Level played two haptics, not one.** `.sensoryFeedback(trigger:)` fires on every change of its trigger, and `justPassedLevels` both gains and later loses the Level (the stamp is removed again after two seconds) — two changes, two buzzes, for one moment worth marking once. This is the same "first-render quirk" I'd already worked around three separate times with three separate ad-hoc flags (`justStamped`, `answered[word]==true`, `justMarkedKnown`) — the review named that duplication directly, so rather than add a fourth copy, extracted `View.oneShotSuccessHaptic(when:)` and switched all four sites to it. Caught my own bug while doing this: the helper's first draft used only `.onChange`, which never fires for a freshly-mounted view whose trigger is already `true` at construction — exactly `BankedResultLine`'s shape, which would have gone from "one haptic" to "no haptic ever." Fixed by adding `.onAppear` alongside `.onChange` so both a persisting view crossing the trigger and a freshly-mounted one starting past it are covered.
3. **The measured-words backfill ran synchronously in `App.init()`**, tokenizing every previously-imported Article's full text before the first frame could draw. Moved to a `Task` scheduled after `self.container` is set, so it runs after launch rather than blocking it — nothing depends on it finishing first, since `readability(known:)` already falls back to computing on the spot for an uncached Article.
4. **`stubbornWords()` fetches the entire `WordLookup` table on every call, with no narrowing** — the same shape ticket 02 deliberately avoided for `CleanSighting` in `bank()`. Not fixed here, on purpose: unlike `bank()`, which only ever needs one Article's words, `stubbornWords()` genuinely needs the full history to count distinct Articles per Word, and the real fix (an incremental counter on `WordProgress`, updated as Lookups happen) is a schema and rule change that deserves its own test-first ticket, not a patch inside a closing sweep. Left as a known, documented gap rather than silently dropped.
5. **Partial `CleanSighting` progress lost on the ticket 02 migration** — already surfaced during ticket 02 itself, and already decided: the student explicitly chose to accept the reset (Words at one or two sightings return to zero) over the alternatives, because the alternative was a second number that could drift from the truth. Not a new finding; re-confirmed as still the right call and not touched again here.

Not seen running: the two "Left for the iPhone" items this ticket itself added — that a Level passing plays exactly one haptic, and that an existing install with a Level already Passed doesn't get a stamp it didn't earn — are precisely the two bugs just fixed, and are the first things worth checking by hand.
