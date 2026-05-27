#!/usr/bin/env python3
"""Analyze hook event log and correlate with sidecar results."""
import json
import sys
from datetime import datetime

def parse_ts(ts_str):
    """Parse ISO timestamp to datetime."""
    # Handle both millisecond and second precision
    for fmt in ("%Y-%m-%dT%H:%M:%S.%fZ", "%Y-%m-%dT%H:%M:%SZ"):
        try:
            return datetime.strptime(ts_str, fmt)
        except ValueError:
            continue
    return None

def main():
    hook_file = sys.argv[1] if len(sys.argv) > 1 else "/tmp/petri-hooks.jsonl"

    # Parse hook events
    entries = []
    with open(hook_file) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            data = json.loads(line)
            entries.append(data)

    # Pair Pre/Post by tool_use_id
    pairs = {}
    for entry in entries:
        ts = parse_ts(entry["ts"])
        p = entry["payload"]
        event = p["hook_event_name"]
        tid = p.get("tool_use_id")

        if event == "Notification":
            ntype = p.get("notification_type", "unknown")
            msg = p.get("message", "")
            print(f"  NOTIFICATION: type={ntype} msg={msg[:60]}")
            continue

        if not tid:
            continue

        if event == "PreToolUse":
            cmd = p.get("tool_input", {}).get("command", "")
            tool = p.get("tool_name", "")
            pairs[tid] = {"pre_ts": ts, "cmd": cmd, "tool": tool}
        elif event == "PostToolUse" and tid in pairs:
            pairs[tid]["post_ts"] = ts

    # Prompted commands from results.md (PROMPTED_ALLOWED)
    prompted_cmds = [
        "for f in a.txt b.txt c.txt; do echo $f; done",
        "for f in *.txt; do cat $f; done",
        "echo $(whoami)",
        "echo $(ls /tmp)",
        "echo {1..5}",
        "echo file-{a,b,c}.txt",
        "cat <(echo hello)",
        "{ echo a; echo b; }",
        "echo $HOME",
        "echo $PATH",
        "echo $MY_CUSTOM_VAR",
    ]

    print()
    print(f"{'#':<4} {'Command':<52} {'Delta':>7}  {'Sidecar':<18}")
    print("-" * 90)

    i = 0
    for tid, p in pairs.items():
        if "post_ts" not in p:
            continue
        if p["tool"] != "Bash":
            continue

        i += 1
        cmd = p["cmd"]
        delta = (p["post_ts"] - p["pre_ts"]).total_seconds()

        was_prompted = cmd in prompted_cmds
        sidecar = "PROMPTED" if was_prompted else "silent"

        # Truncate command for display
        cmd_display = cmd[:50] + "..." if len(cmd) > 50 else cmd

        print(f"{i:<4} {cmd_display:<52} {delta:>6.2f}s  {sidecar:<18}")

    # Summary stats
    prompted_deltas = []
    silent_deltas = []
    for tid, p in pairs.items():
        if "post_ts" not in p or p["tool"] != "Bash":
            continue
        delta = (p["post_ts"] - p["pre_ts"]).total_seconds()
        if p["cmd"] in prompted_cmds:
            prompted_deltas.append(delta)
        else:
            silent_deltas.append(delta)

    print()
    print("Summary:")
    if silent_deltas:
        print(f"  Silent commands:   avg={sum(silent_deltas)/len(silent_deltas):.2f}s  "
              f"min={min(silent_deltas):.2f}s  max={max(silent_deltas):.2f}s  n={len(silent_deltas)}")
    if prompted_deltas:
        print(f"  Prompted commands: avg={sum(prompted_deltas)/len(prompted_deltas):.2f}s  "
              f"min={min(prompted_deltas):.2f}s  max={max(prompted_deltas):.2f}s  n={len(prompted_deltas)}")

if __name__ == "__main__":
    main()
