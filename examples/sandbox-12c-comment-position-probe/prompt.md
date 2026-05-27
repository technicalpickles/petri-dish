# Session 12c: Comment Position Probe

## Sandbox Config

Sandbox enabled, `autoAllowBashIfSandboxed: false`. Tests whether the "Newline followed by # can hide arguments from path validation" warning depends on comment position, indentation, quote style, or language.

## Goal

Session 12b found that `python3 -c` with `# comments` at line start triggers a security warning in the permission prompt, but `node -e` with `// comments` does not. This session probes the boundary: does indentation, mid-line position, double quotes, or `#` in node code also trigger it?

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Test Commands

### Group A: Python # at line start (single quotes, known trigger)

```
A1: python3 -c '
# comment at start
x = 42
print(x)
'
```

### Group B: Python # mid-line only (single quotes)

```
B1: python3 -c '
x = 42  # set value
y = x * 2  # double it
print(y)  # output
'
```

### Group C: Python # indented in block (single quotes)

```
C1: python3 -c '
for i in range(3):
    # process each item
    print(f"item {i}")
'
```

```
C2: python3 -c '
items = [1, 2, 3]
for item in items:
    # multiply by two
    result = item * 2
    print(result)
'
```

### Group D: Python # at line start (double quotes)

```
D1: python3 -c "
# comment at start
x = 42
print(x)
"
```

### Group E: Python # mid-line only (double quotes)

```
E1: python3 -c "
x = 42  # set value
y = x * 2  # double it
print(y)  # output
"
```

### Group F: Python # indented (double quotes)

```
F1: python3 -c "
for i in range(3):
    # process each item
    print(f'item {i}')
"
```

### Group G: Node // at line start (single quotes, known safe)

```
G1: node -e '
// comment at start
const x = 42;
console.log(x);
'
```

### Group H: Node // mid-line (single quotes)

```
H1: node -e '
const x = 42; // set value
const y = x * 2; // double it
console.log(y); // output
'
```

### Group I: Node // indented in block (single quotes)

```
I1: node -e '
for (let i = 0; i < 3; i++) {
    // process each item
    console.log("item " + i);
}
'
```

### Group J: Node with # in string (single quotes)

```
J1: node -e '
const channel = "#general";
console.log(channel);
'
```

```
J2: node -e '
const tags = ["#foo", "#bar"];
console.log(tags.join(", "));
'
```

### Group K: Node // at line start (double quotes)

```
K1: node -e "
// comment at start
const x = 42;
console.log(x);
"
```

### Group L: Node // indented (double quotes)

```
L1: node -e "
for (let i = 0; i < 3; i++) {
    // process each item
    console.log('item ' + i);
}
"
```

### Group M: Node with # in string (double quotes)

```
M1: node -e "
const channel = '#general';
console.log(channel);
"
```

### Group N: Edge cases

```
N1: python3 -c '
x = "# not a comment"
print(x)
'
```

```
N2: python3 -c '
x = 42
# comment after code
print(x)
'
```

```
N3: python3 -c 'x = 42  # inline only, single line'
```

```
N4: python3 -c "x = 42  # inline only, single line, double quotes"
```

## After All Tests

Write "done" to the SIGNAL_FILE.
