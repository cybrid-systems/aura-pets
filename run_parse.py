#!/usr/bin/env python3
"""Parse raw aura REPL output into a clean frame-by-frame view.

Reads from stdin or argv[1]. Strips ANSI escapes and re-collapses the
sparse (per-cell positioned) text into compact visual form for display.

Strategy: build a 2-D grid from the sparse characters and their CSI H
cursor positions, then render row-by-row.
"""

import re
import sys


def parse_ansi_grid(raw: str):
    """Convert raw ANSI text + sparse CSI H positions into a grid."""
    # Each cell write is roughly "ESC[1;1H<fg/bg><ch>ESC[1;2H<ch>..."
    # but the foreground-color SGRs interleaved make naive parsing hard.
    # Easiest: capture the most recently-printed non-ESC chars by stripping
    # all CSI sequences (CSI H included) and re-collapsing whitespace.
    text = re.sub(r'\x1b\][^\x07]*\x07', '', raw)              # OSC title
    text = re.sub(r'\x1b\[\?[0-9]+[lh]', '', text)            # mode
    text = re.sub(r'\x1b\[[0-9;]*[a-zA-Z]', '', text)          # CSI
    # Collapse repeated whitespace per line back to single space.
    lines = []
    for line in text.split('\n'):
        s = re.sub(r' {2,}', ' ', line)
        s = s.strip()
        if s:
            lines.append(s)
    return lines


def find_frames(raw: str):
    """Find FRAME N sections."""
    parts = re.split(r'=== (FRAME \d+\s*\([^)]+\)) ===', raw)
    frames = []
    for i in range(1, len(parts), 2):
        marker = parts[i].strip()
        body = parts[i + 1] if i + 1 < len(parts) else ''
        body = body.split('=== DONE')[0]
        frames.append((marker, body))
    return frames


def main() -> int:
    raw = sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()
    frames = find_frames(raw)

    if not frames:
        # Just print cleaned output
        for line in parse_ansi_grid(raw):
            print(line)
        return 0

    for marker, body in frames:
        print(f'\n=== {marker} ===')
        for line in parse_ansi_grid(body):
            print(line)

    # Look for DONE marker
    if '=== DONE ===' in raw:
        print('\n=== DONE ===')
    return 0


if __name__ == '__main__':
    sys.exit(main())
