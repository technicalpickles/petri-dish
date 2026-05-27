# Session 9: Unix Sockets

## Sandbox Config

This is a TWO-PART session.

- **Part A** (env: sbox-s09-unix-sockets): Default sandbox, unix sockets blocked
- **Part B** (env: sbox-s09b-unix-sockets-allowed): `allowAllUnixSockets: true`

Run the part you're told. If not told, run Part A.

## Goal

Test unix socket access control. Default sandbox blocks unix sockets. This affects git fsmonitor-daemon, SSH agent, Docker socket, and other IPC. Compare blocked vs allowed behavior.

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Part A: Unix Sockets Blocked (default)

### Group A: SSH Agent

```
A1: ssh-add -l 2>&1
A2: ssh -T git@github.com 2>&1
```

### Group B: Docker Socket

```
B1: curl -s --unix-socket /var/run/docker.sock http://localhost/version 2>&1
B2: docker ps 2>&1
```

### Group C: Git IPC (fsmonitor uses unix sockets)

```
C1: git status 2>&1
C2: git fsmonitor--daemon status 2>&1
C3: git -c core.fsmonitor=false status 2>&1
```

### Group D: Arbitrary Socket Test

```
D1: python3 -c "
import socket, os, tempfile
path = os.path.join(tempfile.gettempdir(), 'test.sock')
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
try:
    s.bind(path)
    print(f'bound to {path}')
    s.close()
    os.unlink(path)
except Exception as e:
    print(f'failed: {e}')
" 2>&1
```

## Part B: Unix Sockets Allowed

Same commands as Part A. Everything that failed in Part A should work now.

Additionally, test the Docker socket escape (this is why allowing all sockets is dangerous):

```
B-E1: curl -s --unix-socket /var/run/docker.sock http://localhost/containers/json 2>&1 | head -c 500
```

If this works, a sandboxed process can enumerate and control Docker containers on the host. That's a sandbox escape.

## After All Tests

Write "done" to the SIGNAL_FILE.
