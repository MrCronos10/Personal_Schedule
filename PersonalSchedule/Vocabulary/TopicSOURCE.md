# Where TopicWordList.json came from

Hand-written. Rebuild it byte for byte with:

```sh
python3 .scratch/topic-list/build-topic-list.py
```

Unlike `HSKWordList.json`, this list is **not** drawn from upstream repos. The
student's topic — chicken and pig manure, organic fertilizer, Cambodian
farming — has no public source list carrying the senses they need. The 125
terms, their pinyin and their glosses are typed in `build-topic-list.py`, and
that script is the only source.

The totals (125 overall; 18 / 17 / 27 / 18 / 22 / 23 across the six groups) are
asserted in the script and pinned by a Swift test, so a tweak to the data
cannot quietly move the denominator the student has been watching.

A gloss is a reminder, not a dictionary entry: at most 70 characters, no
newline (so the Article measured-words cache cannot be fooled), one or two
senses in the direction the student will meet them (visiting a Chinese
fertilizer factory, reading production articles, talking to a supplier).

Fourteen of the terms are also in HSK 4 or HSK 5. [ADR 0007](../../docs/adr/0007-topic-list-sits-beside-the-hsk-levels.md)
explains why their Topic state is kept separate from their HSK state rather
than mirrored. The Swift test `TopicWordListTests.aTermAlsoInHSKKeepsItsOwnEntry`
pins this.
