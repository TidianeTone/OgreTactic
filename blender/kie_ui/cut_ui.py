# Détourage des planches KIE sur vert #00FF00 : alpha par distance au vert, dévert des bords, découpe par case.
# python cut_ui.py  ->  assets/ui/frame_<type>.png, orb_<classe>.png, + fenêtres mesurées (fractions) imprimées
import os, json
import numpy as np
from PIL import Image
import cv2

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "assets", "ui")


def key(im):
	a = np.asarray(im.convert("RGB")).astype(float)
	r, g, b = a[..., 0], a[..., 1], a[..., 2]
	green = g - np.maximum(r, b)  # à quel point le pixel est « vert écran »
	alpha = np.clip(1.0 - (green - 40) / 90.0, 0, 1)
	# dévert : on ramène le vert au niveau du max(r, b) sur les bords
	g2 = np.where(green > 0, np.maximum(r, b) + np.minimum(green, 0), g)
	rgb = np.dstack([r, g2, b])
	return np.dstack([rgb, alpha * 255]).astype(np.uint8)


def cells(arr, rows, cols):
	H, W = arr.shape[:2]
	for i in range(rows):
		for j in range(cols):
			c = arr[i * H // rows:(i + 1) * H // rows, j * W // cols:(j + 1) * W // cols]
			ys, xs = np.nonzero(c[..., 3] > 30)
			yield i * cols + j, c[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def holes(c):
	## Fenêtres transparentes intérieures (ne touchant pas le bord), triées de haut en bas, en fractions.
	n, lab = cv2.connectedComponents((c[..., 3] < 30).astype(np.uint8), connectivity=4)
	n -= 1
	H, W = c.shape[:2]
	out = []
	for k in range(1, n + 1):
		ys, xs = np.nonzero(lab == k)
		if ys.min() == 0 or xs.min() == 0 or ys.max() == H - 1 or xs.max() == W - 1 or len(ys) < H * W * 0.02:
			continue
		out.append([round(xs.min() / W, 3), round(ys.min() / H, 3), round((xs.max() + 1) / W, 3), round((ys.max() + 1) / H, 3)])
	return sorted(out, key=lambda r: r[1])


meta = {}
arr = key(Image.open(os.path.join(HERE, "cadres.png")))
for k, c in cells(arr, 2, 2):
	name = ["attaque", "technique", "mouvement", "pouvoir"][k]
	Image.fromarray(c).save(os.path.join(OUT, "frame_%s.png" % name))
	meta[name] = {"size": [c.shape[1], c.shape[0]], "holes": holes(c)}
arr = key(Image.open(os.path.join(HERE, "orbes.png")))
for k, c in cells(arr, 3, 3):
	name = ["garde", "lame", "oracle", "artificier", "moine", "trappeur", "tidiane", "receleur", "neutre"][k]
	Image.fromarray(c).save(os.path.join(OUT, "orb_%s.png" % name))
	meta["orb_" + name] = {"size": [c.shape[1], c.shape[0]], "holes": holes(c)}
json.dump(meta, open(os.path.join(HERE, "mesures.json"), "w"), indent=1)
print(json.dumps(meta, indent=1))
