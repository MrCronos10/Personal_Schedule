# 04: Reader restyle

**What to build:** `screens/Reading.dc.html`. Source chip, serif title, meta row, red scroll bar, 18 pt / 2.0 body on 田字格 paper, dotted underline on looked-up words, **two red dots under a Word with two Clean Sightings**, inline lookup card (drops below the line, never an overlay), bottom Coach dock with the 读完 button.

**Blocked by:** 01. **Status:** ready-for-human

## The rule

- [x] "Near Known" is a library rule (Word with exactly two Clean Sightings, not Known) and is tested at `VocabularyLibrary`; the screen never recomputes it (`isNearKnown`, `nearKnownWords(among:)`; the reader passes its cached segmented Words).
- [x] Marking dots changes nothing about counting (ADR 0004): near-Known is read from the existing Clean Sightings, nothing is written.
- [x] Lookup card keeps the existing Lookup behaviour and wording about its cost (`WordLookupContent` / `clearedArticles`, unchanged).
- [x] Coach dock follows ADR 0008: no counts, no "due" (`CoachDock`, unchanged).

## Comments

Much of the reader was already in place (serif title, red progress bar, inline lookup card dropping under the paragraph, Coach dock, 读完, 田字格 ground). This ticket added the **Near Known** rule and its markings.

**New library rule (TDD, red→green):** `VocabularyLibrary.isNearKnown(_:)` — not Known, seen cleanly in exactly `sightingsForKnown - 1` (two) different Articles — plus `nearKnownWords(among:)` for the reader, resolved in two grouped fetches (the `bank` shape), taking the Words the reader already holds so the tokenizer never re-runs. Six tests.

**Reader (visual, phone-checked — the screen is reached by tapping into an Article):**
- Near-Known Words carry a **red dotted underline** (the "two red dots"); looked-up Words a **faded dotted** underline; other measured Words the plain grey rule.
- Meta row gains the source as a **chip** and "· N 个快认识了" in red when any Word is near Known.
- One new string (个快认识了) with English.

**Rendering note:** exactly two discrete dots under a Word isn't expressible in the `AttributedString`/`Text` layout the reader uses; a red dotted underline is the faithful, low-risk rendering and reads as red dots. A custom `TextRenderer` could draw exactly two if wanted later.

**/code-review (5 findings, all fixed):** N+1 fetches in `nearKnownWords` → two grouped fetches; `nearKnownWords(in:)` re-tokenized the article → takes cached Words via `among:`; `SpeakerButton` lost its meta styling → base style restored on the HStack; the count-test used a hand-written sentence → rebuilt from an explicit Word list (AGENTS.md); two library instances in `render()` → one.

**Not seen running / left for the phone:** the red dots, dotted looked-up underline, source chip and near-Known count in the real reader, light and dark.
