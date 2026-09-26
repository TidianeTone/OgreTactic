# Illustrations des écrans de choix (mode, difficulté, leçons de l'initiation, salles de la carte d'étage),
# même direction low poly que les cartes : planches 4×4 KIE, découpées par ../kie_cartes/cut.py planches_menus 4.
# python gen_menus.py [numéros de planches]
import json, os, sys, subprocess
# versions courtes des héros de scenes.LOOKS : le prompt Seedream plafonne vers 3950 caractères
LOOKS = {"garde": "the Guard (blue-steel knight, tower shield)", "lame": "the Blade (black hooded assassin, red scarf, twin daggers)",
         "oracle": "the Oracle (purple-robed mage, pointed hat, lantern staff)"}
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "kie_cartes", "planches_menus")
os.makedirs(OUT, exist_ok=True)
K = r"C:\Users\Skill RTX\.claude\plugins\cache\nateherk\nateherk-design\0.2.0\skills\scroll-craft\scripts\kie.mjs"
SQUAD = "{garde}, {lame} and {oracle}"

SCENES = [
    ("mode_descente", SQUAD + " walk down a long carved stone staircase toward a flooded ruined city far below, three glowing lanterns mark three diverging paths"),
    ("mode_aventure", SQUAD + " advance through a dark misty stone corridor, the Oracle's lantern lighting the fog, the silhouette of a monster waiting ahead"),
    ("diff_1", "{garde} dozes against a mossy sunlit wall by turquoise water, helmet off, a steaming cup beside him, butterflies, peaceful"),
    ("diff_2", SQUAD + " stand at a ruined stone gate at sunrise, looking out over a flooded valley, packs on their backs, hopeful"),
    ("diff_3", "{garde}, his shield cracked and armor scratched, holds a narrow bridge alone against three drowned armored soldiers with teal glowing eyes"),
    ("diff_4", "gigantic lock gates burst open and a wall of turquoise water rushes through the ruins, {lame} leaps from block to block to escape, stormy sky"),
    ("diff_5", "a colossal black obelisk covered in glowing crimson runes rises over the ruins under a blood-red sky, a horde of dark silhouettes marches out of it"),
    ("tuto_1", "{lame} strikes a moss-covered stone golem in the back while it looks the other way, a big bright slash on its back"),
    ("tuto_2", "{oracle} opens a small iron-bound treasure chest and a single glowing golden card rises out of it in a beam of light, ember sparks"),
    ("tuto_3", SQUAD + " face a huge armored shell beast bristling with plates, a blue shimmer of armor around it, the Oracle raining small embers on it"),
    ("salle_combat", "{lame} and {garde} clash with two cracked basalt golems on a stone plaza, sparks and dust"),
    ("salle_elite", "a towering drowned captain in barnacled plate armor with a great anchor-mace, flanked by two drowned soldiers, teal glowing eyes, menacing"),
    ("salle_sanctuaire", "a small overgrown shrine with a pool of glowing green water, {garde} kneels to drink, healing light motes rise"),
    ("salle_reliquaire", "a stone reliquary altar holding three glowing relics under glass domes, violet light, dust in the air"),
    ("salle_marchand", "a hooded traveling merchant under a patched awning on a ruined bridge, a cart of weapons, potions and cards, warm lanterns"),
    ("salle_mystere", "a fog-filled archway with a single question-mark-shaped glowing rune carved above it, strange eyes glinting in the fog"),
]

STYLE = ("A single image divided into a 4x4 grid of sixteen separate small game illustrations, separated by thin pure black gutters. "
         "Style for every panel: low-poly 3D render, chunky faceted blocky shapes close to voxel art, flat shading, simple readable silhouettes, "
         "few details, soft warm lighting with teal and amber accents, like a stylized voxel tactics video game, three-quarter view, "
         "backgrounds of a flooded ruined stone city. Not realistic, not painterly. No text, no letters, no frames.")

batches = [SCENES[i:i + 16] for i in range(0, len(SCENES), 16)]
json.dump([[x[0] for x in b] for b in batches], open(os.path.join(OUT, "batches.json"), "w"))
only = sys.argv[1:]
for k, b in enumerate(batches):
    out = os.path.join(OUT, "sheet_%02d.png" % k)
    if (only and str(k) not in only) or os.path.exists(out):
        continue
    parts = ["Panel %d (row %d, column %d): %s." % (i + 1, i // 4 + 1, i % 4 + 1, sc.format(**LOOKS)) for i, (_, sc) in enumerate(b)]
    prompt = STYLE + " " + " ".join(parts)
    assert len(prompt) < 3950, len(prompt)
    r = subprocess.run(["node", K, "still", prompt, out, "--ar", "3:2"], capture_output=True, text=True, cwd=r"G:\Mes APP\scrollcraft")
    print(k, "ok" if os.path.exists(out) else r.stderr[-300:], flush=True)
