from PIL import Image, ImageDraw
import math

SIZE = 1024

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

def vertical_gradient(w, h, top, bottom):
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        t = y / (h - 1)
        c = lerp(top, bottom, t)
        for x in range(w):
            px[x, y] = c
    return img

def rounded_mask(w, h, radius):
    m = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=radius, fill=255)
    return m

# Couleurs : chocolat -> ambre
COCOA_DARK = (43, 26, 18)     # #2B1A12
COCOA = (95, 62, 41)          # #5F3E29
AMBER = (255, 193, 7)         # #FFC107 (comme les favoris)
CREAM = (255, 248, 240)

def play_triangle(draw, cx, cy, r, color):
    # Triangle "play" centré, pointe vers la droite.
    pts = [
        (cx - r * 0.55, cy - r * 0.72),
        (cx - r * 0.55, cy + r * 0.72),
        (cx + r * 0.78, cy),
    ]
    draw.polygon(pts, fill=color)

def build_full():
    """Icône pleine (1024) pour iOS et fallback Android."""
    base = vertical_gradient(SIZE, SIZE, COCOA, COCOA_DARK)
    draw = ImageDraw.Draw(base, "RGBA")
    cx = cy = SIZE / 2

    # Cercle ambre derrière le play
    R = SIZE * 0.30
    draw.ellipse([cx - R, cy - R, cx + R, cy + R], fill=AMBER)
    # Play crème
    play_triangle(draw, cx + SIZE * 0.012, cy, SIZE * 0.20, CREAM)

    # Coins arrondis
    mask = rounded_mask(SIZE, SIZE, int(SIZE * 0.22))
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(base, (0, 0), mask)
    out.save("assets/icon/icon.png")

def build_foreground():
    """Avant-plan transparent pour icône adaptative Android (zone sûre centrale)."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    cx = cy = SIZE / 2
    # Plus petit pour respecter la zone sûre (~66%)
    R = SIZE * 0.22
    draw.ellipse([cx - R, cy - R, cx + R, cy + R], fill=AMBER)
    play_triangle(draw, cx + SIZE * 0.009, cy, SIZE * 0.15, CREAM)
    img.save("assets/icon/foreground.png")

import os
os.makedirs("assets/icon", exist_ok=True)
build_full()
build_foreground()
print("Logos générés : assets/icon/icon.png + foreground.png")
