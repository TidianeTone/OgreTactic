# Illustrations peintes de toutes les cartes (hors légendaires) : planches 3×3 générées par KIE (Seedream 5 Pro),
# puis découpées. Chaque vignette montre le lanceur de la carte en train de faire l'action.
# python gen.py cards.json [numéros de planches]      (clé KIE dans G:\Mes APP\scrollcraft\.env)
import json, os, sys, subprocess
import re
from scenes import LOOKS, S
# les ennemis du jeu, à tour de rôle : pas que des golems
FOES = [
    ("a cracked basalt golem with glowing ember cracks", "cracked basalt golems"),
    ("a drowned armored spearman with teal glowing eyes and seaweed on his armor", "drowned armored soldiers with teal glowing eyes"),
    ("a slate-grey wyvern with teal glowing eyes", "slate-grey wyverns"),
    ("a giant armored river crab", "giant armored river crabs"),
    ("a huge warty swamp toad with a long tongue", "huge warty swamp toads"),
    ("a purple-feathered harpy with talons", "purple-feathered harpies"),
    ("a drowned sea-mage in dark blue robes holding a teal orb", "drowned sea-mages"),
    ("a hooded bone-white archer with red eyes", "hooded bone-white archers"),
]
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "planches")
os.makedirs(OUT, exist_ok=True)
K = r"C:\Users\Skill RTX\.claude\plugins\cache\nateherk\nateherk-design\0.2.0\skills\scroll-craft\scripts\kie.mjs"
cards = [c for c in json.load(open(sys.argv[1], encoding="utf8")) if c["rar"] != 4]
missing = [c["id"] for c in cards if c["id"] not in S]
assert not missing, missing
batches = [cards[i:i + 9] for i in range(0, len(cards), 9)]
json.dump([[c["id"] for c in b] for b in batches], open(os.path.join(OUT, "batches.json"), "w"))
STYLE = ("A single image divided into a 3x3 grid of nine separate fantasy trading-card illustrations, separated by thin pure black gutters. "
         "Each panel is one clear, readable scene showing the named character performing the action, full body or three-quarter, centered. "
         "Same style in all nine panels: painterly dark fantasy, rich chiaroscuro, warm glowing light against deep shadows, "
         "ruined flooded stone city of autumn tones, chunky voxel-inspired shapes. Enemies are only the creatures named in each panel; "
         "no dragons, no other monsters. No text, no letters, no frames.")
POS = ["Top-left", "Top-center", "Top-right", "Middle-left", "Center", "Middle-right", "Bottom-left", "Bottom-center", "Bottom-right"]
only = sys.argv[2:]
for k, b in enumerate(batches):
    if only and str(k) not in only:
        continue
    out = os.path.join(OUT, "sheet_%02d.png" % k)
    if os.path.exists(out):
        continue
    parts = []
    for i, c in enumerate(b):
        one, many = FOES[(k * 9 + i) % len(FOES)]
        scene = re.sub(r"golems", many, S[c["id"]]).format(foe=one, **LOOKS)
        parts.append("%s panel: %s." % (POS[i], scene))
    desc = " ".join(parts)
    r = subprocess.run(["node", K, "still", STYLE + " " + desc, out, "--ar", "3:2"], capture_output=True, text=True, cwd=r"G:\Mes APP\scrollcraft")
    print(k, "ok" if os.path.exists(out) else r.stderr[-300:], flush=True)
