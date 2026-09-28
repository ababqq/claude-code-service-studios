#!/usr/bin/env bash
# review-scope.sh — compute the PRD scope for an incremental cross-PRD review.
#
# Replaces the git archaeology /review-all-prds (and /consistency-check
# since-last-review) would otherwise reason through: finds the most recent
# cross-PRD review report, lists the PRDs changed since it, and lists every
# dependency edge that touches a changed PRD -- in both directions, because both
# ends of an edge can go stale. When design/prd/auth.md changes, the PRD that
# depends on it (design/prd/goals.md) may now contradict it even if auth.md never
# names goals.md back.
#
# Usage: bash .claude/scripts/review-scope.sh [since-last-review]
#   The optional argument names the only mode this script has. Anything else
#   prints the usage line and exits 2.
#
# Output (observations only -- the calling skill decides the review set):
#   PRIOR_REVIEW: <path>             (or "NONE (full review required)")
#   CHANGED:                         PRDs modified since that review; a changed
#                                    path no longer on disk is suffixed " (deleted)"
#   DEPS (...):                      dependency edges of the changed PRDs
#     auth.md -> design/prd/x.md     auth.md names x.md in its ## Dependencies
#                                    (suffixed " (not found)" when x.md is absent)
#     auth.md <- design/prd/goals.md goals.md names auth.md in its ## Dependencies
#
# DEPENDENCY EDGES are the design/prd/<slug>.md tokens inside a PRD's
# "## Dependencies" section -- the PRD section contract writes that section as a
# table whose PRD column holds exactly these paths. The section runs to the next
# level-2 heading, so its "### External Services" subsection is scanned too; it
# names third parties, not PRDs, and contributes no tokens.
#
# SCOPE: design/prd/*.md at depth 1 and nothing else lives there, so there is no
# exclusion list. Review logs and cross-review reports live in design/prd/reviews/.
#
# CORRECTNESS NOTES -- three silent-data-loss bugs were fixed when this script was
# first written, and a fourth failure is reachable from the report filename. All
# of them drop files without warning, which in a review tool means a changed PRD
# quietly escapes review:
#
#   1. git pathspecs are fnmatch WITHOUT FNM_PATHNAME, so `*` crosses `/`:
#      'design/prd/*.md' also matches design/prd/reviews/*.md, pulling the review
#      logs into the review scope. Fixed with :(glob) magic, which restricts * to
#      one path segment.
#   2. `git status --porcelain | awk '{print $NF}'` mangles any path containing a
#      space (returns the trailing fragment) and returns the wrong field for
#      renames (`R old -> new`). Fixed with -z, which disables quoting entirely,
#      parsed record by record so a rename's original path is kept too.
#   3. `for f in $changed` word-splits on IFS and glob-expands, so a PRD whose
#      filename contains a space was split into two nonexistent paths and
#      silently discarded. Fixed with `while IFS= read -r`.
#   4. The baseline is chosen by `sort | tail -1` over the report filenames -- see
#      the note at that line.

set -u

case "${1:-since-last-review}" in
    since-last-review) ;;
    *) echo "Usage: bash .claude/scripts/review-scope.sh [since-last-review]" >&2; exit 2 ;;
esac

cd "$(dirname "$0")/../.." || { echo "review-scope: cannot reach repo root" >&2; exit 1; }

PRD_DIR='design/prd'
PRD_GLOB=':(glob)design/prd/*.md'
REVIEW_DIR='design/prd/reviews'

# git prints paths relative to the repository top level; the project root may sit
# below it (a product folder inside a larger repository). Strip that prefix so the
# paths match what find prints from here.
GIT_PREFIX=$(git rev-parse --show-prefix 2>/dev/null || true)
strip_git_prefix() {
    if [ -n "$GIT_PREFIX" ]; then
        awk -v p="$GIT_PREFIX" 'index($0, p) == 1 { print substr($0, length(p) + 1); next } { print }'
    else
        cat
    fi
}

all_prds() {
    find "$PRD_DIR" -maxdepth 1 -name '*.md' -type f 2>/dev/null | sed 's|\\|/|g' | sort
}

# deps_of <prd> -- the design/prd/<slug>.md tokens inside its ## Dependencies
# section, one per line, sorted and unique. The heading match follows the PRD
# section contract: case-insensitive prefix, optional numeric prefix "7. "/"7) ".
deps_of() {
    awk '
        /^##[ \t]/ {
            h = tolower($0); sub(/^##[ \t]+/, "", h); sub(/^[0-9]+[.)][ \t]+/, "", h)
            dep = (h ~ /^dependencies/) ? 1 : 0
            next
        }
        dep { print }
    ' "$1" | grep -oE 'design/prd/[a-z0-9-]+\.md' | sort -u
}

# git status --porcelain -z prints "XY path" records separated by NUL; a rename or
# copy is followed by one extra record holding the original path. Emit both.
porcelain_paths() {
    git status --porcelain -z -- "$PRD_GLOB" 2>/dev/null | {
        while IFS= read -r -d '' rec; do
            printf '%s\n' "${rec:3}"
            case "${rec:0:2}" in
                R*|C*) IFS= read -r -d '' orig && printf '%s\n' "$orig" ;;
            esac
        done
    }
}

# `sort | tail -1` is chronological ONLY because the report filename carries an
# ISO 8601 date (prd-cross-review-YYYY-MM-DD.md). /review-all-prds states that
# requirement at the point it asks permission to write the file; if that ever
# loosens, this line silently picks the wrong baseline and every PRD changed since
# the real last review escapes the next one.
#
# Not mtime: on a fresh clone every file carries the checkout time, so `ls -t`
# here would order the reports arbitrarily. The date in the name is the only
# ordering that survives being cloned.
last_review=$(find "$REVIEW_DIR" -maxdepth 1 -name 'prd-cross-review-*.md' -type f 2>/dev/null \
              | sed 's|\\|/|g' | sort | tail -1)

if [ -z "$last_review" ]; then
    echo "PRIOR_REVIEW: NONE (full review required)"
    echo "CHANGED:"
    prds=$(all_prds)
    if [ -z "$prds" ]; then
        echo "  (no PRDs found in $PRD_DIR/)"
    else
        printf '%s\n' "$prds" | sed 's/^/  /'
    fi
    exit 0
fi

echo "PRIOR_REVIEW: $last_review"

# Prefer git history if the review file is committed; fall back to file mtime.
base=$(git log -1 --format=%H -- "$last_review" 2>/dev/null)
if [ -n "$base" ]; then
    changed=$( {
        git diff --name-only "$base" -- "$PRD_GLOB" 2>/dev/null
        porcelain_paths
    } | strip_git_prefix | sed 's|\\|/|g' | sort -u )
else
    changed=$(find "$PRD_DIR" -maxdepth 1 -name '*.md' -type f -newer "$last_review" 2>/dev/null \
              | sed 's|\\|/|g' | sort)
fi

# Keep depth-1 PRD paths only (a rename's original path can point anywhere).
scope=""
while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in
        "$PRD_DIR"/*/*) continue ;;
        "$PRD_DIR"/*.md) scope="$scope$f"$'\n' ;;
    esac
done <<EOF
$changed
EOF

echo "CHANGED:"
if [ -z "$scope" ]; then
    echo "  (none — no PRDs modified since last review)"
    exit 0
fi
printf '%s' "$scope" | while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ -f "$f" ]; then
        echo "  $f"
    else
        echo "  $f (deleted)"
    fi
done

# Every edge in the PRD set, once: "<prd><TAB><dependency path>".
edges=""
while IFS= read -r p; do
    [ -n "$p" ] || continue
    while IFS= read -r d; do
        [ -n "$d" ] || continue
        [ "$d" = "$p" ] && continue
        edges="$edges$p"$'\t'"$d"$'\n'
    done <<EOF_DEPS
$(deps_of "$p")
EOF_DEPS
done <<EOF_PRDS
$(all_prds)
EOF_PRDS

echo "DEPS (dependency edges of the changed PRDs, both directions — include these in review scope too):"
printed=0
while IFS= read -r f; do
    [ -n "$f" ] || continue
    b=$(basename "$f")
    # Forward: what the changed PRD names in its own ## Dependencies section.
    if [ -f "$f" ]; then
        while IFS= read -r d; do
            [ -n "$d" ] || continue
            [ "$d" = "$f" ] && continue
            if [ -f "$d" ]; then
                echo "  $b -> $d"
            else
                echo "  $b -> $d (not found)"
            fi
            printed=1
        done <<EOF_FWD
$(deps_of "$f")
EOF_FWD
    fi
    # Reverse: every other PRD whose ## Dependencies section names the changed PRD.
    while IFS= read -r p; do
        [ -n "$p" ] || continue
        echo "  $b <- $p"
        printed=1
    done <<EOF_REV
$(printf '%s' "$edges" | awk -F '\t' -v t="$f" '$2 == t { print $1 }' | sort -u)
EOF_REV
done <<EOF_SCOPE
$scope
EOF_SCOPE

[ "$printed" -eq 1 ] || echo "  (none — no changed PRD names a PRD, and no PRD names a changed one)"
exit 0
