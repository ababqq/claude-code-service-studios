#!/usr/bin/env bash
# artifact-check.sh — evaluate every workflow-catalog step's artifact spec
# against what is actually on disk.
#
# Replaces the "Use Glob and Read to verify files exist and have meaningful
# content" loop in /gate-check (and the equivalent hand-scans in /help and
# /project-stage-detect). workflow-catalog.yaml already encodes `glob`,
# `pattern`, `min_count` and `any_of` per step; nothing consumed it
# deterministically, so the model re-derived the same answers by opening files.
#
# EMITS OBSERVATIONS, NOT A VERDICT (per .claude/docs/context-management.md
# rule 2). It reports what is on disk; the CALLER applies the workflow tier,
# the required/optional distinction, and any per-feature override. In
# particular this script never says PASS or FAIL, and never decides that an
# ABSENT artifact is a blocker — at `minimal` most of them are not.
#
# Usage: bash .claude/scripts/artifact-check.sh [--phase <id>] [project-root]
#   --phase <id>  restrict output to one phase (discovery, definition, ...)
#                 An empty id (`--phase ""`, `--phase=`, or a trailing
#                 `--phase`) is an error (exit 2), never "every phase": a caller
#                 whose phase resolved to nothing must not receive a report
#                 for every phase and read it as the one it asked about. An
#                 unknown id also exits 2 and names the known ids.
#   project-root  defaults to the repo root; an explicit path is taken as-is
#                 (used by the test suite against fixtures).
#
# Output:
#   CATALOG: <path>            the catalog actually read
#   ROOT: <path>               the tree evaluated against
#   PHASES: <n> / STEPS: <n>   denominators — see below
#   NO_CHECK: <n>
#   PHASE: <id>
#     STEP: <id> required=<bool> repeatable=<bool> tiers=<list|all> when=<cond|always> check=<kind> status=<status> ...
#
# tiers= / when= echo the step's optional `required_tiers:` and
# `required_when:` catalog fields:
#   tiers=standard,full   the modes.workflow tiers at which `required=true`
#                         applies (members: minimal, standard, full, printed
#                         in that order); tiers=all when the field is absent
#   when=backend          the condition under which `required=true` applies
#                         (ui | backend | pii | stores | multi-locale);
#                         when=always when the field is absent
# The script NEVER resolves the tier or evaluates the condition — it has no
# config access and reports only what the catalog declares. /help and
# /project-stage-detect apply both; /gate-check ignores both (its gate
# reference file is authoritative).
#
# Malformed values are reported, never silently repaired:
#   - an unknown tier member is dropped and the line gains ` tiers_error=<raw>`;
#     a list left with no valid member prints tiers=all (a required step never
#     becomes "required at no tier" through a typo)
#   - an unknown condition is treated as absent (when=always) and the line
#     gains ` when_error=<raw>`
# <raw> is the catalog value with its whitespace removed ("(empty)" when
# nothing was written), so every field stays one space-separated token. A
# caller that sees either error field reports the catalog defect instead of
# trusting tiers= / when= for that step.
#
# status values (observations):
#   PRESENT       glob matched, count >= min_count, pattern found if specified
#   ABSENT        no file matched the glob
#   SHORT         files matched but fewer than min_count
#   PATTERN_MISS  files matched but none contained the required pattern
#   NO_CHECK      the step declares no artifact — completion is not detectable
#                 from disk. NOT the same as ABSENT. A `note=` field carries the
#                 catalog's human-readable fallback where one exists.
#
# DENOMINATOR DISCIPLINE (mirrors create-control-manifest / adr-dep-graph.sh):
# STEPS is printed before any per-step line so a caller can tell "0 steps
# reported because the catalog failed to parse" from "0 steps are incomplete".
# A NO_CHECK count is printed too — a phase that is all NO_CHECK has been
# *scanned*, not *satisfied*, and reporting it as clean would be a false pass.
#
# Patterns are POSIX ERE and are matched with `grep -E`, never Python `re`
# (the catalog uses classes like [[:space:]]) and never `grep -P` (unavailable
# on Windows Git Bash — see .claude/docs/coding-standards notes).

set -u

PHASE_FILTER=""
PHASE_GIVEN=false
ROOT_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --phase)
      PHASE_GIVEN=true
      PHASE_FILTER="${2:-}"
      if [ $# -ge 2 ]; then shift 2; else shift; fi
      ;;
    --phase=*) PHASE_GIVEN=true; PHASE_FILTER="${1#--phase=}"; shift ;;
    -h|--help) sed -n '2,/^set -u$/p' "$0" | sed '$d'; exit 0 ;;
    *) ROOT_ARG="$1"; shift ;;
  esac
done

# An explicitly empty phase id is a caller bug, not a request for every phase.
if [ "$PHASE_GIVEN" = true ] && [ -z "$PHASE_FILTER" ]; then
  echo "ERROR: --phase needs a phase id" >&2
  exit 2
fi

if [ -n "$ROOT_ARG" ]; then
  ROOT="$ROOT_ARG"
else
  cd "$(dirname "$0")/../.." || { echo "artifact-check: cannot reach repo root" >&2; exit 1; }
  ROOT="$(pwd)"
fi

CATALOG="$ROOT/.claude/docs/workflow-catalog.yaml"
if [ ! -f "$CATALOG" ]; then
  echo "artifact-check: catalog not found at $CATALOG" >&2
  exit 1
fi

# Python fallback chain: python -> python3 -> py (the same chain yaml-helper.sh
# resolves in _yaml_helper_resolve_python).
PYBIN=""
for candidate in python python3 py; do
  if command -v "$candidate" >/dev/null 2>&1; then
    if "$candidate" -c 'import sys; sys.exit(0 if sys.version_info[0] == 3 else 1)' >/dev/null 2>&1; then
      PYBIN="$candidate"; break
    fi
  fi
done
if [ -z "$PYBIN" ]; then
  echo "artifact-check: no python 3 interpreter found (tried python, python3, py)" >&2
  exit 1
fi

"$PYBIN" - "$CATALOG" "$ROOT" "$PHASE_FILTER" <<'PYEOF'
import glob as globmod
import os
import subprocess
import sys

catalog_path, root, phase_filter = sys.argv[1], sys.argv[2], sys.argv[3]

# A gate's own output path is part of the gate: the catalog's `note:` fields
# contain em-dashes, and on a cp1252 console an unreconfigured stdout raises
# UnicodeEncodeError mid-report — dying after some rows have printed, which
# reads as a short but successful run. Force UTF-8 and never crash on a glyph.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except (AttributeError, ValueError):
    pass


def indent_of(line):
    return len(line) - len(line.lstrip(" "))


def strip_val(v):
    v = v.strip()
    if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
        v = v[1:-1]
    return v


# Closed vocabularies of the two optional step fields. The catalog header
# documents the same lists; a value outside them is reported, never guessed.
TIERS = ("minimal", "standard", "full")          # modes.workflow values
CONDITIONS = ("ui", "backend", "pii", "stores", "multi-locale")


def raw_token(v):
    # The malformed value as written, whitespace removed so it stays ONE
    # space-separated field on the STEP line; "(empty)" when nothing was written.
    t = "".join(v.split())
    return t if t else "(empty)"


def parse_tiers(v):
    """`required_tiers: [standard, full]` -> (["standard", "full"], None).

    One-line flow list only (the catalog's format contract). Unknown members
    are dropped and the raw value is returned as the error. A list left with no
    valid member cannot mean "required at no tier" — that would silently relax
    a required step — so it collapses to None (every tier) plus the error.
    Members print in the canonical minimal,standard,full order, deduplicated.
    """
    body = v.strip()
    if body.startswith("["):
        body = body[1:]
    if body.endswith("]"):
        body = body[:-1]
    members = [strip_val(m) for m in body.split(",")]
    members = [m for m in members if m]
    bad = [m for m in members if m not in TIERS]
    good = [t for t in TIERS if t in members]
    err = raw_token(v) if (bad or not good) else None
    return (good or None), err


def parse_when(v):
    """`required_when: backend` -> ("backend", None). Unknown -> (None, raw)."""
    cond = strip_val(v)
    if cond in CONDITIONS:
        return cond, None
    return None, raw_token(v)


# --- parse ---------------------------------------------------------------
# Hand-rolled on purpose: PyYAML is not a guaranteed dependency (yaml-helper.sh
# promises "no external deps beyond a Python 3 interpreter"). The catalog's
# shape is fixed and regular, so an indentation walk is sufficient and cannot
# drag in an import that fails on a user's machine.
with open(catalog_path, encoding="utf-8", errors="replace") as fh:
    lines = [ln.rstrip("\n").rstrip("\r") for ln in fh]

phases = []            # [(phase_id, [step, ...])]
cur_phase = None
cur_step = None
ctx = None             # None | "artifact" | "any_of"
in_phases = False

for raw in lines:
    if not raw.strip() or raw.lstrip().startswith("#"):
        continue
    ind = indent_of(raw)
    s = raw.strip()

    if ind == 0:
        in_phases = (s == "phases:")
        continue
    if not in_phases:
        continue

    if ind == 2 and s.endswith(":"):
        cur_phase = (s[:-1].strip(), [])
        phases.append(cur_phase)
        cur_step = None
        ctx = None
        continue
    if cur_phase is None:
        continue

    if ind == 6 and s.startswith("- id:"):
        cur_step = {"id": strip_val(s[len("- id:"):]), "required": False,
                    "repeatable": False, "artifact": None, "note": None,
                    "tiers": None, "tiers_error": None,
                    "when": None, "when_error": None}
        cur_phase[1].append(cur_step)
        ctx = None
        continue
    if cur_step is None:
        continue

    if ind == 8:
        ctx = None
        if s == "artifact:":
            cur_step["artifact"] = {"glob": None, "pattern": None,
                                    "min_count": 1, "any_of": [], "note": None}
            ctx = "artifact"
        elif s.startswith("required:"):
            cur_step["required"] = strip_val(s[len("required:"):]).lower() == "true"
        elif s.startswith("repeatable:"):
            cur_step["repeatable"] = strip_val(s[len("repeatable:"):]).lower() == "true"
        elif s.startswith("required_tiers:"):
            cur_step["tiers"], cur_step["tiers_error"] = parse_tiers(s[len("required_tiers:"):])
        elif s.startswith("required_when:"):
            cur_step["when"], cur_step["when_error"] = parse_when(s[len("required_when:"):])
        continue

    art = cur_step["artifact"]
    if art is None:
        continue

    if ind == 10:
        if s == "any_of:":
            ctx = "any_of"
        elif s.startswith("glob:"):
            art["glob"] = strip_val(s[len("glob:"):]); ctx = "artifact"
        elif s.startswith("pattern:"):
            art["pattern"] = strip_val(s[len("pattern:"):]); ctx = "artifact"
        elif s.startswith("min_count:"):
            try:
                art["min_count"] = int(strip_val(s[len("min_count:"):]))
            except ValueError:
                pass
            ctx = "artifact"
        elif s.startswith("note:"):
            art["note"] = strip_val(s[len("note:"):]); ctx = "artifact"
        continue

    if ind >= 12 and ctx == "any_of":
        if s.startswith("- glob:"):
            art["any_of"].append({"glob": strip_val(s[len("- glob:"):]), "pattern": None})
        elif s.startswith("pattern:") and art["any_of"]:
            art["any_of"][-1]["pattern"] = strip_val(s[len("pattern:"):])

# --- evaluate ------------------------------------------------------------
def match_files(pat):
    if not pat:
        return []
    full = os.path.join(root, pat.replace("/", os.sep))
    return sorted(p for p in globmod.glob(full, recursive=True) if os.path.isfile(p))


def pattern_hits(files, pattern):
    """POSIX ERE via grep -E. Python's re cannot parse [[:space:]], and grep -P
    is unavailable on Windows Git Bash."""
    if not pattern:
        return files
    hits = []
    for f in files:
        try:
            rc = subprocess.call(["grep", "-qE", "--", pattern, f],
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except OSError:
            return None          # no grep — caller reports UNKNOWN rather than a false miss
        if rc == 0:
            hits.append(f)
    return hits


def evaluate(art):
    """-> (status, kind, detail dict). Observation only; no verdict."""
    if art is None:
        return "NO_CHECK", "none", {}

    if art["any_of"]:
        for i, alt in enumerate(art["any_of"]):
            files = match_files(alt["glob"])
            if not files:
                continue
            hits = pattern_hits(files, alt["pattern"])
            if hits is None:
                return "UNKNOWN", "any_of", {"why": "grep-unavailable"}
            if hits:
                return "PRESENT", "any_of", {"match": alt["glob"], "alt": str(i + 1)}
        return "ABSENT", "any_of", {"alts": str(len(art["any_of"]))}

    if not art["glob"]:
        return "NO_CHECK", "none", ({"note": art["note"]} if art["note"] else {})

    files = match_files(art["glob"])
    if not files:
        return "ABSENT", "glob", {"glob": art["glob"]}

    hits = pattern_hits(files, art["pattern"])
    if hits is None:
        return "UNKNOWN", "glob", {"why": "grep-unavailable"}
    if art["pattern"] and not hits:
        return "PATTERN_MISS", "glob", {"glob": art["glob"], "found": str(len(files))}

    counted = hits if art["pattern"] else files
    need = art["min_count"]
    if len(counted) < need:
        return "SHORT", "glob", {"glob": art["glob"], "count": str(len(counted)), "min": str(need)}
    d = {"count": str(len(counted))}
    if need > 1:
        d["min"] = str(need)
    return "PRESENT", "glob", d


sel = [(pid, steps) for pid, steps in phases if not phase_filter or pid == phase_filter]

if phase_filter and not sel:
    known = ", ".join(pid for pid, _ in phases) or "(none parsed)"
    sys.stderr.write("artifact-check: unknown phase '%s' (known: %s)\n" % (phase_filter, known))
    sys.exit(2)

total_steps = sum(len(s) for _, s in sel)
print("CATALOG: %s" % os.path.relpath(catalog_path, root).replace(os.sep, "/"))
print("ROOT: %s" % root.replace(os.sep, "/"))
print("PHASES: %d" % len(sel))
print("STEPS: %d" % total_steps)

no_check = 0
rows = []
for pid, steps in sel:
    rows.append("PHASE: %s" % pid)
    for st in steps:
        status, kind, det = evaluate(st["artifact"])
        if status == "NO_CHECK":
            no_check += 1
        extra = "".join(" %s=%s" % (k, v) for k, v in sorted(det.items()) if v is not None)
        if st["tiers_error"]:
            extra += " tiers_error=%s" % st["tiers_error"]
        if st["when_error"]:
            extra += " when_error=%s" % st["when_error"]
        rows.append("  STEP: %s required=%s repeatable=%s tiers=%s when=%s check=%s status=%s%s"
                    % (st["id"], str(st["required"]).lower(),
                       str(st["repeatable"]).lower(),
                       ",".join(st["tiers"]) if st["tiers"] else "all",
                       st["when"] or "always",
                       kind, status, extra))

# Printed BEFORE the rows so a caller reading top-down knows how much of what
# follows is undetectable-from-disk before it reads any of it.
print("NO_CHECK: %d" % no_check)
for r in rows:
    print(r)
PYEOF
