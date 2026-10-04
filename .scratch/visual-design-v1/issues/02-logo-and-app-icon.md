# 16: Logo and app icon — 读 in a 田字格

**What to build:** The app's visual mark: the character **读** (dú), brush-
written in ink black, inside a grid-red 田字格 on paper cream. Shipped three
ways: the full `AppIcon.appiconset` (every iOS size), a `LogoView` SwiftUI
view for in-app use (About screen, Evening Check sheet header), and a
dark-mode icon variant (cream character on night ink, grid red stays grid
red).

Why this mark: [docs/design-v1.md](../../../docs/design-v1.md) — "The logo".

**Blocked by:** None (can land in parallel with ticket 15; `LogoView` uses
the tokens from 15 if landed, otherwise its own literal colours and gets
swapped later).

**Status:** ready-for-agent

## The rule

- [ ] The 读 is brush-written, not geometric type — fills ~70% of its cell,
      the four quadrants of the 田 remain visible around it
- [ ] `AppIcon.appiconset` carries every iOS size (iPhone, iPad, App Store,
      Settings, Spotlight). The 田字格 is the icon bounds — no outer
      padding, the grid-red line reads as the icon's edge
- [ ] A dark-mode icon variant ships (cream on night ink); grid red
      is unchanged. iOS 18's tinted icon variant is not shipped
- [ ] `LogoView(size:)` renders the mark at any size; used by the About
      screen and the Evening Check sheet header
- [ ] A test `theLogoRendersInLightAndDark` snapshots `LogoView` at 128pt
      in both modes and asserts both exist (visual diffing isn't done
      here — the student taps through on the phone)

## What is not in this ticket

- A splash / launch screen using the mark. The default launch stays.
- A watermark use of 读. The watermark is a repeating 田字格 pattern
  (ticket 17), not the character.

## Comments
