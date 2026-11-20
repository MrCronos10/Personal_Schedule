# 02: When reminders are refused

**What to build:** If the student refuses notification permission, or later turns it off in the Settings app, the reminder switch says so instead of looking on and doing nothing. See `../spec.md`, decision 6.

**Blocked by:** 01

**Status:** ready-for-human (the prompt and Settings round trip need the phone)

## The behaviour

- [x] Refusing the permission prompt leaves the switch off
- [x] While permission is refused, a 通知已关闭 line sits under the switch with a button that opens this app's page in the Settings app
- [x] Permission is re-checked when the app comes back to the front, so turning it on in Settings takes effect without a relaunch
- [x] The student's switches are kept as they were while permission is off, and their reminders come back once it is on again

## Screen text

- [x] 通知已关闭 and the button's label get their English in `Localizable.xcstrings`

## Left for the iPhone

- [ ] Refuse the prompt and see 通知已关闭
- [ ] Open Settings from the button, allow notifications, come back, and see the line gone

## Comments

Built test-first in `ReminderPermissionTests`. Whole suite green at **435 tests**, up from 429.

- **Red → green:** `ReminderPermission` maps iOS's status to never asked / allowed / refused (denied is refused; authorized, provisional and ephemeral all deliver), and `keepsSwitchOn(before:after:)` decides whether a switch just turned on stays on. The scheduler and the form both read it, replacing the scheduler's own `.authorized || .provisional` check — one mapping, so they can't disagree.
- **The switch, pinned:** only refusing the prompt the switch just raised turns it back off. Already off in Settings, a switch turned on stays on with 通知已关闭 under it and is saved on, so its reminder comes back once Settings allows it. This is the reading of "refusing the permission prompt leaves the switch off" and "switches are kept as they were while permission is off" that keeps both true.
- **Coming back:** the form re-reads permission whenever the app becomes active, and ticket 01's `ContentView` refresh on `.active` reschedules, so allowing it in Settings brings reminders back without a relaunch.
- **Kept, not tested:** stored switches are never changed by permission — the scheduler only skips scheduling while refused. That guard is screen-side and checked by hand.

`/code-review`, two axes:

- **Spec:** nothing missing. Found that a switch snapped back off whenever permission was already refused, so saving stored it off and its reminder could never come back; fixed as above, with its test.
- **Standards:** no hard violations, no bugs. Fixed: permission read once instead of twice when asking; the form's two re-checks merged into one `.task(id: scenePhase)`; the snap-back decision moved from the view onto `ReminderPermission` with tests.

Not seen running: the prompt, the Settings button, and the round trip back.
