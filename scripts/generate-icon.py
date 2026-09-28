#!/usr/bin/env python3
"""Renders the NotchMate app icon and writes every size macOS needs.

Usage: python3 scripts/generate-icon.py   (requires Pillow and numpy)

The icon is a macOS-style squircle with a colourful "wallpaper" and a black
notch that has grown into NotchMate's expanded panel, holding three dots.
"""
import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONSET = os.path.join(ROOT, "NotchMate", "Assets.xcassets", "AppIcon.appiconset")
DOCS = os.path.join(ROOT, "docs")
SS = 4  # supersampling factor
S = 1024 * SS


def superellipse_mask(size, box, n=5.0):
    x0, y0, x1, y1 = box
    ys, xs = np.mgrid[0:size, 0:size].astype(np.float64) + 0.5
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    rx, ry = (x1 - x0) / 2, (y1 - y0) / 2
    v = np.abs((xs - cx) / rx) ** n + np.abs((ys - cy) / ry) ** n
    return Image.fromarray(((v <= 1.0) * 255).astype(np.uint8), "L")


def gradient(size, stops, angle_deg):
    ys, xs = np.mgrid[0:size, 0:size].astype(np.float64) / size
    a = np.radians(angle_deg)
    t = (xs * np.cos(a) + ys * np.sin(a))
    t = (t - t.min()) / (t.max() - t.min())
    out = np.zeros((size, size, 3))
    positions = [p for p, _ in stops]
    colors = [np.array(c, dtype=np.float64) for _, c in stops]
    for i in range(len(stops) - 1):
        p0, p1 = positions[i], positions[i + 1]
        m = (t >= p0) & (t <= p1)
        f = ((t - p0) / (p1 - p0))[m][:, None]
        out[m] = colors[i] * (1 - f) + colors[i + 1] * f
    return Image.fromarray(out.astype(np.uint8), "RGB")


def notch_polygon(cx, top, width, height, ear, bottom, steps=48):
    """Same silhouette as NotchShape.swift: concave shoulders, rounded bottom."""
    left, right = cx - width / 2, cx + width / 2
    pts = []

    def quad(p0, c, p1):
        for i in range(steps + 1):
            t = i / steps
            x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t ** 2 * p1[0]
            y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t ** 2 * p1[1]
            pts.append((x, y))

    quad((left, top), (left + ear, top), (left + ear, top + ear))
    quad((left + ear, top + height - bottom), (left + ear, top + height), (left + ear + bottom, top + height))
    quad((right - ear - bottom, top + height), (right - ear, top + height), (right - ear, top + height - bottom))
    quad((right - ear, top + ear), (right - ear, top), (right, top))
    return pts


def render():
    u = SS  # 1 design unit = 1px at 1024
    body = (100 * u, 100 * u, 924 * u, 924 * u)
    mask = superellipse_mask(S, body)

    wallpaper = gradient(S, [(0.0, (88, 86, 240)), (0.5, (176, 82, 222)), (1.0, (255, 128, 110))], 55)
    # Soft highlight in the lower-left for depth.
    glow = Image.new("L", (S, S), 0)
    ImageDraw.Draw(glow).ellipse((60 * u, 520 * u, 700 * u, 1160 * u), fill=110)
    glow = glow.filter(ImageFilter.GaussianBlur(120 * u))
    wallpaper = Image.composite(Image.new("RGB", (S, S), (255, 214, 170)), wallpaper, glow)

    art = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    art.paste(wallpaper, (0, 0), mask)

    # Expanded notch panel hanging from the top edge, with a soft shadow.
    panel = notch_polygon(512 * u, 100 * u - 1, 560 * u, 290 * u, 40 * u, 105 * u)
    shadow = Image.new("L", (S, S), 0)
    ImageDraw.Draw(shadow).polygon([(x, y + 22 * u) for x, y in panel], fill=150)
    shadow = shadow.filter(ImageFilter.GaussianBlur(28 * u))
    shadow = Image.fromarray(np.minimum(np.array(shadow), np.array(mask)))
    art = Image.alpha_composite(art, Image.merge("RGBA", (*[Image.new("L", (S, S), 0)] * 3, shadow)))

    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(layer).polygon(panel, fill=(10, 10, 14, 255))
    layer.putalpha(Image.fromarray(np.minimum(np.array(layer.split()[3]), np.array(mask))))
    art = Image.alpha_composite(art, layer)

    # Three dots: NotchMate's "activity" motif.
    dots = ImageDraw.Draw(art)
    r = 38 * u
    for i, color in enumerate([(255, 255, 255), (255, 170, 205), (150, 200, 255)]):
        cx = (512 + (i - 1) * 112) * u
        cy = 248 * u
        dots.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color + (255,))

    # Subtle inner edge highlight like Apple's icon template.
    edge = mask.filter(ImageFilter.GaussianBlur(3 * u))
    inner = superellipse_mask(S, (104 * u, 104 * u, 920 * u, 920 * u))
    rim = Image.fromarray(np.clip(np.array(edge, dtype=np.int16) - np.array(inner, dtype=np.int16), 0, 255).astype(np.uint8) // 3)
    art = Image.alpha_composite(art, Image.merge("RGBA", (*[Image.new("L", (S, S), 255)] * 3, rim)))

    # Drop shadow under the whole tile.
    tile_shadow = mask.filter(ImageFilter.GaussianBlur(14 * u)).point(lambda v: v * 0.45)
    base = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    offset = Image.new("L", (S, S), 0)
    offset.paste(tile_shadow, (0, 12 * u))
    base = Image.merge("RGBA", (*[Image.new("L", (S, S), 0)] * 3, offset))
    return Image.alpha_composite(base, art).resize((1024, 1024), Image.LANCZOS)


def main():
    master = render()
    os.makedirs(ICONSET, exist_ok=True)
    images = []
    for points in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            px = points * scale
            name = f"icon_{points}x{points}{'@2x' if scale == 2 else ''}.png"
            master.resize((px, px), Image.LANCZOS).save(os.path.join(ICONSET, name), optimize=True)
            images.append({"filename": name, "idiom": "mac", "scale": f"{scale}x", "size": f"{points}x{points}"})
    with open(os.path.join(ICONSET, "Contents.json"), "w") as f:
        json.dump({"images": images, "info": {"author": "xcode", "version": 1}}, f, indent=2)
        f.write("\n")
    os.makedirs(DOCS, exist_ok=True)
    master.resize((256, 256), Image.LANCZOS).save(os.path.join(DOCS, "icon.png"), optimize=True)
    print("wrote", len(images), "icon images")


if __name__ == "__main__":
    main()
