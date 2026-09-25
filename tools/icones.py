"""Icônes game-icons.net (CC BY 3.0) repassées en pixel art crème et or, 128 px.

python tools/icones.py menu_bibliotheque=delapouite/bookshelf gear_casque=lorc/visored-helm ...
SVG téléchargé -> rastérisé 38 px par Godot (headless) -> contour brun, dégradé crème/or, pixels x3.
"""
import os, sys, subprocess, tempfile, urllib.request
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "ui")
CREAM = np.array([242, 228, 196]); GOLD = np.array([214, 176, 108]); EDGE = np.array([58, 30, 18]); HI = np.array([255, 248, 228])


def stylize(src, dst):
	a = np.asarray(Image.open(src).convert("RGBA"))[:, :, 3] > 110
	H, W = a.shape
	ys = np.linspace(0, 1, H)[:, None]
	fill = (CREAM * (1 - ys[..., None] * 0.9) + GOLD * (ys[..., None] * 0.9)).repeat(W, axis=1)
	rgb = np.zeros((H + 4, W + 4, 3)); al = np.zeros((H + 4, W + 4))
	m = np.zeros((H + 4, W + 4), bool); m[2:-2, 2:-2] = a
	o = np.zeros_like(m)
	for dy in (-1, 0, 1):
		for dx in (-1, 0, 1):
			o |= np.roll(np.roll(m, dy, 0), dx, 1)
	o &= ~m
	rgb[2:-2, 2:-2][a] = fill[a]
	rgb[m & ~np.roll(m, 1, 0)] = HI
	rgb[o] = EDGE
	al[m | o] = 255
	p = Image.fromarray(np.dstack([rgb, al]).astype(np.uint8), "RGBA").resize(((W + 4) * 3, (H + 4) * 3), Image.NEAREST)
	can = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
	can.paste(p, ((128 - p.size[0]) // 2, (128 - p.size[1]) // 2))
	can.save(dst)


def main(pairs):
	tmp = tempfile.mkdtemp().replace("\\", "/")
	names = []
	for pair in pairs:
		name, path = pair.split("=")
		svg = urllib.request.urlopen("https://raw.githubusercontent.com/game-icons/icons/master/%s.svg" % path).read().decode()
		svg = svg.replace('<path d="M0 0h512v512H0z"/>', "")  # le fond noir
		open("%s/%s.svg" % (tmp, name), "w").write(svg)
		names.append(name)
	gd = "%s/r.gd" % tmp
	open(gd, "w").write('extends SceneTree\nfunc _init():\n\tfor n in %s:\n\t\tvar im := Image.new()\n'
		'\t\tim.load_svg_from_string(FileAccess.get_file_as_string("%s/%%s.svg" %% n), 38.0 / 512.0)\n'
		'\t\tim.save_png("%s/%%s.png" %% n)\n\tquit()\n' % (str(names).replace("'", '"'), tmp, tmp))
	godot = open(os.path.join(ROOT, ".godot_path")).read().strip()
	if godot.startswith("/c/"):
		godot = "C:" + godot[2:]
	subprocess.run([godot, "--headless", "--script", gd], check=True, capture_output=True)
	for n in names:
		stylize("%s/%s.png" % (tmp, n), os.path.join(OUT, n + ".png"))
	print("ok", len(names))


if __name__ == "__main__":
	main(sys.argv[1:])
