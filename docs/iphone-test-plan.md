# Testing version 1 on the iPhone

Everything in tickets 01–10 that a test can check has been checked. What is left is everything that needs a finger on a screen. This is that list, in an order that builds its own data as it goes, so you never have to set something up twice.

Tick the boxes here as you go. If something doesn't match, note the step and what you saw instead; the wording below says what is expected, so a mismatch is a real bug and not a matter of taste.

## Getting the app on the phone

The project is already set up for signing: automatic signing, team `T24MZN88XQ`, bundle id `com.kuypav.PersonalSchedule`, and it needs iOS 17 or newer. Xcode has already been paired with your iPhone 12 Pro Max.

1. Plug the phone in, unlock it, and tap **Trust This Computer** if asked. Wi-Fi works once paired, but a cable is less trouble the first time.
2. On the phone: **Settings → Privacy & Security → Developer Mode → on**, then restart. iOS 16 and newer won't run a development build without it. This is the one box still unticked in Step 0 of `docs/plan-v1.md`.
3. In Xcode: open `PersonalSchedule.xcodeproj`, choose your phone in the device menu at the top, and press **⌘R**.
4. First launch only: **Settings → General → VPN & Device Management → your Apple ID → Trust**. A free Apple ID needs this once.

**The app stops opening after 7 days.** That is what a free Apple ID allows. Reinstall from Xcode with ⌘R and your data is still there, as long as you don't delete the app. Set a weekly reminder on the phone; this is in the Risks part of the plan for a reason.

## 1. Categories and language (tickets 01, 02, 03)

- [ ] In 设置, add 中文, 学习, 健康, 生活. Force-quit the app, open it again: all four are still there.
- [ ] Switch the language to English. The whole app changes, including the 今天 title. Switch back to 中文, force-quit, reopen: it remembered.
- [ ] Tap a Category's name and rename it. The new name shows everywhere.
- [ ] 归档 生活. It moves to 已归档, and the Action form no longer offers it.
- [ ] 恢复 生活. It comes back in its original place in the list, not at the end.

## 2. A One-time Action, ticked and unticked (tickets 04, 05)

- [ ] 今天 → **+** → title 买SIM卡, Category 生活, leave 类型 on 一次, date today. Save. It appears on today's list with 【生活】一次.
- [ ] Tap its square. The Tick sheet opens with minutes **empty**, because this Action has no default minutes.
- [ ] Type 25, add a note, tap 完成. The row shows the red 完 seal, the title struck through, and 25分钟.
- [ ] Force-quit and reopen: still done, still 25分钟.
- [ ] Tap the 完 seal. It asks first. Confirm: the square is empty again and the minutes are gone.

## 3. Late Actions and deleting (ticket 06)

- [ ] Add a One-time Action dated **yesterday**. Press ◀ to yesterday: it is **not** there.
- [ ] Come back to today: it is here, marked 迟到 in amber, with the date it was planned for.
- [ ] Long-press that row → 删除 → confirm. It is gone.
- [ ] Tick another Action, then long-press it: **no menu appears at all**. A ticked Action can't be deleted.
- [ ] Long-press an unticked row **on its title**, not on the time or the empty space. The 删除 menu should still appear. (The title became a tappable button in ticket 09 and this combination could not be tested from the Mac.)

## 4. Routines (ticket 07)

- [ ] **+** → 学20个新词, Category 中文, 类型 **重复**, 每天, 有时间 07:00, 默认分钟 20. Save. The row says 【中文】每天 and shows 07:00.
- [ ] Tick it today with the pre-filled 20 minutes. Press ▶ to tomorrow: it is there and **not** ticked.
- [ ] **+** → 健身, 类型 重复, 选择日子. Check the seven squares **start on the right day for the language you're in**, then pick Tuesday and Thursday. Save.
- [ ] Walk ▶ through a week: 健身 appears only on Tuesday and Thursday, and its row says 自选日子.
- [ ] Add a 工作日 Routine while looking at a **Saturday**. It saves and the form closes, and nothing appears on that Saturday. That is correct — Saturday isn't a working day — but it does look like nothing happened, so it is worth seeing once.

## 5. Missed days (ticket 08) — needs a night to pass

错过 only counts days after a Routine existed, so it can't be seen on the day you create one. This step is for tomorrow.

- [ ] Tomorrow, with 学20个新词 left unticked today, press ◀ back to today. It reads 错过 in amber.
- [ ] Tick it on that past day. 错过 goes away and the day shows as done.
- [ ] Untick it again: 错过 comes back.
- [ ] Today (the newer day) does **not** say 错过, because today isn't over.

## 6. Changing an Action (ticket 09)

- [ ] Tap an Action's **title**, not its square. 改计划 opens, already filled in, and there is **no 类型 row**: an Action keeps its kind.
- [ ] Change 默认分钟 to 30 and save. Tomorrow's tick pre-fills 30.
- [ ] **The one the review caught:** tick 学20个新词 today, then rename it to 学30个新词. Today's ticked row must still read **学20个新词**, because a finished day keeps what it was ticked as. Tomorrow's row reads 学30个新词.
- [ ] Change that Action's Category as well. The ticked day keeps the old Category's colour and 【name】; later days show the new one.
- [ ] 归档 a Category that an Action uses, then open that Action and change only its time. It saves, and keeps the archived Category. Nothing is deleted in this app, so an Action is allowed to stay in a Category you've retired.
- [ ] Move a One-time Action's date to a later day **after** ticking it. It stays on the day you ticked it.

## 7. Pausing a Routine (ticket 10)

- [ ] 设置 → 重复计划 lists every Routine you made, oldest first.
- [ ] 暂停 学20个新词. It shows 已暂停, and it is gone from 今天.
- [ ] 继续 it. It is back on today.
- [ ] Pause it, let a day pass, then resume: the days in between show nothing and never say 错过.
- [ ] Long-press a Routine's row on the checklist: there is **no 删除**, ever. Routines are paused, not deleted.

## Still undecided, and worth knowing while you test

### The calendar, now settled

Days are stored in one calendar whatever region the phone is set to, and any day already written with the phone's own year is moved once when the app starts. Dates on screen are still shown in your own calendar, so nothing should look different. See [ADR 0003](adr/0003-days-are-stored-in-one-calendar.md).

- [ ] The date at the top of 今天 reads the way your phone normally writes dates, and the weekday next to it is right.
- [ ] ◀ and ▶ land on the days either side, and 今天 comes back to today.

### Still your decision

- **Unticking a One-time Action on a past day** makes it leave that day and reappear on today as 迟到. That follows the rule as written, but it means a mis-tick on Sunday can't be corrected in place on Sunday. Ticket 06 has the details, and it is the last thing in version 1 still waiting on you.
