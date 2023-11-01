import json
import djclick as click
from pathlib import Path
from django.conf import settings

from experiment.models import InitialState

engine_test_fixtures_path : Path = settings.BASE_DIR / ".." / "engine" / "tests" / "bact_states"

@click.command()
@click.option('--force', is_flag=True, default=False, help="Force overriding existing")
def run(force: bool):
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
