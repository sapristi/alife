# Short & Mid-term Achievements

Possible wins that serve the goal but aren't on the current roadmap. Identified 2026-04-06.

## Short-term (no/minimal engine changes)

### 1. Ambient DAEEE templates (experiment only)
Add DAEEE as an ambient molecule in an experiment config — collisions with active molecules would naturally produce templates. Zero code changes, could run today. Tests whether template creation can become an emergent process instead of requiring hand-seeded templates.

### 2. Break product analysis for copy_grabbed copiers
Hand-design a few ~50-80 char copy_grabbed copiers and systematically catalog their break products. Use `from-mol` to parse truncated variants and check which ones fold into functional Petri nets. Validates or falsifies the smooth fitness landscape hypothesis before investing in the full ambient consumption pipeline.

### 3. Lineage/phylogenetic tracking
Add automated lineage tracking (parent → child via template identity) to the Django stats pipeline. Measures:
- Mutation rates per lineage
- Generation depth (how many rounds of replication)
- Which mutations are neutral vs. lethal
- Extinction/survival curves per lineage

Pure analytics — doesn't touch the engine, just enriches snapshot post-processing. Pays dividends for every future experiment.

### 4. Template recycling / release mechanism
Templates are the bottleneck (all "in use" in v4 experiments). A release_ext on the copy_grabbed place (or a new transition that fires after copy_done) would free templates for re-grabbing. Small engine change, big impact on population dynamics.

## Mid-term (moderate engine work, parallel to ambient consumption)

### 5. Slow-replenishing ambient pools
Add a replenishment mechanism to ambient molecules: each ambient species gets a `replenish_rate` and `target_qtt`, and quantity drifts back toward the target over time. This is an *additional* mechanism on top of the existing ambient semantics (infinite pools remain available). When enabled, it creates an open system (chemostat-like): resources flow in continuously but can be depleted faster than they replenish. Effects:
- Genuine resource scarcity → selection pressure → evolution favors efficient copiers
- Boom-bust dynamics: fast replicators crash their own food supply, then recover
- Different replenishment rates per acid create relative scarcity, biasing which mutations are common
- Mutation rate becomes emergent: when preferred acids are scarce, wrong-atom grabs increase

Implementable as a new Gillespie reaction pool (one replenishment "reaction" per ambient species) without changing existing ambient behavior.

### 6. Multi-reactor / dilution protocol
A "serial transfer" experiment: every N reactions, randomly remove X% of molecules and add fresh ambient. Artificial chemistry analog of serial passage in microbiology. Creates bottleneck events that amplify drift and selection. Implementable as a Django-level wrapper around `experiment run`, no engine changes needed.

### 7. Collision-as-recombination
Add a crossover-style collision that swaps segments between two molecules instead of merging. Current collisions are purely destructive and never produce Darwinian pairs (only breaks do). A recombination reaction could dramatically increase the rate of viable novel genotypes.

### 8. Engine profiling for 1M+ runs
The goal mentions 1M+ reaction ecosystems. Current experiments top out at 400k. Profiling the engine (especially `reac_mgr` rate recomputation and the Gillespie loop) with OCaml `landmarks` or `perf` tracing could reveal optimization opportunities. Even 2-3x speedup enables much longer evolutionary timescales.

## Impact vs. effort matrix

| Achievement | Effort | Impact on goal | Prerequisite? |
|---|---|---|---|
| Ambient DAEEE experiment | Trivial | Medium — tests emergent template creation | No |
| Break product analysis | Low | High — validates core hypothesis | No |
| Lineage tracking | Medium | High — transforms experimental insight | No |
| Template recycling | Low-Medium | High — removes population bottleneck | No |
| Slow-replenishing ambient pools | Medium | High — creates selection pressure | Partially overlaps active milestone |
| Serial transfer protocol | Low | Medium — easy evolution accelerator | No |
| Crossover collisions | Medium-High | Potentially very high | No |
| Engine profiling | Low | Medium — enables longer runs | No |

Items 1-3 can be done right now without waiting for copy_grabbed ambient consumption, and directly inform the active milestone's design decisions (rate model, mutation semantics).
