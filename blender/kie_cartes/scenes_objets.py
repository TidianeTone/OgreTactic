# Cartes-objets : l'objet utilisé, en situation, dans les écluses englouties d'automne.
# python scenes_objets.py   -> planches_objets/sheet_00.png, puis : python cut.py planches_objets 4
import json, os, subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "planches_objets")
K = r"C:\Users\Skill RTX\.claude\plugins\cache\nateherk\nateherk-design\0.2.0\skills\scroll-craft\scripts\kie.mjs"

O = {
    "o_fiole": "close-up of a hand pouring a small glass vial of glowing green sap onto a bleeding wound on a hero's arm, green light spreading",
    "o_fumigene": "a round smoke grenade bursting into a big billowing grey smoke cloud on cracked ruin flagstones",
    "o_picots": "sharp steel caltrops scattered on stone flagstones, an armored enemy boot stepping on one, spikes piercing",
    "o_grappin": "a thrown iron grappling hook catching the top of a ruined stone tower, a taut rope stretching down diagonally",
    "o_arbre": "an acorn on the ground bursting into a young oak tree in one instant, thick roots cracking and lifting the flagstones",
    "o_bombe": "a round black bomb with a lit sparking fuse rolling across stone flagstones, bright sparks flying",
    "o_baril": "a wooden gunpowder barrel standing alone on stone flagstones, a short fuse hissing, ominous danger",
    "o_brasero": "an iron brazier on the ground glowing red-hot, embers and sparks flying up into the air",
    "o_filet": "a weighted rope net falling over a cracked basalt golem and trapping it, the golem struggling underneath",
    "o_sels": "a small open tin of smelling salts with sharp white vapor rising, a groggy hooded hero pushing himself up from the ground",
    "o_elixir": "a hero drinking from a bottle of glowing incandescent orange ember elixir, orange energy aura bursting around him",
    "o_carnet": "an open sketchbook with pages flying off into the wind, the pages covered in drawn tactical arrows and maps",
    "o_de": "a single ivory six-sided die tumbling across a stone table, mid-roll, only pips on its faces, a faint glow of trickery",
    "o_sablier": "a cracked hourglass whose falling sand is frozen mid-air, grains suspended in stillness, time stopped",
}
FILL = "an empty autumn stone lock gate half submerged in turquoise water"

STYLE = ("A single image divided into a 4x4 grid of sixteen separate small game card illustrations, separated by thin pure black gutters. "
         "Style for every panel: low-poly 3D render, chunky faceted blocky shapes close to voxel art, flat shading, simple readable silhouettes, "
         "few details, soft warm lighting with teal and amber accents, like a stylized voxel tactics video game, three-quarter view, "
         "simple backgrounds of flooded ruined stone canal locks with turquoise water and autumn trees with orange leaves, warm golden light. "
         "Each panel shows the object being used, in action, centered and large. Not realistic, not painterly. No text, no letters, no numbers, no frames.")

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    ids = list(O)
    json.dump([ids], open(os.path.join(OUT, "batches.json"), "w"))
    scenes = list(O.values()) + [FILL] * (16 - len(ids))
    parts = ["Panel %d (row %d, column %d): %s." % (i + 1, i // 4 + 1, i % 4 + 1, s) for i, s in enumerate(scenes)]
    out = os.path.join(OUT, "sheet_00.png")
    if not os.path.exists(out):
        r = subprocess.run(["node", K, "still", STYLE + " " + " ".join(parts), out, "--ar", "3:2"], capture_output=True, text=True, cwd=r"G:\Mes APP\scrollcraft")
        print("ok" if os.path.exists(out) else r.stderr[-300:])
