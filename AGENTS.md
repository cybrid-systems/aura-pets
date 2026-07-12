# Agent notes — aura-pets

## Split of work

- **aura-pets**: game/business only (pets, care, evolve, scenes, demos, run.sh).
- **aura** (prefer `~/code/grok-dev/aura-grok`): TUI/render/runtime (`tui:*`, input, CSI, pixels, stdlib tui).

Do **not** implement terminal protocols or permanent engine workarounds here. Fix render/input bugs upstream in aura, then use the clean API from pets.

## Run

```bash
./run.sh --frames 6
./run.sh --interactive   # needs rebuilt aura with live TUI + /dev/tty input
./run.sh smoke
```

`run.sh` prefers `AURA_GROK_HOME/build/aura` and sets `AURA_STDLIB_DIR` + `AURA_PATH`.
