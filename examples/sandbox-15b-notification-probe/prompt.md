# Session 15b: Notification Hook Probe

Run these 3 commands. These use variable expansion and command substitution which the parser flags as complex. Run each command, report the result, output a RESULT line, move to the next.

## Commands

```
A1: echo $HOME
```

```
A2: echo $(whoami)
```

```
A3: echo {1..5}
```

When done, write "done" to the SIGNAL_FILE.
