#!/bin/bash
# run.sh — aura-pets (kids play + CI)

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
  echo "FATAL: no aura binary." >&2
  exit 1
fi

export AURA_STDLIB_DIR AURA_BIN
LIB_PARENT="$(cd "$(dirname "$AURA_STDLIB_DIR")" && pwd)"
export AURA_PATH="${LIB_PARENT}${AURA_PATH:+:$AURA_PATH}"

EXAMPLE="examples/cat-demo.aura"
FRAMES=10
MODE="auto"

# pet-log before scene so play-entry can plog-*
LOAD_CORE="(load \"$SCRIPT_DIR/lib/pet-lifecycle.aura\") (load \"$SCRIPT_DIR/lib/pet-edsl.aura\") (load \"$SCRIPT_DIR/lib/pet-anim.aura\") (load \"$SCRIPT_DIR/lib/pet-game.aura\") (load \"$SCRIPT_DIR/lib/pet-log.aura\") (load \"$SCRIPT_DIR/lib/world.aura\") (load \"$SCRIPT_DIR/lib/nl-cmd.aura\") (load \"$SCRIPT_DIR/lib/pixel-cat.aura\")"
LOG_FILE="${AURA_PETS_LOG:-/tmp/aura-pets-debug.log}"
export AURA_PETS_ROOT="$SCRIPT_DIR"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      cat <<USAGE
Aura Pets

  ./run.sh                 play on TTY, else demo
  ./run.sh play            interactive
  ./run.sh --demo [N]      headless frames
  ./run.sh smoke
  ./run.sh play --log FILE debug log path (default /tmp/aura-pets-debug.log)

Play: arrows move | 1 eat 2 play 3 sleep | e grow | g world | t talk | q bye
      type free English to direct the world (LLM):
        snowy park with penguin
        when feed say Pizza nom!
        teach feed Hi | brain | world | talk
World/NL: MiniMax-M3 (key: ~/code/keys/minimax) → eDSL + AST hot update

Debug: every play session writes $LOG_FILE
  tail -f /tmp/aura-pets-debug.log
USAGE
      exit 0
      ;;
    play|--interactive|--play) MODE="play"; shift ;;
    --log) LOG_FILE="$2"; shift 2 || shift ;;
    --demo)
      MODE="demo"
      if [ -n "${2:-}" ] && [ "${2#-}" = "$2" ]; then FRAMES="$2"; shift 2; else shift; fi
      ;;
    --frames) MODE="demo"; FRAMES="$2"; shift 2 || shift ;;
    --loop) MODE="demo"; FRAMES=99999; shift ;;
    smoke) EXAMPLE="examples/smoke.aura"; MODE="smoke"; shift ;;
    --example) EXAMPLE="$2"; shift 2 || shift ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

if [ "$MODE" = "auto" ]; then
  if [ -t 1 ] && [ -e /dev/tty ]; then MODE="play"; else MODE="demo"; fi
fi

export AURA_PETS_LOG="$LOG_FILE"

case "$MODE" in
  play)
    # plog-start! uses fixed default; override path before entry
    EXPR="(begin $LOAD_CORE (load \"$SCRIPT_DIR/$EXAMPLE\") (load \"$SCRIPT_DIR/lib/tui-prompt.aura\") (plog-set-path! \"$LOG_FILE\") (play-entry))"
    export AURA_TUI_LIVE=1
    ;;
  smoke)
    EXPR="(begin (load \"$SCRIPT_DIR/lib/pet-lifecycle.aura\") (load \"$SCRIPT_DIR/$EXAMPLE\") (smoke-entry))"
    ;;
  demo)
    EXPR="(begin $LOAD_CORE (load \"$SCRIPT_DIR/$EXAMPLE\") (load \"$SCRIPT_DIR/lib/tui-prompt.aura\") (cat-demo-anim $FRAMES))"
    ;;
esac

echo "aura=$AURA_BIN mode=$MODE" >&2
if [ "$MODE" = "play" ]; then
  echo "log=$LOG_FILE  (tail -f \$log after/during play)" >&2
  # Capture aura stderr to log as well (crashes / type errors)
  { echo "$EXPR" | "$AURA_BIN" 2>>"$LOG_FILE"; } 
  rc=$?
  echo "exit_code=$rc" >>"$LOG_FILE"
  echo "session ended rc=$rc  log=$LOG_FILE" >&2
  if [ -f "$LOG_FILE" ]; then
    echo "---- last log lines ----" >&2
    tail -n 25 "$LOG_FILE" >&2 || true
  fi
  exit "$rc"
else
  echo "$EXPR" | "$AURA_BIN" 2>&1
fi
