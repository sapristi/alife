#!/usr/bin/env python3
"""Build self-replicating copier molecules for YAACS.

Full system: 4 molecule types that collectively self-replicate.

1. T-copier (no prefix): grabs DAEEE-prefixed templates, copies exactly → new inert templates
2. R-copier (no prefix): grabs DAEEE-prefixed templates, skips DAEEE prefix, copies rest → new copiers
3. Template_T = DAEEE + T-copier_mol (INERT: EEE = stop_interpretation)
4. Template_R = DAEEE + R-copier_mol (INERT)

Templates are inert (no Petri net) so they don't compete for reactions.
Copiers (no D prefix) are invisible to grab pattern ^(D)A.*?$, preventing mutual grabbing.
Grab pattern requires "DA" start, excluding bare ambient "D" molecules.

R-copier skips DAEEE (5 chars) using a trigger chain: T_SKIP1→T_SKIP5 fire
sequentially before T_RESET fills the accumulator. Each T_SKIP advances the
read cursor past one prefix character. The No_token guard on P8 prevents
T_SKIP1 from firing during the copy phase.
"""

import subprocess
import json
import sys

TEMPLATE_PREFIX = "DAEEE"

# Acid encoding functions (from molecule.ml)
def place(): return "AAA"
def ia_reg(tid): return f"BAA{tid}DDF"
def ia_split(tid): return f"BBA{tid}DDF"
def ia_filter(acid, tid): return f"BC{acid}{tid}DDF"
def ia_filter_empty(tid): return f"BAB{tid}DDF"
def ia_no_token(tid): return f"BAC{tid}DDF"
def oa_reg(tid): return f"CAA{tid}DDF"
def oa_merge(tid): return f"CBA{tid}DDF"
def oa_move_fw(tid): return f"CCA{tid}DDF"
def ext_grab(pattern): return f"ABA{pattern}DDF"
def ia_copy(tid): return f"BAD{tid}DDF"
def ext_release(): return "ABB"
def ext_init_token(): return "ABC"
def ext_copy_grabbed(): return "ABD"
def ia_copy_done(tid): return f"BAE{tid}DDF"


def build_simple_copier(grab_pattern="FDFAFF"):
    """Build simplified copier using Copy_iarc extension.

    Uses the new Copy_iarc input arc that reads one acid at the cursor,
    produces a single-acid token, and lets the transition merge it into
    the accumulator. Replaces 6 per-acid transitions + 6 grab places
    with a single T_COPY transition.

    Transitions: T_LOAD, T_COPY, T_DONE, T_RESET (4 total)
    Places: P0(token factory), P1(grab), P2(read head),
            P3(accumulator), P4(copy release), P5(template release) (6 total)

    Token factory is placed FIRST so breaks at the end (losing release
    places) still preserve the copy core.
    """
    T_LOAD  = "A"
    T_COPY  = "B"
    T_DONE  = "C"
    T_RESET = "D"

    parts = []

    # P0: Token factory (first, so it survives most breaks)
    parts.append(place())
    parts.append(ext_init_token())
    parts.append(ia_split(T_RESET))
    parts.append(oa_reg(T_RESET))

    # P1: Template grab
    parts.append(place())
    parts.append(ext_grab(grab_pattern))      # default: ^(D)A.*?$
    parts.append(ia_reg(T_LOAD))

    # P2: Accumulator — BEFORE read head so arc ordering produces correct
    #     token list: [original, acid_token, accumulator] for merge
    #     (proteine builder prepends arcs, reversing molecule order)
    parts.append(place())
    parts.append(ia_no_token(T_RESET))        # T_RESET only when accumulator empty
    parts.append(ia_reg(T_COPY))              # consumed by T_COPY for merge
    parts.append(oa_merge(T_COPY))            # merge acid into accumulator
    parts.append(ia_reg(T_DONE))              # consumed by T_DONE for release
    parts.append(oa_reg(T_RESET))             # receives empty token from T_RESET

    # P3: Read head — uses Copy_iarc for universal acid copying
    parts.append(place())
    parts.append(ia_copy(T_COPY))             # reads acid, produces [original, acid_token]
    parts.append(ia_filter_empty(T_DONE))     # fires T_DONE when cursor past end
    parts.append(oa_move_fw(T_COPY))          # advances cursor after copy
    parts.append(oa_reg(T_LOAD))              # receives token from T_LOAD

    # P4: Copy release
    parts.append(place())
    parts.append(ext_release())
    parts.append(oa_reg(T_DONE))

    # P5: Template release
    parts.append(place())
    parts.append(ext_release())
    parts.append(oa_reg(T_DONE))

    return "".join(parts)


def build_simple_r_copier(grab_pattern="FDFAFF"):
    """Build simplified R-copier using Copy_iarc extension.

    Like build_simple_copier but skips the DAEEE prefix (5 chars) before
    copying. Uses Copy_iarc for both skip and copy transitions — each
    skip produces [original, acid_token], where original goes to move_fw
    and acid_token goes to the trigger chain.

    The released copy is the template body WITHOUT DAEEE — an active copier.

    One-shot gate (P9): T_SKIP1 consumes the gate token, ensuring it fires
    exactly once per cycle. Without this gate, T_SKIP1 would race with
    T_SKIP3/T_SKIP4/etc after T_SKIP2 empties P2, causing duplicate trigger
    chain entries and corrupted copies. The gate is refilled by T_DONE via
    factory split.

    Molecule layout determines arc ordering after proteine.ml's prepend
    reversal. Key constraints:
    - Trigger places (P2-P6) BEFORE read head (P10) for skip output ordering
    - Copy/template release (P7,P8) BEFORE gate (P9) BEFORE read head (P10)
      for T_DONE output ordering: [factory, gate, tmpl_release, copy_release]
    - Factory (P11) AFTER read head for T_DONE/T_RESET input ordering

    Transitions: T_LOAD, T_COPY, T_DONE, T_RESET, T_SKIP1-5 (9 total)
    Places: P0(grab), P1(accumulator), P2-P6(trigger chain),
            P7(copy release), P8(template release), P9(gate),
            P10(read head), P11(factory) (12 total)
    """
    T_LOAD  = "A"
    T_COPY  = "B"
    T_DONE  = "C"
    T_RESET = "D"
    T_SKIP1 = "E"   # Skip position 0
    T_SKIP2 = "F"   # Skip position 1
    T_SKIP3 = "AB"  # Skip position 2
    T_SKIP4 = "AC"  # Skip position 3
    T_SKIP5 = "AD"  # Skip position 4

    parts = []

    # P0: Template grab
    parts.append(place())
    parts.append(ext_grab(grab_pattern))  # default: ^(D)A.*?$
    parts.append(ia_reg(T_LOAD))

    # P1: Accumulator (empty during skip phase, filled by T_RESET)
    parts.append(place())
    parts.append(ia_reg(T_COPY))          # consumed by T_COPY for merge
    parts.append(oa_merge(T_COPY))        # merge acid into accumulator
    parts.append(ia_reg(T_DONE))          # consumed by T_DONE for release
    parts.append(oa_reg(T_RESET))         # receives empty token from T_RESET

    # P2-P6: Trigger chain for 5-char prefix skip
    # T_SKIP1 → P2 → T_SKIP2 → P3 → ... → P6 → T_RESET
    # MUST come before P10 (read head) for correct output arc ordering.

    # P2: trigger1 (filled by T_SKIP1, consumed by T_SKIP2)
    parts.append(place())
    parts.append(oa_reg(T_SKIP1))
    parts.append(ia_reg(T_SKIP2))

    # P3: trigger2 (filled by T_SKIP2, consumed by T_SKIP3)
    parts.append(place())
    parts.append(oa_reg(T_SKIP2))
    parts.append(ia_reg(T_SKIP3))

    # P4: trigger3 (filled by T_SKIP3, consumed by T_SKIP4)
    parts.append(place())
    parts.append(oa_reg(T_SKIP3))
    parts.append(ia_reg(T_SKIP4))

    # P5: trigger4 (filled by T_SKIP4, consumed by T_SKIP5)
    parts.append(place())
    parts.append(oa_reg(T_SKIP4))
    parts.append(ia_reg(T_SKIP5))

    # P6: trigger5 (filled by T_SKIP5, consumed by T_RESET)
    parts.append(place())
    parts.append(oa_reg(T_SKIP5))
    parts.append(ia_reg(T_RESET))

    # P7: Copy release — BEFORE gate for T_DONE output ordering
    parts.append(place())
    parts.append(ext_release())
    parts.append(oa_reg(T_DONE))

    # P8: Template release — BEFORE gate for T_DONE output ordering
    parts.append(place())
    parts.append(ext_release())
    parts.append(oa_reg(T_DONE))

    # P9: One-shot gate — consumed by T_SKIP1, refilled by T_DONE
    # Ensures T_SKIP1 fires exactly once per copy cycle.
    parts.append(place())
    parts.append(ext_init_token())
    parts.append(ia_reg(T_SKIP1))         # consumed by T_SKIP1 (one-shot)
    parts.append(oa_reg(T_DONE))          # refilled by T_DONE via factory split

    # P10: Read head — AFTER gate/triggers for correct arc ordering
    parts.append(place())
    # Skip arcs: Copy_iarc advances cursor, acid_token goes to trigger
    parts.append(ia_copy(T_SKIP1))
    parts.append(oa_move_fw(T_SKIP1))
    parts.append(ia_copy(T_SKIP2))
    parts.append(oa_move_fw(T_SKIP2))
    parts.append(ia_copy(T_SKIP3))
    parts.append(oa_move_fw(T_SKIP3))
    parts.append(ia_copy(T_SKIP4))
    parts.append(oa_move_fw(T_SKIP4))
    parts.append(ia_copy(T_SKIP5))
    parts.append(oa_move_fw(T_SKIP5))
    # Copy arcs
    parts.append(ia_copy(T_COPY))
    parts.append(ia_filter_empty(T_DONE))
    parts.append(oa_move_fw(T_COPY))
    parts.append(oa_reg(T_LOAD))          # receives token from T_LOAD

    # P11: Token factory — LAST for T_RESET/T_DONE input ordering
    # Split produces 2 empty tokens: one refills factory, other goes to
    # accumulator (T_RESET) or gate+factory (T_DONE).
    parts.append(place())
    parts.append(ext_init_token())
    parts.append(ia_split(T_RESET))       # T_RESET: empty token for accumulator
    parts.append(oa_reg(T_RESET))         # T_RESET: refill factory
    parts.append(ia_split(T_DONE))        # T_DONE: tokens for gate + factory refill
    parts.append(oa_reg(T_DONE))          # T_DONE: refill factory

    return "".join(parts)


def build_copy_grabbed_copier(grab_pattern="FDFAFF"):
    """Build copier using copy_grabbed extension.

    The copy_grabbed place atomically reads acid at cursor, appends to
    internal buffer, and advances cursor. One CopyGrabbed reaction per
    acid copied. Copy_done_iarc extracts the buffer when cursor past end.

    Transitions: T_LOAD, T_DONE (2 total)
    Places: P0(grab), P1(copy_grabbed read head), P2(copy release),
            P3(template release) (4 total)
    """
    T_LOAD = "A"
    T_DONE = "B"

    parts = []

    # P0: Template grab
    parts.append(place())
    parts.append(ext_grab(grab_pattern))
    parts.append(ia_reg(T_LOAD))

    # P1: Copy_grabbed read head
    # ia_copy_done produces [template, copy] in token list
    # After proteine.ml prepend, output arcs are [(P3, reg), (P2, reg)]
    # So P3 gets template, P2 gets copy
    parts.append(place())
    parts.append(ext_copy_grabbed())
    parts.append(ia_copy_done(T_DONE))
    parts.append(oa_reg(T_LOAD))

    # P2: Copy release
    parts.append(place())
    parts.append(ext_release())
    parts.append(oa_reg(T_DONE))

    # P3: Template release
    parts.append(place())
    parts.append(ext_release())
    parts.append(oa_reg(T_DONE))

    return "".join(parts)


def build_copy_grabbed_initial_state(copier_mol, grab_pattern="FDFAFF",
                                     copier_qtt=5, template_qtt=10,
                                     acid_qtt=200, d_qtt=50, e_qtt=200):
    """Build initial state for copy_grabbed copier system."""
    template = TEMPLATE_PREFIX + copier_mol

    return {
        "mols": [
            {"mol": copier_mol, "qtt": copier_qtt},
            {"mol": template, "qtt": template_qtt},
            {"mol": "A", "qtt": acid_qtt, "ambient": True},
            {"mol": "B", "qtt": acid_qtt, "ambient": True},
            {"mol": "C", "qtt": acid_qtt, "ambient": True},
            {"mol": "D", "qtt": d_qtt, "ambient": True},
            {"mol": "E", "qtt": e_qtt, "ambient": True},
            {"mol": "F", "qtt": acid_qtt, "ambient": True},
        ],
        "env": {
            "transition_rate": 100,
            "grab_rate": 1,
            "break_rate": 0,
            "collision_rate": 0,
            "copy_grabbed_rate": 100,
        }
    }


def build_simple_4comp_state(t_copier_mol, r_copier_mol,
                             copier_qtt=5, template_qtt=10,
                             acid_qtt=200, d_qtt=50, e_qtt=200):
    """Build initial state with 4-component system using Copy_iarc copiers.

    T-copier copies templates exactly (including DAEEE) → new templates.
    R-copier copies templates, skipping DAEEE → new active copiers.
    """
    template_t = TEMPLATE_PREFIX + t_copier_mol
    template_r = TEMPLATE_PREFIX + r_copier_mol

    return {
        "mols": [
            {"mol": t_copier_mol, "qtt": copier_qtt},
            {"mol": r_copier_mol, "qtt": copier_qtt},
            {"mol": template_t, "qtt": template_qtt},
            {"mol": template_r, "qtt": template_qtt},
            {"mol": "A", "qtt": acid_qtt, "ambient": True},
            {"mol": "B", "qtt": acid_qtt, "ambient": True},
            {"mol": "C", "qtt": acid_qtt, "ambient": True},
            {"mol": "D", "qtt": d_qtt, "ambient": True},
            {"mol": "E", "qtt": e_qtt, "ambient": True},
            {"mol": "F", "qtt": acid_qtt, "ambient": True},
        ],
        "env": {
            "transition_rate": 100,
            "grab_rate": 1,
            "break_rate": 0,
            "collision_rate": 0,
        }
    }


def build_simple_initial_state(copier_mol, grab_pattern="FDFAFF",
                               copier_qtt=10, template_qtt=20,
                               acid_qtt=200, d_qtt=50, e_qtt=200):
    """Build initial state for simplified copier system.

    Only T-copier (exact copy). Templates are DAEEE + copier.
    The copier copies templates exactly, producing new templates.
    """
    template = TEMPLATE_PREFIX + copier_mol

    return {
        "mols": [
            {"mol": copier_mol, "qtt": copier_qtt},
            {"mol": template, "qtt": template_qtt},
            {"mol": "A", "qtt": acid_qtt, "ambient": True},
            {"mol": "B", "qtt": acid_qtt, "ambient": True},
            {"mol": "C", "qtt": acid_qtt, "ambient": True},
            {"mol": "D", "qtt": d_qtt, "ambient": True},
            {"mol": "E", "qtt": e_qtt, "ambient": True},
            {"mol": "F", "qtt": acid_qtt, "ambient": True},
        ],
        "env": {
            "transition_rate": 100,
            "grab_rate": 1,
            "break_rate": 0,
            "collision_rate": 0,
        }
    }


def build_t_copier():
    """Build T-copier: copies templates exactly (including DAEEE prefix).

    Transitions: T_LOAD, T_COPYA-F/E, T_DONE, T_RESET
    Places: P0(grab), P1(read), P2-P7(acid grabs A/B/C/D/F/E),
            P8(accumulator), P9(copy release), P10(template release),
            P11(token factory)
    """
    T_LOAD  = "A"
    T_COPYA = "B"
    T_COPYB = "C"
    T_COPYC = "D"
    T_COPYD = "F"
    T_COPYF = "AB"
    T_COPYE = "AF"
    T_DONE  = "AC"
    T_RESET = "AD"

    parts = []

    # P0: Template grab
    parts.append(place())
    parts.append(ext_grab("FDFAFF"))      # ^(D)A.*?$ — requires DA prefix
    parts.append(ia_reg(T_LOAD))

    # P1: Read head
    parts.append(place())
    for acid, tid in [("A", T_COPYA), ("B", T_COPYB), ("C", T_COPYC),
                      ("D", T_COPYD), ("F", T_COPYF), ("E", T_COPYE)]:
        parts.append(ia_filter(acid, tid))
        parts.append(oa_move_fw(tid))
    parts.append(ia_filter_empty(T_DONE))
    parts.append(oa_reg(T_LOAD))

    # P2-P7: Acid grab places
    for acid, tid, pattern in [("A", T_COPYA, "FAF"), ("B", T_COPYB, "FBF"),
                                ("C", T_COPYC, "FCF"), ("D", T_COPYD, "FDF"),
                                ("F", T_COPYF, "FFF"), ("E", T_COPYE, "FEF")]:
        parts.append(place())
        parts.append(ext_grab(pattern))
        parts.append(ia_reg(tid))

    # P8: Accumulator
    parts.append(place())
    for tid in [T_COPYA, T_COPYB, T_COPYC, T_COPYD, T_COPYF, T_COPYE]:
        parts.append(ia_reg(tid))
        parts.append(oa_merge(tid))
    parts.append(ia_reg(T_DONE))
    parts.append(oa_reg(T_RESET))

    # P9: Copy release
    parts.append(place())
    parts.append(ext_release())
    parts.append(oa_reg(T_DONE))

    # P10: Template release
    parts.append(place())
    parts.append(ext_release())
    parts.append(oa_reg(T_DONE))

    # P11: Token factory
    parts.append(place())
    parts.append(ext_init_token())
    parts.append(ia_split(T_RESET))
    parts.append(oa_reg(T_RESET))

    return "".join(parts)


def build_r_copier():
    """Build R-copier: copies templates with DAEEE prefix skipped.

    Skips 5-char prefix using a trigger chain (T_SKIP1→T_SKIP5).
    T_SKIP1 has No_token guard on P8 (skip phase only) and borrows
    a token from P11 (split) to provide both move_fw on P1 and
    trigger on P12.
    T_SKIP2-5 are sequenced by trigger places P12-P15 (trigger token
    provides the second output token).
    T_RESET requires final trigger from P16 before filling accumulator.

    Transitions: T_LOAD, T_SKIP1-5, T_COPYA-F/E, T_DONE, T_RESET (14 total)
    Places: P0-P11 (same as T-copier) + P12-P16 (trigger chain) (17 total)
    """
    T_LOAD  = "A"
    T_COPYA = "B"
    T_COPYB = "C"
    T_COPYC = "D"
    T_COPYD = "F"
    T_COPYF = "AB"
    T_COPYE = "AF"
    T_DONE  = "AC"
    T_RESET = "AD"
    # Skip transitions for DAEEE prefix (5 characters)
    T_SKIP1 = "AE"   # Skip "D" (position 0)
    T_SKIP2 = "BA"   # Skip "A" (position 1)
    T_SKIP3 = "BB"   # Skip "E" (position 2)
    T_SKIP4 = "BC"   # Skip "E" (position 3)
    T_SKIP5 = "BD"   # Skip "E" (position 4)

    parts = []

    # P0: Template grab
    parts.append(place())
    parts.append(ext_grab("FDFAFF"))      # ^(D)A.*?$ — requires DA prefix
    parts.append(ia_reg(T_LOAD))

    # P1: Read head — includes skip filter arcs
    parts.append(place())
    for acid, tid in [("A", T_COPYA), ("B", T_COPYB), ("C", T_COPYC),
                      ("D", T_COPYD), ("F", T_COPYF), ("E", T_COPYE)]:
        parts.append(ia_filter(acid, tid))
        parts.append(oa_move_fw(tid))
    # Skip arcs: each filters a specific acid and advances cursor
    parts.append(ia_filter("D", T_SKIP1))     # Position 0: "D"
    parts.append(oa_move_fw(T_SKIP1))
    parts.append(ia_filter("A", T_SKIP2))     # Position 1: "A"
    parts.append(oa_move_fw(T_SKIP2))
    parts.append(ia_filter("E", T_SKIP3))     # Position 2: "E"
    parts.append(oa_move_fw(T_SKIP3))
    parts.append(ia_filter("E", T_SKIP4))     # Position 3: "E"
    parts.append(oa_move_fw(T_SKIP4))
    parts.append(ia_filter("E", T_SKIP5))     # Position 4: "E"
    parts.append(oa_move_fw(T_SKIP5))
    parts.append(ia_filter_empty(T_DONE))
    parts.append(oa_reg(T_LOAD))

    # P2-P7: Acid grab places (same as T-copier)
    for acid, tid, pattern in [("A", T_COPYA, "FAF"), ("B", T_COPYB, "FBF"),
                                ("C", T_COPYC, "FCF"), ("D", T_COPYD, "FDF"),
                                ("F", T_COPYF, "FFF"), ("E", T_COPYE, "FEF")]:
        parts.append(place())
        parts.append(ext_grab(pattern))
        parts.append(ia_reg(tid))

    # P8: Accumulator — No_token guard for T_SKIP1 only
    parts.append(place())
    parts.append(ia_no_token(T_SKIP1))       # T_SKIP1 guard: only when P8 empty
    for tid in [T_COPYA, T_COPYB, T_COPYC, T_COPYD, T_COPYF, T_COPYE]:
        parts.append(ia_reg(tid))
        parts.append(oa_merge(tid))
    parts.append(ia_reg(T_DONE))
    parts.append(oa_reg(T_RESET))

    # P9: Copy release
    parts.append(place())
    parts.append(ext_release())
    parts.append(oa_reg(T_DONE))

    # P10: Template release
    parts.append(place())
    parts.append(ext_release())
    parts.append(oa_reg(T_DONE))

    # P11: Token factory — provides extra token for T_SKIP1 and T_RESET
    parts.append(place())
    parts.append(ext_init_token())
    parts.append(ia_split(T_SKIP1))        # T_SKIP1 borrows a token for trigger chain
    parts.append(oa_reg(T_SKIP1))          # T_SKIP1 returns one token back
    parts.append(ia_split(T_RESET))
    parts.append(oa_reg(T_RESET))

    # P12-P16: Trigger chain for 5-char prefix skip
    # T_SKIP1 → P12 → T_SKIP2 → P13 → T_SKIP3 → P14 → T_SKIP4 → P15 → T_SKIP5 → P16 → T_RESET

    # P12: trigger1 (filled by T_SKIP1, consumed by T_SKIP2)
    parts.append(place())
    parts.append(oa_reg(T_SKIP1))
    parts.append(ia_reg(T_SKIP2))

    # P13: trigger2 (filled by T_SKIP2, consumed by T_SKIP3)
    parts.append(place())
    parts.append(oa_reg(T_SKIP2))
    parts.append(ia_reg(T_SKIP3))

    # P14: trigger3 (filled by T_SKIP3, consumed by T_SKIP4)
    parts.append(place())
    parts.append(oa_reg(T_SKIP3))
    parts.append(ia_reg(T_SKIP4))

    # P15: trigger4 (filled by T_SKIP4, consumed by T_SKIP5)
    parts.append(place())
    parts.append(oa_reg(T_SKIP4))
    parts.append(ia_reg(T_SKIP5))

    # P16: trigger5 (filled by T_SKIP5, consumed by T_RESET)
    parts.append(place())
    parts.append(oa_reg(T_SKIP5))
    parts.append(ia_reg(T_RESET))

    return "".join(parts)


def build_initial_state(t_copier_mol, r_copier_mol,
                        copier_qtt=5, template_qtt=10, acid_qtt=200, d_qtt=50, e_qtt=200):
    """Build initial state with all 4 molecule types."""
    template_t = TEMPLATE_PREFIX + t_copier_mol
    template_r = TEMPLATE_PREFIX + r_copier_mol

    return {
        "mols": [
            {"mol": t_copier_mol, "qtt": copier_qtt},
            {"mol": r_copier_mol, "qtt": copier_qtt},
            {"mol": template_t, "qtt": template_qtt},
            {"mol": template_r, "qtt": template_qtt},
            {"mol": "A", "qtt": acid_qtt, "ambient": True},
            {"mol": "B", "qtt": acid_qtt, "ambient": True},
            {"mol": "C", "qtt": acid_qtt, "ambient": True},
            {"mol": "D", "qtt": d_qtt, "ambient": True},
            {"mol": "E", "qtt": e_qtt, "ambient": True},
            {"mol": "F", "qtt": acid_qtt, "ambient": True},
        ],
        "env": {
            "transition_rate": 100,
            "grab_rate": 1,
            "break_rate": 0,
            "collision_rate": 0,
        }
    }


def verify_molecule(mol, label="Molecule"):
    """Verify molecule with yaac from-mol and print Petri net summary."""
    result = subprocess.run(
        ["./yaac", "from-mol", f"--mol={mol}"],
        capture_output=True, text=True, timeout=10
    )
    if result.returncode != 0:
        print(f"  {label}: ERROR — {result.stderr.strip()}")
        return None

    data = json.loads(result.stdout)
    pnet = data["pnet"]
    if pnet is None:
        print(f"  {label}: len={len(mol)} — INERT (no Petri net)")
        return data

    grab = pnet["places"][0]["graber"]["str_repr"] if pnet["places"][0]["graber"] else "none"
    print(f"  {label}: len={len(mol)} places={len(pnet['places'])} "
          f"trans={len(pnet['transitions'])} launch={pnet['launchables_nb']} "
          f"P0_grab={grab}")
    return data


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--simple", action="store_true", help="Build simplified T-copier using Copy_iarc")
    parser.add_argument("--simple-4comp", action="store_true", help="Build 4-component system with Copy_iarc copiers")
    parser.add_argument("--copy-grabbed", action="store_true", help="Build copy_grabbed copier")
    args = parser.parse_args()

    if args.copy_grabbed:
        copier = build_copy_grabbed_copier()
        template = TEMPLATE_PREFIX + copier

        print("Copy_grabbed copier:")
        verify_molecule(copier, "Copier")
        verify_molecule(template, "Template")
        print()

        state = build_copy_grabbed_initial_state(copier)
        print(f"Initial state: {len(state['mols'])} mol types, "
              f"{sum(m['qtt'] for m in state['mols'])} total")
        print(json.dumps(state, indent=2))
    elif args.simple_4comp:
        t_copier = build_simple_copier()
        r_copier = build_simple_r_copier()
        template_t = TEMPLATE_PREFIX + t_copier
        template_r = TEMPLATE_PREFIX + r_copier

        print("Simplified 4-component system (Copy_iarc):")
        verify_molecule(t_copier, "T-copier")
        verify_molecule(r_copier, "R-copier")
        verify_molecule(template_t, "Template_T")
        verify_molecule(template_r, "Template_R")
        print()

        state = build_simple_4comp_state(t_copier, r_copier)
        print(f"Initial state: {len(state['mols'])} mol types, "
              f"{sum(m['qtt'] for m in state['mols'])} total")
        print(json.dumps(state, indent=2))
    elif args.simple:
        copier = build_simple_copier()
        template = TEMPLATE_PREFIX + copier

        print("Simplified copier (Copy_iarc):")
        verify_molecule(copier, "Copier")
        verify_molecule(template, "Template")
        print()

        state = build_simple_initial_state(copier)
        print(f"Initial state: {len(state['mols'])} mol types, "
              f"{sum(m['qtt'] for m in state['mols'])} total")
        print(json.dumps(state, indent=2))
    else:
        t_copier = build_t_copier()
        r_copier = build_r_copier()
        template_t = TEMPLATE_PREFIX + t_copier
        template_r = TEMPLATE_PREFIX + r_copier

        print("Molecules:")
        verify_molecule(t_copier, "T-copier")
        verify_molecule(r_copier, "R-copier")
        verify_molecule(template_t, "Template_T")
        verify_molecule(template_r, "Template_R")
        print()

        state = build_initial_state(t_copier, r_copier)
        print(f"Initial state: {len(state['mols'])} mol types, "
              f"{sum(m['qtt'] for m in state['mols'])} total")
        print(json.dumps(state, indent=2))
