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

Load order: lifecycle → edsl → **genome** → anim → game → **pet-log** → pixel → **tui-prompt** → example.
(`tui-prompt` before example: `play-handle-event!` binds `prompt-handle` at load time.)
(`genome` after edsl: speech AST + trait evolution for Slice A.)

## Debug log (play exits)

Every `./run.sh play` writes:

```text
/tmp/aura-pets-debug.log          # or AURA_PETS_LOG / --log FILE
```

On exit, `run.sh` prints the last 25 lines. Look for:

| Tag | Meaning |
|-----|---------|
| `QUIT reason=...` | Why the loop stopped |
| `evt act=quit tag=quit` | Ctrl+C (needs 2× to exit; first arms) |
| `stop double-ctrl-c` | Second Ctrl+C within window |
| `evt act=quit` + key pay | Ctrl+D on empty prompt |
| `hot cmd=... keep=0` | care command returned stop |
| `ERROR` | exception in play-step |

```bash
./run.sh play
# after unexpected exit:
tail -50 /tmp/aura-pets-debug.log
```

**Known crash (fixed in cde2913):** Scheme `(let iter () … (iter))` main loop
overflowed `eval_flat` stack after ~800 frames → SIGSEGV. Play must use
host `(while pred body)` (C++ for-loop) instead of recursive named-let.
