#!/usr/bin/env bash
# Permission handler: logs PermissionRequest/PermissionDenied events and
# returns allow/deny decision for PermissionRequest.
#
# Environment:
#   HOOK_LOG_FILE            - path to append JSONL entries (required)
#   HARNESS_PERMISSION_MODE  - "accept" or "deny" (default: accept)

set -euo pipefail

LOG_FILE="${HOOK_LOG_FILE:?HOOK_LOG_FILE must be set}"
MODE="${HARNESS_PERMISSION_MODE:-accept}"
TS=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

PAYLOAD=$(cat)

# Log the event
printf '{"ts":"%s","payload":%s}\n' "$TS" "$PAYLOAD" >> "$LOG_FILE"

# Extract event name to decide whether to return a decision
EVENT_NAME=$(printf '%s' "$PAYLOAD" | grep -o '"hook_event_name":"[^"]*"' | cut -d'"' -f4)

if [ "$EVENT_NAME" = "PermissionRequest" ]; then
  if [ "$MODE" = "deny" ]; then
    cat <<'DENY'
{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"deny","message":"Denied by petri"}}}
DENY
  else
    cat <<'ALLOW'
{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}
ALLOW
  fi
fi

exit 0
