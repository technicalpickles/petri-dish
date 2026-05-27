# Session 13c: Compound Construct Walker

## Sandbox Config

Sandbox enabled, `autoAllowBashIfSandboxed: true`.

## Goal

Investigate why `for i in 1 2 3; do echo "item $i"; done` auto-allowed in sandbox-13 while `echo "$HOME"` prompts with "Unhandled node type: string" and `for f in ...; do echo $f; done` prompts with "Contains simple_expansion".

The hypothesis: the compound-construct walker (for/if/subshell) uses a different code path that handles `string` nodes differently from the top-level parser.

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Test Commands

### Group A: For loop with quoted vs bare vars (the critical comparison)

```
A1: for i in 1 2 3; do echo "$i"; done
```

```
A2: for i in 1 2 3; do echo $i; done
```

```
A3: for i in 1 2 3; do echo "item $i"; done
```

```
A4: for i in 1 2 3; do echo "literal string"; done
```

### Group B: If/then with quoted vs bare vars

```
B1: if true; then echo "$HOME"; fi
```

```
B2: if true; then echo $HOME; fi
```

```
B3: if true; then echo "literal string"; fi
```

### Group C: Subshell with quoted vs bare vars

```
C1: (echo "$HOME")
```

```
C2: (echo $HOME)
```

```
C3: (echo "literal string")
```

### Group D: Write path boundaries

```
D1: touch /tmp/sandbox-test/in-sandbox
```

```
D2: touch /tmp/not-in-sandbox
```

### Group E: Nested constructs

```
E1: if true; then for i in 1 2 3; do echo "item $i"; done; fi
```

```
E2: for i in 1 2 3; do if true; then echo "found $i"; fi; done
```

## After All Tests

Write "done" to the SIGNAL_FILE.
