# 04: Readability on the Article row

**What to build:** Each **Article** row says what share of its measured **Words** the student already has **Known**. A menu with twenty-five unknown HSK 5 Words is the most discouraging possible sitting — twenty-five **Lookups** and no progress — and today there is no way to see it coming, or to watch the same Article get easier across the year.

**Readability** is information and never a gate. No Article is locked, hidden, reordered or marked too hard: [ADR 0005](../../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md) rejected that outright, and an app that refused to open the menu in the student's hand would be absurd.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

## The rule

- [ ] Readability is the share of an Article's measured Words that are **Known**, counted once per distinct Word however often it appears
- [ ] Words the app does not measure — HSK 1–3, names, numbers — are not in the denominator
- [ ] An Article with no measured Words at all has no Readability, and says nothing rather than 0%
- [ ] It is stored, not computed on every render: splitting every Article on each render would run the tokenizer over the whole library every time a tap changed one Word
- [ ] It is recomputed when an Article is imported and after each 读完, so it moves as the year goes on

## The screen

- [ ] The share sits on the Article's row, quiet, next to the existing meta
- [ ] Nothing in the list is ordered, greyed, badged or hidden by it
- [ ] Archived rows show it too

## Tests

Build the fixture from an explicit word list. 篇, 干净, 软 and many ordinary-looking words are on the HSK lists, so a sentence written by eye holds more measured Words than it appears to — assert what the fixture contains before asserting a share.

- [ ] An Article of four measured Words with one Known reads one quarter
- [ ] A Word repeated nine times counts once
- [ ] Unmeasured words change neither numerator nor denominator
- [ ] An Article with no measured Words has no Readability rather than zero
- [ ] Marking a Word Known and rebuilding raises the share of an Article holding it

## Glossary

- [ ] **Readability** goes into `CONTEXT.md` once it exists

## Left for the iPhone

- [ ] Check the number reads as encouragement rather than as a grade
- [ ] Confirm the reading list still reads as a list of things to read, not a scoreboard
