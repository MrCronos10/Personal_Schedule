# 05: 读完 result

**What to build:** `screens/Celebrate.dc.html`. After 读完 banks, show the seal stamp, the Banked Result (+认识 / 更近一步 / 回到零), the newly Known words inking into 田字格 cells, and 记下来 which opens the Tick sheet pre-filled. The new-seal strip appears only once ticket 08 exists.

**Blocked by:** 04. **Status:** ready-for-human

## The rule

- [x] Numbers come from the Article's Banked Result, not recomputed (`BankedResultLine` reads the `BankResult`; the inking cells read `BankResult.newlyKnownWords`, filled by the same `bank` that counts).
- [x] An Article with no Banked Result shows no row of zeros (the result area is shown only when `banked != nil`; the inking row only when `newlyKnownWords` is non-empty).
- [x] Reduce Motion replaces the stamp and inking with a fade (the stamp via `RedSealStamp`; the inking via the `reduceMotion` branch in `InkingCells`).
- [x] Light haptic on the stamp; no sound (`showReadSeal` fires one light impact; nothing plays sound).

## Comments

The seal stamp, the Banked Result line, and the pre-filled Tick sheet were already in the reader. This ticket added the **刚刚上墨 inking cells**.

**New (TDD, red→green):** `BankResult.newlyKnownWords` — the Words that became Known this reading, filled in the same branch that increments `newlyKnown`, so the count and the list always agree. Not persisted: it lives only in the result of the 读完 that just happened. Two tests in `BankingTests` (built from an explicit Word fixture).

**Reader:** after 读完, the newly-Known Words ink into 田字格 cells under the Banked Result line, one every 120 ms (`InkingCells`), via a cancellable `.task` so a mid-stagger dismiss drops the pending reveals. 记下来 is the existing post-读完 Tick offer (pre-filled minutes + session note); the 再看一遍 secondary button from the mock is not added — rereading is just scrolling up, and a reread banks nothing.

**/code-review (2 low-severity, both fixed):** uncancelled `DispatchQueue.asyncAfter` stagger → cancellable `.task`; fixed 14 pt multi-char cells → sized by character count like the Collection Grid. No correctness bugs.

**Not seen running / left for the phone:** the inking animation and the result card after a real 读完, light and dark, and with Reduce Motion.
