# Hot Memory
<!-- Rewrite freely. Keep under 50 lines. What matters right now for the goal. -->

## Active work: copy_grabbed ambient consumption

Copy_grabbed reaction type is implemented in engine (commit a0bb48e, 2026-03-14) but **ambient consumption is not yet wired up**. Current state:
- CopyGrabbed reaction reads acid at cursor, appends to buffer, advances cursor
- Rate: `copy_grabbed_ready_nb × copy_grabbed_rate` (flat rate, not concentration-dependent)
- **Missing**: acid concentration index, concentration-dependent rates, stochastic wrong-atom grabs

Next concrete steps (from future-work.md):
1. Add `char -> int` acid concentration index to reac_mgr
2. Change rate to `ambient_qtt(acid_at_cursor)` per copy_grabbed place
3. Firing logic: draw from ambient pool (decrement if not infinite)
4. Stochastic mutation: total ambient rate, specific atom chosen by relative concentration at firing time

## Key parameter sweet spots (from experiments)
- break_exp=0 (uniform), break_rate=1e-2 → most Darwinian pairs
- collision_rate=2e-5 (2x default) → diversity without killing copiers
- grab_rate=5 → best for endless_dup systems

## Builder location
- `django/build_copier.py`: `build_copy_grabbed_copier()`
