# Aura Pets

> Terminal pet — **life as evolving code**. Feed/play/sleep, **teach** speech rules, watch the genome **self-mutate** (`/brain` `/diff` `/mutate`).

Design: [docs/DESIGN.md](docs/DESIGN.md) · Business here · Render bugs → **aura**

## Play

```bash
cd /path/to/aura-grok && cmake -B build && cmake --build build --target aura -j
cd /path/to/aura-pets
./run.sh play              # new life
./run.sh play --continue   # restore ~/.aura-pets/saves/latest.aura
# optional: calmer FPS  AURA_PETS_FRAME_SLEEP=0.016 ./run.sh play
```

| Input | Effect |
|-------|--------|
| **arrows** | Move Mochi |
| **1** | Eat + eat anim |
| **2** | Play + hop anim |
| **3** | Sleep + Zzz anim |
| **Ctrl+D** (empty line) | Bye |
| **Ctrl+C** twice | Bye (second press within ~2s) |
| `/bg` | Scene recipe summary (palette + layers) |
| `/bg cyber` | Preset (stars/ocean/city/sunset/meadow/grid) |
| `/bg layers rain,16\|petals,2` | Custom sparse FX recipe |
| `/bg accent 255,100,160` | Highlight / rain / petal tint |
| `/bg rain 18` | Matrix-rain density (1–24) |
| `/tutorial` | **Interactive guide** — browse commands & how-to |
| `/tutorial care` | Jump topic: `basics` `care` `code` `fight` `world` `save` |
| `/n` `/b` | Next / previous guide page |
| `/tutorial try` | Optional soft walkthrough (never blocks play) |
| `/help` | Short command index (`/help care` → same as `/tut care`) |
| `/eat` `/play` `/sleep` | Care (also `1`/`2`/`3`) |
| `/grow` | Next form: Kitten→Pink→Tiger→Shadow→Dragon |
| `/back` | Previous form |
| `/form` `/status` | Morph name + HP/ATK |
| **Space** / `/fire` | Shoot in facing direction (tank mode) |
| **2× same arrow** | Dash 3 cells that way |
| `/weapon` [name] | Cycle/set: `shot` `double` `beam` `bomb` `fire` |
| `/fight` | Melee if close |
| `/heal` | Full HP (costs energy) |
| `/brain` | **Genome + speech rules** (living source) |
| `/diff` | Before → after last evolution |
| `/mutate` | Force one self-rewrite (toast + log) |
| `/guide lazy` | Steer traits (fierce/clingy/curious/…) |
| `/npc Bunny` | Query living NPC record |
| `/npc Bunny set hp 20` | Mutate field (also `trait fierce +2`, `ai hunter`) |
| `/npc @near …` | Patch nearest NPC |
| `/npc kind=enemy trait fierce +2` | **Batch** patch all enemies |
| `/save` | Save life → `~/.aura-pets/saves/latest.aura` (quit also auto-saves) |
| `/load` | Restore mind + NPCs (data AST; no `set-code`) |
| `/new` | New life (soft reset genome / edsl / love) |
| `/export` | Share/debug export under `~/.aura-pets/exports/` |
| free text | Guide / batch intent (`all enemies fiercer`) or **LLM director** |
| `/fight` near NPC | Shows **on-hit taunt** if set (`ability:taunt`) |

### Save / continue

| Action | Path |
|--------|------|
| Progress (machine) | `~/.aura-pets/saves/latest.aura` (`save-format:1`) |
| Share export | `~/.aura-pets/exports/session.aura` |
| Debug copy | `/tmp/aura-pets-session.aura` |

Default `./run.sh play` starts **new** with a short tip: type **`/tutorial`** for a friendly interactive guide (topics + `/n`/`/b` flip). Free play is always open — nothing is forced.

### Prompt (vi modes + Grok-style)

| Mode | Feel |
|------|------|
| **NORMAL** (default) | Prompt **hidden** — arrows move; **1 2 3** care; **Space** fire |
| **INSERT** | Prompt **box** — pure typing; arrows = cursor/history only |

| Key | Action |
|-----|--------|
| **Esc** | → NORMAL (hide prompt; keep draft buffer) |
| **i** / **a** | → INSERT (show prompt) |
| **:** | → INSERT with leading `/` (command-ready) |
| **Enter** | Submit command; **stay INSERT** (Esc → NORMAL) |
| **Tab** | Slash complete (`/br` → `/brain `); cycle matches |
| **← / →** (INSERT) | Move caret (never move pet) |
| **↑ / ↓** (INSERT) | Command history |
| **C-p / C-n** | History (INSERT) |
| **←↑↓→** (NORMAL) | Move pet |
| **1 2 3 / Space** (NORMAL only) | Care / fire |
| Status line | Live completion hints (`Tab → /brain`) |
| Ghost text | Dim suffix after cursor for unique match |

### Pure Aura LLM / worldgen (no Python required)

NL + world generation run as **Aura** modules:

| Module | Role |
|--------|------|
| `lib/llm-client.aura` | key load + `http-post` + `json-encode` / `json-get-string` |
| `lib/worldgen-engine.aura` | offline dense world + MiniMax worldgen |
| `lib/nl-engine.aura` | free-text → ops (offline heuristics or LLM) |
| `lib/aura-jobs.aura` | background `AURA_BIN` child (async, non-blocking TUI) |

`tools/*.py` remain only as legacy reference; `run.sh` no longer shells to them.

```bash
# offline world file
AURA_PETS_NL_OFFLINE=1 AURA_PETS_ROOT=$PWD \
  echo '(load "lib/llm-client.aura")(load "lib/worldgen-engine.aura")(worldgen-run! 80 24 "/tmp/aura-pets-world.txt" #t)' \
  | "$AURA_BIN"
```

### Tank battle

- Color HP bars on Mochi + above each NPC  
- Floating `-N` damage, flash, death `KO` then NPC disappears  
- NPCs shoot back automatically  
- Higher forms unlock stronger guns (`/grow` then `/weapon`)

| Form | HP | ATK | Unlocks |
|------|----|-----|---------|
| Kitten | 20 | 3 | shot |
| Pink Cat | 28 | 5 | double |
| Tiger | 36 | 7 | beam |
| Shadow | 44 | 9 | bomb |
| Dragon Cat | 55 | 12 | fire |

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
