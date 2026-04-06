# Goal

## What
Build an artificial chemistry simulator that produces open-ended Darwinian evolution — self-replicating molecules that mutate, compete, and diversify without external intervention.

## Why
Understanding how evolution can emerge from chemistry is a fundamental question. Success means a system where molecular diversity, competition, and adaptation arise from simple local rules — not hand-tuned parameters. This would demonstrate that Darwinian evolution is a natural consequence of self-replication + variation + selection pressure, even in a minimal artificial chemistry.

## Success Looks Like
- Emergent mutation rates driven by environmental chemistry (not parametric break rates)
- Stable, self-sustaining ecosystems lasting 1M+ reactions with ongoing diversification
- Compact, evolvable copiers (copy_grabbed ~50-80 chars vs current ~137-331)
- Niche differentiation: copiers with different template affinities coexisting
- Spatial structure or membranes enabling higher-order organization (multicellularity)

## Constraints
- Single developer, research/hobby project
- Engine must remain performant (Gillespie algorithm, OCaml)
- Not building a general-purpose ALife framework — focused on this specific chemistry
