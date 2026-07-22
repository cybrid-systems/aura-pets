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
# Pure-Aura stack: llm-client + engines replace tools/*.py for NL/worldgen.
# Load order matters: Aura's `(load ...)` is one-pass / lex-scoped — defines
# in earlier-loaded files are visible to later loads, but function bodies in
# earlier loads do NOT see defines added by later loads. world.aura must come
# before pet-combat.aura + pet-battle.aura (both reference *world-npcs* /
# *world-theme*). pet-lifecycle.aura owns the stdlib requires (atomic-swap +
# tui/canvas) so draw-text is bound globally before any consumer loads.
#
# tui-prompt MUST load before cat-demo / cyber-cat-stage: play-handle-event!
# and live-dispatch close over prompt-handle at load time. Loading prompt
# after the example left every key act=nil (events arrived, handler unbound).
# pet-genome after edsl; entity after world (query→patch→diff NPCs).
LOAD_CORE="(load \"$SCRIPT_DIR/lib/pet-lifecycle.aura\") (load \"$SCRIPT_DIR/lib/world.aura\") (load \"$SCRIPT_DIR/lib/entity.aura\") (load \"$SCRIPT_DIR/lib/pet-edsl.aura\") (load \"$SCRIPT_DIR/lib/pet-genome.aura\") (load \"$SCRIPT_DIR/lib/pet-anim.aura\") (load \"$SCRIPT_DIR/lib/pet-game.aura\") (load \"$SCRIPT_DIR/lib/pet-combat.aura\") (load \"$SCRIPT_DIR/lib/pet-battle.aura\") (load \"$SCRIPT_DIR/lib/pet-cmd.aura\") (load \"$SCRIPT_DIR/lib/pet-log.aura\") (load \"$SCRIPT_DIR/lib/llm-client.aura\") (load \"$SCRIPT_DIR/lib/worldgen-engine.aura\") (load \"$SCRIPT_DIR/lib/nl-engine.aura\") (load \"$SCRIPT_DIR/lib/aura-jobs.aura\") (load \"$SCRIPT_DIR/lib/nl-cmd.aura\") (load \"$SCRIPT_DIR/lib/pixel-cat.aura\") (load \"$SCRIPT_DIR/lib/tui-prompt.aura\")"
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
  ./run.sh --cyber [N]     3D cyber cat stage (headless frames)
  ./run.sh --cyber-orbit [N] 3D cyber cat stage orbit showcase (headless frames)
  ./run.sh --cyber-live     3D cyber cat stage (interactive, Grok prompt)
  ./run.sh smoke
  ./run.sh play --log FILE debug log path (default /tmp/aura-pets-debug.log)

Play: arrows move | 1 2 3 care | Ctrl+D quit | 2× Ctrl+C quit
  Living code (Slice A — see the pet evolve):
    /brain                genome + speech rules (the "source")
    /diff                 before → after last evolution
    /mutate               force one self-rewrite + toast
    /guide lazy|fierce…   player steers personality
    type: "be more clingy" / "more fierce" (no slash)
    /teach feed Hi        rewrite speech rule (logged as code edit)
    /npc Bunny            show living record (query)
    /npc Bunny set hp 20  patch field (mutate)
    /npc @near trait fierce +2
    /npc kind=enemy trait fierce +2   batch patch all enemies
    /npc kind=friend add hp 3
    /export               dump genome+NPCs → /tmp/aura-pets-session.aura
    type: "more fierce" / "all enemies fiercer" → offline intent patch
    fight: NPC on-hit taunt speech fires when set
  Slash commands (type /… then Enter):
    /eat /play /sleep     care
    /grow /back           morph forms (Kitten→…→Dragon)
    /fire  (or Space)     shoot in facing dir (tank mode)
    /weapon [name]        cycle/set: shot double beam bomb fire
    /fight                melee if close
    /heal /status /talk /world /help
    /bg cyber|stars|ocean|city|sunset|meadow|grid
  Free text (async LLM): "cyber rain" / "starry night" / "ocean beach"
  Double-tap same arrow = dash. NPCs shoot back. HP bars + dmg FX.
World/NL: pure Aura (llm-client + engines). Key: ~/code/keys/minimax

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
    --cyber)
      MODE="cyber"
      if [ -n "${2:-}" ] && [ "${2#-}" = "$2" ]; then FRAMES="$2"; shift 2; else shift; fi
      ;;
    --cyber-orbit)
      MODE="cyber-orbit"
      if [ -n "${2:-}" ] && [ "${2#-}" = "$2" ]; then FRAMES="$2"; shift 2; else shift; fi
      ;;
    --cyber-live)
      MODE="cyber-live"
      ;;
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
    # tui-prompt already in LOAD_CORE (before EXAMPLE).
    EXPR="(begin $LOAD_CORE (load \"$SCRIPT_DIR/$EXAMPLE\") (plog-set-path! \"$LOG_FILE\") (play-entry))"
    export AURA_TUI_LIVE=1
    ;;
  smoke)
    EXPR="(begin (load \"$SCRIPT_DIR/lib/pet-lifecycle.aura\") (load \"$SCRIPT_DIR/$EXAMPLE\") (smoke-entry))"
    ;;
  demo)
    EXPR="(begin $LOAD_CORE (load \"$SCRIPT_DIR/$EXAMPLE\") (cat-demo-anim $FRAMES))"
    ;;
  cyber)
    # 3D voxel scene — voxel-render + cyber-cat-scene + entry.
    EXAMPLE="examples/cyber-cat-stage.aura"
    LOAD_STAGE="(load \"$SCRIPT_DIR/lib/voxel-render.aura\") (load \"$SCRIPT_DIR/lib/cyber-cat-scene.aura\")"
    EXPR="(begin $LOAD_STAGE (load \"$SCRIPT_DIR/$EXAMPLE\") (cyber-cat-stage-anim $FRAMES))"
    ;;
  cyber-orbit)
    # 4-stop camera swing showcase (non-interactive orbit preview).
    EXAMPLE="examples/cyber-cat-stage.aura"
    LOAD_STAGE="(load \"$SCRIPT_DIR/lib/voxel-render.aura\") (load \"$SCRIPT_DIR/lib/cyber-cat-scene.aura\")"
    EXPR="(begin $LOAD_STAGE (load \"$SCRIPT_DIR/$EXAMPLE\") (cyber-cat-stage-orbit $FRAMES))"
    ;;
  cyber-live)
    # Interactive cyber cat stage — real event loop with the Grok Build–
    # style prompt (blinking block cursor, Ctrl+D-only quit).
    # tui-prompt before EXAMPLE so live-dispatch sees prompt-handle.
    EXAMPLE="examples/cyber-cat-stage.aura"
    LOAD_STAGE="(load \"$SCRIPT_DIR/lib/voxel-render.aura\") (load \"$SCRIPT_DIR/lib/cyber-cat-scene.aura\") (load \"$SCRIPT_DIR/lib/tui-prompt.aura\")"
    EXPR="(begin $LOAD_STAGE (load \"$SCRIPT_DIR/$EXAMPLE\") (cyber-cat-stage-live))"
    ;;
esac

# Aura eval_flat uses ~8KB C stack per call; named-let is not reliably TCO'd.
# Default shell stack (8MB) SIGSEGVs on deep loops / large loads. Raise limit.
ulimit -s 32768 2>/dev/null || ulimit -s unlimited 2>/dev/null || true

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
