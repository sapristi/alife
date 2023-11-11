import json
import subprocess as sp
import typer
from enum import Enum

from experiment.models import BactSnapshot, Experiment

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
    experiment = Experiment.objects.get(id=experiment_id)
    if  (snapshot := experiment.last_snapshot) and not reset:
        state = json.dumps(snapshot.data)
        command = ["./yaac", "eval", f"--initial-state={state}",
             "--use-dump=true", f"--nb-steps={nb_steps}"]
        nb_reactions_start = snapshot.nb_reactions
        print(f"Starting from previous snapshot at reaction {nb_reactions_start}")
    else:
        state = json.dumps(experiment.initial_state)
        command = ["./yaac", "eval", f"--initial-state={state}", f"--nb-steps={nb_steps}"]
        nb_reactions_start = 0
        print(f"Starting from initial state")

    if log_level:
        command.append(f"--log-level={log_level}")
    p = sp.run(
        command,
        capture_output=True,
        encoding="utf-8"
    )
    if p.returncode != 0:
        print("FAILED")
        print("Command", command)
        print("Error", p.stderr)
        print("Logs", p.stdout)
        return

    output = p.stdout.splitlines()
    logs = output[:-1]
    print("\n".join(logs))
    res_data = json.loads(output[-1])
    res_snapshot = BactSnapshot(
        experiment=experiment,
        nb_reactions=nb_reactions_start + nb_steps,
        data=res_data
    )
    res_snapshot.save()
    print("Saved new snapshot")


@app.command()
def clear(experiment_id: int):
    """Remove all snapshots from experiment"""
    experiment = Experiment.objects.get(id=experiment_id)
    snapshots = BactSnapshot.objects.filter(experiment=experiment)
    print(f"Will remove {snapshots.count()} snapshots from experiment {format_experiment(experiment)}")
    input()
    snapshots.delete()

