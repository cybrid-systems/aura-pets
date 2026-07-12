#!/bin/bash
# run.sh — aura-pets entry point.
#
# Renders via Aura tui:* primitives (tui:init / tui:cell / tui:present /
# tui:frame-ansi) + lib/std/tui/{sprite,canvas,run}.aura — not hand ANSI.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Prefer aura-grok (has atomic-swap / persist / latest tui), then aura.
AURA_GROK_HOME="${AURA_GROK_HOME:-/home/dev/code/grok-dev/aura-grok}"
AURA_HOME="${AURA_HOME:-/home/dev/code/aura}"
AURA_BIN=""
AURA_STDLIB_DIR=""

if [ -x "$AURA_GROK_HOME/build/aura" ]; then
  AURA_BIN="$AURA_GROK_HOME/build/aura"
  AURA_STDLIB_DIR="$AURA_GROK_HOME/lib/std"
elif [ -x "$AURA_HOME/build/aura" ]; then
  AURA_BIN="$AURA_HOME/build/aura"
  AURA_STDLIB_DIR="$AURA_HOME/lib/std"
else
  echo "FATAL: no aura binary. Build one:" >&2
  echo "  cd $AURA_GROK_HOME && cmake -B build && ninja -C build aura" >&2
  exit 1
fi

export AURA_STDLIB_DIR
export AURA_BIN
# Runtime (require "std/...") resolves via AURA_PATH + "std/foo".
# stdlib root is .../lib/std → parent .../lib must be on AURA_PATH.
LIB_PARENT="$(cd "$(dirname "$AURA_STDLIB_DIR")" && pwd)"
export AURA_PATH="${LIB_PARENT}${AURA_PATH:+:$AURA_PATH}"

EXAMPLE="examples/cat-demo.aura"
FRAMES=8
ENTRY_FN="cat-demo-anim"
MODE="frames"   # frames | interactive | smoke

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      cat <<USAGE
Usage:
  ./run.sh                  8 frames of cat demo via Aura tui:frame-ansi
  ./run.sh --frames N       N frames then exit
  ./run.sh --loop           long headless anim (Ctrl-C to stop)
  ./run.sh --interactive    raw-mode keys: e=evolve, arrows, q=quit
  ./run.sh smoke            2-frame evolve smoke (TUI)
  ./run.sh --example FILE   use a different example file
USAGE
      exit 0
      ;;
    --frames) FRAMES="$2"; shift 2 || shift ;;
    --loop) FRAMES=99999; shift ;;
    --interactive) MODE="interactive"; shift ;;
    smoke) EXAMPLE="examples/smoke.aura"; ENTRY_FN="smoke-entry"; MODE="smoke"; shift ;;
    --example) EXAMPLE="$2"; shift 2 || shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [ ! -f "$EXAMPLE" ]; then
  echo "FATAL: example not found: $EXAMPLE" >&2
  exit 1
fi

case "$MODE" in
  interactive)
    EXPR="(begin (load \"$SCRIPT_DIR/lib/pet-lifecycle.aura\") (load \"$SCRIPT_DIR/$EXAMPLE\") (cat-demo-interactive))"
    ;;
  smoke)
    EXPR="(begin (load \"$SCRIPT_DIR/lib/pet-lifecycle.aura\") (load \"$SCRIPT_DIR/$EXAMPLE\") (smoke-entry))"
    ;;
  *)
    EXPR="(begin (load \"$SCRIPT_DIR/lib/pet-lifecycle.aura\") (load \"$SCRIPT_DIR/$EXAMPLE\") ($ENTRY_FN $FRAMES))"
    ;;
esac

echo "aura=$AURA_BIN" >&2
echo "stdlib=$AURA_STDLIB_DIR" >&2
echo "example=$EXAMPLE mode=$MODE" >&2
echo "$EXPR" | "$AURA_BIN" 2>&1
