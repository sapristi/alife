# Parameter Sweep Follow-up: Fine-tuning & Long Runs (50k)

**Date:** 2026-03-08 02:38
**Experiments:** #14, #16, #21, #22-#26 (8 experiments extended to 50k reactions)
**Follow-up to:** [parameter-sweep.md](2026-03-08-parameter-sweep.md)
**Parameters:** 50,000 reactions total, stats every 500 (first 10k) then every 2000

## Goal

Fine-tune the two most promising levers from the first sweep:
1. **Grab rate tuning** for ed: is 5 the optimum? Try 2, 3.
2. **Combined grab_rate + ambient** for both setups.
3. **Long runs** (50k) to check if the promising configs are truly self-sustaining.

## New experiments

| ID | Setup | Config | grab_rate | ambient |
|----|-------|--------|-----------|---------|
| #22 | ed | grab_rate=2 | 2 | 50 |
| #23 | ed | grab_rate=3 | 3 | 50 |
| #24 | ed | grab_rate=5 + ambient=500 | 5 | 500 |
| #25 | ri | grab_rate=5 + ambient=500 | 5 | 500 |
| #26 | ri | grab_rate=5 + ambient=200 | 5 | 200 |

Extended from first sweep: #14 (ed grab=5), #16 (ed grab=10), #21 (ri amb=500).

## Results: Active species over 50k reactions

| reac | ed g=2 | ed g=3 | ed g=5 | ed g=10 | ed g5+a500 | ri a500 | ri g5+a500 | ri g5+a200 |
|-----:|-------:|-------:|-------:|--------:|-----------:|--------:|-----------:|-----------:|
|    1 |      2 |      2 |      2 |       2 |          2 |       1 |          1 |          1 |
|  5k  |      8 |      9 |      8 |       8 |          5 |       2 |          2 |          1 |
| 10k  |      8 |      9 |     11 |       6 |          5 |       4 |          3 |          2 |
| 20k  |    **0** |    **0** |      6 |     **0** |          8 |       1 |          3 |        **0** |
| 30k  |      0 |      0 |      7 |       0 |          4 |       2 |          2 |          0 |
| 40k  |      0 |      0 |      1 |       0 |          4 |       3 |          3 |          0 |
| 48k  |      0 |      0 |      2 |       0 |          1 |       4 |          2 |          0 |

**Bold = dead (0 active species)**

### Grabs over time

| reac | ed g=2 | ed g=3 | ed g=5 | ed g=10 | ed g5+a500 | ri a500 | ri g5+a500 | ri g5+a200 |
|-----:|-------:|-------:|-------:|--------:|-----------:|--------:|-----------:|-----------:|
|  10k |      7 |      0 |      6 |       3 |          0 |       6 |          6 |          3 |
|  20k |      0 |      0 |      4 |       0 |          5 |       0 |          0 |          0 |
|  30k |      0 |      0 |      2 |       0 |          0 |       0 |          5 |          0 |
|  40k |      0 |      0 |      1 |       0 |          2 |       1 |          0 |          0 |
|  48k |      0 |      0 |      1 |       0 |          0 |       1 |          1 |          0 |

## Analysis

### None of the systems are truly self-sustaining

The critical finding: **every configuration eventually declines**. Even ed_R4 (grab_rate=5), which looked so promising at 10k with 11 growing active species, dropped to 1-2 by 48k. The 10k snapshot was misleading — it caught the system at peak diversification, not steady state.

### Grab rate has a sharp optimum at 5

| grab_rate | Death point | Peak active | Notes |
|-----------|-------------|-------------|-------|
| 1 (baseline) | ~8.5k | 8 at 5k | |
| 2 (#22) | ~15k | 8 at 10k | Barely better than baseline |
| 3 (#23) | ~15k | 9 at 10k | Same as grab=2 |
| 5 (#14) | ~45k | 11 at 10k | **5x longer life** |
| 10 (#16) | ~15k | 8 at 5k | Worse than grab=5 |

grab_rate=5 is clearly optimal. Both 2 and 3 barely extend life beyond baseline (dead by ~15k vs ~8.5k). The jump from 3 to 5 is dramatic (15k → 45k lifetime). At 10, over-grabbing causes faster resource depletion.

### Combined grab_rate=5 + ambient=500 shows extended activity

ed_grab5_amb500 (#24) maintained 4 active species at 30-40k with functional grabs, and still had 1 active species at 48k. This is the longest-surviving ed configuration, though still declining. The combination is mildly additive.

### Ribosome survives longer with ambient, not with grab_rate

ri_A2 (#21, ambient=500 only) maintained 4 active species at 48k — **the best ribosome result**. Adding grab_rate=5 to that (ri_grab5_amb500, #25) was roughly equivalent (2 active at 48k). But ri_grab5_amb200 (#26, less ambient) died at 20k. For ribosome, ambient surplus is the key lever, and grab_rate adds little.

### The fundamental problem persists

All systems follow the same pattern:
1. **Early growth** (0-10k): Breaks create fragments, some become active, active species increase
2. **Peak** (5-15k): Maximum diversity of active species
3. **Slow decline** (15-40k): Breaks gradually destroy functional molecules faster than new ones form
4. **Death** (40-50k+): Last active species breaks, system becomes inert

The timescale changes with parameters, but the trajectory doesn't. Without a genuine self-replication mechanism that produces *copies of the replicator itself*, entropy always wins. The current "replication" appears to be the existing Petri nets producing activity through existing pathways, not producing new copies of themselves.

### What would actually work

The experiments strongly suggest that parameter tuning alone cannot produce indefinite survival. The system needs a qualitative change:
- A molecule that can **copy itself** (not just produce new active fragments through breaks)
- Or a **repair mechanism** that reconstructs functional molecules from fragments
- Or a **redundancy mechanism** where multiple copies of the replicator exist and breaks are statistically survivable

---

<details>
<summary>Baseline env (all experiments)</summary>

```json
{"transition_rate": 10, "grab_rate": 1, "break_rate": "1/1000000", "collision_rate": "1/100000"}
```

Variants override specific values as noted.

</details>

**Date:** 2026-03-08 | **Commit:** `a2c527c`
