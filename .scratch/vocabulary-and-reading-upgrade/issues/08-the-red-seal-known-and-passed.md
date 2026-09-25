# 08: The red seal — Known, and Passed

**What to build:** The two moments the year is actually made of, marked. A **Word** turning **Known**, and a **Level** turning **Passed**, get a small red seal stamp — the same seal the tick already uses — and a light haptic.

This is not a badge and not a streak. [ADR 0004](../../../docs/adr/0004-known-is-earned-by-reading-not-by-review.md) turned those down because they create debt; a stamp on something already earned creates none. Nothing is due, nothing accrues, and a day not opened still leaves nothing behind.

**Blocked by:** 03 (where the stamp belongs depends on whether what an Article proved is a durable thing on its row or a line that vanishes)

**Status:** ready-for-agent

## The rule

- [ ] The Word stamp fires when a Word becomes Known, by any route: three **Clean Sightings**, 认识 in **Daily New Words**, or marking it by hand
- [ ] One 读完 that makes several Words Known is **one** stamp on the line that says how many, never one animation per Word. A long **Article** would otherwise fire a dozen at once
- [ ] The Level stamp fires once when a Level reaches **Passed**, and never again
- [ ] The Level stamp waits for the 阅读 tab. Passing can happen inside the reader or a Word sheet, and interrupting there would break that screen's own rule about keeping controls out of the way of the text — **Passed** changes nothing functionally, so it can afford to wait for the room built for it
- [ ] Taking a Level back below four fifths with 其实不认识 re-arms it: passing again is worth marking again
- [ ] The app remembers which Levels it has already congratulated, so reopening the tab does not stamp again

## The screen

- [ ] Quiet and in the 田字格 practice-book voice: a seal landing, not confetti
- [ ] It never blocks a tap or delays what the student was doing
- [ ] Reduce Motion is honoured — the stamp appears without the animation rather than not at all
- [ ] The haptic is light, and absent where the phone has it turned off

## Tests

The animation is judged by eye. What can be pinned:

- [ ] A bank making three Words Known reports three, for one stamp — the count, not three events
- [ ] Passing is detected at four fifths exactly, matching the existing Level rule, and not at a rounded percentage
- [ ] A Level already congratulated is not congratulated again
- [ ] Dropping below four fifths and passing again does congratulate again

## Left for the iPhone

- [ ] Get a Word to Known by reading and judge whether the stamp is earned or annoying
- [ ] Fake a Level to four fifths and check the stamp waits for the 阅读 tab rather than interrupting
- [ ] Turn Reduce Motion on and check it still makes sense
- [ ] Decide honestly whether the haptic is right. If it feels like a game, take it out
