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

## Copier v2: T-copier + DEEE-template (2026-03-08 04:30)

Report: `docs/experiments/20260308T0430-copier-v2-tcopier.md`

| ID | Name | Findings |
|----|------|----------|
| 28 | copier_v2 | **First self-sustaining system.** T-copier (no D prefix) + inert DEEE-templates. 200k reactions: active species 1→77, active count 10→84, inert count 1070→4727. Copier/template separation prevents mutual grabbing. Break mutations create emergent molecular diversity. |

## Copier v4: Inert template full system (2026-03-08 05:30)

Report: `docs/experiments/20260308T0530-copier-v4-inert-templates.md`

| ID | Name | Findings |
|----|------|----------|
| 55 | v4fix_clean_g5 | **First full self-replicating system.** Both T-copier and R-copier replicate via inert DAEEE-templates. 200k reactions: 5+5 → 56 T-copiers + 31 R-copiers. Templates are bottleneck (all "in use"). |
| 56 | v4fix_mut_g1 | **22 active species from 2 originals.** Mutations (break+collision) create molecular diversity. Original copiers dominate (count=8+5) while mutant species are singletons. Open-ended diversification but not yet Darwinian evolution — mutants don't self-replicate. |
| 57-58 | v4fix_mut_g5/g10 | Pending (running). |

Key insight: inert templates (DAEEE prefix, EEE=stop_interpretation) eliminate the reaction competition that killed all v3 designs. R-copier's 5-step skip chain required fixing a token shortage bug (T_SKIP1 needed ia_split from P11 token factory).
