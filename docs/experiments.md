# Experiment Log

## Baseline (2026-03-08 01:55)

| ID | Name | Findings |
|----|------|----------|
| 3 | endless_duplication_run1 | Stable replication then fragmentation then collapse by 10k. Break damage accumulates without repair. |
| 4 | ribosome_1_run1 | Halted at 1957 reactions. Single-point failure—loss of sole replicator kills the system. |

## Matched-environment comparison (2026-03-08 02:09)

Report: `docs/experiments/20260308T0209-endless-dup-vs-ribosome-matched.md`

| ID | Name | Findings |
|----|------|----------|
| 5 | endless_dup_matched | Diversified to 8 species then sudden crash ~8500. |
| 6 | ribosome_1_matched | More stable (3 species plateau) but also died ~8500. Diversification doesn't ensure resilience. |

## Parameter sweep (2026-03-08 02:33)

Report: `docs/experiments/20260308T0233-parameter-sweep.md`

| ID | Name | Findings |
|----|------|----------|
| 8-9 | low_break (1/10M) | Break rate not the bottleneck. |
| 10-13 | hi/vhi_collision | Higher collision accelerates death. |
| 14-17 | hi/vhi_grab (5, 10) | grab=5 best for ed (11 active species at 9.5k). Minimal effect on ri. |
| 18-21 | amb200/amb500 | Ambient surplus helps ri most (4 species, 6 grabs at 9.5k). |

ed needs faster replication (grab_rate), ri needs more raw material (ambient).

## Parameter sweep follow-up — 50k runs (2026-03-08 02:38)

Report: `docs/experiments/20260308T0238-parameter-sweep-followup.md`

| ID | Name | Findings |
|----|------|----------|
| 22-23 | ed_grab2, ed_grab3 | Died before 50k. grab=5 remains optimal. |
| 24-26 | combined grab5+ambient | Mildly additive, all still died. |

No configuration is self-sustaining. All follow: growth -> peak -> decline -> death. Systems need qualitative changes (self-copying, repair, redundancy).
