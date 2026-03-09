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

## Copier v5: R-copier and Darwinian evolution (2026-03-08 21:00)

Report: `docs/experiments/20260308T2100-v5-rcopier-darwinian-evolution.md`

| ID | Name | Findings |
|----|------|----------|
| 69 | v5_4comp_clean | Clean replication: 5+5 → 68 T-cop + 20 R-cop in 50k. Zero mismatches. |
| 70 | v5_4comp_lowmut | Low mutation (break=1e-6): 37 species at 200k, no DAEEE mutant templates. |
| 71 | v5_4comp_himut | **Darwinian evolution confirmed.** break=1e-4, 400k: 11 DAEEE mutant template species, 3 Darwinian pairs (mutant template + matching mutant copier). Parasitic truncated copiers emerge. |

## Break length exponent (2026-03-09 12:00)

Report: `docs/experiments/20260309T1200-break-length-exponent.md`

| ID | Name | Findings |
|----|------|----------|
| 72 | 4comp break_exp=0.5 (control) | Control: default sqrt scaling. 400k: 335 T-cop, 59 R-cop, 14 DAEEE mutants, 0 Darwinian pairs. |
| 73 | 4comp break_exp=0 (pressure) | Uniform pressure (exp=0, rate=1e-4): similar growth, 16 DAEEE mutants, **2 Darwinian pairs**. Effective break rate 10x lower. |
| 74 | 4comp break_exp=0 rate=1e-3 | Compensated (exp=0, rate=1e-3): 18 DAEEE mutants, **3 Darwinian pairs**. Uniform pressure produces more Darwinian evolution. |

## Higher break rates (2026-03-09 14:00)

Report: `docs/experiments/20260309T1400-higher-break-rates.md`

| ID | Name | Findings |
|----|------|----------|
| 78 | 4comp break_exp=0 rate=5e-3 | Moderate increase: 22 DAEEE mutants, **5 Darwinian pairs**, 104 active species. |
| 79 | 4comp break_exp=0 rate=1e-2 | High break: 165 DAEEE mutants (52sp), **14 Darwinian pairs**, 172 active species. Dominant parasitic R-cop truncation (79 copies). R-copiers drop to 19. |
| 80 | 4comp break_exp=0.5 rate=1e-3 | Length-dependent at similar eff. rate: 176 DAEEE mutants, **17 Darwinian pairs**. Same parasitic lineage emerges. Exponent matters less than effective rate. |

## Collision rate (2026-03-09 18:00)

Report: `docs/experiments/20260309T1800-collision-rate.md`

| ID | Name | Findings |
|----|------|----------|
| 87 | 4comp coll=2e-5 | **Sweet spot.** 2x collision: 70 DAEEE mutants, **8 Darwinian pairs**, 124 active species. Copiers survive (240 T, 27 R). All pairs still from breaks, not collisions. |
| 85 | 4comp coll=5e-5 | 5x collision: massive diversity (344 active sp, 1864 inert sp) but copiers extinct by 400k. Darwinian pairs peak at 3 then drop to 0. |
| 84 | 4comp coll=1e-4 | 10x collision: system dead by 100k, engine crash (`cannot pop No_token`). |
| 81-83 | coll=1e-3 to 1e-1 | System dead immediately. Collisions far more destructive than breaks. |
