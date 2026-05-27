# Session 12b: Permission Prompt Layer (autoAllowBashIfSandboxed OFF)

## Sandbox Config

Sandbox enabled but `autoAllowBashIfSandboxed: false`. No tools are pre-allowed in permissions. This means every Bash command goes through the permission prompt layer, which parses the command before showing it to the user.

## Goal

Test whether the permission prompt layer treats multiline inline code with comments differently from simple one-line commands. Session 12 proved the OS-level sandbox doesn't care, but session 12 used `autoAllowBashIfSandboxed: true` which bypasses the permission prompt entirely. This session exposes that layer.

Specifically: does the command parser show "Unhandled node type: string" or similar diagnostic messages for multiline code with comments?

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Test Commands

### Group A: Simple One-Liners (control group)

```
A1: echo "hello"
A2: ls -la
A3: cat README.md
A4: git status
```

### Group B: Simple Inline Interpreters (no comments)

```
B1: node -e 'console.log("hello")'
B2: python3 -c 'print("hello")'
B3: ruby -e 'puts "hello"'
```

### Group C: Multiline Inline WITHOUT Comments

```
C1: node -e '
const x = 42;
const y = x * 2;
console.log(y);
'
```

```
C2: python3 -c '
x = 42
y = x * 2
print(y)
'
```

### Group D: Multiline Inline WITH Comments (the hypothesis)

```
D1: node -e '
// Calculate a simple value
const x = 42;
// Double it
const y = x * 2;
// Print the result
console.log(y);
'
```

```
D2: python3 -c '
# Calculate a simple value
x = 42
# Double it
y = x * 2
# Print the result
print(y)
'
```

```
D3: node -e '
// Read a file and count lines
const fs = require("fs");
// Use README as input
const content = fs.readFileSync("README.md", "utf8");
// Count newlines
const lines = content.split("\n").length;
console.log("Lines:", lines);
'
```

```
D4: python3 -c '
# Read a file and count lines
with open("README.md") as f:
    content = f.read()
# Count newlines
line_count = content.count("\n") + 1
print(f"Lines: {line_count}")
'
```

### Group E: Piped Commands with Comments

```
E1: echo '{"key": "value"}' | python3 -c '
# Read JSON from stdin
import sys, json
# Parse it
data = json.load(sys.stdin)
# Print formatted
print(json.dumps(data, indent=2))
'
```

```
E2: cat README.md | node -e '
// Read stdin and count chars
let d = "";
process.stdin.on("data", c => d += c);
// Print count when done
process.stdin.on("end", () => console.log("Chars:", d.length));
'
```

### Group F: Complex One-Liners with Pipes (no comments, for comparison)

```
F1: echo '{"key": "value"}' | python3 -c 'import sys,json; print(json.dumps(json.load(sys.stdin), indent=2))'
F2: cat README.md | wc -l
```

## After All Tests

Write "done" to the SIGNAL_FILE.
