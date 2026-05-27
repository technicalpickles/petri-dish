#!/usr/bin/env bash
# Hook logger: reads JSON from stdin, adds timestamp, appends to JSONL file.
# Usage: Configured as a Claude Code hook command.
#
# Environment:
#   HOOK_LOG_FILE - path to append JSONL entries (default: /tmp/harness-hooks.jsonl)

LOG_FILE="${HOOK_LOG_FILE:-/tmp/harness-hooks.jsonl}"
TS=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

# Read stdin (the hook JSON payload)
PAYLOAD=$(cat)

# Wrap with timestamp and write as one JSONL line
printf '{"ts":"%s","payload":%s}\n' "$TS" "$PAYLOAD" >> "$LOG_FILE"

# Exit 0: no decision, let normal flow continue
exit 0
