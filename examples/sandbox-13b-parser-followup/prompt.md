# Session 13b: Parser Follow-up Tests

## Sandbox Config

Sandbox enabled, `autoAllowBashIfSandboxed: true`. Same config as sandbox-13.

## Goal

Confirm four findings from sandbox-13:

1. **Double-quote masking**: Does `"$VAR"` inside quotes avoid prompts while bare `$VAR` triggers them?
2. **For loop variable isolation**: Was C2's silence in sandbox-13 from double quotes or from something else about the for loop?
3. **Write path boundaries**: Do writes outside sandbox-allowed paths prompt?
4. **Nested constructs**: Do nested for/if/subshell combos still auto-allow when bodies are simple?

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Test Commands

### Group A: Double-quote masking (direct A/B comparison)

```
A1: echo $HOME
```

```
A2: echo "$HOME"
```

```
A3: echo $USER
```

```
A4: echo "$USER"
```

```
A5: echo $PWD
```

```
A6: echo "$PWD"
```

### Group B: For loop variable isolation

```
B1: for i in 1 2 3; do echo $i; done
```

```
B2: for i in 1 2 3; do echo "$i"; done
```

```
B3: for f in a b c; do echo $f; done
```

```
B4: for f in a b c; do echo "$f"; done
```

### Group C: Write path boundaries

```
C1: touch /tmp/sandbox-test/allowed-write
```

```
C2: touch /tmp/outside-sandbox-test
```

```
C3: mkdir -p /tmp/sandbox-test/allowed-dir
```

```
C4: echo "test" > /tmp/sandbox-test/allowed-redirect
```

```
C5: echo "test" > /tmp/outside-sandbox-redirect
```

### Group D: Nested constructs

```
D1: if true; then for i in 1 2 3; do echo "item $i"; done; fi
```

```
D2: for i in 1 2 3; do if [[ $i -eq 2 ]]; then echo "found $i"; fi; done
```

```
D3: (for i in 1 2 3; do echo "nested $i"; done)
```

```
D4: if true; then (echo "subshell in if"); fi
```

```
D5: for i in 1 2 3; do (echo "subshell in loop $i"); done
```

## After All Tests

Write "done" to the SIGNAL_FILE.
