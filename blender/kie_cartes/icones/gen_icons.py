# Icônes de reliques en silhouette (planche 4×4 KIE), repassées en pixel art au style des icônes du jeu.
# python gen_icons.py  → sheet.png puis les icônes relic_*.png dans assets/ui
import os, subprocess, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
UI = os.path.join(HERE, "..", "..", "..", "assets", "ui")
K = r"C:\Users\Skill RTX\.claude\plugins\cache\nateherk\nateherk-design\0.2.0\skills\scroll-craft\scripts\kie.mjs"
ICONS = [
    ("relic_masque", "a half porcelain theater mask"),
    ("relic_tambour", "a small hand drum with two drumsticks"),
    ("relic_galet", "three smooth river pebbles stacked in a cairn"),
    ("relic_pierre", "a whetstone with a dagger blade resting on it"),
    ("relic_braise_eternelle", "a skull wreathed in a small flame"),
    ("relic_hamecon", "a large rusty fishing hook with a bit of rope"),
    ("relic_collier", "a spiked dog collar with a round tag"),
    ("relic_sifflet", "a bone whistle on a cord"),
    ("relic_bourse", "a coin purse tied with a string, a coin beside it"),
    ("relic_journal_route", "a travel journal with a strap and a feather bookmark"),
    ("comp_crabe", "a crab seen from above"),
    ("comp_harpie", "a harpy bird with spread wings"),
    ("comp_crapaud", "a fat toad with its tongue out"),
    ("comp_chaman", "a hooded shaman holding a small flame"),
    ("room_mystere", "a question mark carved in a stone tablet"),
    ("room_halte", "a campfire with crossed logs"),
]
out = os.path.join(HERE, "sheet.png")
if not os.path.exists(out):
    parts = ["Panel %d (row %d, column %d): %s." % (i + 1, i // 4 + 1, i % 4 + 1, d) for i, (_, d) in enumerate(ICONS)]
    prompt = ("A single square image divided into a 4x4 grid of sixteen separate icons, each centered in its own cell with generous white margin. "
              "Every icon is a simple solid pure black silhouette on a pure white background, bold readable shapes, game-icons.net style, "
              "no outlines, no gray, no text, no letters, no frames, no shadows. " + " ".join(parts))
    r = subprocess.run(["node", K, "still", prompt, out, "--ar", "1:1"], capture_output=True, text=True, cwd=r"G:\Mes APP\scrollcraft")
    print("planche", "ok" if os.path.exists(out) else r.stderr[-400:])
im = Image.open(out).convert("L")
W, H = im.size
OUT_D, HI = (58, 30, 18), (255, 248, 228)
for i, (name, _) in enumerate(ICONS):
    cx, cy = i % 4, i // 4
    cell = im.crop((cx * W // 4, cy * H // 4, (cx + 1) * W // 4, (cy + 1) * H // 4))
    m = cell.point(lambda v: 255 if v < 110 else 0)
    bb = m.getbbox()
    if not bb:
        print("vide", name)
        continue
    m = m.crop(bb)
    s = 26 / max(m.size)
    m = m.resize((max(1, int(m.size[0] * s)), max(1, int(m.size[1] * s))), Image.LANCZOS).point(lambda v: 255 if v > 110 else 0)
    g = Image.new("L", (32, 32), 0)
    g.paste(m, ((32 - m.size[0]) // 2, (32 - m.size[1]) // 2))
    px = g.load()
    icon = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    ip = icon.load()
    ys = [y for y in range(32) for x in range(32) if px[x, y]]
    y0, y1 = min(ys), max(ys)
    for y in range(32):
        for x in range(32):
            if px[x, y]:
                t = (y - y0) / max(1, y1 - y0)
                edge_hi = y > 0 and not px[x, y - 1]
                base = tuple(int(a + (b - a) * t) for a, b in zip((238, 212, 160), (200, 160, 98)))
                ip[x, y] = (HI if edge_hi else base) + (255,)
            elif any(0 <= x + dx < 32 and 0 <= y + dy < 32 and px[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                ip[x, y] = OUT_D + (255,)
    icon.resize((128, 128), Image.NEAREST).save(os.path.join(UI, name + ".png"))
    print(name)
