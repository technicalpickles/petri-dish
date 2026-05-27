# Session 10: Localhost Binding

## Sandbox Config

This is a TWO-PART session.

- **Part A** (env: sbox-s10-localhost-binding): Default sandbox, localhost binding disabled
- **Part B** (env: sbox-s10b-localhost-binding-enabled): `allowLocalBinding: true`

Run the part you're told. If not told, run Part A.

## Goal

Test whether sandboxed processes can bind localhost ports. Dev servers (rails, node, python), test runners, and some tools need this. Docs say it's disabled by default on macOS.

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Part A: Localhost Binding Disabled (default)

### Group A: Simple Listeners

```
A1: python3 -c "
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    s.bind(('127.0.0.1', 18234))
    s.listen(1)
    print(f'bound to 127.0.0.1:18234')
    s.close()
except Exception as e:
    print(f'bind failed: {e}')
" 2>&1
```

```
A2: python3 -c "
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    s.bind(('0.0.0.0', 18235))
    s.listen(1)
    print(f'bound to 0.0.0.0:18235')
    s.close()
except Exception as e:
    print(f'bind failed: {e}')
" 2>&1
```

```
A3: nc -l 18236 &
sleep 1
kill %1 2>/dev/null
echo "nc exit: $?"
```

### Group B: Dev Server Patterns

```
B1: timeout 3 python3 -m http.server 18237 2>&1 || true
B2: timeout 3 node -e "require('http').createServer((q,s)=>{s.end('ok')}).listen(18238, ()=>console.log('listening'))" 2>&1 || true
```

### Group C: Outbound Connections (should still work)

```
C1: curl -s https://api.github.com/zen
C2: python3 -c "
import urllib.request
r = urllib.request.urlopen('https://api.github.com/zen')
print(r.read().decode())
" 2>&1
```

## Part B: Localhost Binding Enabled

Same commands as Part A. Binding should work now.

## After All Tests

Write "done" to the SIGNAL_FILE.
