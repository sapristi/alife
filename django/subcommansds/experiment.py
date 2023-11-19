import json
import typer
from enum import Enum
from experiment.engine import StatLogCollector, YaacWrapper

from experiment.models import BactSnapshot, Experiment, Log

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
    return

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
        snapshot_period: int | None = typer.Option(None, help="Snapshots saved every N reactions."),
        stats_period: int  = typer.Option(10, help="States saved every N reactions."),
):
    """Run an experiment, from initial state, or last snapshot"""
    experiment = Experiment.objects.get(id=experiment_id)
    if  (snapshot := experiment.last_snapshot) and not reset:
        state = json.dumps(snapshot.data)
        kwargs = {
            "use_dump": "true",
        }
        nb_reactions_start = snapshot.nb_reactions
        print(f"Starting from previous snapshot at reaction {nb_reactions_start}")
    else:
        state = json.dumps(experiment.initial_state)
        BactSnapshot.objects.filter(experiment=experiment).delete()
        Log.objects.filter(experiment=experiment).delete()
        kwargs = {}
        nb_reactions_start = 0
        print(f"Starting from initial state")

    if log_level:
        kwargs["log_level"] = log_level.value

    log_collector = StatLogCollector(experiment=experiment)
    yaac = YaacWrapper(log_collector)
    if snapshot_period is None:
        snapshot_period = nb_reacs

    if snapshot_period is None:
        res_data = yaac.run(
            "eval",
            **kwargs,
            nb_steps=nb_reacs,
            initial_state=state,
            stats_period=stats_period,
        )
        res_snapshot = BactSnapshot(
            experiment=experiment,
            nb_reactions=nb_reactions_start + nb_reacs,
            data=res_data
        )
        res_snapshot.save()
        print(f"Saved new snapshot, {res_snapshot.nb_reactions} reactions")

    else:
        nb_steps = nb_reacs // snapshot_period
        for _ in range(nb_steps):
            res_data = yaac.run(
                "eval",
                **kwargs,
                nb_steps=nb_reacs,
                initial_state=state,
                stats_period=stats_period,
            )
            res_snapshot = BactSnapshot(
                experiment=experiment,
                nb_reactions=nb_reactions_start + nb_reacs,
                data=res_data
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

