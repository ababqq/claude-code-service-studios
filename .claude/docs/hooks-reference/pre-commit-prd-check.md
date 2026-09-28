# Hook: pre-commit-prd-check

## Trigger

Runs before any commit that stages a feature PRD — `design/prd/<feature>.md` (a git `pre-commit` hook). Review
logs under `design/prd/reviews/` are never checked. Optional: `validate-commit.sh` already gives the same
warning on Claude's own commits; this recipe extends it to every contributor.

## Purpose

Keeps PRDs complete for their tier before they enter version control, so `/prd-review`, `/review-all-prds`,
`/create-epics` and the gates never read a PRD with a required section missing. It checks **presence only** — a
heading for each section the tier requires — and leaves content quality to `/prd-review`. It **warns and never
blocks**: a PRD is often committed as a work-in-progress draft (`> **Status**: Draft`), and blocking would push
people to commit empty placeholder headings, which is worse than a visible gap.

The section contract is `.claude/docs/templates/prd.md`. What the tier requires:

| Tier | Required sections |
| ---- | ----------------- |
| `full` | Overview, Goals & Non-Goals, User Value, Functional Requirements, Business Rules & Calculations, Edge Cases, Dependencies, Non-Functional Requirements, Configuration & Flags, Success Metrics & Instrumentation, Acceptance Criteria |
| `standard` | Overview, Goals & Non-Goals, Functional Requirements, Edge Cases, Dependencies, Non-Functional Requirements, Success Metrics & Instrumentation, Acceptance Criteria (Business Rules & Calculations is conditional — `/prd-review` decides from what the feature defines) |
| `minimal` | none — the one-pager (`design/product/one-pager.md`) is the design record |

The tier is the project's `modes.workflow`, replaced for one PRD by its
`workflow_overrides.feature_overrides.<feature>` entry. Presence is decided by
`.claude/scripts/prd-structure-check.sh`, which uses the same heading match as `validate-commit.sh`: a heading of
level `##` or deeper, an optional numeric prefix (`3.` or `3)`), then the section name — case-insensitive, prefix
match.

## Implementation

```bash
#!/bin/bash
# Pre-commit hook: PRD sections required at each PRD's tier. WARN only -- always exits 0.
# Place in .git/hooks/pre-commit or configure via your hook manager (lefthook, husky).

ROOT=$(git rev-parse --show-toplevel) || exit 0
cd "$ROOT" || exit 0

PRDS=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '^design/prd/[^/]+\.md$')
[ -z "$PRDS" ] && exit 0

if [ ! -f .claude/hooks/yaml-helper.sh ] || [ ! -f .claude/scripts/prd-structure-check.sh ]; then
    echo "NOT CHECKED: PRD sections (framework scripts not found)"
    exit 0
fi

# Resolve the project tier and the per-feature overrides once.
CONFIG=$(bash .claude/hooks/yaml-helper.sh resolve_config --keys workflow,feature_overrides)
TIER=$(printf '%s\n' "$CONFIG" | sed -n 's/^workflow: \([a-z]*\).*/\1/p')
OVERRIDES=$(printf '%s\n' "$CONFIG" | sed -n 's/^feature_overrides: //p')
[ "$OVERRIDES" = "none" ] && OVERRIDES=""

case "$TIER" in
    minimal|standard|full) ;;
    *) echo "NOT CHECKED: PRD sections (workflow tier unresolved)"; exit 0 ;;
esac

required_for() {
    case "$1" in
        full)     echo "Overview|Goals & Non-Goals|User Value|Functional Requirements|Business Rules & Calculations|Edge Cases|Dependencies|Non-Functional Requirements|Configuration & Flags|Success Metrics & Instrumentation|Acceptance Criteria" ;;
        standard) echo "Overview|Goals & Non-Goals|Functional Requirements|Edge Cases|Dependencies|Non-Functional Requirements|Success Metrics & Instrumentation|Acceptance Criteria" ;;
        *)        echo "" ;;
    esac
}

WARNED=0
while IFS= read -r PRD; do
    [ -z "$PRD" ] && continue
    FEATURE=$(basename "$PRD" .md)
    PRD_TIER="$TIER"
    for PAIR in $OVERRIDES; do
        [ "${PAIR%%=*}" = "$FEATURE" ] && PRD_TIER="${PAIR#*=}"
    done
    REQUIRED=$(required_for "$PRD_TIER")
    if [ -z "$REQUIRED" ]; then
        echo "NOTE: $PRD -- tier minimal requires no PRD sections"
        continue
    fi

    # prd-structure-check.sh prints "<file> PRESENT: a,b" and, when something is
    # missing, "<file> ABSENT:  c,d" -- observations only; the tier is applied here.
    ABSENT=$(bash .claude/scripts/prd-structure-check.sh "$PRD" | sed -n 's/^.* ABSENT:[[:space:]]*//p')
    MISSING=""
    OLD_IFS=$IFS; IFS=','
    for SECTION in $ABSENT; do
        case "|$REQUIRED|" in
            *"|$SECTION|"*) MISSING="${MISSING:+$MISSING, }$SECTION" ;;
        esac
    done
    IFS=$OLD_IFS

    if [ -n "$MISSING" ]; then
        echo "WARNING: $PRD is missing section(s) required at tier $PRD_TIER: $MISSING"
        WARNED=1
    fi
done <<EOF
$PRDS
EOF

[ "$WARNED" = 1 ] && echo "Template: .claude/docs/templates/prd.md -- /write-prd fills a section, /prd-review checks the content."
exit 0
```

## Agent Integration

When this hook warns:
1. Missing sections in a PRD you are still drafting: continue with `/write-prd` — it resumes section by section
   from what is on disk
2. Missing sections in a PRD marked `In Review` or `Approved`: invoke `product-manager` to complete the document,
   and `business-analyst` when the gap is `Business Rules & Calculations` (prices, limits, fees, rounding)
3. A tier that looks wrong for the feature: change it deliberately with
   `/settings workflow_overrides.feature_overrides.<feature>=<tier>`, never by deleting sections
