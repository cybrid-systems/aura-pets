#!/usr/bin/env python3
"""Natural-language → structured ops for aura-pets (MiniMax-M3).

Kids type free text in the TUI prompt. This tool turns it into apply lines
that lib/nl-cmd.aura executes: world/theme/npc, teach (eDSL), aura:commit.

Usage:
  python3 tools/nl_command.py --text "snowy park with a penguin" \\
      --out /tmp/aura-pets-nl.txt [--cols 80] [--rows 24]
  python3 tools/nl_command.py --text "when I feed say pizza" --offline

Key: ~/code/keys/minimax or ~/code/key/minimax or MINIMAX_API_KEY
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
            if "=" in line and not line.startswith("sk-"):
                line = line.split("=", 1)[1].strip().strip('"').strip("'")
            return line
    return None


SYSTEM = """You are the live director of a kids terminal pet game (Aura eDSL).
Convert the player's natural language into ONLY plain apply-lines (no markdown).

Allowed lines (emit only what is needed):
say:<short English reply for speech bubble, max 40 chars, kid-safe ASCII>
theme:<short English name>
sky:<r>,<g>,<b>
sky2:<r>,<g>,<b>
floor:<r>,<g>,<b>
floor2:<r>,<g>,<b>
star:<r>,<g>,<b>
npc_clear:
npc:<Name>|<x>|<y>|<friend|decor>|<speech max 28 ASCII>
prop_clear:
prop:<tree|flower|rock>|<x>|<y>
teach:<event>|<speech max 28 ASCII>
  event is feed|play|sleep|evolve|move|idle
care:<feed|play|sleep>
world_regen:
aura:commit
help:

Rules:
- Kid-safe. ASCII only in say/teach/npc speech/names.
- If they ask for new place/background/scene/world/NPCs/props/colors: emit theme + colors + npc_clear + 3-5 npc + prop_clear + 3-6 prop. x in [2,COLS-4], y in [4,ROWS-7].
- If they only want to change what the pet says for an action: emit teach: lines (+ aura:commit).
- If they want both world and teach: emit both.
- Prefer aura:commit after any teach: so Aura AST/hot path runs.
- If unclear: emit help: and a short say:
- Never invent other prefixes. No code fences.
"""


def call_minimax(key: str, text: str, cols: int, rows: int, context: str) -> str:
    url = f"{API_BASE.rstrip('/')}/chat/completions"
    user = (
        f"Terminal COLS={cols} ROWS={rows}.\n"
        f"Current game context:\n{context or '(none)'}\n\n"
        f"Player said:\n{text}\n"
    )
    body = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": user},
        ],
        "temperature": 0.7,
        "max_tokens": 900,
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
    content = re.sub(r"<think>[\s\S]*?</think>", "", content, flags=re.I)
    return content.strip()


def ascii_clip(s: str, n: int) -> str:
    s = re.sub(r"[^A-Za-z0-9 .!?,'\-\:]", "", s)
    return s[:n].strip()


def offline_ops(text: str, cols: int, rows: int) -> str:
    """Keyword heuristics when API is offline."""
    t = text.strip().lower()
    floor_y = max(8, rows - 6)
    lines: list[str] = []

    # teach patterns: "when feed say X" / "teach feed X" / "say X when eating"
    m = re.search(
        r"(?:teach\s+)?(?:when\s+)?(feed|eat|play|sleep|evolve|move|idle)\s+"
        r"(?:say\s+|says?\s+|to\s+)?[\"']?(.+?)[\"']?$",
        text.strip(),
        re.I,
    )
    if not m:
        m = re.search(
            r"(?:say|react)\s+[\"']?(.+?)[\"']?\s+when\s+(feed|eat|play|sleep)",
            text.strip(),
            re.I,
        )
        if m:
            speech, ev = m.group(1), m.group(2)
            if ev == "eat":
                ev = "feed"
            lines.append(f"say:Learned {ev}!")
            lines.append(f"teach:{ev}|{ascii_clip(speech, 28)}")
            lines.append("aura:commit")
            return "\n".join(lines) + "\n"

    if m:
        ev, speech = m.group(1).lower(), m.group(2)
        if ev == "eat":
            ev = "feed"
        lines.append(f"say:Learned {ev}!")
        lines.append(f"teach:{ev}|{ascii_clip(speech, 28)}")
        lines.append("aura:commit")
        return "\n".join(lines) + "\n"

    want_world = any(
        k in t
        for k in (
            "world",
            "scene",
            "background",
            "bg",
            "park",
            "forest",
            "beach",
            "snow",
            "night",
            "npc",
            "friend",
            "bunny",
            "tree",
            "make",
            "create",
            "generate",
            "change",
            "add",
        )
    )

    if want_world or len(t) > 8:
        snow = any(k in t for k in ("snow", "winter", "ice", "cold"))
        night = any(k in t for k in ("night", "dark", "star"))
        beach = any(k in t for k in ("beach", "ocean", "sea", "sand"))
        if snow:
            lines += [
                "say:Snow day! New friends!",
                "theme:Snowy Meadow",
                "sky:180,200,230",
                "sky2:210,225,245",
                "floor:230,240,250",
                "floor2:200,215,230",
                "star:255,255,255",
            ]
            names = [
                ("Penguin", "Waddle waddle!"),
                ("Seal", "Splash!"),
                ("Fox", "Snow fluff!"),
            ]
        elif beach:
            lines += [
                "say:Beach day!",
                "theme:Sunny Beach",
                "sky:100,180,255",
                "sky2:160,210,255",
                "floor:230,210,140",
                "floor2:200,180,110",
                "star:255,255,200",
            ]
            names = [
                ("Crab", "Click click!"),
                ("Gull", "Caw! Nice waves!"),
                ("Fish", "Blub blub!"),
            ]
        elif night:
            lines += [
                "say:Night park ready!",
                "theme:Starry Park",
                "sky:15,20,45",
                "sky2:25,30,70",
                "floor:30,50,40",
                "floor2:20,40,30",
                "star:240,245,255",
            ]
            names = [
                ("Owl", "Hoo hoo!"),
                ("Moth", "Soft glow!"),
                ("Cat", "Meow under stars!"),
            ]
        else:
            lines += [
                "say:New park ready!",
                "theme:Happy Park",
                "sky:30,50,90",
                "sky2:45,70,110",
                "floor:55,110,65",
                "floor2:40,90,50",
                "star:230,235,255",
            ]
            names = [
                ("Bunny", "Hi! Want to play?"),
                ("Bird", "Chirp! Nice day!"),
                ("Frog", "Ribbit~"),
            ]
        lines.append("npc_clear:")
        xs = [max(8, cols // 5), cols // 2, min(cols - 8, cols * 2 // 3)]
        ys = [floor_y - 3, floor_y - 2, max(4, rows // 5)]
        for i, (name, speech) in enumerate(names):
            lines.append(f"npc:{name}|{xs[i % 3]}|{ys[i % 3]}|friend|{speech}")
        lines.append("prop_clear:")
        lines.append(f"prop:tree|{cols // 3}|{floor_y - 1}")
        lines.append(f"prop:tree|{cols * 2 // 3}|{floor_y - 1}")
        lines.append(f"prop:flower|{cols // 4}|{floor_y}")
        lines.append(f"prop:flower|{cols // 2}|{floor_y}")
        lines.append("aura:commit")
        return "\n".join(lines) + "\n"

    if any(k in t for k in ("help", "?", "what", "how")):
        return "say:Type: snowy park / teach feed Pizza!\nhelp:\n"

    # Default: treat as teach for feed with the whole phrase (clipped)
    speech = ascii_clip(text, 28) or "Hi!"
    return f"say:I learned a feed line!\nteach:feed|{speech}\naura:commit\n"


def sanitize_ops(text: str, cols: int, rows: int) -> str:
    out: list[str] = []
    has_useful = False
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or line.startswith("```"):
            continue
        if line.startswith("say:"):
            out.append("say:" + ascii_clip(line[4:], 40))
            has_useful = True
            continue
        if line.startswith("theme:"):
            name = re.sub(r"[^A-Za-z0-9 \-']", "", line[6:])[:24] or "Park"
            out.append(f"theme:{name}")
            has_useful = True
            continue
        if re.match(r"^(sky|sky2|floor|floor2|star):\d+,\d+,\d+$", line):
            out.append(line)
            has_useful = True
            continue
        key = line.rstrip(":").lower()
        if key in ("npc_clear", "prop_clear", "help", "world_regen"):
            out.append(key + ":")
            has_useful = True
            continue
        if key == "aura:commit" or line.lower() in ("aura:commit", "aura:commit:"):
            out.append("aura:commit")
            has_useful = True
            continue
        m = re.match(
            r"^npc:([A-Za-z][A-Za-z0-9 ]{0,11})\|(\d+)\|(\d+)\|(friend|decor)\|(.{0,28})$",
            line,
        )
        if m:
            name, xs, ys, kind, speech = m.groups()
            x = max(2, min(cols - 4, int(xs)))
            y = max(4, min(rows - 7, int(ys)))
            out.append(
                f"npc:{name.strip()}|{x}|{y}|{kind}|{ascii_clip(speech, 28)}"
            )
            has_useful = True
            continue
        m = re.match(r"^prop:(tree|flower|rock)\|(\d+)\|(\d+)$", line)
        if m:
            kind, xs, ys = m.groups()
            x = max(2, min(cols - 3, int(xs)))
            y = max(5, min(rows - 5, int(ys)))
            out.append(f"prop:{kind}|{x}|{y}")
            has_useful = True
            continue
        m = re.match(
            r"^teach:(feed|play|sleep|evolve|move|idle)\|(.{1,28})$",
            line,
            re.I,
        )
        if m:
            ev, speech = m.group(1).lower(), ascii_clip(m.group(2), 28)
            out.append(f"teach:{ev}|{speech}")
            has_useful = True
            continue
        m = re.match(r"^care:(feed|play|sleep)$", line, re.I)
        if m:
            out.append(f"care:{m.group(1).lower()}")
            has_useful = True
            continue
    if not has_useful:
        return offline_ops("help", cols, rows)
    # auto aura commit if teach present without commit
    if any(x.startswith("teach:") for x in out) and "aura:commit" not in out:
        out.append("aura:commit")
    return "\n".join(out) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--text", required=True)
    ap.add_argument("--out", default="/tmp/aura-pets-nl.txt")
    ap.add_argument("--cols", type=int, default=80)
    ap.add_argument("--rows", type=int, default=24)
    ap.add_argument("--context", default="", help="optional game context string")
    ap.add_argument("--context-file", default="")
    ap.add_argument("--offline", action="store_true")
    args = ap.parse_args()

    cols = max(40, min(200, args.cols))
    rows = max(18, min(60, args.rows))
    text = args.text.strip()
    if not text:
        text = "help"

    ctx = args.context
    if args.context_file and Path(args.context_file).is_file():
        ctx = Path(args.context_file).read_text(encoding="utf-8", errors="replace")

    if args.offline:
        raw = offline_ops(text, cols, rows)
        src = "offline"
        ops = sanitize_ops(raw, cols, rows)
    else:
        key = load_api_key()
        if not key:
            print("nl_command: no API key, offline", file=sys.stderr)
            ops = sanitize_ops(offline_ops(text, cols, rows), cols, rows)
            src = "offline-no-key"
        else:
            try:
                raw = call_minimax(key, text, cols, rows, ctx)
                ops = sanitize_ops(raw, cols, rows)
                src = "minimax"
            except Exception as e:
                print(f"nl_command: API failed ({e}); offline", file=sys.stderr)
                ops = sanitize_ops(offline_ops(text, cols, rows), cols, rows)
                src = "offline-api-fail"

    Path(args.out).write_text(ops, encoding="utf-8")
    print(f"nl_command: wrote {args.out} source={src}", file=sys.stderr)
    # path only on stderr so Aura shell does not pollute the TUI
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
