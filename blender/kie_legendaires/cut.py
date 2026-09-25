# Découpe une planche 2x2 en 4 illustrations : les gouttières noires séparent les vignettes.
import json, os, sys
from PIL import Image
S = os.path.dirname(os.path.abspath(__file__))
ART = r"G:\Mes APP\Delve\assets\art"
batches = json.load(open(os.path.join(S, "batches.json")))

def segments(profile, n):
    ## zones non noires le long d'un axe ; on garde les deux plus longues
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
    p = os.path.join(S, "sheet_%d.png" % k)
    try:
        im = Image.open(p).convert("RGB")
    except Exception:
        print("pas de planche", k)
        continue
    g = im.convert("L")
    w, h = g.size
    px = g.load()
    col = [sum(1 for y in range(0, h, 4) if px[x, y] < 22) / (h / 4) > 0.9 for x in range(w)]
    row = [sum(1 for x in range(0, w, 4) if px[x, y] < 22) / (w / 4) > 0.9 for y in range(h)]
    xs, ys = segments(col, 2), segments(row, 2)
    if len(xs) < 2 or len(ys) < 2:
        xs = [(0, w // 2), (w // 2, w)]
        ys = [(0, h // 2), (h // 2, h)]
        print("gouttières introuvables, coupe au milieu", k)
    for i, (cid, _) in enumerate(b):
        x0, x1 = xs[i % 2]
        y0, y1 = ys[i // 2]
        m = 6
        panel = im.crop((x0 + m, y0 + m, x1 - m, y1 - m))
        # recadre au 3:2 des illustrations de cartes
        pw, ph = panel.size
        if pw / ph > 1.5:
            nw = int(ph * 1.5)
            panel = panel.crop(((pw - nw) // 2, 0, (pw - nw) // 2 + nw, ph))
        else:
            nh = int(pw / 1.5)
            panel = panel.crop((0, (ph - nh) // 2, pw, (ph - nh) // 2 + nh))
        panel.resize((504, 336), Image.LANCZOS).save(os.path.join(ART, "card_%s.png" % cid))
        print(k, cid, panel.size)
