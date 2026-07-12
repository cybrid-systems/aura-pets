#!/usr/bin/env python3
"""Generate aura-pets world (bg + NPCs) via MiniMax-M3 OpenAI-compatible API.

Usage:
  python3 tools/worldgen.py --out /tmp/aura-pets-world.txt [--cols 80] [--rows 24]
  python3 tools/worldgen.py --offline   # no API, fixed cute defaults

Key file (first non-empty non-# line):
  ~/code/keys/minimax   or  ~/code/key/minimax
  or env MINIMAX_API_KEY / OPENAI_API_KEY
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

# api.minimax.io often rejects coding keys (401); international key works on
# api.minimaxi.com and api.minimax.chat. Override with MINIMAX_BASE_URL if needed.
API_BASE = os.environ.get("MINIMAX_BASE_URL", "https://api.minimaxi.com/v1")
MODEL = os.environ.get("MINIMAX_MODEL", "MiniMax-M3")

KEY_CANDIDATES = [
    Path(os.path.expanduser("~/code/keys/minimax")),
    Path(os.path.expanduser("~/code/key/minimax")),
    Path(os.environ.get("MINIMAX_KEY_FILE", "")),
]


def load_api_key() -> str | None:
    env = os.environ.get("MINIMAX_API_KEY") or os.environ.get("OPENAI_API_KEY")
    if env and env.strip():
        return env.strip()
    for p in KEY_CANDIDATES:
        if not p or not str(p) or not p.is_file():
            continue
        for line in p.read_text(encoding="utf-8", errors="replace").splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            # allow KEY=sk-... or bare sk-...
            if "=" in line and not line.startswith("sk-"):
                line = line.split("=", 1)[1].strip().strip('"').strip("'")
            return line
    return None


def offline_world(cols: int, rows: int) -> str:
    """Cute default park scene — no network."""
    floor_y = max(8, rows - 6)
    return "\n".join(
        [
            "theme:Sunset Meadow",
            "sky:30,50,90",
            "sky2:45,70,110",
            "floor:55,110,65",
            "floor2:40,90,50",
            "star:230,235,255",
            f"npc:Bunny|{max(8, cols // 5)}|{floor_y - 3}|friend|Hi! Want to play?",
            f"npc:Bird|{min(cols - 8, cols * 2 // 3)}|{max(4, rows // 5)}|friend|Chirp! Nice day!",
            f"npc:Frog|{min(cols - 10, cols // 2)}|{floor_y - 2}|friend|Ribbit~",
            f"prop:tree|{cols // 3}|{floor_y - 1}",
            f"prop:tree|{cols * 2 // 3}|{floor_y - 1}",
            f"prop:flower|{cols // 4}|{floor_y}",
            f"prop:flower|{cols // 2 + 3}|{floor_y}",
            f"prop:flower|{cols * 3 // 4}|{floor_y}",
            "",
        ]
    )


SYSTEM = """You design cute kid-safe virtual pet game worlds for a terminal pixel game.
Reply with ONLY plain text lines in this exact format (no markdown, no fences):
theme:<short English name>
sky:<r>,<g>,<b>
sky2:<r>,<g>,<b>
floor:<r>,<g>,<b>
floor2:<r>,<g>,<b>
star:<r>,<g>,<b>
npc:<Name>|<x>|<y>|<kind>|<short speech>
prop:<kind>|<x>|<y>

Rules:
- 3 to 5 npc lines. kind is friend or decor.
- Name and speech ASCII only, speech max 28 chars, kid-friendly, no violence.
- 3 to 6 prop lines. kind is tree or flower or rock.
- x in [2, COLS-4], y in [4, ROWS-7]. Keep NPCs above the floor band.
- Colors are 0-255 RGB integers for a soft pleasant palette.
- Do not invent other line types.
"""


def call_minimax(key: str, cols: int, rows: int) -> str:
    url = f"{API_BASE.rstrip('/')}/chat/completions"
    user = (
        f"Terminal size COLS={cols} ROWS={rows}. "
        "Create a cheerful park or backyard world with friendly animal NPCs."
    )
    body = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": user},
        ],
        "temperature": 0.9,
        "max_tokens": 800,
        # MiniMax-M3: skip long thinking for faster worldgen
        "thinking": {"type": "disabled"},
    }
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=90) as resp:
        payload = json.loads(resp.read().decode("utf-8"))
    content = payload["choices"][0]["message"]["content"]
    if not isinstance(content, str):
        content = str(content)
    # Strip optional think tags if model still emits them
    content = re.sub(r"<think>[\s\S]*?</think>", "", content, flags=re.I)
    return content.strip()


def sanitize_world(text: str, cols: int, rows: int) -> str:
    """Keep only valid lines; clamp coords; ensure minima."""
    lines_out: list[str] = []
    npcs = 0
    props = 0
    has_theme = False
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("```"):
            continue
        if line.startswith("theme:"):
            name = re.sub(r"[^A-Za-z0-9 \-']", "", line[6:])[:24] or "Meadow"
            lines_out.append(f"theme:{name}")
            has_theme = True
            continue
        if re.match(r"^(sky|sky2|floor|floor2|star):\d+,\d+,\d+$", line):
            lines_out.append(line)
            continue
        m = re.match(
            r"^npc:([A-Za-z][A-Za-z0-9 ]{0,11})\|(\d+)\|(\d+)\|(friend|decor)\|(.{0,28})$",
            line,
        )
        if m:
            name, xs, ys, kind, speech = m.groups()
            x = max(2, min(cols - 4, int(xs)))
            y = max(4, min(rows - 7, int(ys)))
            speech = re.sub(r"[^A-Za-z0-9 .!?,'\-]", "", speech)[:28]
            lines_out.append(f"npc:{name.strip()}|{x}|{y}|{kind}|{speech}")
            npcs += 1
            continue
        m = re.match(r"^prop:(tree|flower|rock)\|(\d+)\|(\d+)$", line)
        if m:
            kind, xs, ys = m.groups()
            x = max(2, min(cols - 3, int(xs)))
            y = max(5, min(rows - 5, int(ys)))
            lines_out.append(f"prop:{kind}|{x}|{y}")
            props += 1
            continue
    if not has_theme:
        lines_out.insert(0, "theme:Sunny Park")
    if npcs == 0 or props == 0:
        return offline_world(cols, rows)
    # ensure bg colors exist
    keys = {ln.split(":", 1)[0] for ln in lines_out}
    defaults = {
        "sky": "sky:30,50,90",
        "sky2": "sky2:45,70,110",
        "floor": "floor:55,110,65",
        "floor2": "floor2:40,90,50",
        "star": "star:230,235,255",
    }
    for k, v in defaults.items():
        if k not in keys:
            lines_out.insert(1, v)
    return "\n".join(lines_out) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="/tmp/aura-pets-world.txt")
    ap.add_argument("--cols", type=int, default=80)
    ap.add_argument("--rows", type=int, default=24)
    ap.add_argument("--offline", action="store_true")
    args = ap.parse_args()

    cols = max(40, min(200, args.cols))
    rows = max(18, min(60, args.rows))

    text: str
    if args.offline:
        text = offline_world(cols, rows)
        src = "offline"
    else:
        key = load_api_key()
        if not key:
            print("worldgen: no API key, using offline world", file=sys.stderr)
            text = offline_world(cols, rows)
            src = "offline-no-key"
        else:
            try:
                raw = call_minimax(key, cols, rows)
                text = sanitize_world(raw, cols, rows)
                src = "minimax"
            except Exception as e:
                print(f"worldgen: API failed ({e}); offline fallback", file=sys.stderr)
                text = offline_world(cols, rows)
                src = "offline-api-fail"

    Path(args.out).write_text(text, encoding="utf-8")
    print(f"worldgen: wrote {args.out} source={src}", file=sys.stderr)
    print(args.out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
