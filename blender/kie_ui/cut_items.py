# Découpe des planches d'équipement (gen_items.py) : case par case, détourage du vert, recadrage carré,
# puis une vraie grille de pixels (64 px, alpha net) agrandie ×2 -> assets/ui/item_<id>.png
# Aussi le dos de carte -> assets/ui/dos_carte.png
import os, json
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "assets", "ui")
ITEMS = os.path.join(HERE, "items")
N = 4
PX = 64


def key(a):
	a = a.astype(float)
	r, g, b = a[..., 0], a[..., 1], a[..., 2]
	green = g - np.maximum(r, b)
	alpha = np.clip(1.0 - (green - 40) / 90.0, 0, 1)
	g2 = np.where(green > 0, np.maximum(r, b) + np.minimum(green, 0), g)
	return np.dstack([r, g2, b, alpha * 255]).astype(np.uint8)


def pixelize(c):
	import cv2
	m = (c[..., 3] > 60).astype(np.uint8)
	n, lab, st, _ = cv2.connectedComponentsWithStats(m, connectivity=8)
	if n <= 1:
		return None
	big = st[1:, 4].max()
	keep = [k for k in range(1, n) if st[k, 4] >= big * 0.03]  # les poussières de vert mal détouré ne comptent pas
	m = np.isin(lab, keep)
	c = c.copy()
	c[..., 3] = np.where(m, c[..., 3], 0)
	ys, xs = np.nonzero(m)
	c = c[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
	h, w = c.shape[:2]
	s = int(max(h, w) * 1.08)
	sq = np.zeros((s, s, 4), np.uint8)
	sq[(s - h) // 2:(s - h) // 2 + h, (s - w) // 2:(s - w) // 2 + w] = c
	im = Image.fromarray(sq).resize((PX, PX), Image.BOX)
	a = np.asarray(im).copy()
	a[..., 3] = np.where(a[..., 3] > 110, 255, 0)  # bord net, comme du vrai pixel art
	return Image.fromarray(a).resize((PX * 2, PX * 2), Image.NEAREST)


def segs(profile, n):
	## Les n plus larges bandes pleines, séparées par des couloirs vides ; à défaut, une grille régulière.
	full = profile > profile.max() * 0.01
	out, start = [], None
	for i, f in enumerate(list(full) + [False]):
		if f and start is None:
			start = i
		elif not f and start is not None:
			out.append((start, i))
			start = None
	out = sorted(sorted(out, key=lambda q: q[1] - q[0], reverse=True)[:n])
	if len(out) != n:
		L = len(profile)
		return [(L * k // n, L * (k + 1) // n) for k in range(n)]
	# on élargit chaque bande jusqu'au milieu des couloirs voisins
	cuts = [0] + [(out[k][1] + out[k + 1][0]) // 2 for k in range(n - 1)] + [len(profile)]
	return [(cuts[k], cuts[k + 1]) for k in range(n)]


batches = json.load(open(os.path.join(ITEMS, "batches.json")))
for k, b in enumerate(batches):
	p = os.path.join(ITEMS, "sheet_%02d.png" % k)
	if not os.path.exists(p):
		print("planche manquante", k)
		continue
	arr = key(np.asarray(Image.open(p).convert("RGB")))
	H, W = arr.shape[:2]
	# la grille peinte n'est pas régulière : on coupe dans les couloirs vides (profils d'alpha)
	xs, ys = segs(arr[..., 3].sum(axis=0), N), segs(arr[..., 3].sum(axis=1), N)
	for i, id in enumerate(b):
		r, c = divmod(i, N)
		cell = arr[ys[r][0]:ys[r][1], xs[c][0]:xs[c][1]]
		im = pixelize(cell)
		if im is None:
			print("case vide", id)
			continue
		im.save(os.path.join(OUT, "item_%s.png" % id))
	print("planche", k, "ok")
dos = os.path.join(HERE, "dos_carte.png")
if os.path.exists(dos):
	d = np.asarray(Image.open(dos).convert("RGB")).astype(int)
	white = (d.min(axis=2) > 225)
	ys, xs = np.nonzero(~white)
	d = d[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
	a = np.where(d.min(axis=2) > 225, 0, 255)  # coins arrondis : le blanc devient transparent
	im = Image.fromarray(np.dstack([d, a]).astype(np.uint8))
	im.resize((392, 544), Image.LANCZOS).save(os.path.join(OUT, "dos_carte.png"))
	print("dos ok")
