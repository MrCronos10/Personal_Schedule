# 01: Create Categories that are saved

**What to build:** The app opens with two tabs, 今天 (Today) and 设置 (Settings). In 设置 the student can add Categories (for example 中文, 学习, 健康, 生活) and see them in a list. Categories are kept after the app is closed and opened again. This ticket also adds the automated tests, so every later ticket can build test-first.

**Blocked by:** None (can start immediately). The student should first finish Step 0 by running the app on their iPhone.

**Status:** ready-for-human (only the iPhone check is left)

- [x] The screens follow the 田字格 Practice book look described in `docs/plan-v1.md` (paper background, red ink, serif titles)
- [x] The app shows two tabs: 今天 (empty for now) and 设置
- [x] 设置 has a Categories screen that lists all Categories
- [x] The student can add a Category by typing a name; an empty name can't be saved
- [x] Categories are still there after closing and reopening the app
- [x] The database follows the iCloud-ready rules in `docs/plan-v1.md` (every field has a default or is optional, no unique fields, every link optional with a link back)
- [x] A unit test target exists and runs, with at least one test for adding a Category
- [ ] Verified on the iPhone: create 中文, 学习, 健康, 生活, close the app, reopen, all four are listed

## Comments

- Tests are at the Category library: adding shows the Category in the list, a blank or spaces-only name is refused, and Categories are still listed after the database is reopened. The screens are checked by hand.
- iPhones have no Song font, so Noto Serif SC Bold and Black are shipped inside the app (about 24 MB, SIL Open Font License).
- Checked in the simulator: the 今天 tab shows the 田字格 header in Noto Serif. The 设置 screen still needs checking on a device.
