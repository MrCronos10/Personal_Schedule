# 02: The Stubborn Deck

**What to build:** A 再看一遍 button on the 难词 screen that opens every **Stubborn Word** as a swipe deck. See `../spec.md` for the decisions and ADR 0012 for why.

**Blocked by:** 01

**Status:** ready-for-agent

## The rule

The rule lives in `VocabularyLibrary`.

- [ ] The deck holds exactly `stubbornWords()`, in its order; no second filter or sort
- [ ] 认识 calls the existing `markKnown`, and the Word leaves the Stubborn list
- [ ] 不认识 writes nothing: the Word's set-aside day and Clean Sightings are unchanged

## The screen

- [ ] 再看一遍 on the 难词 screen, no number on it, hidden when the list is empty
- [ ] Reuses the swipe deck from 01: right 认识, left 不认识, tap to flip, the speaker, a snapshot of the words taken when it opens, the double-answer guard
- [ ] The back shows pinyin, English, and the Word Note when there is one
- [ ] The last card leads to the shared `EmptyState`, then back to 难词
- [ ] Decide whether 认识 here fires the success haptic. The shared deck fires it on every 认识 today, which is right for Daily New Words; CONTEXT.md's **Celebration** limits haptics to named moments, so check it before reusing as is
- [ ] **What must not exist here:** a count, a due date, a streak, or the deck appearing anywhere but 难词

## Tests

Build fixtures from an explicit word list, never from a Chinese sentence; assert which Words are Stubborn before asserting the deck.

- [ ] The deck is the Stubborn Words, most-looked-up first
- [ ] 认识 makes a Word Known and takes it out of the next deck
- [ ] 不认识 leaves the Word's set-aside day, sightings and Stubborn status exactly as they were
- [ ] A Word Note shows on the back; a Word without one shows none

## Glossary

- [ ] **Stubborn Deck** goes into `CONTEXT.md`: opened by choice, never due, 不认识 changes nothing. _Avoid_: review, drill, due

## Screen text

- [ ] 再看一遍 and any new deck text get their English in `Localizable.xcstrings`

## Left for the iPhone

- [ ] Swipe through the real deck after a week of reading; does it feel like a second look or like homework?
- [ ] Mark one 认识 and see it gone from 难词
- [ ] Check that a Word Note on the back actually helps
