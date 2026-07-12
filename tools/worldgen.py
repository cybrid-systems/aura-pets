#!/usr/bin/env python3
"""DEPRECATED shim — worldgen is pure Aura now.

Prefer:
  echo '(load "lib/llm-client.aura")(load "lib/worldgen-engine.aura")
        (worldgen-run! 80 24 "/tmp/aura-pets-world.txt" #f)' | $AURA_BIN

This script only shells out to Aura for compatibility.
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
    ap = argparse.ArgumentParser(description="Deprecated: use Aura worldgen-engine")
    ap.add_argument("--out", default="/tmp/aura-pets-world.txt")
    ap.add_argument("--cols", type=int, default=80)
    ap.add_argument("--rows", type=int, default=24)
    ap.add_argument("--offline", action="store_true")
    args = ap.parse_args()
    env = os.environ.copy()
    env["AURA_PETS_ROOT"] = str(ROOT)
    env.setdefault("AURA_STDLIB_DIR", "/home/dev/code/grok-dev/aura-grok/lib/std")
    env.setdefault("AURA_PATH", "/home/dev/code/grok-dev/aura-grok/lib")
    if args.offline:
        env["AURA_PETS_NL_OFFLINE"] = "1"
    expr = (
        f'(begin (load "{ROOT}/lib/llm-client.aura") '
        f'(load "{ROOT}/lib/worldgen-engine.aura") '
        f'(worldgen-run! {args.cols} {args.rows} "{args.out}" '
        f'{"#t" if args.offline else "#f"}))'
    )
    print(f"worldgen.py: delegating to Aura ({AURA})", file=sys.stderr)
    r = subprocess.run([AURA], input=expr, text=True, env=env)
    return r.returncode


if __name__ == "__main__":
    raise SystemExit(main())
