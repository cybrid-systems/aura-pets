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

Load order: lifecycle → edsl → anim → game → **pet-log** → pixel → example → **tui-prompt last**.

## Debug log (play exits)

Every `./run.sh play` writes:

```text
/tmp/aura-pets-debug.log          # or AURA_PETS_LOG / --log FILE
```

On exit, `run.sh` prints the last 25 lines. Look for:

| Tag | Meaning |
|-----|---------|
| `QUIT reason=...` | Why the loop stopped |
| `evt act=quit tag=quit` | Ctrl-C / tui quit event |
| `evt act=quit pay=q` | User pressed **q** |
| `hot cmd=... keep=0` | care command returned stop |
| `ERROR` | exception in play-step |

```bash
./run.sh play
# after unexpected exit:
tail -50 /tmp/aura-pets-debug.log
```
