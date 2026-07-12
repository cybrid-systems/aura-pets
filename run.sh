#!/bin/bash
# run.sh — aura-pets entry (kids product + CI demos).
#
# Business: lib/pet-*.aura + examples/*
# Render: Aura tui:* + lib/std/tui/*  (engine bugs → fix in aura)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

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
  echo "  cd $AURA_GROK_HOME && cmake -B build && cmake --build build --target aura -j" >&2
  exit 1
fi

export AURA_STDLIB_DIR
export AURA_BIN
LIB_PARENT="$(cd "$(dirname "$AURA_STDLIB_DIR")" && pwd)"
export AURA_PATH="${LIB_PARENT}${AURA_PATH:+:$AURA_PATH}"

EXAMPLE="examples/cat-demo.aura"
FRAMES=8
MODE="auto"   # auto | play | demo | smoke

# lifecycle + game + pixel, then example (require sprite), then prompt last
LOAD_CORE="(load \"$SCRIPT_DIR/lib/pet-lifecycle.aura\") (load \"$SCRIPT_DIR/lib/pet-game.aura\") (load \"$SCRIPT_DIR/lib/pixel-cat.aura\")"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      cat <<USAGE
Aura Pets — terminal pet for kids

Usage:
  ./run.sh                 play (interactive if TTY, else short demo)
  ./run.sh play            force interactive play
  ./run.sh --demo [N]      headless N frames (default 8) for CI / gifs
  ./run.sh --frames N      same as --demo N
  ./run.sh smoke           vitals + evolve smoke
  ./run.sh --interactive   alias for play

Keys in play:  1 eat  2 play  3 sleep  e grow  q bye
USAGE
      exit 0
      ;;
    play|--interactive|--play) MODE="play"; shift ;;
    --demo)
      MODE="demo"
      if [ -n "${2:-}" ] && [ "${2#-}" = "$2" ]; then FRAMES="$2"; shift 2; else shift; fi
      ;;
    --frames) MODE="demo"; FRAMES="$2"; shift 2 || shift ;;
    --loop) MODE="demo"; FRAMES=99999; shift ;;
    smoke) EXAMPLE="examples/smoke.aura"; MODE="smoke"; shift ;;
    --example) EXAMPLE="$2"; shift 2 || shift ;;
    *) echo "Unknown arg: $1 (try --help)" >&2; exit 1 ;;
  esac
done

if [ "$MODE" = "auto" ]; then
  if [ -t 1 ] && [ -e /dev/tty ]; then
    MODE="play"
  else
    MODE="demo"
  fi
fi

if [ ! -f "$EXAMPLE" ]; then
  echo "FATAL: example not found: $EXAMPLE" >&2
  exit 1
fi

case "$MODE" in
  play)
    EXPR="(begin $LOAD_CORE (load \"$SCRIPT_DIR/$EXAMPLE\") (load \"$SCRIPT_DIR/lib/tui-prompt.aura\") (play-entry))"
    export AURA_TUI_LIVE=1
    ;;
  smoke)
    EXPR="(begin (load \"$SCRIPT_DIR/lib/pet-lifecycle.aura\") (load \"$SCRIPT_DIR/$EXAMPLE\") (smoke-entry))"
    ;;
  demo)
    EXPR="(begin $LOAD_CORE (load \"$SCRIPT_DIR/$EXAMPLE\") (load \"$SCRIPT_DIR/lib/tui-prompt.aura\") (cat-demo-anim $FRAMES))"
    ;;
esac

echo "aura=$AURA_BIN" >&2
echo "stdlib=$AURA_STDLIB_DIR" >&2
echo "example=$EXAMPLE mode=$MODE" >&2

if [ "$MODE" = "play" ]; then
  if [ ! -e /dev/tty ]; then
    echo "FATAL: play mode needs a real terminal (/dev/tty)" >&2
    exit 1
  fi
  echo "$EXPR" | "$AURA_BIN"
else
  echo "$EXPR" | "$AURA_BIN" 2>&1
fi
