#!/bin/bash
# run.sh — aura-pets entry point
#
# Sets up AURA_STDLIB_DIR to point at the aura stdlib (where hot-update /
# atomic-swap / persist live), then loads lib/pet-lifecycle.aura and
# invokes the requested example.

set -e

# ── Paths ─────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AURA_HOME="${AURA_HOME:-/home/dev/code/aura}"
AURA_BIN="${AURA_BIN:-$AURA_HOME/build/aura}"
AURA_GROK_BIN="${AURA_GROK_BIN:-/home/dev/code/grok-dev/aura-grok/build/aura}"
AURA_STDLIB_DIR="${AURA_STDLIB_DIR:-$AURA_HOME/lib/std}"
export AURA_STDLIB_DIR

# Pick the first working aura binary; prefer grok-dev's if aura main not built.
if [ -x "$AURA_BIN" ]; then
  AURA="$AURA_BIN"
elif [ -x "$AURA_GROK_BIN" ]; then
  AURA="$AURA_GROK_BIN"
else
  echo "FATAL: no aura binary. Build it first:" >&2
  echo "  cd $AURA_HOME && cmake -B build && cmake --build build --target aura -j" >&2
  echo "OR build aura-grok:" >&2
  echo "  cd $(dirname $AURA_GROK_BIN) && cmake --build build --target aura -j" >&2
  exit 1
fi

# ── Args ──────────────────────────────────────────────────────────────────
EXAMPLE="${1:-examples/smoke.aura}"
shift || true

if [ ! -f "$EXAMPLE" ]; then
  echo "FATAL: example file not found: $EXAMPLE" >&2
  exit 1
fi

# ── Run ───────────────────────────────────────────────────────────────────
# Aura is a REPL on stdin. We compose: (load pet-lifecycle) (load example)
# plus any extra args. If extra args, last expression is the example's "main".
EXPR=$(cat <<EOF
(begin
  (load "$SCRIPT_DIR/lib/pet-lifecycle.aura")
  (load "$EXAMPLE"))
EOF
)

# If extra args, run them as final expression
if [ $# -gt 0 ]; then
  EXPR="$EXPR $@"
fi

echo "$EXPR" | "$AURA"