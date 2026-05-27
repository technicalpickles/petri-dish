#!/usr/bin/env bash
# inspect-session.sh — mine a Claude Code session JSONL for LSP-relevant content.
#
# Usage:
#   scripts/inspect-session.sh <path-to-session.jsonl>
#
# The session JSONL lives at:
#   ~/.local/share/cenv/<env>/projects/<cwd-slug>/<session-id>.jsonl
#
# Reports: attachment types, user-message content matching diagnostic patterns,
# and LSP tool invocations (operation + position).

set -euo pipefail

SESSION="${1:?usage: inspect-session.sh <session.jsonl>}"

if [ ! -f "$SESSION" ]; then
  echo "error: session file not found: $SESSION" >&2
  exit 1
fi

echo "=== Session: $SESSION ==="
echo

echo "=== Entry type counts ==="
jq -r '.type' "$SESSION" | sort | uniq -c
echo

echo "=== Attachment types ==="
jq -r 'select(.type == "attachment") | .attachment.type // (.attachment | keys | join(","))' "$SESSION" \
  | sort | uniq -c
echo

echo "=== User-role content matching diagnostic/lsp patterns ==="
jq -r 'select(.type == "user") | .message.content | if type == "array" then map(.text // (.content // "") | tostring) | join(" | ") else . end' "$SESSION" \
  | grep -iE 'diagnost|lsp |offense|warning:|error:' \
  | head -20 || echo "(no matches)"
echo

echo "=== LSP tool invocations (assistant tool_use entries) ==="
jq -r 'select(.type == "assistant") | .message.content | if type == "array" then map(select(.type == "tool_use" and .name == "LSP")) else [] end | .[] | "\(.input.operation // "?") @ \(.input.filePath // "?"):\(.input.line // "?"):\(.input.character // "?")"' "$SESSION" \
  || echo "(no LSP tool calls)"
echo

echo "=== Any 'lsp_diagnostics' or 'lspDiagnostics' anywhere in raw content ==="
grep -ciE 'lsp_diagnostics|lspDiagnostics' "$SESSION" || true
echo

echo "=== Tool counts (PreToolUse equivalent — assistant tool_use by name) ==="
jq -r 'select(.type == "assistant") | .message.content | if type == "array" then map(select(.type == "tool_use") | .name) else [] end | .[]' "$SESSION" \
  | sort | uniq -c
