# Découpe chaque planche 3×3 en 9 illustrations (les gouttières noires séparent les vignettes).
import json, os, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "..", "assets", "art")
batches = json.load(open(os.path.join(HERE, "planches", "batches.json")))


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
    p = os.path.join(HERE, "planches", "sheet_%02d.png" % k)
    if not os.path.exists(p):
        print("planche manquante", k)
        continue
    im = Image.open(p).convert("RGB")
    g = im.convert("L")
    w, h = g.size
    px = g.load()
    col = [sum(1 for y in range(0, h, 4) if px[x, y] < 24) / (h / 4) > 0.85 for x in range(w)]
    row = [sum(1 for x in range(0, w, 4) if px[x, y] < 24) / (w / 4) > 0.85 for y in range(h)]
    xs, ys = segments(col, 3), segments(row, 3)
    ok = len(xs) == 3 and len(ys) == 3 and all(s[1] - s[0] > w / 5 for s in xs) and all(s[1] - s[0] > h / 5 for s in ys)
    if not ok:
        xs = [(w * i // 3, w * (i + 1) // 3) for i in range(3)]
        ys = [(h * i // 3, h * (i + 1) // 3) for i in range(3)]
        print("gouttières introuvables, coupe régulière", k)
    for i, cid in enumerate(b):
        x0, x1 = xs[i % 3]
        y0, y1 = ys[i // 3]
        m = 5
        panel = im.crop((x0 + m, y0 + m, x1 - m, y1 - m))
        pw, ph = panel.size
        if pw / ph > 1.5:
            nw = int(ph * 1.5)
            panel = panel.crop(((pw - nw) // 2, 0, (pw - nw) // 2 + nw, ph))
        else:
            nh = int(pw / 1.5)
            panel = panel.crop((0, (ph - nh) // 2, pw, (ph - nh) // 2 + nh))
        panel.resize((504, 336), Image.LANCZOS).save(os.path.join(ART, "card_%s.png" % cid))
    print(k, "découpée")
