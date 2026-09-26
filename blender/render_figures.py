# Silhouettes en pied des héros pour la fiche d'équipement (fond transparent) -> assets/art/figure_<héros>.png
# blender -b --factory-startup -P render_figures.py
import bpy, os, sys, math
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import render_art as ra

ra.setup()
bpy.context.scene.render.film_transparent = True
for owner, col in ra.CLASS.items():
    ra.clear()
    root = ra.load_hero(owner)
    root.rotation_euler = (0, 0, math.radians(-18))
    ra.light_rig(col)
    ra.camera((0.25, -4.0, 1.2), (0.0, 0, 0.92), lens=58)
    ra.render(os.path.join(ra.ART, "figure_%s.png" % owner), 256, 384)
print("figures ok")
