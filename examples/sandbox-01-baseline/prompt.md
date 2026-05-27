# Session 1: Baseline (Sandbox On, No Config)

## Sandbox Config

Sandbox enabled with `autoAllowBashIfSandboxed`, nothing else. This tests the out-of-the-box sandbox behavior with zero customization.

## Goal

Understand what the sandbox does by default. What writes are allowed? Are reads restricted at all? How does network access work? What domains are pre-allowed?

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Test Commands

### Group A: Filesystem Writes

```
A1: echo "hello" > test.txt
A2: touch /tmp/sandbox-test-tmp.txt
A3: echo "hi" > ~/Desktop/sandbox-test.txt
A4: echo "bad" >> ~/.bashrc
A5: echo "bad" >> ~/.zshrc
A6: mkdir -p ~/sandbox-escape && touch ~/sandbox-escape/test.txt
```

### Group B: Filesystem Reads

```
B1: cat /etc/hosts | head -5
B2: cat /etc/resolv.conf
B3: cat ~/.ssh/config 2>&1 | head -5
B4: cat ~/.aws/credentials 2>&1 | head -5
B5: cat ~/.claude/settings.json 2>&1 | head -5
B6: ls ~/ | head -10
```

### Group C: Network (likely pre-allowed)

```
C1: curl -s https://api.github.com/zen
C2: curl -s https://registry.npmjs.org/left-pad | head -c 100
C3: curl -s https://rubygems.org | head -c 100
```

### Group D: Network (likely not pre-allowed)

```
D1: curl -s -m 5 https://example.com | head -c 100
D2: curl -s -m 5 https://httpbin.org/get | head -c 200
```

### Group E: Network Edge Cases

```
E1: curl -s -m 5 http://1.1.1.1 2>&1 | head -c 200
E2: ping -c 1 -t 3 example.com 2>&1
E3: nslookup example.com 2>&1
```

### Group F: Temp Directory

```
F1: echo "test" > $TMPDIR/sandbox-tmpdir-test.txt 2>&1
F2: echo "test" > /tmp/sandbox-tmp-test.txt 2>&1
F3: echo "test" > /private/tmp/claude-501/sandbox-test.txt 2>&1
```

## After All Tests

Write "done" to the SIGNAL_FILE.
