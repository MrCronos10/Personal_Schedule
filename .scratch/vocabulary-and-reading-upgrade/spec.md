# Vocabulary and reading, upgraded

The reading feature (tickets 12–20) works: **Articles** come in, **Words** are tapped, **Clean Sightings** bank, **Levels** move. This round is about making it worth opening — and about one hole found while looking.

## What this round is, and is not

**Delight and richness, not game mechanics.** [ADR 0004](../../docs/adr/0004-known-is-earned-by-reading-not-by-review.md) rejected streaks, badges and review queues, and that stands. Nothing here is ever due, nothing accrues, and a day not opened still leaves nothing behind. "More fun" here means the app showing the student what they have actually done, sounding like real Chinese, and being easier to feed.

**Offline.** No new network dependency anywhere. [ADR 0001](../../docs/adr/0001-native-swift-app-first.md) chose native Swift for weak internet in China; text-to-speech and text recognition are both on-device, and nothing new is fetched.

**Every Article stays the student's own.** A bundled starter library of graded readers was considered and dropped. [ADR 0005](../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md) is proud that "a teahouse menu does not know what level it is", and the point of the feature is reading the Chinese in front of you in Hangzhou. Ticket 07 makes real content easier to capture instead.

## The hole found on the way

**Daily New Words** offered only Words with no record at all, and answering 不认识 created one — so every Word the student admitted to not knowing left the pool for good, with only three Clean Sightings in three Articles left as a path. ADR 0005 says in its own consequences that reading alone will never finish a Level. The Words most in need of the top-up were the exact ones it had stopped serving, and the **Level** could stall permanently with nothing on screen to say why.

Fixed in ticket 01, and written up as [ADR 0006](../../docs/adr/0006-a-word-set-aside-comes-back.md).

## Deferred, on purpose

These were discussed and left out. They are recorded so they are not rediscovered as new ideas.

- **Bundled example sentences on a Word.** The richest thing a Word could gain, and the one needing most care: `Vocabulary/SOURCE.md` already argues that a wrong pinyin is worse than none, and a wrong example sentence is worse still. It needs a licensed, vetted source and generator work on the scale of ticket 13, not a pass bolted onto this round.
- **A bundled starter library of Articles.** Dropped, not deferred. See above.
- **A bridge from reading to speaking.** The **Goal** is conversation, and everything in this feature is receptive: read, tap, hear, mark. An obvious bridge exists — a **Known** Word prompting the student to use it, landing as an ordinary **Action** — and it is the one idea here that could become the daily obligation ADR 0004 exists to prevent. It deserves its own grilling session and probably its own ADR.
- **An incremental count of distinct Articles per Word, on `WordProgress`.** Found by ticket 09's round-wide review: `VocabularyLibrary.stubbornWords()` fetches every `WordLookup` ever recorded on each call, the same unbounded-growth shape ticket 02 deliberately avoided for `CleanSighting`. Not urgent at the scale of one student's year, but real. Scoped as ticket 10.

## Order

01 is done. 02 → 03 → 08 is the one real chain; 04, 05, 06 and 07 can each start immediately. 09 closes the round.
