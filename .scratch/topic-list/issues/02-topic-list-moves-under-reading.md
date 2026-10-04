# 14: 农业词 moves under 阅读

**What to build:** The fix for the tab overflow ticket 11 caused. 农业词 was a top-level tab, which took the app to six tabs, which iPhone collapses to four-plus-"More" — so 设置 (and with it the Reading Coach's API key field) ended up hidden behind "More", and the student could not find the chatbot. 农业词 moves to a NavigationLink inside 阅读, next to 难词.

Why vocabulary lives with vocabulary: ADR 0007 (updated).

**Blocked by:** Tickets 11 and 12.

**Status:** ready-for-human (one screenshot showing the five-tab bar; a tap through 阅读 → 农业词 on the phone)

## The rule

- [x] The tab bar is back to five: 今天, 阅读, 笔记, 进度, 设置, with nothing under "More"
- [x] 农业词 is a `NavigationLink` inside 阅读, in the row next to 难词
- [x] `TopicListView` is unchanged — it still owns the whole screen it draws, with its meter, chips, add-your-own and archived sections
- [x] The 设置 → 读伴 section is visible again without needing to tap "More"

## Comments

- Full suite: 295 passing.
- Simulator screenshot confirms the five-tab bar.
- `TopicListView.swift` was not touched; it reads the same whether it's a tab or a pushed destination.
- English translations for the Coach UI strings I missed in ticket 12 were added in this ticket (the Xcode IDE build auto-extracted them).
