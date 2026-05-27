# Session 14b: autoMode + autoAllowBashIfSandboxed Layered

## Config

Sandbox enabled, `defaultMode: "auto"`, `autoAllowBashIfSandboxed: true`. Both settings active.

## Goal

sandbox-14 showed that `defaultMode: "auto"` alone doesn't change parser gating. Commands still prompt, autoMode just auto-accepts them. This test adds `autoAllowBashIfSandboxed` back to see the layered behavior.

**Prediction:** The parser auto-allows the same commands as sandbox-13 (simple commands, anchored variables). The remaining prompts (bare `$VAR`, command_substitution, etc.) get auto-accepted by autoMode. Net result: nothing prompts at all.

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Test Commands

Same command set as sandbox-14 for direct comparison.

### Group A: Controls (auto-allowed in both sandbox-13 and sandbox-14)

```
A1: echo hello world
```

```
A2: echo hello | grep h
```

### Group B: Bare variable expansion (prompted in sandbox-13 and sandbox-14)

```
B1: echo $HOME
```

```
B2: echo $MY_CUSTOM_VAR
```

### Group C: String-only expansion (prompted in sandbox-13 and sandbox-14)

```
C1: echo "$HOME"
```

```
C2: echo "$USER"
```

### Group D: Anchored variable (auto-allowed in both sandbox-13 and sandbox-14)

```
D1: echo "value: $HOME"
```

```
D2: for i in 1 2 3; do echo "item $i"; done
```

### Group E: Command substitution (prompted in sandbox-13 and sandbox-14)

```
E1: echo $(whoami)
```

### Group F: Process substitution (prompted in sandbox-13 and sandbox-14)

```
F1: cat <(echo hello)
```

### Group G: Brace expansion (prompted in sandbox-13 and sandbox-14)

```
G1: echo {1..5}
```

### Group H: Compound statement (prompted in sandbox-13 and sandbox-14)

```
H1: { echo a; echo b; }
```

### Group I: For loop with bare variable (prompted in sandbox-13 and sandbox-14)

```
I1: for f in a.txt b.txt c.txt; do echo $f; done
```

### Group J: For loop with string-only variable (prompted in sandbox-13 and sandbox-14)

```
J1: for i in 1 2 3; do echo "$i"; done
```

## After All Tests

Write "done" to the SIGNAL_FILE.
