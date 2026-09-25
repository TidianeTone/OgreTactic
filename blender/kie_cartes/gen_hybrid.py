# Cartes de guilde avec les héros hybrides (vocation : coiffe et bas de tenue de la classe apprise)
# et les 220 cartes du 25/09. Planches 4×4 low poly via KIE, comme gen_lowpoly.py.
# python gen_hybrid.py cartes.json [numéros de planches]   puis   python cut.py planches_hy 4
# L'action prime : le héros n'est pas obligatoire sur l'image, l'ennemi non plus.
import json, os, sys, subprocess, re
from scenes import LOOKS, S
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "planches_hy")
os.makedirs(OUT, exist_ok=True)
K = r"C:\Users\Skill RTX\.claude\plugins\cache\nateherk\nateherk-design\0.2.0\skills\scroll-craft\scripts\kie.mjs"
sys.path.insert(0, os.path.join(HERE, ".."))
PAIRS = [("garde", "lame"), ("garde", "oracle"), ("garde", "artificier"), ("garde", "moine"), ("garde", "trappeur"), ("garde", "tidiane"),
         ("garde", "receleur"), ("lame", "oracle"), ("lame", "artificier"), ("lame", "moine"), ("lame", "trappeur"), ("lame", "tidiane"),
         ("lame", "receleur"), ("oracle", "artificier"), ("oracle", "moine"), ("oracle", "trappeur"), ("oracle", "tidiane"), ("oracle", "receleur"),
         ("artificier", "moine"), ("artificier", "trappeur"), ("artificier", "tidiane"), ("artificier", "receleur"), ("moine", "trappeur"),
         ("moine", "tidiane"), ("moine", "receleur"), ("trappeur", "tidiane"), ("trappeur", "receleur"), ("tidiane", "receleur")]
# ce que la vocation ajoute au héros (même chose que les modèles voxel hybrides)
HYB = {"garde": "a steel crested helmet with a blue plume and blue lower garments",
       "lame": "a red headband with long trailing tails and red lower garments",
       "oracle": "a wide pointed purple wizard hat with a gold brim and a purple lower robe",
       "artificier": "brass goggles pushed up on the forehead and teal lower garments",
       "moine": "a conical straw hat with a green cord and green lower garments",
       "trappeur": "a big ochre feather in the hair and ochre lower garments",
       "tidiane": "a white porcelain half-mask and magenta lower garments",
       "receleur": "a grey-blue hood and grey-blue lower garments"}
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


SHORT = {"garde": "a blue-armored knight with a tower shield", "lame": "a black-hooded assassin with twin daggers",
         "oracle": "a purple-robed witch with a lantern staff", "artificier": "a teal-clad engineer with a wrench",
         "moine": "a green-robed barefoot monk", "trappeur": "an ochre-leather hunter with a harpoon",
         "tidiane": "a duelist in a magenta coat with a brush-blade", "receleur": "a grey-blue cloaked thief with a loot sack"}
TAG = {"garde": "a blue-plumed helmet", "lame": "a red headband", "oracle": "a purple wizard hat", "artificier": "brass goggles",
       "moine": "a straw hat", "trappeur": "an ochre feather", "tidiane": "a porcelain mask", "receleur": "a grey hood"}
LOOKS = SHORT


def hybrid_looks(a, b):
    """Dans une carte de guilde, chaque héros de la paire porte la vocation de l'autre."""
    d = dict(LOOKS)
    d[a] = LOOKS[a] + " wearing " + TAG[b]
    d[b] = LOOKS[b] + " wearing " + TAG[a]
    return d


new = json.load(open(sys.argv[1], encoding="utf8"))
items = []
for gid, sc in S.items():  # anciennes cartes de guilde (hors légendaires, figures nommées)
    if gid.startswith("g_"):
        items.append((gid, sc, None))
for c in new:
    items.append((c["id"], c["scene"], c.get("g", -1)))
old_g = {}
src = open(os.path.join(HERE, "..", "..", "scripts", "guildes.gd"), encoding="utf8").read()
for m in re.finditer(r'"(g_[a-z0-9_]+)": \{"name": "[^"]*", "g": (\d+)', src):
    old_g[m.group(1)] = int(m.group(2))
batches = [items[i:i + 16] for i in range(0, len(items), 16)]
json.dump([[x[0] for x in b] for b in batches], open(os.path.join(OUT, "batches.json"), "w"))
STYLE = ("A single image divided into a 4x4 grid of sixteen separate small game card illustrations, separated by thin pure black gutters. "
         "Style for every panel: low-poly 3D render, chunky faceted blocky shapes close to voxel art, flat shading, simple readable silhouettes, "
         "few details, soft warm lighting with teal and amber accents, like a stylized voxel tactics video game, three-quarter view, "
         "simple backgrounds of a flooded ruined stone city. Each panel shows one clear dynamic action. Not realistic, not painterly. "
         "No text, no letters, no frames.")
only = sys.argv[2:]
for k, b in enumerate(batches):
    if only and str(k) not in only:
        continue
    out = os.path.join(OUT, "sheet_%02d.png" % k)
    if os.path.exists(out):
        continue
    parts = []
    for i, (cid, sc, g) in enumerate(b):
        g = g if g is not None and g >= 0 else old_g.get(cid, -1)
        looks = hybrid_looks(*PAIRS[g]) if g >= 0 else LOOKS
        one, many = FOES[(k * 16 + i) % len(FOES)]
        sc = re.sub(r"\bgolems\b", many, sc)
        sc = sc.replace("{foe}", one)
        for key, v in looks.items():
            sc = sc.replace("{%s}" % key, v)
        parts.append("Panel %d (row %d, column %d): %s." % (i + 1, i // 4 + 1, i % 4 + 1, sc))
    while len(STYLE) + sum(map(len, parts)) + 16 > 3950:  # limite du modèle : on raccourcit la scène la plus longue
        j = max(range(len(parts)), key=lambda q: len(parts[q]))
        cut = parts[j][:-1].rsplit(",", 1)[0] if "," in parts[j][40:] else parts[j][:len(parts[j]) - 30]
        parts[j] = cut.rstrip(" .") + "."
    print(k, "longueur", len(STYLE) + sum(map(len, parts)), flush=True)
    r = subprocess.run(["node", K, "still", STYLE + " " + " ".join(parts), out, "--ar", "3:2"], capture_output=True, text=True, cwd=r"G:\Mes APP\scrollcraft")
    print(k, "ok" if os.path.exists(out) else r.stderr[-300:], flush=True)
print(len(batches), "planches")
