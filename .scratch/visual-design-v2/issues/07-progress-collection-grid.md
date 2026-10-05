# 07: Progress collection grid

**What to build:** `screens/Progress.dc.html`. Night band with three stats, segmented HSK 4 / HSK 5 / 农业词, count with the brass Passed tick at 80%, 8-per-row 田字格 grid in four states (not met, seen, Known, freshly inked), cell sheet, weekly Category cards below. Reuses v1 ticket 04 if built.

**Blocked by:** 01. **Status:** ready-for-human (partial — see deferred below)

## The rule

- [x] "Freshly inked" = became Known since the screen was last opened; stored as a last-seen timestamp, glow for 1 s (`CollectionGridView` + `CollectionLibrary.freshlyKnown`, last-seen set in `collectionGrid.knownWords`).
- [x] Seen = at least one Lookup and not Known (existing `CollectionLibrary` cell state).
- [x] The grid is lazy; HSK 5's 1,300 cells must scroll smoothly (`LazyVGrid` per section).
- [x] Today's new-Known count matches the Today sliver's source (both read `CollectionLibrary`; unchanged).

## Comments

The collection grid (states, glow, lazy sections, cell sheet, counts) was already built (v1 ticket 04) and already satisfies every rule above — this ticket added no new rule, so there was no new red/green cycle.

**Done:** the **Night Band header** — the 进度 title on an ink band with rounded bottom corners, over the 田字格 paper, using the shared `NightBand.cornerRadius`.

**Deferred (flagged):**
- The **stats row** (+N 今天认识, minutes today, total Known) — these need sources that don't exist cleanly yet (a live total-Known and a today-new-Known that must match the Today sliver), so wiring them in `onAppear` went stale against the live grid in review. Deferred as a set rather than shipped half-live.
- The **brass-outlined 印章册 button** — it opens the Seal Book, which is **ticket 08, blocked on ADR 0010**. It lands with that ticket.
- The **segmented HSK 4 / HSK 5 / 农业词 control and the brass Passed tick at 80%** — the existing collapsible-section grid meets all the rules; the segmented restyle is a larger change left for a focused pass.

**/code-review:** an earlier attempt added a `totalKnown` stat refreshed in `onAppear`; review flagged it as stale vs. the live grid, a duplicate `allCells()` read, duplicated count logic, and a wrong English label ("认识" → "I know it"). All resolved by deferring the stat and keeping the header to the title.

**Not seen running / left for the phone:** the night-band header over the grid, light and dark.
