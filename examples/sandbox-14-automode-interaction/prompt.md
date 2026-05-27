# Session 14: autoMode Interaction with Parser Patterns

## Config

Sandbox enabled, `defaultMode: "auto"`. Note: `autoAllowBashIfSandboxed` is NOT set.

## Goal

In sandbox-13, we mapped out which bash constructs auto-allow vs prompt under `autoAllowBashIfSandboxed`. This test checks whether `defaultMode: "auto"` overrides those parser decisions. We're reusing the commands that ALWAYS prompted in sandbox-13, plus two controls that auto-allowed.

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Test Commands

### Group A: Controls (auto-allowed in sandbox-13)

```
A1: echo hello world
```

```
A2: echo hello | grep h
```

### Group B: Bare variable expansion (prompted in sandbox-13: "Contains simple_expansion")

```
B1: echo $HOME
```

```
B2: echo $MY_CUSTOM_VAR
```

### Group C: String-only expansion (prompted in sandbox-13: "Unhandled node type: string")

```
C1: echo "$HOME"
```

```
C2: echo "$USER"
```

### Group D: Anchored variable (auto-allowed in sandbox-13)

```
D1: echo "value: $HOME"
```

```
D2: for i in 1 2 3; do echo "item $i"; done
```

### Group E: Command substitution (prompted in sandbox-13: "Contains command_substitution")

```
E1: echo $(whoami)
```

### Group F: Process substitution (prompted in sandbox-13: "Contains process_substitution")

```
F1: cat <(echo hello)
```

### Group G: Brace expansion (prompted in sandbox-13)

```
G1: echo {1..5}
```

### Group H: Compound statement (prompted in sandbox-13: "Contains compound_statement")

```
H1: { echo a; echo b; }
```

### Group I: For loop with bare variable (prompted in sandbox-13)

```
I1: for f in a.txt b.txt c.txt; do echo $f; done
```

### Group J: For loop with string-only variable (prompted in sandbox-13)

```
J1: for i in 1 2 3; do echo "$i"; done
```

## After All Tests

Write "done" to the SIGNAL_FILE.
