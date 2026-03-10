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
