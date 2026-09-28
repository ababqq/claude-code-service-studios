#!/usr/bin/env bash

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
#   4. this script's location   -> <root>/.claude/.. by construction
# Rule 4 always works and needs no environment at all; rules 1-2 stop it from
# overriding a caller that legitimately means somewhere else.
#
# NOT an upward search: that resolves a nested project to its parent's config.
if [ -f "project.yaml" ] || [ -d ".claude" ]; then
  CCSS_ROOT="$PWD"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}" ]; then
  CCSS_ROOT="$CLAUDE_PROJECT_DIR"
else
  CCSS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)"
fi
[ -n "$CCSS_ROOT" ] && cd "$CCSS_ROOT" 2>/dev/null || true

# Claude Code Service Studios — Status Line
# Receives JSON on stdin, outputs a single-line status.
#
# Segments: ctx% | model | stage · rigor [| Epic > Feature > Task]

input=$(cat)

# --- Parse JSON (jq with grep fallback) ---
if command -v jq &>/dev/null; then
  model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
  used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
  cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
else
  model=$(echo "$input" | grep -oE '"display_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
  used_pct=$(echo "$input" | grep -oE '"used_percentage"[[:space:]]*:[[:space:]]*[0-9]+' | head -1 | sed 's/.*: *//')
  cwd=$(echo "$input" | grep -oE '"current_dir"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
  [ -z "$model" ] && model="Unknown"
fi

# Normalize Windows paths
cwd=$(echo "$cwd" | sed 's|\\|/|g')
[ -z "$cwd" ] && cwd="."

# --- Context usage ---
if [ -n "$used_pct" ]; then
  ctx_label="ctx: ${used_pct}%"
else
  ctx_label="ctx: --"
fi

# --- Stage ---
# One estimator for the whole framework: .claude/scripts/stage-estimate.sh.
# Its STAGE line is project.stage when that is set to a valid stage, otherwise
# its own estimate from fixed paths. The status line keeps no ladder of its own:
# a private copy drifts, and then the status line, /help and the gates report
# different stages for the same tree. --quick keeps the call inside the
# per-turn budget (fixed-path globs only, no source-file count).
#
# $cwd is passed as the project root so the stage describes the same workspace
# as every other segment below. The project's own copy of the estimator runs
# when it has one; the copy next to this script otherwise.
stage=""
project_yaml="$cwd/project.yaml"
yaml_helper="$cwd/.claude/hooks/yaml-helper.sh"
stage_script="$cwd/.claude/scripts/stage-estimate.sh"
[ -f "$stage_script" ] || stage_script="${CCSS_ROOT:-.}/.claude/scripts/stage-estimate.sh"
if [ -f "$stage_script" ]; then
  stage=$(bash "$stage_script" --quick "$cwd" 2>/dev/null | sed -n 's/^STAGE: //p' | head -1)
fi
# No estimator, or it printed nothing: say "unknown" the same way the context
# segment does, rather than inventing a stage.
[ -z "$stage" ] && stage="--"

# --- Process posture (modes.rigor) ---
# Locked to project.yaml (not locally overridable) with a plain terminal default
# of 'minimal', so a direct get_yaml_key read + default is exact:
#   Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which
#   resolves `review_mode` to `solo`.
# A value outside minimal|standard|full is treated as unset, exactly as
# yaml-helper's resolution lets an enum-invalid value fall through to the
# default — the status line must never show a posture the skills do not use.
# Deliberately NOT resolve_setting: that resolves from the preamble's root,
# while every segment of this line describes the workspace in $cwd.
#
# The 'minimal' default applies ONLY when nothing contradicts it. If `rigor` is
# unset but a knob it fronts is set explicitly, the project's real process
# weight is whatever that knob says, and printing 'minimal' actively misreports
# it — a project that pins `modes.review_mode: full` by hand, with no
# `modes.rigor`, runs full director reviews while the line would read
# 'Build · minimal'. Suppress instead of guessing, matching the unconfigured-
# project behaviour: no config, no claim. Suppression is correct rather than
# lossy — the fronted knobs disagree with each other in this state, so there
# is no single honest posture.
rigor=""
if [ -f "$project_yaml" ] && [ -f "$yaml_helper" ]; then
  source "$yaml_helper"
  # Cheap superset pre-filter: no indented `rigor:` line anywhere means
  # modes.rigor cannot be set, so the interpreter start is skipped. It only
  # ever skips the precise read below; it never decides the value.
  if grep -qE '^[[:space:]]+rigor:' "$project_yaml" 2>/dev/null; then
    rigor=$(get_yaml_key "$project_yaml" modes.rigor 2>/dev/null)
  fi
  case "$rigor" in
    minimal|standard|full) ;;
    *) rigor="" ;;
  esac
  if [ -z "$rigor" ]; then
    rigor="minimal"
    # Cheap pre-filter first. This line renders every turn, and the common case
    # (nothing fronted set) must not cost a get_yaml_key subprocess per key.
    # The grep is a deliberate SUPERSET — it matches the leaf names anywhere at
    # depth, so a false positive only costs the precise checks below, while a
    # miss is impossible. Never let it decide on its own: a bare `size:` under
    # some unrelated block would suppress the posture with no reason.
    _fronted='^[[:space:]]+(review_mode|workflow|density|level|story_granularity|size):[[:space:]]*[^[:space:]#]'
    for _f in "$project_yaml" "$cwd/project.local.yaml"; do
      [ -f "$_f" ] || continue
      grep -qE "$_fronted" "$_f" 2>/dev/null || continue
      for _k in modes.review_mode modes.workflow docs.density qa.level \
                modes.story_granularity team.size; do
        if [ -n "$(get_yaml_key "$_f" "$_k" 2>/dev/null)" ]; then rigor=""; break; fi
      done
      [ -z "$rigor" ] && break
    done
  fi
fi

# --- Epic/Feature/Task breadcrumb (Build and later only) ---
breadcrumb=""
if [ "$stage" = "Build" ] || [ "$stage" = "Hardening" ] || [ "$stage" = "Launch" ]; then
  state_file="$cwd/production/session-state/active.md"
  if [ -f "$state_file" ]; then
    # Parse structured STATUS block
    in_block=false
    epic="" feature="" task=""
    while IFS= read -r line; do
      case "$line" in
        *"<!-- STATUS -->"*) in_block=true; continue ;;
        *"<!-- /STATUS -->"*) break ;;
      esac
      if [ "$in_block" = true ]; then
        case "$line" in
          Epic:*) epic=$(echo "$line" | sed 's/^Epic: *//') ;;
          Feature:*) feature=$(echo "$line" | sed 's/^Feature: *//') ;;
          Task:*) task=$(echo "$line" | sed 's/^Task: *//') ;;
        esac
      fi
    done < "$state_file"

    # Build breadcrumb from whatever is set
    parts=""
    [ -n "$epic" ] && parts="$epic"
    [ -n "$feature" ] && parts="${parts:+$parts > }$feature"
    [ -n "$task" ] && parts="${parts:+$parts > }$task"
    [ -n "$parts" ] && breadcrumb=" | $parts"
  fi
fi

# --- Assemble ---
printf "%s" "${ctx_label} | ${model} | ${stage}${rigor:+ · $rigor}${breadcrumb}"
