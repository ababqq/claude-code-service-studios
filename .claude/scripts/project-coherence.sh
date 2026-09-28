#!/usr/bin/env bash
#
# project-coherence.sh — stack coherence: compare what `project.yaml` DECLARES
# about the stack with what the stack reference and the repository say.
#
# WHY THIS EXISTS
#
# /setup-stack writes the same facts to several places in one run: component
# versions to `project.yaml` (`stack.layers.*`) and to the Pinned Components
# table of `docs/stack-reference/VERSION.md`; the runtime to
# `stack.layers.backend.runtime`; the package manager to `stack.package_manager`;
# and the commands every later skill executes to `commands.*`. The repository
# states the same things again in its own files — `.nvmrc`, `package.json`, the
# lockfile, the Dockerfile — and each reader trusts a different copy: agents read
# `project.yaml`, developers read `.nvmrc`, CI reads the Dockerfile. Prose in the
# skill telling it to keep them in step does not hold on its own. What holds is a
# step that reads back what was written and compares it with what is on disk.
#
# WHAT IT COMPARES (one observation line per comparison)
#
#   1  stack.pinned_on             vs the `**Stack Pinned**` row of VERSION.md
#   2  each configured component   vs its Pinned Components row
#        web / mobile / backend framework: the `version` key
#        backend runtime, data and cloud components: the trailing version inside
#        the configured string (`PostgreSQL 16`), else UNCHECKED
#        rows reading `n/a (managed service)` or `NOT DETERMINED` (accepted or
#        not): UNCHECKED, with the reason
#   3  Pinned Components rows that no configured component accounts for
#   4  backend runtime             vs .nvmrc / .node-version / .python-version /
#                                     .tool-versions / package.json#engines /
#                                     Dockerfile FROM (repo root and backend roots)
#   5  framework major             vs the manifest dependency in each declared root:
#        next, react, vue, nuxt, @nestjs/core, express, fastify, react-native,
#        expo (package.json) · flutter (pubspec.yaml `environment:`) ·
#        spring-boot (Gradle plugin, Gradle version catalog, Maven parent) ·
#        fastapi, django (pyproject.toml, requirements.txt)
#   6  lockfiles on disk           vs stack.package_manager (and the root
#                                     package.json `packageManager` field)
#   7  commands.*                  vs package.json scripts, for every command that
#                                     names a package script
#
# OUTPUT
#
#   === stack coherence ===
#   COMPARISONS: <n> match=<n> mismatch=<n> unchecked=<n>
#   MATCH: <subject> — <what agreed>
#   MISMATCH: <subject> — <what disagreed>
#   UNCHECKED: <subject> — <why the comparison could not be made>
#
# The denominator prints before the rows. A comparison that could not run prints
# an UNCHECKED line that names why: silence is never agreement, and a search that
# found no file has not established that nothing disagrees.
#
# OBSERVATIONS, NEVER VERDICTS
#
# Per CLAUDE.md ("Helpers in .claude/scripts/ emit observations, never
# verdicts"): this script prints what it compared and what it found, and always
# exits 0. It never prints PASS or FAIL and never decides whether a MISMATCH
# matters — the skill that ran it (/setup-stack, /smoke-check) and the user do.
#
# Usage: bash .claude/scripts/project-coherence.sh [project-root]
#   project-root  defaults to CLAUDE_PROJECT_DIR, else the repository this script
#                 sits in (<root>/.claude/scripts/../..). An explicit path is
#                 taken as-is (used against fixtures).
#
# Reads project.yaml only through .claude/hooks/yaml-helper.sh (the one YAML
# reader the framework shares) and package.json with Python's json module, so it
# needs a Python 3 interpreter; without one every comparison prints UNCHECKED.
# bash 3.2 compatible (macOS): no associative arrays, no ${var,,}, no mapfile.

set -u
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"

case "${1:-}" in
  -h|--help) sed -n '2,/^set -u$/p' "$0" | sed '$d'; exit 0 ;;
esac

if [ -n "${1:-}" ]; then
  ROOT="$1"
else
  ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$SCRIPT_DIR/../.." 2>/dev/null && pwd)}"
fi

# --- observation buffer ------------------------------------------------------
# Rows are collected first so the denominator can print before them.

ROWS=""
N_MATCH=0
N_MISMATCH=0
N_UNCHECKED=0
NL='
'
TAB='	'

_obs()      { ROWS="${ROWS}$1: $2${NL}"; }
match()     { N_MATCH=$((N_MATCH+1));         _obs MATCH "$*"; }
mismatch()  { N_MISMATCH=$((N_MISMATCH+1));   _obs MISMATCH "$*"; }
unchecked() { N_UNCHECKED=$((N_UNCHECKED+1)); _obs UNCHECKED "$*"; }

finish() {
  total=$((N_MATCH + N_MISMATCH + N_UNCHECKED))
  printf '%s\n' "=== stack coherence ==="
  printf 'COMPARISONS: %s match=%s mismatch=%s unchecked=%s\n' \
    "$total" "$N_MATCH" "$N_MISMATCH" "$N_UNCHECKED"
  printf '%s' "$ROWS"
  printf '\n%s\n%s\n' \
    "Observations only — no verdict. Each UNCHECKED line names why that comparison" \
    "could not be made; UNCHECKED is not agreement."
  exit 0
}

if [ -z "$ROOT" ] || ! cd "$ROOT" 2>/dev/null; then
  unchecked "every comparison — project root not readable (${ROOT:-unset})"
  finish
fi
ROOT="$PWD"

if [ ! -f project.yaml ]; then
  unchecked "every comparison — no project.yaml at the project root (run /start, then /setup-stack)"
  finish
fi

# --- interpreters and the shared YAML reader ---------------------------------

PY=""
for _c in python3 python py; do
  if command -v "$_c" >/dev/null 2>&1 &&
     "$_c" -c 'import sys; sys.exit(0 if sys.version_info[0] >= 3 else 1)' >/dev/null 2>&1; then
    PY="$_c"; break
  fi
done
if [ -z "$PY" ]; then
  unchecked "every comparison — no Python 3 interpreter (tried python3, python, py); project.yaml and package.json cannot be read"
  finish
fi

HELPER=""
if [ -f "$ROOT/.claude/hooks/yaml-helper.sh" ]; then
  HELPER="$ROOT/.claude/hooks/yaml-helper.sh"
elif [ -f "$SCRIPT_DIR/../hooks/yaml-helper.sh" ]; then
  HELPER="$SCRIPT_DIR/../hooks/yaml-helper.sh"
fi
if [ -z "$HELPER" ]; then
  unchecked "every comparison — .claude/hooks/yaml-helper.sh not found; project.yaml cannot be read"
  finish
fi
# Silenced on both streams: anything printed while sourcing would land above the
# denominator line.
# shellcheck disable=SC1090
. "$HELPER" >/dev/null 2>&1
if ! command -v get_yaml_key >/dev/null 2>&1 || ! command -v get_yaml_array >/dev/null 2>&1; then
  unchecked "every comparison — yaml-helper.sh has no get_yaml_key / get_yaml_array"
  finish
fi

YAML="$ROOT/project.yaml"
yk() { get_yaml_key "$YAML" "$1" 2>/dev/null; }
ya() { get_yaml_array "$YAML" "$1" 2>/dev/null; }

# --- small helpers -----------------------------------------------------------

lc()    { printf '%s' "$1" | tr 'A-Z' 'a-z'; }
trim()  { printf '%s' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'; }
strip_v() { printf '%s' "$1" | sed -E 's/^[[:space:]]*[vV]//; s/[[:space:]]+$//'; }

# A value that states "no component" rather than naming one.
is_none() {
  case "$(lc "$(trim "$1")")" in
    ""|none|unset|n/a|-|—) return 0 ;;
  esac
  return 1
}

# Component name / trailing version of a configured string: "PostgreSQL 16" ->
# "PostgreSQL" / "16". A string with no trailing version keeps its whole text as
# the name and has no version.
comp_name() { printf '%s' "$1" | sed -E 's/[[:space:]]+[vV]?[0-9][0-9A-Za-z.+-]*$//'; }
comp_ver()  { printf '%s' "$1" | sed -nE 's/.*[[:space:]][vV]?([0-9][0-9A-Za-z.+-]*)$/\1/p'; }

# prefix_agree <configured> <found>: equal, or one a dotted prefix of the other
# ("22" and "22.11.0" agree; "22" and "20.18.0" do not).
prefix_agree() {
  _a="$(strip_v "$1")"; _b="$(strip_v "$2")"
  [ "$_a" = "$_b" ] && return 0
  case "$_b" in "$_a".*) return 0 ;; esac
  case "$_a" in "$_b".*) return 0 ;; esac
  return 1
}

# major_of <version or spec>: the compatibility line of the first version found
# in the text — the major, or major.minor on a 0.x line (0.79, 0.115), where the
# minor is the breaking component.
major_of() {
  _v="$(printf '%s' "$1" | grep -oE '[0-9]+(\.[0-9]+)*' | head -1)"
  case "$_v" in
    "") ;;
    0.*) printf '%s' "$_v" | cut -d. -f1-2 ;;
    *)   printf '%s' "$_v" | cut -d. -f1 ;;
  esac
}

# Declared roots of a layer, one per line, trailing slash removed. The key is a
# scalar path or a flow list (`[apps/web, apps/admin]`).
layer_roots() {
  _raw="$(yk "stack.layers.$1.root")"
  case "$_raw" in
    "") ;;
    \[*) ya "stack.layers.$1.root" ;;
    *) printf '%s\n' "$_raw" ;;
  esac | sed -E 's#/+$##; s#^\./##' | grep -v '^$'
}

shared_roots() {
  _raw="$(yk stack.shared_roots)"
  case "$_raw" in
    "") ;;
    \[*) ya stack.shared_roots ;;
    *) printf '%s\n' "$_raw" ;;
  esac | sed -E 's#/+$##; s#^\./##' | grep -v '^$'
}

# rel <dir> <file>: a display path relative to the project root.
rel() { if [ "$1" = "." ]; then printf '%s' "$2"; else printf '%s/%s' "$1" "$2"; fi; }

# pkg_json <file> <mode> [arg] — read one fact from a package.json.
#   dep <name>        version spec from dependencies / devDependencies /
#                     peerDependencies / optionalDependencies (first found)
#   engines <name>    engines.<name>
#   pm                packageManager
# A file that is not valid JSON prints "!unreadable", so a parse failure is never
# mistaken for "the field is absent".
pkg_json() {
  "$PY" - "$@" <<'PYEOF' 2>/dev/null
import json, sys
path, mode = sys.argv[1], sys.argv[2]
arg = sys.argv[3] if len(sys.argv) > 3 else ""
try:
    with open(path, encoding="utf-8-sig") as f:
        d = json.load(f)
except Exception:
    sys.stdout.write("!unreadable")
    sys.exit(0)
if not isinstance(d, dict):
    sys.stdout.write("!unreadable")
    sys.exit(0)
out = ""
if mode == "dep":
    for sec in ("dependencies", "devDependencies", "peerDependencies", "optionalDependencies"):
        s = d.get(sec)
        if isinstance(s, dict) and arg in s:
            out = str(s[arg]); break
elif mode == "engines":
    e = d.get("engines")
    if isinstance(e, dict) and arg in e:
        out = str(e[arg])
elif mode == "pm":
    out = str(d.get("packageManager", "") or "")
sys.stdout.write(out)
PYEOF
}

# pkg_index <file>... — "<path>\t<name>\t<script,script,...>" per package.json.
pkg_index() {
  "$PY" - "$@" <<'PYEOF' 2>/dev/null
import json, sys
for p in sys.argv[1:]:
    try:
        with open(p, encoding="utf-8-sig") as f:
            d = json.load(f)
    except Exception:
        continue
    if not isinstance(d, dict):
        continue
    name = d.get("name", "") or ""
    scripts = d.get("scripts", {})
    keys = ",".join(sorted(scripts.keys())) if isinstance(scripts, dict) else ""
    sys.stdout.write("%s\t%s\t%s\n" % (p, name, keys))
PYEOF
}

# =============================================================================
# Read the configuration
# =============================================================================

LAYERS="web mobile backend data cloud"

# Configured components: "<layer>\t<key>\t<name>\t<version>" per line.
COMPONENTS=""
add_comp() { COMPONENTS="${COMPONENTS}$1${TAB}$2${TAB}$3${TAB}$4${NL}"; }

for _layer in web mobile backend; do
  _fw="$(yk "stack.layers.$_layer.framework")"
  if ! is_none "$_fw"; then
    _v="$(yk "stack.layers.$_layer.version")"
    [ -z "$_v" ] && _v="$(comp_ver "$_fw")"
    add_comp "$_layer" framework "$(comp_name "$_fw")" "$(strip_v "$_v")"
  fi
done
RUNTIME="$(yk stack.layers.backend.runtime)"
if ! is_none "$RUNTIME"; then
  add_comp backend runtime "$(comp_name "$RUNTIME")" "$(comp_ver "$RUNTIME")"
fi
for _k in database cache queue orm; do
  _s="$(yk "stack.layers.data.$_k")"
  is_none "$_s" || add_comp data "$_k" "$(comp_name "$_s")" "$(comp_ver "$_s")"
done
for _k in provider iac; do
  _s="$(yk "stack.layers.cloud.$_k")"
  is_none "$_s" || add_comp cloud "$_k" "$(comp_name "$_s")" "$(comp_ver "$_s")"
done

# The stack reference.
VF="docs/stack-reference/VERSION.md"
HEADER='| Layer | Component | Version | Knowledge Risk | Source | Retrieved |'
HAVE_VF=false; HAVE_HEADER=false
PIN_ROWS=""        # "<layer>\t<component>\t<version>" per real row
PINNED_ROW=""
if [ -f "$VF" ]; then
  HAVE_VF=true
  PINNED_ROW="$(grep -E '^\| \*\*Stack Pinned\*\* \|' "$VF" | head -1 |
                sed -E 's/^\| \*\*Stack Pinned\*\* \|[[:space:]]*//; s/[[:space:]]*\|[[:space:]]*$//')"
  if grep -qF "$HEADER" "$VF"; then
    HAVE_HEADER=true
    PIN_ROWS="$(awk -v H="$HEADER" '
      { sub(/\r$/, "") }
      state == 0 && index($0, H) == 1 { state = 1; next }
      state == 1 { state = 2; next }                      # the |---| separator
      state == 2 && /^\|/ {
        n = split($0, c, "|")
        # An empty cell prints as "-" so `read` cannot shift the fields.
        for (i = 2; i <= 4; i++) { gsub(/^[ \t]+|[ \t]+$/, "", c[i]); if (c[i] == "") c[i] = "-" }
        print c[2] "\t" c[3] "\t" c[4]
        next
      }
      state == 2 { exit }
    ' "$VF")"
  fi
fi

# =============================================================================
# 1. stack.pinned_on vs the **Stack Pinned** row
# =============================================================================

PON="$(yk stack.pinned_on)"
PON_DATE="$(printf '%s' "$PON" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)"
ROW_DATE="$(printf '%s' "$PINNED_ROW" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)"

if [ "$HAVE_VF" = false ]; then
  unchecked "stack.pinned_on vs **Stack Pinned** — $VF not found"
elif [ -z "$PINNED_ROW" ]; then
  unchecked "stack.pinned_on vs **Stack Pinned** — $VF has no '| **Stack Pinned** |' row"
elif [ -z "$PON_DATE" ] && [ -z "$ROW_DATE" ]; then
  unchecked "stack.pinned_on — unset in project.yaml and not recorded in $VF: stack setup has not completed (run /setup-stack)"
elif [ -n "$PON_DATE" ] && [ -z "$ROW_DATE" ]; then
  mismatch "stack.pinned_on — project.yaml says $PON_DATE but the **Stack Pinned** row of $VF has no date (run /setup-stack refresh)"
elif [ -z "$PON_DATE" ]; then
  mismatch "stack.pinned_on — the **Stack Pinned** row of $VF says $ROW_DATE but stack.pinned_on is unset in project.yaml"
elif [ "$PON_DATE" = "$ROW_DATE" ]; then
  match "stack.pinned_on — project.yaml and the **Stack Pinned** row both say $PON_DATE"
else
  mismatch "stack.pinned_on — project.yaml says $PON_DATE, the **Stack Pinned** row of $VF says $ROW_DATE"
fi

# =============================================================================
# 2. Each configured component vs its Pinned Components row
# =============================================================================

if [ -z "$COMPONENTS" ]; then
  unchecked "stack components vs $VF — no stack.layers.* component is configured in project.yaml (run /setup-stack)"
else
  while IFS="$TAB" read -r _layer _key _name _cv; do
    [ -n "$_layer" ] || continue
    _subj="$_layer $_name ($_key)"
    if [ "$HAVE_VF" = false ]; then
      unchecked "$_subj vs $VF — file not found"; continue
    fi
    if [ "$HAVE_HEADER" = false ]; then
      unchecked "$_subj vs $VF — Pinned Components header not found (expected '$HEADER')"; continue
    fi
    _lname="$(lc "$_name")"
    _row="$(printf '%s\n' "$PIN_ROWS" | awk -F'\t' -v L="$_layer" -v C="$_lname" \
             'tolower($1) == L && tolower($2) == C { print; exit }')"
    if [ -z "$_row" ]; then
      mismatch "$_subj — configured in project.yaml but $VF has no Pinned Components row for it"
      continue
    fi
    _rv="$(printf '%s' "$_row" | cut -f3)"
    case "$_rv" in
      "n/a (managed service)"*)
        unchecked "$_subj — managed service, recorded as 'n/a (managed service)': no version to compare"; continue ;;
      "NOT DETERMINED — accepted by user"*)
        unchecked "$_subj — accepted gap ('$_rv'): no pinned version to compare"; continue ;;
      "NOT DETERMINED"*)
        unchecked "$_subj — the row reads NOT DETERMINED and the gap was not accepted: pin incomplete (run /setup-stack refresh)"; continue ;;
    esac
    if [ -z "$_cv" ]; then
      case "$_key" in
        framework) unchecked "$_subj — no stack.layers.$_layer.version configured to compare with the row ($_rv)" ;;
        *)         unchecked "$_subj — the configured string carries no trailing version to compare with the row ($_rv)" ;;
      esac
      continue
    fi
    if [ "$(strip_v "$_cv")" = "$(strip_v "$_rv")" ]; then
      match "$_subj — project.yaml $_cv, $VF $_rv"
    else
      mismatch "$_subj — project.yaml says $_cv but $VF pins $_rv"
    fi
  done <<EOF
$COMPONENTS
EOF
fi

# =============================================================================
# 3. Pinned Components rows no configured component accounts for
# =============================================================================

if [ "$HAVE_HEADER" = true ] && [ -n "$PIN_ROWS" ]; then
  while IFS="$TAB" read -r _rl _rc _rv; do
    [ -n "$_rl$_rc" ] || continue
    # The skeleton's placeholder row (`| — | NOT DETERMINED | … |`) is not a pin.
    if is_none "$_rl" && [ "$_rc" = "NOT DETERMINED" ]; then continue; fi
    _lrl="$(lc "$_rl")"
    case " $LAYERS " in
      *" $_lrl "*) ;;
      *) mismatch "row '$_rl | $_rc' in $VF — layer is not one of web|mobile|backend|data|cloud"; continue ;;
    esac
    _hit="$(printf '%s' "$COMPONENTS" | awk -F'\t' -v L="$_lrl" -v C="$(lc "$_rc")" \
             '$1 == L && tolower($3) == C { print "y"; exit }')"
    if [ -z "$_hit" ]; then
      mismatch "row '$_rl | $_rc' in $VF — no configured stack.layers.$_lrl component matches it (stale after a stack change? run /setup-stack refresh)"
    fi
  done <<EOF
$PIN_ROWS
EOF
fi

# =============================================================================
# 4. Backend runtime vs the repository's runtime version files
# =============================================================================

# runtime_obs <subject> <configured-version> <declared-value>
runtime_obs() {
  _val="$(trim "$3" | sed -E "s/^[\"']//; s/[\"']\$//")"
  _core="$(printf '%s' "$_val" | sed -E 's/^(\^|~|=)//; s/^[vV]//; s/\+.*$//; s/(\.[xX*])+$//')"
  if printf '%s' "$_core" | grep -qE '^[0-9]+(\.[0-9]+)*$'; then
    if prefix_agree "$2" "$_core"; then
      match "$1 — declares $_val, configured $2"
    else
      mismatch "$1 — declares $_val, configured $2"
    fi
  else
    unchecked "$1 — '$_val' is an alias or a range, not evaluated (configured $2)"
  fi
}

# first_value <file>: the first non-empty, non-comment line.
first_value() { grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null | head -1; }

if is_none "$RUNTIME"; then
  unchecked "backend runtime vs version files — stack.layers.backend.runtime not configured"
else
  RT_NAME="$(comp_name "$RUNTIME")"
  RT_VER="$(comp_ver "$RUNTIME")"
  case "$(lc "$RT_NAME")" in
    node|node.js|nodejs)   RT_FAM=node ;;
    bun)                   RT_FAM=bun ;;
    deno)                  RT_FAM=deno ;;
    python|cpython)        RT_FAM=python ;;
    java|jdk|jre|openjdk|*temurin*|*corretto*|*zulu*|*liberica*) RT_FAM=java ;;
    go|golang)             RT_FAM=go ;;
    *)                     RT_FAM="" ;;
  esac
  if [ -z "$RT_FAM" ]; then
    unchecked "backend runtime '$RUNTIME' — runtime family not recognised (node, bun, deno, python, java, go)"
  elif [ -z "$RT_VER" ]; then
    unchecked "backend runtime '$RUNTIME' — the configured string carries no version to compare"
  else
    case "$RT_FAM" in
      node)   TV_KEYS="nodejs node";   IMG_RE='^node$' ;;
      bun)    TV_KEYS="bun";           IMG_RE='^bun$' ;;
      deno)   TV_KEYS="deno";          IMG_RE='^deno$' ;;
      python) TV_KEYS="python";        IMG_RE='^python$' ;;
      java)   TV_KEYS="java";          IMG_RE='^(eclipse-temurin|amazoncorretto|openjdk|sapmachine|ibm-semeru-runtimes|liberica-openjdk(-[a-z]+)?|zulu-openjdk(-[a-z]+)?)$' ;;
      go)     TV_KEYS="golang go";     IMG_RE='^golang$' ;;
    esac
    RT_DIRS="$(printf '.\n%s\n' "$(layer_roots backend)" | grep -v '^$' | awk '!seen[$0]++')"
    RT_FOUND=0
    while IFS= read -r _d; do
      [ -n "$_d" ] || continue
      [ -d "$_d" ] || continue
      _subj_base="backend runtime $RT_NAME $RT_VER vs"
      if [ "$RT_FAM" = node ]; then
        for _f in .nvmrc .node-version; do
          if [ -f "$_d/$_f" ]; then
            RT_FOUND=$((RT_FOUND+1))
            runtime_obs "$_subj_base $(rel "$_d" "$_f")" "$RT_VER" "$(first_value "$_d/$_f")"
          fi
        done
      fi
      if [ "$RT_FAM" = python ] && [ -f "$_d/.python-version" ]; then
        RT_FOUND=$((RT_FOUND+1))
        runtime_obs "$_subj_base $(rel "$_d" .python-version)" "$RT_VER" "$(first_value "$_d/.python-version")"
      fi
      if [ -f "$_d/.tool-versions" ]; then
        for _k in $TV_KEYS; do
          _line="$(grep -E "^[[:space:]]*$_k[[:space:]]+" "$_d/.tool-versions" | head -1)"
          if [ -n "$_line" ]; then
            RT_FOUND=$((RT_FOUND+1))
            # First version on the line; a vendor prefix (`temurin-21.0.5`) is dropped.
            _tv="$(printf '%s' "$_line" | awk '{print $2}' | sed -E 's/^[A-Za-z]+-([0-9])/\1/')"
            runtime_obs "$_subj_base $(rel "$_d" .tool-versions) ($_k)" "$RT_VER" "$_tv"
            break
          fi
        done
      fi
      if { [ "$RT_FAM" = node ] || [ "$RT_FAM" = bun ]; } && [ -f "$_d/package.json" ]; then
        _eng="$(pkg_json "$_d/package.json" engines "$RT_FAM")"
        if [ "$_eng" = "!unreadable" ]; then
          RT_FOUND=$((RT_FOUND+1))
          unchecked "$_subj_base $(rel "$_d" package.json) engines.$RT_FAM — package.json is not valid JSON"
        elif [ -n "$_eng" ]; then
          RT_FOUND=$((RT_FOUND+1))
          runtime_obs "$_subj_base $(rel "$_d" package.json) engines.$RT_FAM" "$RT_VER" "$_eng"
        fi
      fi
      for _df in "$_d"/Dockerfile "$_d"/Dockerfile.* "$_d"/*.Dockerfile; do
        [ -f "$_df" ] || continue
        _dname="$(rel "$_d" "$(basename "$_df")")"
        while IFS= read -r _img; do
          [ -n "$_img" ] || continue
          _ref="${_img%%@*}"                                  # drop a digest
          _base="${_ref##*/}"                                 # last path segment
          _iname="${_base%%:*}"
          printf '%s' "$_iname" | grep -qE "$IMG_RE" || continue
          RT_FOUND=$((RT_FOUND+1))
          case "$_base" in
            *:*) _tag="${_base#*:}" ;;
            *)   _tag="latest" ;;
          esac
          case "$_ref" in
            *'$'*) unchecked "$_subj_base $_dname FROM $_img — image reference uses a build argument, not evaluated"; continue ;;
          esac
          runtime_obs "$_subj_base $_dname FROM $_img" "$RT_VER" "${_tag%%-*}"
        done <<EOF
$(grep -iE '^[[:space:]]*FROM[[:space:]]' "$_df" 2>/dev/null |
  sed -E 's/^[[:space:]]*[Ff][Rr][Oo][Mm][[:space:]]+//; s/--platform=[^[:space:]]+[[:space:]]+//' |
  awk '{print $1}')
EOF
      done
    done <<EOF
$RT_DIRS
EOF
    if [ "$RT_FOUND" -eq 0 ]; then
      unchecked "backend runtime $RT_NAME $RT_VER — no runtime version file found in $(printf '%s' "$RT_DIRS" | tr '\n' ' ' | sed 's/ $//') (looked for .nvmrc, .node-version, .python-version, .tool-versions, package.json engines, Dockerfile FROM)"
    fi
  fi
fi

# =============================================================================
# 5. Framework major vs the manifest dependency, per declared root
# =============================================================================

# fw_dep <layer> <framework>: "<manifest-kind> <dependency>", or nothing.
fw_dep() {
  _f="$(lc "$2")"
  case "$1" in
    web)
      case "$_f" in
        *nuxt*) echo "npm nuxt" ;;  *next*) echo "npm next" ;;
        *vue*)  echo "npm vue" ;;   *react*) echo "npm react" ;;
      esac ;;
    mobile)
      case "$_f" in
        *"react native"*|*react-native*) echo "npm react-native" ;;
        *expo*) echo "npm expo" ;;  *flutter*) echo "pub flutter" ;;
      esac ;;
    backend)
      case "$_f" in
        *nest*) echo "npm @nestjs/core" ;;  *express*) echo "npm express" ;;
        *fastify*) echo "npm fastify" ;;    *spring*) echo "jvm spring-boot" ;;
        *fastapi*) echo "py fastapi" ;;     *django*) echo "py django" ;;
      esac ;;
  esac
}

# catalog_spec <dep> <catalog-name|"">: the spec a pnpm catalog gives <dep>.
catalog_spec() {
  [ -f pnpm-workspace.yaml ] || return 0
  awk -v D="$1" -v N="$2" '
    function entry(l,   key, v) {
      sub(/^[[:space:]]+/, "", l); key = l; v = l
      sub(/[[:space:]]*:.*/, "", key); gsub(/["\047]/, "", key)
      if (key != D) return
      sub(/^[^:]*:[[:space:]]*/, "", v); sub(/[[:space:]]+#.*/, "", v); gsub(/["\047]/, "", v)
      print v; found = 1
    }
    { sub(/\r$/, "") }
    found { exit }
    /^[^[:space:]#]/ { sect = $0; sub(/:.*/, "", sect); cat = ""; next }
    sect == "catalog" && N == "" && /^  [^ #]/ { entry($0); next }
    sect == "catalogs" && /^  [^ #]/ { cat = $0; sub(/^  /, "", cat); sub(/:.*/, "", cat); gsub(/["\047]/, "", cat); next }
    sect == "catalogs" && N != "" && cat == N && /^    [^ #]/ { entry($0); next }
  ' pnpm-workspace.yaml 2>/dev/null
}

# manifest_spec <kind> <dep> <dir>: prints "<file>\t<spec>" when found; prints
# "<file>\t" when the manifest exists but does not declare the dependency;
# prints nothing when no manifest of that kind exists in <dir>.
manifest_spec() {
  _kind="$1"; _dep="$2"; _dir="$3"
  case "$_kind" in
    npm)
      [ -f "$_dir/package.json" ] || return 0
      _s="$(pkg_json "$_dir/package.json" dep "$_dep")"
      case "$_s" in
        catalog:*) _c="${_s#catalog:}"; [ "$_c" = default ] && _c=""
                   _cs="$(catalog_spec "$_dep" "$_c")"
                   [ -n "$_cs" ] && _s="$_cs (pnpm catalog)" ;;
        npm:*@*)   _s="${_s##*@}" ;;
      esac
      printf '%s\t%s\n' "$(rel "$_dir" package.json)" "$_s" ;;
    pub)
      [ -f "$_dir/pubspec.yaml" ] || return 0
      _s="$(awk '
        { sub(/\r$/, "") }
        /^environment:/ { inb = 1; next }
        inb && /^[^[:space:]#]/ { inb = 0 }
        inb && /^[[:space:]]+flutter:/ { sub(/^[[:space:]]+flutter:[[:space:]]*/, ""); gsub(/["\047]/, ""); print; exit }
      ' "$_dir/pubspec.yaml")"
      printf '%s\t%s\n' "$(rel "$_dir" pubspec.yaml)" "$_s" ;;
    jvm)
      for _g in build.gradle.kts build.gradle; do
        [ -f "$_dir/$_g" ] || continue
        _s="$(grep -oE "org\.springframework\.boot[\"']?\)?[[:space:]]+version[[:space:]]+[\"'][^\"']+[\"']" "$_dir/$_g" |
              head -1 | sed -E "s/.*version[[:space:]]+[\"']([^\"']+)[\"'].*/\1/")"
        if [ -n "$_s" ]; then printf '%s\t%s\n' "$(rel "$_dir" "$_g")" "$_s"; return 0; fi
      done
      for _t in "$_dir/gradle/libs.versions.toml" "gradle/libs.versions.toml"; do
        [ -f "$_t" ] || continue
        _s="$(awk '
          { sub(/\r$/, "") }
          /^\[/ { inv = ($0 ~ /^\[versions\]/); next }
          inv && tolower($0) ~ /^[[:space:]]*(spring-?boot|spring_boot)[[:space:]]*=/ {
            v = $0; sub(/^[^=]*=[[:space:]]*/, "", v); gsub(/"/, "", v); print v; exit
          }' "$_t")"
        if [ -n "$_s" ]; then printf '%s\t%s\n' "${_t#./}" "$_s"; return 0; fi
      done
      if [ -f "$_dir/pom.xml" ]; then
        _s="$(awk '
          /<parent>/ { inp = 1; art = ""; ver = "" }
          inp && /<artifactId>/ { a = $0; sub(/.*<artifactId>/, "", a); sub(/<\/artifactId>.*/, "", a); art = a }
          inp && /<version>/ { v = $0; sub(/.*<version>/, "", v); sub(/<\/version>.*/, "", v); ver = v }
          /<\/parent>/ { if (art == "spring-boot-starter-parent") { print ver; exit } inp = 0 }
        ' "$_dir/pom.xml")"
        printf '%s\t%s\n' "$(rel "$_dir" pom.xml)" "$_s"; return 0
      fi
      for _g in build.gradle.kts build.gradle; do
        if [ -f "$_dir/$_g" ]; then printf '%s\t\n' "$(rel "$_dir" "$_g")"; return 0; fi
      done ;;
    py)
      for _p in pyproject.toml requirements.txt; do
        [ -f "$_dir/$_p" ] || continue
        _s="$(grep -iE "(^|[\"'[:space:]])$_dep(\[[^]]*\])?[[:space:]]*(===|==|~=|>=|<=|!=|>|<)[[:space:]]*[vV]?[0-9]" "$_dir/$_p" |
              head -1 | grep -ioE "$_dep(\[[^]]*\])?[[:space:]]*(===|==|~=|>=|<=|!=|>|<)[[:space:]]*[vV]?[0-9][0-9A-Za-z.*]*" |
              head -1 | sed -E 's/^[^=~<>!]*//')"
        if [ -z "$_s" ] && [ "$_p" = pyproject.toml ]; then
          # Poetry: `fastapi = "^0.115.0"` or `fastapi = { version = "^0.115" }`
          _s="$(grep -iE "^[[:space:]]*$_dep[[:space:]]*=" "$_dir/$_p" | head -1 |
                grep -oE "\"[^\"]*[0-9][^\"]*\"" | head -1 | tr -d '"')"
        fi
        printf '%s\t%s\n' "$(rel "$_dir" "$_p")" "$_s"; return 0
      done ;;
  esac
}

FW_ANY=false
for _layer in web mobile backend; do
  _fw="$(yk "stack.layers.$_layer.framework")"
  is_none "$_fw" && continue
  FW_ANY=true
  _cv="$(strip_v "$(yk "stack.layers.$_layer.version")")"
  _map="$(fw_dep "$_layer" "$_fw")"
  _subj="$_layer framework $_fw${_cv:+ $_cv}"
  if [ -z "$_map" ]; then
    unchecked "$_subj vs manifest — no manifest mapping for this framework (mapped: next, react, vue, nuxt, @nestjs/core, express, fastify, react-native, expo, flutter, spring-boot, fastapi, django)"
    continue
  fi
  _kind="${_map%% *}"; _dep="${_map#* }"
  if [ -z "$_cv" ]; then
    unchecked "$_subj vs $_dep — no stack.layers.$_layer.version configured"
    continue
  fi
  _roots="$(layer_roots "$_layer")"
  if [ -z "$_roots" ]; then
    # No declared root: the repository root is the only candidate, and a
    # dependency it does not declare says nothing about the layer.
    _ms="$(manifest_spec "$_kind" "$_dep" ".")"
    if [ -z "$_ms" ] || [ -z "$(printf '%s' "$_ms" | cut -f2)" ]; then
      unchecked "$_subj vs $_dep — no stack.layers.$_layer.root declared, and the repository root declares no $_dep"
      continue
    fi
    _roots="."
  fi
  while IFS= read -r _r; do
    [ -n "$_r" ] || continue
    if [ ! -d "$_r" ]; then
      unchecked "$_subj vs $_dep in $_r — the declared root does not exist yet"
      continue
    fi
    _ms="$(manifest_spec "$_kind" "$_dep" "$_r")"
    if [ -z "$_ms" ]; then
      unchecked "$_subj vs $_dep in $_r — no manifest for it in that root"
      continue
    fi
    _mf="$(printf '%s' "$_ms" | cut -f1)"; _spec="$(printf '%s' "$_ms" | cut -f2)"
    if [ "$_spec" = "!unreadable" ]; then
      unchecked "$_subj vs $_dep — $_mf is not valid JSON"
      continue
    fi
    if [ -z "$_spec" ]; then
      mismatch "$_subj — $_mf does not declare $_dep"
      continue
    fi
    case "$(lc "$_spec")" in
      workspace:*|link:*|file:*|git*|http*|latest|next|canary|beta|\*|x|catalog:*)
        unchecked "$_subj vs $_mf — $_dep '$_spec' is not a version, not evaluated"; continue ;;
    esac
    _fm="$(major_of "$_spec")"; _cm="$(major_of "$_cv")"
    if [ -z "$_fm" ]; then
      unchecked "$_subj vs $_mf — $_dep '$_spec' carries no version, not evaluated"
    elif [ "$_fm" = "$_cm" ]; then
      match "$_subj — $_mf declares $_dep $_spec (line $_fm)"
    elif printf '%s' "$_spec" | grep -qE '^[[:space:]]*>' && ! printf '%s' "$_spec" | grep -q '<'; then
      # A bare lower bound admits the configured line; only the lockfile knows.
      unchecked "$_subj vs $_mf — $_dep '$_spec' is a lower bound only (line $_fm), not evaluated against configured line $_cm"
    else
      mismatch "$_subj — $_mf declares $_dep $_spec (line $_fm), configured line $_cm"
    fi
  done <<EOF
$_roots
EOF
done
if [ "$FW_ANY" = false ]; then
  unchecked "framework vs manifest dependency — no web, mobile or backend framework configured"
fi

# =============================================================================
# 6. Lockfiles vs stack.package_manager
# =============================================================================

JS_LOCKS="pnpm-lock.yaml package-lock.json npm-shrinkwrap.json yarn.lock bun.lock bun.lockb"
PY_LOCKS="uv.lock poetry.lock pdm.lock Pipfile.lock"

ALL_ROOT_DIRS="$(
  { printf '.\n'
    for _l in web mobile backend cloud; do layer_roots "$_l"; done
    shared_roots
  } | grep -v '^$' | awk '!seen[$0]++'
)"

# locks_present <names>: "<dir>/<file>" for every listed lockfile on disk.
locks_present() {
  while IFS= read -r _d; do
    [ -d "$_d" ] || continue
    for _n in $1; do
      [ -f "$_d/$_n" ] && rel "$_d" "$_n" && printf '\n'
    done
  done <<EOF
$ALL_ROOT_DIRS
EOF
}

PM="$(lc "$(trim "$(yk stack.package_manager)")")"
if [ -z "$PM" ]; then
  unchecked "lockfile vs stack.package_manager — stack.package_manager not configured"
else
  EXPECT=""; ECO=""
  case "$PM" in
    pnpm)   EXPECT="pnpm-lock.yaml"; ECO=js ;;
    npm)    EXPECT="package-lock.json npm-shrinkwrap.json"; ECO=js ;;
    yarn)   EXPECT="yarn.lock"; ECO=js ;;
    bun)    EXPECT="bun.lock bun.lockb"; ECO=js ;;
    uv)     EXPECT="uv.lock"; ECO=py ;;
    poetry) EXPECT="poetry.lock"; ECO=py ;;
    pdm)    EXPECT="pdm.lock"; ECO=py ;;
    pipenv) EXPECT="Pipfile.lock"; ECO=py ;;
    gradle) EXPECT="gradle.lockfile" ;;
    cargo)  EXPECT="Cargo.lock" ;;
    go)     EXPECT="go.sum" ;;
    composer) EXPECT="composer.lock" ;;
    bundler)  EXPECT="Gemfile.lock" ;;
    pub|flutter) EXPECT="pubspec.lock" ;;
    cocoapods)   EXPECT="Podfile.lock" ;;
    swiftpm|spm) EXPECT="Package.resolved" ;;
    pip|maven)   EXPECT="-" ;;
  esac
  if [ -z "$EXPECT" ]; then
    unchecked "lockfile vs stack.package_manager — no lockfile mapping for '$PM'"
  elif [ "$EXPECT" = "-" ]; then
    unchecked "lockfile vs stack.package_manager — $PM has no lockfile convention"
  else
    _found="$(locks_present "$EXPECT" | grep -v '^$')"
    _dirs="$(printf '%s' "$ALL_ROOT_DIRS" | tr '\n' ' ' | sed 's/ $//')"
    if [ -n "$_found" ]; then
      match "stack.package_manager $PM — $(printf '%s' "$_found" | tr '\n' ' ' | sed 's/ $//') present"
    elif [ "$PM" = gradle ]; then
      unchecked "stack.package_manager gradle — no gradle.lockfile in $_dirs (Gradle dependency locking is not enabled)"
    else
      unchecked "stack.package_manager $PM — no $EXPECT in $_dirs (dependencies not installed yet, or the lockfile is not committed)"
    fi
    case "$ECO" in
      js) _rivals="$JS_LOCKS" ;;
      py) _rivals="$PY_LOCKS" ;;
      *)  _rivals="" ;;
    esac
    if [ -n "$_rivals" ]; then
      for _e in $EXPECT; do _rivals="$(printf '%s' " $_rivals " | sed "s/ $_e / /g")"; done
      _other="$(locks_present "$_rivals" | grep -v '^$')"
      while IFS= read -r _o; do
        [ -n "$_o" ] || continue
        mismatch "stack.package_manager $PM — $_o belongs to another package manager"
      done <<EOF
$_other
EOF
    fi
    if [ "$ECO" = js ] && [ -f package.json ]; then
      _pmf="$(pkg_json package.json pm)"
      if [ "$_pmf" = "!unreadable" ]; then
        unchecked "stack.package_manager $PM vs package.json packageManager — package.json is not valid JSON"
      elif [ -z "$_pmf" ]; then
        unchecked "stack.package_manager $PM vs package.json packageManager — the field is not set"
      elif [ "$(lc "${_pmf%%@*}")" = "$PM" ]; then
        match "stack.package_manager $PM — package.json packageManager is $_pmf"
      else
        mismatch "stack.package_manager $PM — package.json packageManager is $_pmf"
      fi
    fi
  fi
fi

# =============================================================================
# 7. commands.* that name package scripts vs package.json scripts
# =============================================================================

# Every configured command as "<label>\t<command>": a string field, or each key
# of an OS map (default / linux / macos / windows). The fields are the keys that
# are actually present under `commands:` — derived, not a hand-kept list, so a
# field added to the schema is checked without editing this script.
child_keys() {
  if command -v get_yaml_child_keys >/dev/null 2>&1; then
    { get_yaml_child_keys "$YAML" "$1" 2>/dev/null; printf '\n'; } | grep -v '^$'
  fi
}
CMDS=""
CMD_FIELDS="$(child_keys commands)"
if [ -z "$CMD_FIELDS" ] && grep -qE '^commands:' project.yaml 2>/dev/null &&
   ! command -v get_yaml_child_keys >/dev/null 2>&1; then
  unchecked "commands.* vs package.json scripts — yaml-helper.sh has no get_yaml_child_keys; the commands block cannot be enumerated"
  finish
fi
for _f in $CMD_FIELDS; do
  _v="$(yk "commands.$_f")"
  if [ -n "$_v" ]; then
    CMDS="${CMDS}commands.$_f${TAB}$_v${NL}"
  else
    for _os in $(child_keys "commands.$_f"); do
      _v="$(yk "commands.$_f.$_os")"
      [ -n "$_v" ] && CMDS="${CMDS}commands.$_f.$_os${TAB}$_v${NL}"
    done
  fi
done

# script_refs <command>: one line per package-script reference,
#   "<class>\t<pm>\t<selector-kind>\t<selector>\t<script>"
# class: explicit (a missing script fails the command) | ambiguous (the manager
# falls back to a binary of that name) | recursive | ifpresent | turbo.
script_refs() {
  printf '%s\n' "$1" | awk '
    BEGIN {
      pnpm_b = " add audit bin c config create dedupe deploy dlx doctor env exec fetch help i import init install install-test it link list ll ls outdated pack patch patch-commit patch-remove prune publish rb rebuild remove rm root server setup store un uninstall unlink up update why licenses self-update approve-builds ignored-builds "
      yarn_b = " add audit autoclean bin cache check config constraints create dedupe dlx exec explain generate-lock-entry global help import info init install licenses link list login logout node npm outdated owner pack patch plugin policies publish rebuild remove search set stage tag team unlink unplug up upgrade version why workspaces "
      bun_b  = " add build create exec i init install link outdated patch pm publish remove repl rm test update upgrade x "
    }
    # Empty fields print as "-": a tab is IFS whitespace, so `read` would
    # collapse two adjacent tabs and shift every later field.
    function emit(cls, pm, sk, sv, sc) {
      if (sv == "") sv = "-"
      if (sc == "") sc = "-"
      print cls "\t" pm "\t" sk "\t" sv "\t" sc
    }
    {
      n = split($0, seg, /&&|\|\||;|\|/)
      for (s = 1; s <= n; s++) {
        m = split(seg[s], t, /[[:space:]]+/)
        i = 1
        while (i <= m && (t[i] == "" || t[i] ~ /^[A-Za-z_][A-Za-z0-9_]*=/)) i++   # env assignments
        if (i > m) continue
        pm = t[i]; sub(/\.cmd$/, "", pm); i++
        if (pm != "pnpm" && pm != "npm" && pm != "yarn" && pm != "bun") {
          if (pm == "turbo" || pm == "nx") emit("turbo", pm, "", "", "")
          continue
        }
        sk = "root"; sv = ""; rec = 0; ifp = 0
        # yarn workspace <name> <rest>
        if (pm == "yarn" && t[i] == "workspace") { sk = "name"; sv = t[i+1]; i += 2 }
        if (pm == "yarn" && t[i] == "workspaces") { rec = 1; i++ }
        while (i <= m && t[i] ~ /^-/) {
          o = t[i]
          if (o ~ /^--filter=/ || o ~ /^--workspace=/) { v = o; sub(/^[^=]*=/, "", v); sk = "sel"; sv = v; i++; continue }
          if (o == "--filter" || o == "-F" || o == "--workspace" || (pm == "npm" && o == "-w")) { sk = "sel"; sv = t[i+1]; i += 2; continue }
          if (o == "-C" || o == "--dir" || o == "--prefix") { sk = "path"; sv = t[i+1]; i += 2; continue }
          if (o == "-r" || o == "--recursive" || o == "-ws" || o == "--workspaces") { rec = 1; i++; continue }
          if (pm == "pnpm" && (o == "-w" || o == "--workspace-root")) { sk = "root"; sv = ""; i++; continue }
          if (o == "--if-present") { ifp = 1; i++; continue }
          i++
        }
        if (i > m) continue
        sub_ = t[i]; i++
        if (sub_ == "turbo" || sub_ == "nx") { emit("turbo", pm, "", "", ""); continue }
        cls = ""; sc = ""
        if (sub_ == "run" || sub_ == "run-script" || sub_ == "rum" || sub_ == "urn") {
          while (i <= m && t[i] ~ /^-/) { if (t[i] == "--if-present") ifp = 1; i++ }
          if (i > m) continue
          sc = t[i]
          cls = (pm == "bun") ? "ambiguous" : "explicit"
          if (pm == "bun" && sc ~ /(\/|\.(ts|tsx|js|jsx|mjs|cjs)$)/) continue
        } else if (sub_ == "test" || sub_ == "t" || sub_ == "tst" || sub_ == "start" || sub_ == "stop" || sub_ == "restart") {
          if (pm == "bun") continue                      # `bun test` is the built-in runner
          if (sub_ == "t" || sub_ == "tst") sub_ = "test"
          sc = sub_; cls = "explicit"
        } else if (pm == "npm") {
          continue                                       # every other npm word is built in
        } else if ((pm == "pnpm" && index(pnpm_b, " " sub_ " ")) || (pm == "yarn" && index(yarn_b, " " sub_ " ")) || (pm == "bun" && index(bun_b, " " sub_ " "))) {
          continue
        } else {
          sc = sub_; cls = "ambiguous"
        }
        if (rec) cls = "recursive"
        else if (ifp) cls = "ifpresent"
        emit(cls, pm, sk, sv, sc)
      }
    }
  '
}

if [ -z "$CMDS" ]; then
  unchecked "commands.* vs package.json scripts — no commands declared in project.yaml"
else
  # Index every package.json near the root once: "<path>\t<name>\t<scripts>".
  PKG_FILES="$(find . -maxdepth 4 -name package.json -not -path '*/node_modules/*' -not -path './.git/*' 2>/dev/null | sed 's#^\./##' | sort)"
  PKG_INDEX=""
  if [ -n "$PKG_FILES" ]; then
    # shellcheck disable=SC2086
    PKG_INDEX="$(printf '%s\n' "$PKG_FILES" | { set --; while IFS= read -r _p; do set -- "$@" "$_p"; done; pkg_index "$@"; })"
  fi

  while IFS="$TAB" read -r _label _cmd; do
    [ -n "$_label" ] || continue
    _refs="$(script_refs "$_cmd")"
    if [ -z "$_refs" ]; then
      unchecked "$_label — names no package script, not checked ($_cmd)"
      continue
    fi
    while IFS="$TAB" read -r _cls _pm _sk _sv _sc; do
      [ -n "$_cls" ] || continue
      [ "$_sv" = "-" ] && _sv=""
      [ "$_sc" = "-" ] && _sc=""
      case "$_cls" in
        turbo)     unchecked "$_label — runs a $_pm task, not a package script ($_cmd)"; continue ;;
        recursive) unchecked "$_label — '$_sc' runs recursively across workspace packages, not evaluated ($_cmd)"; continue ;;
        ifpresent) unchecked "$_label — '$_sc' runs with --if-present, so a missing script is allowed ($_cmd)"; continue ;;
      esac
      # Resolve the package.json the reference means.
      _pkg=""; _why=""
      case "$_sk" in
        root) _pkg="package.json" ;;
        path) _pkg="$(printf '%s' "$_sv" | sed -E 's#^\./##; s#/+$##')/package.json" ;;
        name|sel)
          _s="$(printf '%s' "$_sv" | sed -E "s/^[\"']//; s/[\"']\$//; s/^\\^?\\.\\.\\.//; s/\\.\\.\\.\$//; s/^\\{//; s/\\}\$//")"
          case "$_s" in
            *'*'*) _why="selector '$_sv' is a pattern" ;;
            ./*|../*) _pkg="$(printf '%s' "$_s" | sed -E 's#^\./##; s#/+$##')/package.json" ;;
            *)
              _pkg="$(printf '%s\n' "$PKG_INDEX" | awk -F'\t' -v N="$_s" '$2 == N { print $1; exit }')"
              # The scope is optional in a pnpm filter: `web` selects `@moa/web`
              # when exactly one scoped package has that name.
              if [ -z "$_pkg" ] && [ "$_pm" = pnpm ]; then
                _pkg="$(printf '%s\n' "$PKG_INDEX" | awk -F'\t' -v N="$_s" '
                  { n = $2; sub(/^@[^\/]+\//, "", n) } $2 ~ /^@/ && n == N { c++; p = $1 }
                  END { if (c == 1) print p }')"
              fi
              if [ -z "$_pkg" ] && [ -f "$_s/package.json" ]; then _pkg="$_s/package.json"; fi
              [ -z "$_pkg" ] && _why="selector '$_sv' matches no package.json name or path" ;;
          esac ;;
      esac
      if [ -z "$_pkg" ]; then
        unchecked "$_label — script '$_sc': ${_why:-package not resolved} ($_cmd)"; continue
      fi
      if [ ! -f "$_pkg" ]; then
        unchecked "$_label — script '$_sc': $_pkg not found ($_cmd)"; continue
      fi
      _entry="$(printf '%s\n' "$PKG_INDEX" | awk -F'\t' -v P="$_pkg" '$1 == P { print "y" $3; exit }')"
      if [ -z "$_entry" ]; then
        unchecked "$_label — script '$_sc': $_pkg is not valid JSON or lies outside the indexed depth ($_cmd)"; continue
      fi
      _scripts="${_entry#y}"
      case ",$_scripts," in
        *",$_sc,"*) match "$_label — script '$_sc' exists in $_pkg" ;;
        *)
          if [ "$_cls" = explicit ]; then
            mismatch "$_label — script '$_sc' is not defined in $_pkg ($_cmd)"
          else
            unchecked "$_label — '$_sc' is not a script in $_pkg; $_pm runs it as a binary of that name if one is installed ($_cmd)"
          fi ;;
      esac
    done <<EOF
$_refs
EOF
  done <<EOF
$CMDS
EOF
fi

finish
