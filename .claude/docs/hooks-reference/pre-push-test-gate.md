# Hook: pre-push-test-gate

## Trigger

Runs before any push to a remote branch (a git `pre-push` hook). The full gate is mandatory for pushes to the
shared branches — `main`, `master`, `develop`, `release/*`, `production`, `prod` — the same list
`validate-push.sh` warns about.

## Purpose

Ensures the build succeeds and the test suites pass before code reaches a branch other people build on or
deploy from. This is the last automated quality gate before code affects other developers — and, with
continuous deployment, users. It runs the project's own commands from `project.yaml` (`commands.build`,
`commands.test`, `commands.e2e`, written by `/setup-stack` and `/test-setup`), so a green pre-push means the same
thing as a green CI run.

| Suite | Command | Pushes |
| ----- | ------- | ------ |
| Unit | `commands.test` (or its unit filter) | every push |
| Integration and contract | `commands.test` (integration / contract projects — `tests/integration/`, `tests/contract/`) | shared branches |
| E2E smoke | `commands.e2e` with the smoke tag (critical journeys only) | shared branches |

## Implementation

```bash
#!/bin/bash
# Pre-push hook: build and test gate.
# git passes the remote name and URL as $1 $2, and one line per pushed ref on stdin:
#   <local ref> <local sha> <remote ref> <remote sha>

REMOTE="$1"
URL="$2"

ROOT=$(git rev-parse --show-toplevel) || exit 1
cd "$ROOT" || exit 1

cmd_for() {  # cmd_for test -> commands.test (OS map aware), or nothing
    [ -f .claude/hooks/yaml-helper.sh ] || return 0
    . .claude/hooks/yaml-helper.sh
    local os="linux" v=""
    case "$(uname -s)" in Darwin) os="macos" ;; MINGW*|MSYS*|CYGWIN*) os="windows" ;; esac
    v=$(get_yaml_key project.yaml "commands.$1.$os")
    [ -z "$v" ] && v=$(get_yaml_key project.yaml "commands.$1.default")
    [ -z "$v" ] && v=$(get_yaml_key project.yaml "commands.$1")
    printf '%s' "$v"
}

is_shared() {
    case "$1" in main|master|develop|production|prod|release/*) return 0 ;; esac
    return 1
}

FULL_GATE=false
RANGES=""
ZERO=0000000000000000000000000000000000000000
while read -r LOCAL_REF LOCAL_SHA REMOTE_REF REMOTE_SHA; do
    [ "$LOCAL_SHA" = "$ZERO" ] && continue            # branch deletion
    is_shared "${REMOTE_REF#refs/heads/}" && FULL_GATE=true
    if [ "$REMOTE_SHA" = "$ZERO" ]; then
        RANGES="$RANGES$LOCAL_SHA --not --remotes=$REMOTE
"                                                     # new branch
    else
        RANGES="$RANGES$REMOTE_SHA..$LOCAL_SHA
"
    fi
done

echo "=== Pre-Push Quality Gate ($REMOTE) ==="

# Step 1: Build
BUILD_CMD=$(cmd_for build)
if [ -n "$BUILD_CMD" ]; then
    echo "Building: $BUILD_CMD"
    sh -c "$BUILD_CMD" || { echo "Build: FAILED"; exit 1; }
    echo "Build: PASS"
else
    echo "Build: NOT CHECKED (commands.build unset -- run /setup-stack)"
fi

# Step 2: Unit tests (every push)
TEST_CMD=$(cmd_for test)
if [ -n "$TEST_CMD" ]; then
    echo "Running tests: $TEST_CMD"
    # Examples of what commands.test holds:
    #   pnpm turbo run test            (Vitest/Jest per workspace)
    #   pytest -m "not integration"    (FastAPI service)
    #   ./gradlew test                 (Spring / Android unit tests)
    #   flutter test / go test ./...
    sh -c "$TEST_CMD" || { echo "Tests: FAILED"; exit 1; }
    echo "Tests: PASS"
else
    echo "Tests: NOT CHECKED (commands.test unset -- run /test-setup)"
fi

if [ "$FULL_GATE" = true ]; then
    # Step 3: Integration and contract tests (shared branches)
    # If commands.test already runs them, this step is a no-op; otherwise adapt:
    #   pnpm turbo run test:integration test:contract
    #   pytest tests/integration tests/contract
    echo "Integration and contract tests: covered by commands.test (adapt if they are separate)"

    # Step 4: E2E smoke (critical journeys only -- the full E2E suite belongs to CI)
    E2E_CMD=$(cmd_for e2e)
    if [ -n "$E2E_CMD" ]; then
        echo "Running E2E smoke: $E2E_CMD --grep @smoke"
        # Playwright: tag critical-journey tests with @smoke; Maestro/Detox: a smoke flow folder.
        sh -c "$E2E_CMD --grep @smoke" || { echo "E2E smoke: FAILED"; exit 1; }
        echo "E2E smoke: PASS"
    else
        echo "E2E smoke: NOT CHECKED (commands.e2e unset -- run /test-setup)"
    fi
fi

# Step 5: Migration dry-run reminder
MIGRATIONS_DIR=""
if [ -f .claude/hooks/yaml-helper.sh ] && [ -f project.yaml ]; then
    . .claude/hooks/yaml-helper.sh
    MIGRATIONS_DIR=$(get_yaml_key project.yaml stack.layers.data.migrations_dir)
fi
TOUCHED=""
if [ -n "$MIGRATIONS_DIR" ]; then
    while IFS= read -r RANGE; do          # one git log per pushed ref
        [ -z "$RANGE" ] && continue
        git log --format= --name-only $RANGE 2>/dev/null \
            | grep -q "^${MIGRATIONS_DIR%/}/" && TOUCHED=yes
    done <<EOF
$RANGES
EOF
fi
if [ -n "$TOUCHED" ]; then
    echo "REMINDER: this push contains migrations under $MIGRATIONS_DIR."
    echo "  Dry-run them on a disposable database (commands.migrate -- apply the expand step, then roll it back)"
    echo "  and keep the log as production/qa/evidence/<story-slug>/migration-dry-run.log."
    echo "  Confirm the phase in the migration plan (docs/data/migrations/): expand, backfill or contract."
fi

echo "=== Gate complete ==="
exit 0
```

`git push --no-verify` skips the hook; reserve it for emergencies and say so in the pull request. Keep the
pre-push gate fast (unit tests and a smoke subset); the exhaustive suites, load tests and full E2E runs belong to
CI, where `commands.test` and `commands.e2e` run on every pull request.

## Agent Integration

When this hook fails:
1. Build failure: invoke `tech-lead` to diagnose; a CI/build-tooling problem goes to `devops-engineer`
2. Unit, integration or contract test failure: invoke `qa-engineer` to identify the failing test and the owning
   engineer (`backend-engineer`, `frontend-engineer`, `mobile-engineer`) to fix it; a broken contract test also
   means `/api-design` must reconcile the contract before the push
3. E2E smoke failure: `qa-engineer` triages — a real regression becomes a bug (`/bug-report`), a flaky test goes
   to `/test-flakiness`
4. Migration without dry-run evidence: `/data-model` owns the migration plan; run the dry run before pushing
