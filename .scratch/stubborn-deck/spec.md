# The Stubborn Deck

A **再看一遍** button on the 难词 screen opens the **Stubborn Deck**: every **Stubborn Word**, swiped like **Daily New Words**. It is a place the student chooses to visit, never a queue. [ADR 0012](../../docs/adr/0012-stubborn-deck-is-a-look-again-not-a-review.md) records why this reverses ticket 05's "no review button" line, and why ADR 0004 still holds.

## Decisions (grilled 2026-11-20)

1. **认识 marks the Word Known** by hand, through the existing `markKnown`. It leaves the Stubborn list.
2. **不认识 changes nothing.** No `setAside`, no restarted thirty days, no change to what Daily New Words offers.
3. **The back of a card** shows pinyin, English, and the student's **Word Note** if the Word has one. No lookup count on the card.
4. **Every Stubborn Word, most-looked-up first**, the same order `stubbornWords()` already gives. No cap.
5. **Opened only from 再看一遍 on 难词.** No number on the button, hidden when there are no Stubborn Words, nothing on 今天 or the 词 tab.
6. **The name is Stubborn Deck.** Avoid *review*, *drill* and *due*.

## Tickets

- `01` the swipe deck stands on its own (prefactor)
- `02` the Stubborn Deck
