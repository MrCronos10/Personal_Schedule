# 01: Create Categories that are saved

**What to build:** The app opens with two tabs, 今天 (Today) and 设置 (Settings). In 设置 the student can add Categories (for example 中文, 学习, 健康, 生活) and see them in a list. Categories are kept after the app is closed and reopened. The project gets its automated test setup in this ticket, so every later ticket can build test-first.

**Blocked by:** None (can start immediately). The student should first finish Step 0 by running the app on their iPhone.

**Status:** ready-for-agent

- [ ] The app shows two tabs: 今天 (empty for now) and 设置
- [ ] 设置 has a Categories screen that lists all Categories
- [ ] The student can add a Category by typing a name; an empty name can't be saved
- [ ] Categories are still there after closing and reopening the app
- [ ] The database follows the iCloud-ready rules in `docs/plan-v1.md` (every field has a default or is optional, no unique fields, every link optional with a link back)
- [ ] A unit test target exists and runs, with at least one test for adding a Category
- [ ] Verified on the iPhone: create 中文, 学习, 健康, 生活, close the app, reopen, all four are listed
