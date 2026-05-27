# Permission Test 02b: Bare Bash in ask — Unsandboxed Fires

## Config

- `sandbox.enabled: true`, `autoAllowBashIfSandboxed: true`
- `permissions.ask: [Bash]` — bare Bash rule, no pattern

## Goal

Validate the escape-hatch workaround (from anthropics/claude-code#34315): bare `Bash` in the `ask` list fires a permission prompt when the command runs with `dangerouslyDisableSandbox: true`.

This complements 02a: sandboxed commands are silent (02a); unsandboxed retries hit the ask rule and prompt (02b).

## Protocol

Follow the escape hatch protocol from the preamble. Use `dangerouslyDisableSandbox` when your normal rules say to (sandbox failure evidence), and report both sandboxed and unsandboxed attempts for any retry.

## Steps

### A1: Trigger natural sandbox failure + unsandboxed retry

```
defaults write ~/Library/Preferences/com.bare-bash-ask-probe.plist key value
```

Expected:
- First attempt: auto-allowed under sandbox (sandboxed commands bypass the ask rule), then FAILS with Operation not permitted (~/Library/Preferences not in allowWrite)
- Retry with `dangerouslyDisableSandbox: true`: hits the `ask` rule and PROMPTS — the bare Bash ask rule fires for unsandboxed commands
- Sidecar accepts the prompt. Command succeeds.

Report both the first attempt result and the retry result separately.

## Cleanup

After A1 succeeds, delete the plist:

```
rm -f ~/Library/Preferences/com.bare-bash-ask-probe.plist
```

(Use `dangerouslyDisableSandbox: true` for cleanup too if needed.)

## After All Steps

Write "done" to the SIGNAL_FILE.
