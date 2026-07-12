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
| **Love** | hearts / stars | love points from successful care |
| **Speech** | bubble under pet | last reaction string |
| **Evolve** | “sparkle” + new colors | version via atomic-swap when love+mood+hunger ready |
| **Idle** | slow walk + blink | frame anim; gentle tick |

No death. Low vitals → sad face + nudge text only.

## UX layout (R1)

```
 Mochi   happy   love***   v0
 food[====....] heart[======..] zest[====....]
 [1]eat  [2]play  [3]sleep  [e]grow  [q]bye
 ············· soft room + pixel cat ·············
        ( ^_^ )
 「 Yum! So good! 」
 > _
```

**Controls (no typing required)**

| Key | Action |
|-----|--------|
| `1` | Eat |
| `2` | Play |
| `3` | Sleep |
| `e` | Grow/evolve (only if ready; else soft refuse) |
| `q` | Bye (empty prompt) |
| optional | type `help` / emacs line edit (advanced) |

**Copy language (R1):** short English ASCII so multi-byte UTF-8 cell bugs in aura do not garble HUD.  
Chinese UI is **R3+**, after aura paints full codepoints per cell (engine work).

## Soft rules

1. Vitals never go below **1** (soft floor).  
2. Evolve only when `love >= 3` and mood/hunger high enough (or free evolve after parent `--cheat` later).  
3. Every care action → speech + log line + visible bar change within one frame.  
4. Idle tick every ~N frames, mild decay only above floor+1.

## Iteration roadmap

| Round | Goal | Exit criteria |
|-------|------|----------------|
| **R1 Kids MVP** (this ship) | One pet, 1/2/3 care, love, speech, soft evolve, playable interactive default | Child can feed/play/sleep without reading README; bars + bubble react |
| **R2 Juice** | Action anim (eat bounce, sleep zzz), sound-ish flash, better pixel frames | Each action has 3–6 frame reaction |
| **R3 Words** | Chinese HUD + bubble (needs aura UTF-8 cell or draw-text by codepoint) | CN mode flag |
| **R4 Memory** | Save/load soul (persist), next-day greeting | File round-trip |
| **R5 Magic** | Teach a phrase → behavior tweak (Aura mutate story) | One safe mutation path |

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
