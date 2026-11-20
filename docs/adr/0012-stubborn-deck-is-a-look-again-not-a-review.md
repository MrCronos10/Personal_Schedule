# The Stubborn Deck is a look-again, not a review

The 难词 screen gains a **再看一遍** button that opens the **Stubborn Deck**: every **Stubborn Word**, most-looked-up first, swiped like **Daily New Words**. 认识 marks the Word **Known** by hand; 不认识 changes nothing. This reverses one line of ticket 05 (`.scratch/vocabulary-and-reading-upgrade/issues/05`), which said the 难词 screen must not have a "review these" button.

Ticket 05's line was protecting the rule of [ADR 0004](0004-known-is-earned-by-reading-not-by-review.md): nothing is ever due, and the list must never feel like owed work. The student asked for a way to practise the Words that keep beating them, and the deck was shaped so that every source of debt is absent, rather than by dropping the rule.

## Considered Options

- **Keep ticket 05's rule and leave 难词 as a list only.** Honest to the original decision, but the most useful list in the app stays something to read and never something to act on, and the Word Note written for these exact Words is only seen by chance.
- **Open the deck from somewhere other than 难词**, such as inside a Word's sheet. Technically keeps the letter of ticket 05 while breaking its spirit just as much, and is harder to find. Rejected as a dodge.
- **A deck on the 词 tab beside 今日新词, with a count of what is waiting.** Rejected: a waiting count is the queue ADR 0004 turned down.
- **The deck on the 难词 screen, with no count, no cap, no schedule and no consequence for 不认识.** Chosen.

## Consequences

- ADR 0004 and [ADR 0006](0006-a-word-set-aside-comes-back.md) stand in full. Nothing is due, nothing accrues, and a day the deck is not opened leaves nothing behind.
- **不认识 changes nothing.** A Stubborn Word has already been looked up in more than one Article, so another "not known" adds no evidence. Calling `setAside` again would restart its thirty days and quietly change what **Daily New Words** offers, so it is not called.
- **认识 is the hand override ADR 0004 already allows.** It skips the three **Clean Sightings**, the same as 认识 in Daily New Words.
- The button carries no number and is hidden when there are no Stubborn Words. The words *review*, *drill* and *due* are avoided for it, on screen and in `CONTEXT.md`.
