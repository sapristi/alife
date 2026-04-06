# Hot Memory
<!-- Rewrite freely. Keep under 50 lines. What matters right now for the goal. -->
<!-- Design details: see future-work.md. Full milestone spec: see roadmap.md. -->

## Active work: copy_grabbed ambient consumption

**Status:** copy_grabbed reaction implemented (commit a0bb48e). Ambient consumption NOT yet wired up.

Missing pieces:
1. Acid concentration index (`char -> int` map in reac_mgr)
2. Concentration-dependent rate: `ambient_qtt(acid_at_cursor)` per place
3. Firing logic: draw from ambient pool on copy
4. Stochastic mutation: wrong-atom grabs weighted by concentration

## Key parameter sweet spots
- break_exp=0 (uniform), break_rate=1e-2 → most Darwinian pairs
- collision_rate=2e-5 (2x default) → diversity without killing copiers
- grab_rate=5 → best for endless_dup systems
