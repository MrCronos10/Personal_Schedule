# 06: Vocabulary and swipe deck

**What to build:** `screens/Words.dc.html`. Bamboo ground, 今日新词 hero card, 难词 shelf, HSK 4 and 农业词 cards with 20-cell mini grids. Daily New Words becomes a swipe deck: right = 认识, left = 不认识, tap flips.

**Blocked by:** 01. **Status:** ready-for-human

## The rule

- [x] The deck calls the existing 认识 / 不认识 rules (ADR 0006: 不认识 sets aside for 30 days); no new rule (`markKnown` / `setAside`, unchanged).
- [x] No count of what is "due" appears anywhere (the deck shows one card at a time; the empty states name no number).
- [x] Mini grids use the Collection Grid cell states, not a copy (`CollectionSliver` / `CollectionCellView`, unchanged).
- [x] The two Level totals stay 600 and 1,300 (ADR 0005, pinned by `LevelTests`; untouched).

## Comments

The 难词 shelf, HSK level cards with mini-grids, and the 农业词 shelf were already built. This ticket added the **bamboo ground** and turned Daily New Words into a **swipe deck**.

**Bamboo ground:** `VocabularyView` now sits on `BambooBackground` instead of the plain paper grid.

**Swipe deck (`DailyNewWordsDeck`):** one card at a time — swipe right for 认识, left for 不认识, tap to flip the card from the character to its pinyin · English. It only calls the existing `markKnown` / `setAside`; it adds no rule. The 认识 / 不认识 labels fade in on the side the card is pushed toward, and a success haptic fires on 认识.

**/code-review (5 findings, all fixed):**
- The deck indexed the live `dailyNewWords`, which drops the answered Word and appends a new one → every other card was skipped. Fixed by snapshotting the session's Words into the deck's own queue.
- No re-entrancy guard during the fly-off → a fast second swipe answered the same Word twice. Added an `isAnimating` guard.
- VoiceOver couldn't reach the meaning (flip is visual only). Added the meaning as the accessibility value, with named 认识 / 不认识 actions.
- The peek card revealed the next Word's meaning. Now the peek shows only the character.
- The success haptic from the old row was dropped. Restored on 认识.

**Deviation from the mock:** the deck is inline under the HSK shelf rather than launched from a 今日新词 hero card with a red 开始 (a session sheet). The interaction and rules are the same; the hero-card launch is a later polish.

**Not seen running / left for the phone:** the swipe gestures, flip, hints and haptic on device; the bamboo ground, light and dark.
