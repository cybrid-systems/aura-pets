# Aura Pets — Kids Playable Design

> Terminal virtual pet for children (~5–10), powered by Aura TUI.  
> **Business lives in aura-pets. Render/input bugs are fixed in aura.**

## Vision

A tiny creature that needs care. Kids press big keys, see the pet react, and feel “it grew because of me.”  
Sessions are **2–5 minutes**. Failure is soft (never “dead forever”). Evolution is a small ceremony.

```
care → happier pet → love up → evolve unlock → new look → keep caring
```

## Player fantasy

| Role | Feel |
|------|------|
| Kid | “My cat. I feed it. It dances. It changes color.” |
| Parent | Safe, offline-first, no ads, runs in terminal with one command |

## Core systems (business)

| System | Kid sees | Data |
|--------|----------|------|
| **Care** | 1 feed / 2 play / 3 sleep | hunger, mood, energy 0–10 (floor 1) |
| **Move** | arrows / wasd | cat-x/y clamped to room |
| **Anim** | eat/play/sleep/evolve poses | anim-kind + phase (14–18 frames) |
| **Love** | hearts / stars | love points from successful care |
| **Speech** | bubble under pet | last reaction from **eDSL rules** |
| **Evolve** | sparkle + new colors | atomic-swap version when love+mood+hunger ready |
| **eDSL brain** | `teach feed Hi` / `brain` / free NL | rule list mutated online + AST commit |
| **Genome (Slice A)** | `/brain` `/diff` `/mutate` `/guide` | traits self-mutate; visible before→after |
| **Entity mutate** | `/npc` + NL `target:`/`set:`/`trait:` | query locate → patch data AST → diff |
| **NL director** | free English in prompt | MiniMax → ops → world/eDSL + set-code |

No death. Low vitals → sad face + nudge text only.

## UX layout (R2)

```
 Mochi   happy love*** v0 eat
 food[====....] heart[======..] zest[====....]
 arrows/wasd move  [1]eat [2]play [3]sleep [e]grow [q]bye
 ············· soft room + pixel cat (you steer) ·········
        ( O_O )     ← pose matches action anim
 " Yum yum! So good! "
 > teach feed Nom!_
```

**Controls**

| Key | Action |
|-----|--------|
| arrows / wasd | Move cat (when prompt empty) |
| `1` | Eat + eat anim |
| `2` | Play + hop anim |
| `3` | Sleep + Zzz anim |
| `e` | Grow when ready + sparkle anim |
| `q` | Bye |
| `teach feed Hi` | **Online eDSL mutation** of speech rule |
| `brain` | Dump current rule list |

**Copy language (R1):** short English ASCII so multi-byte UTF-8 cell bugs in aura do not garble HUD.  
Chinese UI is **R3+**, after aura paints full codepoints per cell (engine work).

## Soft rules

1. Vitals never go below **1** (soft floor).  
2. Evolve only when `love >= 3` and mood/hunger high enough (or free evolve after parent `--cheat` later).  
3. Every care action → speech + log line + visible bar change within one frame.  
4. Idle tick every ~N frames, mild decay only above floor+1.

## eDSL online change (Aura mutation story)

Pet reactions are not hard-coded forever. They live in an **eDSL rule table**:

```text
(event  speech                  love-delta)
 feed   "Yum yum! So good!"     1
 play   "Wheee! That was fun!"  1
 sleep  "Zzz... feeling cozy."  1
```

### Layer A — in-process AST-as-data (R2, shipping)

`lib/pet-edsl.aura` holds `*edsl-rules*`.  
`(edsl-teach! "feed" "Nom!")` **rewrites the rule list in place** — this is a structural edit of the pet’s behavior AST (data).  
Kids type: `teach feed Nom!` then feed with `1` to hear the new line.

### Layer B — Aura workspace mutation (engine, R5 full)

When we want the *runtime source* to change (persistable self-modifying pet):

```text
1. ast:snapshot "pet-brain"          ; rollback point
2. edsl-to-aura-source               ; rules → (define *edsl-rules* …)
3. set-code / mutate:set-body        ; patch workspace AST
4. typecheck-current                 ; gate
5. eval-current                      ; rebind
6. on fail → ast:restore
```

Helpers already in aura:

| Primitive / lib | Role |
|-----------------|------|
| `ast:snapshot` / `ast:restore` | versioned brain |
| `set-code` + `eval-current` | load new AST |
| `mutate:set-body` / `mutate:query-and-replace` | surgical edit |
| `safe-refactor:replace-fn` | snapshot + typecheck gate |
| `swap-binding!` / `sync-bindings!` (`atomic-swap`) | versioned sprite/behavior artifact (already used by `pet-evolve`) |

`edsl-aura-commit!` attempts a best-effort `set-code` append after teach; falls back to **local** rules if mutate path unavailable.

### Layer C — personality as code (later)

Ship a tiny `(define (react event) …)` in the workspace; teach becomes `mutate:set-body "react" new-body` so the pet’s *program* evolves — Aura’s killer loop for agents, used as a toy for kids.

## Entertainment loop: LLM × eDSL × AST (R2.6 plan)

Kids should *feel* the pet’s brain and world are alive code, not just chat text.

```text
  free CN/EN in prompt          slash /grow /fire
           │                            │
           ▼                            ▼
   nl_command.py (MiniMax)         pet-cmd.aura
           │                            │
           ▼                            ▼
   ops file (theme/npc/teach)    care / morph / battle
           │                            │
           └──────────┬─────────────────┘
                      ▼
              in-process hot data
         *edsl-rules*  *world-*  *combat-*
                      │
                      ▼
         ast:snapshot + side files  (safe)
         (no mid-session set-code — TUI closures)
```

### Fun hooks (shipping now)

| Hook | Kid experience | eDSL/AST angle |
|------|----------------|----------------|
| `/teach feed 好吃` | pet says new line | rewrite rule row (AST-as-data) |
| free text “下雪公园” | whole scene swap | world list rebind + snapshot |
| `/grow` `/back` | body morph stack | versioned sprite binding |
| tank `/fire` + NPC roam | arcade chaos | combat state + random props |

### Next entertainment upgrades (design, not all shipped)

1. **Mood eDSL** — rules like `(near-npc "Bunny" speech "Hi friend!")` evaluated each tick.  
2. **LLM → rule pack** — “make her sassy” expands to 3–5 teach ops + love-delta tweaks.  
3. **Stage scripts** — mini quests as data: `(quest find-crate reward grow)` hot-loaded.  
4. **Safe AST playground** — after session end, dump `*edsl-rules*` into a real `.aura` file and `ast:snapshot` history for “save my pet brain”.  
5. **NPC personalities as eDSL** — each friend has a tiny rule table; `/talk` samples it; fight triggers `(on-hit taunt)`.

Principle: **mutate data the TUI already draws** every frame. That *is* hot update. Full `mutate:set-body` waits for engine-safe mid-session rebind.

## Pure-Aura tool path (Python retired)

Worldgen + NL director are **Aura modules** that exercise language surface area:

| Layer | Aura primitives / libs |
|-------|------------------------|
| Key I/O | `getenv`, `read-file`, `file-exists?` |
| LLM HTTP | `http-post`, `json-encode`, `json-get-string` (`lib/llm-client.aura`) |
| Offline world | pure string builders (`lib/worldgen-engine.aura`) |
| NL ops | keyword heuristics + LLM (`lib/nl-engine.aura`) |
| Async | child `AURA_BIN` via `shell` + done-file (`lib/aura-jobs.aura`) |
| Apply | in-process `world-load!` / `edsl-teach!` (AST-as-data) |

Gaps closed by using / extending stdlib rather than Python:

- OpenAI-compatible chat body → `json-encode` + nested `hash`
- Auth → `http-post` third arg (`Bearer` added by runtime)
- Content extract → `json-get-string` on raw response
- Background work → Aura subprocess (same interpreter as the game)

`tools/*.py` are thin shims that shell to Aura for old muscle memory only.

## Iteration roadmap

| Round | Goal | Exit criteria |
|-------|------|----------------|
| **R1 Kids MVP** | 1/2/3 care, love, speech, soft evolve | playable without README |
| **R2 Move + anim + eDSL** (this) | player moves cat; eat/play/sleep/evolve poses; teach mutates rules | demo shows anim=eat/play/sleep/evolve; teach changes speech |
| **R2.5 NL director** | free English → MiniMax → ops → world/eDSL hot + `ast:snapshot` | type "snowy park"; feed speech changes after teach NL |
| **R3 Words** | Chinese HUD (needs aura UTF-8 cell) | CN mode |
| **R4 Memory** | persist soul + brain rules | round-trip file |
| **R5 Magic** | full `mutate:set-body` + safe-refactor on `react` (engine-safe mid-session) | verified snapshot/restore without TUI break |

## Repo ownership

| Concern | Repo |
|---------|------|
| Pet rules, love, speech, scenes, demos | **aura-pets** |
| `tui:cell` multi-char, UTF-8 glyphs, prompt stdlib | **aura** |
| Generic line editor long-term | aura `lib/std/tui/prompt` (today: borrowed `lib/tui-prompt.aura`) |

## Technical constraints (Aura)

- `(require …)` not nested stdlib `load` mid-file.  
- No top-level `(rgb …)` after require in loaded files.  
- Load `tui-prompt` **after** files that require sprite.  
- Interactive: `AURA_TUI_LIVE=1`, keys via `/dev/tty`.  
- Prefer `draw-text` for strings; precomputed bars to limit string churn.

## Success metrics (qualitative)

- Parent: `./run.sh` → pet on screen in &lt; 5s.  
- Kid: finds `1` and sees reaction without coaching twice.  
- Engineer: `./run.sh smoke` + `./run.sh --demo 6` green in CI.
