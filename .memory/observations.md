# Observations
<!-- Append-only. Format: - YYYY-MM-DD [tags]: observation -->
<!-- Tags: progress, blocker, insight, decision, meta -->

- 2026-03-10 [decision]: Chose to replace Copy_iarc with copy_grabbed entirely (not incremental). Atomic design: single transition per acid copied.
- 2026-03-11 [insight]: Point mutations should emerge from concentration-weighted ambient atom selection during copying, not from parametric break rates. Physical coherence: copying should consume atoms, not materialize them.
- 2026-03-11 [decision]: Persistent project knowledge lives in CLAUDE.md, not auto-memory directory. Documentation split: CLAUDE.md (dev knowledge), README (users), future-work.md (ideas), design-history (philosophy).
- 2026-03-14 [progress]: copy_grabbed reaction type implemented in engine. Core types, parser (ABD/BAE encoding), place extensions (copy_buffer, cursor tracking), transition logic, environment integration all done.
- 2026-04-06 [meta]: First cog-focus reflect. Memory files bootstrapped from session mining. ~3 week gap between copy_grabbed implementation and today — no sessions in between.
