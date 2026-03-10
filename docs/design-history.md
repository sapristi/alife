# Design History

Origins, motivations, and prior art for the YAACS project.

## Motivation

Create a program that realizes the dream of artificial life: host and simulate cells that evolve, recreating life *in silico*.

## Prior art

### Tierra

- World is a 1D array. Each cell is either empty or contains an instruction from a carefully chosen instruction set.
- Cells are contiguous instruction sequences. They can read anywhere but cannot write inside other cells. Replication works by copying genetic code to an empty region.
- Each cell has its own processor simulating code execution.
- **Observed behaviors:** specialization, parasitism, some complexification.

### Hutton's systems

- World is a 2D array containing atoms that move more or less freely.
- Atoms have a fixed type and a mutable state. A carefully chosen set of chemical reactions determines whether two atoms of given type/state form a bond when they meet.
- Cells have a circular membrane and a DNA strand connected at both ends to the membrane. Replication happens spontaneously via chemical reactions.
- Simulation is fully physical: each atom individually, nothing else.
- **Observed behaviors:** not much beyond slight DNA reduction.

### Lessons learned

Tierra is promising but closer to a computer than a cell — lacks reaction capability, communication, etc. Hutton is very close to biology but doesn't work well, has enormous simulation costs, and requires an overly contrived reaction set.

## Design approach

The goal: a model that is both close to how computers work (simple physics, no low-level simulation needed) and reflects how a cell functions as much as desirable and possible.

First idea was Tierra-like but in more dimensions (cells as matrices, instructions pointing to next). In 3D this gets interesting but duplication becomes complex and the cell-universe relationship breaks down.

Second idea: use simple computational models to simulate proteins. Starting from automata, arrived at **Petri nets**, which seemed promising enough to pursue.

### Why Petri nets

- Petri nets are built non-linearly from acid lists — should be robust to minor acid modifications.
- Graph structure gives spatial meaning: a membrane-connected protein can have parts inside and outside.
- Easy to connect Petri nets together (bind/catch) — enables membranes and extended functionality.

### Molecule shape

Linear molecules (atom lists parsed into acids) were chosen as the simplest model. Graph-shaped molecules with 2-3 branch connectors would be richer but harder to manipulate.
