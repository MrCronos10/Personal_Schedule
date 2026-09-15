# 02: Chinese / English language switch

**What to build:** 设置 has a Language option with 中文 and English. 中文 is the default. Changing it immediately changes all screen text in the app, and the choice is remembered after the app is reopened. From this ticket on, every new piece of screen text is added in both languages.

The student's own Category names, Action titles and Notes are never translated.

**Blocked by:** 01 (Create Categories that are saved)

**Status:** ready-for-human (the tap-through checks on the iPhone are left)

- [x] 设置 has a Language option: 中文 / English
- [x] A fresh install shows the app in 中文
- [ ] Switching language changes all existing screen text (tabs, Categories screen, buttons) right away, without restarting
- [x] The chosen language is kept after closing and reopening the app
- [x] All screen text lives in one place with both translations, so missing translations are easy to spot
- [ ] Category names the student typed are shown exactly as typed in both languages
- [ ] Verified on the iPhone: switch to English, reopen the app, it is still English; switch back to 中文

## Comments

- Tests: the language setting defaults to 中文 and remembers English after reopening; a translations check fails if any entry in `PersonalSchedule/Localizable.xcstrings` is missing its English, or if the catalog's source language isn't Chinese. Screens are checked by hand.
- Screen text is written in Chinese in the code and translated to English in `Localizable.xcstrings`. The whole app follows the chosen language, not the phone's language.
- Checked in the simulator: with no saved choice the 今天 tab is in 中文 (田字格 header, Chinese date); with English saved and the app reopened, the date, "Today" title, caption, empty message and tab names are all English.
- Not yet seen running: the 设置 screen's language picker, switching without restarting, and typed Category names in English mode. Category names use verbatim text, so they are never looked up for translation.
- Code review found that the screens read the saved language directly instead of through the tested `LanguageSetting`. Fixed: the app now shares one `LanguageSetting` through the SwiftUI environment. Tests and the English relaunch check were run again after the fix.
- Every later ticket must add its new screen text to `Localizable.xcstrings` with an English translation, or the translations test fails.
