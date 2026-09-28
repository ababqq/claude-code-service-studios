#!/bin/bash

# --- work from the project root ----------------------------------------------
# Every path below is repo-relative, so a hook invoked with a working directory
# that is not the repo root would silently read and write the WRONG TREE --
# returning a near-empty result instead of the session-recovery block, and
# creating stray trees such as docs/production/session-logs/ on write.
#
# PRECEDENCE IS LOAD-BEARING. A cwd that IS a project root carries real
# information and must win: a caller sitting inside another project means that
# project, not this one. Resolving to the script's own location first would
# override them. So, in order:
#   1. cwd holds project.yaml   -> cwd   (a project root)
#   2. cwd holds .claude/       -> cwd   (a project root not yet configured)
#   3. CLAUDE_PROJECT_DIR       -> that  (populated in the hook environment)
#   4. this script's location   -> <root>/.claude/hooks/../.. by construction
# Rule 4 always works and needs no environment at all; rules 1-2 stop it from
# overriding a caller that legitimately means somewhere else.
#
# NOT an upward search: that resolves a nested project to its parent's config.
if [ -f "project.yaml" ] || [ -d ".claude" ]; then
  CCSS_ROOT="$PWD"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}" ]; then
  CCSS_ROOT="$CLAUDE_PROJECT_DIR"
else
  CCSS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
fi
[ -n "$CCSS_ROOT" ] && cd "$CCSS_ROOT" 2>/dev/null || true

# Claude Code PostToolUse hook: validates JSON/YAML data files after Write/Edit.
#
# Scope -- the same path list validate-commit.sh blocks on, because these are the
# files a runtime, a CI runner or a skill reads with no human in between:
#   config/**, docs/api/**, **/locales/**, **/i18n/**, design/registry/*.yaml,
#   docs/registry/*.yaml, docs/architecture/tr-registry.yaml,
#   .github/workflows/*, project.yaml
# (JSON and YAML files only; tsconfig/jsconfig files are JSON with comments and
# are skipped.) There are no naming rules here: file names follow `naming.files`
# and the stack's own conventions, which a path hook cannot know.
#
# Parse rule -- the same as validate-commit.sh: JSON with the Python standard
# library; YAML with PyYAML when it is importable, otherwise a standard-library
# structural check plus the line
#   NOT CHECKED: full YAML parse (PyYAML unavailable)
# CCSS_YAML_PARSER=stdlib forces the structural check (test hook).
#
# Exit behavior:
#   exit 0 = the file parses, is out of scope, or could not be checked (said so)
#   exit 2 = the file does not parse: `Invalid <JSON|YAML> in <path>: <error>`
#
# A PostToolUse hook CANNOT block -- the write has already happened by the time
# this runs (see .claude/docs/hooks-reference/hook-input-schemas.md). The only
# question is who hears about it, and that is what the exit code selects:
#   exit 1 -> stderr goes to the USER only. Claude never sees it, so a JSON file
#             it just corrupted looks like it wrote cleanly and it moves on.
#   exit 2 -> stderr is fed back to CLAUDE as actionable feedback, so it can fix
#             the file it just wrote.
# Exiting 1 while printing "fix before proceeding" would be a promise the hook
# cannot keep, delivered to the one party who cannot act on it.
#
# Input schema (PostToolUse for Write/Edit):
# { "tool_name": "Write", "tool_input": { "file_path": "/abs/path/config/plans.yaml", "content": "..." } }

INPUT=$(cat)

# Parse file path -- use jq if available, fall back to grep
if command -v jq >/dev/null 2>&1; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
    FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi
[ -z "$FILE_PATH" ] && exit 0

# Normalize path separators (Windows backslash to forward slash).
# Two rules, order significant -- see the long note in validate-skill-change.sh.
# Short version: hook input is JSON, so a Windows path arrives as `\\`. Without
# jq the fallback cannot unescape it, and a single-rule sed turns each escaped
# pair into two slashes, so no path test below matches and this hook silently
# validates nothing on Windows.
FILE_PATH=$(printf '%s' "$FILE_PATH" | sed 's|\\\\|/|g; s|\\|/|g')

# Make the path repo-relative. Write and Edit pass ABSOLUTE paths, and the scope
# list is anchored at the repo root (`config/**` must not match some other
# tree's config/). Try the logical root, the physical root (symlinked temp or
# home directories) and, on Windows shells, the drive-letter form.
REL=""
case "$FILE_PATH" in
    /*|[A-Za-z]:/*)
        for _root in "$PWD" "$(pwd -P 2>/dev/null)" "$(pwd -W 2>/dev/null)"; do
            [ -z "$_root" ] && continue
            case "$FILE_PATH" in
                "$_root"/*) REL="${FILE_PATH#"$_root"/}"; break ;;
            esac
        done
        # Absolute and outside this project: not ours to validate.
        [ -z "$REL" ] && exit 0
        ;;
    *)
        REL="${FILE_PATH#./}"
        ;;
esac

DATA_FILE_RE='^(config/.+\.(json|ya?ml)|docs/api/.+\.(json|ya?ml)|(.+/)?(locales|i18n)/.+\.(json|ya?ml)|design/registry/[^/]+\.yaml|docs/registry/[^/]+\.yaml|docs/architecture/tr-registry\.yaml|\.github/workflows/[^/]+\.ya?ml|project\.yaml)$'
if ! printf '%s\n' "$REL" | grep -qE "$DATA_FILE_RE"; then
    exit 0
fi
[ -f "$REL" ] || exit 0

_PY=""
for _c in python python3 py; do
    if command -v "$_c" >/dev/null 2>&1 \
       && "$_c" -c 'import sys; sys.exit(0 if sys.version_info[0] >= 3 else 1)' >/dev/null 2>&1; then
        _PY="$_c"
        break
    fi
done
if [ -z "$_PY" ]; then
    # Say so rather than skipping in silence: without an interpreter this hook
    # exits 0 on a file it never opened -- indistinguishable from a valid one.
    echo "NOT CHECKED: JSON/YAML parse of $REL (no Python 3 interpreter found)" >&2
    exit 0
fi

# SHARED PARSE PROGRAM -- byte-identical in validate-commit.sh and
# validate-data-files.sh; change both or neither. Paths arrive on stdin, one per
# line. Output (bytes): `BAD\t<JSON|YAML>\t<path>\t<error>` per file that does
# not parse, then `NOYAML` once when any YAML file got only the structural check.
read -r -d '' _CCSS_PARSE_PY <<'PYEOF'
import json, os, re, sys

yaml = None
if os.environ.get("CCSS_YAML_PARSER", "") != "stdlib":
    try:
        import yaml
    except Exception:
        yaml = None

# tsconfig/jsconfig files are JSON with comments by definition (the TypeScript
# compiler reads them that way), so a strict JSON parse would be a false block.
JSONC = re.compile(r"^(tsconfig|jsconfig)([.-][^/]*)?\.json$")

def one_line(msg):
    return " ".join(str(msg).split())[:300]

def check_json(path):
    with open(path, "r", encoding="utf-8-sig") as fh:
        json.load(fh)

if yaml is not None:
    class _Loader(yaml.SafeLoader):
        pass

    def _local_tag(loader, suffix, node):
        # Local tags (!Ref, !Sub, !reference) belong to the consuming tool; an
        # unknown tag is not a syntax error.
        if isinstance(node, yaml.ScalarNode):
            return loader.construct_scalar(node)
        if isinstance(node, yaml.SequenceNode):
            return loader.construct_sequence(node)
        return loader.construct_mapping(node)

    _Loader.add_multi_constructor("!", _local_tag)

    def check_yaml(path):
        with open(path, "r", encoding="utf-8-sig") as fh:
            for _doc in yaml.load_all(fh, Loader=_Loader):
                pass
else:
    # Structural check, standard library only. It flags what is certainly
    # broken -- tab indentation, a quoted string or a flow collection
    # ([..] / {..}) that is never closed or closes the wrong bracket, a line
    # that is neither a mapping entry nor a list item -- and never blocks valid
    # YAML: block-scalar bodies (`run: |`) are free text, and flow collections,
    # quoted strings and plain scalars may continue on the following lines. It
    # is not a parser -- the NOT CHECKED line says so.
    BLOCK_SCALAR = re.compile(r"(^|:[ \t]+)[|>][1-9+-]{0,2}$")

    def close_quote(s, j, q):
        n = len(s)
        while j < n:
            if q == '"' and s[j] == "\\":
                j += 2
                continue
            if s[j] == q:
                if q == "'" and j + 1 < n and s[j + 1] == "'":
                    j += 2
                    continue
                return j + 1
            j += 1
        return -1

    def scan(s, depth, quote):
        # Walk one line. depth / quote carry an open flow collection or quoted
        # scalar from earlier lines. Returns (mapping_colon, depth, quote,
        # value_kind, comment_start, error).
        colon, kind, start, i, n = False, None, True, 0, len(s)
        if quote:
            i = close_quote(s, 0, quote)
            if i < 0:
                return colon, depth, quote, kind, n, None
            quote, start = "", False
        while i < n:
            c = s[i]
            if c == "#" and (i == 0 or s[i - 1] in " \t"):
                return colon, depth, quote, kind, i, None
            if c in " \t":
                i += 1
                continue
            if start and c in "\"'":
                if not depth:
                    kind = "quoted"
                j = close_quote(s, i + 1, c)
                if j < 0:
                    return colon, depth, c, kind, n, None
                i, start = j, False
                continue
            if c in "[{" and (start or depth):
                if not depth:
                    kind = "flow"
                depth = depth + [c]
                i, start = i + 1, True
                continue
            if c in "]}" and depth:
                if (c == "]") != (depth[-1] == "["):
                    return colon, depth, quote, kind, n, "'%s' closes '%s'" % (c, depth[-1])
                depth = depth[:-1]
                i, start = i + 1, False
                continue
            if c == "," and depth:
                i, start = i + 1, True
                continue
            if c == ":" and (i + 1 == n or s[i + 1] in " \t" or (depth and s[i + 1] in ",]}")):
                if not depth:
                    colon, kind = True, None
                i, start = i + 1, True
                continue
            if start and not depth:
                kind = "plain"
            i, start = i + 1, False
        return colon, depth, quote, kind, n, None

    def check_yaml(path):
        with open(path, "r", encoding="utf-8-sig", errors="replace") as fh:
            lines = fh.read().splitlines()
        block = -1          # block scalar body: lines indented deeper than this
        cont = -1           # plain scalar: deeper lines without ': ' continue it
        depth, quote, opened = [], "", 0
        for no, raw in enumerate(lines, 1):
            sp = len(raw) - len(raw.lstrip(" "))
            if block >= 0:
                if not raw.strip() or sp > block:
                    continue
                block = -1
            if depth or quote:
                _c, depth, quote, _k, _cut, err = scan(raw.lstrip(" \t"), depth, quote)
                if err:
                    raise ValueError("line %d: %s" % (no, err))
                continue
            body = raw.lstrip(" \t")
            if not body or body.startswith("#"):
                continue
            if "\t" in raw[:len(raw) - len(body)]:
                raise ValueError("line %d: tab character in indentation (YAML indents with spaces)" % no)
            if sp == 0 and body[:3] in ("---", "...") or body.startswith("%"):
                cont = -1
                continue
            if cont >= 0 and sp > cont and not scan(body, [], "")[0]:
                continue
            cont = -1
            s, item = body, False
            while s == "-" or s.startswith("- "):
                item, s = True, s[1:].lstrip(" ")
            if not s or s.startswith("#") or s.startswith("? "):
                continue
            colon, depth, quote, kind, cut, err = scan(s, [], "")
            if err:
                raise ValueError("line %d: %s" % (no, err))
            if depth or quote:
                opened = no
                continue
            if not item and not colon:
                raise ValueError("line %d: neither a 'key: value' entry nor a '- ' list item" % no)
            col = sp + (len(body) - len(s)) if colon else sp
            if BLOCK_SCALAR.search(s[:cut].rstrip()):
                block = col
            elif kind == "plain":
                cont = col
        if quote:
            raise ValueError("line %d: %s-quoted string is never closed"
                             % (opened, "double" if quote == '"' else "single"))
        if depth:
            raise ValueError("line %d: '%s' is never closed" % (opened, depth[-1]))

out, fallback = [], False
for line in sys.stdin.read().splitlines():
    path = line.strip()
    if not path or not os.path.isfile(path):
        continue
    name = os.path.basename(path)
    low = name.lower()
    if low.endswith(".json"):
        if JSONC.match(low):
            continue
        kind, check = "JSON", check_json
    elif low.endswith(".yaml") or low.endswith(".yml"):
        kind, check = "YAML", check_yaml
        if yaml is None:
            fallback = True
    else:
        continue
    try:
        check(path)
    except Exception as exc:
        out.append("BAD\t%s\t%s\t%s" % (kind, path, one_line(exc)))
if fallback:
    out.append("NOYAML")
# Bytes, not text. Python text-mode stdout on Windows rewrites \n as \r\n,
# putting a CR inside every path but the last.
sys.stdout.buffer.write(("\n".join(out) + ("\n" if out else "")).encode("utf-8"))
PYEOF

RESULT=$(printf '%s\n' "$REL" | "$_PY" -c "$_CCSS_PARSE_PY" 2>/dev/null)
STATUS=0
while IFS= read -r _row; do
    case "$_row" in
        BAD*)
            _kind=$(printf '%s' "$_row" | cut -f2)
            _err=$(printf '%s' "$_row" | cut -f4-)
            echo "Invalid $_kind in $REL: $_err" >&2
            STATUS=2
            ;;
        NOYAML)
            echo "NOT CHECKED: full YAML parse (PyYAML unavailable)" >&2
            ;;
    esac
done <<EOF
$RESULT
EOF

if [ "$STATUS" = 2 ]; then
    echo "The file was written but does not parse. Fix it now, before continuing -- validate-commit.sh blocks the commit until it does." >&2
fi
exit "$STATUS"
