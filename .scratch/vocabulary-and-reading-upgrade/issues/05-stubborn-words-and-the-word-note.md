# 05: 难词, and the Word Note

**What to build:** The **Words** that keep beating the student, and somewhere to write down how to remember one.

Every **Lookup** has been recorded since ticket 15 — the word, the **Article**, the day — and nothing has ever read it back. So the app silently knows which Words have defeated the student five times across five Articles, which is the most useful thing in the whole store, and shows it nowhere. A **Stubborn Word** is one looked up more than once and still not **Known**.

A **Word Note** is the student's own free text on one Word: a memory trick, where they first met it, why it keeps slipping. It belongs to the Word, not to a day, so it stays out of the **Notes List**, which is about **Completions**.

**Blocked by:** None (can start immediately)

**Status:** ready-for-human (the checks left need the phone)

## The rule

**The decision the ticket left open, pinned:** a Stubborn Word counts distinct *Articles*, not raw Lookups. Two taps inside one reading session are not twice the evidence three separate sittings are — this matches how a **Clean Sighting** already counts one Article regardless of how often a Word appears in it, and it keeps one nervous re-tap from making a Word look worse than it is. The on-screen count is the same number the ordering uses, so the two never disagree.

- [x] A Stubborn Word is a Word looked up in more than one **Article** that is not **Known**
- [x] They are ordered by Article count, most first
- [x] A Word becoming Known leaves the list at once, however many Lookups it had
- [x] Lookups of Words the app does not measure are not Stubborn Words: they were never recorded as anything, and `stubbornWords()` guards this a second time defensively even though `lookUp` already refuses to record one
- [x] A Word Note can be written, changed and cleared, and is kept on the Word
- [x] A Word Note is never translated: it is the student's own writing

## The screen

- [x] A 难词 list, reachable from a quiet link on the 阅读 tab, showing each Word, its pinyin, its English, and how many Articles it has been looked up in
- [x] Tapping one opens the same `WordLookupSheet` a reading tap opens, where the Note can be written
- [x] The Word Note shows wherever a Word is opened, so a note written from 难词 is seen again mid-reading, and one written mid-reading is seen again from 难词
- [x] An empty list says so in the quiet voice the rest of the app uses — no Stubborn Words is good news, not a blank screen
- [x] **What must not exist here:** a count on the tab, a nag, a "review these" button, or any sense that the list is owed work — the entry point is a plain link with no number on it

## Tests

- [x] A Word looked up twice in two Articles is a Stubborn Word; looked up once, it is not
- [x] Two Lookups of one Word in the *same* Article count as one, not two — pinned with its own test
- [x] Marking a Stubborn Word Known takes it off the list
- [x] Words outside HSK 4 and 5 never appear, tested directly against `stubbornWords()` rather than only against `lookUp`'s own upstream guard
- [x] The list is ordered most-looked-up first
- [x] A Word Note saves, changes, clears, and survives the Word becoming Known
- [x] A Word Note never appears among Completions

## Glossary

- [x] **Stubborn Word** and **Word Note** go into `CONTEXT.md` once they exist

## Left for the iPhone

- [ ] Look at the real list after a week of reading and check it reads as useful rather than as a list of failures
- [ ] Write a Note on a Word, meet it again while reading, and see whether the Note actually helps
- [ ] Confirm the 难词 link on the 阅读 tab doesn't compete for attention with 今日新词 right above it
- [ ] Check the note field's placeholder and behaviour at a large Dynamic Type size

## Comments

Built test-first. Whole suite green at **231 tests**, up from 222.

The ticket explicitly left one decision open: whether two Lookups of one Word in the same Article count as one or two. Decided for one, matching how a Clean Sighting already counts one Article regardless of repetition — the same shape of decision the app has already made once, so it made itself. Pinned with `twoLookupsInOneArticleCountAsOne` and written into `CONTEXT.md`'s Stubborn Word entry so a future reader doesn't have to rediscover it.

`StubbornWordsView` initially fetched its list from a plain computed property, relying on two declared-but-unused `@Query` properties purely for their side effect of forcing SwiftUI to re-render. Caught before running anything and rewritten to match `ReadingView`'s own established `refresh()` + hashed-signature + `.onChange` pattern instead, since relying on an unused `@Query`'s invalidation as an undocumented side channel isn't a pattern this codebase actually uses anywhere else.

`/code-review` found one real thing: seeding `noteDraft` from the stored Note in `.task(id: word)` is itself a change `onChange(of:)` sees, so opening a Word that already has a Note wrote it straight back to the store every single time, having changed nothing. Fixed with a guard comparing the trimmed draft against what's actually stored before writing.

Not seen running: anything on the phone, including whether the 难词 entry point sits well next to 今日新词 or crowds it.
