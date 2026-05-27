# Session 7: Escape Hatch Behavior

## Sandbox Config

This is a THREE-PART session. You will be told which part to run.

- **Part A** (env: sbox-s07-escape-hatch): Default sandbox, escape hatch ON (default behavior)
- **Part B** (env: sbox-s07b-escape-hatch-disabled): `allowUnsandboxedCommands: false`
- **Part C** (env: sbox-s07c-excluded-commands): `allowUnsandboxedCommands: false` + `excludedCommands: ["docker"]`

Run the part you're told. If not told, run Part A.

## Goal

Understand how `dangerouslyDisableSandbox` works in practice. When does the escape hatch trigger? Can it be disabled? How do `excludedCommands` interact with sandbox restrictions?

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Part A: Escape Hatch ON (default)

### Group A: Commands Known to Be Sandbox-Incompatible

```
A1: docker ps 2>&1
A2: docker compose ls 2>&1
```

### Group B: Commands That Should Work

```
B1: ls -la
B2: git status
B3: curl -s https://api.github.com/zen
```

### Group C: Borderline Commands

```
C1: python3 -c "import socket; s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); print('socket created')" 2>&1
C2: nc -z localhost 8080 2>&1
```

## Part B: Escape Hatch DISABLED

Same commands as Part A. The key question: with `allowUnsandboxedCommands: false`, do sandbox-incompatible commands just fail with no escape?

## Part C: Excluded Commands

```
C-A1: docker ps 2>&1
C-A2: docker compose ls 2>&1
C-B1: curl -s https://example.com
C-B2: ls -la
```

Docker should run outside the sandbox (excluded). Everything else stays sandboxed.

## After All Tests

Write "done" to the SIGNAL_FILE.
