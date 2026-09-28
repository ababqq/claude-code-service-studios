# Hook: pre-commit-code-quality

## Trigger

Runs before any commit that stages source files under the project's code roots (a git `pre-commit` hook).
Optional — install it for every contributor; `validate-commit.sh` already guards Claude's own commits.

## Purpose

Keeps code that fails the project's linters, formatters or type check out of version control, and stops
secrets at the developer's machine instead of at the remote's push protection. It runs the project's **own**
commands — `commands.lint` and `commands.typecheck` in `project.yaml`, written by `/setup-stack` and `/test-setup`
— so the hook and CI can never disagree about what "clean" means. Per-file tools run on staged files only to stay
fast; the type check runs project-wide because types cross file boundaries.

## Implementation

### Option A — plain git hook (`.git/hooks/pre-commit`, or `core.hooksPath`)

```bash
#!/bin/bash
# Pre-commit hook: lint, format check, type check and secret scan.
# Blocks on failure (exit 1). Bypass for an emergency with `git commit --no-verify`
# and say so in the pull request.

ROOT=$(git rev-parse --show-toplevel) || exit 1
cd "$ROOT" || exit 1

STAGED=$(git diff --cached --name-only --diff-filter=ACMR)
[ -z "$STAGED" ] && exit 0

# --- project commands (commands.<name> in project.yaml; an OS map is allowed) ---
cmd_for() {  # cmd_for lint -> the configured command, or nothing
    [ -f .claude/hooks/yaml-helper.sh ] || return 0
    . .claude/hooks/yaml-helper.sh
    local os="linux" v=""
    case "$(uname -s)" in Darwin) os="macos" ;; MINGW*|MSYS*|CYGWIN*) os="windows" ;; esac
    v=$(get_yaml_key project.yaml "commands.$1.$os")
    [ -z "$v" ] && v=$(get_yaml_key project.yaml "commands.$1.default")
    [ -z "$v" ] && v=$(get_yaml_key project.yaml "commands.$1")
    printf '%s' "$v"
}

EXIT_CODE=0
run() {  # run <label> <command...>
    echo "--- $1"
    shift
    "$@" || { echo "FAILED: $*"; EXIT_CODE=1; }
}

# Files by family (staged, still present)
TS=$(printf '%s\n' "$STAGED" | grep -E '\.(ts|tsx|js|jsx|mjs|cjs|vue|svelte)$')
PY=$(printf '%s\n' "$STAGED" | grep -E '\.py$')
KT=$(printf '%s\n' "$STAGED" | grep -E '\.kts?$')
SWIFT=$(printf '%s\n' "$STAGED" | grep -E '\.swift$')
FMT=$(printf '%s\n' "$STAGED" | grep -E '\.(ts|tsx|js|jsx|mjs|cjs|vue|svelte|json|css|scss|md|ya?ml)$')

# --- 1. Project lint command, when configured --------------------------------
LINT_CMD=$(cmd_for lint)
if [ -n "$LINT_CMD" ]; then
    # e.g. `pnpm turbo run lint --filter=...[HEAD]` -- whatever CI runs
    run "lint ($LINT_CMD)" sh -c "$LINT_CMD"
else
    # --- 1'. Per-stack linters on staged files (commands.lint unset) ---------
    # TypeScript / JavaScript (Next.js, NestJS, Expo, Node): ESLint flat config
    [ -n "$TS" ] && run "eslint" npx --no-install eslint --max-warnings=0 $TS
    # Python (FastAPI, Django): Ruff lint + format check
    [ -n "$PY" ] && run "ruff check" ruff check $PY
    [ -n "$PY" ] && run "ruff format" ruff format --check $PY
    # Kotlin (Android, Spring): ktlint
    [ -n "$KT" ] && run "ktlint" ktlint $KT
    # Swift (iOS): SwiftLint, strict so warnings fail too
    [ -n "$SWIFT" ] && run "swiftlint" swiftlint lint --strict --quiet $SWIFT
fi

# --- 2. Formatting (Prettier) for web/Node files -------------------------------
if [ -n "$FMT" ] && [ -f node_modules/.bin/prettier ]; then
    run "prettier" npx --no-install prettier --check --ignore-unknown $FMT
fi

# --- 3. Type check (project-wide) ------------------------------------------------
TYPECHECK_CMD=$(cmd_for typecheck)
if [ -n "$TYPECHECK_CMD" ]; then
    run "typecheck ($TYPECHECK_CMD)" sh -c "$TYPECHECK_CMD"
elif [ -n "$TS" ] && [ -f tsconfig.json ]; then
    run "tsc" npx --no-install tsc --noEmit -p tsconfig.json
fi

# --- 4. Secret scan (staged changes only) ----------------------------------------
if command -v gitleaks >/dev/null 2>&1; then
    run "gitleaks" gitleaks git --pre-commit --staged --redact --no-banner
else
    # Fallback: the same token patterns validate-commit.sh blocks on.
    PATTERN='AKIA[0-9A-Z]{16}|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{36,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|sk_live_[0-9a-zA-Z]{16,}'
    if git diff --cached -U0 --no-color | grep -E '^\+' | grep -v 'pragma: allowlist secret' \
        | grep -oE -e "$PATTERN" | grep -vE 'EXAMPLE$' | grep -q .; then
        echo "FAILED: possible secret in the staged changes (install gitleaks for file and line detail)"
        EXIT_CODE=1
    fi
fi

# --- 5. Advisory: TODO without an owner --------------------------------------------
UNOWNED=$(printf '%s\n' "$STAGED" | tr '\n' '\0' \
    | xargs -0 grep -IlE '(^|[^A-Za-z0-9_])(TODO|FIXME|HACK)([^(A-Za-z0-9_]|$)' 2>/dev/null || true)
[ -n "$UNOWNED" ] && printf 'WARNING: TODO/FIXME without owner -- use TODO(owner):\n%s\n' "$UNOWNED"

exit $EXIT_CODE
```

Unquoted `$TS`, `$PY`, … split the file list on whitespace: fine for repositories whose paths contain no spaces
(the norm for web and mobile code). For paths with spaces, prefer Option B, which quotes for you.

### Option B — lefthook (`lefthook.yml`) or husky + lint-staged

Both are common in 2026 JavaScript/TypeScript monorepos and handle staged-file lists, partial staging and
parallelism. A lefthook equivalent of the script above for Moa (pnpm + Turborepo, Next.js web, Expo mobile,
NestJS API):

```yaml
pre-commit:
  parallel: true
  commands:
    eslint:
      glob: "*.{ts,tsx,js,jsx,mjs,cjs}"
      run: pnpm exec eslint --max-warnings=0 {staged_files}
    prettier:
      glob: "*.{ts,tsx,js,jsx,json,css,md,yml,yaml}"
      run: pnpm exec prettier --check --ignore-unknown {staged_files}
    typecheck:
      glob: "*.{ts,tsx}"
      run: pnpm turbo run typecheck      # = commands.typecheck
    gitleaks:
      run: gitleaks git --pre-commit --staged --redact --no-banner
```

Python services add `ruff check {staged_files}` and `ruff format --check {staged_files}` (glob `*.py`); an
Android module adds `ktlint {staged_files}` (glob `*.{kt,kts}`); an iOS app adds
`swiftlint lint --strict --quiet {staged_files}` (glob `*.swift`).

## Agent Integration

When this hook fails:
1. Lint or format violations: run the fixer (`eslint --fix`, `prettier --write`, `ruff check --fix`,
   `ruff format`, `ktlint --format`, `swiftlint --fix`), or invoke the engineer for the layer
   (`frontend-engineer`, `backend-engineer`, `mobile-engineer`) with the stack specialist from the routing in
   `project.yaml`
2. Type errors: invoke the same engineer; a type error at a module boundary goes to `tech-lead`
3. A secret: remove it, **rotate it** (deleting it from the diff is not enough if it was ever pushed or shared),
   and invoke `security-engineer` when it reached a remote
4. Hardcoded business values flagged by `validate-commit.sh`: move them to config or feature flags, citing the
   PRD's `## Business Rules & Calculations` rule
