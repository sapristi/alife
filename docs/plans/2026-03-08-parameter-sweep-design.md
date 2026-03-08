# Parameter Sweep: Rate Tuning & Ambient Surplus

**Date:** 2026-03-08
**Goal:** Identify which parameter changes extend replication longevity in YAACS

## Baseline

Experiments 5 and 6 (matched env): `break_rate=1/1000000`, `collision_rate=1/100000`, `grab_rate=1`, `transition_rate=10`, ambient `qtt=50`. Both setups die around reaction 8500.

## Parameter variations

### Rate variations (one parameter changed, rest = baseline)

| ID | Parameter | Value | Rationale |
|----|-----------|-------|-----------|
| R1 | `break_rate` | `1/10000000` | 10x less damage |
| R2 | `collision_rate` | `1/10000` | 10x more recombination |
| R3 | `collision_rate` | `1/1000` | 100x more recombination |
| R4 | `grab_rate` | `5` | 5x faster replication |
| R5 | `grab_rate` | `10` | 10x faster (matches transition_rate) |

### Ambient variations (baseline rates)

| ID | Ambient `qtt` | Total ambient |
|----|---------------|---------------|
| A1 | 200 | 1000 |
| A2 | 500 | 2500 |

## Experiment matrix

7 configs x 2 molecule setups (endless_duplication, ribosome_1) = 14 experiments.

## Run parameters

10,000 reactions, `stats_period=500`, `snapshot_period=5000`.

## Implementation plan

### Step 1: Add `create-variant` CLI command

Add a command to `subcommansds/experiment.py` that creates an experiment from an existing InitialState with overridden env values and/or ambient qtt. This avoids manually creating 14 InitialState + Experiment pairs.

```
uv run ./cli.py experiment create-variant <initial_state_id> --env-override '{"break_rate": "1/10000000"}' --ambient-qtt 200 --name "ed_R1"
```

The command should:
- Copy mols from the source InitialState
- If `--ambient-qtt` is set, update qtt for all ambient mols
- Merge `--env-override` into the source env
- Create the Experiment directly (no new InitialState needed)

### Step 2: Create all 14 experiments

Using the new command, create experiments with naming convention: `{setup}_{variation}` where setup is `ed` or `ri` and variation is `R1`-`R5` or `A1`-`A2`.

### Step 3: Run all experiments

Run each experiment: `uv run ./cli.py experiment run <id> 10000 --stats-period 500 --snapshot-period 5000`

### Step 4: Collect results

Use `experiment stats` to extract key metrics from each experiment. Compare `areactants.nb_species` and `areactants.total_nb` at reaction 5000 and at death/end.

### Step 5: Write report

Save comparison table and analysis to `docs/experiments/2026-03-08-parameter-sweep.md`.

## Key questions

- Does lower break_rate extend life proportionally?
- Does higher collision_rate create a repair pathway (broken fragments recombining)?
- Does higher grab_rate speed up replication enough to outpace breaks?
- Does more ambient material help (more raw material for replication)?
- Which parameter has the largest effect on longevity?
