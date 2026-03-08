# Parameter Sweep Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Run 14 experiments varying rates and ambient molecule counts across both molecule setups, then analyze which parameters extend replication longevity.

**Architecture:** Add a `create-variant` CLI command that copies an InitialState with env/ambient overrides, then a `batch-run` command to run multiple experiments sequentially. Use existing `stats` command to extract results.

**Tech Stack:** Python/Typer CLI, Django ORM, existing `yaac` engine binary.

---

### Task 1: Add `create-variant` command

**Files:**
- Modify: `django/subcommansds/experiment.py`

**Step 1: Add the command after the existing `create` command (after line 214)**

```python
@app.command()
def create_variant(
    initial_state_id: int,
    name: str = typer.Option(..., help="Experiment name"),
    description: str = typer.Option("", help="Experiment description"),
    env_override: str = typer.Option(None, help="JSON dict of env overrides, merged into source env"),
    ambient_qtt: int = typer.Option(None, help="Override qtt for all ambient molecules"),
):
    """Create an experiment from an InitialState with env/ambient overrides"""
    initial_state = InitialState.objects.get(id=initial_state_id)
    env = dict(initial_state.env)
    if env_override:
        env.update(json.loads(env_override))

    mols = [dict(m) for m in initial_state.mols]
    if ambient_qtt is not None:
        for m in mols:
            if m.get("ambient"):
                m["qtt"] = ambient_qtt

    experiment = Experiment(
        name=name,
        description=description,
        initial_state={"mols": mols, "env": env},
    )
    experiment.save()
    print(f"Created experiment: {format_experiment(experiment)}")
    print(f"  env: {json.dumps(env)}")
    if ambient_qtt is not None:
        total = sum(m["qtt"] for m in mols if m.get("ambient"))
        print(f"  ambient qtt: {ambient_qtt} per type ({total} total)")
```

**Step 2: Test it manually**

Run: `cd /home/sapristi/dev/alife/django && uv run ./cli.py experiment create-variant 8 --name "test_variant" --env-override '{"break_rate": "1/10000000"}' --ambient-qtt 200`

Expected: Creates an experiment with modified env and ambient qtt. Verify with `uv run ./cli.py experiment info <id>`.

**Step 3: Delete test experiment and commit**

```bash
cd /home/sapristi/dev/alife/django
uv run python -c "
import os, django; os.environ['DJANGO_SETTINGS_MODULE']='alife.settings'; django.setup()
from experiment.models import Experiment
Experiment.objects.filter(name='test_variant').delete()
"
git add subcommansds/experiment.py
git commit -m "django: add create-variant command for parameter sweep experiments"
```

---

### Task 2: Add `batch-run` command

**Files:**
- Modify: `django/subcommansds/experiment.py`

**Step 1: Add the command**

```python
@app.command()
def batch_run(
    experiment_ids: str = typer.Argument(help="Comma-separated experiment IDs"),
    nb_reacs: int = typer.Argument(help="Number of reactions per experiment"),
    snapshot_period: int = typer.Option(None, help="Snapshots saved every N reactions."),
    stats_period: int = typer.Option(500, help="Stats saved every N reactions."),
):
    """Run multiple experiments sequentially"""
    ids = [int(x.strip()) for x in experiment_ids.split(",")]
    for exp_id in ids:
        experiment = Experiment.objects.get(id=exp_id)
        print(f"\n{'='*60}")
        print(f"Running {format_experiment(experiment)}")
        print(f"{'='*60}")
        run(
            experiment_id=exp_id,
            nb_reacs=nb_reacs,
            reset=False,
            log_level=None,
            snapshot_period=snapshot_period or nb_reacs,
            stats_period=stats_period,
        )
```

**Step 2: Commit**

```bash
git add subcommansds/experiment.py
git commit -m "django: add batch-run command for running multiple experiments"
```

---

### Task 3: Create all 14 experiments

**Step 1: Create the experiments using a shell script**

Source InitialState IDs: `8` = endless_duplication, `9` = ribosome_1.
Baseline env: `{"transition_rate": 10, "grab_rate": 1, "break_rate": "1/1000000", "collision_rate": "1/100000"}`

```bash
cd /home/sapristi/dev/alife/django

# R1: break_rate=1/10000000
uv run ./cli.py experiment create-variant 8 --name "ed_R1_low_break" --description "break_rate=1/10000000" --env-override '{"break_rate": "1/10000000"}'
uv run ./cli.py experiment create-variant 9 --name "ri_R1_low_break" --description "break_rate=1/10000000" --env-override '{"break_rate": "1/10000000"}'

# R2: collision_rate=1/10000
uv run ./cli.py experiment create-variant 8 --name "ed_R2_hi_collision" --description "collision_rate=1/10000" --env-override '{"collision_rate": "1/10000"}'
uv run ./cli.py experiment create-variant 9 --name "ri_R2_hi_collision" --description "collision_rate=1/10000" --env-override '{"collision_rate": "1/10000"}'

# R3: collision_rate=1/1000
uv run ./cli.py experiment create-variant 8 --name "ed_R3_vhi_collision" --description "collision_rate=1/1000" --env-override '{"collision_rate": "1/1000"}'
uv run ./cli.py experiment create-variant 9 --name "ri_R3_vhi_collision" --description "collision_rate=1/1000" --env-override '{"collision_rate": "1/1000"}'

# R4: grab_rate=5
uv run ./cli.py experiment create-variant 8 --name "ed_R4_hi_grab" --description "grab_rate=5" --env-override '{"grab_rate": 5}'
uv run ./cli.py experiment create-variant 9 --name "ri_R4_hi_grab" --description "grab_rate=5" --env-override '{"grab_rate": 5}'

# R5: grab_rate=10
uv run ./cli.py experiment create-variant 8 --name "ed_R5_vhi_grab" --description "grab_rate=10" --env-override '{"grab_rate": 10}'
uv run ./cli.py experiment create-variant 9 --name "ri_R5_vhi_grab" --description "grab_rate=10" --env-override '{"grab_rate": 10}'

# A1: ambient_qtt=200
uv run ./cli.py experiment create-variant 8 --name "ed_A1_amb200" --description "ambient qtt=200" --ambient-qtt 200
uv run ./cli.py experiment create-variant 9 --name "ri_A1_amb200" --description "ambient qtt=200" --ambient-qtt 200

# A2: ambient_qtt=500
uv run ./cli.py experiment create-variant 8 --name "ed_A2_amb500" --description "ambient qtt=500" --ambient-qtt 500
uv run ./cli.py experiment create-variant 9 --name "ri_A2_amb500" --description "ambient qtt=500" --ambient-qtt 500
```

**Step 2: Verify with `experiment list`**

Run: `uv run ./cli.py experiment list`
Expected: 14 new experiments (IDs 7-20) plus the 6 existing ones.

**Note:** The ribosome_1 InitialState (#9) has `break_rate: 0.001` and `collision_rate: 0` — these will be overridden by the `create-variant` env_override for R1-R5. But for A1 and A2, the ambient-only variants will inherit the *original* ribosome_1 env (high break_rate, no collisions), not the matched baseline. To use the matched baseline env for A1/A2, pass `--env-override '{"transition_rate": 10, "grab_rate": 1, "break_rate": "1/1000000", "collision_rate": "1/100000"}'` as well.

Update the A1/A2 commands for ribosome_1:
```bash
MATCHED_ENV='{"transition_rate": 10, "grab_rate": 1, "break_rate": "1/1000000", "collision_rate": "1/100000"}'
uv run ./cli.py experiment create-variant 9 --name "ri_A1_amb200" --description "ambient qtt=200, matched env" --ambient-qtt 200 --env-override "$MATCHED_ENV"
uv run ./cli.py experiment create-variant 9 --name "ri_A2_amb500" --description "ambient qtt=500, matched env" --ambient-qtt 500 --env-override "$MATCHED_ENV"
```

Similarly for R1-R5 ribosome variants — each `--env-override` should include the full matched baseline plus the one changed parameter:
```bash
uv run ./cli.py experiment create-variant 9 --name "ri_R1_low_break" --description "break_rate=1/10000000" --env-override '{"transition_rate": 10, "grab_rate": 1, "break_rate": "1/10000000", "collision_rate": "1/100000"}'
uv run ./cli.py experiment create-variant 9 --name "ri_R2_hi_collision" --description "collision_rate=1/10000" --env-override '{"transition_rate": 10, "grab_rate": 1, "break_rate": "1/1000000", "collision_rate": "1/10000"}'
uv run ./cli.py experiment create-variant 9 --name "ri_R3_vhi_collision" --description "collision_rate=1/1000" --env-override '{"transition_rate": 10, "grab_rate": 1, "break_rate": "1/1000000", "collision_rate": "1/1000"}'
uv run ./cli.py experiment create-variant 9 --name "ri_R4_hi_grab" --description "grab_rate=5" --env-override '{"transition_rate": 10, "grab_rate": 1, "break_rate": "1/1000000", "collision_rate": "1/100000", "grab_rate": 5}'
uv run ./cli.py experiment create-variant 9 --name "ri_R5_vhi_grab" --description "grab_rate=10" --env-override '{"transition_rate": 10, "grab_rate": 1, "break_rate": "1/1000000", "collision_rate": "1/100000", "grab_rate": 10}'
```

---

### Task 4: Run all 14 experiments

**Step 1: Run using batch-run**

```bash
cd /home/sapristi/dev/alife/django
# Get the comma-separated list of new experiment IDs from `experiment list`
# Then run them all:
uv run ./cli.py experiment batch-run "7,8,9,10,11,12,13,14,15,16,17,18,19,20" 10000 --stats-period 500 --snapshot-period 5000
```

Expected: Each experiment runs 10k reactions (or stops early if no reactions available). Progress printed for each.

---

### Task 5: Collect results and write report

**Files:**
- Create: `docs/experiments/2026-03-08-parameter-sweep.md`

**Step 1: Extract key metrics from each experiment**

For each experiment, run:
```bash
uv run ./cli.py experiment stats <id> --last 5
```

Collect `areactants.nb_species`, `areactants.total_nb`, and last reaction count.

**Step 2: Build comparison table**

Create a summary table with columns:
- Experiment name
- Variation
- Last reaction (or 10000 if completed)
- Active species at reaction 5000
- Active species at end
- Grabs at end

**Step 3: Write analysis**

Compare results against the baseline (experiments 5, 6 which died at ~8500). Key questions:
- Which parameter had the largest effect?
- Did any experiment sustain active species through 10000 reactions?
- Did collision_rate create a repair pathway?

**Step 4: Add footer with initial states and commit hash, save to `docs/experiments/2026-03-08-parameter-sweep.md`**

**Step 5: Commit report**

```bash
cd /home/sapristi/dev/alife
git add docs/experiments/2026-03-08-parameter-sweep.md
git commit -m "docs: add parameter sweep experiment report"
```
