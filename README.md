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
| **arrows** | Move Mochi |
| **1** | Eat + eat anim |
| **2** | Play + hop anim |
| **3** | Sleep + Zzz anim |
| type `e` + Enter | Grow (not a steal-hotkey — letters type normally) |
| type `world` / `talk` | Regen world / talk NPC |
| **q** (empty line) | Bye |
| free text in `>` | **LLM director** (EN + 中文), async |
| `teach feed Nom!` | Classic eDSL teach (no LLM) |
| `brain` | Show rules |

> Empty-line hotkeys are only **1/2/3** (care) and **q**.  
> **e / g / t** are normal letters so you can type English and Chinese without fights.

### Natural language director (eDSL + AST hot update)

Type English in the bottom prompt and press Enter:

```text
> snowy park with a penguin
> when feed say Pizza nom!
> make a night beach and teach play Splash!
```

Pipeline (async — cat keeps moving while LLM thinks):

1. Enter free text → background `python3 tools/nl_command.py … &`  
2. Play loop polls `/tmp/aura-pets-nl.done` each frame; arrows still work  
3. On done: apply ops → `*edsl-rules*` / `*world-*` hot rewrite  
4. `ast:snapshot` + side files for Aura version points  
5. NPCs bob / wiggle / wander every few frames  

> Note: mid-session `set-code` is intentionally avoided; replacing the workspace flat invalidates loaded TUI closures. Snapshot + in-process eDSL is the safe hot path.

### World + NPCs (full regen)

On play start (and on **g**), `tools/worldgen.py` invents a full park scene.

```bash
# API key: ~/code/keys/minimax  or  ~/code/key/minimax  or MINIMAX_API_KEY
python3 tools/worldgen.py --out /tmp/aura-pets-world.txt --cols 80 --rows 24
python3 tools/nl_command.py --text "snowy park" --offline
```

API failure → offline keyword heuristics automatically.

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
lib/world.aura           bg + NPC load/draw + AST commit
lib/nl-cmd.aura          free-text → ops apply + hot update
lib/pixel-cat.aura       poses: idle eat play sleep evolve
lib/tui-prompt.aura      line edit + nav when empty
tools/worldgen.py        MiniMax-M3 full world file
tools/nl_command.py      MiniMax-M3 NL → structured ops
examples/cat-demo.aura   play scene
```

## License

See [LICENSE](LICENSE).
