# Direction artistique low poly (proche du voxel du jeu) : toutes les cartes, légendaires comprises,
# et les bienfaits des Anciens, en planches 4×4 générées par KIE (Seedream 5 Pro), puis découpées.
# python gen_lowpoly.py cards.json [numéros de planches]
import json, os, sys, subprocess, re
from scenes import LOOKS, S, LEG, BOONS
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "planches_lp")
os.makedirs(OUT, exist_ok=True)
K = r"C:\Users\Skill RTX\.claude\plugins\cache\nateherk\nateherk-design\0.2.0\skills\scroll-craft\scripts\kie.mjs"
FOES = [
    ("a cracked basalt golem with glowing ember cracks", "cracked basalt golems"),
    ("a drowned armored spearman with teal glowing eyes", "drowned armored soldiers"),
    ("a slate-grey wyvern", "slate-grey wyverns"),
    ("a giant armored river crab", "giant river crabs"),
    ("a big warty swamp toad", "swamp toads"),
    ("a purple-feathered harpy", "purple harpies"),
    ("a drowned sea-mage with a teal orb", "drowned sea-mages"),
    ("a hooded bone-white archer", "bone-white archers"),
]
cards = json.load(open(sys.argv[1], encoding="utf8"))
items = []
for c in cards:
    scene = LEG[c["id"]] if c["rar"] == 4 else S[c["id"]]
    items.append((c["id"], scene))
for k, v in BOONS.items():
    items.append(("boon_" + k, v))
batches = [items[i:i + 16] for i in range(0, len(items), 16)]
json.dump([[x[0] for x in b] for b in batches], open(os.path.join(OUT, "batches.json"), "w"))
STYLE = ("A single image divided into a 4x4 grid of sixteen separate small game card illustrations, separated by thin pure black gutters. "
         "Style for every panel: low-poly 3D render, chunky faceted blocky shapes close to voxel art, flat shading, simple readable silhouettes, "
         "few details, soft warm lighting with teal and amber accents, like a stylized voxel tactics video game, three-quarter view, "
         "simple backgrounds of a flooded ruined stone city. Not realistic, not painterly. No text, no letters, no frames.")
only = sys.argv[2:]
for k, b in enumerate(batches):
    if only and str(k) not in only:
        continue
    out = os.path.join(OUT, "sheet_%02d.png" % k)
    if os.path.exists(out):
        continue
    parts = []
    for i, (cid, sc) in enumerate(b):
        one, many = FOES[(k * 16 + i) % len(FOES)]
        sc = re.sub(r"\bgolems\b", many, sc)
        sc = sc.format(foe=one, **LOOKS) if "{" in sc else sc
        parts.append("Panel %d (row %d, column %d): %s." % (i + 1, i // 4 + 1, i % 4 + 1, sc))
    r = subprocess.run(["node", K, "still", STYLE + " " + " ".join(parts), out, "--ar", "3:2"], capture_output=True, text=True, cwd=r"G:\Mes APP\scrollcraft")
    print(k, "ok" if os.path.exists(out) else r.stderr[-300:], flush=True)
print(len(batches), "planches")
