#!/usr/bin/env bash
# PreToolUse hook: block any Bash command matching a regex pattern.
#
# Environment:
#   HOOK_BLOCK_PATTERN - regex matched against tool_input.command (required)
#   HOOK_LOG_FILE      - JSONL path to log every invocation (optional)
#
# Reads the PreToolUse JSON payload on stdin. If the command matches
# HOOK_BLOCK_PATTERN, emits a JSON decision denying the call with
# exit 0 (documented mechanism). Otherwise exits 0 silently.

set -u

LOG_FILE="${HOOK_LOG_FILE:-/tmp/harness-hooks.jsonl}"
PATTERN="${HOOK_BLOCK_PATTERN:-}"

PAYLOAD=$(cat)

# Log every invocation with timestamp
TS=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
printf '{"ts":"%s","payload":%s}\n' "$TS" "$PAYLOAD" >> "$LOG_FILE"

# No pattern configured: let everything through
if [ -z "$PATTERN" ]; then
  exit 0
fi

# Only evaluate Bash tool calls
TOOL_NAME=$(printf '%s' "$PAYLOAD" | python3 -c "import json,sys; print(json.load(sys.stdin).get('tool_name',''))")
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

COMMAND=$(printf '%s' "$PAYLOAD" | python3 -c "import json,sys; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))")

if printf '%s' "$COMMAND" | grep -qE "$PATTERN"; then
  cat <<JSON
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Blocked by policy hook: command matches HOOK_BLOCK_PATTERN"
  }
}
JSON
  exit 0
fi

exit 0
