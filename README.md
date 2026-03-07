# YAACS - Yet Another Artificial Chemistry Simulator

An artificial chemistry simulator centered around Petri nets. Molecules encode proteins which fold into Petri nets that drive chemical reactions in a simulated environment.

## Architecture

The project has three components:

- **Engine** (`engine/`) — OCaml CLI that handles simulation: parsing molecules, building Petri nets, and running reactions. Outputs JSON to stdout.
- **Django app** (`django/`) — Web application for managing experiments, running simulations (calls the OCaml binary as a subprocess), and exposing a REST API. Also provides a Typer-based CLI (`cli.py`) for running experiments from the command line.
- **Cytoscape visualization** (`cytoscape/`) — JavaScript graph visualization using webcola for layout, bundled with webpack.

### How they connect

Django calls the `yaac` OCaml binary via `subprocess.Popen` (see `django/experiment/engine.py`). The engine reads JSON input from CLI arguments and writes JSON results to stdout. Django parses the output and stores snapshots/logs in SQLite.

Grafana connects to the Django SQLite database for experiment monitoring dashboards.

## Project structure

```
engine/                    # OCaml simulation engine
  bin/yaac.ml              # CLI entry point (cmdliner via ppx_subliner)
  bacterie/                # Simulation runtime (reactions, environments, molecule sets)
  base_chemistry/          # Core types: molecules, proteins, Petri nets, places, transitions
  libs/                    # Utility libraries (config, numerics, random, sets)
  jlog/                    # Custom JSON-capable logging library
  tests/                   # Alcotest tests and fixture states
    bact_states/           # JSON fixture files for initial states
  dune-project             # OCaml package definition

django/                    # Django web application
  manage.py                # Django management
  cli.py                   # Typer CLI entry point (experiment management)
  alife/                   # Django project settings
    settings.py
    urls.py
  experiment/              # Main Django app
    models.py              # Experiment, BactSnapshot, Log, InitialState
    engine.py              # YaacWrapper — subprocess interface to OCaml engine
    views.py               # REST API (DRF) and template views
    urls.py
    admin.py
    fixtures/
  subcommansds/            # Typer subcommands
    experiment.py          # list, run, clear experiments
  templates/               # HTML templates
  static/                  # Static assets
  Dockerfile               # Archlinux-based container
  pyproject.toml           # Python dependencies (uv)

cytoscape/                 # Graph visualization
  src/                     # JS source (index.mjs, cytoscape-cola.mjs, defaults.mjs)
  webpack.config.mjs
  package.json             # webcola dependency, webpack build

docker-compose.yaml        # Django + Grafana services
grafana/                   # Grafana data (SQLite datasource on Django DB)
```

## Building and running

### OCaml engine

Requires opam. The engine uses `effect` as a type name and `String.uppercase`, so it needs **OCaml 4.14** (not 5.x).

```bash
cd engine
opam switch create . ocaml-base-compiler.4.14.2 --yes
eval $(opam env)
opam install dune containers ppx_subliner zarith ppx_deriving_yojson alcotest base --yes
opam pin add pringo git+https://github.com/sapristi/pringo.git --yes
dune build          # Build the yaac binary
dune runtest        # Run alcotest tests
```

The binary is built at `engine/_build/default/bin/yaac.exe`. Key CLI subcommands:

- `from-mol` — Parse molecule string, return protein + Petri net JSON
- `from-prot` — Build Petri net from protein JSON
- `eval` — Run N reaction steps from an initial state
- `load-signature` — Expand a compact bacterie signature to full state
- `reactions` — List available reactions from a state
- `acid-examples` — List example acid types

Use `--log-level` (`-l`) to control logging. Set `JSON_LOG=1` env var for JSON log output.

### Django app

Requires Python >= 3.10. Uses uv for dependency management.

```bash
cd django
uv sync                                            # Install dependencies
uv run ./manage.py migrate                         # Create/update database
ln -sf ../engine/_build/default/bin/yaac.exe yaac  # Symlink engine binary
uv run ./cli.py load-initial-states                # Load fixtures from engine test data
uv run ./manage.py runserver                       # Start dev server (default: localhost:8000)
```

The Typer CLI for experiment management:

```bash
cd django
uv run ./cli.py experiment list                           # List experiments
uv run ./cli.py experiment run <id> <nb_reacs>            # Run experiment
uv run ./cli.py experiment run <id> <nb_reacs> --reset    # Run from initial state
uv run ./cli.py experiment clear <id>                     # Remove snapshots
uv run ./cli.py load-initial-states                       # Load fixtures from engine test data
```

**Important:** The `yaac` binary must be accessible at `./yaac` from the Django working directory (the symlink step above handles this).

### Docker (full stack)

```bash
docker-compose up       # Starts Django (port 8000) and Grafana (port 3000)
```

### Cytoscape visualization

```bash
cd cytoscape
pnpm install
pnpm build              # Webpack bundle
```

## OCaml conventions

- **PPX**: `ppx_deriving_yojson` for JSON serialization, `ppx_subliner` for CLI argument parsing from type definitions
- **Key dependencies**: `containers` (stdlib extension), `zarith` (arbitrary precision), `pringo` (PRNG), `alcotest` (testing)
- **Module layout**: `base_chemistry` defines core domain types (molecules, proteins, Petri nets); `bacterie` implements runtime simulation; `libs` has general utilities; `jlog` is a custom structured logging library
- **CLI pattern**: Subcommands are defined as modules with a `params` type (derived with `subliner`), a `doc` string, and a `handle` function

## Django conventions

- **Models** (`experiment/models.py`): `Experiment` holds initial state as JSON; `BactSnapshot` stores simulation state at checkpoints; `Log` stores per-step statistics; `InitialState` stores reusable starting configurations
- **Engine integration** (`experiment/engine.py`): `YaacWrapper` class invokes the OCaml binary, `StatLogCollector` captures structured log output during runs
- **API**: Django REST Framework viewsets for experiments and snapshots
- **CLI**: Typer app in `cli.py` with subcommands in `subcommansds/`

## Maintaining this file

Always keep `CLAUDE.md` up to date when making changes that affect project structure, build instructions, conventions, or workflow. Ask the user before adding new sections. This file is a symlink — that's expected, edit it normally.

## Development workflow

1. **Engine changes**: Edit OCaml code in `engine/`, build with `dune build`, test with `dune runtest`
2. **Django changes**: Edit Python code in `django/`, restart dev server. Use `./cli.py` for experiment operations
3. **Visualization**: Edit JS in `cytoscape/src/`, rebuild with `pnpm build`
4. **Full integration**: Ensure the `yaac` binary is built and accessible from the Django working directory, then run the Django server
