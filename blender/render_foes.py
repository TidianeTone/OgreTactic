# Portraits des ennemis pour le guide : chaque modèle cadré d'après sa boîte englobante.
# blender -b --factory-startup -P render_foes.py -- DOSSIER
import bpy, os, sys, math
from mathutils import Vector
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import render_art as ra

OUT = sys.argv[sys.argv.index("--") + 1]
os.makedirs(OUT, exist_ok=True)
FOES = ["husk", "guetteur", "sentinelle", "wisp", "gardien", "chaman", "carapace", "rodeur", "lancier", "cavalier", "vouivre", "mage",
        "bretteur", "danseuse", "capitaine", "baliste", "crabe", "crapaud", "harpie", "obelisque"]
ra.setup()
for k in FOES:
    ra.clear()
    ra.backdrop((0.9, 0.35, 0.2) if k in ("husk", "guetteur", "sentinelle", "wisp", "gardien", "chaman", "carapace", "rodeur") else (0.2, 0.75, 0.7))
    root = ra.load_hero(k)
    root.rotation_euler = (0, 0, math.radians(-25))
    bpy.context.view_layer.update()
    pts = [o.matrix_world @ Vector(c) for o in root.children_recursive if o.type == "MESH" for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    c = (lo + hi) / 2
    size = max(hi.x - lo.x, hi.z - lo.z, 0.5)
    ra.light_rig((0.9, 0.6, 0.4))
    bpy.ops.object.light_add(type="AREA", location=(c.x + size * 0.6, c.y - size * 1.6, c.z + size * 0.8))
    key = bpy.context.active_object
    key.data.energy = 260 * size * size
    key.data.size = size * 1.5
    key.rotation_euler = (math.radians(55), 0, math.radians(20))
    ra.camera((c.x + size * 0.3, c.y - size * 1.25, c.z + size * 0.2), (c.x, c.y, c.z), lens=50)
    ra.render(os.path.join(OUT, "foe_%s.png" % k), 320, 320)
print("foes ok")
