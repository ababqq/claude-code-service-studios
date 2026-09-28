#!/bin/bash
# Hook helper: yaml-helper.sh
# Purpose: Shared YAML reading helper for CCSS hooks, scripts and skill orchestrators.
# Cross-platform: Windows Git Bash compatible; bash 3.2 (macOS) compatible.
#
# Provides (sourced):
#   get_yaml_key <file> <dotted.path>
#     Prints the scalar value at <dotted.path> in <file>, or empty string if:
#       - the file does not exist or is unreadable
#       - the path does not exist in the YAML
#       - the path resolves to a sub-map or a block list (caller wanted a scalar)
#       - no Python interpreter is available
#     A flow list comes back as its raw text (`[web, ios]`, `[]`) -- which is how
#     a caller detects set-but-empty (`[]`) before any array parsing.
#     Always exits 0 — callers can safely use it under `set -e`.
#
#   get_yaml_array <file> <dotted.path>
#     Prints array values one per line. Handles both inline [a, b, c]
#     and block-dash forms (- a / - b on subsequent indented lines).
#     Empty output if not an array, not found, or file missing. NOTE: `[]` and
#     "absent" both print nothing here; when the difference matters, check the
#     raw value with get_yaml_key first (see "Array-element enums" below).
#
#   get_effective_yaml_key <dotted.path>
#   get_effective_yaml_array <dotted.path>
#     Convenience wrappers that read project.local.yaml first -- ONLY for keys
#     on the local whitelist -- then fall back to project.yaml. Per-leaf
#     override (local wins), so the effective config has deep-merge semantics
#     across leaves. No enum validation and no provenance: use resolve_setting
#     for any enum-typed key.
#
#   get_yaml_child_keys <file> <dotted.path>
#     Child key names of a mapping node, one per line.
#
#   get_yaml_default <dotted.path>
#     The terminal default for a key, or '' when it has none.
#
#   validate_yaml_enum <file>
#     Validates every enum-typed scalar key (_yaml_helper_enums) and every
#     array-element enum key (_yaml_helper_array_enums) present in <file>.
#     Prints one error line per invalid value or dropped element to stderr.
#     Returns 1 if anything was invalid, 0 otherwise. Also reports
#     tab-indented lines, which the parser cannot see.
#
#   validate_enum_value <dotted.path> <value>
#     Single-key version of validate_yaml_enum — for /settings to check a
#     pending write before committing it to disk. Array-element enum keys
#     accept `a,b` or `[a, b]`; every element is checked and ONE invalid
#     element rejects the whole write. Returns 0 if the key has no enum
#     constraint OR the value is valid; 1 (with error on stderr) otherwise.
#
#   validate_local_yaml_base
#     Hard-error guard: project.local.yaml requires a project.yaml base.
#     Returns 1 with error on stderr if local exists without base.
#
#   is_locally_overridable <dotted.path>
#     Whitelist check for the /settings --local flag. Returns 0 if the setting
#     is on the personal-experience whitelist (_yaml_helper_locally_overridable),
#     1 otherwise. Locked settings cannot be locally overridden because they
#     affect on-disk artifacts.
#
#   validate_local_scope [<file>]
#     Names keys in project.local.yaml that are NOT locally overridable, which
#     resolution ignores. One line per key on stderr; returns 1 if any found.
#
#   is_always_ask_category <category>
#     Membership check on modes.automation_always_ask. Returns 0 if the
#     category is in the configured list (or in the default list when unset),
#     1 otherwise. Skills use this in autonomous mode to know when to prompt
#     anyway. Default list: _yaml_helper_always_ask_default.
#
#   log_decision <skill> <point> <options> <chosen> <reason> <category>
#     Append a decision-log entry to production/session-logs/decision-log.md.
#
#   session_state_enabled
#     0 unless features.session_state is literally `off`.
#
#   resolve_setting <dotted.path>
#     "<value>\t<source>" through the full chain (see below).
#
#   resolve_config [--keys l1,l2,...] [<feature>]
#     The resolved-config block a skill reads instead of re-deriving anything.
#
#   resolve_code_roots
#     One line per code root: "<dir>\t<layer>\t<source>". Nothing when
#     unresolved. Never defaults to `src`.
#
#   list_code_files [--limit N]
#     Every source file under the scannable code roots, pruned, one per line.
#
#   code_extensions
#     Space-separated source-file extensions derived from the configured stack.
#
# Only resolve_config is reachable by direct execution (see the bottom of this
# file); every other function is for callers that `source` it.
#
# Python fallback chain: python -> python3 -> py
# Parses a YAML subset: nested maps + scalar leaves + arrays + comments
# + quoted strings. PyYAML is NOT required.
#
# Usage:
#   source .claude/hooks/yaml-helper.sh
#   review_mode=$(resolve_setting modes.review_mode | cut -f1)   # e.g. solo
#   code_dirs=$(resolve_code_roots | cut -f1)                     # one dir per line

# Resolve a working Python interpreter once per shell, cache the result.
_yaml_helper_python=""
_yaml_helper_resolve_python() {
  if [ -n "$_yaml_helper_python" ]; then return 0; fi
  for candidate in python python3 py; do
    if command -v "$candidate" >/dev/null 2>&1; then
      # Require Python 3 — the parser uses py3-only open(encoding=) kwargs.
      if "$candidate" -c "import sys; sys.exit(0 if sys.version_info[0] >= 3 else 1)" >/dev/null 2>&1; then
        _yaml_helper_python="$candidate"
        return 0
      fi
    fi
  done
  return 1
}

get_yaml_key() {
  local file="${1:-}"
  local path="${2:-}"
  if [ -z "$file" ] || [ -z "$path" ]; then return 0; fi
  if [ ! -f "$file" ]; then return 0; fi
  if ! _yaml_helper_resolve_python; then
    echo "yaml-helper: no python interpreter found (tried python, python3, py)" >&2
    return 0
  fi
  "$_yaml_helper_python" - "$file" "$path" <<'PYEOF'
import sys, re

path_file, dotted = sys.argv[1], sys.argv[2]
keys = dotted.split('.')

def parse(lines):
    root = {}
    stack = [(-1, root)]  # (indent, mapping)
    for raw in lines:
        line = raw.rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            continue
        indent = len(line) - len(stripped)
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', stripped)
        if not m:
            continue
        key = m.group(1).strip()
        value = m.group(2).strip()
        # Resolve the scalar: handle comment-only, quoted, and inline-comment forms.
        if value.startswith('#'):
            value = ''
        elif value[:1] in ('"', "'"):
            quote = value[0]
            end = value.find(quote, 1)
            if end >= 0:
                value = value[1:end]   # quoted content; any trailing comment ignored
            else:
                value = value[1:]      # unterminated quote — take the remainder
        else:
            hash_pos = value.find(' #')
            if hash_pos >= 0:
                value = value[:hash_pos].strip()
        if value == '':
            new_map = {}
            parent[key] = new_map
            stack.append((indent, new_map))
        else:
            parent[key] = value
    return root

try:
    with open(path_file, 'r', encoding='utf-8-sig', errors='replace') as f:
        data = parse(f.readlines())
except OSError:
    sys.exit(0)

cur = data
for k in keys:
    if isinstance(cur, dict) and k in cur:
        cur = cur[k]
    else:
        sys.exit(0)

if isinstance(cur, dict):
    sys.exit(0)

# Write raw UTF-8 bytes — bypasses the platform stdout encoding (cp1252 on
# Windows) so unicode values round-trip intact.
sys.stdout.buffer.write(str(cur).encode('utf-8'))
PYEOF
}

# -----------------------------------------------------------------------------
# Array reads, effective (deep-merged) reads, enum validation
# -----------------------------------------------------------------------------

get_yaml_array() {
  local file="${1:-}"
  local path="${2:-}"
  if [ -z "$file" ] || [ -z "$path" ]; then return 0; fi
  if [ ! -f "$file" ]; then return 0; fi
  if ! _yaml_helper_resolve_python; then
    echo "yaml-helper: no python interpreter found (tried python, python3, py)" >&2
    return 0
  fi
  "$_yaml_helper_python" - "$file" "$path" <<'PYEOF'
import sys, re

path_file, dotted = sys.argv[1], sys.argv[2]
keys = dotted.split('.')

# Parser extended to recognize two YAML array forms:
#   key: [a, b, c]                     (inline)
#   key:                               (block-dash)
#     - a
#     - b
# Block-dash detection peeks ahead at indented child lines after a key
# whose own value is empty; if those children start with "- ", they form
# an array, otherwise they form a sub-map (existing behavior).
def parse(lines):
    root = {}
    stack = [(-1, root)]
    i = 0
    while i < len(lines):
        raw = lines[i]
        line = raw.rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            i += 1
            continue
        indent = len(line) - len(stripped)
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', stripped)
        if not m:
            i += 1
            continue
        key = m.group(1).strip()
        value = m.group(2).strip()
        if value.startswith('#'):
            value = ''
        elif value[:1] == '[':
            # Inline array, scanned with QUOTE AWARENESS.
            #
            # A comma or a closing bracket inside a quoted element is DATA, not
            # a delimiter. Splitting on every comma turns one quoted entry that
            # contains commas into several bogus ones -- and because each shard
            # is a plausible-looking string, nothing downstream can tell that it
            # happened. Values written from hand-authored prose hit this
            # routinely.
            parts = []
            buf = ''
            quote = None
            idx = 1
            while idx < len(value):
                ch = value[idx]
                if quote is not None:
                    if ch == quote:
                        quote = None
                    else:
                        buf += ch
                elif ch in ('"', "'"):
                    quote = ch
                elif ch == ']':
                    break
                elif ch == ',':
                    parts.append(buf.strip())
                    buf = ''
                else:
                    buf += ch
                idx += 1
            if buf.strip():
                parts.append(buf.strip())
            parent[key] = [p for p in parts if p != '']
            i += 1
            continue
        elif value[:1] in ('"', "'"):
            quote = value[0]
            end = value.find(quote, 1)
            if end >= 0:
                value = value[1:end]
            else:
                value = value[1:]
        else:
            hash_pos = value.find(' #')
            if hash_pos >= 0:
                value = value[:hash_pos].strip()
        if value == '':
            # Peek: block-dash list or sub-map?
            j = i + 1
            items = []
            while j < len(lines):
                pl = lines[j].rstrip('\n').rstrip('\r')
                pstripped = pl.lstrip(' ')
                if not pstripped.strip() or pstripped.lstrip().startswith('#'):
                    j += 1
                    continue
                pindent = len(pl) - len(pstripped)
                if pindent <= indent:
                    break
                if pstripped.startswith('- '):
                    # INDENT IS NOT ENFORCED between items, deliberately.
                    #
                    # Requiring every item to sit at the first item's indent
                    # made ONE misindented entry end the list there and return
                    # the prefix, silently: three configured always-ask
                    # categories came back as one. `is_always_ask_category`
                    # compares exactly, so the dropped entries lost their
                    # prompt with nothing written anywhere -- and a partial
                    # list is non-empty, so the caller's "fall back to the
                    # defaults when unset" branch does not fire either. It
                    # failed toward LESS confirmation, which is the wrong
                    # direction for the setting that decides when to ask.
                    #
                    # Safe because this schema holds only flat scalar lists:
                    # any deeper `- ` line under the key is an item of it. A
                    # non-dash line still ends the list via the break below,
                    # so a sub-map after a list is unaffected.
                    item = pstripped[2:].strip()
                    if item[:1] in ('"', "'") and item[-1:] == item[:1] and len(item) >= 2:
                        item = item[1:-1]
                    else:
                        # Unquoted items take the same trailing-comment rule
                        # scalars take. Without it `- scope_changes  # ask`
                        # parsed as the literal string INCLUDING the comment
                        # and matched no category -- the same silent loss as
                        # above, reached a different way. Quoted items are
                        # left alone: a `#` inside quotes is data.
                        hash_pos = item.find(' #')
                        if hash_pos >= 0:
                            item = item[:hash_pos].strip()
                    items.append(item)
                    j += 1
                    continue
                break
            if items:
                parent[key] = items
                i = j
                continue
            else:
                new_map = {}
                parent[key] = new_map
                stack.append((indent, new_map))
        else:
            parent[key] = value
        i += 1
    return root

try:
    with open(path_file, 'r', encoding='utf-8-sig', errors='replace') as f:
        data = parse(f.readlines())
except OSError:
    sys.exit(0)

cur = data
for k in keys:
    if isinstance(cur, dict) and k in cur:
        cur = cur[k]
    else:
        sys.exit(0)

if not isinstance(cur, list):
    sys.exit(0)

for item in cur:
    sys.stdout.buffer.write((str(item) + '\n').encode('utf-8'))
PYEOF
}

# --- project root resolution -------------------------------------------------
#
# Config paths must NOT be resolved against the bare current working directory.
# Run a skill or hook from a subdirectory that way and project.yaml is
# unfindable, so EVERY setting resolves to empty -- silently, because the guard
# that reports a missing base cannot find its files either. From the repo root
# `modes.rigor` returns `full`; from `apps/web/` it would return nothing.
#
# Being loadable from anywhere is only half the problem: the helper must also be
# able to do its job from anywhere. Fixing one without the other leaves it
# sourceable everywhere and functional only at the root.
#
# PRECEDENCE IS LOAD-BEARING, in this order:
#   1. cwd holds project.yaml         -> cwd
#   2. cwd holds project.local.yaml   -> cwd
#   3. CLAUDE_PROJECT_DIR has a base  -> that directory
#   4. nothing found                  -> cwd (unchanged behaviour)
#
# AN UPWARD WALK WAS IMPLEMENTED AND REMOVED, and the reason is worth keeping.
# The intent was a fallback needing no environment variable: climb until an
# ancestor has project.yaml. It resolves the wrong tree. An unconfigured project
# (no project.yaml yet) sitting anywhere below another project would read the
# OUTER project's project.yaml and project.local.yaml as its own -- the wrong
# answer, returned silently. Any real project nested inside another repo that
# happens to carry a project.yaml would inherit the outer project's settings,
# which is the same silent-wrong-answer class this whole fix exists to remove.
# A fallback that guesses is worse than one that is absent: rule 4 leaves an
# unconfigured directory resolving to defaults and saying so on `notes:`, which
# is exactly what a project without project.yaml should see.
#
# CLAUDE_PROJECT_DIR is populated in both the hook environment and the
# skill-bootstrap environment, so rule 3 covers every way this framework
# actually invokes the helper.
#
# 1 and 2 come FIRST deliberately. A project nested inside another one must read
# ITSELF, and an ambient CLAUDE_PROJECT_DIR would otherwise point it at the
# outer tree. Rule 2 covers the case that is easiest to lose: a directory with a
# project.local.yaml and deliberately NO base must still raise the hard error
# for a missing base. Without it, an upward walk finds an ancestor's
# project.yaml and that error silently stops firing.
#
# Sets a variable rather than echoing a path: a $( ) per lookup would add a
# subshell to every lookup in the chain, and per-lookup cost of that kind is
# what pushes a hook past its 10s timeout.
_yaml_helper_set_root() {
  _YH_ROOT="."
  [ -f "$_YH_ROOT/project.yaml" ] && return 0
  [ -f "$_YH_ROOT/project.local.yaml" ] && return 0
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -f "$CLAUDE_PROJECT_DIR/project.yaml" ]; then
    _YH_ROOT="$CLAUDE_PROJECT_DIR"; return 0
  fi
  return 0
}

# Guard: project.local.yaml requires a project.yaml base. The local file has
# no meaning without a base — it only overrides values from project.yaml.
# Prints a hard-error message to stderr and returns 1 if the orphan case is
# detected. Returns 0 otherwise (including when neither file exists).
validate_local_yaml_base() {
  _yaml_helper_set_root
  if [ -f "$_YH_ROOT/project.local.yaml" ] && [ ! -f "$_YH_ROOT/project.yaml" ]; then
    echo "project.local.yaml exists but project.yaml is missing — run /start to create one. Local overrides require a base." >&2
    return 1
  fi
  return 0
}

# Per-leaf deep-merge: read project.local.yaml first (if present AND the key
# is on the local read scope), fall back to project.yaml. Each leaf is
# resolved independently from its own file, so sibling keys at the same
# nesting level come through from project.yaml when project.local.yaml only
# overrides specific leaves.
#
# The whitelist gate is the same one resolve_setting applies. Without it these
# wrappers were a side door: a locked key hand-written into project.local.yaml
# (a performance budget, a stack component) won here while resolve_setting,
# /settings and the notes line all said it was ignored.
get_effective_yaml_key() {
  _yaml_helper_set_root
  local path="${1:-}"
  if [ -z "$path" ]; then return 0; fi
  local val=""
  if [ -f "$_YH_ROOT/project.local.yaml" ] && _yaml_helper_in_local_read_scope "$path"; then
    val=$(get_yaml_key "$_YH_ROOT/project.local.yaml" "$path")
  fi
  if [ -z "$val" ] && [ -f "$_YH_ROOT/project.yaml" ]; then
    val=$(get_yaml_key "$_YH_ROOT/project.yaml" "$path")
  fi
  printf '%s' "$val"
}

get_effective_yaml_array() {
  _yaml_helper_set_root
  local path="${1:-}"
  if [ -z "$path" ]; then return 0; fi
  local val=""
  if [ -f "$_YH_ROOT/project.local.yaml" ] && _yaml_helper_in_local_read_scope "$path"; then
    val=$(get_yaml_array "$_YH_ROOT/project.local.yaml" "$path")
  fi
  if [ -z "$val" ] && [ -f "$_YH_ROOT/project.yaml" ]; then
    val=$(get_yaml_array "$_YH_ROOT/project.yaml" "$path")
  fi
  printf '%s' "$val"
}

# Enum constants — every scalar setting whose values are constrained to a
# fixed set (effects-map.md carries a matching `**Values:**` line for each,
# under the key's own `## <key>` heading or its group heading, e.g.
# `## workflow_overrides` for the three workflow_overrides.* booleans).
# Format: dotted.path::value1|value2|...
# Validation: walk this list; for each key present in the file, verify the
# value is in the allowed set. An out-of-set value never wins: resolve_setting
# drops it and the chain continues, and resolve_config names it on `notes:`.
_yaml_helper_enums="\
modes.review_mode::full|lean|solo
modes.rigor::minimal|standard|full
modes.workflow::minimal|standard|full
modes.automation::collaborative|guided|autonomous
modes.story_granularity::coarse|balanced|fine
docs.density::terse|balanced|thorough
qa.level::minimal|standard|full
team.size::individual|small|studio
performance.enforce::warn|block|off
release.distribution::web|stores|web+stores|enterprise|internal
accessibility.target::none|wcag-a|wcag-aa|wcag-aaa
project.stage::Discovery|Definition|Architecture|Validation|Build|Hardening|Launch
testing.strict.logic::true|false
testing.strict.integration::true|false
testing.strict.ui::true|false
testing.strict.e2e::true|false
testing.strict.config::true|false
features.session_state::on|off
privacy.handles_pii::true|false
stack.monorepo::true|false
workflow_overrides.edge_cases::true|false
workflow_overrides.config_flags::true|false
workflow_overrides.design_language_strict::true|false"
# The boolean keys above are enumerated for the same reason the string keys are:
# `resolve_setting` validates every hop and DROPS a value that fails, so a key
# absent from this table accepts anything. Unlisted, `testing.strict.logic:
# maybe` in project.local.yaml would pass validation and win over an explicit
# `true` in project.yaml -- and `/story-done` treats the gate as BLOCKING only
# when the value is `true`, so a typo would silently downgrade a blocking test
# gate to advisory with no error. The same holds for `privacy.handles_pii`,
# where a typo must surface as "unset -- ask", never as a silent `false`.
# Any NEW boolean setting must be added here too.
#
# Two shapes deliberately NOT listed as `true|false`:
#   - `features.session_state` is an ON/OFF enum, not a boolean. It is listed
#     above as `on|off` because `session_state_enabled()` disables only on the
#     literal `off`, and effects-map documents `on`/`off`. Writing `false` there
#     means ENABLED, which is why validating it matters.
#   - `testing.strict` (the parent) is absent because its only shape is a MAP of
#     the five type keys. The `**Values:**` line under effects-map.md
#     `## testing.strict` documents the map;
#     the five leaves above carry the validation, which is where /story-done
#     reads.

# Array-element enums — list-valued settings whose ELEMENTS are constrained.
#
# These never go through the scalar table above: `platform.surfaces: [web, ios]`
# read as a scalar is the raw text "[web, ios]", which matches no scalar value,
# so the whole list would be rejected and the key would resolve to unset. They
# are parsed with the get_yaml_array parser (flow `[a, b]` and block lists) and
# checked ELEMENT BY ELEMENT: an invalid element is dropped and named on
# `notes:` (`platform.surfaces: dropped invalid element 'iso' ...`); the valid
# rest survives. A scalar written where the list belongs counts as a
# one-element list.
#
# SET-BUT-EMPTY IS NOT UNSET. A raw value of exactly `[]` is detected before any
# array parsing (get_yaml_array prints nothing for both `[]` and "absent").
# For `compliance.regions` it means "explicitly none" and prints `regions=none`;
# for the keys in _yaml_helper_array_nonempty it is invalid -- a product ships
# at least one surface -- so it is noted and treated as unset.
_yaml_helper_array_enums="\
platform.surfaces::web|ios|android|api
compliance.regions::kr|eu|us"

# Array-element enum keys for which `[]` is invalid (see above).
_yaml_helper_array_nonempty="platform.surfaces"

# Allowed-element string ("a|b|c") of an array-element enum key, or ''.
_yaml_helper_array_allowed() {
  local key="${1:-}" line
  [ -z "$key" ] && return 0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [ "${line%%::*}" = "$key" ]; then printf '%s' "${line#*::}"; return 0; fi
  done <<EOF
$_yaml_helper_array_enums
EOF
  return 0
}

_yaml_helper_array_requires_element() {
  local key="${1:-}" entry
  [ -z "$key" ] && return 1
  for entry in $_yaml_helper_array_nonempty; do
    [ "$entry" = "$key" ] && return 0
  done
  return 1
}

#   validate_local_scope [<file>]
#     The location check the value checks above cannot do: names keys in
#     project.local.yaml that are NOT locally overridable, which resolution
#     silently ignores. One line per key on stderr; returns 1 if any found.
#     Warns, never reconciles. Defined below is_locally_overridable.

# Whitelist of locally-overridable settings (effects-map.md § "Local Override
# Pattern"). Personal-experience settings only — divergence between developers
# is safe because they don't affect what artifacts exist on disk.
_yaml_helper_locally_overridable="\
modes.review_mode
modes.automation
modes.automation_always_ask
team.size
testing.strict.logic
testing.strict.integration
testing.strict.ui
testing.strict.e2e
testing.strict.config
performance.enforce
features.session_state
features.token_budget_warn_at"

is_locally_overridable() {
  local path="${1:-}"
  [ -z "$path" ] && return 1
  local whitelisted
  while IFS= read -r whitelisted; do
    [ -z "$whitelisted" ] && continue
    if [ "$path" = "$whitelisted" ]; then return 0; fi
  done <<EOF
$_yaml_helper_locally_overridable
EOF
  return 1
}

# validate_local_scope [<file>]
#   Names the keys in project.local.yaml that resolution will NEVER read,
#   because they are not on the whitelist above. One line per key on stderr;
#   returns 1 if any were found, 0 otherwise.
#
#   Why this needs its own check, separate from validate_yaml_enum: that
#   function validates VALUES, and a locked key hand-written into the local
#   file has a perfectly legal one. `modes.rigor: full` there passes every
#   validation in the chain — correct key, correct value — and then
#   resolve_setting never consults the local file for that path, so the
#   setting is discarded in total silence and the user sees the default they
#   were trying to override. Nothing else checks the key's LOCATION.
#   /settings --local already refuses these; only the hand-edited file is
#   unguarded, and hand-editing is what the file is for.
#
#   WARNS, NEVER RECONCILES. It does not edit project.local.yaml, does not
#   begin honouring the key, and does not alter resolution. A locked setting
#   is locked because it changes which artifacts exist on disk, so a helper
#   that "helpfully" applied one would let two developers' checkouts diverge —
#   precisely what the whitelist exists to prevent. The fix belongs to the
#   user: move the key to project.yaml, or delete it.
#
#   The parser below is another copy of the one in get_yaml_key and
#   validate_yaml_enum. That duplication is deliberate and matches the
#   established shape of this file: these helpers are sourced individually
#   and must agree on YAML edge cases exactly, and a shared copy that drifted
#   would make two functions disagree about what a file says.
validate_local_scope() {
  local file="${1:-}"
  if [ -z "$file" ]; then
    _yaml_helper_set_root
    if [ "$_YH_ROOT" = "." ]; then file="project.local.yaml"; else file="$_YH_ROOT/project.local.yaml"; fi
  fi
  [ -f "$file" ] || return 0
  if ! _yaml_helper_resolve_python; then return 0; fi
  local found key rc=0
  found=$("$_yaml_helper_python" - "$file" "$_yaml_helper_locally_overridable" <<'PYEOF'
import sys, re

path_file, allowed_table = sys.argv[1], sys.argv[2]
allowed = set(l.strip() for l in allowed_table.splitlines() if l.strip())

# File metadata, not settings -- effects-map.md `## Local Override Pattern —
# `project.local.yaml``, "Locked to `project.yaml`" table, first row, lists
# `schema_version` and `framework.*` with the reason "File metadata, not
# preferences". They are not preferences, so "you cannot override this
# preference locally" is the wrong complaint about them: nothing was dropped
# and nothing needs moving. A project.local.yaml that carries
# `schema_version: 1` is correct as written and must stay silent.
EXEMPT_EXACT = {'schema_version'}
EXEMPT_PREFIX = ('framework.',)

def parse(lines):
    root = {}
    stack = [(-1, root)]
    for raw in lines:
        line = raw.rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            continue
        indent = len(line) - len(stripped)
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', stripped)
        if not m:
            continue
        key = m.group(1).strip()
        value = m.group(2).strip()
        if value.startswith('#'):
            value = ''
        elif value[:1] in ('"', "'"):
            quote = value[0]
            end = value.find(quote, 1)
            value = value[1:end] if end >= 0 else value[1:]
        else:
            hash_pos = value.find(' #')
            if hash_pos >= 0:
                value = value[:hash_pos].strip()
        if value == '':
            new_map = {}
            parent[key] = new_map
            stack.append((indent, new_map))
        else:
            parent[key] = value
    return root

try:
    with open(path_file, 'r', encoding='utf-8-sig', errors='replace') as f:
        data = parse(f.readlines())
except OSError:
    sys.exit(0)

# An EMPTY map counts as a leaf. Array-valued keys parse that way -- the
# `- item` lines carry no colon and are skipped -- so treating an empty map as
# a branch would silently exempt every list-valued setting from this check.
def walk(node, prefix):
    for k, v in node.items():
        dotted = prefix + k if not prefix else prefix + '.' + k
        if isinstance(v, dict) and v:
            walk(v, dotted)
        elif dotted in allowed or dotted in EXEMPT_EXACT:
            continue
        elif dotted.startswith(EXEMPT_PREFIX):
            continue
        else:
            print(dotted)

walk(data, '')
PYEOF
)
  [ -n "$found" ] || return 0
  while IFS= read -r key; do
    [ -z "$key" ] && continue
    echo "$file: \`$key\` is not locally overridable — ignored, not applied. Move it to project.yaml (or delete it); see the whitelist in yaml-helper.sh." >&2
    rc=1
  done <<EOF
$found
EOF
  return "$rc"
}

# session_state_enabled
#   Returns 0 when the session-state pipeline should run, 1 when the user has
#   turned it off with `features.session_state: off`. Honours the local
#   override (the key is on the whitelist above), local winning over base.
#
#   DEFAULT IS `on`. A default of `off` would contradict practice: every project
#   runs with the pipeline active --
#   and `production/session-state/active.md` is the documented recovery
#   checkpoint that `.claude/docs/context-management.md` tells users to rely on.
#   Shipping `off` as the default would silently remove crash recovery, the
#   session archive and the subagent spawn tally from every project. Users who
#   want the ~2-5k tokens per session opt out explicitly.
#
#   Deliberately awk, not get_effective_yaml_key: this runs in log-agent.sh on
#   EVERY subagent spawn, and get_effective_yaml_key shells out to Python twice.
#   Spending 200ms of interpreter startup per spawn to check a token-saving flag
#   would be self-defeating.
session_state_enabled() {
  local f v
  for f in project.local.yaml project.yaml; do
    [ -f "$f" ] || continue
    v=$(awk '
      /^features:[[:space:]]*$/ { inf=1; next }
      /^[^[:space:]#]/          { inf=0 }
      inf && /^[[:space:]]+session_state:/ {
        sub(/^[[:space:]]*session_state:[[:space:]]*/, "")
        sub(/[[:space:]]*#.*$/, "")
        gsub(/["'"'"']/, "")
        print; exit
      }
    ' "$f" 2>/dev/null | tr -d '\r' | tr -d ' ')
    if [ -n "$v" ]; then
      [ "$v" = "off" ] && return 1
      return 0
    fi
  done
  return 0   # unset anywhere => on
}

validate_yaml_enum() {
  local file="${1:-}"
  if [ -z "$file" ] || [ ! -f "$file" ]; then return 0; fi
  if ! _yaml_helper_resolve_python; then
    echo "yaml-helper: no python interpreter found (tried python, python3, py)" >&2
    return 0
  fi
  # ONE interpreter spawn for the whole enum table.
  #
  # Calling `get_yaml_key` once per enum spawns a Python interpreter each time
  # (see get_yaml_key). At ~214ms of process startup on Windows that is several
  # seconds per config file, and with project.yaml plus project.local.yaml it
  # puts session-start.sh over its 10s hook timeout, killing it mid-write so
  # the recovery checkpoint never reaches context.
  #
  # A bash pre-filter that skips lookups for keys ABSENT from the file is
  # correct but insufficient, and the distinction is the lesson: it only removes
  # spawns for keys you do not have. A sparse config skips nearly all of them
  # and looks like a large win. A fully configured project sets all of them,
  # every lookup survives the filter, and the cost returns in full -- no
  # improvement on the population that matters.
  # The count of spawns was never the invariant worth fixing; the cost of one
  # was. Parsing the document once and answering every enum from that parse is
  # constant in the number of keys, so a denser config no longer costs more.
  #
  # The scalar table is walked with the get_yaml_key parser (a flow list under
  # a scalar key is its raw text and is reported as invalid, as before); the
  # array-element table is walked with the get_yaml_array parser.
  "$_yaml_helper_python" - "$file" "$_yaml_helper_enums" "$_yaml_helper_array_enums" "$_yaml_helper_array_nonempty" <<'PYEOF'
import sys, re

path_file, enum_table, array_table, nonempty_list = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
nonempty = set(nonempty_list.split())

def parse(lines):
    root = {}
    stack = [(-1, root)]  # (indent, mapping)
    for raw in lines:
        line = raw.rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            continue
        indent = len(line) - len(stripped)
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', stripped)
        if not m:
            continue
        key = m.group(1).strip()
        value = m.group(2).strip()
        if value.startswith('#'):
            value = ''
        elif value[:1] in ('"', "'"):
            quote = value[0]
            end = value.find(quote, 1)
            if end >= 0:
                value = value[1:end]
            else:
                value = value[1:]
        else:
            hash_pos = value.find(' #')
            if hash_pos >= 0:
                value = value[:hash_pos].strip()
        if value == '':
            new_map = {}
            parent[key] = new_map
            stack.append((indent, new_map))
        else:
            parent[key] = value
    return root

# The get_yaml_array parser (see the comments there for the quote-aware flow
# scan, the unenforced item indent and the item comment rule).
def parse_lists(lines):
    root = {}
    stack = [(-1, root)]
    i = 0
    while i < len(lines):
        line = lines[i].rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            i += 1
            continue
        indent = len(line) - len(stripped)
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', stripped)
        if not m:
            i += 1
            continue
        key = m.group(1).strip()
        value = m.group(2).strip()
        if value.startswith('#'):
            value = ''
        elif value[:1] == '[':
            parts, buf, quote, idx = [], '', None, 1
            while idx < len(value):
                ch = value[idx]
                if quote is not None:
                    if ch == quote:
                        quote = None
                    else:
                        buf += ch
                elif ch in ('"', "'"):
                    quote = ch
                elif ch == ']':
                    break
                elif ch == ',':
                    parts.append(buf.strip())
                    buf = ''
                else:
                    buf += ch
                idx += 1
            if buf.strip():
                parts.append(buf.strip())
            parent[key] = [p for p in parts if p != '']
            i += 1
            continue
        elif value[:1] in ('"', "'"):
            quote = value[0]
            end = value.find(quote, 1)
            value = value[1:end] if end >= 0 else value[1:]
        else:
            hash_pos = value.find(' #')
            if hash_pos >= 0:
                value = value[:hash_pos].strip()
        if value == '':
            j = i + 1
            items = []
            while j < len(lines):
                pl = lines[j].rstrip('\n').rstrip('\r')
                pstripped = pl.lstrip(' ')
                if not pstripped.strip() or pstripped.lstrip().startswith('#'):
                    j += 1
                    continue
                pindent = len(pl) - len(pstripped)
                if pindent <= indent:
                    break
                if pstripped.startswith('- '):
                    item = pstripped[2:].strip()
                    if item[:1] in ('"', "'") and item[-1:] == item[:1] and len(item) >= 2:
                        item = item[1:-1]
                    else:
                        hash_pos = item.find(' #')
                        if hash_pos >= 0:
                            item = item[:hash_pos].strip()
                    items.append(item)
                    j += 1
                    continue
                break
            if items:
                parent[key] = items
                i = j
                continue
            new_map = {}
            parent[key] = new_map
            stack.append((indent, new_map))
        else:
            parent[key] = value
        i += 1
    return root

try:
    with open(path_file, 'r', encoding='utf-8-sig', errors='replace') as f:
        raw_lines = f.readlines()
except OSError:
    sys.exit(0)

data = parse(raw_lines)

# A TAB IN THE INDENTATION IS AN ERROR, not something to normalise away.
#
# The parser strips leading SPACES only, so a tab-indented line never matches
# the key regex and vanishes -- the setting then silently resolves to its
# default. Every enum check below passes on such a file, because a key that
# cannot be read cannot hold an invalid value. That is rc=0 on a config that
# configures nothing, byte-identical in outcome to a genuinely clean file: the
# same file with tabs instead of spaces reported no errors while
# `modes.review_mode: BOGUS_VALUE` sat in it unread.
#
# This is the validator's own version of the rule the skills are held to --
# absence of evidence is not evidence of absence. It cannot report "no invalid
# values" when the real answer is "no values".
#
# YAML forbids tabs for indentation, so reporting rather than repairing is
# correct; doing neither was the defect. Comment lines are exempt: a tab in
# front of a `#` hides nothing.
tab_lines = []
for _n, _raw in enumerate(raw_lines, 1):
    _line = _raw.rstrip('\n').rstrip('\r')
    if not _line.strip() or _line.lstrip(' \t').startswith('#'):
        continue
    _lead = _line[:len(_line) - len(_line.lstrip(' \t'))]
    if '\t' in _lead:
        tab_lines.append(_n)

def node_at(tree, dotted):
    cur = tree
    for k in dotted.split('.'):
        if isinstance(cur, dict) and k in cur:
            cur = cur[k]
        else:
            return None
    return cur

def lookup(dotted):
    cur = node_at(data, dotted)
    if cur is None or isinstance(cur, dict):
        return ''
    return str(cur)

errors = 0
out = []
if tab_lines:
    _shown = ', '.join(str(n) for n in tab_lines[:5])
    if len(tab_lines) > 5:
        _shown += ' (and %d more)' % (len(tab_lines) - 5)
    out.append("line %s: indented with a TAB. YAML forbids tabs for indentation, "
               "so these lines are invisible to the config parser and their "
               "settings silently fall back to defaults. Replace leading tabs "
               "with spaces." % _shown)
    errors += 1
for line in enum_table.splitlines():
    line = line.strip()
    if not line or '::' not in line:
        continue
    enum_path, _, enum_values = line.partition('::')
    actual = lookup(enum_path)
    if actual == '':
        continue
    if actual not in enum_values.split('|'):
        out.append("%s: '%s' is not a valid value (expected: %s)"
                   % (enum_path, actual, enum_values))
        errors += 1

ldata = None
for line in array_table.splitlines():
    line = line.strip()
    if not line or '::' not in line:
        continue
    if ldata is None:
        ldata = parse_lists(raw_lines)
    arr_path, _, arr_values = line.partition('::')
    allowed = arr_values.split('|')
    node = node_at(ldata, arr_path)
    if node is None:
        continue
    if isinstance(node, dict):
        # An empty map is a key written with no value: unset, nothing to say.
        # A populated map is the wrong shape entirely.
        if node:
            out.append("%s: expected a list such as [%s] — treated as unset"
                       % (arr_path, allowed[0]))
            errors += 1
        continue
    items = node if isinstance(node, list) else [node]
    if not items:
        if arr_path in nonempty:
            out.append("%s: [] is not valid (at least one element is required) — treated as unset"
                       % arr_path)
            errors += 1
        continue
    for item in items:
        if item not in allowed:
            out.append("%s: dropped invalid element '%s' (expected: %s)"
                       % (arr_path, item, arr_values))
            errors += 1

if out:
    sys.stderr.buffer.write(('\n'.join(out) + '\n').encode('utf-8'))
sys.exit(1 if errors else 0)
PYEOF
}

# Validate a single pending value for /settings writes.
#
# Scalar enum keys: the value must be one of the key's values.
# Array-element enum keys: the value may be written `a,b` or `[a, b]` (quotes
# around elements are tolerated). Every element is checked, and ONE invalid
# element rejects the WHOLE write -- /settings must never store a list the
# resolver would then silently shorten. `[]` is accepted where it means
# "explicitly none" and rejected for _yaml_helper_array_nonempty keys.
# Keys with no enum constraint return 0 (the caller decides what to do).
# Returns 1 with the reason on stderr on an invalid value.
validate_enum_value() {
  local key="${1:-}"
  local value="${2:-}"
  [ -z "$key" ] && return 0
  local line enum_path enum_values v allowed
  allowed=$(_yaml_helper_array_allowed "$key")
  if [ -n "$allowed" ]; then
    _yaml_helper_validate_array_value "$key" "$value" "$allowed"
    return $?
  fi
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    enum_path="${line%::*}"
    enum_values="${line##*::}"
    if [ "$key" = "$enum_path" ]; then
      local oldIFS="$IFS"
      IFS='|'
      for v in $enum_values; do
        if [ "$value" = "$v" ]; then IFS="$oldIFS"; return 0; fi
      done
      IFS="$oldIFS"
      echo "Invalid value '$value' for '$key'. Allowed: $enum_values" >&2
      return 1
    fi
  done <<EOF
$_yaml_helper_enums
EOF
  # Key has no enum constraint — caller decides what to do.
  return 0
}

# Element-wise check behind validate_enum_value for array-element enum keys.
_yaml_helper_validate_array_value() {
  local key="${1:-}" value="${2:-}" allowed="${3:-}" body items item bad="" n=0
  body=$(printf '%s' "$value" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
  case "$body" in
    \[*\]) body="${body#\[}"; body="${body%\]}" ;;
  esac
  items=$(printf '%s\n' "$body" | tr ',' '\n' \
          | sed "s/^[[:space:]]*//; s/[[:space:]]*\$//; s/^[\"']//; s/[\"']\$//")
  while IFS= read -r item; do
    [ -z "$item" ] && continue
    n=$((n + 1))
    case "|$allowed|" in
      *"|$item|"*) ;;
      *) bad="${bad:+$bad, }'$item'" ;;
    esac
  done <<EOF
$items
EOF
  if [ -n "$bad" ]; then
    echo "Invalid element(s) $bad in '$value' for '$key'. Allowed elements: $allowed" >&2
    return 1
  fi
  if [ "$n" -eq 0 ]; then
    if [ -z "$body" ] && [ -z "$(printf '%s' "$value" | tr -d '[:space:]')" ]; then
      echo "Invalid value '' for '$key'. Allowed elements: $allowed" >&2
      return 1
    fi
    if _yaml_helper_array_requires_element "$key"; then
      echo "Invalid value '$value' for '$key': at least one element is required. Allowed elements: $allowed" >&2
      return 1
    fi
  fi
  return 0
}

# automation_always_ask category check.
# Returns 0 if the named category is in modes.automation_always_ask (or in
# the default list when unset), 1 otherwise. Used by skills in autonomous
# mode to know which decisions still warrant a prompt. The default list
# (used when modes.automation_always_ask is absent from both files) is the
# nine production-risk categories below; `.claude/docs/automation-modes.md`
# defines every recognized category.
_yaml_helper_always_ask_default="scope_changes
file_deletions
schema_changes
production_deploys
db_migrations
infra_changes
secrets_access
pii_data_access
billing_changes"

is_always_ask_category() {
  local category="${1:-}"
  [ -z "$category" ] && return 1
  local configured
  configured=$(get_effective_yaml_array modes.automation_always_ask)
  if [ -z "$configured" ]; then
    configured="$_yaml_helper_always_ask_default"
  fi
  local item
  while IFS= read -r item; do
    [ -z "$item" ] && continue
    if [ "$item" = "$category" ]; then return 0; fi
  done <<EOF
$configured
EOF
  return 1
}

# Append a decision-log entry. Format per automation-modes.md
# `## Decision Log Format (Autonomous Mode)` (effects-map.md `## modes.automation`
# → `### Decision log` points there). Creates the file and parent
# directory if absent. Uses ISO 8601 UTC timestamps. Decisions only — never
# evidence (production/session-logs/ is gitignored).
log_decision() {
  _yaml_helper_set_root
  local skill="${1:-}"
  local point="${2:-}"
  local options="${3:-}"
  local chosen="${4:-}"
  local reason="${5:-}"
  local category="${6:-}"
  local logfile="$_YH_ROOT/production/session-logs/decision-log.md"
  mkdir -p "$(dirname "$logfile")"
  if [ ! -f "$logfile" ]; then
    printf '# Decision Log\n\nAppend-only audit trail of decisions made in autonomous mode.\n' > "$logfile"
  fi
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u)
  cat >> "$logfile" <<EOF

## $timestamp — $skill

**Decision point:** $point
**Options considered:** $options
**Chosen:** $chosen
**Reason:** $reason
**Category:** $category
EOF
}

# =============================================================================
# Whole-config resolution.
#
# WHY THIS EXISTS
#   Without it, every skill carries its own English description of a
#   deterministic fallback chain ("1. If --review passed -> use that; 2. Else
#   read modes.review_mode from project.yaml; 3. Else derive it from
#   modes.rigor; ..."), re-interpreted by a model on every invocation at
#   roughly +1,360 tokens per skill. resolve_config computes the same answer
#   once, in ~150 tokens, deterministically -- and testably, which prose never
#   was.
#
# CONTRACT BOUNDARY
#   This layer resolves SOURCES. It does not own per-skill policy. Anything
#   whose default legitimately differs between skills (testing.strict.*) is
#   reported as configured-or-unset and left to the skill to default, and
#   anything whose unset state means "ask the user" (surfaces, distribution,
#   compliance, accessibility) is reported as unset, never defaulted.
# =============================================================================

# Terminal defaults. ONLY knobs whose default is uniform across every consumer.
#
# testing.strict.* is deliberately ABSENT: /smoke-check defaults it to blocking
# (build-health gate) while /story-done and /dev-story default per story type.
# Emitting one value here would silently pick a winner between them.
#
# release.distribution, platform.surfaces, compliance.regions,
# privacy.handles_pii and accessibility.target are ABSENT for a different
# reason: their unset state means "ask" (obligation 2 of skill-authoring.md --
# absence is not a permissive default). A default of `web`, `[]`, `false` or
# `none` would make the question unaskable.
#
# The six knobs `rigor` fronts (modes.workflow, docs.density, qa.level,
# modes.story_granularity, modes.review_mode, team.size) are ALSO absent: their
# value comes from the rigor expansion below, which sits between the explicit
# sources and this table. Leaving a terminal default here as well would shadow
# the expansion and make `rigor` a no-op for anyone who had not also set the
# sub-knob. modes.review_mode is fronted by rigor so `rigor: minimal` resolves
# review_mode to `solo` (skipping the director/specialist gate spawns),
# `standard` yields `lean` and `full` yields `full`. team.size is fronted the
# same way: `full` yields `studio` (the whole roster) while `minimal`/`standard`
# yield `individual`. Both stay locally overridable (they are
# personal-experience knobs, not on-disk artifacts): that source sits ABOVE the
# expansion, so only the terminal fallback moved.
#
# --- WHY modes.rigor DEFAULTS TO `minimal` -----------------------------------
#
# A `standard` default was measured against it: building the same product both
# ways showed the heavier tier costing several times as much to reach working
# code without producing a better result, and giving nothing back when a fresh
# developer picked the project up. A default that costs more and does not repay
# is the wrong default, and it is what every user who never opens /settings
# receives.
#
# Raising rigor stays one question in /start and one `/settings` call, and the
# upward triggers in settings-guidance.md § 4 are written to fire from exactly
# this starting state. The cost of under-running is one prompt.
#
# ORDER MATTERS: this default is only safe while /gate-check keeps its floors.
# `rigor: minimal` expands to `workflow: minimal` + `qa.level: minimal`, which
# together could leave the Build -> Hardening gate with ZERO required artifacts
# -- a vacuous PASS. /gate-check prevents that with the smoke-report floor and
# the "nothing required -> NOT ASSESSED, never PASS" rule. Do not move this
# default without re-checking that the gates below it still require something.
_yaml_helper_defaults="\
modes.automation::collaborative
modes.rigor::minimal
performance.enforce::warn"

# Rigor expansion — one asked-at-/start knob that supplies six.
#
# WHY: /start does not ask about workflow, docs.density, qa.level,
# story_granularity, review_mode or team.size one by one, so in practice every
# project would run all of them at their defaults. Several of them drive one
# behaviour each (prose verbosity, is-evidence-required, story size) restated
# across many skills. `rigor` makes the common case reachable in one question
# while each knob stays individually settable.
#
# modes.workflow is fronted, NOT replaced: it drives several distinct behaviours
# and owns the only per-feature override mechanism
# (workflow_overrides.feature_overrides), which continues to win over the
# rigor-derived value.
_yaml_helper_rigor_expansion="\
minimal::modes.workflow=minimal,docs.density=terse,qa.level=minimal,modes.story_granularity=coarse,modes.review_mode=solo,team.size=individual
standard::modes.workflow=standard,docs.density=balanced,qa.level=standard,modes.story_granularity=balanced,modes.review_mode=lean,team.size=individual
full::modes.workflow=full,docs.density=thorough,qa.level=full,modes.story_granularity=fine,modes.review_mode=full,team.size=studio"

# Value for <path> implied by the project's rigor level, or '' if rigor does not
# front that key. Never consulted for modes.rigor itself — that would recurse.
_yaml_helper_rigor_value() {
  _yaml_helper_set_root
  local path="${1:-}" level="" line pair
  [ -z "$path" ] && return 0
  [ "$path" = "modes.rigor" ] && return 0

  # Fast path: a key the expansion never mentions cannot be fronted, so do not
  # pay an interpreter spawn to read the rigor level for it.
  case "$_yaml_helper_rigor_expansion" in
    *"$path="*) ;;
    *) return 0 ;;
  esac

  # Resolve rigor WITHOUT resolve_setting, to keep the recursion impossible.
  [ -f "$_YH_ROOT/project.yaml" ] && level=$(_yaml_helper_cfg_scalar project modes.rigor)
  if [ -n "$level" ] && ! validate_enum_value modes.rigor "$level" 2>/dev/null; then level=""; fi
  [ -z "$level" ] && level=$(get_yaml_default modes.rigor)
  [ -z "$level" ] && return 0

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    [ "${line%%::*}" = "$level" ] || continue
    local oldIFS="$IFS"; IFS=','
    for pair in ${line##*::}; do
      if [ "${pair%%=*}" = "$path" ]; then IFS="$oldIFS"; printf '%s' "${pair#*=}"; return 0; fi
    done
    IFS="$oldIFS"
  done <<EOF
$_yaml_helper_rigor_expansion
EOF
  return 0
}

# The rigor level currently in effect (for source labels and /settings).
_yaml_helper_rigor_level() {
  _yaml_helper_set_root
  local level=""
  [ -f "$_YH_ROOT/project.yaml" ] && level=$(_yaml_helper_cfg_scalar project modes.rigor)
  if [ -n "$level" ] && ! validate_enum_value modes.rigor "$level" 2>/dev/null; then level=""; fi
  [ -z "$level" ] && level=$(get_yaml_default modes.rigor)
  printf '%s' "$level"
}

# Scalar read used by the resolution chain: <project|local> <dotted.path>.
#
# Outside resolve_config it is exactly get_yaml_key on the file. While
# resolve_config runs it answers from the one-parse snapshots resolve_config
# takes of both files (_YH_LV_CACHE, _YH_LVL_CACHE) -- the chain, its order and
# its validation are unchanged; only the interpreter spawn per hop is gone. A
# ten-label bootstrap otherwise pays ~30 spawns, which on Windows Git Bash is
# seconds before the skill even renders. Scalar keys only: a list-valued key
# reads as '' here (resolve_config never resolves one through the chain).
_yaml_helper_cfg_scalar() {
  local which="${1:-}" key="${2:-}"
  [ -z "$key" ] && return 0
  if [ "${_YH_LV_ON:-0}" = "1" ]; then
    if [ "$which" = "local" ]; then
      _yaml_helper_lv_scalar "${_YH_LVL_CACHE:-}" "$key"
    else
      _yaml_helper_lv_scalar "${_YH_LV_CACHE:-}" "$key"
    fi
    return 0
  fi
  if [ "$which" = "local" ]; then
    get_yaml_key "$_YH_ROOT/project.local.yaml" "$key"
  else
    get_yaml_key "$_YH_ROOT/project.yaml" "$key"
  fi
  return 0
}

# Which keys consult project.local.yaml DURING RESOLUTION.
#
# This list MUST equal the `/settings --local` write whitelist. If resolution
# consulted project.local.yaml for a narrower set than /settings will write to
# it, `/settings --local modes.review_mode=solo` would write a value that
# /settings accepts and displays, and that every skill then ignores. A write
# list and a read list that disagree is not a design; it is a bug with a
# plausible-looking symptom.
#
# Kept as its own variable rather than inlining the whitelist: "may be written
# locally" and "is read during resolution" are distinct concepts that merely
# coincide. A future setting could legitimately be one and not the other.
_yaml_helper_local_read_scope="$_yaml_helper_locally_overridable"

_yaml_helper_in_local_read_scope() {
  local path="${1:-}" entry
  [ -z "$path" ] && return 1
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    [ "$path" = "$entry" ] && return 0
  done <<EOF
$_yaml_helper_local_read_scope
EOF
  return 1
}

# Documented terminal default for a key, or '' when it has none.
get_yaml_default() {
  local path="${1:-}" line
  [ -z "$path" ] && return 0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [ "${line%%::*}" = "$path" ]; then printf '%s' "${line##*::}"; return 0; fi
  done <<EOF
$_yaml_helper_defaults
EOF
  return 0
}

# Resolve one setting through the full chain.
#   prints: "<value>\t<source>"
#   chain:  project.local.yaml (whitelisted keys only) -> project.yaml
#           -> modes.rigor expansion (the six fronted knobs) -> terminal default
#   source: project.local.yaml | project.yaml | rigor:<level> | default | unset
#   exit:   always 0
#
# Enum-invalid values FALL THROUGH rather than winning — a typo degrades to the
# next source and ultimately the documented default (or unset), instead of
# propagating a nonsense mode into every skill. resolve_config surfaces what
# was rejected on its `notes:` line.
resolve_setting() {
  _yaml_helper_set_root
  local path="${1:-}"
  if [ -z "$path" ]; then printf '\tunset'; return 0; fi
  local val="" src=""

  if _yaml_helper_in_local_read_scope "$path" && [ -f "$_YH_ROOT/project.local.yaml" ]; then
    val=$(_yaml_helper_cfg_scalar local "$path")
    if [ -n "$val" ] && ! validate_enum_value "$path" "$val" 2>/dev/null; then val=""; fi
    [ -n "$val" ] && src="project.local.yaml"
  fi

  if [ -z "$val" ] && [ -f "$_YH_ROOT/project.yaml" ]; then
    val=$(_yaml_helper_cfg_scalar project "$path")
    if [ -n "$val" ] && ! validate_enum_value "$path" "$val" 2>/dev/null; then val=""; fi
    [ -n "$val" ] && src="project.yaml"
  fi

  # Rigor expansion sits BELOW every explicit source and ABOVE the terminal
  # default. That ordering is the whole contract: a project.yaml that sets
  # docs.density explicitly keeps it whatever rigor says, and an unset fronted
  # knob follows rigor instead of a hard-coded value.
  if [ -z "$val" ]; then
    val=$(_yaml_helper_rigor_value "$path")
    [ -n "$val" ] && src="rigor:$(_yaml_helper_rigor_level)"
  fi

  if [ -z "$val" ]; then
    val=$(get_yaml_default "$path")
    [ -n "$val" ] && src="default"
  fi

  [ -z "$src" ] && src="unset"
  printf '%s\t%s' "$val" "$src"
}

# =============================================================================
# Stack reads: one parse of project.yaml answers every stack, root and list key.
#
# The stack line alone reads twenty-odd keys. One get_yaml_key per key is one
# interpreter spawn per key -- the cost validate_yaml_enum already had to
# engineer away -- so these readers take a single "leaves" dump of the file,
# made with the get_yaml_array parser, and answer every lookup from it.
# resolve_config makes the dump once and shares it with every label it prints.
# =============================================================================

# Every leaf of <file>, one per line: "<kind>\t<dotted.path>\t<value>".
#   kind s = scalar; l = one list element (one line per element, in order);
#   e = an empty list (`[]` -- set-but-empty, distinct from absent).
# A key written with no value (an empty map) prints nothing: that is unset.
_yaml_helper_leaves() {
  local file="${1:-}"
  if [ -z "$file" ] || [ ! -f "$file" ]; then return 0; fi
  if ! _yaml_helper_resolve_python; then
    echo "yaml-helper: no python interpreter found (tried python, python3, py)" >&2
    return 0
  fi
  "$_yaml_helper_python" - "$file" <<'PYEOF'
import sys, re

path_file = sys.argv[1]

# The get_yaml_array parser (see the comments there for the quote-aware flow
# scan, the unenforced item indent and the item comment rule).
def parse(lines):
    root = {}
    stack = [(-1, root)]
    i = 0
    while i < len(lines):
        line = lines[i].rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            i += 1
            continue
        indent = len(line) - len(stripped)
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', stripped)
        if not m:
            i += 1
            continue
        key = m.group(1).strip()
        value = m.group(2).strip()
        if value.startswith('#'):
            value = ''
        elif value[:1] == '[':
            parts, buf, quote, idx = [], '', None, 1
            while idx < len(value):
                ch = value[idx]
                if quote is not None:
                    if ch == quote:
                        quote = None
                    else:
                        buf += ch
                elif ch in ('"', "'"):
                    quote = ch
                elif ch == ']':
                    break
                elif ch == ',':
                    parts.append(buf.strip())
                    buf = ''
                else:
                    buf += ch
                idx += 1
            if buf.strip():
                parts.append(buf.strip())
            parent[key] = [p for p in parts if p != '']
            i += 1
            continue
        elif value[:1] in ('"', "'"):
            quote = value[0]
            end = value.find(quote, 1)
            value = value[1:end] if end >= 0 else value[1:]
        else:
            hash_pos = value.find(' #')
            if hash_pos >= 0:
                value = value[:hash_pos].strip()
        if value == '':
            j = i + 1
            items = []
            while j < len(lines):
                pl = lines[j].rstrip('\n').rstrip('\r')
                pstripped = pl.lstrip(' ')
                if not pstripped.strip() or pstripped.lstrip().startswith('#'):
                    j += 1
                    continue
                pindent = len(pl) - len(pstripped)
                if pindent <= indent:
                    break
                if pstripped.startswith('- '):
                    item = pstripped[2:].strip()
                    if item[:1] in ('"', "'") and item[-1:] == item[:1] and len(item) >= 2:
                        item = item[1:-1]
                    else:
                        hash_pos = item.find(' #')
                        if hash_pos >= 0:
                            item = item[:hash_pos].strip()
                    items.append(item)
                    j += 1
                    continue
                break
            if items:
                parent[key] = items
                i = j
                continue
            new_map = {}
            parent[key] = new_map
            stack.append((indent, new_map))
        else:
            parent[key] = value
        i += 1
    return root

try:
    with open(path_file, 'r', encoding='utf-8-sig', errors='replace') as f:
        data = parse(f.readlines())
except OSError:
    sys.exit(0)

out = []
def clean(v):
    return str(v).replace('\t', ' ').replace('\n', ' ')
def walk(node, prefix):
    for k, v in node.items():
        dotted = k if not prefix else prefix + '.' + k
        if isinstance(v, dict):
            walk(v, dotted)
        elif isinstance(v, list):
            if not v:
                out.append('e\t%s\t' % dotted)
            for item in v:
                out.append('l\t%s\t%s' % (dotted, clean(item)))
        else:
            out.append('s\t%s\t%s' % (dotted, clean(v)))
walk(data, '')
if out:
    sys.stdout.buffer.write(('\n'.join(out) + '\n').encode('utf-8'))
PYEOF
}

# The leaves dump of project.yaml -- resolve_config's snapshot while it runs,
# a fresh parse otherwise (never a cache that could outlive a /settings write).
_yaml_helper_project_leaves() {
  if [ "${_YH_LV_ON:-0}" = "1" ]; then printf '%s' "${_YH_LV_CACHE:-}"; return 0; fi
  _yaml_helper_set_root
  [ -f "$_YH_ROOT/project.yaml" ] && _yaml_helper_leaves "$_YH_ROOT/project.yaml" 2>/dev/null
  return 0
}

# Lookups on a leaves dump. <dump> is the text _yaml_helper_leaves printed.
#   _yaml_helper_lv_scalar <dump> <key>   the scalar value, or ''
#   _yaml_helper_lv_items  <dump> <key>   list elements one per line; a scalar
#                                         counts as a one-element list
#   _yaml_helper_lv_empty  <dump> <key>   0 when the key is set to `[]`
_yaml_helper_lv_scalar() {
  [ -z "${1:-}" ] && return 0
  printf '%s\n' "$1" | awk -F '\t' -v k="${2:-}" \
    '$1 == "s" && $2 == k { print substr($0, length($1) + length($2) + 3); exit }'
  return 0
}

_yaml_helper_lv_items() {
  [ -z "${1:-}" ] && return 0
  printf '%s\n' "$1" | awk -F '\t' -v k="${2:-}" \
    '($1 == "s" || $1 == "l") && $2 == k { v = substr($0, length($1) + length($2) + 3); if (v != "") print v }'
  return 0
}

_yaml_helper_lv_empty() {
  [ -z "${1:-}" ] && return 1
  printf '%s\n' "$1" | awk -F '\t' -v k="${2:-}" \
    'BEGIN { r = 1 } $1 == "e" && $2 == k { r = 0 } END { exit r }'
}

# Repo-relative directory, normalised: no leading "./", no trailing "/".
_yaml_helper_norm_dir() {
  local d="${1:-}"
  while :; do case "$d" in ./*) d="${d#./}" ;; *) break ;; esac; done
  while :; do
    case "$d" in
      /) break ;;
      */) d="${d%/}" ;;
      *) break ;;
    esac
  done
  [ -z "$d" ] && d="."
  printf '%s' "$d"
}

# 0 when <dir> equals, or sits inside, any directory of the newline-separated
# <list>. "." contains everything.
_yaml_helper_under_any() {
  local d="${1:-}" e
  while IFS= read -r e; do
    [ -z "$e" ] && continue
    [ "$e" = "." ] && return 0
    [ "$d" = "$e" ] && return 0
    case "$d" in "$e"/*) return 0 ;; esac
  done <<EOF
${2:-}
EOF
  return 1
}

# =============================================================================
# Specialist routing (effects-map.md § "stack.layers and specialists").
#
#   _yaml_helper_route_specialist <layer>
#     prints <lead>, <lead>><sub>, or <lead>><sub1>+<sub2> (native mobile);
#     nothing when the layer is not configured -- an unset layer spawns no
#     specialist, and the skill says `NOT CHECKED — <layer> layer not
#     configured (run /setup-stack)`.
#
# The sub-specialist is DERIVED from the layer's configuring value
# (case-insensitive ERE, rules in order, first match wins); `specialists.<layer>`
# overrides the sub. Internal: resolve_config's `stack` label is the one caller,
# and skills read the routing from that label.
# =============================================================================
_yaml_helper_route_specialist() {
  _yaml_helper_set_root
  local layer="${1:-}" lv="" fw="" lead="" sub="" lc="" ov=""
  lv=$(_yaml_helper_project_leaves)
  case "$layer" in
    web|mobile|backend)
      lead="$layer-specialist"
      fw=$(_yaml_helper_lv_scalar "$lv" "stack.layers.$layer.framework") ;;
    data)
      fw=$(_yaml_helper_lv_scalar "$lv" stack.layers.data.database)
      [ -n "$fw" ] && printf '%s' "data-specialist"
      return 0 ;;
    cloud)
      fw=$(_yaml_helper_lv_scalar "$lv" stack.layers.cloud.provider)
      [ -n "$fw" ] && printf '%s' "cloud-specialist"
      return 0 ;;
    *) return 0 ;;
  esac
  [ -z "$fw" ] && return 0
  lc=$(printf '%s' "$fw" | tr '[:upper:]' '[:lower:]')
  case "$layer" in
    web)
      if printf '%s' "$lc" | grep -Eq 'next|react'; then sub="nextjs-specialist"
      elif printf '%s' "$lc" | grep -Eq 'nuxt|vue'; then sub="vue-nuxt-specialist"
      fi ;;
    mobile)
      if printf '%s' "$lc" | grep -Eq 'react native|expo'; then sub="react-native-specialist"
      elif printf '%s' "$lc" | grep -Eq 'flutter'; then sub="flutter-specialist"
      elif { printf '%s' "$lc" | grep -Eq 'swift|ios' && printf '%s' "$lc" | grep -Eq 'kotlin|compose|android'; } \
           || printf '%s' "$lc" | grep -Eq '^native'; then sub="ios-specialist+android-specialist"
      elif printf '%s' "$lc" | grep -Eq 'swift|ios'; then sub="ios-specialist"
      elif printf '%s' "$lc" | grep -Eq 'kotlin|compose|android'; then sub="android-specialist"
      fi ;;
    backend)
      if printf '%s' "$lc" | grep -Eq 'nest|express|fastify|hono|node'; then sub="node-specialist"
      elif printf '%s' "$lc" | grep -Eq 'spring|java|kotlin'; then sub="spring-specialist"
      elif printf '%s' "$lc" | grep -Eq 'fastapi|django|flask|python'; then sub="python-specialist"
      fi ;;
  esac
  ov=$(_yaml_helper_lv_scalar "$lv" "specialists.$layer")
  if [ -n "$ov" ] && _yaml_helper_valid_specialist_override "$layer" "$ov"; then
    if [ "$ov" = "$lead" ]; then sub=""; else sub="$ov"; fi
  fi
  printf '%s' "$lead${sub:+>$sub}"
  return 0
}

# Values `specialists.<layer>` may take: one of the layer lead's own
# sub-specialists, the native-mobile pair, or the lead itself (= no sub).
# Anything else is ignored (derived routing stands) and named on `notes:`.
_yaml_helper_valid_specialist_override() {
  local layer="${1:-}" v="${2:-}"
  case "$layer:$v" in
    web:web-specialist|web:nextjs-specialist|web:vue-nuxt-specialist) return 0 ;;
    mobile:mobile-specialist|mobile:react-native-specialist|mobile:flutter-specialist) return 0 ;;
    mobile:ios-specialist|mobile:android-specialist|mobile:ios-specialist+android-specialist) return 0 ;;
    backend:backend-specialist|backend:node-specialist|backend:spring-specialist|backend:python-specialist) return 0 ;;
  esac
  return 1
}

# =============================================================================
# Code roots.
#
#   resolve_code_roots
#     prints one line per root:  <dir>\t<layer>\t<source>
#       dir    = repo-relative path (field 1, so `cut -f1` consumers keep working)
#       layer  in web | mobile | backend | cloud | data | shared | app | undeclared
#       source in project.yaml | missing | workspace | detected
#     prints nothing when unresolved; exit 0 always
#
# WHY MULTI-ROOT. A service repo is rarely one tree: a monorepo carries
# apps/web, apps/admin, apps/mobile, apps/api, services/worker, packages and
# infra side by side. A scan anchored to ONE root matches nothing in the others
# -- and matching nothing is indistinguishable from scanning cleanly. That is
# the `/security-audit` row `.claude/rules/skill-authoring.md` records (a grep
# that returned zero hits because it looked in the wrong place, read as clean).
#
# UNSET DOES NOT DEFAULT TO `src`. Obligation 2 of skill-authoring.md: an absent
# value may not default to the permissive one. An unresolvable root prints
# nothing, and the CALLER must announce that its check did not run:
#   NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)
#
# Algorithm (code-root-resolution.md documents the same steps):
#   1. web mobile backend cloud (fixed order): stack.layers.<layer>.root, a
#      path or a flow list; one line per entry, source project.yaml when the
#      directory exists, else missing.
#   2. stack.layers.data.migrations_dir -> layer data.
#   3. stack.shared_roots entries -> layer shared.
#   4. ALWAYS (derivation, obligation 5): every apps/*, services/*, packages/*
#      directory holding a manifest and NOT equal to or inside a root from
#      steps 1-3 -> layer undeclared, source workspace. Callers scan these too
#      and print `WARN: undeclared code roots: <dirs> — declare them with /setup-stack`.
#   5. ONLY if 1-4 printed nothing: a repo-root manifest plus EXACTLY ONE of
#      src/, app/, lib/ -> that dir, layer app, source detected. Zero or
#      several is genuinely undecidable -- do not guess.
#   6. Nothing else. Never `src` by default.
# =============================================================================
_yaml_helper_manifests="package.json pyproject.toml build.gradle build.gradle.kts pom.xml go.mod pubspec.yaml Cargo.toml composer.json Gemfile"

_yaml_helper_has_manifest() {
  local d="${1:-}" m
  [ -z "$d" ] && return 1
  for m in $_yaml_helper_manifests; do
    [ -f "$d/$m" ] && return 0
  done
  return 1
}

resolve_code_roots() {
  _yaml_helper_set_root
  local lv="" layer="" d="" rel="" emitted="" key="" src="" found="" n=0
  lv=$(_yaml_helper_project_leaves)

  # Steps 1-3: declared roots.
  for layer in web mobile backend cloud data shared; do
    case "$layer" in
      data)   key="stack.layers.data.migrations_dir" ;;
      shared) key="stack.shared_roots" ;;
      *)      key="stack.layers.$layer.root" ;;
    esac
    while IFS= read -r d; do
      [ -z "$d" ] && continue
      d=$(_yaml_helper_norm_dir "$d")
      if [ -d "$_YH_ROOT/$d" ]; then src="project.yaml"; else src="missing"; fi
      printf '%s\t%s\t%s\n' "$d" "$layer" "$src"
      emitted="${emitted}${d}
"
    done <<EOF
$(_yaml_helper_lv_items "$lv" "$key")
EOF
  done

  # Step 4: undeclared workspace packages -- always derived, never enumerated.
  for d in "$_YH_ROOT"/apps/* "$_YH_ROOT"/services/* "$_YH_ROOT"/packages/*; do
    [ -d "$d" ] || continue
    _yaml_helper_has_manifest "$d" || continue
    rel="${d#"$_YH_ROOT"/}"
    _yaml_helper_under_any "$rel" "$emitted" && continue
    printf '%s\t%s\t%s\n' "$rel" "undeclared" "workspace"
    emitted="${emitted}${rel}
"
  done

  # Step 5: a single-app repo, only when nothing else resolved.
  if [ -z "$emitted" ] && _yaml_helper_has_manifest "$_YH_ROOT"; then
    for d in src app lib; do
      if [ -d "$_YH_ROOT/$d" ]; then found="$d"; n=$((n + 1)); fi
    done
    if [ "$n" -eq 1 ]; then printf '%s\t%s\t%s\n' "$found" "app" "detected"; fi
  fi
  return 0
}

# Directories a multi-root scan never descends into: dependency caches, build
# output, framework caches, virtualenvs, IaC state and VCS metadata. Without the
# prune a web root's node_modules alone outnumbers its sources by orders of
# magnitude, so a capped scan would count vendored files and stop.
_yaml_helper_scan_prune="node_modules .next .nuxt .output .turbo .vercel .expo dist build out coverage Pods DerivedData .gradle .dart_tool .venv venv __pycache__ .terraform vendor target .git"

# Source-file extensions derived from the configured stack, or '' when no
# language/framework value is configured (code_extensions then falls back to
# the union). Families are matched on every layer's language, framework and
# runtime, case-insensitively.
_yaml_helper_ext_derived() {
  local lv="" vals="" layer k v fam="" exts=""
  lv=$(_yaml_helper_project_leaves)
  for layer in web mobile backend; do
    for k in language framework runtime; do
      v=$(_yaml_helper_lv_scalar "$lv" "stack.layers.$layer.$k")
      [ -n "$v" ] && vals="$vals | $v"
    done
  done
  [ -z "$vals" ] && return 0
  vals=$(printf '%s |' "$vals" | tr '[:upper:]' '[:lower:]')
  _yaml_helper_ext_family() { printf '%s' "$vals" | grep -Eq "$1" && exts="${exts:+$exts }$2"; return 0; }
  _yaml_helper_ext_family 'typescript|javascript|node|deno|bun|next|react|vue|nuxt|svelte|angular|remix|astro|nest|express|fastify|hono|expo|electron' 'ts tsx js jsx mjs cjs vue svelte'
  _yaml_helper_ext_family 'python|django|fastapi|flask' 'py'
  _yaml_helper_ext_family '(^|[^a-z])java([^s]|$)|kotlin|spring|jetpack|compose|ktor|quarkus|micronaut|android' 'java kt kts'
  _yaml_helper_ext_family 'swift' 'swift'
  _yaml_helper_ext_family 'dart|flutter' 'dart'
  _yaml_helper_ext_family '(^|[^a-z])go([^a-z]|$)|golang' 'go'
  _yaml_helper_ext_family 'ruby|rails' 'rb'
  _yaml_helper_ext_family 'php|laravel|symfony' 'php'
  _yaml_helper_ext_family 'c#|csharp|\.net|dotnet' 'cs'
  _yaml_helper_ext_family 'rust|axum|actix' 'rs'
  [ -z "$exts" ] && return 0
  if [ -n "$(_yaml_helper_lv_scalar "$lv" stack.layers.data.database)" ] \
     || [ -n "$(_yaml_helper_lv_scalar "$lv" stack.layers.data.migrations_dir)" ]; then
    exts="$exts sql"
  fi
  fam=$(_yaml_helper_lv_scalar "$lv" stack.layers.cloud.iac | tr '[:upper:]' '[:lower:]')
  case "$fam" in *terraform*|*opentofu*) exts="$exts tf" ;; esac
  printf '%s' "$exts"
  return 0
}

# code_extensions
#   Space-separated extension list for the configured stack: TypeScript /
#   JavaScript -> ts tsx js jsx mjs cjs vue svelte; Python -> py; Java/Kotlin ->
#   java kt kts; Swift -> swift; Dart -> dart; Go -> go; Ruby -> rb; PHP -> php;
#   C# -> cs; Rust -> rs; plus sql when a data layer is set and tf when
#   stack.layers.cloud.iac is Terraform. Nothing configured -> the union of all
#   of them (callers announce it as "extensions: default union").
code_extensions() {
  _yaml_helper_set_root
  local exts=""
  exts=$(_yaml_helper_ext_derived)
  [ -z "$exts" ] && exts="ts tsx js jsx mjs cjs vue svelte py java kt kts swift dart go rb php cs rs sql tf"
  printf '%s\n' "$exts"
  return 0
}

# list_code_files [--limit N]
#   Every file under the scannable code roots (sources project.yaml, workspace,
#   detected -- never missing) whose extension is in code_extensions, pruning
#   _yaml_helper_scan_prune, one repo-relative path per line. With --limit,
#   stops after N files. A root nested inside another listed root is walked
#   once, through its parent. Prints nothing when no root resolves -- the
#   caller then prints its NOT CHECKED line. Exit 0 always.
list_code_files() {
  _yaml_helper_set_root
  local limit="" roots="" kept="" dir="" e="" out="" count=0 remaining=""
  if [ "${1:-}" = "--limit" ]; then
    limit="${2:-}"
    case "$limit" in ''|*[!0-9]*) limit="" ;; esac
  fi
  [ "$limit" = "0" ] && return 0

  roots=$(resolve_code_roots | awk -F '\t' '$3 != "missing" && $1 != "" { print length($1) "\t" $1 }' \
          | sort -n | cut -f2-)
  [ -z "$roots" ] && return 0
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    _yaml_helper_under_any "$dir" "$kept" && continue
    kept="${kept}${dir}
"
  done <<EOF
$roots
EOF

  # find arguments: -mindepth 1 keeps a root whose own name is on the prune
  # list from pruning itself.
  set -- -mindepth 1 '(' -type d '('
  local first=1 p
  for p in $_yaml_helper_scan_prune; do
    if [ "$first" = 1 ]; then first=0; else set -- "$@" -o; fi
    set -- "$@" -name "$p"
  done
  set -- "$@" ')' ')' -prune -o -type f '('
  first=1
  for e in $(code_extensions); do
    if [ "$first" = 1 ]; then first=0; else set -- "$@" -o; fi
    set -- "$@" -name "*.$e"
  done
  set -- "$@" ')' -print

  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    if [ -n "$limit" ]; then
      remaining=$((limit - count))
      [ "$remaining" -le 0 ] && break
      out=$( (cd "$_YH_ROOT" 2>/dev/null && find "$dir" "$@" 2>/dev/null) | head -n "$remaining") || true
    else
      out=$( (cd "$_YH_ROOT" 2>/dev/null && find "$dir" "$@" 2>/dev/null) ) || true
    fi
    [ -z "$out" ] && continue
    printf '%s\n' "$out"
    count=$((count + $(printf '%s\n' "$out" | wc -l)))
  done <<EOF
$kept
EOF
  return 0
}

# List the child key names of a mapping node (one per line). get_yaml_key
# deliberately returns nothing for a mapping, so this is how a whole map (for
# example workflow_overrides.feature_overrides) gets enumerated in one shot.
get_yaml_child_keys() {
  local file="${1:-}" path="${2:-}"
  if [ -z "$file" ] || [ -z "$path" ] || [ ! -f "$file" ]; then return 0; fi
  _yaml_helper_resolve_python || return 0
  "$_yaml_helper_python" - "$file" "$path" <<'PYEOF'
import sys, re
path_file, dotted = sys.argv[1], sys.argv[2]
keys = dotted.split('.')

def parse(lines):
    root = {}
    stack = [(-1, root)]
    for raw in lines:
        line = raw.rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            continue
        indent = len(line) - len(stripped)
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', stripped)
        if not m:
            continue
        key, value = m.group(1).strip(), m.group(2).strip()
        if value.startswith('#'):
            value = ''
        elif value[:1] in ('"', "'"):
            q = value[0]; end = value.find(q, 1)
            value = value[1:end] if end >= 0 else value[1:]
        else:
            hp = value.find(' #')
            if hp >= 0:
                value = value[:hp].strip()
        if value == '':
            nm = {}; parent[key] = nm; stack.append((indent, nm))
        else:
            parent[key] = value
    return root

try:
    with open(path_file, 'r', encoding='utf-8-sig', errors='replace') as f:
        data = parse(f.readlines())
except OSError:
    sys.exit(0)

cur = data
for k in keys:
    if isinstance(cur, dict) and k in cur:
        cur = cur[k]
    else:
        sys.exit(0)
if not isinstance(cur, dict):
    sys.exit(0)
sys.stdout.buffer.write("\n".join(cur.keys()).encode('utf-8'))
PYEOF
}

# Emit the resolved-config block a skill reads instead of re-deriving anything.
#
#   resolve_config [--keys l1,l2,...] [<feature>]
#
# ALWAYS exits 0 and ALWAYS emits a complete block — a missing project.yaml,
# malformed YAML, an orphan project.local.yaml or a missing Python interpreter
# each degrade to defaults and surface on the notes: line rather than producing
# a truncated block a skill might half-read.
#
# --keys restricts output to the named labels. USE IT. A full block costs
# several hundred tokens, while the resolution prose it replaces averages only
# ~101 tokens per skill -- so a full block is a NET LOSS for any skill that
# reads 2-3 knobs. A 3-knob block costs ~45 tokens, which is the actual win.
# Measured, not estimated.
#
# Valid labels (the output vocabulary; config-resolution.md § "Labels" shows
# each line's shape):
#   rigor, review_mode, automation, workflow, docs.density, story_granularity,
#   qa.level, team.size, project.stage, automation_always_ask, testing.strict,
#   performance.enforce, feature_overrides, stack, code_roots, surfaces,
#   distribution (also accepted as release.distribution), compliance,
#   accessibility.
# An unknown label prints nothing and is named on `notes:` -- a skill asking for
# a label that does not exist must not silently run on defaults.
#
# <feature> (a PRD stem, design/prd/<stem>.md) additionally prints
# `workflow[<feature>]: …` -- the feature's override tier or the project value.
resolve_config() {
  _yaml_helper_set_root
  local want=""
  if [ "${1:-}" = "--keys" ]; then
    want=",${2:-},"
    if [ $# -ge 2 ]; then shift 2; else shift; fi
  fi
  local feature="${1:-}"
  local notes="" v s pair tab
  tab=$(printf '\t')
  # emit <label> — true when the label was requested (or nothing was restricted)
  _rc_want() { [ -z "$want" ] || case "$want" in *",$1,"*) return 0;; *) return 1;; esac; }

  if ! _yaml_helper_resolve_python; then
    notes="NO PYTHON INTERPRETER — YAML unreadable; defaults only"
  fi
  if [ ! -f "$_YH_ROOT/project.yaml" ]; then
    notes="${notes:+$notes; }project.yaml absent — defaults in use"
  elif [ ! -s "$_YH_ROOT/project.yaml" ]; then
    # An EMPTY project.yaml resolves to defaults; unannounced it is
    # indistinguishable from a healthy fully-defaulted project. Absence is
    # announced one line above; emptiness is the more suspicious state of the two
    # (a truncated write, an interrupted /setup-stack) and was the silent one.
    notes="${notes:+$notes; }project.yaml is EMPTY — defaults in use; if you configured this project, the file did not survive"
  fi
  local orphan
  orphan=$(validate_local_yaml_base 2>&1) || notes="${notes:+$notes; }$orphan"

  # Collect enum complaints (scalar values and array elements) from both files
  # so a typo is visible, not silent.
  local enum_err
  enum_err=$(validate_yaml_enum "$_YH_ROOT/project.yaml" 2>&1 >/dev/null)
  [ -n "$enum_err" ] && notes="${notes:+$notes; }$(echo "$enum_err" | tr '\n' ';' | sed 's/;$//') — ignored, chain continued"
  if [ -f "$_YH_ROOT/project.local.yaml" ]; then
    enum_err=$(validate_yaml_enum "$_YH_ROOT/project.local.yaml" 2>&1 >/dev/null)
    [ -n "$enum_err" ] && notes="${notes:+$notes; }local: $(echo "$enum_err" | tr '\n' ';' | sed 's/;$//')"
    # Locked keys in the local file. Separate from the enum check
    # above because their VALUES are legal — it is the location that is not, so
    # every value-shaped validation passes them and resolution then drops them
    # in silence. Reported, never applied: see validate_local_scope.
    # Collapsed to one note listing the keys: validate_local_scope prints a
    # full remedy sentence per key for direct callers, and three copies of it
    # would cost more of this block than every resolved value put together.
    local scope_err scope_keys
    scope_err=$(validate_local_scope "$_YH_ROOT/project.local.yaml" 2>&1 >/dev/null)
    if [ -n "$scope_err" ]; then
      scope_keys=$(printf '%s\n' "$scope_err" | sed -n 's/.*`\([^`]*\)`.*/\1/p' | paste -sd, - | sed 's/,/, /g')
      notes="${notes:+$notes; }local: not locally overridable, ignored — $scope_keys (move to project.yaml or delete)"
    fi
  fi

  # Unknown labels: named, never silently dropped.
  local lbl unknown=""
  if [ -n "$want" ]; then
    for lbl in $(printf '%s' "$want" | tr ',' ' '); do
      case "$lbl" in
        rigor|review_mode|automation|workflow|docs.density|story_granularity|qa.level|team.size|project.stage) ;;
        automation_always_ask|testing.strict|performance.enforce|feature_overrides) ;;
        stack|code_roots|surfaces|distribution|release.distribution|compliance|accessibility) ;;
        *) unknown="${unknown:+$unknown, }$lbl" ;;
      esac
    done
    [ -n "$unknown" ] && notes="${notes:+$notes; }unknown label ignored — $unknown"
  fi

  # Framing costs ~81 chars. For a skill reading 1-2 knobs that is more than the
  # inline chain it replaced, so bare lines are emitted instead -- "automation:
  # guided (project.local.yaml)" is self-describing without a banner. Measured:
  # single-knob skills were +226 chars WITH framing, negative without it.
  local nkeys=0
  if [ -n "$want" ]; then
    nkeys=$(printf '%s' "$want" | tr ',' '\n' | grep -c '[a-z]')
  fi
  local bare=0
  [ -n "$want" ] && [ "$nkeys" -le 2 ] && bare=1

  # One parse per file, shared by every label below: resolve_setting's hops
  # (_yaml_helper_cfg_scalar) and the stack/list labels all answer from these
  # snapshots until the end of this function. The enum and scope checks above
  # keep their own parse -- they must see exactly what a direct caller sees.
  _YH_LV_ON=0; _YH_LV_CACHE=""; _YH_LVL_CACHE=""
  if _yaml_helper_resolve_python; then
    _YH_LV_CACHE=$(_yaml_helper_project_leaves)
    [ -f "$_YH_ROOT/project.local.yaml" ] && _YH_LVL_CACHE=$(_yaml_helper_leaves "$_YH_ROOT/project.local.yaml" 2>/dev/null)
    _YH_LV_ON=1
  fi
  local lv="$_YH_LV_CACHE"

  if [ "$bare" = "1" ]; then
    :
  elif [ -n "$want" ]; then
    echo "=== CCSS Config (resolved: local->yaml->rigor->default; use as-is) ==="
  else
    echo "=== CCSS Resolved Config ==="
  fi
  for pair in modes.rigor:rigor \
              modes.review_mode:review_mode \
              modes.automation:automation \
              modes.workflow:workflow \
              docs.density:docs.density \
              modes.story_granularity:story_granularity \
              qa.level:qa.level \
              team.size:team.size \
              project.stage:project.stage; do
    _rc_want "${pair##*:}" || continue
    v=$(resolve_setting "${pair%%:*}")
    s="${v#*$tab}"; v="${v%%$tab*}"
    echo "${pair##*:}: ${v:-not set} ($s)"
  done

  # automation_always_ask: array-valued, so it does not go through resolve_setting.
  local aaa
  if _rc_want automation_always_ask; then
    aaa=$(get_effective_yaml_array modes.automation_always_ask 2>/dev/null)
    if [ -n "$aaa" ]; then
      echo "automation_always_ask: $(echo "$aaa" | tr '\n' ',' | sed 's/,$//; s/,/, /g') (configured)"
    else
      echo "automation_always_ask: $(echo "$_yaml_helper_always_ask_default" | tr '\n' ',' | sed 's/,$//; s/,/, /g') (default)"
    fi
  fi

  # testing.strict.*: reported as CONFIGURED STATE ONLY, never defaulted here.
  # Its unset default differs per skill by design. Each leaf goes through
  # resolve_setting, so a local override applies (the five are whitelisted)
  # and an invalid value falls through to `unset` instead of being handed on.
  local ts_out="" k tv
  if _rc_want testing.strict; then
    for k in logic integration ui e2e config; do
      tv=$(resolve_setting "testing.strict.$k"); tv="${tv%%$tab*}"
      ts_out="$ts_out $k=${tv:-unset}"
    done
    echo "testing.strict:${ts_out} (unset = each skill applies its own default)"
  fi

  # performance.enforce: warn | block | off, default `warn`.
  # Unlike testing.strict.* this DOES get defaulted here -- effects-map gives it
  # a single terminal default (`warn`) rather than a per-skill one, so resolving
  # it in one place keeps /perf-profile and /gate-check from disagreeing. It goes
  # through resolve_setting so an invalid value never wins and the line names
  # its provenance: the key is on the `/settings --local` whitelist, and "did
  # this FAIL come from the project or from my own project.local.yaml" is
  # exactly the question the line has to answer.
  local pe
  if _rc_want performance.enforce; then
    pe=$(resolve_setting performance.enforce)
    s="${pe#*$tab}"; pe="${pe%%$tab*}"
    echo "performance.enforce: ${pe:-warn} ($s)"
  fi

  # feature_overrides: dump the whole map so the per-feature skills need no
  # second call. Each tier is validated like any other enum: an invalid tier
  # never wins; it is dropped and named on notes.
  local fo_out="" fo_line stem tier fo_tier=""
  local fo_prefix="workflow_overrides.feature_overrides."
  if _rc_want feature_overrides || [ -n "$feature" ]; then
    while IFS= read -r fo_line; do
      [ -z "$fo_line" ] && continue
      stem="${fo_line%%$tab*}"; tier="${fo_line#*$tab}"
      case "|minimal|standard|full|" in
        *"|$tier|"*)
          fo_out="$fo_out $stem=$tier"
          [ "$stem" = "$feature" ] && fo_tier="$tier" ;;
        *)
          notes="${notes:+$notes; }$fo_prefix$stem: '$tier' is not a valid value (expected: minimal|standard|full) — ignored" ;;
      esac
    done <<EOF
$(printf '%s\n' "$lv" | awk -F '\t' -v p="$fo_prefix" \
    '$1 == "s" && index($2, p) == 1 { print substr($2, length(p) + 1) "\t" substr($0, length($1) + length($2) + 3) }')
EOF
  fi
  if _rc_want feature_overrides; then
    echo "feature_overrides:${fo_out:- none}"
  fi
  if [ -n "$feature" ]; then
    if [ -n "$fo_tier" ]; then
      echo "workflow[$feature]: $fo_tier (feature_overrides)"
    else
      v=$(resolve_setting modes.workflow); v="${v%%$tab*}"
      echo "workflow[$feature]: $v (no override — project value)"
    fi
  fi

  # stack: project.yaml only, plus the derived specialist routing. Every one of
  # the five layers appears either as `<layer>=…` or in `unset=`, so a skill
  # can tell "not configured" from "not printed". A layer counts as configured
  # when its configuring key is set: framework (web, mobile, backend),
  # database (data), provider (cloud).
  local st_parts="" st_unset="" st_routes="" layer main val seg ex x roots ov
  if _rc_want stack; then
    for layer in web mobile backend data cloud; do
      case "$layer" in
        data)  main="database" ;;
        cloud) main="provider" ;;
        *)     main="framework" ;;
      esac
      val=$(_yaml_helper_lv_scalar "$lv" "stack.layers.$layer.$main")
      if [ -z "$val" ]; then st_unset="${st_unset:+$st_unset,}$layer"; continue; fi
      seg="$layer=$val"
      case "$layer" in
        web|mobile|backend)
          x=$(_yaml_helper_lv_scalar "$lv" "stack.layers.$layer.version")
          [ -n "$x" ] && seg="$seg $x" ;;
      esac
      ex=""
      case "$layer" in
        web|mobile) set -- language ;;
        backend)    set -- language runtime ;;
        data)       set -- cache queue orm ;;
        cloud)      set -- iac ;;
      esac
      for k in "$@"; do
        x=$(_yaml_helper_lv_scalar "$lv" "stack.layers.$layer.$k")
        [ -n "$x" ] && ex="${ex:+$ex, }$k=$x"
      done
      [ -n "$ex" ] && seg="$seg ($ex)"
      case "$layer" in
        web|mobile|backend|cloud)
          roots=""
          while IFS= read -r x; do
            [ -z "$x" ] && continue
            roots="${roots:+$roots,}$(_yaml_helper_norm_dir "$x")"
          done <<EOF
$(_yaml_helper_lv_items "$lv" "stack.layers.$layer.root")
EOF
          [ -n "$roots" ] && seg="$seg @$roots" ;;
      esac
      st_parts="${st_parts:+$st_parts; }$seg"
      st_routes="${st_routes:+$st_routes, }$(_yaml_helper_route_specialist "$layer")"
      case "$layer" in
        web|mobile|backend)
          ov=$(_yaml_helper_lv_scalar "$lv" "specialists.$layer")
          if [ -n "$ov" ] && ! _yaml_helper_valid_specialist_override "$layer" "$ov"; then
            notes="${notes:+$notes; }specialists.$layer: '$ov' is not a $layer sub-specialist (or $layer-specialist) — ignored, derived routing used"
          fi ;;
      esac
    done
    if [ -z "$st_parts" ]; then
      echo "stack: unset — run /setup-stack"
    else
      x="stack: $st_parts"
      [ -n "$st_unset" ] && x="$x; unset=$st_unset"
      [ -z "$(_yaml_helper_lv_scalar "$lv" stack.pinned_on)" ] && x="$x pinned_on=unset"
      echo "$x [routing: $st_routes] (project.yaml)"
    fi
  fi

  # code_roots: every resolved root grouped by source, then the extension list
  # scans use. Unresolved is said in so many words -- never an empty line.
  local cr cr_groups exts
  if _rc_want code_roots; then
    cr=$(resolve_code_roots)
    if [ -z "$cr" ]; then
      echo "code_roots: unresolved — NOT CHECKED (set stack.layers.<layer>.root via /setup-stack)"
    else
      cr_groups=$(printf '%s\n' "$cr" | awk -F '\t' '
        NF >= 3 {
          k = $3 SUBSEP $2
          if (!($3 in seen)) { seen[$3] = 1; order[$3] = "" }
          if (!(k in dirs)) { order[$3] = order[$3] (order[$3] == "" ? "" : "\n") $2; dirs[k] = $1 }
          else { dirs[k] = dirs[k] "," $1 }
        }
        END {
          n = split("project.yaml missing workspace detected", srcs, " ")
          out = ""
          for (i = 1; i <= n; i++) {
            s = srcs[i]
            if (!(s in seen)) continue
            m = split(order[s], lays, "\n"); g = ""
            for (j = 1; j <= m; j++) g = g (g == "" ? "" : "; ") lays[j] "=" dirs[s SUBSEP lays[j]]
            out = out (out == "" ? "" : "; ") g " (" s ")"
          }
          print out
        }')
      exts=$(_yaml_helper_ext_derived)
      if [ -n "$exts" ]; then
        echo "code_roots: $cr_groups; extensions: $exts"
      else
        echo "code_roots: $cr_groups; extensions: default union — $(code_extensions)"
      fi
    fi
  fi

  # surfaces: array-element enum, project.yaml only. Invalid elements were
  # already named on notes by validate_yaml_enum; here they are dropped and the
  # rest survives. `[]` is invalid for this key and resolves to unset.
  local sf_allowed sf_out="" sf
  if _rc_want surfaces; then
    sf_allowed=$(_yaml_helper_array_allowed platform.surfaces)
    while IFS= read -r sf; do
      [ -z "$sf" ] && continue
      case "|$sf_allowed|" in *"|$sf|"*) ;; *) continue ;; esac
      case ", $sf_out, " in *", $sf, "*) continue ;; esac
      sf_out="${sf_out:+$sf_out, }$sf"
    done <<EOF
$(_yaml_helper_lv_items "$lv" platform.surfaces)
EOF
    if [ -n "$sf_out" ]; then
      echo "platform.surfaces: $sf_out (project.yaml)"
    else
      echo "platform.surfaces: (unset -- ask which surfaces ship)"
    fi
  fi

  # distribution: a scalar enum, so it goes through resolve_setting -- an
  # invalid value is dropped (and named on notes) and the key is not locally
  # overridable, so a value in project.local.yaml is ignored (and named on
  # notes) rather than winning. NO DEFAULT: unset means "ask how this release
  # ships" (obligation 2), never `web`.
  if _rc_want distribution || _rc_want release.distribution; then
    v=$(resolve_setting release.distribution)
    s="${v#*$tab}"; v="${v%%$tab*}"
    if [ -n "$v" ]; then
      echo "release.distribution: $v ($s)"
    else
      echo "release.distribution: (unset -- ask how this release ships)"
    fi
  fi

  # compliance: regions (array-element enum; `[]` = explicitly none) and
  # privacy.handles_pii (scalar enum through resolve_setting). Unset is not
  # false and not none: each unset part says "ask".
  local rg_allowed rg_out="" rg pii pii_src cp_set=0
  if _rc_want compliance; then
    rg_allowed=$(_yaml_helper_array_allowed compliance.regions)
    if _yaml_helper_lv_empty "$lv" compliance.regions; then
      rg_out="none"
    else
      while IFS= read -r rg; do
        [ -z "$rg" ] && continue
        case "|$rg_allowed|" in *"|$rg|"*) ;; *) continue ;; esac
        case ",$rg_out," in *",$rg,"*) continue ;; esac
        rg_out="${rg_out:+$rg_out,}$rg"
      done <<EOF
$(_yaml_helper_lv_items "$lv" compliance.regions)
EOF
    fi
    [ -n "$rg_out" ] && cp_set=1
    pii=$(resolve_setting privacy.handles_pii)
    pii_src="${pii#*$tab}"; pii="${pii%%$tab*}"
    [ -n "$pii" ] && cp_set=1
    x="compliance: regions=${rg_out:-(unset -- ask)} handles_pii=${pii:-(unset -- ask)}"
    [ "$cp_set" = 1 ] && x="$x (project.yaml)"
    echo "$x"
  fi

  # accessibility: a scalar enum through resolve_setting. Unset is not `none`.
  if _rc_want accessibility; then
    v=$(resolve_setting accessibility.target)
    s="${v#*$tab}"; v="${v%%$tab*}"
    if [ -n "$v" ]; then
      echo "accessibility.target: $v ($s)"
    else
      echo "accessibility.target: (unset -- ask; unset is not none)"
    fi
  fi

  _YH_LV_ON=0; _YH_LV_CACHE=""; _YH_LVL_CACHE=""

  if [ "$bare" = "1" ]; then
    # Bare form: values only. notes still surface, because a rejected enum value
    # or a missing interpreter must never be silent.
    [ -n "$notes" ] && echo "notes: $notes"
  elif [ -n "$want" ]; then
    # Terse form: the header already states the chain, and notes only appear
    # when something actually went wrong. Every line here is paid on every
    # invocation of every skill that bootstraps with it.
    [ -n "$notes" ] && echo "notes: $notes"
    echo "=== end ==="
  else
    echo "notes: ${notes:-none}"
    echo "Values above are fully resolved (local -> yaml -> rigor -> default). Use as-is."
    echo "An inline --review flag, if passed, overrides review_mode."
    echo "=== end CCSS config ==="
  fi
  return 0
}

# --- Direct execution: the skill-bootstrap entry point -----------------------
#
#   bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys a,b
#
# Skills cannot `source` this file in their `` !`cmd` `` bootstrap line. Claude
# Code permission-checks every injected command before the skill renders, and
# outside auto mode anything short of "allow" ABORTS the whole invocation --
# measured on 2.1.281, see .claude/docs/config-resolution.md. A `${VAR:-x}` or
# `$( )` in the command fails that check as "Contains expansion" and no grant can
# approve it; a `source … && resolve_config` compound needs every part approved.
# `${CLAUDE_SKILL_DIR}` is substituted as text before the check, so one plain
# `bash <path> resolve_config …` call is approvable by the matching grant in the
# skill's own `allowed-tools`. That is also what lets a Bash-less agent preload
# the skill (GitHub issue #128).
#
# Only resolve_config is dispatchable: the bootstrap is the one caller, and
# every name added here widens what a skill grant can reach. resolve_code_roots,
# list_code_files and code_extensions are for hooks and scripts that source
# this file; skills read the same facts from the `code_roots` label.
#
# ROOT. Run from a subdirectory, the skill shell's cwd has no project.yaml and
# $CLAUDE_PROJECT_DIR is the launch directory, not the repo root (measured), so
# rules 1-3 of _yaml_helper_set_root all miss. This file's own location is the
# one anchor that cannot drift: hooks/ sits two levels below the root. It only
# fills CLAUDE_PROJECT_DIR when that has no project.yaml, so rules 1-2 (cwd
# first, for nested projects) keep their precedence.
#
# ALWAYS exits 0: a non-zero exit from an injected command aborts the skill.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-}" in
    resolve_config)
      shift
      if [ -z "${CLAUDE_PROJECT_DIR:-}" ] || [ ! -f "$CLAUDE_PROJECT_DIR/project.yaml" ]; then
        _yh_self_root=$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)
        [ -n "$_yh_self_root" ] && CLAUDE_PROJECT_DIR="$_yh_self_root"
      fi
      resolve_config "$@"
      ;;
    *)
      echo "yaml-helper.sh: usage: bash yaml-helper.sh resolve_config [--keys l1,l2,...] [<feature>]"
      ;;
  esac
  exit 0
fi
