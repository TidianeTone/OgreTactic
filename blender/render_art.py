# Illustrations de cartes et portraits : le modèle voxel du héros devant un emblème lumineux.
# blender -b --factory-startup -P render_art.py  ->  assets/art/card_<id>.png, portrait_<héros>.png
import bpy, os, math, sys

ASSETS = r"G:\Mes APP\Delve\assets"
ART = os.path.join(ASSETS, "art")
os.makedirs(ART, exist_ok=True)

CLASS = {"garde": (0.24, 0.39, 0.88), "lame": (0.88, 0.2, 0.31), "oracle": (0.61, 0.31, 0.85),
         "artificier": (0.13, 0.72, 0.65), "moine": (0.42, 0.76, 0.29), "trappeur": (0.79, 0.64, 0.23),
         "tidiane": (0.82, 0.25, 0.6), "receleur": (0.62, 0.71, 0.76)}

ICONS = {
    "bag": ["....####....", "...##..##...", "....####....", "..########..", ".##########.", "############",
            "#####..#####", "#####..#####", "############", "############", ".##########.", "..########.."],
    "key": ["...####.....", "..##..##....", "..##..##....", "...####.....", "....##......", "....##......",
            "....####....", "....##......", "....###.....", "....##......", "....####....", "............"],
    "sword": ["..........##", ".........###", "........###.", ".......###..", "......###...", ".....###....",
              "#...###.....", "##.###......", ".####.......", "..##........", ".####.......", "##..#......."],
    "shield": [".##########.", "############", "###......###", "###.####.###", "###.####.###", "###......###",
               ".###....###.", ".####..####.", "..########..", "...######...", "....####....", ".....##....."],
    "chevron": ["#.....#.....", "##....##....", ".##....##...", "..##....##..", "...##....##.", "....##....##",
                "....##....##", "...##....##.", "..##....##..", ".##....##...", "##....##....", "#.....#....."],
    "flag": ["##..........", "##########..", "#########...", "##########..", "#########...", "##..........",
             "##..........", "##..........", "##..........", "##..........", "##..........", "####........"],
    "castle": ["##.##..##.##", "############", "############", "############", "####....####", "###......###",
               "###......###", "###......###", "###......###", "############", "............", "............"],
    "hammer": ["..########..", "..########..", "..########..", "..########..", ".....##.....", ".....##.....",
               ".....##.....", ".....##.....", ".....##.....", ".....##.....", ".....##.....", "....####...."],
    "dagger": [".....#......", ".....##.....", ".....##.....", ".....##.....", ".....##.....", ".....##.....",
               ".....##.....", "...######...", ".....##.....", ".....##.....", "....####....", "............"],
    "moon": ["....####....", "..######....", ".#####......", ".####.......", "####........", "####........",
             "####........", "####........", ".####.......", ".#####......", "..######....", "....####...."],
    "cross2": ["#..........#", "##........##", ".##......##.", "..##....##..", "...##..##...", "....####....",
               "....####....", "...##..##...", "..##....##..", "####....####", "##........##", "#..........#"],
    "drop": [".....##.....", ".....##.....", "....####....", "....####....", "...######...", "..########..",
             "..########..", ".##########.", ".##########.", ".##########.", "..########..", "....####...."],
    "cleaver": ["....########", "...#########", "..##########", "..##########", "..#########.", "...######...",
                "....##......", "...##.......", "..##........", ".##.........", "##..........", "#..........."],
    "bolt": [".......####.", "......####..", ".....####...", "....####....", "...########.", "..########..",
             ".....####...", "....####....", "...####.....", "..###.......", ".##.........", "#..........."],
    "flame": [".....#......", ".....##.....", "....###.....", "....####....", "...#####.#..", "..#######.#.",
              "..########..", ".####.#####.", ".###...####.", ".###...###..", "..###.###...", "...#####...."],
    "cross": ["....####....", "....####....", "....####....", "....####....", "############", "############",
              "############", "############", "....####....", "....####....", "....####....", "....####...."],
    "burst": [".....##.....", "..#..##..#..", "...#.##.#...", "....####....", "..########..", "############",
              "############", "..########..", "....####....", "...#.##.#...", "..#..##..#..", ".....##....."],
    "wave": ["............", "...###......", "..#####.....", ".##...##...#", "##.....##.##", "#.......###.",
             "............", "...###......", "..#####.....", ".##...##...#", "##.....##.##", "#.......###."],
    "eye": ["............", "....####....", "..########..", ".###....###.", "###..##..###", "##..####..##",
            "##..####..##", "###..##..###", ".###....###.", "..########..", "....####....", "............"],
    "pick": ["..########..", ".##########.", "##...##...##", "#....##....#", ".....##.....", ".....##.....",
             ".....##.....", ".....##.....", ".....##.....", ".....##.....", ".....##.....", ".....##....."],
    "bomb": ["........##..", ".......#..#.", "......#.....", "....####....", "..########..", ".##########.",
             ".##########.", "############", "############", ".##########.", "..########..", "....####...."],
    "barrel": ["..########..", ".##########.", "############", "############", ".##########.", "############",
               "############", ".##########.", "############", "############", ".##########.", "..########.."],
    "gear": ["....####....", ".##.####.##.", ".##########.", "..###..###..", "####....####", "###......###",
             "###......###", "####....####", "..###..###..", ".##########.", ".##.####.##.", "....####...."],
    "tower": ["#.##..##.#..", "##########..", ".########...", "..######....", "..######...#", "..#######.##",
              "..########..", "..######....", "..######....", ".########...", "##########..", "##########.."],
    "fist": ["..##.##.##..", ".##########.", ".##########.", ".##########.", "###########.", "############",
             "############", ".##########.", "..########..", "..########..", "..########..", "..########.."],
    "spiral": ["...######...", "..##....##..", ".##......##.", "##...###..##", "#...##.##..#", "#..##...#..#",
               "#..#..#.#..#", "#..#.##.#..#", "##..##..#.##", ".##....##.#.", "..######.##.", "..........#."],
    "arrow": ["........####", ".........###", "........####", ".......###.#", "......###...", ".....###....",
              "....###.....", "...###......", "#.###.......", "####........", ".##.........", "#.#........."],
    "trap": ["#.#.#..#.#.#", "############", "##........##", "#..........#", "#....##....#", "#...####...#",
             "#...####...#", "#....##....#", "#..........#", "##........##", "############", "#.#.#..#.#.#"],
    "target": ["....####....", "..##....##..", ".#........#.", ".#..####..#.", "#..#....#..#", "#..#.##.#..#",
               "#..#.##.#..#", "#..#....#..#", ".#..####..#.", ".#........#.", "..##....##..", "....####...."],
    "net": ["#..#..#..#..", ".##.##.##.##", ".##.##.##.##", "#..#..#..#..", "#..#..#..#..", ".##.##.##.##",
            ".##.##.##.##", "#..#..#..#..", "#..#..#..#..", ".##.##.##.##", ".##.##.##.##", "#..#..#..#.."],
    "hook": ["....####....", "...##..##...", "...##..##...", "....####....", ".....##.....", ".....##.....",
             ".....##.....", "#....##....#", "##...##...##", ".##..##..##.", "..########..", "...######..."],
    "rings": ["....####....", "..##....##..", ".#..####..#.", "#..#....#..#", "#.#..##..#.#", "#.#.#..#.#.#",
              "#.#.#..#.#.#", "#.#..##..#.#", "#..#....#..#", ".#..####..#.", "..##....##..", "....####...."],
    "brush": ["..........##", ".........###", "........###.", ".......###..", "......###...", ".....###....",
              "....###.....", "..####......", ".#####......", "######......", "#####.......", ".##........."],
    "book": ["............", ".####..####.", "#....##....#", "#.##.##.##.#", "#....##....#", "#.##.##.##.#",
             "#....##....#", "#.##.##.##.#", "#....##....#", ".####..####.", "......##....", "............"],
    "note": [".....#######", ".....#######", ".....##...##", ".....##...##", ".....##...##", ".....##...##",
             ".....##...##", "..####..####", ".#####.#####", ".#####.#####", "..###...###.", "............"],
    "gem": ["...######...", "..#.#..#.#..", ".#..#..#..#.", "############", ".#...##...#.", "..#..##..#..",
            "...#.##.#...", "....####....", ".....##.....", "............", "............", "............"],
    "flower": [".....##.....", "....####....", ".##.####.##.", "####.##.####", ".####..####.", "..###..###..",
               "#..######..#", "##.######.##", ".##########.", "..########..", "....####....", "............"],
}

CARDS = {
    "frappe": ("garde", "sword"), "pavois": ("garde", "shield"), "charge": ("garde", "chevron"), "defi": ("garde", "flag"),
    "rempart": ("garde", "castle"), "marteau": ("garde", "hammer"), "bastion": ("garde", "shield"),
    "estoc": ("lame", "dagger"), "ombre": ("lame", "moon"), "double": ("lame", "cross2"), "venin": ("lame", "drop"),
    "couperet": ("lame", "cleaver"), "ricochet": ("lame", "bolt"),
    "braise": ("oracle", "flame"), "seve": ("oracle", "cross"), "colonne": ("oracle", "burst"), "maree": ("oracle", "wave"),
    "surveil": ("oracle", "eye"), "delve": ("oracle", "pick"), "lotus": ("oracle", "flower"),
    "bouclier": ("garde", "shield"), "crochet": ("garde", "hook"), "forteresse": ("garde", "castle"),
    "fente": ("lame", "chevron"), "embuscade": ("lame", "moon"), "coupures": ("lame", "cross2"),
    "arc": ("oracle", "bolt"), "echo": ("oracle", "rings"), "cendres": ("oracle", "flame"),
    "grenade": ("artificier", "bomb"), "baril": ("artificier", "barrel"), "etincelle": ("artificier", "burst"),
    "rivet": ("artificier", "hammer"), "tourelle": ("artificier", "tower"), "surcharge": ("artificier", "bolt"),
    "mortier": ("artificier", "bomb"), "atelier": ("artificier", "gear"),
    "paume": ("moine", "fist"), "poing": ("moine", "fist"), "tourbillon": ("moine", "spiral"), "bond": ("moine", "chevron"),
    "souffle": ("moine", "flower"), "ressac": ("moine", "wave"), "cent": ("moine", "burst"), "voie": ("moine", "spiral"),
    "fleche": ("trappeur", "arrow"), "piege": ("trappeur", "trap"), "marque": ("trappeur", "target"), "filet": ("trappeur", "net"),
    "pluie": ("trappeur", "arrow"), "harpon": ("trappeur", "hook"), "perforant": ("trappeur", "arrow"), "instinct": ("trappeur", "eye"),
    "esquisse": ("tidiane", "brush"), "recul": ("tidiane", "shield"), "journal": ("tidiane", "book"), "pacte": ("tidiane", "cleaver"),
    "arbo": ("tidiane", "flower"), "wavedash": ("tidiane", "chevron"), "punchline": ("tidiane", "fist"), "truecombo": ("tidiane", "cross2"),
    "monster": ("tidiane", "bolt"), "nuit": ("tidiane", "moon"), "transmutation": ("tidiane", "drop"), "dette": ("tidiane", "dagger"),
    "dsm": ("tidiane", "eye"), "contreanalyse": ("tidiane", "target"), "troisvoix": ("tidiane", "wave"), "break174": ("tidiane", "note"),
    "purerage": ("tidiane", "burst"), "potentiel": ("tidiane", "gem"), "revelation": ("tidiane", "brush"), "hyperfocus": ("tidiane", "target"),
    "dnb": ("tidiane", "note"), "obsession": ("tidiane", "spiral"),
    "larcin": ("receleur", "bag"), "cle": ("receleur", "gear"), "bricolage": ("receleur", "gear"), "camelote": ("receleur", "bag"),
    "crochetage": ("receleur", "key"), "recyclage": ("receleur", "spiral"), "contrefacon": ("receleur", "rings"),
    "coupdesac": ("receleur", "bag"), "etal": ("receleur", "gem"), "lecasse": ("receleur", "key"),
    "marchenoir": ("receleur", "gem"), "poches": ("receleur", "bag"),
}


MELEE = {"larcin", "cle", "coupdesac", "lecasse", "pacte", "wavedash", "punchline", "truecombo", "dette", "break174", "purerage", "potentiel", "frappe", "charge", "marteau", "estoc", "double", "couperet", "venin", "fente", "rivet", "paume", "poing", "ressac", "cent"}
RANGED = {"camelote", "crochetage", "esquisse", "transmutation", "dsm", "contreanalyse", "troisvoix", "braise", "ricochet", "colonne", "delve", "maree", "bouclier", "crochet", "arc", "grenade", "mortier", "etincelle",
          "fleche", "marque", "filet", "pluie", "harpon", "perforant"}


def cubes(points, size, col, strength):
    """Nuée de petits cubes lumineux : traînées, projectiles, auras."""
    verts, faces = [], []
    for (x, y, z, k) in points:
        h = size * k / 2
        base = len(verts)
        for dx in (-h, h):
            for dy in (-h, h):
                for dz in (-h, h):
                    verts.append((x + dx, y + dy, z + dz))
        for f in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
            faces.append(tuple(base + i for i in f))
    me = bpy.data.meshes.new("fx")
    me.from_pydata(verts, [], faces)
    ob = bpy.data.objects.new("fx", me)
    bpy.context.scene.collection.objects.link(ob)
    ob.data.materials.append(vc_mat("fx_%s_%s" % (str(col), strength), color=col, strength=strength))
    return ob


def moment(cid, col, root):
    """Le geste de la carte : traînée d'arme, projectile ou aura."""
    import random
    R = random.Random(hash(cid) & 0xffff)
    light = (1.0, 0.45, 0.12) if cid in ("braise", "colonne", "delve", "grenade", "mortier", "etincelle", "baril", "cendres") else tuple(min(1.0, c * 1.1 + 0.05) for c in col)
    hero = (0.55, 0.0, 1.0)
    if cid in MELEE:
        for o in root.children_recursive:
            if o.name.endswith("_weapon"):
                o.rotation_euler = (math.radians(-75), 0, 0)
        pts = []
        for i in range(90):
            a = math.radians(15 + i * 1.6)
            r = 0.95 + R.uniform(-0.08, 0.08)
            k = 1.6 * (1 - abs(i - 45) / 50)
            pts.append((hero[0] - 0.2 + math.cos(a) * r, -0.55, hero[2] - 0.1 + math.sin(a) * r * 0.9, max(0.3, k)))
        cubes(pts, 0.06, light, 2.6)
    elif cid in RANGED:
        c0 = (-0.55, -0.5, 1.25)
        pts = [(c0[0] + R.uniform(-0.2, 0.2), c0[1], c0[2] + R.uniform(-0.2, 0.2), 1.6) for _ in range(40)]
        for i in range(40):
            t = i / 40
            pts.append((c0[0] + t * 1.0, c0[1] + t * 0.3, c0[2] - t * 0.15 + R.uniform(-0.06, 0.06), 1.2 * (1 - t) + 0.2))
        cubes(pts, 0.07, light, 3.2)
        bpy.ops.object.light_add(type="POINT", location=c0)
        pl = bpy.context.active_object
        pl.data.energy = 120
        pl.data.color = light
    else:
        pts = []
        for i in range(70):
            a = i / 70 * math.tau
            pts.append((hero[0] + math.cos(a) * 0.75, math.sin(a) * 0.45, 0.08 + R.uniform(0, 0.05), 1.0))
        for i in range(40):
            a = R.uniform(0, math.tau)
            r = R.uniform(0.3, 0.8)
            pts.append((hero[0] + math.cos(a) * r, math.sin(a) * r * 0.6, R.uniform(0.2, 1.9), R.uniform(0.3, 0.9)))
        cubes(pts, 0.05, light, 2.4)


PROPS = {"baril": ["prop_baril"], "etincelle": ["prop_baril"], "atelier": ["prop_tourelle", "prop_baril"],
         "tourelle": ["prop_tourelle"], "piege": ["prop_piege"], "instinct": ["prop_piege"]}


def load_prop(name, loc, scale=1.6):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(ASSETS, name + ".glb"))
    for o in [o for o in bpy.data.objects if o not in before]:
        if o.type == "MESH":
            o.data.materials.clear()
            o.data.materials.append(vc_mat("vc_glow" if "glow" in o.name else "vc", glow="glow" in o.name))
        if o.parent is None:
            o.location = loc
            o.scale = (scale, scale, scale)


def signature(cid, col):
    """L'objet ou la forme propre à la mécanique, devant le héros."""
    import random
    R = random.Random(hash(cid) & 0xfff)
    for i, name in enumerate(PROPS.get(cid, [])):
        load_prop(name, (-0.55 - i * 0.7, -0.35 + i * 0.3, 0.0))
    if cid == "etincelle":
        cubes([(-0.55 + R.uniform(-0.4, 0.4), -0.35, 0.7 + R.uniform(0, 0.8), R.uniform(0.6, 1.6)) for _ in range(60)], 0.06, (1.0, 0.5, 0.15), 4.0)
    if cid in ("grenade", "mortier"):
        pts = [(-1.1 + t * 0.03, -0.4, 0.4 + math.sin(t / 40 * math.pi) * 1.3, 0.8) for t in range(40)]
        pts += [(-0.2 + R.uniform(-0.35, 0.35), -0.4, 0.2 + R.uniform(0, 0.5), R.uniform(0.8, 2.0)) for _ in range(50)]
        cubes(pts, 0.07, (1.0, 0.55, 0.2), 3.5)
    if cid in ("harpon", "crochet"):
        cubes([(-1.3 + t * 0.04, -0.5, 1.0 - t * 0.004, 0.9 if t % 3 else 1.4) for t in range(40)], 0.05, (0.85, 0.85, 0.8), 1.2)
    if cid == "marque":
        cubes([(-0.6 + math.cos(a / 40 * math.tau) * 0.45, -0.3 + math.sin(a / 40 * math.tau) * 0.3, 0.05, 1.0) for a in range(40)], 0.06, (1.0, 0.25, 0.2), 4.0)
    if cid == "filet":
        cubes([(-0.9 + x * 0.12, -0.4, 0.3 + y * 0.12, 0.7) for x in range(8) for y in range(7) if (x + y) % 2 == 0], 0.05, (0.9, 0.85, 0.7), 1.0)
    if cid in ("tourbillon", "voie"):
        cubes([(0.55 + math.cos(a * 0.3) * (0.3 + a * 0.012), math.sin(a * 0.3) * (0.3 + a * 0.012) * 0.6, 0.2 + a * 0.02, 1.0) for a in range(70)], 0.05, (0.6, 1.0, 0.5), 3.0)


def clear():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)


def setup():
    scn = bpy.context.scene
    for eng in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            scn.render.engine = eng
            break
        except TypeError:
            continue
    scn.render.film_transparent = False
    try:
        scn.view_settings.view_transform = "AgX"
        scn.view_settings.look = "AgX - Punchy"
    except TypeError:
        pass
    try:
        scn.eevee.taa_render_samples = 48
    except AttributeError:
        pass
    w = bpy.data.worlds.new("DelveArt")
    try:
        w.use_nodes = True
    except Exception:
        pass
    bg = w.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (0.012, 0.01, 0.014, 1)
    bg.inputs["Strength"].default_value = 1.0
    scn.world = w
    return scn


def vc_mat(name, glow=False, color=None, strength=4.0):
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    try:
        m.use_nodes = True
    except Exception:
        pass
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 0.8
    if color:
        bsdf.inputs["Base Color"].default_value = (*color, 1)
        bsdf.inputs["Emission Color"].default_value = (*color, 1)
        bsdf.inputs["Emission Strength"].default_value = strength
        return m
    ca = nt.nodes.new("ShaderNodeVertexColor")
    nt.links.new(ca.outputs["Color"], bsdf.inputs["Base Color"])
    if glow:
        nt.links.new(ca.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 8.0
    return m


def backdrop(col):
    bpy.ops.mesh.primitive_plane_add(size=9, location=(0, 2.6, 1.0), rotation=(math.pi / 2, 0, 0))
    p = bpy.context.active_object
    m = bpy.data.materials.new("bd")
    try:
        m.use_nodes = True
    except Exception:
        pass
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    tc = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Location"].default_value = (-0.62, -0.5, 0)
    mp.inputs["Scale"].default_value = (1.8, 1.8, 1)
    gr = nt.nodes.new("ShaderNodeTexGradient")
    gr.gradient_type = "SPHERICAL"
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (0.01, 0.008, 0.012, 1)
    ramp.color_ramp.elements[1].color = (col[0] * 1.3, col[1] * 1.3, col[2] * 1.3, 1)
    e = ramp.color_ramp.elements.new(0.55)
    e.color = (col[0] * 0.35, col[1] * 0.35, col[2] * 0.35, 1)
    nt.links.new(tc.outputs["Generated"], mp.inputs["Vector"])
    nt.links.new(mp.outputs["Vector"], gr.inputs["Vector"])
    nt.links.new(gr.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], em.inputs["Color"])
    em.inputs["Strength"].default_value = 1.0
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    p.data.materials.append(m)
    return p


def emblem(rows, col):
    verts, faces = [], []
    s = 0.13
    for r, line in enumerate(rows):
        for c, ch in enumerate(line):
            if ch != "#":
                continue
            x0, z0 = (c - 6) * s, (11 - r - 6) * s
            base = len(verts)
            for dx in (0, s):
                for dy in (0, s * 1.5):
                    for dz in (0, s):
                        verts.append((x0 + dx, dy, z0 + dz))
            for f in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
                faces.append(tuple(base + i for i in f))
    me = bpy.data.meshes.new("emblem")
    me.from_pydata(verts, [], faces)
    ob = bpy.data.objects.new("emblem", me)
    bpy.context.scene.collection.objects.link(ob)
    ob.data.materials.append(vc_mat("emb_%s" % str(col), color=tuple(min(1.0, c * 1.15 + 0.06) for c in col), strength=1.4))
    ob.location = (-0.75, 1.1, 1.0)
    ob.rotation_euler = (0, 0, math.radians(-12))
    return ob


def load_hero(key):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(ASSETS, "u_%s.glb" % key))
    objs = [o for o in bpy.data.objects if o not in before]
    root = bpy.data.objects.new("hero_root", None)
    bpy.context.scene.collection.objects.link(root)
    for o in objs:
        if o.type == "MESH":
            o.data.materials.clear()
            o.data.materials.append(vc_mat("vc_glow" if "glow" in o.name else "vc", glow="glow" in o.name))
        if o.parent is None:
            o.parent = root
    return root


def light_rig(col):
    bpy.ops.object.light_add(type="SUN", rotation=(math.radians(55), math.radians(10), math.radians(-35)))
    sun = bpy.context.active_object
    sun.data.energy = 3.2
    sun.data.color = (1.0, 0.86, 0.7)
    bpy.ops.object.light_add(type="AREA", location=(0.6, 1.8, 2.4))
    rim = bpy.context.active_object
    rim.data.energy = 320
    rim.data.size = 2.5
    rim.data.color = tuple(min(1.0, c * 1.4 + 0.2) for c in col)
    rim.rotation_euler = (math.radians(-60), 0, 0)
    rim.rotation_euler = (math.radians(120), 0, math.radians(180))


def camera(loc, look, lens=50):
    bpy.ops.object.camera_add(location=loc)
    cam = bpy.context.active_object
    cam.data.lens = lens
    t = bpy.data.objects.new("look", None)
    bpy.context.scene.collection.objects.link(t)
    t.location = look
    c = cam.constraints.new("TRACK_TO")
    c.target = t
    c.track_axis = "TRACK_NEGATIVE_Z"
    c.up_axis = "UP_Y"
    bpy.context.scene.camera = cam
    return cam


def render(path, w, h):
    scn = bpy.context.scene
    scn.render.resolution_x = w
    scn.render.resolution_y = h
    scn.render.resolution_percentage = 100
    scn.render.filepath = path
    bpy.ops.render.render(write_still=True)


def run():
    scn = setup()
    only_new = "--new" in sys.argv
    only = next((a.split("=", 1)[1].split(",") for a in sys.argv if a.startswith("--only=")), None)
    for i, (cid, (owner, icon)) in enumerate(CARDS.items()):
        if only_new and os.path.exists(os.path.join(ART, "card_%s.png" % cid)):
            continue
        if only is not None and cid not in only:
            continue
        clear()
        col = CLASS[owner]
        backdrop(col)
        em = emblem(ICONS[icon], col)
        em.scale = (0.32, 0.32, 0.32)
        em.location = (-1.25, -0.6, 1.72)
        root = load_hero(owner)
        root.location = (0.55, 0, 0)
        root.rotation_euler = (0, 0, math.radians(-38 + (i * 17) % 40))
        moment(cid, col, root)
        signature(cid, col)
        light_rig(col)
        camera((0.15, -3.6, 0.55), (0.0, 0, 1.0), lens=38)
        render(os.path.join(ART, "card_%s.png" % cid), 336, 224)
    for owner, col in CLASS.items():
        clear()
        backdrop(col)
        root = load_hero(owner)
        root.rotation_euler = (0, 0, math.radians(-20))
        light_rig(col)
        camera((0.35, -2.2, 1.55), (0.0, 0, 1.12), lens=60)
        render(os.path.join(ART, "portrait_%s.png" % owner), 192, 192)
    print("art ok", len(os.listdir(ART)))


if __name__ == "__main__":
    run()
