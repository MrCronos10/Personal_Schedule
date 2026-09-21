# 15: Read an Article and tap a word

**What to build:** The reading screen. An **Article**'s text is split into words, HSK 4 and 5 **Words** are faintly underlined, and tapping any word shows its pinyin and English. A tap on an HSK 4/5 Word writes a **Lookup**, which is the evidence ticket 16 uses against it.

**Blocked by:** 14

**Status:** ready-for-human (every check left needs a tap)

## Splitting the text

- [x] `VocabularyLibrary.segment(_:)` splits Chinese text into words using `NLTokenizer(unit: .word)` with the language set to `.simplifiedChinese`. This is built into iOS: no library, no network
- [x] It returns each word **with its range in the original text**, so the screen can draw the text as it was written, punctuation and line breaks intact. The student must read the real article, not a list of tokens
- [x] Words are matched against `HSKWordList` exactly as segmented. No stemming, no variants, no traditional conversion

## The screen

- [x] Opening an Article from the 阅读 list pushes a reading screen: the title at headline size, 来源 and imported day in meta type, then the text at body size with generous line height — this is the one screen in the app made for reading, so it gets the room
- [x] HSK 4 and HSK 5 Words carry a thin underline in `outline-variant`. Level 4 and level 5 look the same: the student is reading, not being quizzed
- [x] A Word already **Known** carries no underline. It is not new any more
- [x] Any word can be tapped, HSK or not
- [x] 读完 sits at the bottom, always reachable. It does nothing yet — ticket 16 gives it its job

## The lookup sheet

- [x] Tapping a word opens a short sheet: the word large in Noto Serif SC, its pinyin under it, its English under that
- [x] A word with no `HSKWordList` entry — HSK 1–3, a name, a number — shows the word and a quiet line saying there is nothing recorded for it. It is not an error and nothing is written ([ADR 0005](../../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md))
- [x] Tapping an HSK 4/5 Word writes a `WordLookup`: word, the Article, today's **Day**. One row per tap; tapping the same Word twice in one Article writes two rows and means the same thing as one
- [x] The sheet also carries 我认识这个词, which marks the Word **Known** by hand and closes the sheet. Its underline goes. This is the override [ADR 0004](../../../docs/adr/0004-known-is-earned-by-reading-not-by-review.md) allows
- [x] Tapping a Word that is already Known offers 其实不认识, which returns it to not-Known with zero **Clean Sightings**

## The record

- [x] `WordLookup`: word, article (optional link with an inverse), day. `WordProgress`: word, level, clean sightings (default 0), known (default no), known day (optional)
- [x] `WordProgress` rows are written lazily — a Word never met has no row and counts as not Known, so the store does not carry 1,900 empty rows

## Tests

At `VocabularyLibrary`:

- [x] A sentence splits into the words a reader would expect, and 中国人 does not come back as three separate characters
- [x] Punctuation, numbers and Latin inside the text survive segmentation and are not offered as Words
- [x] Each returned word's range points back at the same characters in the original text
- [x] `hskWords(in:)` returns only words that `HSKWordList` places at level 4 or 5, each once, with duplicates in the text collapsed
- [x] Marking a Word Known by hand sets known and a known day, and leaves clean sightings alone
- [x] 其实不认识 returns a Known Word to not-Known **and** to zero clean sightings — it must not leave three sightings behind, or the Word would be Known again at the next 读完

## Left for the iPhone

- [ ] Read a real article end to end and judge the line height and the size. This screen is where you will spend the most time
- [ ] Check the underlines are visible but not shouting — they should look like a pencil mark, not a link
- [ ] Tap a word you don't know and see whether the pinyin and one English gloss is really enough, or whether you reach for a dictionary anyway
- [ ] Tap a name or a number and check the quiet empty sheet does not feel like a failure

## Comments

- **A test found that 33 Words could never be reached, and that changed the design.** `NLTokenizer` splits by its own idea of a word, which is not the **Word List**'s: 不过 comes back as 不 + 过, 弹钢琴 as 弹 + 钢琴, 名胜古迹 as 名胜 + 古迹, 百分之 as 百分 + 之. Matching tokens straight against the list would have left those 33 entries permanently invisible — never underlined, never looked up, never counted toward the 1,900, with nothing on screen to say anything was missing. That is exactly the silent failure ADR 0005 is written against.
- **The fix joins neighbouring tokens when the join is itself a Word**, longest first, up to four tokens. It works *outward from the tokenizer's boundaries* rather than scanning the raw text, which is what stops 国王 being discovered inside 中国 + 王子; there is a test for that. A run with anything dropped between its tokens — a space, a comma — is not joined, because those were never neighbours.
- **Two tests hold the coverage down**: one walks all 1,898 non-grammar entries and asserts each can be found at all, and one puts nine of the awkward ones inside a paragraph of ordinary prose, which is the harder case and the one that nearly slipped through. The first test originally claimed in its comment to test prose and did not; `/code-review` caught the gap and the second test is the answer.
- **Grammar entries confirm the ticket-13 judgement was right.** `grammarEntriesNeverMatchAWordInAnArticle` reads a sentence with bare 得 and 等 in it and finds neither. Had the annotation been stripped back then, 得 would now be underlined in nearly every sentence in the app.
- **Words are rendered as links under a private `psword://` scheme.** SwiftUI has no per-word tap inside flowing text, and the alternative — laying words out in a wrapping grid — would break the reading flow on the one screen built for reading. The scheme is handled by the screen itself and never leaves the app. If it turns out badly on the phone, this is the piece to replace.

### After `/code-review`

Six findings, all taken:

- **归档 inside a `NavigationLink` label would never have fired.** A `Button` nested in a link's label is not hit-tested separately outside a `List`, so tapping 归档 would have pushed the reader and archived nothing — leaving no way at all to archive an unread Article. Only the text column is the link now, with 归档 beside it.
- **The lookup sheet was a fixed 260 pt with no scroll.** The longest bundled gloss runs 70 characters, and at a large Dynamic Type size it would push 我认识这个词 below the sheet, where it could not be reached and the Word could never be marked Known. It scrolls now, at `.medium`.
- **The whole Article was re-tokenized on every render.** Each tap writes a row, which invalidates the query, which re-ran `NLTokenizer` over a whole 微信 article on the main actor. The split is worked out once into `@State` now, and only the underlines are recomputed when a Word becomes Known.
- **Two screens fetched every `WordProgress` row** to answer a question about one Word, growing toward 1,900 as the year goes on. The reader now asks only for Known Words, and the sheet only for the one Word — which also removes the second copy of a lookup `VocabularyLibrary` already owns.
- **The new `NavigationStack` put a bare system bar on the 阅读 tab**, which no other tab has. It is hidden on the tab, which has its own 田字格 header, and painted in `Theme.paper` on the reader, which needs its back button.

129 tests pass, 11 suites, up from 109 in 10.
