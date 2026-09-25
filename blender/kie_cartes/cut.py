# Découpe les planches en illustrations (les gouttières noires séparent les vignettes).
# python cut.py [planches_lp 4]   (dossier, côté de la grille ; par défaut les planches 3×3 peintes)
import json, os, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "..", "assets", "art")
UI = os.path.join(HERE, "..", "..", "assets", "ui")
DIR = sys.argv[1] if len(sys.argv) > 1 else "planches"
N = int(sys.argv[2]) if len(sys.argv) > 2 else 3
batches = json.load(open(os.path.join(HERE, DIR, "batches.json")))


def segments(profile, n):
    segs, start = [], None
    for i, dark in enumerate(profile + [True]):
        if not dark and start is None:
            start = i
        elif dark and start is not None:
            segs.append((start, i))
            start = None
    segs.sort(key=lambda s: s[1] - s[0], reverse=True)
    return sorted(segs[:n])


for k, b in enumerate(batches):
    p = os.path.join(HERE, DIR, "sheet_%02d.png" % k)
    if not os.path.exists(p):
        print("planche manquante", k)
        continue
    im = Image.open(p).convert("RGB")
    g = im.convert("L")
    w, h = g.size
    px = g.load()
    col = [sum(1 for y in range(0, h, 4) if px[x, y] < 24) / (h / 4) > 0.85 for x in range(w)]
    row = [sum(1 for x in range(0, w, 4) if px[x, y] < 24) / (w / 4) > 0.85 for y in range(h)]
    xs, ys = segments(col, N), segments(row, N)
    ok = len(xs) == N and len(ys) == N and all(s[1] - s[0] > w / (N + 2) for s in xs) and all(s[1] - s[0] > h / (N + 2) for s in ys)
    if not ok:
        xs = [(w * i // N, w * (i + 1) // N) for i in range(N)]
        ys = [(h * i // N, h * (i + 1) // N) for i in range(N)]
        print("gouttières introuvables, coupe régulière", k)
    for i, cid in enumerate(b):
        x0, x1 = xs[i % N]
        y0, y1 = ys[i // N]
        m = 5
        panel = im.crop((x0 + m, y0 + m, x1 - m, y1 - m))
        pw, ph = panel.size
        if pw / ph > 1.5:
            nw = int(ph * 1.5)
            panel = panel.crop(((pw - nw) // 2, 0, (pw - nw) // 2 + nw, ph))
        else:
            nh = int(pw / 1.5)
            panel = panel.crop((0, (ph - nh) // 2, pw, (ph - nh) // 2 + nh))
        if cid.startswith("boon_"):
            panel.resize((360, 240), Image.LANCZOS).save(os.path.join(UI, "%s.png" % cid))
        else:
            panel.resize((504, 336), Image.LANCZOS).save(os.path.join(ART, "card_%s.png" % cid))
    print(k, "découpée")
