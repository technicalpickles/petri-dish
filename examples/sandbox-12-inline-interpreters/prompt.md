# Session 12: Inline Interpreter Commands

## Sandbox Config

Baseline sandbox: enabled, autoAllowBashIfSandboxed. Tests whether `node -e`, `python -c`, and piped interpreter commands are treated differently from direct file execution.

## Goal

Determine whether sandbox treats inline interpreter invocations (`node -e "..."`, `python3 -c "..."`) differently from running scripts as files. This matters for validation commands (e.g. JSONC parsing checks) that use inline code snippets. A subagent previously reported that `node -e` was denied during a hooks implementation, suggesting possible special handling.

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Test Commands

### Group A: Basic Inline Execution

```
A1: node -e 'console.log("hello from node")'
A2: python3 -c 'print("hello from python")'
A3: ruby -e 'puts "hello from ruby"'
```

### Group B: Inline with File I/O (in-project, should be allowed)

```
B1: node -e 'const fs = require("fs"); fs.writeFileSync("node-test.txt", "written by node -e"); console.log("wrote file")'
B2: python3 -c 'open("python-test.txt", "w").write("written by python -c"); print("wrote file")'
B3: node -e 'const fs = require("fs"); console.log(fs.readFileSync("README.md", "utf8").substring(0, 50))'
B4: python3 -c 'print(open("README.md").read()[:50])'
```

### Group C: Inline with File I/O (outside project, should be blocked)

```
C1: node -e 'const fs = require("fs"); fs.writeFileSync("/tmp/node-escape.txt", "escaped"); console.log("wrote")'
C2: python3 -c 'open("/tmp/python-escape.txt", "w").write("escaped"); print("wrote")'
C3: node -e 'const fs = require("fs"); fs.writeFileSync(require("os").homedir() + "/node-escape.txt", "escaped")'
C4: python3 -c 'from pathlib import Path; Path.home().joinpath("python-escape.txt").write_text("escaped")'
```

### Group D: Inline JSON/JSONC Parsing (the actual use case)

```
D1: node -e 'console.log(JSON.stringify({test: true}))'
D2: node -e 'const data = JSON.parse("{\"key\": \"value\"}"); console.log(data.key)'
D3: python3 -c 'import json; print(json.dumps({"key": "value"}))'
D4: node -e 'const fs = require("fs"); const content = fs.readFileSync("README.md", "utf8"); console.log("parsed", content.length, "bytes")'
```

### Group E: File-Based Execution (control group)

For comparison, run equivalent code from temp files in the project directory.

```
E1: echo 'console.log("hello from file")' > /tmp/sandbox-test/test-script.js && node /tmp/sandbox-test/test-script.js
E2: echo 'print("hello from file")' > /tmp/sandbox-test/test-script.py && python3 /tmp/sandbox-test/test-script.py
```

Note: write the files to the project directory (CWD) since that's writable.

### Group F: Piped Execution

```
F1: echo 'console.log("piped to node")' | node
F2: echo 'print("piped to python")' | python3
F3: echo '{"key": "value"}' | node -e 'let d=""; process.stdin.on("data",c=>d+=c); process.stdin.on("end",()=>console.log(JSON.parse(d)))'
F4: echo '{"key": "value"}' | python3 -c 'import sys,json; print(json.load(sys.stdin))'
```

### Group G: Network from Inline (edge case)

```
G1: node -e 'fetch("https://api.github.com/zen").then(r=>r.text()).then(console.log)' 2>&1
G2: python3 -c 'import urllib.request; print(urllib.request.urlopen("https://api.github.com/zen").read().decode())' 2>&1
```

### Group H: Multiline Inline with Comments (node)

These test whether multiline code with inline comments triggers sandbox prompts.

```
H1: node -e '
// Parse a simple config object
const config = { host: "localhost", port: 3000 };
// Log the formatted result
console.log("Config:", JSON.stringify(config));
'
```

```
H2: node -e '
// Read a file and count its lines
const fs = require("fs");
// Use the project README as test input
const content = fs.readFileSync("README.md", "utf8");
// Split by newline and report count
const lines = content.split("\n").length;
console.log("Lines:", lines);
'
```

```
H3: node -e '
// Validate JSON structure
const input = "{\"name\": \"test\", \"version\": 1}";
// Parse and check required fields
const parsed = JSON.parse(input);
const valid = parsed.name && parsed.version;
// Report validation result
console.log("Valid:", valid);
'
```

### Group I: Multiline Inline with Comments (python)

```
I1: python3 -c '
# Build a simple greeting message
name = "sandbox"
# Format with f-string
message = f"Hello from {name}"
# Print the result
print(message)
'
```

```
I2: python3 -c '
# Read a file and count lines
with open("README.md") as f:
    # Read all content
    content = f.read()
# Count newlines
line_count = content.count("\n") + 1
# Report
print(f"Lines: {line_count}")
'
```

```
I3: python3 -c '
# Parse and validate JSON data
import json
# Sample input
raw = "{\"name\": \"test\", \"version\": 1}"
# Parse it
data = json.loads(raw)
# Check required fields exist
valid = "name" in data and "version" in data
# Report
print(f"Valid: {valid}")
'
```

### Group J: Cleanup

```
J1: rm -f node-test.txt python-test.txt test-script.js test-script.py 2>&1
```

## After All Tests

Write "done" to the SIGNAL_FILE.
