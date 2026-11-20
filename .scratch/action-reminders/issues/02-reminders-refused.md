# 02: When reminders are refused

**What to build:** If the student refuses notification permission, or later turns it off in the Settings app, the reminder switch says so instead of looking on and doing nothing. See `../spec.md`, decision 6.

**Blocked by:** 01

**Status:** ready-for-agent

## The behaviour

- [ ] Refusing the permission prompt leaves the switch off
- [ ] While permission is refused, a 通知已关闭 line sits under the switch with a button that opens this app's page in the Settings app
- [ ] Permission is re-checked when the app comes back to the front, so turning it on in Settings takes effect without a relaunch
- [ ] The student's switches are kept as they were while permission is off, and their reminders come back once it is on again

## Screen text

- [ ] 通知已关闭 and the button's label get their English in `Localizable.xcstrings`

## Left for the iPhone

- [ ] Refuse the prompt and see 通知已关闭
- [ ] Open Settings from the button, allow notifications, come back, and see the line gone
