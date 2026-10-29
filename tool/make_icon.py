"""SpendSplit icon: the split bar as a square module on the construction grid.
Usage: python3 make_icon.py <out_dir>"""
import sys
from PIL import Image, ImageDraw

S = 4  # supersample
N = 1024 * S
GROUND = (0x10, 0x11, 0x13, 255)
GRID = (0x2A, 0x2C, 0x31, 255)
ORANGE = (0xFF, 0x5A, 0x1F, 255)
BONE = (0xE8, 0xE4, 0xDC, 255)

def module(draw, x0, y0, side):
    # Same geometry as the dashboard split bar, scaled: slant ~10/44 of the
    # height, gap ~3/44, Available share 60%.
    slant, gap = side * 0.23, side * 0.05
    x = x0 + side * 0.58
    draw.polygon([(x0, y0), (x + slant / 2, y0), (x - slant / 2, y0 + side), (x0, y0 + side)], fill=ORANGE)
    draw.polygon([(x + slant / 2 + gap, y0), (x0 + side, y0), (x0 + side, y0 + side), (x - slant / 2 + gap, y0 + side)], fill=BONE)

def render(with_ground, side_frac):
    img = Image.new("RGBA", (N, N), GROUND if with_ground else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if with_ground:
        cell = N // 16
        for i in range(1, 16):
            w = 2 * S
            d.rectangle([i * cell - w // 2, 0, i * cell + w // 2, N], fill=GRID)
            d.rectangle([0, i * cell - w // 2, N, i * cell + w // 2], fill=GRID)
    side = N * side_frac
    o = (N - side) / 2
    module(d, o, o, side)
    return img.resize((1024, 1024), Image.LANCZOS)

out = sys.argv[1]
render(True, 0.5).convert("RGB").save(f"{out}/app-icon.png")
# Android adaptive foreground: content inside the 66/108 safe zone.
render(False, 0.34).save(f"{out}/app-icon-foreground.png")
