#!/bin/bash
# run.sh — aura-pets entry point.
#
# Sets AURA_STDLIB_DIR, loads pet-lifecycle + chosen example, then calls
# <entry-fn> explicitly. Avoids an Aura REPL quirk where top-level
# (define) + (call-of-fn-with-colon-in-name) silently no-ops.

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
  echo "FATAL: no aura binary found" >&2
  exit 1
fi

EXAMPLE="${1:-examples/smoke.aura}"
ENTRY_FN="${2:-smoke-entry}"
shift 2 || shift || true

if [ ! -f "$EXAMPLE" ]; then
  echo "FATAL: example not found: $EXAMPLE" >&2
  exit 1
fi

EXPR="(begin (load \"$SCRIPT_DIR/lib/pet-lifecycle.aura\") (load \"$EXAMPLE\") ($ENTRY_FN))"
if [ $# -gt 0 ]; then
  EXPR="$EXPR $*"
fi

RAW_OUTPUT=$(echo "$EXPR" | "$AURA" 2>&1 || true)

python3 /home/dev/code/aura-pets/run_parse.py "$RAW_OUTPUT"