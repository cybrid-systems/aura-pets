# Agent notes — aura-pets

## Split of work

- **aura-pets**: game/business only (pets, care, love, speech, evolve rules, scenes, demos).
- **aura** (`~/code/grok-dev/aura-grok`): TUI/render/runtime (`tui:*`, input, CSI, pixels, stdlib tui).

Do **not** implement terminal protocols or permanent engine workarounds here.

Product design: `docs/DESIGN.md`. Current ship target: **R1 Kids MVP**.

## Run

```bash
./run.sh                 # play on TTY, else demo
./run.sh play            # interactive kids loop
./run.sh --demo 8        # headless frames
./run.sh smoke
```

`run.sh` prefers `AURA_GROK_HOME/build/aura` and sets `AURA_STDLIB_DIR` + `AURA_PATH`.

Load order: lifecycle → pet-game → pixel-cat → example (require sprite) → **tui-prompt last**.
