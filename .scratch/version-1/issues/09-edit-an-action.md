# 09: Edit an Action

**What to build:** The student can open an existing Action (One-time or Routine) and change its title, Category, time, Default Minutes, date, or repeat days. Days already ticked keep the title and Category copied into their Completion, so past progress does not change (ADR 0002). Days not ticked show the new values.

Known limitation, accepted: changing a Routine's repeat days also changes which past unticked days show as Missed.

**Blocked by:** 07 (Routines appear on their repeat days)

**Status:** ready-for-agent

- [ ] Tapping an Action (not its circle) opens it in the Action form for editing
- [ ] Title, Category, time, Default Minutes, date (One-time) and repeat days (Routine) can be changed and saved
- [ ] Only active Categories can be chosen when editing
- [ ] A day ticked before the edit still shows the old title and still counts toward the old Category
- [ ] Days not ticked, and future days, show the new values
- [ ] Tests cover: renaming an Action keeps ticked days' copy; changing Category keeps ticked days in the old Category
- [ ] All new screen text exists in 中文 and English
- [ ] Verified on the iPhone: tick "学20个新词" today, rename it to "学30个新词", today still shows 20, tomorrow shows 30
