# 02: Clean Sightings remember their Article

**What to build:** A **Word** can say *where* it was earned. Tapping a Word shows which **Articles** gave it its **Clean Sightings**, not just how many it has. A **Lookup** deletes those records along with the count, so the list can never disagree with the number it is explaining.

Today a Clean Sighting is a bare number, so the app knows a Word has two and cannot say which two readings proved it. [ADR 0004](../../../docs/adr/0004-known-is-earned-by-reading-not-by-review.md) says a Lookup returns a Word to zero and "all three Articles must be earned again" — once the Articles are named, that has to be true of the names too.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

## The rule

- [ ] Finishing an **Article** for the first time records one Clean Sighting per un-looked-up **Word**, each remembering the Article it came from
- [ ] A Word's sighting count is the number of those records, with no second copy of the number to drift from them
- [ ] A **Lookup** deletes every Clean Sighting record for that Word, matching the count returning to zero
- [ ] Still at most one sighting per Word per Article, and still only the first time that Article is finished: rereading proves nothing new
- [ ] An **Archived Article** keeps the sightings it gave. Articles are archived, never deleted, so a **Known** count can never fall because of tidying up
- [ ] 其实不认识 clears the records too, for the same reason it clears the count

## The screen

- [ ] Tapping a Word shows the Articles that earned it, by their own titles, never translated
- [ ] A Word with no sightings yet says so quietly rather than showing an empty area
- [ ] A Word outside HSK 4 and 5 shows nothing here: it carries no state at all (ADR 0005)

## Tests

At `VocabularyLibrary`, from a fixture built off an explicit word list, never a sentence written by eye:

- [ ] Finishing two Articles containing one Word gives it two records, naming both
- [ ] The same Article finished twice gives one record, not two
- [ ] A Word appearing nine times in one Article gets one record
- [ ] A Lookup leaves the Word with no records and a count of zero
- [ ] Three records in three Articles makes the Word Known, and the records name those three
- [ ] Archiving an Article leaves its records standing
- [ ] Words the app does not measure record nothing

## Glossary

- [ ] **Clean Sighting** in `CONTEXT.md` regains the clause that each one remembers its Article, and that a Lookup takes them away together — held back until it was true

## Left for the iPhone

- [ ] Tap a Word with two sightings and check the two Article titles read as a reminder of real reading, not as a database listing
- [ ] Tap a Word up after it had sightings, and confirm the list empties with the count
