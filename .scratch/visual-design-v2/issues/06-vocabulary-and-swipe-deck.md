# 06: Vocabulary and swipe deck

**What to build:** `screens/Words.dc.html`. Bamboo ground, 今日新词 hero card, 难词 shelf, HSK 4 and 农业词 cards with 20-cell mini grids. Daily New Words becomes a swipe deck: right = 认识, left = 不认识, tap flips.

**Blocked by:** 01. **Status:** ready-for-agent

## The rule

- [ ] The deck calls the existing 认识 / 不认识 rules (ADR 0006: 不认识 sets aside for 30 days); no new rule
- [ ] No count of what is "due" appears anywhere
- [ ] Mini grids use the Collection Grid cell states, not a copy
- [ ] The two Level totals stay 600 and 1,300 (ADR 0005)

## Comments
