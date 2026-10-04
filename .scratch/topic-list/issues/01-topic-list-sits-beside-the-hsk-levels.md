# 11: A Topic List sits beside the HSK Levels

**What to build:** A second word list the student can mark by hand — 农业词, 125 **Topic Words** for their family's manure-to-organic-fertilizer business in Cambodia, grouped into six **Topic Groups**. Its own meter, its own screen, its own progress rows; the HSK **Levels** and **Known** count are untouched.

Why this reopens what [ADR 0005](../../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md) deliberately closed, and why hand-marking only in this version: [ADR 0007](../../../docs/adr/0007-topic-list-sits-beside-the-hsk-levels.md).

**Blocked by:** None.

**Status:** ready-for-human (the taps left need the phone; the Xcode string-extraction pass needs the IDE)

## The rule

- [x] The bundled **Topic List** holds 125 **Topic Words**, split 18 / 17 / 27 / 18 / 22 / 23 across the six **Topic Groups**; the totals are pinned by `TopicWordListTests` so a tweak to the JSON cannot quietly move the denominator
- [x] A Topic Word with its pinyin and short English is read from `PersonalSchedule/Vocabulary/TopicWordList.json`; `TopicSOURCE.md` says why the list is hand-written rather than drawn from a public repo
- [x] 认识 marks a Topic Word **Topic Known**; 其实不认识 takes it back
- [x] A word not on the Topic List (bundled or custom) cannot be marked Topic Known, so a stray input never inflates the meter
- [x] The Topic List meter counts active Topic Words and **Custom Topic Words**; archiving a Custom Topic Word leaves the meter and restoring it brings its Known state back
- [x] A **Custom Topic Word** must be in Chinese and must have an English gloss; a duplicate of a bundled or custom term is refused with a reason
- [x] A bundled Topic Word is never archived — the student only ever puts away a word they added themselves
- [x] Marking any Topic Word writes to `TopicWordProgress` and never to `WordProgress`, so what moves the Topic List meter cannot move the HSK Level numbers
- [x] The 农业词 tab shows the list, grouped by **Topic Group**, with a meter at the top and a chip row for the group filter; the Custom-Topic-Word sheet is reachable from the same screen

## What is not in this ticket

- Reading-based evidence against the Topic List (banking **Clean Sightings** for Topic Words through 读完, segmenting Articles for Topic Words). Deferred to a next ticket; ADR 0007 explains why.

## Comments

- 279 tests pass end to end (`xcodebuild test`, iPhone 16 / iOS 18.3.1). 20 of them are new, 14 in `TopicLibraryTests` and 6 in `TopicWordListTests`.
- `/code-review` was run against the diff; findings worth acting on were folded back in.
- The 农业词 screen was built but was not tapped. The student checks screens by hand on their iPhone (AGENTS.md). The build succeeds; `TopicListView.swift` compiles clean.
- The Swift strings catalog (`PersonalSchedule/Localizable.xcstrings`) is not updated by `xcodebuild build` — Xcode's IDE extracts new keys when the project is next opened. The next IDE build will pull new UI strings into the catalog, where the student can translate them. Until then, English users see the Chinese fallthrough on the 农业词 screen. The ternary-based strings (`isChinese ? "中文" : "English"`) already work in both languages.
- Fourteen of the 125 Topic Words are also on an HSK list (农业, 市场, 技术, 质量…). They keep independent state in each list on purpose; `TopicLibraryTests.markingATopicWordNeverTouchesTheHSKRow` pins that.
