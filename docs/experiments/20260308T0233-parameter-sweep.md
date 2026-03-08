# Parameter Sweep: Rate Tuning & Ambient Surplus

**Date:** 2026-03-08 02:33
**Experiments:** #8-#21 (14 experiments)
**Base molecules:** `endless_duplication` (ed, InitialState #8) and `ribosome_1` (ri, InitialState #9)
**Parameters:** 10,000 reactions, stats every 500, snapshots every 5000
**Baseline env:** `{"transition_rate": 10, "grab_rate": 1, "break_rate": "1/1000000", "collision_rate": "1/100000"}`

## Goal

Identify which parameters extend replication longevity. Previous matched-env experiments (#5, #6) showed both setups dying around reaction 8500.

## Experiment Matrix

| Config | Parameter changed | Value | ed ID | ri ID |
|--------|------------------|-------|-------|-------|
| Baseline | (none) | (matched env) | #5 | #6 |
| R1 | break_rate | 1/10000000 (10x lower) | #8 | #9 |
| R2 | collision_rate | 1/10000 (10x higher) | #10 | #11 |
| R3 | collision_rate | 1/1000 (100x higher) | #12 | #13 |
| R4 | grab_rate | 5 (5x higher) | #14 | #15 |
| R5 | grab_rate | 10 (10x higher) | #16 | #17 |
| A1 | ambient qtt | 200 (4x more) | #18 | #19 |
| A2 | ambient qtt | 500 (10x more) | #20 | #21 |

## Results: Active species over time

### endless_duplication (ed)

| reac | Base | R1 low brk | R2 hi col | R3 vhi col | R4 hi grb | R5 vhi grb | A1 amb200 | A2 amb500 |
|-----:|-----:|-----------:|----------:|-----------:|----------:|-----------:|----------:|----------:|
|    1 |    2 |          2 |         2 |          2 |         2 |          2 |         2 |         2 |
|  501 |    3 |          3 |         3 |          3 |         3 |          3 |         3 |         2 |
| 1001 |    4 |          4 |         3 |          2 |         4 |          4 |         3 |         2 |
| 3001 |    7 |          7 |         1 |          0 |         7 |          7 |         4 |         3 |
| 5001 |    8 |          8 |         0 |          0 |         8 |          8 |         6 |         5 |
| 7001 |    7 |          7 |         0 |          0 |         9 |          7 |         5 |         4 |
| 9001 |    3 |          3 |         0 |          0 |        10 |          6 |         4 |         5 |
| 9501 |    1 |          1 |         0 |          0 |        11 |          6 |         5 |         5 |

### ribosome_1 (ri)

| reac | Base | R1 low brk | R2 hi col | R3 vhi col | R4 hi grb | R5 vhi grb | A1 amb200 | A2 amb500 |
|-----:|-----:|-----------:|----------:|-----------:|----------:|-----------:|----------:|----------:|
|    1 |    1 |          1 |         1 |          1 |         1 |          1 |         1 |         1 |
|  501 |    3 |          3 |         2 |          2 |         2 |          2 |         2 |         1 |
| 1001 |    3 |          3 |         2 |          2 |         3 |          3 |         1 |         1 |
| 3001 |    3 |          3 |         0 |          0 |         3 |          3 |         1 |         1 |
| 5001 |    2 |          2 |         0 |          0 |         2 |          2 |         1 |         2 |
| 7001 |    2 |          2 |         0 |          0 |         2 |          2 |         3 |         2 |
| 9001 |    0 |          0 |         0 |          0 |         0 |          0 |         2 |         3 |
| 9501 |    0 |          0 |         0 |          0 |         0 |          0 |         4 |         4 |

### Grabs at reaction 9501

| Setup | Base | R1 | R2 | R3 | R4 | R5 | A1 | A2 |
|-------|-----:|---:|---:|---:|---:|---:|---:|---:|
| ed    |    0 |  0 |  0 |  0 |  4 |  2 |  2 |  5 |
| ri    |    0 |  0 |  0 |  0 |  0 |  0 |  1 |  6 |

## Analysis

### R1 (lower break_rate): No effect

Reducing break_rate 10x had **zero measurable effect**. Both ed_R1 (#8) and ri_R1 (#9) follow trajectories identical to baseline. This is surprising — it suggests that breaks are already rare enough that they aren't the primary cause of death. The system is dying from something else.

### R2/R3 (higher collision_rate): Accelerates death

Higher collision rates **killed the systems faster**, not slower. ed_R2 died by reaction 5001, ed_R3 by reaction 3001. Ribosome variants died even faster. More collisions means more random molecular interactions that disrupt the existing Petri nets. Collisions don't create repair — they create chaos.

### R4 (grab_rate=5): Best result for ed, extends active life

**The standout result.** ed_R4 (#14) is the only experiment where active species are *still growing* at reaction 9501 (11 species, 4 grabs). The system diversified from 2 to 11 active species without collapsing. However, ri_R4 (#15) still died — identical trajectory to baseline. This suggests grab_rate helps the two-molecule endless_duplication system sustain its replication machinery, but the single-molecule ribosome can't benefit.

### R5 (grab_rate=10): Good but worse than R4

ed_R5 (#16) maintained 6 active species at 9501 with 2 grabs — alive but declining. This is better than baseline (dead at 8500) but worse than R4 (grab_rate=5). Higher grab_rate may cause the replication machinery to over-grab, depleting ambient resources faster or creating too many grab-based interactions.

### A1/A2 (more ambient molecules): Surprising effect on ribosome

For ed, ambient surplus provides moderate benefit: 5 active species at 9501 for both A1 and A2 (vs 1 for baseline). A2 maintained 5 grabs throughout.

The **surprising result** is ribosome: ri_A1 (#19) and ri_A2 (#21) both have 4 active species at reaction 9501, up from 0 in baseline. The ribosome system, which was completely dead in every other configuration, is alive and *growing* with more ambient molecules. ri_A2 maintained 6 grabs consistently from reaction 5001 onward.

### Key findings ranked by impact

| Rank | Config | Effect on ed | Effect on ri |
|------|--------|-------------|--------------|
| 1 | **R4 grab_rate=5** | 11 active species at 9501 (growing) | No effect (dead) |
| 2 | **A2 ambient=500** | 5 active, 5 grabs at 9501 | 4 active, 6 grabs at 9501 |
| 3 | **A1 ambient=200** | 5 active, 2 grabs at 9501 | 4 active, 1 grab at 9501 |
| 4 | **R5 grab_rate=10** | 6 active, 2 grabs at 9501 | No effect (dead) |
| 5 | R1 low break_rate | No effect | No effect |
| 6 | R2 hi collision | Accelerates death | Accelerates death |
| 7 | R3 vhi collision | Accelerates death faster | Accelerates death faster |

### Interpretation

1. **Break rate is not the bottleneck.** At 1/1000000, breaks are already rare enough. The system dies from structural degradation, not break frequency. This overturns our initial hypothesis.

2. **Grab rate is critical for ed.** The replication machinery in endless_duplication depends on grabs to function. Faster grabs = faster replication = outpaces degradation. But only up to a point (R5 is worse than R4), suggesting there's an optimal grab rate.

3. **Ambient surplus helps both systems** by providing more raw material. With more ambient molecules, break products can be replaced. This is the only parameter that helped ribosome_1.

4. **Collisions are destructive, not constructive.** Random molecular combination destroys functional structures rather than repairing them. This makes sense — random assembly of a functional Petri net from fragments is astronomically unlikely.

5. **The two setups respond to different levers.** ed benefits most from faster replication (grab_rate), ri benefits most from more raw material (ambient surplus). This suggests they have different failure modes: ed dies from slow replication, ri dies from resource depletion.

### Next steps

- **Combine R4 + A2**: Try grab_rate=5 with ambient=500 for ed — could be additive.
- **Extend promising runs**: Run ed_R4 and ri_A2 to 50k or 100k reactions to see if they're truly self-sustaining or just slower to die.
- **Fine-tune grab_rate**: Try values between 1 and 5 (e.g., 2, 3) to find the optimum.
- **Ambient surplus for ed**: Since ed_R4 works with baseline ambient, what happens with grab_rate=5 + ambient=500?

---

<details>
<summary>Shared baseline env</summary>

```json
{"transition_rate": 10, "grab_rate": 1, "break_rate": "1/1000000", "collision_rate": "1/100000"}
```

</details>

<details>
<summary>endless_duplication initial molecules</summary>

```json
[
  {"mol": "AAABAAAADDFCBAAADDFBAAABDDFCBAABDDFBAAACDDFCBAACDDFBAAADDDFCBAADDDFBAAAFDDFCBAAFDDFBAAAAADDFCAABBBDDFAAABAAAADDFABAFAFDDFAAABAAABDDFABAFBFDDFAAABAAACDDFABAFCFDDFAAABAAADDDFABAFDFDDFAAABAAAFDDFABAFFFDDFAAABCAAADDFCCAAADDFBCBABDDFCCAABDDFBCCACDDFCCAACDDFBCDADDDFCCAADDDFBCFAFDDFCCAAFDDFBABAAADDFCAABBBDDFAAACAAAAADDFABBAAACAAAAADDFABBAAABAABBBDDFCAACCCDDFAAABAABBBDDFABADFDFFFDDFAAABBACCCDDFCAACCCDDFABC", "qtt": 1},
  {"mol": "DDCBAFDDCCCAACFDDCCCABBAAAFDDFFFDFDABAFDDBBBAABAAAFDDCCCAACFDDBBBAABAAABBAFDDAAAAACAAABBAFDDAAAAACAAAFDDBBBAACFDDAAABABFDDFAACCFDDFAFCBFDDDAACCFDDDADCBFDDCAACCFDDCACCBFDDBAACCFDDBABCBFDDAAACCFDDAAACBAAAFDDFFFABAFDDFAAABAAAFDDFDFABAFDDDAAABAAAFDDFCFABAFDDCAAABAAAFDDFBFABAFDDBAAABAAAFDDFAFABAFDDAAAABAAAFDDBBBAACFDDAAAAABFDDFAABCFDDFAAABFDDDAABCFDDDAAABFDDCAABCFDDCAAABFDDBAABCFDDBAAABFDDAAABCFDDAAAABAAA", "qtt": 1},
  {"mol": "A", "qtt": 50, "ambient": true},
  {"mol": "B", "qtt": 50, "ambient": true},
  {"mol": "C", "qtt": 50, "ambient": true},
  {"mol": "D", "qtt": 50, "ambient": true},
  {"mol": "F", "qtt": 50, "ambient": true}
]
```

</details>

<details>
<summary>ribosome_1 initial molecules</summary>

```json
[
  {"mol": "AAABAAAADDFCBAAADDFBAAABDDFCBAABDDFBAAACDDFCBAACDDFBAAADDDFCBAADDDFBAAAFDDFCBAAFDDFBAAAAADDFCAABBBDDFAAABAAAADDFABAFAFDDFAAABAAABDDFABAFBFDDFAAABAAACDDFABAFCFDDFAAABAAADDDFABAFDFDDFAAABAAAFDDFABAFFFDDFAAABCAAADDFCCAAADDFBCBABDDFCCAABDDFBCCACDDFCCAACDDFBCDADDDFCCAADDDFBCFAFDDFCCAAFDDFBABAAADDFCAABBBDDFAAACAAAAADDFABBAAACAAAAADDFABBAAABAABBBDDFCAACCCDDFAAABAABBBDDFABADFDFFFDDFAAABBACCCDDFCAACCCDDFABC", "qtt": 1},
  {"mol": "DDBBAFDDAABCAAAFDDFBFABAFDDAAABAAAFDDAAABFDDFAFABAAAAA", "qtt": 1, "ambient": false},
  {"mol": "A", "qtt": 50, "ambient": true},
  {"mol": "B", "qtt": 50, "ambient": true},
  {"mol": "C", "qtt": 50, "ambient": true},
  {"mol": "D", "qtt": 50, "ambient": true},
  {"mol": "F", "qtt": 50, "ambient": true}
]
```

</details>

**Date:** 2026-03-08 | **Commit:** `28966b6358b6422a27c9c1e70798a2892382c766`
