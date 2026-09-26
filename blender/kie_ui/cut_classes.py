# Cadres par classe (planche cadres_classes.png, 3x3) et par guilde (guildes/<a>_<b>.png, un cadre peint par paire).
# Chaque cadre est recalé sur la carte du jeu : sa fenêtre d'illustration tombe sur F_ART (ui.gd), le bas de sa fenêtre
# de texte sur le bas de F_TXT. On l'enregistre sur une toile plus grande que la carte (MARGE de chaque côté) :
# les ornements qui débordent (flammes, pinceaux) restent visibles.
# python cut_classes.py  ->  assets/ui/frame_c_<classe>.png, frame_g_<a>_<b>.png, assets/ui/frames.json
import os, json, sys
import numpy as np
from PIL import Image
import cv2

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
OUT = os.path.join(HERE, "..", "..", "assets", "ui")
CARD = (490, 680)            # 2,5 × la carte du jeu (196 × 272)
MARGE = 0.2                  # toile = carte + 20 % de chaque côté
F_ART = (0.14, 0.175, 0.86, 0.65)
F_TXT_BOTTOM = 0.91
NAMES = ["garde", "lame", "oracle", "artificier", "moine", "trappeur", "tidiane", "receleur", "objet"]
PAIRS = [("garde", "lame"), ("garde", "oracle"), ("garde", "artificier"), ("garde", "moine"), ("garde", "trappeur"), ("garde", "tidiane"), ("garde", "receleur"),
	("lame", "oracle"), ("lame", "artificier"), ("lame", "moine"), ("lame", "trappeur"), ("lame", "tidiane"), ("lame", "receleur"),
	("oracle", "artificier"), ("oracle", "moine"), ("oracle", "trappeur"), ("oracle", "tidiane"), ("oracle", "receleur"),
	("artificier", "moine"), ("artificier", "trappeur"), ("artificier", "tidiane"), ("artificier", "receleur"),
	("moine", "trappeur"), ("moine", "tidiane"), ("moine", "receleur"), ("trappeur", "tidiane"), ("trappeur", "receleur"), ("tidiane", "receleur")]

def key(im):
	## Comme cut_ui.key (ne pas l'importer : cut_ui refait toutes ses découpes à l'import).
	a = np.asarray(im.convert("RGB")).astype(float)
	r, g, b = a[..., 0], a[..., 1], a[..., 2]
	green = g - np.maximum(r, b)
	alpha = np.clip(1.0 - (green - 40) / 90.0, 0, 1)
	g2 = np.where(green > 0, np.maximum(r, b) + np.minimum(green, 0), g)
	return np.dstack([r, g2, b, alpha * 255]).astype(np.uint8)


def holes(c):
	## Fenêtres intérieures (transparentes, loin du bord de la case), en pixels, de haut en bas.
	n, lab, stats, _ = cv2.connectedComponentsWithStats((c[..., 3] < 30).astype(np.uint8), connectivity=4)
	H, W = c.shape[:2]
	out = []
	for k in range(1, n):
		x, y, w, h, area = stats[k]
		if x == 0 or y == 0 or x + w >= W or y + h >= H or area < H * W * 0.02:
			continue
		out.append((x, y, x + w, y + h))
	return sorted(out, key=lambda r: r[1])


def fit(c):
	## Cadre -> toile : l'illustration sur F_ART (en x et en haut), le bas du texte sur F_TXT_BOTTOM.
	hs = holes(c)
	art, txt = hs[0], hs[-1]
	sx = (F_ART[2] - F_ART[0]) * CARD[0] / (art[2] - art[0])
	sy = (F_TXT_BOTTOM - F_ART[1]) * CARD[1] / (txt[3] - art[1])
	cw, ch = int(CARD[0] * (1 + 2 * MARGE)), int(CARD[1] * (1 + 2 * MARGE))
	ox = CARD[0] * MARGE + F_ART[0] * CARD[0] - art[0] * sx
	oy = CARD[1] * MARGE + F_ART[1] * CARD[1] - art[1] * sy
	M = np.float32([[sx, 0, ox], [0, sy, oy]])
	canvas = cv2.warpAffine(c, M, (cw, ch), flags=cv2.INTER_AREA, borderValue=(0, 0, 0, 0))
	# séparation illustration / texte, en fractions de carte
	div = [(art[3] * sy + oy - CARD[1] * MARGE) / CARD[1], (txt[1] * sy + oy - CARD[1] * MARGE) / CARD[1]]
	return canvas, div


arr = key(Image.open(os.path.join(HERE, "cadres_classes.png")))
H, W = arr.shape[:2]
meta = {"marge": MARGE}
canv = {}
for i, name in enumerate(NAMES):
	r, c = divmod(i, 3)
	cell = arr[r * H // 3:(r + 1) * H // 3, c * W // 3:(c + 1) * W // 3]
	canvas, div = fit(cell)
	canv[name] = (canvas, div)
	Image.fromarray(canvas).save(os.path.join(OUT, "frame_c_%s.png" % name))
	meta["c_" + name] = [round(div[0], 4), round(div[1], 4)]
for a, b in PAIRS:
	# un cadre peint par paire (gen_ui.py guildes) : les deux styles fondus, plus deux moitiés recollées
	canvas, div = fit(key(Image.open(os.path.join(HERE, "guildes", "%s_%s.png" % (a, b)))))
	Image.fromarray(canvas).save(os.path.join(OUT, "frame_g_%s_%s.png" % (a, b)))
	meta["g_%s_%s" % (a, b)] = [round(div[0], 4), round(div[1], 4)]
json.dump(meta, open(os.path.join(OUT, "frames.json"), "w"), indent=1)
print(json.dumps({k: v for k, v in meta.items() if k.startswith("c_")}, indent=0))
