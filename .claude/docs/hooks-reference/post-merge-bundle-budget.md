# Hook: post-merge-bundle-budget

## Trigger

Runs after a merge (a git `post-merge` hook) that changes web code, dependencies or the mobile app — typically
when `develop`, `main` or a `release/*` branch is pulled or merged locally.

## Purpose

An early, cheap signal that the merge made the product heavier: web JavaScript measured against
`performance.bundle_kb` (initial JavaScript per route, gzip, in KB) and mobile release artifacts reported by
size. Bundle weight grows one innocent dependency at a time — a date library with every locale, a full icon pack
through a barrel import, a CJK web font shipped unsubset — and nobody notices until the Core Web Vitals or the
store's size report say so.

**Observations only, never a verdict.** A git hook cannot see which chunks a route loads on first visit, so it
reports what is on disk: the largest chunks, any single chunk larger than the whole per-route budget, and the
change since the previous merge. Whether a route breaches its budget — and what that means under
`performance.enforce` (`warn`, `block` or `off`) — is decided by `/bundle-audit`, which maps routes to their
initial chunks. The hook always exits 0 (a `post-merge` hook cannot undo a merge anyway).

Mobile app size has no `performance.*` budget key: sizes are informational unless the architecture or a PRD's
`## Non-Functional Requirements` documents a target, which `/bundle-audit` Phase 5 reads.

## Implementation

```bash
#!/bin/bash
# Post-merge hook: bundle and app size observations. Always exits 0.
# Set BUNDLE_BUDGET_BUILD=1 to run commands.build first (slow); otherwise the hook
# measures the build output already on disk and says how old it is.

ROOT=$(git rev-parse --show-toplevel) || exit 0
cd "$ROOT" || exit 0
[ -f .claude/hooks/yaml-helper.sh ] && . .claude/hooks/yaml-helper.sh

CHANGED=$(git diff --name-only ORIG_HEAD HEAD 2>/dev/null)
[ -z "$CHANGED" ] && exit 0

# Code roots per layer (resolve_code_roots prints "<dir>\t<layer>\t<source>").
ROOTS=""
command -v resolve_code_roots >/dev/null 2>&1 && ROOTS=$(resolve_code_roots)
WEB_ROOTS=$(printf '%s\n' "$ROOTS" | awk -F '\t' '$2 == "web" && $3 != "missing" { print $1 }')
MOBILE_ROOTS=$(printf '%s\n' "$ROOTS" | awk -F '\t' '$2 == "mobile" && $3 != "missing" { print $1 }')

touches() {  # touches <roots...> -> true when the merge changed a file under one of them
    local r
    for r in "$@"; do
        printf '%s\n' "$CHANGED" | grep -q "^$r/" && return 0
    done
    return 1
}
DEPS_CHANGED=$(printf '%s\n' "$CHANGED" | grep -E '(^|/)(package\.json|pnpm-lock\.yaml|package-lock\.json|yarn\.lock|bun\.lockb?)$')

TAB=$(printf '\t')
echo "=== Bundle & App Size (observations) ==="

# --- Web: gzip size of JavaScript chunks --------------------------------------------
if [ -n "$WEB_ROOTS" ] && { touches $WEB_ROOTS || [ -n "$DEPS_CHANGED" ]; }; then
    BUDGET=$(get_yaml_key project.yaml performance.bundle_kb 2>/dev/null)
    ENFORCE=$(resolve_setting performance.enforce 2>/dev/null | cut -f1)
    echo "Budget: performance.bundle_kb=${BUDGET:-unset} (initial JS per route, gzip) -- performance.enforce=${ENFORCE:-warn}"

    if [ "${BUNDLE_BUDGET_BUILD:-0}" = 1 ]; then
        BUILD_CMD=$(get_yaml_key project.yaml commands.build 2>/dev/null)
        if [ -n "$BUILD_CMD" ]; then
            echo "Building: $BUILD_CMD"
            sh -c "$BUILD_CMD" >/dev/null 2>&1 || echo "BUILD FAILED -- sizes below are from older output"
        else
            echo "NOT CHECKED: fresh build (commands.build unset)"
        fi
    fi

    ROWS=""
    for r in $WEB_ROOTS; do
        # Client JS output of common web stacks: Next.js, Vite (React/Vue/Svelte SPA),
        # Create React App, Nuxt, SvelteKit, Astro.
        for out in "$r/.next/static/chunks" "$r/dist/assets" "$r/build/static/js" \
                   "$r/.output/public/_nuxt" "$r/.svelte-kit/output/client/_app/immutable" "$r/dist/_astro"; do
            [ -d "$out" ] || continue
            AGE_MIN=$(( ( $(date +%s) - $(stat -c %Y "$out" 2>/dev/null || stat -f %m "$out") ) / 60 ))
            echo "Output: $out (modified ${AGE_MIN} min ago)"
            while IFS= read -r f; do
                kb=$(( ( $(gzip -9 -c "$f" | wc -c) + 1023 ) / 1024 ))
                ROWS="$ROWS$kb$TAB$f
"
            done <<EOF
$(find "$out" -type f -name '*.js' 2>/dev/null)
EOF
        done
    done

    if [ -z "$ROWS" ]; then
        echo "NOT CHECKED: web bundle (no build output found -- build, or set BUNDLE_BUDGET_BUILD=1)"
    else
        TOTAL=$(printf '%s' "$ROWS" | awk -F '\t' '{ s += $1 } END { print s }')
        echo "Total client JS (all chunks, gzip): ${TOTAL} KB -- an upper bound, not a per-route figure"
        echo "Largest chunks (gzip KB):"
        printf '%s' "$ROWS" | sort -rn | head -10 | awk -F '\t' '{ printf "  SIZE: %5d KB  %s\n", $1, $2 }'
        if [ -n "$BUDGET" ]; then
            printf '%s' "$ROWS" | awk -F '\t' -v b="$BUDGET" '$1 > b { printf "  ABOVE_BUNDLE_KB: %s is %d KB alone (> %d KB per route)\n", $2, $1, b }'
        fi
        # Change since the previous merge on this clone (kept in .git, never committed).
        BASE="$(git rev-parse --git-dir)/ccss-bundle-total"
        [ -f "$BASE" ] && echo "Change since previous measurement: $(( TOTAL - $(cat "$BASE") )) KB"
        echo "$TOTAL" > "$BASE"
    fi
else
    echo "Web: no web code or dependency change in this merge (or no web root declared)"
fi

# --- Mobile: release artifacts on disk --------------------------------------------------
if [ -n "$MOBILE_ROOTS" ] && touches $MOBILE_ROOTS; then
    FOUND=0
    for r in $MOBILE_ROOTS; do
        while IFS= read -r a; do
            [ -z "$a" ] && continue
            FOUND=1
            mb=$(awk -v b="$(wc -c < "$a")" 'BEGIN { printf "%.1f", b / 1048576 }')
            echo "  ARTIFACT: $a -- ${mb} MB on disk (download size differs; see below)"
        done <<EOF
$(find "$r" \( -name '*.aab' -o -name '*.apk' -o -name '*.ipa' \) -type f -not -path '*/node_modules/*' 2>/dev/null)
EOF
    done
    [ "$FOUND" = 0 ] && echo "NOT CHECKED: mobile app size (no .aab/.apk/.ipa release artifact on disk)"
    echo "  Download size per device: bundletool get-size total --apks=<file>.apks (Android),"
    echo "  the App Thinning Size Report (iOS); Flutter: build with --analyze-size."
fi

echo "Observations only -- run /bundle-audit for the per-route verdict."
exit 0
```

`stat -c %Y` is the GNU/Linux form and `stat -f %m` the BSD/macOS one; GNU is tried first because GNU
`stat -f` means something else (file-system status) and would print noise instead of failing. The script assumes
paths without spaces, the norm for web and mobile build output.

## Agent Integration

When this hook reports growth or a chunk above the per-route budget:
1. Run `/bundle-audit` for the per-route measurement, the verdict under `performance.enforce` and the ranked
   causes (heavy dependencies in the initial bundle, duplicate packages, client code the framework could
   render on the server, unsubset CJK fonts)
2. For the fix, invoke `frontend-engineer` with the web stack specialist (`nextjs-specialist`,
   `vue-nuxt-specialist` …); for mobile artifact growth, `mobile-engineer` with the platform specialist
3. When the growth comes with a new dependency, `tech-lead` decides whether it stays (and records it in
   `docs/architecture/tech-radar.md`); `performance-engineer` owns the budgets themselves
