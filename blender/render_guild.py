# Illustrations des cartes de guilde : les deux héros de la paire ensemble, devant un fond aux deux couleurs.
# blender -b --factory-startup -P render_guild.py [-- --only=g_etau,...]  ->  assets/art/card_g_*.png
# Les légendaires (rar 4) sont peintes à part (planches KIE) : on ne les rend pas ici.
import bpy, os, re, sys, math, random
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import render_art as ra

GUILDES = os.path.join(os.path.dirname(ra.ASSETS), "scripts", "guildes.gd")


def guild_cards():
    src = open(GUILDES, encoding="utf8").read()
    pairs = re.findall(r'^\t\["(\w+)", "(\w+)", "', src, re.M)
    out = []
    for cid, g, rar, kind in re.findall(r'^\t"(g_\w+)": \{"name": "[^"]*", "g": (\d+), "rar": (\d), (?:"voix": "\w", )?"cost": \d, "kind": "(\w+)"', src, re.M):
        a, b = pairs[int(g)]
        out.append((cid, a, b, int(rar), kind))
    return out


def backdrop2(ca, cb):
    ## Fond coupé en deux : la couleur de chaque classe d'un côté, la nuit au milieu.
    bpy.ops.mesh.primitive_plane_add(size=9, location=(0, 2.6, 1.0), rotation=(math.pi / 2, 0, 0))
    p = bpy.context.active_object
    m = bpy.data.materials.new("bd2")
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    els = ramp.color_ramp.elements
    els[0].position = 0.28
    els[0].color = (cb[0] * 1.3, cb[1] * 1.3, cb[2] * 1.3, 1)
    els[1].position = 0.72
    els[1].color = (ca[0] * 1.3, ca[1] * 1.3, ca[2] * 1.3, 1)
    mid = els.new(0.5)
    mid.color = (0.02, 0.016, 0.022, 1)
    nt.links.new(tc.outputs["Generated"], sep.inputs["Vector"])
    nt.links.new(sep.outputs["X"], ramp.inputs["Fac"])
    # vignette : un halo au centre, les bords dans la nuit
    mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Location"].default_value = (-0.5, -0.45, 0)
    mp.inputs["Scale"].default_value = (1.6, 1.6, 1)
    gr = nt.nodes.new("ShaderNodeTexGradient")
    gr.gradient_type = "SPHERICAL"
    mul = nt.nodes.new("ShaderNodeMixRGB")
    mul.blend_type = "MULTIPLY"
    mul.inputs["Fac"].default_value = 1.0
    nt.links.new(tc.outputs["Generated"], mp.inputs["Vector"])
    nt.links.new(mp.outputs["Vector"], gr.inputs["Vector"])
    nt.links.new(ramp.outputs["Color"], mul.inputs["Color1"])
    nt.links.new(gr.outputs["Color"], mul.inputs["Color2"])
    nt.links.new(mul.outputs["Color"], em.inputs["Color"])
    em.inputs["Strength"].default_value = 1.0
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    p.data.materials.append(m)


def effect(cid, kind, rar, ca, cb):
    R = random.Random(sum(map(ord, cid)))
    mix = tuple(min(1.0, (x + y) * 0.55) for x, y in zip(ca, cb))
    n = 1.0 + 0.5 * (rar - 1)  # plus rare, plus d'éclat
    if kind == "atk":
        # deux arcs qui se croisent : les deux classes frappent ensemble
        for side, col in ((1, ca), (-1, cb)):
            pts = []
            for i in range(int(70 * n)):
                t = i / (70 * n)
                a = math.radians(200 - t * 150) if side > 0 else math.radians(-20 + t * 150)
                pts.append((math.cos(a) * 1.0 * side * -1 + side * 0.1, -0.6, 1.0 + math.sin(a) * 0.9, 1.5 * (1 - abs(t - 0.5)) + 0.3))
            ra.cubes(pts, 0.06, col, 1.8)
        ra.cubes([(R.uniform(-0.3, 0.3), -0.65, 1.0 + R.uniform(-0.3, 0.3), R.uniform(0.3, 0.9)) for _ in range(int(18 * n))], 0.06, mix, 2.0)
    elif kind == "power":
        pts = [(math.cos(a * 0.28) * (0.25 + a * 0.01), 0.35 + math.sin(a * 0.28) * 0.25, 0.1 + a * 0.028, 1.1) for a in range(int(80 * n))]
        ra.cubes(pts, 0.06, mix, 3.4)
        bpy.ops.object.light_add(type="POINT", location=(0, 0.2, 1.6))
        pl = bpy.context.active_object
        pl.data.energy = 160
        pl.data.color = mix
    else:
        pts = [(math.cos(i / 80 * math.tau) * 1.15, math.sin(i / 80 * math.tau) * 0.5, 0.06, 1.0) for i in range(80)]
        pts += [(R.uniform(-1.1, 1.1), R.uniform(-0.4, 0.4), R.uniform(0.2, 2.0), R.uniform(0.3, 0.9)) for _ in range(int(40 * n))]
        ra.cubes(pts, 0.05, mix, 1.8)


def run():
    only = next((a.split("=", 1)[1].split(",") for a in sys.argv if a.startswith("--only=")), None)
    ra.setup()
    done = 0
    for i, (cid, a, b, rar, kind) in enumerate(guild_cards()):
        if rar == 4 or (only and cid not in only):
            continue
        ra.clear()
        ca, cb = ra.CLASS[a], ra.CLASS[b]
        backdrop2(ca, cb)
        ha = ra.load_hero(a)
        ha.location = (0.62, 0.05, 0)
        ha.rotation_euler = (0, 0, math.radians(-30 + (i * 13) % 24))
        hb = ra.load_hero(b)
        hb.location = (-0.62, 0.05, 0)
        hb.rotation_euler = (0, 0, math.radians(30 - (i * 7) % 24))
        effect(cid, kind, rar, ca, cb)
        ra.light_rig(tuple((x + y) / 2 for x, y in zip(ca, cb)))
        cx = ((i * 37) % 9 - 4) * 0.12  # cadrages variés d'une carte à l'autre
        ra.camera((cx, -3.9, 0.45 + (i % 3) * 0.2), (cx * 0.3, 0, 1.0), lens=36 + (i % 4) * 3)
        ra.render(os.path.join(ra.ART, "card_%s.png" % cid), 336, 224)
        done += 1
    print("guildes ok", done)


if __name__ == "__main__":
    run()
