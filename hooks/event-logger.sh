#!/usr/bin/env bash
# Hook event logger: reads JSON from stdin, adds timestamp, appends to JSONL file.
# Attached to all non-decision hook event types: PreToolUse, PostToolUse,
# UserPromptSubmit, Notification, Stop, SubagentStop, PreCompact, SessionStart,
# SessionEnd, PermissionDenied.
#
# Environment:
#   PETRIDISH_HOOK_LOG_FILE - path to append JSONL entries (required)

set -euo pipefail

LOG_FILE="${PETRIDISH_HOOK_LOG_FILE:?PETRIDISH_HOOK_LOG_FILE must be set}"
TS=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

PAYLOAD=$(cat)

printf '{"ts":"%s","payload":%s}\n' "$TS" "$PAYLOAD" >> "$LOG_FILE"

exit 0
