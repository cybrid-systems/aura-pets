#!/bin/bash
# run.sh — aura-pets entry point.
#
# Default: 8 frames of cat-demo.aura with full 24-bit ANSI colors visible
# in your terminal. See --help for more modes.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AURA_HOME="${AURA_HOME:-/home/dev/code/aura}"
AURA_BIN="${AURA_BIN:-$AURA_HOME/build/aura}"
AURA_GROK_BIN="${AURA_GROK_BIN:-/home/dev/code/grok-dev/aura-grok/build/aura}"
AURA_STDLIB_DIR="${AURA_STDLIB_DIR:-$AURA_HOME/lib/std}"
export AURA_STDLIB_DIR

if [ -x "$AURA_BIN" ]; then
  AURA="$AURA_BIN"
elif [ -x "$AURA_GROK_BIN" ]; then
  AURA="$AURA_GROK_BIN"
else
  echo "FATAL: no aura binary. Build one:" >&2
  echo "  cd $AURA_HOME && cmake -B build && cmake --build build --target aura -j" >&2
  exit 1
fi

EXAMPLE="examples/cat-demo.aura"
FRAMES=8
ENTRY_FN="cat-demo-anim"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      cat <<USAGE
Usage:
  ./run.sh                  8 frames of cat demo (default)
  ./run.sh --frames N       N frames then exit (e.g. --frames 4)
  ./run.sh --loop           animate forever (Ctrl-C to stop)
  ./run.sh smoke            text-only smoke (no colors) for CI logs
  ./run.sh --example FILE   use a different example file
USAGE
      exit 0
      ;;
    --frames) FRAMES="$2"; shift 2 || shift ;;
    --loop) FRAMES=99999; shift ;;
    smoke) EXAMPLE="examples/smoke.aura"; ENTRY_FN="smoke-entry"; shift ;;
    --example) EXAMPLE="$2"; shift 2 || shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [ ! -f "$EXAMPLE" ]; then
  echo "FATAL: example not found: $EXAMPLE" >&2
  exit 1
fi

EXPR="(begin (load \"$SCRIPT_DIR/lib/pet-lifecycle.aura\") (load \"$EXAMPLE\") ($ENTRY_FN $FRAMES))"
echo "$EXPR" | "$AURA" 2>&1
