# Patterns
<!-- Edit in place. Distilled rules from experience. Keep under 50 lines. -->
<!-- What works, what doesn't, how to approach things. -->

- New reaction types follow existing module patterns (e.g., CopyGrabbed modeled after Grab). Architectural consistency reduces implementation risk.
- Experiment-driven development: parameter sweeps reveal system dynamics before committing to code changes. Map the landscape, then build.
- Copier fitness landscape is sharp: small mutations destroy function. Shorter copiers (copy_grabbed ~50-80 chars) flatten the landscape and enable evolution.
- Darwinian pairs only emerge from break truncations so far, not collisions. Collisions are far more destructive than breaks.
- Physical coherence matters: mechanisms that create matter from nothing (Copy_iarc) produce results but undermine emergent dynamics.
- Documentation consolidation prevents knowledge fragmentation. Single source of truth per audience (CLAUDE.md for dev, README for users).
