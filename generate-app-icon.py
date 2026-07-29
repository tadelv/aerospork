#!/usr/bin/env python3
"""
Generate the aerospork app icon.

Design intent: the mark is the *layout*, not a letter. A tiling window manager's whole idea is one
focused pane beside a stack of others, so that is the glyph — one large tile left, three stacked
right, on a deep gradient squircle.

Two constraints drove the shape:
  * It has to read at 16pt in the Finder sidebar, where anything thinner than ~1.5px disappears.
    Hence few, large shapes and generous gaps rather than a fine grid — the previous icon drew a
    3x3 line grid, which turned to mush below 32pt.
  * macOS icons are squircles with a specific corner ratio (~22%) and are NOT full-bleed: Apple's
    grid insets the artwork. Getting either wrong is most of what makes an icon look homemade.
"""

import json
import os
from PIL import Image, ImageDraw

# Rendered at 4x then downsampled: PIL has no anti-aliased rounded-rectangle, so supersampling is
# what keeps corners clean at small sizes.
SUPERSAMPLE = 4

BASE_SIZES = [16, 32, 128, 256, 512]

BG_TOP = (28, 32, 44)
BG_BOTTOM = (16, 18, 26)
FOCUSED = (94, 158, 255)   # the active pane — system-blue family
DIMMED = (78, 86, 106)     # unfocused panes, deliberately low contrast


def _vertical_gradient(size, top, bottom):
    grad = Image.new("RGB", (1, size), top)
    px = grad.load()
    for y in range(size):
        t = y / max(size - 1, 1)
        px[0, y] = tuple(round(a + (b - a) * t) for a, b in zip(top, bottom))
    return grad.resize((size, size))


def _squircle_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([(0, 0), (size - 1, size - 1)], radius=radius, fill=255)
    return mask


def create_icon(size):
    s = size * SUPERSAMPLE
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))

    inset = round(s * 0.055)
    box = s - 2 * inset
    radius = round(box * 0.225)

    plate = _vertical_gradient(box, BG_TOP, BG_BOTTOM).convert("RGBA")
    plate.putalpha(_squircle_mask(box, radius))
    img.paste(plate, (inset, inset), plate)

    draw = ImageDraw.Draw(img)

    # Tiles get their own padding so they never crowd the squircle's corners.
    pad = round(box * 0.20)
    gap = round(box * 0.062)
    tile_r = max(round(box * 0.045), 1)

    left, top = inset + pad, inset + pad
    right, bottom = inset + box - pad, inset + box - pad
    split = left + round((right - left - gap) * 0.56)

    # Focused pane: full height, left.
    draw.rounded_rectangle([(left, top), (split, bottom)], radius=tile_r, fill=FOCUSED)

    # Three stacked panes on the right.
    col_left = split + gap
    h = ((bottom - top) - 2 * gap) / 3
    for i in range(3):
        y0 = round(top + i * (h + gap))
        draw.rounded_rectangle([(col_left, y0), (right, round(y0 + h))], radius=tile_r, fill=DIMMED)

    return img.resize((size, size), Image.LANCZOS)


def main():
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "resources", "Assets.xcassets", "AppIcon.appiconset")
    os.makedirs(out, exist_ok=True)

    for f in os.listdir(out):
        if f.endswith(".png"):
            os.remove(os.path.join(out, f))

    images = []
    for base in BASE_SIZES:
        for scale in (1, 2):
            px = base * scale
            name = f"icon_{base}x{base}{'@2x' if scale == 2 else ''}.png"
            create_icon(px).save(os.path.join(out, name))
            images.append({
                "size": f"{base}x{base}",
                "idiom": "mac",
                "filename": name,
                "scale": f"{scale}x",
            })

    create_icon(1024).save(os.path.join(out, "icon.png"))

    with open(os.path.join(out, "Contents.json"), "w") as f:
        json.dump({"images": images, "info": {"version": 1, "author": "xcode"}}, f, indent=2)

    print(f"wrote {len(images)} icon files to {out}")


if __name__ == "__main__":
    main()
