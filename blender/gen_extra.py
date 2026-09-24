# Objets posés par les héros (baril, tourelle, piège), sans regénérer tout le décor.
# blender -b --factory-startup -P gen_extra.py
import bpy, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_assets as G

FLAT = dict(origin=(8, 8, 0), skip=((0, 0, -1),))
for o in list(G.coll().objects):
    bpy.data.objects.remove(o, do_unlink=True)
kit = []
vox, g = G.barrel(564)
kit.append(("prop_baril", vox, g, FLAT))
vox, g = G.turret(565)
kit.append(("prop_tourelle", vox, g, FLAT))
kit.append(("prop_piege", G.jaw_trap(566), None, FLAT))
def caltrops(seed):
    """Picots : des chausse-trapes de fer semées en grappe."""
    R = G.random.Random(seed)
    vox = {}
    IRON = G.pal(["#4a4642", "#3a3734", "#5a554f"])
    for _ in range(10):
        cx, cy = R.randint(2, 13), R.randint(2, 13)
        for d in ((0, 0, 0), (1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1)):
            vox[(cx + d[0], cy + d[1], d[2])] = G.pick(R, IRON)
        vox[(cx, cy, 2)] = G.lin("#c9c2b4")
    return vox


def sack(seed):
    """Sac de butin lâché par un ennemi : toile nouée, pièces qui débordent."""
    R = G.random.Random(seed)
    vox, glow = {}, {}
    CL = G.pal(["#8a6a44", "#7a5a38", "#9a7a50"])
    for x in range(16):
        for y in range(16):
            for z in range(0, 11):
                if ((x - 7.5) / 4.6) ** 2 + ((y - 7.5) / 4.2) ** 2 + ((z - 4.5) / 5.2) ** 2 <= 1:
                    vox[(x, y, z)] = G.pick(R, CL)
    for z in (10, 11):
        for x in range(6, 10):
            for y in range(6, 10):
                vox[(x, y, z)] = G.lin("#5b4130")
    for x in range(5, 11):
        for y in range(5, 11):
            if G.math.hypot(x - 7.5, y - 7.5) < 2.8:
                vox[(x, y, 12)] = G.pick(R, CL)
    for q in ((12, 7, 0), (12, 8, 0), (13, 8, 0), (3, 9, 0), (11, 11, 0), (12, 10, 1)):
        glow[q] = (1.0, 0.8, 0.3)
    return vox, glow


kit.append(("prop_picots", caltrops(567), None, FLAT))
vox, g = sack(568)
kit.append(("prop_sac", vox, g, FLAT))
for i in range(2):
    vox, g = G.crystal(700 + i)
    kit.append(("crystal_%d" % i, vox, g, dict(origin=(8, 8, 0))))
vox, g = G.crystal(710, True)
kit.append(("crystal_giant", vox, g, dict(origin=(8, 8, 0))))
G.emit(kit)
print("extra ok")
