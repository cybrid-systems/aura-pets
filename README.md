# Aura Pets

> **Aura-powered virtual pet.** Care for a pixel cat in the terminal — feed, play, sleep, evolve.

Built on [Aura](https://github.com/cybrid-systems/aura) TUI (`tui:*`, half-block `tui:pixel`) and `lib/std/atomic-swap`.

## Quick start

```bash
# Needs a built aura binary (aura-grok preferred):
cd /path/to/aura-grok && cmake -B build && cmake --build build --target aura -j

cd /path/to/aura-pets
./run.sh                  # 8-frame scripted care demo
./run.sh --frames 6
./run.sh smoke            # vitals + evolve smoke
./run.sh --interactive    # bottom prompt + hotkeys
```

`run.sh` sets `AURA_STDLIB_DIR` + `AURA_PATH`, then loads:

1. `lib/pet-lifecycle.aura` — pet record, vitals, care, evolve  
2. `lib/tui-prompt.aura` — Grok Build–style bottom input line  
3. `lib/pixel-cat.aura` — half-block room + cat  
4. `examples/cat-demo.aura` — scene loop  

## Interactive controls

| Input | Action |
|-------|--------|
| `1` / `feed` | Feed (hunger↑) |
| `2` / `play` | Play (mood↑ energy↓) |
| `3` / `sleep` | Sleep (energy↑) |
| `e` / `evolve` | Evolve form |
| `help` | Command list |
| type + Enter | Run command |
| `q` (empty line) | Quit |

Layout:

```
aura-pets  mochi v0 happy f=12
H[=======...] M[========..] E[======....]
············ night room + pixel cat ··········
(o.o)
hi!  1=feed  2=play  3=sleep  e=evolve  type help
> feed_
```

## Stage map

| Stage | Status |
|-------|--------|
| 0.8 Aura TUI stack | done |
| **0.9 care + prompt + half-block cat** | **this** |
| 1.0 richer pixel art / animations | next |
| 1.1 dialogue + soft fail states | next |
| 1.2 soul persist (save/load) | later |

## Ownership (hard split)

| Layer | Repo | Owns |
|-------|------|------|
| **Business / game** | **aura-pets** | pet lifecycle, vitals, care, evolution, scenes, dialogue, saves, demos |
| **Render / TUI / runtime** | **aura** (`aura-grok`) | `tui:*`, termios/raw input, CSI keys, half-block pixels, truecolor, `lib/std/tui/*`, engine string/load bugs that break TUI |

**Rule:** “猫饿了 / 喂食 / 进化” → aura-pets. “Delete 变空格 / 没光标 / present 不画 / 按键读不到” → **aura**. Game code may call Aura APIs; do not reimplement terminal protocols or keep permanent engine workarounds here.

| Path | Belongs? |
|------|----------|
| `lib/pet-lifecycle.aura`, care loop, demos | aura-pets ✓ |
| `lib/pixel-cat.aura` (game art on `tui:pixel`) | aura-pets ✓ |
| `lib/tui-prompt.aura` (generic line editor) | **borrowed** → graduate to `lib/std/tui/prompt` in aura |
| Mac DEL / live present / `/dev/tty` / CSI | aura ✓ |

## Aura load notes

1. Prefer `(require "std/...")` over nested stdlib `(load)`.  
2. Do not call imported procs at **top-level init** inside a loaded file (e.g. `(define C (rgb …))`) — use literals or call inside procedures.  
3. `tui:cell` first-codepoint-only is an **aura** surface quirk; use `draw-text` until multi-char cell is fixed upstream.

## License

See [LICENSE](LICENSE).
