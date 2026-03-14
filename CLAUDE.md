# Instructions

Always read README.md at the start of each conversation.

## Persistent memory

Instead of using the auto-memory directory (`~/.claude/projects/.../memory/`), store all persistent notes and learnings directly in this file. Edit this file to add, update, or remove memories.

## Commits

Commit code when done with a set of changes. First line format: `<scope>: <description>`.

Scopes: `engine` (OCaml), `django` (Python/CLI), `front` (cytoscape/JS), `docs`, or omit for cross-cutting changes.

Examples: `engine: stop eval loop when no reactions available`, `django: add experiment CLI commands`, `docs: add ribosome experiment report`.

# Project Knowledge

## Engine gotchas
- **Grabbed molecule is REMOVED** from environment; its Petri net state + internal tokens destroyed permanently
- **Ambient molecules** never deplete (`add_to_qtt` is no-op for ambient=true)
- **Copy_iarc** materializes an atom from nothing: reads acid at cursor → produces [original, acid_token(1, acid_char)]
- **Merge** (`insert(src, dest)`): when both cursors=0, prepends source to dest
- **EEE (Stop_interpretation)**: rest of molecule ignored → inert (no Petri net)
- **Token flow**: output arcs consume tokens in molecule-order; if list runs out, remaining arcs get nothing (`| _ -> []`)
- **No_token_iarc** produces 0 tokens (just checks place is empty)
- **`launchables_nb=0`** → transition rate=0, but grabs still work; after grab, `update_launchables` runs and can enable transitions
- **`@filepath` convention**: engine reads from file when arg starts with `@`; Django `YaacWrapper` auto-writes temp files for args > 100KB

## Copier design notes
- **Arc ordering**: `proteine.ml` prepends arcs, reversing order. Accumulator BEFORE read head gives [original, acid_token, accumulator] for merge.
- **One-shot gate pattern**: Place with ext_init_token consumed by first transition, refilled by T_DONE via factory split. Prevents Gillespie race conditions.
- Builders: `build_simple_copier()` and `build_simple_r_copier()` in `django/build_copier.py`

## Copy_grabbed design notes
- **Copy_grabbed_ext** place extension: stores mutable `copy_buffer`, incremented by CopyGrabbed reactions
- **CopyGrabbed reaction**: reads acid at cursor, appends to buffer, advances cursor in-place (no token pop/push)
- **Copy_done_iarc**: fires when cursor past end + buffer non-empty, produces [template, copy_buffer] tokens
- **Rate**: `copy_grabbed_ready_nb` (count of places with ext + token + cursor not past end) × `copy_grabbed_rate`
- Builders: `build_copy_grabbed_copier()` in `django/build_copier.py`
- Molecule encoding: `ABD` = Copy_grabbed_ext (no params), `BAE<tid>DDF` = Copy_done_iarc

## Known issues
- "Ignoring add of bad molecule" warnings: empty strings from break reactions (harmless)
- `yaac` binary in `django/` is a copy (not symlink), must be manually updated after engine rebuild
