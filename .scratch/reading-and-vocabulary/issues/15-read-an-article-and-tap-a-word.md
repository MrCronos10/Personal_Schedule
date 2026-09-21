# 15: Read an Article and tap a word

**What to build:** The reading screen. An **Article**'s text is split into words, HSK 4 and 5 **Words** are faintly underlined, and tapping any word shows its pinyin and English. A tap on an HSK 4/5 Word writes a **Lookup**, which is the evidence ticket 16 uses against it.

**Blocked by:** 14

**Status:** ready-for-agent

## Splitting the text

- [ ] `VocabularyLibrary.segment(_:)` splits Chinese text into words using `NLTokenizer(unit: .word)` with the language set to `.simplifiedChinese`. This is built into iOS: no library, no network
- [ ] It returns each word **with its range in the original text**, so the screen can draw the text as it was written, punctuation and line breaks intact. The student must read the real article, not a list of tokens
- [ ] Words are matched against `HSKWordList` exactly as segmented. No stemming, no variants, no traditional conversion

## The screen

- [ ] Opening an Article from the 阅读 list pushes a reading screen: the title at headline size, 来源 and imported day in meta type, then the text at body size with generous line height — this is the one screen in the app made for reading, so it gets the room
- [ ] HSK 4 and HSK 5 Words carry a thin underline in `outline-variant`. Level 4 and level 5 look the same: the student is reading, not being quizzed
- [ ] A Word already **Known** carries no underline. It is not new any more
- [ ] Any word can be tapped, HSK or not
- [ ] 读完 sits at the bottom, always reachable. It does nothing yet — ticket 16 gives it its job

## The lookup sheet

- [ ] Tapping a word opens a short sheet: the word large in Noto Serif SC, its pinyin under it, its English under that
- [ ] A word with no `HSKWordList` entry — HSK 1–3, a name, a number — shows the word and a quiet line saying there is nothing recorded for it. It is not an error and nothing is written ([ADR 0005](../../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md))
- [ ] Tapping an HSK 4/5 Word writes a `WordLookup`: word, the Article, today's **Day**. One row per tap; tapping the same Word twice in one Article writes two rows and means the same thing as one
- [ ] The sheet also carries 我认识这个词, which marks the Word **Known** by hand and closes the sheet. Its underline goes. This is the override [ADR 0004](../../../docs/adr/0004-known-is-earned-by-reading-not-by-review.md) allows
- [ ] Tapping a Word that is already Known offers 其实不认识, which returns it to not-Known with zero **Clean Sightings**

## The record

- [ ] `WordLookup`: word, article (optional link with an inverse), day. `WordProgress`: word, level, clean sightings (default 0), known (default no), known day (optional)
- [ ] `WordProgress` rows are written lazily — a Word never met has no row and counts as not Known, so the store does not carry 1,900 empty rows

## Tests

At `VocabularyLibrary`:

- [ ] A sentence splits into the words a reader would expect, and 中国人 does not come back as three separate characters
- [ ] Punctuation, numbers and Latin inside the text survive segmentation and are not offered as Words
- [ ] Each returned word's range points back at the same characters in the original text
- [ ] `hskWords(in:)` returns only words that `HSKWordList` places at level 4 or 5, each once, with duplicates in the text collapsed
- [ ] Marking a Word Known by hand sets known and a known day, and leaves clean sightings alone
- [ ] 其实不认识 returns a Known Word to not-Known **and** to zero clean sightings — it must not leave three sightings behind, or the Word would be Known again at the next 读完

## Left for the iPhone

- [ ] Read a real article end to end and judge the line height and the size. This screen is where you will spend the most time
- [ ] Check the underlines are visible but not shouting — they should look like a pencil mark, not a link
- [ ] Tap a word you don't know and see whether the pinyin and one English gloss is really enough, or whether you reach for a dictionary anyway
- [ ] Tap a name or a number and check the quiet empty sheet does not feel like a failure
