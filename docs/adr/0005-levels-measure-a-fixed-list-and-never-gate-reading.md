# Levels measure a fixed list and never gate reading

A **Level** counts **Known** Words against the whole of its **Word List** — HSK 4 out of 600, HSK 5 out of 1,300, from the HSK 2.0 standard, counting each level's new words only. **Passed** at four fifths. Passing decides one thing: which Level **Daily New Words** are drawn from. It never decides what the student may read.

Two alternatives were live. Counting against *the words that appeared in the student's Articles* makes the number fall every time something new is imported, which punishes exactly the behaviour ADR 0004 is built to reward. Counting against the *cumulative* lists (1,200 and 2,500) pads the score with HSK 1–3 words the student already owns, so the number would start near half full and mean nothing. A fixed denominator of words actually worth learning is the only one that can only go up and still be honest.

Locking HSK 5 Articles behind HSK 4 was rejected outright. The student imports real writing from real life in Hangzhou — a teahouse menu does not know what level it is, and an app that refuses to open one the student is holding would be absurd and would be the reason they stopped using it.

## Considered Options

- **HSK 3.0 (2021) lists.** What the current exam uses, but the bands are renumbered and much larger, and the student's teachers and textbooks in Hangzhou use HSK 2.0. Rejected as a mismatch with the materials actually to hand.
- **Cumulative lists, with HSK 1–3 auto-marked Known on first run.** Honest arithmetic, but it needs 900 rows written at install to say something already assumed, and the totals then no longer match what the student would recognise as "HSK 4".
- **100% to pass.** Turns the last two hundred rare words into a wall to sit behind for months. Four fifths is the point where HSK 5 words are the better use of attention.

## Consequences

- The **Word List** is bundled, read-only, and never edited by the app. Changing its contents later would move the denominator under a number the student has been watching for a year, so it is fixed for the year.
- Words outside HSK 4 and 5 carry no state at all. They are split out of an Article and can be tapped for pinyin, but a **Lookup** on one records nothing. Adding the student's own words is a separate feature with a separate number, not this one.
- Reading alone will not finish a Level: real Articles will never contain all 600 words. **Daily New Words** exists to cover the remainder, and is the only part of the app that offers Words the student has not met.
- The HSK 4 / HSK 5 wording appears on exactly one screen, as a list name. Nothing in the app is described as an exam, a test, or a qualification, per **Goal** in CONTEXT.md.
