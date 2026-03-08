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
def ext_release(): return "ABB"
def ext_init_token(): return "ABC"


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
