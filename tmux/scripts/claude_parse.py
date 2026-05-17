#!/usr/bin/env python3
"""
Claude rate-limit parser for tmux status bar.

Subcommands:
  read-token    <credentials_file>            Print OAuth access token
  refresh-cache <headers_file> <cache_file>   Parse API response headers → cache
  cache-ts      <cache_file>                  Print cache timestamp (0 if missing)
  format-output <cache_file>                  Print formatted usage string
"""
import json
import re
import sys
import time


def cmd_read_token(creds_file: str) -> None:
    try:
        d = json.load(open(creds_file))
        print(d["claudeAiOauth"]["accessToken"])
    except Exception:
        print("")


def cmd_refresh_cache(headers_file: str, cache_file: str) -> None:
    try:
        with open(headers_file) as f:
            headers = f.read()

        def get_h(name: str):
            m = re.search(rf"^{re.escape(name)}:\s*(.+)$", headers, re.M | re.I)
            return m.group(1).strip() if m else None

        util_5h  = get_h("anthropic-ratelimit-unified-5h-utilization")
        reset_5h = get_h("anthropic-ratelimit-unified-5h-reset")
        util_7d  = get_h("anthropic-ratelimit-unified-7d-utilization")
        reset_7d = get_h("anthropic-ratelimit-unified-7d-reset")

        cache = {
            "ts":       int(time.time()),
            "util_5h":  round(float(util_5h) * 100) if util_5h  else None,
            "reset_5h": int(reset_5h)                if reset_5h else None,
            "util_7d":  round(float(util_7d) * 100) if util_7d  else None,
            "reset_7d": int(reset_7d)                if reset_7d else None,
        }
        json.dump(cache, open(cache_file, "w"))
    except Exception:
        pass


def cmd_cache_ts(cache_file: str) -> None:
    try:
        print(json.load(open(cache_file)).get("ts", 0))
    except Exception:
        print(0)


def cmd_format_output(cache_file: str) -> None:
    try:
        d = json.load(open(cache_file))
        util  = d.get("util_5h")
        reset = d.get("reset_5h")

        if util is None:
            print("--")
            return

        remaining_s = max(0, reset - int(time.time())) if reset else 0
        h = remaining_s // 3600
        m = (remaining_s % 3600) // 60
        tstr = f"~{h}h{m:02d}m" if h > 0 else f"~{m}m"
        print(f"{util}% {tstr}")
    except Exception:
        print("--")


COMMANDS = {
    "read-token":    (cmd_read_token,    1),
    "refresh-cache": (cmd_refresh_cache, 2),
    "cache-ts":      (cmd_cache_ts,      1),
    "format-output": (cmd_format_output, 1),
}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        print(__doc__)
        sys.exit(1)

    cmd, n_args = COMMANDS[sys.argv[1]]
    if len(sys.argv) - 2 != n_args:
        print(f"usage: {sys.argv[0]} {sys.argv[1]} <{'> <'.join(['arg'] * n_args)}>")
        sys.exit(1)

    cmd(*sys.argv[2:])
