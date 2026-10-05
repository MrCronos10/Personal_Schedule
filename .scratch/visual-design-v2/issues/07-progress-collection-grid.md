# 07: Progress collection grid

**What to build:** `screens/Progress.dc.html`. Night band with three stats, segmented HSK 4 / HSK 5 / 农业词, count with the brass Passed tick at 80%, 8-per-row 田字格 grid in four states (not met, seen, Known, freshly inked), cell sheet, weekly Category cards below. Reuses v1 ticket 04 if built.

**Blocked by:** 01. **Status:** ready-for-agent

## The rule

- [ ] "Freshly inked" = became Known since the screen was last opened; stored as a last-seen timestamp, glow for 1 s
- [ ] Seen = at least one Lookup and not Known (existing model)
- [ ] The grid is lazy; HSK 5's 1,300 cells must scroll smoothly on the phone
- [ ] Today's new-Known count matches the Today sliver's source

## Comments
