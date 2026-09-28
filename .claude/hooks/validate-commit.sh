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

# Claude Code PreToolUse hook: validates `git commit` commands before they run.
# Receives JSON on stdin with tool_input.command
# Exit 0 = allow (warnings on stderr), Exit 2 = block (stderr shown to Claude)
#
# Input schema (PreToolUse for Bash):
# { "tool_name": "Bash", "tool_input": { "command": "git commit -m ..." } }
#
# BLOCKS (exit 2) -- the three things a commit must never carry:
#   (a) a JSON or YAML file that does not parse, under the paths a runtime, a CI
#       runner or a skill reads with no human in between: config/**, docs/api/**,
#       **/locales/**, **/i18n/**, design/registry/*.yaml, docs/registry/*.yaml,
#       docs/architecture/tr-registry.yaml, .github/workflows/*, project.yaml.
#       JSON is parsed with the Python standard library. YAML is parsed with
#       PyYAML when it is importable; otherwise a standard-library structural
#       check runs and the hook prints
#         NOT CHECKED: full YAML parse (PyYAML unavailable)
#       A structural failure blocks; the absence of PyYAML never does.
#       CCSS_YAML_PARSER=stdlib forces the structural check (test hook).
#   (b) a secret in an added line of the staged diff: AWS access key IDs,
#       private-key headers, GitHub tokens, Slack tokens, Google API keys and
#       Stripe live secret keys. Allowlist: a matched token ending in EXAMPLE,
#       or a line carrying `pragma: allowlist secret`, is ignored.
#   (c) a credential file: .env / .env.* (except .env.example), *.keystore,
#       *.jks, *.p12, *.mobileprovision, and *.pem files holding a private key.
#
# WARNS (exit 0):
#   - google-services.json / GoogleService-Info.plist staged
#   - a staged PRD (design/prd/<feature>.md, never design/prd/reviews/) missing
#     a section its workflow tier requires (.claude/docs/templates/prd.md)
#   - hardcoded business values and absolute URL hosts in code outside tests
#     and config, under the resolved code roots
#   - TODO/FIXME/HACK without an owner -- the TODO(owner) form
#   - a commit message that is not Conventional Commits, or that carries no
#     story/task ID line -- read from -m; any other message source prints
#       NOT CHECKED: commit message (not passed with -m)
#
# Every check that cannot run says so (obligation 3 of
# .claude/rules/skill-authoring.md): a skipped check and a clean one must never
# produce the same output.

INPUT=$(cat)

# Parse command -- use jq if available, fall back to grep
if command -v jq >/dev/null 2>&1; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
else
    COMMAND=$(echo "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

# Only process git commit commands -- as the whole command or as one segment of
# a chained one (`pnpm test && git commit -m ...`). Anchoring on the first word
# alone let every chained commit through unchecked.
if ! printf '%s\n' "$COMMAND" | grep -qE '(^|[;&|(])[[:space:]]*git[[:space:]]+commit([[:space:]]|$)'; then
    exit 0
fi

WARNINGS=""
BLOCKS=""
_TAB=$(printf '\t')
_vc_warn()  { WARNINGS="${WARNINGS}${WARNINGS:+
}$*"; }
_vc_block() { BLOCKS="${BLOCKS}${BLOCKS:+
}$*"; }

# Resolve a Python 3 interpreter ONCE for every batched check below. Every scan
# that needs Python spawns it once for all of its items and shares this lookup.
# The version probe matters: `python` is Python 2 on some hosts and a store stub
# on stock Windows, and the programs below are Python 3 only.
_VC_PY=""
for _c in python python3 py; do
    if command -v "$_c" >/dev/null 2>&1 \
       && "$_c" -c 'import sys; sys.exit(0 if sys.version_info[0] >= 3 else 1)' >/dev/null 2>&1; then
        _VC_PY="$_c"
        break
    fi
done

# Without jq, the grep fallback above stops at the first escaped quote and
# cannot unescape newlines -- enough to recognise a commit, not to read its
# message. Now that this IS a commit, take the full command from the JSON.
if ! command -v jq >/dev/null 2>&1 && [ -n "$_VC_PY" ]; then
    _FULL=$(printf '%s' "$INPUT" | "$_VC_PY" -c '
import json, sys
try:
    cmd = (json.load(sys.stdin).get("tool_input") or {}).get("command") or ""
except Exception:
    cmd = ""
sys.stdout.buffer.write(cmd.encode("utf-8"))
' 2>/dev/null)
    [ -n "$_FULL" ] && COMMAND="$_FULL"
fi

# --- read the commit command itself ------------------------------------------
# One Python pass over the command answers two questions: does the commit use
# -a/--all (then tracked working-tree changes are part of the commit too), and
# what is the message? The message is read from -m / --message only, including
# the heredoc form `-m "$(cat <<'EOF' ... EOF)"`. Any other source (-F, -C,
# --amend without -m, the editor) is reported as NOT CHECKED, never guessed.
#
# Output: line 1 `ALL=0|1`, line 2 `STATE=OK|NONE|UNPARSEABLE`, then the
# message itself when STATE=OK.
read -r -d '' _VC_CMD_PY <<'PYEOF'
import re, shlex, sys

cmd = sys.stdin.read()
bodies = []

def heredoc(m):
    bodies.append(m.group(3))
    return "__CCSS_HEREDOC_%d__" % (len(bodies) - 1)

cmd = re.sub(r"\$\(\s*cat\s*<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1[ \t]*\n(.*?)\n[ \t]*\2[ \t]*\n?\s*\)",
             heredoc, cmd, flags=re.S)

def emit(all_flag, state, msg=""):
    out = "ALL=%d\nSTATE=%s\n%s" % (all_flag, state, msg)
    sys.stdout.buffer.write(out.encode("utf-8"))
    sys.exit(0)

try:
    lex = shlex.shlex(cmd, posix=True, punctuation_chars=True)
    lex.whitespace_split = True
    toks = list(lex)
except ValueError:
    emit(0, "UNPARSEABLE")

SEPARATORS = {";", "&", "&&", "|", "||", "(", ")", ";;"}
GIT_OPT_ARG = {"-C", "-c", "--git-dir", "--work-tree", "--namespace"}
LONG_ARG = {"--message", "--file", "--reuse-message", "--reedit-message", "--template",
            "--fixup", "--squash", "--author", "--date", "--cleanup", "--trailer",
            "--pathspec-from-file"}
OTHER_SOURCE = {"--file", "--reuse-message", "--reedit-message", "--fixup", "--squash"}

start = None
for i, t in enumerate(toks):
    if t != "git":
        continue
    j = i + 1
    while j < len(toks) and toks[j].startswith("-"):
        j += 2 if toks[j] in GIT_OPT_ARG else 1
    if j < len(toks) and toks[j] == "commit":
        start = j + 1
        break
if start is None:
    emit(0, "NONE")

args = []
for t in toks[start:]:
    if t in SEPARATORS:
        break
    args.append(t)

msgs, all_flag, other, k = [], 0, False, 0
while k < len(args):
    t = args[k]
    if t == "--":
        break
    if t.startswith("--"):
        name, eq, val = t.partition("=")
        if name == "--all":
            all_flag = 1
        if name in LONG_ARG and not eq:
            k += 1
            val = args[k] if k < len(args) else None
        if name == "--message":
            msgs.append(val)
        elif name in OTHER_SOURCE:
            other = True
    elif t.startswith("-") and len(t) > 1:
        p = 1
        while p < len(t):
            ch = t[p]
            if ch == "a":
                all_flag = 1
            if ch in "mFCct":
                rest = t[p + 1:]
                if not rest:
                    k += 1
                    rest = args[k] if k < len(args) else None
                if ch == "m":
                    msgs.append(rest)
                elif ch in "FCc":
                    other = True
                break
            if ch in "Su":
                break
            p += 1
    k += 1

if not msgs or None in msgs:
    emit(all_flag, "NONE")
msg = "\n\n".join(msgs)
if "$(" in msg or "`" in msg or re.search(r"\$\{?[A-Za-z_]", msg):
    emit(all_flag, "UNPARSEABLE")
msg = re.sub(r"__CCSS_HEREDOC_(\d+)__", lambda m: bodies[int(m.group(1))], msg)
emit(all_flag, "OK", msg)
PYEOF

VC_ALL=0
VC_MSG_STATE="NOPY"
VC_MSG=""
if [ -n "$_VC_PY" ]; then
    _VC_PARSED=$(printf '%s' "$COMMAND" | "$_VC_PY" -c "$_VC_CMD_PY" 2>/dev/null)
    VC_ALL=$(printf '%s\n' "$_VC_PARSED" | sed -n '1s/^ALL=//p')
    VC_MSG_STATE=$(printf '%s\n' "$_VC_PARSED" | sed -n '2s/^STATE=//p')
    VC_MSG=$(printf '%s\n' "$_VC_PARSED" | sed '1,2d')
    [ "$VC_ALL" = 1 ] || VC_ALL=0
    [ -n "$VC_MSG_STATE" ] || VC_MSG_STATE="UNPARSEABLE"
fi

# A `git add` chained in front of the commit stages its files AFTER this hook
# has run, so they are invisible here. Say so instead of implying they passed.
if printf '%s\n' "$COMMAND" | grep -qE '(^|[;&|(])[[:space:]]*git[[:space:]]+(add|stage)([[:space:]]|$)'; then
    _vc_warn "NOT CHECKED: files staged by the \`git add\` in this same command -- this hook runs before it. Stage in one command and commit in the next to have them checked."
fi

# The files this commit carries: the index, plus tracked working-tree changes
# when -a/--all is given. Deletions need no validation (and deleting a committed
# .env is exactly what should happen), so only added/copied/modified/renamed/
# type-changed paths are listed.
_vc_changed() {
    git diff --cached --name-only --diff-filter=ACMRT 2>/dev/null
    [ "$VC_ALL" = 1 ] && git diff --name-only --diff-filter=ACMRT 2>/dev/null
    return 0
}
_vc_diff() {
    git diff --cached -U0 --no-color --no-ext-diff --src-prefix=a/ --dst-prefix=b/ 2>/dev/null
    [ "$VC_ALL" = 1 ] && git diff -U0 --no-color --no-ext-diff --src-prefix=a/ --dst-prefix=b/ 2>/dev/null
    return 0
}
STAGED=$(_vc_changed | sort -u)

# Section findings are collected through a file, not a variable: the batched
# scans below write their report in one pass, and the scratch file must
# actually be WRITABLE -- that has to be tested rather than assumed. `mktemp`
# and the `${TMPDIR:-/tmp}` fallback beside it both aim at /tmp, which does not
# exist or is not writable in several environments this hook runs in -- notably
# sandboxed Windows shells. When the redirect failed, `[ -s "$TMP_SCAN" ]` was
# false, the section scan emitted nothing, and the hook exited 0: a check that
# could not run, reporting clean.
#
# So: try mktemp, then TMPDIR, then the repo's own .git directory (writable by
# definition -- `git diff --cached` has already succeeded against it), and PROVE
# each candidate by writing to it. If none works, TMP_SCAN stays empty and the
# scan announces that it did not run instead of skipping in silence.
TMP_SCAN=""
if [ -n "$STAGED" ]; then
    for _cand in "$(mktemp 2>/dev/null)" "${TMPDIR:+$TMPDIR/ccss-commit-$$}" \
                 "$(git rev-parse --git-dir 2>/dev/null)/ccss-commit-$$"; do
        [ -z "$_cand" ] && continue
        if : > "$_cand" 2>/dev/null; then TMP_SCAN="$_cand"; break; fi
    done
fi
trap '[ -n "$TMP_SCAN" ] && rm -f "$TMP_SCAN"' EXIT

# ---------------------------------------------------------------------------
# BLOCKING CHECKS FIRST. Everything after this block is advisory: it appends to
# $WARNINGS and the hook still exits 0. This block is the only one that can
# exit 2, and exit 2 is the reason the hook is registered.
#
# Two rules keep it inside the 15s hook budget on a large commit, and both were
# learned the hard way. Validating one file per interpreter spawn (~110ms each
# on Windows) got the hook killed by its timeout before it reached the corrupt
# file, so whether a bad file was caught depended on where its NAME SORTED.
# Measured with 201 staged files and one corrupt:
#
#   corrupt sorts FIRST -> 730ms,   rc=2,   BLOCKED emitted
#   corrupt sorts LAST  -> 15217ms, rc=124, nothing emitted, commit not blocked
#
#   (a) ORDER. The blocking checks run before any advisory work, so a starved
#       hook has already done the part that matters.
#   (b) COST. One interpreter validates every staged data file, one diff pass
#       feeds the secret scan, and one name filter finds the credential files:
#       the spawn count is constant in file count instead of linear. Making the
#       per-file shape merely faster is not enough -- the cost stays linear and
#       the hook starves again at a larger commit.
# ---------------------------------------------------------------------------
if [ -n "$STAGED" ]; then

# --- (a) data files that must parse -------------------------------------------
# The same path list and the same parse rule as validate-data-files.sh, which
# gives the same answer right after each Write/Edit.
DATA_FILE_RE='^(config/.+\.(json|ya?ml)|docs/api/.+\.(json|ya?ml)|(.+/)?(locales|i18n)/.+\.(json|ya?ml)|design/registry/[^/]+\.yaml|docs/registry/[^/]+\.yaml|docs/architecture/tr-registry\.yaml|\.github/workflows/[^/]+\.ya?ml|project\.yaml)$'

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

DATA_FILES=$(printf '%s\n' "$STAGED" | grep -E "$DATA_FILE_RE")
if [ -n "$DATA_FILES" ]; then
    if [ -n "$_VC_PY" ]; then
        # One spawn, all files. The list arrives on stdin so an unbounded number
        # of paths cannot overflow the argument limit.
        _PARSE_OUT=$(printf '%s\n' "$DATA_FILES" | "$_VC_PY" -c "$_CCSS_PARSE_PY" 2>/dev/null)
        while IFS= read -r _row; do
            case "$_row" in
                BAD*)
                    _kind=$(printf '%s' "$_row" | cut -f2)
                    _path=$(printf '%s' "$_row" | cut -f3)
                    _err=$(printf '%s' "$_row" | cut -f4-)
                    _vc_block "BLOCKED: $_path is not valid $_kind: $_err"
                    ;;
                NOYAML)
                    _vc_warn "NOT CHECKED: full YAML parse (PyYAML unavailable)"
                    ;;
            esac
        done <<EOF
$_PARSE_OUT
EOF
    else
        _vc_warn "NOT CHECKED: JSON/YAML parse of the staged config, API, locale, registry and workflow files (no Python 3 interpreter found)"
    fi
fi

# --- (c) credential files -------------------------------------------------------
# One name filter over the whole list; only the few candidates are looked at.
CRED_FILES=""
CRED_CANDIDATES=$(printf '%s\n' "$STAGED" \
    | grep -iE '(^|/)(\.env(\..+)?|[^/]+\.(keystore|jks|p12|mobileprovision|pem))$' \
    | grep -viE '(^|/)\.env\.example$')
while IFS= read -r _f; do
    [ -z "$_f" ] && continue
    _b=$(printf '%s' "${_f##*/}" | tr '[:upper:]' '[:lower:]')
    case "$_b" in
        .env|.env.*)
            _vc_block "BLOCKED: $_f is an environment file. Keep real values in the secret manager or an untracked .env; commit placeholders as .env.example." ;;
        *.pem)
            # A .pem is often a public certificate, which is fine to commit.
            # Only a private key blocks.
            grep -q 'PRIVATE KEY-----' "$_f" 2>/dev/null || continue
            _vc_block "BLOCKED: $_f holds a private key. Keep it in the secret manager (or CI secrets), never in the repository." ;;
        *.mobileprovision)
            _vc_block "BLOCKED: $_f is an Apple provisioning profile. Manage signing in CI (fastlane match, Xcode Cloud or EAS credentials), not in the repository." ;;
        *)
            _vc_block "BLOCKED: $_f is a signing or client-certificate store. Keep it in the secret manager or CI secrets (fastlane match, Play App Signing), never in the repository." ;;
    esac
    CRED_FILES="${CRED_FILES}${_f}
"
done <<EOF
$CRED_CANDIDATES
EOF

# --- (b) secrets in added lines --------------------------------------------------
# One diff pass: awk turns the zero-context diff into `path:line<TAB>added text`,
# lines carrying the allowlist pragma are dropped, and one grep finds the
# candidates. Only candidate lines (normally none) are examined one by one.
# Firebase client configs are handled by their own WARN below -- their API key
# is an identifier, not a credential -- so they are not scanned here.
SECRET_RE='AKIA[0-9A-Z]{16}|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{36,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|sk_live_[0-9a-zA-Z]{16,}'
SECRET_HITS=$(_vc_diff | awk '
    /^diff --git / { hdr = 1; next }
    hdr && /^\+\+\+ / { f = substr($0, 5); sub(/^b\//, "", f); hdr = 0; next }
    /^@@/ { hdr = 0; ln = 0
            if (match($0, /\+[0-9]+/)) ln = substr($0, RSTART + 1, RLENGTH - 1) + 0
            next }
    hdr { next }
    /^\+/ { n = f; sub(/^.*\//, "", n)
            if (n != "google-services.json" && n != "GoogleService-Info.plist")
                print f ":" ln "\t" substr($0, 2)
            ln++ }' \
    | grep -v -F 'pragma: allowlist secret' \
    | grep -E -e "$SECRET_RE" | head -n 200)
while IFS= read -r _hit; do
    [ -z "$_hit" ] && continue
    _loc=${_hit%%"$_TAB"*}
    _text=${_hit#*"$_TAB"}
    _file=${_loc%:*}
    case "
$CRED_FILES" in *"
$_file
"*) continue ;; esac
    _toks=$(printf '%s\n' "$_text" | grep -oE -e "$SECRET_RE")
    while IFS= read -r _t; do
        [ -z "$_t" ] && continue
        case "$_t" in *EXAMPLE) continue ;; esac
        case "$_t" in
            AKIA*)     _kind="AWS access key ID";      _shown="${_t:0:8}..." ;;
            -----*)    _kind="private key";            _shown="PEM header" ;;
            gh*)       _kind="GitHub token";           _shown="${_t:0:8}..." ;;
            xox*)      _kind="Slack token";            _shown="${_t:0:8}..." ;;
            AIza*)     _kind="Google API key";         _shown="${_t:0:8}..." ;;
            sk_live_*) _kind="Stripe live secret key"; _shown="${_t:0:12}..." ;;
            *)         _kind="secret";                 _shown="${_t:0:6}..." ;;
        esac
        _vc_block "BLOCKED: possible $_kind at $_loc ($_shown)."
    done <<EOF2
$_toks
EOF2
done <<EOF
$SECRET_HITS
EOF

if [ -n "$BLOCKS" ]; then
    if printf '%s\n' "$BLOCKS" | grep -q 'BLOCKED: possible '; then
        _vc_block "Secrets: remove the value from the change and rotate it if it was ever pushed or shared; load it from the secret manager or an untracked .env. A deliberate placeholder ends in EXAMPLE; a reviewed false positive takes a \`pragma: allowlist secret\` comment on the same line."
    fi
    if [ -n "$CRED_FILES" ]; then
        _vc_block "Credential files: unstage with \`git restore --staged <path>\` and add the pattern to .gitignore."
    fi
    {
        echo "=== Commit BLOCKED (validate-commit.sh) ==="
        printf '%s\n' "$BLOCKS"
        [ -n "$WARNINGS" ] && printf '%s\n' "$WARNINGS"
        echo "==========================================="
    } >&2
    exit 2
fi

fi  # STAGED non-empty -- end of the blocking checks

# ---------------------------------------------------------------------------
# ADVISORY CHECKS. Nothing below exits non-zero.
# ---------------------------------------------------------------------------

# Source the config helper ONCE, ahead of every consumer below. Detect success by
# asking whether the functions EXIST, not by the source's exit status: a sourced
# file returns the status of its last statement, which is incidental -- gating on
# it once left the tier check silently running on a fallback value.
_VC_HELPER=0
if [ -f .claude/hooks/yaml-helper.sh ]; then
    . .claude/hooks/yaml-helper.sh 2>/dev/null || true
    command -v resolve_setting >/dev/null 2>&1 \
        && command -v resolve_code_roots >/dev/null 2>&1 && _VC_HELPER=1
fi

if [ -n "$STAGED" ]; then

# --- Firebase client configs ---------------------------------------------------
FIREBASE_FILES=$(printf '%s\n' "$STAGED" | grep -E '(^|/)(google-services\.json|GoogleService-Info\.plist)$')
while IFS= read -r _f; do
    [ -z "$_f" ] && continue
    _vc_warn "WARN: $_f staged. A Firebase client config is not a credential, but its API key must be restricted (app or bundle ID and API restrictions in the Google Cloud console), and per-environment copies usually belong in CI rather than in the repository."
done <<EOF
$FIREBASE_FILES
EOF

# --- PRD sections required at this PRD's tier ------------------------------------
# The section contract is .claude/docs/templates/prd.md. The tier decides what is
# required -- all eleven at `full`, eight at `standard` (Business Rules &
# Calculations is conditional there and left to /prd-review, which can read what
# the feature defines), none at `minimal`, where the one-pager is the design
# record. A per-feature tier in workflow_overrides.feature_overrides replaces the
# project tier for that PRD, in both directions.
#
# Scope: design/prd/<feature>.md only. Review logs live in design/prd/reviews/
# and are never section-checked.
#
# ONE HEADING REGEX, shared with .claude/scripts/prd-structure-check.sh -- the
# same ERE, byte for byte:
#   grep -qiE "^##+[[:space:]]+([0-9]+[.)][[:space:]]+)?${s}"
# a heading of level ## or deeper, an optional numeric prefix "3. " or "3) ",
# then the section name -- case-insensitive, prefix match, `&` and `-` literal.
# prd-structure-check.sh runs it with -q, once per file. Here each (tier,
# section) pair runs it ONCE with -l over every staged PRD at that tier, which
# lists the PRDs that have the section -- the grep count follows the section
# lists below, never the number of staged PRDs. One grep per file x section
# pair costs a process each and starved this hook's budget on a bulk commit.
_vc_prd_required() {
    case "$1" in
        minimal)  printf '%s' "" ;;
        full)     printf '%s' "Overview|Goals & Non-Goals|User Value|Functional Requirements|Business Rules & Calculations|Edge Cases|Dependencies|Non-Functional Requirements|Configuration & Flags|Success Metrics & Instrumentation|Acceptance Criteria" ;;
        standard) printf '%s' "Overview|Goals & Non-Goals|Functional Requirements|Edge Cases|Dependencies|Non-Functional Requirements|Success Metrics & Instrumentation|Acceptance Criteria" ;;
    esac
}

PRD_FILES=$(printf '%s\n' "$STAGED" | grep -E '^design/prd/[^/]+\.md$')
if [ -n "$PRD_FILES" ]; then
    WORKFLOW=""
    FEATURE_TIERS=""
    if [ "$_VC_HELPER" = 1 ]; then
        WORKFLOW=$(resolve_setting modes.workflow 2>/dev/null | cut -f1)
        FEATURE_TIERS=$(resolve_config --keys feature_overrides 2>/dev/null \
            | sed -n 's/^feature_overrides:[[:space:]]*//p' | head -1)
        [ "$FEATURE_TIERS" = "none" ] && FEATURE_TIERS=""
    fi
    case "$WORKFLOW" in
        minimal|standard|full) ;;
        *) WORKFLOW="" ;;
    esac

    if [ -z "$WORKFLOW" ]; then
        # No fallback tier. Guessing one here would warn a minimal project about
        # sections it does not need, or stay silent on a full one.
        _vc_warn "NOT CHECKED: PRD sections (workflow tier unresolved)"
    elif [ -z "$TMP_SCAN" ]; then
        _vc_warn "SKIPPED: no writable scratch location, so the PRD section check did NOT run on the staged PRD(s)."
    else
        # One line per staged PRD on disk: "<path>\t<tier>\t<source>". A staged
        # deletion has no file to read, so it is not a PRD missing sections.
        PRD_ROWS=""
        MINIMAL_COUNT=0
        while IFS= read -r _f; do
            [ -z "$_f" ] && continue
            [ -f "$_f" ] || continue
            _stem=${_f##*/}; _stem=${_stem%.md}
            _tier="$WORKFLOW"; _src="workflow=$WORKFLOW"
            for _pair in $FEATURE_TIERS; do
                if [ "${_pair%%=*}" = "$_stem" ]; then
                    _tier="${_pair#*=}"; _src="feature_overrides.$_stem=$_tier"
                fi
            done
            if [ "$_tier" = "minimal" ]; then
                MINIMAL_COUNT=$((MINIMAL_COUNT + 1))
                continue
            fi
            PRD_ROWS="${PRD_ROWS}${_f}${_TAB}${_tier}${_TAB}${_src}
"
        done <<EOF
$PRD_FILES
EOF
        if [ "$MINIMAL_COUNT" -gt 0 ]; then
            _vc_warn "NOTE: PRD section check skipped for $MINIMAL_COUNT staged PRD(s) at tier minimal -- that tier requires no PRD sections (the one-pager is the design record)."
        fi
        if [ -n "$PRD_ROWS" ]; then
            # One grep per (tier, required section) over the PRDs at that tier.
            # _PS_HITS[k] holds the PRDs that HAVE section _PS_SEC[k], one per
            # line, exactly as grep -l prints the paths it was given.
            _NL='
'
            _k=0
            for _t in standard full; do
                _tfiles=$(printf '%s' "$PRD_ROWS" | awk -F '\t' -v t="$_t" '$2 == t { print $1 }')
                [ -z "$_tfiles" ] && continue
                while IFS= read -r _s; do
                    [ -z "$_s" ] && continue
                    _PS_TIER[$_k]="$_t"
                    _PS_SEC[$_k]="$_s"
                    _PS_HITS[$_k]=$(printf '%s\n' "$_tfiles" | tr '\n' '\000' \
                        | xargs -0 grep -liE "^##+[[:space:]]+([0-9]+[.)][[:space:]]+)?${_s}" 2>/dev/null)
                    _k=$((_k + 1))
                done <<EOF
$(_vc_prd_required "$_t" | tr '|' '\n')
EOF
            done
            # The report goes through the proven-writable scratch file, in
            # staged order: one line per PRD missing a section its tier requires.
            while IFS="$_TAB" read -r _f _t _src; do
                [ -z "$_f" ] && continue
                _missing=""
                _j=0
                while [ "$_j" -lt "$_k" ]; do
                    if [ "${_PS_TIER[$_j]}" = "$_t" ]; then
                        case "$_NL${_PS_HITS[$_j]}$_NL" in
                            *"$_NL$_f$_NL"*) ;;
                            *) _missing="${_missing:+$_missing, }${_PS_SEC[$_j]}" ;;
                        esac
                    fi
                    _j=$((_j + 1))
                done
                if [ -n "$_missing" ]; then
                    printf 'PRD: %s is missing section(s) required at %s: %s\n' "$_f" "$_src" "$_missing"
                fi
            done > "$TMP_SCAN" 2>/dev/null <<EOF
$PRD_ROWS
EOF
            if [ -s "$TMP_SCAN" ]; then
                while IFS= read -r _line; do
                    [ -n "$_line" ] && _vc_warn "$_line"
                done < "$TMP_SCAN"
                _vc_warn "      Template: .claude/docs/templates/prd.md -- run /prd-review for the content review."
            fi
        fi
    fi
fi

# --- code under the resolved code roots -------------------------------------------
# There is no fixed code root. resolve_code_roots (yaml-helper) prints one
# `<dir>\t<layer>\t<source>` line per declared root, per undeclared workspace
# package (apps/*, services/*, packages/* holding a manifest) and, for a
# single-app repo, the one detected root. A staged file is in scope when it lies
# under any root; the longest matching root names its layer.
#
# Scans are batched through xargs so the spawn count is bounded by total path
# length rather than by file count. NUL-delimited, NOT `-d '\n'`: both `-d` and
# `-r` are GNU-only, BSD xargs (macOS) rejects `-d`, and because these pipelines
# end in `|| true` the rejection would be SILENT -- an empty result that reads as
# a clean scan. `-0` exists in both. `grep -l` names files without printing the
# matched lines.
DEFAULT_EXTS="ts tsx js jsx mjs cjs vue svelte py java kt kts swift dart go rb php cs rs sql tf"
CODE_ROOTS=""
UNDECLARED=""
CODE_EXTS=""
if [ "$_VC_HELPER" = 1 ]; then
    _CR=$(resolve_code_roots 2>/dev/null)
    CODE_ROOTS=$(printf '%s\n' "$_CR" | awk -F '\t' '$1 != "" && $3 != "missing" { print $1 "\t" $2 }')
    UNDECLARED=$(printf '%s\n' "$_CR" | awk -F '\t' '$2 == "undeclared" { print $1 }')
    CODE_EXTS=$(code_extensions 2>/dev/null)
fi
[ -n "$CODE_EXTS" ] || CODE_EXTS="$DEFAULT_EXTS"

if [ -z "$CODE_ROOTS" ]; then
    # Only when code is actually being committed, so a docs-only or config-only
    # commit stays quiet and the notice keeps its meaning.
    _ANY_EXT_RE="\\.($(printf '%s' "$DEFAULT_EXTS" | tr ' ' '|'))\$"
    if printf '%s\n' "$STAGED" | grep -qE "$_ANY_EXT_RE"; then
        if [ "$_VC_HELPER" = 1 ]; then
            _why="no code root resolved"
        else
            _why="yaml-helper unavailable, so no code root could be resolved"
        fi
        _vc_warn "SKIPPED: code files are staged but $_why -- the hardcoded-value, URL-host and TODO-owner scans did NOT run. Set stack.layers.<layer>.root via /setup-stack."
    fi
else
    # "<path>\t<layer>" for every staged file under a root (longest root wins).
    IN_ROOTS=$(printf '%s\n' "$STAGED" | VC_ROOTS="$CODE_ROOTS" awk '
        BEGIN {
            n = split(ENVIRON["VC_ROOTS"], r, "\n")
            for (i = 1; i <= n; i++) {
                if (split(r[i], p, "\t") >= 1 && p[1] != "") { m++; dir[m] = p[1]; lay[m] = p[2] }
            }
        }
        $0 != "" {
            best = 0; bl = -1
            for (i = 1; i <= m; i++) {
                d = dir[i]
                if ((d == "." || index($0, d "/") == 1) && length(d) > bl) { best = i; bl = length(d) }
            }
            if (best) print $0 "\t" lay[best]
        }')

    if [ -n "$UNDECLARED" ] && printf '%s\n' "$IN_ROOTS" | awk -F '\t' '$2 == "undeclared" { f = 1 } END { exit !f }'; then
        _vc_warn "WARN: undeclared code roots: $(printf '%s\n' "$UNDECLARED" | paste -sd ',' - | sed 's/,/, /g') — declare them with /setup-stack"
    fi

    SRC_FILES=$(printf '%s\n' "$IN_ROOTS" | cut -f1 | sed '/^$/d')

    # Business values and URL hosts belong to application code: IaC (cloud
    # layer) and migrations (data layer) are configuration by nature, and tests,
    # fixtures, seeds, stories and framework config files are allowed literals.
    _EXT_RE="\\.($(printf '%s\n' $CODE_EXTS | grep -vxE 'sql|tf|tfvars' | paste -sd '|' -))\$"
    _NOT_APP_RE='(^|/)(tests?|__tests__|__mocks__|e2e|specs?|fixtures?|mocks?|seeds?|migrations|stories|config|configs)/|\.(test|spec|stories|config|conf)\.[A-Za-z0-9]+$|(^|/)test_[^/]*\.py$|_test\.(go|py)$|Tests?\.(kt|java|swift)$'
    APP_FILES=$(printf '%s\n' "$IN_ROOTS" | awk -F '\t' '$2 != "data" && $2 != "cloud" && $1 != "" { print $1 }' \
        | grep -E "$_EXT_RE" | grep -vE "$_NOT_APP_RE")

    if [ -n "$APP_FILES" ]; then
        HARDCODED=$(printf '%s\n' "$APP_FILES" | tr '\n' '\0' \
            | xargs -0 grep -lE '(price|amount|fee|limit|quota|timeout|ttl|max_[a-z_]+)[[:space:]]*[:=][[:space:]]*[0-9]+' 2>/dev/null || true)
        while IFS= read -r _f; do
            [ -n "$_f" ] && _vc_warn "CODE: $_f may hardcode business values (price, amount, fee, limit, quota, timeout, ttl, max_*). Read them from config or feature flags and cite the PRD rule (## Business Rules & Calculations)."
        done <<EOF
$HARDCODED
EOF

        # Absolute URL hosts: comment lines are documentation links, and a few
        # hosts are namespaces or reserved placeholders rather than endpoints.
        HOSTS=$(printf '%s\n' "$APP_FILES" | tr '\n' '\0' \
            | xargs -0 grep -HnE 'https?://[A-Za-z0-9]' 2>/dev/null \
            | awk '
                {
                    f = $0; sub(/:[0-9]+:.*$/, "", f)
                    c = $0; sub(/^[^:]*:[0-9]+:/, "", c)
                    t = c; sub(/^[ \t]+/, "", t)
                    if (t ~ /^(\/\/|#|\*|\/\*|<!--|--)/) next
                    s = c
                    while (match(s, /https?:\/\/[A-Za-z0-9.-]+/)) {
                        h = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
                        sub(/^https?:\/\//, "", h); lh = tolower(h)
                        if (lh == "localhost" || lh == "127.0.0.1" || lh == "0.0.0.0") continue
                        if (lh ~ /(^|\.)(example\.(com|org|net)|w3\.org|schema\.org|json-schema\.org|localhost)$/) continue
                        if (lh ~ /\.(example|test|invalid|local)$/) continue
                        if (!(f in seen)) { seen[f] = lh; order[++n] = f }
                    }
                }
                END { for (i = 1; i <= n; i++) print order[i] "\t" seen[order[i]] }' || true)
        while IFS= read -r _row; do
            [ -z "$_row" ] && continue
            _vc_warn "CODE: ${_row%%"$_TAB"*} hardcodes the absolute URL host '${_row#*"$_TAB"}'. Read base URLs from config or the environment so local, staging and production differ by configuration only."
        done <<EOF
$HOSTS
EOF
    fi

    # TODO/FIXME/HACK without an owner. Not extension-bounded: an unowned TODO is
    # worth flagging in a migration, a Terraform file or a build script too.
    # -I skips binary files.
    if [ -n "$SRC_FILES" ]; then
        UNOWNED=$(printf '%s\n' "$SRC_FILES" | tr '\n' '\0' \
            | xargs -0 grep -IlE '(^|[^A-Za-z0-9_])(TODO|FIXME|HACK)([^(A-Za-z0-9_]|$)' 2>/dev/null || true)
        while IFS= read -r _f; do
            [ -n "$_f" ] && _vc_warn "STYLE: $_f has a TODO/FIXME/HACK without an owner. Use the TODO(owner) form."
        done <<EOF
$UNOWNED
EOF
    fi
fi

fi  # STAGED non-empty -- end of the file-based advisory checks

# --- commit message ------------------------------------------------------------------
# Conventional Commits subject plus a story/task reference, per
# .claude/docs/coding-standards.md. Advisory: the message is the user's to write.
case "$VC_MSG_STATE" in
    OK)
        _SUBJECT=$(printf '%s\n' "$VC_MSG" | sed '/^[[:space:]]*$/d' | head -1)
        if ! printf '%s\n' "$_SUBJECT" | grep -qE '^(feat|fix|chore|docs|test|refactor|perf|build|ci|revert)(\(.+\))?!?: '; then
            _vc_warn "MESSAGE: subject is not Conventional Commits -- expected '<type>(<scope>)!: <summary>' with type feat|fix|chore|docs|test|refactor|perf|build|ci|revert (got: \"$_SUBJECT\")."
        fi
        # A story/task ID line: a reference trailer (Story:, Task:, Refs: ...) or
        # a recognisable ID -- a story file, TR-<feature>-NNN, BUG-NNNN,
        # INC-YYYYMMDD-NN, a tracker key such as MOA-123, or #123.
        if ! printf '%s\n' "$VC_MSG" | grep -qiE '^[[:space:]]*(story|task|refs?|closes|fixes|resolves|issue|bug|incident)[[:space:]]*:[[:space:]]*[^[:space:]]' \
           && ! printf '%s\n' "$VC_MSG" | grep -qE '(story-[0-9]{3}|TR-[a-z0-9-]+-[0-9]{3}|BUG-[0-9]{4}|INC-[0-9]{8}-[0-9]{2}|(^|[^A-Za-z0-9])[A-Z][A-Z0-9]+-[0-9]+([^0-9]|$)|(^|[[:space:](])#[0-9]+)'; then
            _vc_warn "MESSAGE: no story/task ID line. Add one to the body, e.g. -m \"Story: production/epics/goals-core/story-001-create-goal.md\"."
        fi
        ;;
    NOPY)
        _vc_warn "NOT CHECKED: commit message (no Python 3 interpreter to parse the command)" ;;
    *)
        _vc_warn "NOT CHECKED: commit message (not passed with -m)" ;;
esac

# Print warnings (non-blocking) and allow the commit
if [ -n "$WARNINGS" ]; then
    {
        echo "=== Commit Validation Warnings ==="
        printf '%s\n' "$WARNINGS"
        echo "=================================="
    } >&2
fi

exit 0
