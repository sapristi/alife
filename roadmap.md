# Roadmap

The path from here to the goal. Non-linear — milestones get revised, reordered, and added as you learn.

## Active Milestone

### Copy_grabbed completion and ambient consumption
- **Objective**: Copy_grabbed copiers that consume ambient atoms during replication, making mutation an emergent property of environmental chemistry rather than a separate break parameter.
- **Open questions**:
  - Should copy rate scale linearly with ambient concentration or use saturation (Michaelis-Menten)?
  - Should wrong-atom grabs be stochastic (weighted by concentrations) or deterministic (most abundant)?
  - How does ambient consumption interact with the current ambient no-depletion semantics?
  - Should copy_grabbed handle end-of-molecule detection or keep separate filter_empty arc?
- **Approach**: Implement acid concentration index in reac_mgr, add CopyGrabbed as new reaction pool (option a from future-work.md), build firing logic that reads cursor acid and draws from ambient pool. Test with existing copier experiments to validate.

## Upcoming
- [ ] Emergent mutation experiments — run copy_grabbed copiers with ambient consumption, measure whether mutation rates emerge naturally from environmental atom concentrations
- [ ] Variable grab patterns — mutations to grab pattern region creating copiers with different template affinities, enabling niche differentiation
- [ ] Membranes — bind extensions linking Petri nets, establishing barriers that regulate molecule entry/exit
- [ ] Energy model — tokens mediating energy exchanges, bond formation/breaking costs, enabling selection pressure beyond replication speed
- [ ] Spatial structure — moving beyond single-reactor to neighbor interaction, enabling geographic isolation and multicellular behavior

## Completed
- 2026-03-08: Self-sustaining replication (copier v2) — T-copier + inert DEEE templates. First system that doesn't die.
- 2026-03-08: Full self-replication (copier v4) — Both T-copier and R-copier replicate via inert DAEEE templates. Templates are the bottleneck.
- 2026-03-08: Darwinian evolution confirmed (copier v5, exp 71) — Mutant templates + matching mutant copiers. Parasitic truncated copiers emerge. break=1e-4 optimal.
- 2026-03-09: Parameter landscape mapped — Break exponent, collision rate, grab rate sweeps. Uniform break pressure (exp=0) and moderate collision (2e-5) are sweet spots.
- 2026-04-06: Copy_grabbed reaction type added to engine — CopyGrabbed reaction, copy_grabbed_ext place extension, copy_done_iarc. Builder in django/build_copier.py.
