# 09: Notes, Settings, empty states

**What to build:** Notes as cream index cards (±2° rotation, red top edge), Settings as grouped lists with 关于 (logo, font licences), and empty states (faint 田字格, one grey brush character, one sentence, one button). Not drawn yet: follow `brief.md` and the v1 notes, and ask the student to look at a first pass.

**Blocked by:** 01, 02. **Status:** ready-for-human

## The rule

- [x] Settings gains the daily reading goal (default 200 字) — already present (`ReadingPreferences`, the Stepper in the 阅读 section).
- [x] The API key stays local and the note says so (ADR 0008) — the 读伴 section keeps the key in Keychain and says it isn't backed up.
- [x] Every new empty state has one sentence and one action — the new `EmptyState` component carries a sentence and (where there is something to do) one action.

## Comments

Notes (index cards), Settings (reading goal, font size, categories, routines, language, the 读伴 key) and the About section were already built. This ticket added the shared **empty-state** shape and finished the About credits.

**New (`EmptyState`):** a faint 田字格 holding one grey brush character, a sentence, and an optional single action — the shape every empty state takes (`brief.md`). Applied to the **Notes** empty state (character 记, with a 去今天 action that closes the sheet to go do a plan). Other empty states (Settings categories/routines) keep their inline text, where the add control already sits beside them.

**About:** now credits both bundled typefaces — Noto Serif SC and the Ma Shan Zheng brush face (ticket 04) — under the SIL Open Font License, since the brush font is now shipped.

**/code-review (4 findings):**
- *(fixed)* the deck combined the whole card for VoiceOver, absorbing the SpeakerButton → the character+meaning are one element with the answer actions, and the speaker is kept separate and reachable.
- *(fixed)* the 认识 / 不认识 swipe hints were on the corners opposite the drag → now 认识 on the right, 不认识 on the left.
- *(deferred, noted)* the deck's snapshot queue isn't reset on a midnight rollover while the app stays open; the proper fix needs day-change plumbing, and the snapshot's 10/day cap (confirmed correct in review) matters more — a relaunch picks up the new day. Flagged for a follow-up.
- *(fixed)* `EmptyState` wrapped in `.card()` doubled its padding in Notes → the wrapper removed.

**Not seen running / left for the phone:** the Notes empty state and its 去今天 action, the About credits, light and dark.
