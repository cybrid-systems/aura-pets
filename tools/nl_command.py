#!/usr/bin/env python3
"""DEPRECATED shim — NL director is pure Aura now.

Prefer lib/nl-engine.aura via aura-jobs / run.sh play.
This script shells out to Aura for old call sites.
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AURA = os.environ.get("AURA_BIN", "/home/dev/code/grok-dev/aura-grok/build/aura")


def main() -> int:
    ap = argparse.ArgumentParser(description="Deprecated: use Aura nl-engine")
    ap.add_argument("--text", required=True)
    ap.add_argument("--out", default="/tmp/aura-pets-nl.txt")
    ap.add_argument("--cols", type=int, default=80)
    ap.add_argument("--rows", type=int, default=24)
    ap.add_argument("--context", default="")
    ap.add_argument("--context-file", default="")
    ap.add_argument("--offline", action="store_true")
    args = ap.parse_args()
    env = os.environ.copy()
    env["AURA_PETS_ROOT"] = str(ROOT)
    env.setdefault("AURA_STDLIB_DIR", "/home/dev/code/grok-dev/aura-grok/lib/std")
    env.setdefault("AURA_PATH", "/home/dev/code/grok-dev/aura-grok/lib")
    if args.offline:
        env["AURA_PETS_NL_OFFLINE"] = "1"
    if args.context_file and Path(args.context_file).is_file():
        pass  # engine reads /tmp/aura-pets-nl-ctx.txt by convention
    safe = (
        args.text.replace("\\", "")
        .replace('"', "")
        .replace("'", "")
        .replace("\n", " ")
    )
    expr = (
        f'(begin (load "{ROOT}/lib/llm-client.aura") '
        f'(load "{ROOT}/lib/worldgen-engine.aura") '
        f'(load "{ROOT}/lib/nl-engine.aura") '
        f'(nl-engine-run! "{safe}" {args.cols} {args.rows} "{args.out}" '
        f'{"#t" if args.offline else "#f"}))'
    )
    print(f"nl_command.py: delegating to Aura ({AURA})", file=sys.stderr)
    r = subprocess.run([AURA], input=expr, text=True, env=env)
    return r.returncode


if __name__ == "__main__":
    raise SystemExit(main())
