#!/usr/bin/env python
import os
import json
import typer
import django
from pathlib import Path

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'alife.settings')
django.setup()

from django.conf import settings
from subcommansds import experiment
from experiment.models import InitialState
app = typer.Typer(no_args_is_help=True, add_completion=False)

app.add_typer(experiment.app)


engine_test_fixtures_path : Path = settings.BASE_DIR / ".." / "engine" / "tests" / "bact_states"

@app.command()
def load_initial_states(force: bool = typer.Option(False, is_flag=True, help="Force overriding existing")):
    """Load initial states from engine into database"""
    for fpath in engine_test_fixtures_path.iterdir():
        if not fpath.is_file(): continue
        if not fpath.suffix == ".json": continue

        data = json.loads(fpath.read_text())
        name = fpath.stem

        (state, created) = InitialState.objects.get_or_create(defaults=data, name=name)
        if not created:
            if not force:
                print(f"Not overriding existing {name}")
                continue
            else:
                state.mols = data["mols"]
                state.env = data["env"]
                print(f"Will override {name}")

        print(f"Loaded {name}")


if __name__ == "__main__":
    app()
