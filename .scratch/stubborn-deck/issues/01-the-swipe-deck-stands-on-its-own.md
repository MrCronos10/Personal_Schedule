# 01: The swipe deck stands on its own

**What to build:** The 今日新词 swipe deck becomes a deck that takes any list of **Words** and is told what 认识 and 不认识 do, so the **Stubborn Deck** (ticket 02) can reuse it instead of copying it. **Daily New Words** looks and behaves exactly as before.

This is a prefactor: no rule changes, so no new library test. The suite staying green, and the deck unchanged on the phone, is the check.

**Blocked by:** None (can start immediately)

**Status:** ready-for-human (only the swipe-through on the iPhone is left)

- [x] The deck lives in its own file, not as a private part of the level meter
- [x] It is given its Words, what an answer does, and the line shown when it is spent
- [x] An answer that could not be written still springs the card back instead of flying off
- [x] Daily New Words passes `markKnown` / `setAside` and 今天的新词看完了, and nothing else about it changes: snapshot, double-answer guard, peek card without its meaning, hints, haptic on 认识, VoiceOver actions, speaker
- [x] The whole suite passes

## Left for the iPhone

- [ ] Swipe through 今日新词 and see nothing different

## Comments

A pure move, so no new test: no library rule changed. `WordSwipeDeck` now lives in its own file and takes the Words, a `finishedLine`, and a `record` closure given the Word and an `Answer` (`.known` / `.notKnown`). 今日新词 binds it to `markKnown` / `setAside` in a small wrapper. Whole suite green at **414 tests**, the same as before.

`/code-review`, two axes:

- **Spec:** nothing missing, no scope creep. A line-by-line comparison with the old deck found only the expected changes (the line, the closure call, comments). It flagged the `record` doc as reading "was it written", which ticket 02's 不认识 (writes nothing, still advances) would contradict; reworded to "was it handled".
- **Standards:** no hard violations; the existing 今天的新词看完了 key still applies, and no new screen text. Fixed from its judgement calls: the answer is a small `Answer` type instead of a bare `Bool`; `spentLine` renamed `finishedLine`; an unglossed **Stubborn Deck** reference dropped from a comment; "mastery" (on the avoid list) replaced in a carried-over comment. Kept: the thin `DailyNewWordsDeck` wrapper, the one place that rule is bound. The haptic on every 认识 is right for Daily New Words and is left as is, with a question added to ticket 02.

Not seen running: the deck on the phone.
