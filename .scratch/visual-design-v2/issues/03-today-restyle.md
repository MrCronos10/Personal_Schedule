# 03: Today restyle

**What to build:** `screens/Today.dc.html`. Dawn header, boxed 今天 title, Today card (Routine ring, reading progress, stamp slot), 最近认识 sliver, notebook-rule checklist, 去读 button on the next reading Action, floating + button. Move Settings to a button on Today and Notes to a sheet if v1 ticket 05 has not already.

**Blocked by:** 01. **Status:** ready-for-agent

## The rule

- [ ] The sliver reads the last 10 Words that became Known across all lists, newest right; the query lives in a library with a test
- [ ] Today's characters read use the same count the Reading Session saves; one rule, not a second copy
- [ ] The stamp slot fills once per day when the goal (default 200 字, in Settings) is first reached; medium haptic, first time only
- [ ] All Routines done folds into one "今天 — 完成" card
- [ ] Outstanding Actions still show before ticked ones (`ordered(_:)`)
- [ ] New strings translated; student's own text uses `Text(verbatim:)`

## Comments
