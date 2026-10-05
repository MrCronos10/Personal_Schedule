# 04: Reader restyle

**What to build:** `screens/Reading.dc.html`. Source chip, serif title, meta row, red scroll bar, 18 pt / 2.0 body on 田字格 paper, dotted underline on looked-up words, **two red dots under a Word with two Clean Sightings**, inline lookup card (drops below the line, never an overlay), bottom Coach dock with the 读完 button.

**Blocked by:** 01. **Status:** ready-for-agent

## The rule

- [ ] "Near Known" is a library rule (Word with exactly two Clean Sightings, not Known) and is tested at `VocabularyLibrary`; the screen never recomputes it
- [ ] Marking dots changes nothing about counting (ADR 0004)
- [ ] Lookup card keeps the existing Lookup behaviour and wording about its cost
- [ ] Coach dock follows ADR 0008: no counts, no "due"

## Comments
