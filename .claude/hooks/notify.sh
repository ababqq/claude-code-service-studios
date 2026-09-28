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

# Notification hook — fires when Claude Code sends a notification
# Shows a desktop notification with the tool each platform already ships:
#   Windows (Git Bash, MSYS, Cygwin) and WSL
#                    balloon tip via PowerShell (System.Windows.Forms)
#   macOS            osascript -e 'display notification …'
#   Linux            notify-send, when it is installed
# Anything else -- or a platform whose tool is missing -- is a silent no-op.
# A notification is a convenience: this hook never blocks and never fails a
# session over one, so every notifier runs in the background with its output
# discarded, and the exit code is always 0.

# Read notification JSON from stdin
INPUT=$(cat)

# Extract message — try jq first, fall back to grep
if command -v jq &>/dev/null; then
  MESSAGE=$(echo "$INPUT" | jq -r '.message // empty' 2>/dev/null)
fi
if [ -z "${MESSAGE:-}" ]; then
  # `[[:space:]]*` around the colon, like every other hook's fallback. This one
  # required `"message":"` with no space, so a pretty-printed or space-separated
  # payload fell through to the generic text below and the real notification was
  # lost. Nothing reported that -- the hook still fired, just saying nothing.
  MESSAGE=$(echo "$INPUT" | grep -oE '"message"[[:space:]]*:[[:space:]]*"[^"]*"' \
            | head -1 | sed 's/"message"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi
if [ -z "$MESSAGE" ]; then
  MESSAGE="Claude Code needs your attention"
fi

# TRUNCATE FIRST, then escape. Escaping doubles each `'` into `''`, so cutting
# at a fixed byte count afterwards can land between the two halves of a pair and
# hand PowerShell an unbalanced quote. The command then fails to parse, and
# because it is backgrounded with stderr discarded the only symptom is a
# notification that never appears.
#
# A byte cut can also split a multi-byte character (a Korean message is three
# bytes per syllable), and osascript and notify-send reject the invalid tail
# the same silent way. iconv -c drops the partial sequence when iconv exists;
# without it the cut is used as-is.
MESSAGE_SHORT=$(printf '%s' "$MESSAGE" | head -c 200)
if command -v iconv >/dev/null 2>&1; then
  _MS=$(printf '%s' "$MESSAGE_SHORT" | iconv -c -f UTF-8 -t UTF-8 2>/dev/null)
  [ -n "$_MS" ] && MESSAGE_SHORT="$_MS"
fi

# Show Windows balloon tip notification (works on all Windows 10/11 without extra modules)
notify_windows() {
  MESSAGE_SAFE=$(printf '%s' "$MESSAGE_SHORT" | sed "s/'/''/g")
  powershell.exe -NonInteractive -WindowStyle Hidden -Command "
    Add-Type -AssemblyName System.Windows.Forms
    \$notify = New-Object System.Windows.Forms.NotifyIcon
    \$notify.Icon = [System.Drawing.SystemIcons]::Information
    \$notify.BalloonTipTitle = 'Claude Code'
    \$notify.BalloonTipText = '$MESSAGE_SAFE'
    \$notify.Visible = \$true
    \$notify.ShowBalloonTip(5000)
    Start-Sleep -Seconds 6
    \$notify.Dispose()
  " >/dev/null 2>&1 &
}

# macOS Notification Center. The message goes inside an AppleScript string
# literal, whose only special characters are the backslash and the double
# quote -- escape exactly those (backslash first) and nothing else.
notify_macos() {
  _AS=$(printf '%s' "$MESSAGE_SHORT" | sed 's/\\/\\\\/g; s/"/\\"/g')
  osascript -e "display notification \"$_AS\" with title \"Claude Code\"" >/dev/null 2>&1 &
}

# freedesktop notifications. notify-send renders a small markup subset in the
# body, so a literal `<` or `&` in the message would be eaten as a tag or an
# entity; escape the three markup characters (ampersand first).
notify_linux() {
  _NS=$(printf '%s' "$MESSAGE_SHORT" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
  notify-send "Claude Code" "$_NS" >/dev/null 2>&1 &
}

case "$(uname -s 2>/dev/null)" in
  Darwin)
    command -v osascript >/dev/null 2>&1 && notify_macos
    ;;
  Linux)
    # WSL is Linux with Windows interop: prefer a native notifier when one is
    # installed, otherwise the Windows balloon reaches the desktop the user sees.
    if command -v notify-send >/dev/null 2>&1; then
      notify_linux
    elif command -v powershell.exe >/dev/null 2>&1; then
      notify_windows
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    command -v powershell.exe >/dev/null 2>&1 && notify_windows
    ;;
  *)
    : # no notifier for this platform -- silent no-op
    ;;
esac

echo "Notification: $MESSAGE_SHORT"
exit 0
