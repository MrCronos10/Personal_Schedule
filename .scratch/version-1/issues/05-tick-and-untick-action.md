# 05: Tick and untick an Action

**What to build:** On the Daily Checklist, tapping an Action's circle opens a Tick sheet. Minutes are filled in from the Action's Default Minutes; the student can change them or leave them empty, and add an optional Note. Saving creates a Completion for that day, and the Action shows as done. The Completion keeps a copy of the Action's title and Category as they were when ticked (ADR 0002). Tapping a ticked circle asks for confirmation, then removes the Completion.

**Blocked by:** 04 (Plan a One-time Action and see it on the Daily Checklist)

**Status:** ready-for-agent

- [ ] Tapping an unticked Action opens the Tick sheet with Minutes pre-filled from Default Minutes (empty if the Action has none)
- [ ] Minutes can be changed or cleared; the Note is optional
- [ ] Saving creates a Completion for the day shown, and the Action shows as done
- [ ] The Completion stores its own copy of the title and Category
- [ ] Tapping a ticked Action asks for confirmation; confirming removes the Completion and the Action is no longer done
- [ ] Completions are kept after reopening the app
- [ ] Tests cover: ticking with default minutes, with changed minutes, with no minutes, and unticking
- [ ] All new screen text exists in 中文 and English
- [ ] Verified on the iPhone: tick an Action with 25 minutes and a Note, reopen the app, it is still done
