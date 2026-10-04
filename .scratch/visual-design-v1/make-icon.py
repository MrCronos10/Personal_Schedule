#!/usr/bin/env python3
"""Draws the app icon: 读 in a red 田字格. Run from the repo root; writes into AppIcon.appiconset.

The glyph is Noto Serif SC Black, not a hand-drawn brush stroke: it is the heaviest serif the app
already bundles. Swap in a real brush-written 读 by replacing the two PNGs; nothing else changes.
"""
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
FONT = "PersonalSchedule/Fonts/NotoSerifSC-Black.otf"
OUT = "PersonalSchedule/Assets.xcassets/AppIcon.appiconset"

def hexc(h):
    return ((h >> 16) & 255, (h >> 8) & 255, h & 255)

def draw(path, background, ink, grid):
    img = Image.new("RGB", (SIZE, SIZE), hexc(background))
    d = ImageDraw.Draw(img)
    inset, stroke = 96, 22
    box = (inset, inset, SIZE - inset, SIZE - inset)
    mid = SIZE // 2
    dash = 30
    faint = tuple(int(c * 0.45 + b * 0.55) for c, b in zip(hexc(grid), hexc(background)))
    for pos in range(inset, SIZE - inset, dash * 2):
        d.line([(pos, mid), (min(pos + dash, SIZE - inset), mid)], fill=faint, width=8)
        d.line([(mid, pos), (mid, min(pos + dash, SIZE - inset))], fill=faint, width=8)
    d.rectangle(box, outline=hexc(grid), width=stroke)
    font = ImageFont.truetype(FONT, 600)
    left, top, right, bottom = d.textbbox((0, 0), "读", font=font)
    x = mid - (left + right) / 2
    y = mid - (top + bottom) / 2
    d.text((x, y), "读", font=font, fill=hexc(ink))
    img.save(path)

draw(f"{OUT}/AppIcon.png", 0xFAF6EC, 0x1C1A17, 0xC8382E)
draw(f"{OUT}/AppIcon-Dark.png", 0x1C1A17, 0xE8DEC5, 0xC8382E)
