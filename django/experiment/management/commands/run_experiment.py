import djclick as click

from experiment.models import BactSnapshot, Experiment

@click.command()
@click.option('--experiment-id', type=int,)
@click.option('--nb-steps', type=int)
def command(experiment_id: int | None, nb_steps: int | None):
    if experiment_id is None:
        print("Available experiments:")
        for experiment in Experiment.objects.all():
            exp_str = f"* [{experiment.pk}] - {experiment.name}"
            if experiment.description:
                exp_str += f" ({experiment.description})"
            print(exp_str)
        return

    experiment = Experiment.objects.get(experiment_id)
    snapshots = BactSnapshot.objects.filter(experiment=experiment)
    if snapshots.count():
        last_snapshot = snapshots.last()
