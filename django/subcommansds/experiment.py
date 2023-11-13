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
        nb_steps: int,
        reset: bool=typer.Option(False, is_flag=True, help="Restart from the initial state"),
        log_level: LogLevel = typer.Option(None)
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

    log_collector = StatLogCollector(experiment=experiment)
    yaac = YaacWrapper(log_collector)
    res_data = yaac.run("eval", **kwargs, log_level=log_level.value, nb_steps=nb_steps, initial_state=state)
    if res_data is None:
        print("Error")
        return
    res_snapshot = BactSnapshot(
        experiment=experiment,
        nb_reactions=nb_reactions_start + nb_steps,
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

