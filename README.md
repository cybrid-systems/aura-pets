# Aura Pets

> **Aura-powered virtual pet game.** Pets evolve their own behaviors and personalities through self-mutating Aura code.

A playful experimental project exploring how [Aura](https://github.com/cybrid-systems/aura) — the AI-native Lisp programming language with auto-mutating ASTs — can create living, adaptive virtual pets.

## ✨ What Makes It Special

- **Self-evolving pets**: Pet logic, responses, and "personalities" are written in Aura and can **mutate** over time based on player interaction.
- **Classic pet养成 with a twist**: Feed, play, train, and care for your pet — then watch it genuinely surprise you as its code evolves.
- **Showcase of Aura's capabilities**: Demonstrates dynamic code modification, reflection, incremental compilation, and agent-like behavior in an interactive terminal-based game context.
- **All-terminal pixel art** — no web, no GUI, just Aura + TUI. Same aesthetic as `examples/cyber_cat.aura` from the Aura repo, evolved.
- Part of the **cybrid-systems** ecosystem.

## Planned Features

- Multiple pet species with different base traits
- Visual evolution (appearance + behavior changes via `lib/std/atomic-swap`)
- Training & interaction systems that trigger code mutations
- Persistent saves with evolution history ("pet soul" versioning via `lib/std/persist`)
- All-terminal pixel UI
- Optional AI co-pilot that helps evolve pets

## Getting Started

### 1. Build Aura from source (one-time)

```bash
cd /path/to/aura
cmake -B build && cmake --build build --target aura -j
```

If you have a parallel aura checkout under `~/code/grok-dev/aura-grok`, `run.sh` will prefer that one automatically.

### 2. Run the Stage-0 smoke test

```bash
cd /path/to/aura-pets
./run.sh                                # runs examples/smoke.aura
./run.sh examples/smoke.aura             # explicit
./run.sh examples/cat.aura "(cat-demo)" # pass extra args as the entry expression
```

`run.sh` sets `AURA_STDLIB_DIR` to your Aura repo's `lib/std/` so that
`pet-lifecycle.aura` can `(load)` the generic primitives (`atomic-swap`,
`hot-update`, `persist`) from there.

### 3. Verify it works

You should see:
```
INIT version=0
INIT species=cat
INIT sprite-id=cat-idle
INIT history-len=1
EVOLVED version=1
EVOLVED sprite-id=cat-v1
EVOLVED history-len=2
SYNC=ok
DONE
```

## Project Structure

```
aura-pets/
├── lib/
│   └── pet-lifecycle.aura     ; pet:make / pet:evolve! / pet:history / :health / :save-soul
├── examples/
│   └── smoke.aura             ; CI smoke test (Stage 0)
├── assets/                    ; sprites, animations
├── run.sh                     ; entry point: sets AURA_STDLIB_DIR + runs aura
├── LICENSE
└── README.md
```

## How Pets Evolve

Each pet's core behavior is expressed as Aura code. Using Aura's generic
primitives (now in `lib/std/`):

- **AOT hot-reload** (`aot:reload` + `lib/std/hot-update` #1366 / #1370) — swap
  behavior at runtime, per-evaluator region isolated (#1367), stale-closure-safe
  via `bridge_epoch` (#1365).
- **Atomic resource swap** (`lib/std/atomic-swap` #1380) — bind a behavior
  version to its sprite ID, so behavior + visual evolve together at the
  render-cycle boundary.
- **Persistent souls** (`serialize-workspace` + `lib/std/persist` #1381) — save
  the entire evaluator + AOT module state to a binary `.aura-soul` file.
  Format `AURASOUL\x01 v1`.
- **Incremental type check** (`incremental_infer` #148) + **post-mutation
  invariant** (`typed_mutate` #147) — pets can't evolve into a broken state.

This repo owns the **vocabulary layer** (`pet:make` / `pet:evolve!` / etc.).
Aura's stdlib owns the **mechanism layer** (`swap-binding!` / `sync-bindings!` /
`persist:save`). Each project composes its own vocab over generic mechanism.

## Current Status

🚧 **Stage 0 bootstrap** (Summer 2026 experimental project)

Done:
- Repo skeleton
- `lib/pet-lifecycle.aura` shell with pet:make / pet:evolve! / pet:render-sync!
- `examples/smoke.aura` smoke test that prints version / species / sprite /
  history
- `run.sh` wrapper

Roadmap (development rhythm):
- **Stage 1** — full pet-lifecycle stdlib (hot-reload wiring + persist + tests)
- **Stage 2** — `examples/cat.aura` interactive demo (cyber_cat template +
  pet system)
- **Stage 3** — persistence (save-menu + autosave)
- **Stage 4** — multi-pet + sub-region
- **Stage 5** — polish + more species

## Contributing

This is currently a personal/experimental project. Feedback, ideas, and contributions are very welcome once it opens up!

## License

Apache-2.0 License (same as Aura)

---

**Built with glowing particles and a lot of curiosity.**
