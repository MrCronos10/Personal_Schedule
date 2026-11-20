# 02: The Stubborn Deck

**What to build:** A 再看一遍 button on the 难词 screen that opens every **Stubborn Word** as a swipe deck. See `../spec.md` for the decisions and ADR 0012 for why.

**Blocked by:** 01

**Status:** ready-for-human (the swiping and how the card looks need the phone)

## The rule

The rule lives in `VocabularyLibrary`.

- [x] The deck holds exactly `stubbornWords()`, in its order; no second filter or sort
- [x] 认识 calls the existing `markKnown`, and the Word leaves the Stubborn list
- [x] 不认识 writes nothing: the Word's set-aside day and Clean Sightings are unchanged

## The screen

- [x] 再看一遍 on the 难词 screen, no number on it, hidden when the list is empty
- [x] Reuses the swipe deck from 01: right 认识, left 不认识, tap to flip, the speaker, a snapshot of the words taken when it opens, the double-answer guard
- [x] The back shows pinyin, English, and the Word Note when there is one
- [x] The last card leads to the shared `EmptyState`, then back to 难词
- [x] Decide whether 认识 here fires the success haptic. The shared deck fires it on every 认识 today, which is right for Daily New Words; CONTEXT.md's **Celebration** limits haptics to named moments, so check it before reusing as is
- [x] **What must not exist here:** a count, a due date, a streak, or the deck appearing anywhere but 难词

## Tests

Build fixtures from an explicit word list, never from a Chinese sentence; assert which Words are Stubborn before asserting the deck.

- [x] The deck is the Stubborn Words, most-looked-up first
- [x] 认识 makes a Word Known and takes it out of the next deck
- [x] 不认识 leaves the Word's set-aside day, sightings and Stubborn status exactly as they were
- [x] A Word Note shows on the back; a Word without one shows none

## Glossary

- [x] **Stubborn Deck** goes into `CONTEXT.md`: opened by choice, never due, 不认识 changes nothing. _Avoid_: review, drill, due

## Screen text

- [x] 再看一遍 and any new deck text get their English in `Localizable.xcstrings`

## Left for the iPhone

- [ ] Swipe through the real deck after a week of reading; does it feel like a second look or like homework?
- [ ] Mark one 认识 and see it gone from 难词
- [ ] Check that a Word Note on the back actually helps

## Comments

Built test-first in `StubbornDeckTests`. Whole suite green at **417 tests**, up from 414.

- **Red → green:** a Stubborn Word carries its Word Note (`StubbornWord.note`); `answerInStubbornDeck(_:known:on:)` with 认识 marks the Word Known and it leaves the next deck.
- **Passed on first run, kept as a guard:** 不认识 changes nothing. It answers on a *later* day, so a stray `setAside` would show as a moved set-aside day; it also checks Clean Sightings, Known and Stubborn status.
- **Order:** the deck is `stubbornWords()` passed straight through, so its order is the one `StubbornWordsTests.orderedMostLookedUpFirst` already pins. No second sort.
- **Word Note on the back:** the rule (note filled in or nil) is tested; the card showing it is screen code, left for the phone.
- **Haptic, decided:** kept on 认识. CONTEXT.md's **Small Celebration** already marks a Word crossing to Known, which is what 认识 here does.

The deck from 01 gained an optional `note` and a `finished` view slot, so the Stubborn Deck can end on `EmptyState` (回到难词) while Daily New Words keeps its own line. Three new strings with English; the `Localizable.xcstrings` edit was written in Xcode's own format so the diff is only the three entries.

`/code-review`, two axes:

- **Spec:** nothing missing or wrong. Noted as additions beyond the ticket, all kept: a 完成 button on the sheet, the Note read out by VoiceOver with the meaning, and the deck's finished line becoming a view slot (needed for `EmptyState`).
- **Standards:** no hard violations. Fixed: Word Notes are looked up once by Word instead of searched for on every card; the sheet's bar is painted paper, per "Look". Kept: `answerInStubbornDeck` takes a Bool so the library doesn't depend on a view type. Noted, not changed here: Daily New Words still holds its 认识/不认识 switch in the view rather than the library — older than this ticket, worth its own cleanup.

Not seen running: the sheet, the swipe inside its scroll view, and the Note on a card.

## Left for the iPhone (from review)

- [ ] Swipe left and right inside the 再看一遍 sheet and check the swipe doesn't fight the scroll
