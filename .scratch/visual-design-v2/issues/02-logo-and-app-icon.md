# 02: Logo and app icon

**What to build:** The 读 田字格 mark with the 日 chop (`screens/Main.dc.html`, `brief.md` Logo): `AppIcon.appiconset` (light, dark), and `LogoView(size:)` which drops the cross and chop at ≤ 40 pt. Use it in the Settings About row and the Evening Check header. Brush-written 读, not geometric type.

**Blocked by:** 01. **Status:** ready-for-agent

## The rule

- [ ] All iOS icon sizes present, light and dark; no iOS 18 tinted variant
- [ ] `LogoView` small-size variant has no cross or chop
- [ ] A test renders `LogoView` at 128 pt in both modes and asserts both exist

## Comments
