# 02: Clean Sightings remember their Article

**What to build:** A **Word** can say *where* it was earned. A **Clean Sighting** becomes a record carrying the **Article** it came from, and those records *are* the count, so there is no second number to drift from them. A **Lookup** deletes them along with the count, so a list of Articles can never disagree with the number it is explaining.

On screen, that shows up as the one thing a Lookup can honestly say: which Articles this tap just cleared. See "The screen" below for why it is not a standing list of where the Word was earned.

Today a Clean Sighting is a bare number, so the app knows a Word has two and cannot say which two readings proved it. [ADR 0004](../../../docs/adr/0004-known-is-earned-by-reading-not-by-review.md) says a Lookup returns a Word to zero and "all three Articles must be earned again" — once the Articles are named, that has to be true of the names too.

**Blocked by:** None (can start immediately)

**Status:** ready-for-human (the checks left need the phone, and one needs an install over existing data)

## The rule

- [x] Finishing an **Article** for the first time records one Clean Sighting per un-looked-up **Word**, each remembering the Article it came from
- [x] A Word's sighting count is the number of those records, with no second copy of the number to drift from them
- [x] **Known** counts distinct **Articles**, not records: nothing in the store stops two rows describing one reading, and two copies must not be worth two readings
- [x] A **Lookup** deletes every Clean Sighting record for that Word, matching the count returning to zero
- [x] Still at most one sighting per Word per Article, and still only the first time that Article is finished: rereading proves nothing new
- [x] An **Archived Article** keeps the sightings it gave. Articles are archived, never deleted, so a Known count can never fall because of tidying up
- [x] 其实不认识 clears the records too, for the same reason it clears the count

## The screen

**This section was written wrong and is corrected here.** It asked for "tapping a Word shows the Articles that earned it", which cannot happen: the only way to that sheet is tapping a word in an Article, and that same tap *is* the **Lookup** that clears the records. A standing list of where a Word was earned needs a way into a Word that is not a Lookup, which ticket 05 adds. What this ticket shows instead is the one thing that tap can honestly say.

- [x] A Lookup names the Articles it just cleared, which now have to be read again (ADR 0004)
- [x] Said quietly and in the muted voice, not as a warning or a scolding: the line says what to do next, not what the student did wrong. This is the only place the app has ever admitted that asking for help costs something
- [x] A Word with nothing behind it — much the commonest tap — shows nothing at all there, because there is nothing to say
- [x] A Word outside HSK 4 and 5 shows nothing here: it carries no state at all (ADR 0005)
- [x] The student's own Article titles, never translated

## Tests

At `VocabularyLibrary`, from a fixture built off an explicit word list, never a sentence written by eye:

- [x] Finishing two Articles containing one Word gives it two records, naming both
- [x] The same Article finished twice gives one record, not two
- [x] A Word appearing nine times in one Article gets one record
- [x] A Lookup leaves the Word with no records and a count of zero
- [x] Three records in three Articles makes the Word Known, and the records name those three
- [x] Two records describing *one* Article do not make a Word Known off two readings
- [x] Archiving an Article leaves its records standing
- [x] Words the app does not measure record nothing

## Glossary

- [x] **Clean Sighting** in `CONTEXT.md` regains the clause that each one remembers its Article, and that a Lookup takes them away together — held back until it was true

## Left for the iPhone

- [ ] **Install over existing data first.** A stored property was removed and a new record type added, with no migration plan — SwiftData should handle both, but if it does not the app will fail to launch, and no test can cover a store written by the old schema
- [ ] Tap a Word that had two sightings and judge the 这些文章要重新读 line: it has to read as information, not as a telling-off. If it stings, reword it or take it out
- [ ] Tap a Word with nothing behind it and confirm the sheet looks exactly as it did before
- [ ] Confirm Words at one or two sightings really did go back to zero, and that the Level count did not fall

## Comments

Built test-first. Whole suite green at **206 tests**, up from 202.

The first pass was committed as `d82322f` before the review came back, and the review then found that its headline screen was dead: `WordLookupSheet` is reached from exactly one place, and the tap that opens it records the **Lookup** that deletes the records, so the new 读过的文章 list was always the empty state — and that empty state told the student they had never read the Word in anything, minutes after they had. Fixed by capturing the Articles before the Lookup and saying the honest thing instead: these need reading again. The ticket's screen section above was rewritten rather than quietly ticked, because it asked for something the app's one route to that sheet cannot do.

Also from the review:

- **Known counted records, not Articles.** Two rows describing one reading — which iCloud sync can produce, since no field is unique — would have made a Word Known off two readings. Now counts distinct Articles, with a test.
- **`bank` fetched the whole sightings table** on every 读完, and that table grows all year. Narrowed to the Words in the Article in hand.
- **An order-dependent assertion.** Three Articles banked on one day tie on the sort key, so asserting their order relied on the store's unspecified tie-break. Compared as a set, and `cleanSightings(of:)` no longer promises an order it cannot keep.
- **Ungrammatical English** on a string that has since been replaced anyway.

Not seen running: anything on the phone, including the migration, which is the one failure mode that would stop the app launching.
