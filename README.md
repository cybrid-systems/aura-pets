# Aura Pets

> **Aura-powered virtual pet game.** Pets evolve their own behaviors and personalities through self-mutating Aura code.

A playful experimental project exploring how [Aura](https://github.com/cybrid-systems/aura) — the AI-native Lisp programming language with auto-mutating ASTs — can create living, adaptive virtual pets.

## What Makes It Special

- **Self-evolving pets**: Pet logic and "personalities" are Aura code that can mutate over time.
- **Aura TUI rendering**: Pixel art via Aura's `tui:*` primitives + `lib/std/tui/{sprite,canvas}` — not hand-rolled ANSI.
- **atomic-swap evolution**: Versioned bindings via `lib/std/atomic-swap` wrapped as pet vocabulary in this repo.
- Part of the **cybrid-systems** ecosystem.

## Getting Started

### 1. Build Aura

```bash
# Prefer aura-grok (latest tui / atomic-swap), or stock aura:
cd /path/to/aura-grok   # or aura
cmake -B build && cmake --build build --target aura -j
```

`run.sh` prefers `$AURA_GROK_HOME/build/aura` (default `~/code/grok-dev/aura-grok`), then `$AURA_HOME/build/aura`.

### 2. Run demos

```bash
cd /path/to/aura-pets
./run.sh                  # 8 frames of cat demo (Aura tui:frame-ansi)
./run.sh --frames 4       # N frames then exit
./run.sh smoke            # 2-frame evolve smoke (TUI)
./run.sh --interactive    # raw-mode keys: e=evolve, q=quit
```

`run.sh` sets:

- `AURA_STDLIB_DIR` → Aura's `lib/std`
- `AURA_PATH` → Aura's `lib` (so `(require "std/...")` resolves)

then evaluates:

```scheme
(load "lib/pet-lifecycle.aura")
(load "examples/cat-demo.aura")   ; or smoke.aura
(cat-demo-anim N)                 ; or smoke-entry / cat-demo-interactive
```

### 3. What you should see

Cat frames with HUD (`aura-pets cat v0 …`) and a walking pixel cat (`/\_/\`, `( o.o )`, `> ^ <`). At frame 4 the pet auto-evolves to v1 (sprite eyes change). Smoke prints two frames (v0 → v1) then `=== DONE ===`.

## Project Structure

```
aura-pets/
├── lib/
│   └── pet-lifecycle.aura   ; pet-make / pet-evolve / pet-render-sync
├── examples/
│   ├── cat-demo.aura        ; Stage 0.8 TUI cat (tui:* + sprite/canvas)
│   └── smoke.aura           ; short evolve + TUI smoke
├── assets/
├── run.sh
├── LICENSE
└── README.md
```

## Rendering stack

| Layer | What |
|-------|------|
| Host | `tui:init` / `tui:cell` / `tui:present` / `tui:frame-ansi` |
| Stdlib | `(require "std/tui/sprite" all:)` — `draw-sprite`, `draw-anim`, `CAT-IDLE-*` |
| Stdlib | `(require "std/tui/canvas" all:)` — `rgb`, `NEON-PINK`, `MATRIX-GREEN`, … |
| Pets | `pet-make` / `pet-evolve` / `pet-render-sync` (wraps `atomic-swap`) |

**Do not** hand-build `\x1b[` escape strings for the main surface — use `tui:frame-ansi` (headless) or `tui:present` (live).

### Aura `load` gotchas

1. Prefer `(require "std/...")` over nested `(load …/lib/std/…)` inside example files — nested load can clobber the workspace AST mid-file.
2. After `require` inside a **loaded** file, do **not** call imported procedures at top-level init (e.g. `(define C (rgb 0 220 255))`). That aborts the load and drops later `define`s plus require exports. Use palette constants (`NEON-PINK`, …) or literal RGB ints; call `rgb` only inside procedure bodies.

## How Pets Evolve

```scheme
(define mochi (pet-make "mochi" "cat" "/tmp/brain" "cat-idle"))
(define mochi-v1 (pet-evolve mochi "/tmp/brain-v2" "feed"))
(pet-render-sync)   ; drain atomic-swap before tui:present
```

Pet records are plain lists (id, species, version, region-mask, behavior-path, sprite-id, history, binding). Evolution bumps version, updates the binding via `swap-binding!` / `sync-bindings!`, and appends history.

## License

See [LICENSE](LICENSE).
