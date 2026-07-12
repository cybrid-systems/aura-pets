# Aura Pets

> Terminal virtual pet for kids — feed, play, sleep, grow. Powered by [Aura](https://github.com/cybrid-systems/aura).

**Business logic: this repo. Rendering bugs: fix in aura.**  
Design: [docs/DESIGN.md](docs/DESIGN.md)

## Play (kids / parents)

```bash
# once: build Aura
cd /path/to/aura-grok && cmake -B build && cmake --build build --target aura -j

cd /path/to/aura-pets
./run.sh              # opens play if you have a real terminal
./run.sh play         # force interactive
```

| Key | What happens |
|-----|----------------|
| **1** | Eat (food↑, love↑) |
| **2** | Play (heart↑, love↑) |
| **3** | Sleep (zest↑, love↑) |
| **e** | Grow — only when love is high enough |
| **q** | Bye |

Pet never “dies” (vitals soft-floor at 1). Grow needs **love\*\*\*** plus happy + full tummy.

## Dev / CI

```bash
./run.sh --demo 8     # headless frames
./run.sh smoke        # short evolve smoke
```

## Layout

```
aura-pets/
├── docs/DESIGN.md           # product + iteration roadmap (R1–R5)
├── lib/
│   ├── pet-lifecycle.aura   # records, vitals, atomic-swap evolve
│   ├── pet-game.aura        # kids session: love, speech, soft rules
│   ├── pixel-cat.aura       # half-block cat art
│   └── tui-prompt.aura      # line editor (borrowed; → aura std later)
├── examples/
│   ├── cat-demo.aura        # R1 play scene
│   └── smoke.aura
└── run.sh
```

## Iterations

| Round | Status |
|-------|--------|
| **R1 Kids MVP** | playable care + love + speech + soft evolve |
| R2 Juice | action animations |
| R3 Chinese UI | needs aura UTF-8 cell |
| R4 Save soul | persist |
| R5 Teach phrase | light code mutation |

## License

See [LICENSE](LICENSE).
