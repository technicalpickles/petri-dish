# Session 13d: Parser Bail List Validation (Lite)

## Sandbox Config

Sandbox enabled, `autoAllowBashIfSandboxed: true`. The parser classifies commands before the sandbox auto-allow check. Simple commands under sandbox read paths auto-allow silently. Commands that hit a bail condition prompt.

## Goal

Validate the specific Layer 3 bail-list claims for the "Claude Code permission layers" article. Each command targets one parser classification:

- **A1:** bare `$VAR` → hits `simple_expansion` bail, should prompt
- **A2:** `"$HOME"` (quoted, var only) → hits `Unhandled node type: string`, should prompt
- **A3:** `"item $HOME"` (quoted, mixed) → anchored-variable pattern, should auto-allow
- **A4:** `{1..5}` → brace expansion bail, should prompt
- **A5:** `$(whoami)` → command substitution bail, should prompt
- **A6:** `touch /tmp/sandbox-test/foo && echo done` → compound, all-safe children, should auto-allow
- **A7:** `echo hello | grep hello` → pipeline, all-safe children, should auto-allow
- **A8:** `cat /tmp/sandbox-test/foo` → simple read inside sandbox, should auto-allow

Run A6 before A8 so the file exists.

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Test Commands

### Group A: Parser bail-list probes

```
A1: echo $HOME
```

```
A2: echo "$HOME"
```

```
A3: echo "item $HOME"
```

```
A4: echo {1..5}
```

```
A5: echo $(whoami)
```

```
A6: touch /tmp/sandbox-test/foo && echo done
```

```
A7: echo hello | grep hello
```

```
A8: cat /tmp/sandbox-test/foo
```

## After All Tests

Write "done" to the SIGNAL_FILE.
