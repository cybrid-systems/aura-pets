# Aura Pets

> Terminal pet for kids — **you move the cat**, feed/play/sleep with **animations**, and **teach** it new lines (eDSL mutation).

Design: [docs/DESIGN.md](docs/DESIGN.md) · Business here · Render bugs → **aura**

## Play

```bash
cd /path/to/aura-grok && cmake -B build && cmake --build build --target aura -j
cd /path/to/aura-pets
./run.sh play
```

| Input | Effect |
|-------|--------|
| **arrows / wasd** | Move Mochi |
| **1** | Eat + eat anim |
| **2** | Play + hop anim |
| **3** | Sleep + Zzz anim |
| **e** | Grow (needs love\*\*\* + happy + full) + sparkle |
| **q** | Bye |
| `teach feed Nom!` | **Change brain eDSL online** |
| `brain` | Show rules |

## Dev

```bash
./run.sh --demo 10    # scripted care + anim labels
./run.sh smoke
```

## eDSL + Aura mutation (short)

1. **Now:** rules in `lib/pet-edsl.aura`; `teach` rewrites them in memory (and tries `set-code` if available).  
2. **Next:** `mutate:set-body` / `safe-refactor:replace-fn` + `ast:snapshot` so the pet’s *source AST* evolves safely.  
3. **Evolve look:** already uses `atomic-swap` bindings.

See DESIGN.md §“eDSL online change”.

## Layout

```
lib/pet-lifecycle.aura   vitals + evolve (atomic-swap)
lib/pet-edsl.aura        behavior rules + teach + aura commit hook
lib/pet-anim.aura        action anim timeline
lib/pet-game.aura        session / commands
lib/pixel-cat.aura       poses: idle eat play sleep evolve
lib/tui-prompt.aura      line edit + nav when empty
examples/cat-demo.aura   play scene
```

## License

See [LICENSE](LICENSE).
