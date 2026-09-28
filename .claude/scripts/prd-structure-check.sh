#!/usr/bin/env bash
# prd-structure-check.sh — deterministic section-presence check for feature PRDs.
#
# Replaces a full-document model read per PRD with ~2 lines of output that cannot
# hallucinate a missing section. This is the cheapest real win available: the
# model spends its budget judging content, not counting headings.
#
# REPORTS PRESENCE ONLY — IT DOES NOT JUDGE COMPLETENESS.
# Which sections are REQUIRED depends on the PRD's workflow tier (the project
# tier, or its workflow_overrides.feature_overrides entry) and on what the feature
# defines (/prd-review Phase 2b): at `standard`, User Value and Configuration &
# Flags are advisory, and Business Rules & Calculations is required only when the
# feature defines a numeric or policy rule -- prices, fees, limits, quotas, rate
# limits, eligibility thresholds, time windows, rounding. A `standard`-tier PRD
# without User Value is COMPLETE, so an "N/11" score would actively misreport it.
# The caller applies the tier; this script only says what is on disk.
#
# SHARED CONTRACT. The eleven section names, their order and the heading regex
# below are the PRD section contract: .claude/docs/templates/prd.md, the /write-prd
# skeleton and the PRD section check in .claude/hooks/validate-commit.sh use the
# same list and the same tolerant match. Change them together or not at all.
#
# Scope: design/prd/*.md at depth 1 and nothing else lives there, so there is no
# exclusion list. Governance documents live in design/product/ and review logs in
# design/prd/reviews/, which -maxdepth 1 keeps out of scope.
#
# Usage:
#   bash .claude/scripts/prd-structure-check.sh                     # every PRD
#   bash .claude/scripts/prd-structure-check.sh design/prd/goals.md # one PRD
#
# Output (per PRD; the ABSENT line is omitted when nothing is absent):
#   goals.md PRESENT: Overview,Goals & Non-Goals,User Value,Functional Requirements,...
#   auth.md PRESENT: Overview,Goals & Non-Goals,Functional Requirements,Edge Cases,...
#   auth.md ABSENT:  User Value,Business Rules & Calculations,Configuration & Flags

set -u

cd "$(dirname "$0")/../.." || { echo "prd-structure-check: cannot reach repo root" >&2; exit 1; }

# One MATCH entry per contract section, in template order; LABEL is the name
# reported to the caller. The match is a case-insensitive PREFIX match, so the
# heading text may continue after the name ("## Overview — goals v2" counts).
MATCH=("Overview" "Goals & Non-Goals" "User Value" "Functional Requirements" \
       "Business Rules & Calculations" "Edge Cases" "Dependencies" "Non-Functional Requirements" \
       "Configuration & Flags" "Success Metrics & Instrumentation" "Acceptance Criteria")
LABEL=("${MATCH[@]}")

check_file() {
    local f="$1" present="" absent="" i s
    for i in "${!MATCH[@]}"; do
        s="${MATCH[$i]}"
        # One heading regex, shared with validate-commit.sh: any heading level from
        # ## down, an optional numeric prefix "3. " or "3) ", then the section name.
        # "&" and "-" are literal in ERE, so the names need no escaping.
        # [[:space:]] not [ \t] -- inside double quotes the shell leaves \t literal
        # and ERE reads the class as {space, backslash, t}, so real tabs fail to
        # match while "##tOverview" false-positives.
        if grep -qiE "^##+[[:space:]]+([0-9]+[.)][[:space:]]+)?${s}" "$f"; then
            present="$present,${LABEL[$i]}"
        else
            absent="$absent,${LABEL[$i]}"
        fi
    done
    local b; b="$(basename "$f")"
    echo "$b PRESENT: ${present#,}"
    [ -n "$absent" ] && echo "$b ABSENT:  ${absent#,}"
    return 0
}

if [ $# -gt 0 ] && [ -n "${1:-}" ]; then
    [ -f "$1" ] || { echo "Not found: $1" >&2; exit 1; }
    check_file "$1"
    exit 0
fi

any=0
# -maxdepth 1 keeps design/prd/reviews/ out of scope -- /prd-review and
# /review-all-prds write their own output there, and sweeping it in makes the
# tool review its own reports.
while IFS= read -r f; do
    [ -n "$f" ] || continue
    any=1
    check_file "$f"
done <<EOF
$(find design/prd -maxdepth 1 -name '*.md' -type f 2>/dev/null | sort)
EOF

[ "$any" -eq 1 ] || echo "No PRDs found in design/prd/."
exit 0
