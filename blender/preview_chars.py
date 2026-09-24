# Planche de contrôle : tous les personnages côte à côte -> captures/chars.png
import bpy, os, math, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from render_art import setup, clear, vc_mat, camera

ASSETS = r"G:\Mes APP\Delve\assets"
setup()
clear()
x = 0.0
for key, w in (("garde", 1.4), ("lame", 1.2), ("oracle", 1.4), ("artificier", 1.4), ("moine", 1.3), ("trappeur", 1.3), ("tidiane", 1.3)):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(ASSETS, "u_%s.glb" % key))
    root = bpy.data.objects.new("r_" + key, None)
    bpy.context.scene.collection.objects.link(root)
    for o in set(bpy.data.objects) - before:
        if o.type == "MESH":
            o.data.materials.clear()
            o.data.materials.append(vc_mat("vcg" if "glow" in o.name else "vc", glow="glow" in o.name))
        if o.parent is None and o is not root:
            o.parent = root
    x += w * 0.5
    root.location = (x, 0, 0)
    root.rotation_euler = (0, 0, math.radians(-25))
    x += w * 0.5
bpy.ops.mesh.primitive_plane_add(size=40, location=(x / 2, 0, 0))
bpy.context.active_object.data.materials.append(vc_mat("floor", color=(0.35, 0.33, 0.3), strength=0.0))
bpy.ops.object.light_add(type="SUN", rotation=(math.radians(50), 0, math.radians(-30)))
bpy.context.active_object.data.energy = 3.5
camera((x / 2, -15, 3.0), (x / 2, 0, 1.4), lens=34)
scn = bpy.context.scene
scn.render.resolution_x, scn.render.resolution_y = 1600, 600
scn.render.filepath = r"G:\Mes APP\Delve\captures\chars.png"
bpy.ops.render.render(write_still=True)
