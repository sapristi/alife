# Future Work

Ideas, remarks, and open questions to address in future development.

## Copy_iarc should consume ambient atoms

Copy_iarc currently materializes new acid tokens from nothing (`Token.make acid_char 1`). This is physically incoherent — the copier creates matter without consuming any resource.

**Fix:** Copy_iarc should consume an atom from the ambient pool to produce the copied token. The transition's firing rate should depend on the concentration of the target atom in the environment. If the copier needs to copy an "A", the rate depends on how much ambient "A" is available.

**Point mutations as emergent consequence:** If the copy mechanism draws from the ambient pool weighted by concentration, a copier needing a rare atom will sometimes grab a different, more abundant atom instead. Mutation rate becomes an emergent property of environmental chemistry rather than a separate parameter.

### Open questions

- Should the copy transition rate scale with target atom concentration directly, or use a Michaelis-Menten-like saturation model?
- Should a failed copy (wrong atom grabbed) be deterministic (most abundant substitute) or stochastic (weighted by all concentrations)?
- How does this interact with the current ambient `add_to_qtt` no-op? Ambient atoms don't deplete — should copying consume them, or should ambient remain infinite?

## Membranes

A membrane establishes a barrier with the outside world. Desired properties:

- Regulate molecule entry/exit
- Difficult barrier for unwanted external molecules
- Size requirements proportional to internal molecule count (overfill → damage)

**Implementation idea:** two anchor points connected by a chain of proteins via Bind extensions. Bind extension pairs (symmetric strings) link two Petri nets; binding creates tokens in both places, unbinding when both receive tokens again.

### Bind extension design choices

- Strong bind: Petri nets fuse at bind place (complex state management)
- Weak bind: Petri nets remain independent (simpler, sufficient for membranes)
- Either way, need a supergraph tracking the extended Petri net structure (distances, cycles)

## Energy model

Tokens could mediate energy exchanges. Forming a bond costs energy, breaking it releases energy — mirroring real chemistry. This implies modifying grab/bind conditions to account for energy availability. Could also enable energy transfer between a protein and a grabbed molecule.

## World / spatial structure

Ideas for scaling beyond a single reactor:

- Unrestricted duplication: each new bacterium gets a resource distribution
- 3D matrix with commands for neighbor interaction, movement, communication
- Hosts for multicellular behavior: host has receptor slots, cells plug in to act in a physical world
- Lazy graph where nodes contain membrane interfaces of varying permeability

## `copy_grabbed` extension (from next-steps-evolution.md)

A place extension that atomically performs: read acid at cursor → grab matching acid from ambient → merge into accumulator → advance cursor. One transition step per acid copied. Would shrink copiers from ~137-331 chars to ~50-80, flattening the fitness landscape.

See `docs/next-steps-evolution.md` for full design and rationale.

## Variable grab patterns

Mutations to the grab pattern region could create copiers with different template affinities → niche differentiation → selection pressure.

## Ambient DAEEE molecules

Add DAEEE as ambient; collisions naturally create templates from active molecules. Simple, no code changes, but probabilistic.
