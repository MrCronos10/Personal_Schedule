# 08: The red seal — Known, and Passed

**What to build:** The two moments the year is actually made of, marked. A **Word** turning **Known**, and a **Level** turning **Passed**, get a small red seal stamp — the same seal the tick already uses — and a light haptic.

This is not a badge and not a streak. [ADR 0004](../../../docs/adr/0004-known-is-earned-by-reading-not-by-review.md) turned those down because they create debt; a stamp on something already earned creates none. Nothing is due, nothing accrues, and a day not opened still leaves nothing behind.

**Blocked by:** 03 (where the stamp belongs depends on whether what an Article proved is a durable thing on its row or a line that vanishes)

**Status:** ready-for-human (the checks left need real motion and haptics)

## The rule

- [x] The Word stamp fires when a Word becomes Known, by any route: three **Clean Sightings**, 认识 in **Daily New Words**, or marking it by hand
- [x] One 读完 that makes several Words Known is **one** stamp on the line that says how many, never one animation per Word — gated on a freshness flag rather than on the count alone, so the same line reused permanently on the Article's row (ticket 03) never replays it
- [x] The Level stamp fires once when a Level reaches **Passed**, and never again
- [x] The Level stamp waits for the 阅读 tab. Detection lives only in `ReadingView.refresh()`, nowhere else, so wherever a Word actually turns Known — the reader, a Word sheet, Daily New Words — the congratulation itself only ever happens once the student is looking at this tab
- [x] Taking a Level back below four fifths with 其实不认识 re-arms it: passing again is worth marking again
- [x] The app remembers which Levels it has already congratulated (`LevelCongratulation`, written lazily like `WordProgress`), so reopening the tab does not stamp again
- [x] Both Levels can cross **Passed** in the same refresh, and both get their stamp — see Comments for the bug this caught

## The screen

- [x] Quiet and in the 田字格 practice-book voice: a seal landing, not confetti — reuses the visual language of the existing 完 tick seal
- [x] It never blocks a tap. The Word sheet's hand-marking path pauses briefly (0.7s) before its own dismiss so the stamp has time to land, which is a pause before an automatic action, not a second tap demanded of the student
- [x] Reduce Motion is honoured — the stamp appears without the animation rather than not at all
- [x] The haptic is light (`.sensoryFeedback(.success, trigger:)`), which already respects the system's own haptics setting

## Tests

The animation is judged by eye. What can be pinned:

- [x] A bank making several Words Known reports the count, for one stamp — already covered by `theResultCountsWhatMoved` from ticket 16, reused rather than duplicated
- [x] Passing is detected at four fifths exactly — already covered by `LevelTests`, reused rather than duplicated
- [x] A Level already congratulated is not congratulated again
- [x] Dropping below four fifths re-arms it; a Word taken back that doesn't actually drop the Level leaves it armed; the full round trip — dropped, re-armed, earned back, worth marking again

**Not written, and why:** the `justStamped`/`.sensoryFeedback` timing fixes below are SwiftUI view-state bugs, not library rules, and this project checks screens by hand rather than with a view-testing framework. What's testable about them — that `VocabularyLibrary`'s congratulation state is correct — is fully covered above.

## Left for the iPhone

- [ ] Get a Word to Known by reading and judge whether the stamp is earned or annoying
- [ ] Fake a Level to four fifths and check the stamp waits for the 阅读 tab rather than interrupting
- [ ] Fake *both* Levels to four fifths in one sitting and confirm both stamps actually appear, not just HSK 5's
- [ ] Turn Reduce Motion on and check it still makes sense
- [ ] Decide honestly whether the haptic is right. If it feels like a game, take it out
- [ ] Mark a Word Known by hand in the Word sheet and watch it dismiss on its own; judge whether 0.7s is the right pause or needs adjusting

## Comments

Built test-first where the rule was library-side. Whole suite green at **245 tests**, up from 236.

`/code-review` found one real bug, and it's a sharp one: `justPassedLevel` started as a single `Optional<HSKLevel>`. Reading enough in one sitting to cross Passed on both HSK 4 and HSK 5 at once — entirely plausible, since a long Article can bank dozens of Words across both lists — meant the loop in `refresh()` set it to `.four`, marked HSK 4 congratulated, then in the same synchronous pass overwrote it with `.five` before SwiftUI ever rendered the first value. HSK 4 would have been marked congratulated forever with its stamp never shown once. Fixed by changing it to a `Set<HSKLevel>`, so both Levels can be added independently and neither overwrites the other.

Caught before the review, on my own: `.sensoryFeedback(trigger:)` only reliably fires on a genuine value change within a view that persists across it — not on a view that is freshly mounted at the exact moment its first value already satisfies the trigger. Two of the three stamp sites are exactly that shape (the stamp itself is conditionally inserted the moment it should appear), so I moved each haptic onto the nearest always-present container instead of the stamp, and gave `BankedResultLine` a `justStamped` flag that starts false and flips true on `.onAppear` specifically to guarantee a real transition regardless of the framework's own first-appearance behaviour.

Also worked out from scratch: `WordLookupSheet`'s hand-marking dismisses itself immediately on tap in the code that existed before this ticket, which left no time for a stamp to ever be seen. `isKnown` itself flips almost instantly once the write lands through the sheet's own live query, which would have swapped the button under the stamp mid-animation had the stamp been gated on it. Decoupled the stamp from `isKnown` entirely and added a short pause before the sheet's own automatic dismiss.

Not seen running: anything on the phone, and this ticket leans on real motion and real haptics more than most — the "both Levels at once" scenario the review caught is also the first thing worth confirming by hand now that it's fixed.
