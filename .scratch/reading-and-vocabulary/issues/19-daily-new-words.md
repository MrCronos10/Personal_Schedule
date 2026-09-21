# 19: 今日新词

**What to build:** Ten **Words** of the **Served Level** the student has not met, offered once a day in the 阅读 tab, each marked 认识 or 不认识. This is how a **Level** gets finished: real Articles will never contain all 600 words.

It must stay small and unpunishing. The moment it nags, it is the abandoned flashcard deck [ADR 0004](../../../docs/adr/0004-known-is-earned-by-reading-not-by-review.md) exists to avoid.

**Blocked by:** 18

**Status:** ready-for-human (every check left needs a tap)

## Choosing the ten

`VocabularyLibrary.dailyNewWords(count:progress:day:)`:

- [x] Only Words of the **Served Level** that are not **Known** and have **no `WordProgress` row at all** — a Word the student has already met while reading is on its way already and is not offered here
- [x] Ten, in the **Word List**'s own order, which is roughly by frequency: the most useful words come first
- [x] The same ten for the whole of one **Day**, worked out from the day itself, so leaving the tab and coming back does not reshuffle them
- [x] Fewer than ten left is fine, and none left is fine

## The screen

- [x] A card under the Level meter, headed 今日新词, holding ten rows: the word, its pinyin, its English, and 认识 / 不认识
- [x] 认识 marks the Word **Known** with today as its known day, and the row settles into the green chip from ticket 12
- [x] 不认识 writes a `WordProgress` row at zero clean sightings and takes the row out of today's list. The Word is then "met", so it will not be offered here again — it is now the reading's job, exactly as if it had been tapped in an Article
- [x] A row left alone is left alone. It is neither 认识 nor 不认识, and tomorrow it may be offered again
- [x] When all ten are answered: 今天的新词看完了, and nothing else. No streak, no next-day countdown, no "come back tomorrow"
- [x] When the Served Level has no unmet Words left: a quiet line saying so
- [x] **What must not exist here:** a badge on the tab, a count of what is due, a streak, a reminder, or any mark for a day skipped. A day not opened leaves nothing behind

## Tests

At `VocabularyLibrary`:

- [x] Ten Words come back, all at the Served Level, none Known, none with an existing row
- [x] The same day asked twice gives the same ten in the same order; a different day gives a different ten
- [x] A Word answered 不认识 today is not offered tomorrow
- [x] A Word met while reading is never offered
- [x] 认识 sets known and a known day, and the Level count from ticket 18 goes up by one
- [x] With four Words left in the pool, four come back, not ten and not an error
- [x] With none left, an empty list comes back
- [x] Once HSK 4 is **Passed**, the ten are drawn from HSK 5

## Left for the iPhone

- [ ] Do a day's ten and see how long it actually takes. If it is more than about two minutes, ten is too many — say so rather than living with it
- [ ] Skip a day on purpose and confirm the app says nothing about it anywhere
- [ ] Check 认识 is not too easy to press by accident: marking a word Known by mistake is the one action here that damages the headline number
- [ ] Check the card does not push the Article list off the screen. Reading is the point of this tab; the words are the top-up
