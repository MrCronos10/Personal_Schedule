# 05: 难词, and the Word Note

**What to build:** The **Words** that keep beating the student, and somewhere to write down how to remember one.

Every **Lookup** has been recorded since ticket 15 — the word, the **Article**, the day — and nothing has ever read it back. So the app silently knows which Words have defeated the student five times across five Articles, which is the most useful thing in the whole store, and shows it nowhere. A **Stubborn Word** is one looked up more than once and still not **Known**.

A **Word Note** is the student's own free text on one Word: a memory trick, where they first met it, why it keeps slipping. It belongs to the Word, not to a day, so it stays out of the **Notes List**, which is about **Completions**.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

## The rule

- [ ] A Stubborn Word is a Word with more than one Lookup that is not Known
- [ ] They are ordered by how many Lookups they have, most first
- [ ] A Word becoming Known leaves the list at once, however many Lookups it had
- [ ] Lookups of Words the app does not measure are not Stubborn Words: they were never recorded as anything
- [ ] A Word Note can be written, changed and cleared, and is kept on the Word
- [ ] A Word Note is never translated: it is the student's own writing

## The screen

- [ ] A 难词 list, reachable from the 阅读 tab, showing each Word, its pinyin, its English, and how many times it has been looked up
- [ ] Tapping one opens the Word, where the Note can be written
- [ ] The Word Note shows wherever a Word is opened, so a note written once is seen again while reading
- [ ] An empty list says so in the quiet voice the rest of the app uses — no Stubborn Words is good news, not a blank screen
- [ ] **What must not exist here:** a count on the tab, a nag, a "review these" button, or any sense that the list is owed work

## Tests

- [ ] A Word looked up twice in two Articles is a Stubborn Word; looked up once, it is not
- [ ] Two Lookups of one Word in the *same* Article — the order is by Lookups, so decide and pin whether that is one or two
- [ ] Marking a Stubborn Word Known takes it off the list
- [ ] Words outside HSK 4 and 5 never appear
- [ ] The list is ordered most-looked-up first
- [ ] A Word Note saves, changes, clears, and survives the Word becoming Known
- [ ] A Word Note never appears in the Notes List

## Glossary

- [ ] **Stubborn Word** and **Word Note** go into `CONTEXT.md` once they exist

## Left for the iPhone

- [ ] Look at the real list after a week of reading and check it reads as useful rather than as a list of failures
- [ ] Write a Note on a Word, meet it again while reading, and see whether the Note actually helps
