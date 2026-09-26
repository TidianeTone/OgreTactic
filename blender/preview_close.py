# Planche rapprochée : quelques modèles en gros plan -> captures/close.png
# blender -b --factory-startup -P preview_close.py -- u_garde u_lame u_husk ...
import bpy, os, math, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from render_art import setup, clear, vc_mat, camera

ASSETS = r"G:\Mes APP\Delve\assets"
names = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["u_garde", "u_lame", "u_oracle"]
out = os.environ.get("DELVE_OUT", r"G:\Mes APP\Delve\captures\close.png")
setup()
clear()
x = 0.0
for key in names:
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(ASSETS, key + ".glb"))
    root = bpy.data.objects.new("r_" + key, None)
    bpy.context.scene.collection.objects.link(root)
    for o in set(bpy.data.objects) - before:
        if o.type == "MESH":
            o.data.materials.clear()
            o.data.materials.append(vc_mat("vcg" if "glow" in o.name else "vc", glow="glow" in o.name))
        if o.parent is None and o is not root:
            o.parent = root
    root.location = (x, 0, 0)
    root.rotation_euler = (0, 0, math.radians(-30))
    x += 1.5
bpy.ops.mesh.primitive_plane_add(size=60, location=(x / 2, 0, 0))
bpy.context.active_object.data.materials.append(vc_mat("floor", color=(0.35, 0.33, 0.3), strength=0.0))
bpy.ops.object.light_add(type="SUN", rotation=(math.radians(50), 0, math.radians(-30)))
bpy.context.active_object.data.energy = 3.5
w = x - 1.5
camera((w / 2, -4.2 - w * 0.55, 2.6), (w / 2, 0, 0.9), lens=40)
scn = bpy.context.scene
scn.render.resolution_x, scn.render.resolution_y = 1600, 800
scn.render.filepath = out
bpy.ops.render.render(write_still=True)
