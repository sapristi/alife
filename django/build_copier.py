#!/usr/bin/env python3
"""Build self-replicating copier molecules for YAACS.

Full system: 4 molecule types that collectively self-replicate.

1. T-copier (no prefix, safe): grabs D-prefixed templates, copies exactly → new templates
2. R-copier (no prefix, safe): grabs D-prefixed templates, skips D, copies rest → new copiers
3. Template_T = D + T-copier_mol (active T-copier with D prefix): also copies templates
4. Template_R = D + R-copier_mol (active R-copier with D prefix): also produces copiers

Safe copiers (no D prefix) are NOT matched by grab pattern ^(D).*?$, preventing
destructive mutual grabbing. Templates (D prefix) are grabbable but expendable.

R-copier uses a skip mechanism: T_SKIPD fires when accumulator P8 is empty (before T_RESET),
advancing past the D prefix. A trigger token then enables T_RESET to fill the accumulator.
During the copy phase (P8 has token), T_SKIPD can't fire (No_token_iarc guard on P8).
"""

import subprocess
import json
import sys

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
    """Build T-copier: copies templates exactly (no skip, no prefix).

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
    parts.append(ext_grab("FDFFF"))       # ^(D).*?$
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
    """Build R-copier: copies templates with D prefix skipped (ribosome mode).

    Extra vs T-copier: T_SKIPD transition + P12 trigger place.
    T_SKIPD fires when P8 (accumulator) is empty, skipping the D prefix.
    T_RESET requires P12 trigger token (produced by T_SKIPD).

    Transitions: T_LOAD, T_SKIPD, T_COPYA-F/E, T_DONE, T_RESET
    Places: P0-P11 (same as T-copier) + P12(trigger)
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
    T_SKIPD = "AE"   # New: skip D prefix

    parts = []

    # P0: Template grab
    parts.append(place())
    parts.append(ext_grab("FDFFF"))       # ^(D).*?$
    parts.append(ia_reg(T_LOAD))

    # P1: Read head — includes T_SKIPD filter D arc
    parts.append(place())
    for acid, tid in [("A", T_COPYA), ("B", T_COPYB), ("C", T_COPYC),
                      ("D", T_COPYD), ("F", T_COPYF), ("E", T_COPYE)]:
        parts.append(ia_filter(acid, tid))
        parts.append(oa_move_fw(tid))
    parts.append(ia_filter("D", T_SKIPD))    # Skip D: filter D
    parts.append(oa_move_fw(T_SKIPD))        # Skip D: advance cursor
    parts.append(ia_filter_empty(T_DONE))
    parts.append(oa_reg(T_LOAD))

    # P2-P7: Acid grab places (same as T-copier)
    for acid, tid, pattern in [("A", T_COPYA, "FAF"), ("B", T_COPYB, "FBF"),
                                ("C", T_COPYC, "FCF"), ("D", T_COPYD, "FDF"),
                                ("F", T_COPYF, "FFF"), ("E", T_COPYE, "FEF")]:
        parts.append(place())
        parts.append(ext_grab(pattern))
        parts.append(ia_reg(tid))

    # P8: Accumulator — includes No_token guard for T_SKIPD
    parts.append(place())
    parts.append(ia_no_token(T_SKIPD))       # T_SKIPD guard: only when P8 empty
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

    # P11: Token factory — T_RESET now requires trigger from P12
    parts.append(place())
    parts.append(ext_init_token())
    parts.append(ia_split(T_RESET))
    parts.append(oa_reg(T_RESET))

    # P12: Trigger place (empty initially, filled by T_SKIPD, consumed by T_RESET)
    parts.append(place())
    parts.append(oa_reg(T_SKIPD))            # T_SKIPD output: produce trigger
    parts.append(ia_reg(T_RESET))            # T_RESET input: consume trigger

    return "".join(parts)


def build_initial_state(t_copier_mol, r_copier_mol,
                        copier_qtt=5, template_qtt=10, acid_qtt=200, d_qtt=50, e_qtt=200):
    """Build initial state with all 4 molecule types."""
    template_t = "D" + t_copier_mol
    template_r = "D" + r_copier_mol

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
    template_t = "D" + t_copier
    template_r = "D" + r_copier

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
