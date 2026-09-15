# 03: Rename, archive and restore Categories

**What to build:** On the Categories screen the student can rename a Category, archive it, and restore it. Categories are never deleted: an Archived Category is hidden from the main list but kept, with all its history, in an "Archived" section, from where it can be restored.

**Blocked by:** 02 (Chinese / English language switch)

**Status:** ready-for-human (only the iPhone check is left)

- [x] The student can rename a Category; an empty name can't be saved
- [x] The student can archive a Category; it moves out of the active list into an Archived section
- [x] The student can restore an Archived Category; it returns to the active list
- [x] There is no way to delete a Category
- [x] Renaming, archiving and restoring are kept after reopening the app
- [x] Tests cover rename, archive and restore
- [x] All new screen text exists in 中文 and English
- [ ] Verified on the iPhone: archive 生活, see it under Archived, restore it

## Comments

- Tests are at the Category library: renaming shows the new name; a blank or spaces-only rename is refused and the old name stays; archiving moves a Category from the active list to the archived list; restoring puts it back in its original place.
- On 设置: tap a Category's name to rename it (an alert with a text field); 归档 archives it; the 已归档 section lists archived Categories with 恢复. There is no delete anywhere.
- Rename, archive and restore save the same way as adding a Category, which ticket 01's reopen test covers; there is no separate reopen test for each of them.
- Category inks now follow creation order across all Categories, so archiving one doesn't change the other Categories' colors.
- New screen text (归档, 恢复, 已归档, 没有已归档的分类, 重命名, 重命名分类, 分类名称, 保存, 取消) is in `Localizable.xcstrings` with English; the translations test passes.
- Code review found no bugs. Afterwards, adding a Category was changed to use the same save-or-undo step as rename, archive and restore; all 11 tests passed again.
- Not seen running: the 设置 screen itself, since the simulator can't be tapped from the command line. The app was launched in the simulator and opens normally.
