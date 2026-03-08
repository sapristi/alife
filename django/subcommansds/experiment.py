import csv
import io
import json
import typer
from enum import Enum
from experiment.engine import QuietLogHandler, StatLogCollector, YaacWrapper

from experiment.models import BactSnapshot, Experiment, InitialState, Log

app = typer.Typer(
    name="experiment", no_args_is_help=True, add_completion=False,
    help="Manage experiments"
)

def format_experiment(experiment: Experiment):
    exp_str = f"[{experiment.pk}] - {experiment.name}"
    if experiment.description:
        exp_str += f" ({experiment.description})"
    return exp_str


@app.command()
def list():
    "List experiments"
    print("Available experiments:")
    for experiment in Experiment.objects.all():
        line = "* " + format_experiment(experiment)
        if snapshot := experiment.last_snapshot:
            line += f"\n  last snapshot: {snapshot.nb_reactions} reactions"
        print(line)


class LogLevel(Enum):
    Debug = "Debug"
    Info = "Info"
    Warning = "Warning"


@app.command()
def run(
        experiment_id: int,
        nb_reacs: int,
        reset: bool=typer.Option(False, is_flag=True, help="Restart from the initial state"),
        log_level: LogLevel = typer.Option(None),
        snapshot_period: int = typer.Option(None, help="Snapshots saved every N reactions."),
        stats_period: int = typer.Option(10, help="States saved every N reactions."),
):
    """Run an experiment, from initial state, or last snapshot"""
    experiment = Experiment.objects.get(id=experiment_id)
    if  (snapshot := experiment.last_snapshot) and not reset:
        state = snapshot.data
        nb_reactions_start = snapshot.nb_reactions
        print(f"Starting from previous snapshot at reaction {nb_reactions_start}")
    else:
        BactSnapshot.objects.filter(experiment=experiment).delete()
        Log.objects.filter(experiment=experiment).delete()

        state = YaacWrapper(QuietLogHandler()).run("load-signature", signature=experiment.initial_state)
        nb_reactions_start = 0
        print(f"Starting from initial state")
        if reset:
            print("All previous dumps and stats have been deleted")
        BactSnapshot(experiment=experiment, data=state).save()

    kwargs = {}
    if log_level:
        kwargs["log_level"] = log_level.value

    log_collector = StatLogCollector(experiment=experiment)
    yaac = YaacWrapper(log_collector)
    if snapshot_period is None:
        snapshot_period = nb_reacs

    nb_steps = nb_reacs // snapshot_period
    current_nb_reacs = nb_reactions_start
    for _ in range(nb_steps):
        log_collector.last_dump = None
        yaac.run(
            "eval",
            **kwargs,
            nb_steps=snapshot_period,
            initial_state=state,
            stats_period=stats_period,
        )
        if log_collector.last_dump is None:
            print(f"No dump received, stopping early at {current_nb_reacs} reactions")
            break
        state = log_collector.last_dump
        new_reac_count = state.get("reac_counter", 0)
        if new_reac_count == current_nb_reacs:
            print(f"No reactions occurred, stopping early at {current_nb_reacs} reactions")
            break
        current_nb_reacs = new_reac_count
        res_snapshot = BactSnapshot(
            experiment=experiment,
            data=state
        )
        res_snapshot.save()
        print(f"Saved new snapshot, {res_snapshot.nb_reactions} reactions")


@app.command()
def clear(experiment_id: int):
    """Remove all snapshots from experiment"""
    experiment = Experiment.objects.get(id=experiment_id)
    snapshots = BactSnapshot.objects.filter(experiment=experiment)
    print(f"Will remove {snapshots.count()} snapshots from experiment {format_experiment(experiment)}")
    input()
    snapshots.delete()


@app.command()
def info(experiment_id: int):
    """Show detailed information about an experiment"""
    experiment = Experiment.objects.get(id=experiment_id)
    print(f"Experiment: {format_experiment(experiment)}")
    print()

    # Initial state summary
    init = experiment.initial_state
    if mols := init.get("mols"):
        total_qtt = sum(m.get("qtt", 1) for m in mols)
        print(f"Initial state: {len(mols)} molecule types, {total_qtt} total molecules")
    if env := init.get("env"):
        print(f"Environment:   {json.dumps(env)}")
    print()

    # Snapshots
    snapshots = experiment.snapshots
    snap_count = snapshots.count()
    print(f"Snapshots: {snap_count}")
    if last := experiment.last_snapshot:
        print(f"Last snapshot: {last.nb_reactions} reactions ({last.timestamp.strftime('%Y-%m-%d %H:%M')})")
    print()

    # Logs
    log_count = Log.objects.filter(experiment=experiment).count()
    print(f"Log entries: {log_count}")
    if log_count > 0:
        last_log = Log.objects.filter(experiment=experiment).order_by("reac_count").last()
        print(f"Last log at reaction: {last_log.reac_count}")


@app.command()
def stats(
    experiment_id: int,
    last: int = typer.Option(None, "--last", help="Show only the last N entries"),
    as_csv: bool = typer.Option(False, "--csv", is_flag=True, help="Output as CSV"),
):
    """Show log statistics for an experiment"""
    experiment = Experiment.objects.get(id=experiment_id)
    logs = Log.objects.filter(experiment=experiment).order_by("reac_count")

    if logs.count() == 0:
        print(f"No log entries for experiment {format_experiment(experiment)}")
        print("Run with --stats-period to collect stats during simulation.")
        return

    if last:
        logs = logs[max(0, logs.count() - last):]

    # Collect all stat keys from the tags field, flattening nested dicts
    all_keys = set()
    rows = []
    for log in logs:
        tags = log.data.get("tags", {})
        flat = {"reac_count": log.reac_count}
        def _flatten(prefix, data):
            if isinstance(data, dict):
                for k, v in sorted(data.items()):
                    _flatten(f"{prefix}.{k}" if prefix else k, v)
            else:
                flat[prefix] = data
                all_keys.add(prefix)
        for section_name in sorted(tags):
            _flatten(section_name, tags[section_name])
        rows.append(flat)

    columns = ["reac_count"] + sorted(all_keys)

    if as_csv:
        out = io.StringIO()
        writer = csv.DictWriter(out, fieldnames=columns, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)
        print(out.getvalue(), end="")
    else:
        # Simple table output
        col_widths = {c: len(c) for c in columns}
        for row in rows:
            for c in columns:
                col_widths[c] = max(col_widths[c], len(str(row.get(c, ""))))

        header = " | ".join(c.rjust(col_widths[c]) for c in columns)
        print(header)
        print("-" * len(header))
        for row in rows:
            line = " | ".join(str(row.get(c, "")).rjust(col_widths[c]) for c in columns)
            print(line)


@app.command()
def create(
    initial_state_id: int,
    name: str = typer.Option("", help="Experiment name"),
    description: str = typer.Option("", help="Experiment description"),
):
    """Create a new experiment from an initial state"""
    initial_state = InitialState.objects.get(id=initial_state_id)
    if not name:
        name = initial_state.name

    experiment = Experiment(
        name=name,
        description=description,
        initial_state={"mols": initial_state.mols, "env": initial_state.env},
    )
    experiment.save()
    print(f"Created experiment: {format_experiment(experiment)}")


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


@app.command()
def compare(experiment_id_1: int, experiment_id_2: int):
    """Compare two experiments side by side"""
    exp1 = Experiment.objects.get(id=experiment_id_1)
    exp2 = Experiment.objects.get(id=experiment_id_2)

    def exp_summary(exp):
        init = exp.initial_state
        mol_count = len(init.get("mols", []))
        total_qtt = sum(m.get("qtt", 1) for m in init.get("mols", []))
        snap_count = exp.snapshots.count()
        last = exp.last_snapshot
        last_reacs = last.nb_reactions if last else 0
        log_count = Log.objects.filter(experiment=exp).count()
        return {
            "Name": exp.name,
            "Description": exp.description or "-",
            "Molecule types": str(mol_count),
            "Total molecules": str(total_qtt),
            "Env": json.dumps(init.get("env", {})),
            "Snapshots": str(snap_count),
            "Last reaction": str(last_reacs),
            "Log entries": str(log_count),
        }

    s1 = exp_summary(exp1)
    s2 = exp_summary(exp2)

    label_w = max(len(k) for k in s1)
    col1_w = max(len(v) for v in s1.values())
    col2_w = max(len(v) for v in s2.values())

    header = f"{'':>{label_w}} | {f'[{exp1.pk}]':>{col1_w}} | {f'[{exp2.pk}]':>{col2_w}}"
    print(header)
    print("-" * len(header))
    for key in s1:
        print(f"{key:>{label_w}} | {s1[key]:>{col1_w}} | {s2[key]:>{col2_w}}")
