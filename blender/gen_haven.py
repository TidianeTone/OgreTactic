# Lieux de repos : l'étal du marchand, le feu de camp, le kiosque sur l'eau, la fontaine à vasques.
# D'après les références de la bibliothèque visuelle : cour mauresque au bassin, temple rond sur le lac
# parmi les statues, marché sous auvents rayés, fontaine baroque sous les feuillages d'automne.
# blender -b --factory-startup -P gen_haven.py
import bpy, os, sys, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_assets as G

P = G.pal
R0 = random.Random
STONE = P(["#e2d6c0", "#d4c6ae", "#eadfcb", "#c9baa0"])
GOLD = P(["#e6b84f", "#f0c860", "#d4a040"])
WOOD = P(["#6a4a32", "#5a3d27", "#7a5638"])
WATER = P(["#6fd0cc", "#7cdcd4", "#5dc0c0"])
AWN_A = P(["#e8a040", "#f0b050"])     # ambre
AWN_B = P(["#c8506a", "#d8607a"])     # rose
JARS = P(["#b8643a", "#c87848", "#9a5030", "#3f8a8a", "#d8c098"])
RUG = P(["#8a2a3a", "#a83a48", "#e3b45c", "#2a4a6a"])


def stall(seed):
    """Étal : comptoir de bois, jarres et tapis roulés, auvent rayé ambre et rose sur quatre perches."""
    R = R0(seed)
    vox, glow = {}, {}
    W, D = 32, 16
    for x in range(2, W - 2):
        for y in range(4, 10):
            for z in range(0, 11):
                edge = z >= 9 or y in (4, 9) or x in (2, W - 3)
                vox[(x, y, z)] = G.pick(R, WOOD, 1.0 if edge else 0.8, 1.1)
    for x in range(1, W - 1):  # plateau
        for y in range(3, 11):
            vox[(x, y, 11)] = G.pick(R, WOOD, 1.05, 1.2)
    # jarres, fioles et pièces sur le comptoir
    for i in range(7):
        cx = 4 + i * 4 + R.randint(-1, 0)
        cy = R.randint(5, 8)
        h = R.randint(3, 6)
        col = R.choice(JARS)
        for z in range(12, 12 + h):
            r = 1.6 if 12 < z < 11 + h else 1.1
            for x in range(-2, 3):
                for y in range(-2, 3):
                    if x * x + y * y <= r * r + 0.5:
                        vox[(cx + x, cy + y, z)] = G.tone(col, R.uniform(0.9, 1.1))
        if i % 3 == 1:
            glow[(cx, cy, 12 + h)] = P(["#7ff0e0"])[0]
    for x in range(20, 27):
        glow[(x, 9, 12)] = GOLD[0]
    # perches
    for px, py in ((1, 2), (W - 2, 2), (1, D - 1), (W - 2, D - 1)):
        for z in range(0, 30):
            vox[(px, py, z)] = G.pick(R, WOOD)
    # auvent rayé, légèrement bombé et incliné vers l'avant
    for x in range(-1, W + 1):
        for y in range(0, D + 2):
            z = 29 + int(2 * math.sin(math.pi * (x + 1) / (W + 2))) + (y // 6)
            vox[(x, y, z)] = G.pick(R, AWN_A if (x // 4) % 2 == 0 else AWN_B, 0.95, 1.08)
            if y == 0 and x % 4 == 1:
                vox[(x, y, z - 1)] = G.pick(R, AWN_A if (x // 4) % 2 == 0 else AWN_B, 0.85, 0.95)
    # lanternes pendues
    for lx in (6, W - 7):
        for z in range(23, 28):
            vox[(lx, 1, z)] = G.lin("#3a3030")
        for x in range(lx - 1, lx + 2):
            for y in range(0, 3):
                for z in range(19, 23):
                    glow[(x, y, z)] = P(["#ffc070", "#ffd690"])[R.randint(0, 1)]
    # tapis roulés appuyés
    for k, x0 in enumerate((W - 1, W)):
        col = RUG[k % len(RUG)]
        for z in range(0, 18):
            for dx in range(2):
                for y in (12, 13):
                    vox[(x0 + dx, y, z)] = G.tone(col, 0.9 + 0.2 * ((z // 3) % 2))
    return vox, glow


def campfire(seed):
    """Feu de camp : cercle de pierres, bûches croisées, flammes et braises qui luisent."""
    R = R0(seed)
    vox, glow = {}, {}
    for a in range(22):
        t = a / 22 * math.tau
        x, y = 8 + math.cos(t) * 6.5, 8 + math.sin(t) * 6.5
        for z in range(0, R.randint(2, 3)):
            vox[(int(round(x)), int(round(y)), z)] = G.pick(R, STONE, 0.75, 0.95)
    for k in range(4):
        t = k / 4 * math.pi + 0.3
        for i in range(-5, 6):
            x, y = 8 + math.cos(t) * i, 8 + math.sin(t) * i
            vox[(int(round(x)), int(round(y)), 1 + (abs(i) < 3))] = G.pick(R, WOOD, 0.7, 0.9)
    FL = P(["#ff6a1a", "#ffa040", "#ffd070", "#ff8a2a"])
    for z in range(2, 11):
        r = 3.2 * (1 - (z - 2) / 10)
        for x in range(-4, 5):
            for y in range(-4, 5):
                if x * x + y * y <= r * r and R.random() < 0.85:
                    glow[(8 + x, 8 + y, z)] = FL[min(3, (z - 2) // 3 + R.randint(0, 1))]
    for _ in range(10):
        glow[(R.randint(4, 12), R.randint(4, 12), 0)] = FL[0]
    return vox, glow


def gazebo(seed):
    """Kiosque rond sur l'eau : trois marches, six colonnes, coupole bleue à lanternon doré."""
    R = R0(seed)
    vox, glow = {}, {}
    C = 24
    DOME = P(["#4a6fb0", "#5a80c0", "#3a5a98"])
    for z in range(0, 6):
        rr = 23 - (z // 2) * 3
        for x in range(C - rr, C + rr + 1):
            for y in range(C - rr, C + rr + 1):
                d = math.hypot(x - C, y - C)
                if d <= rr:
                    vox[(x, y, z)] = G.pick(R, STONE, 0.9 if d > rr - 1 else 1.0, 1.1)
    for k in range(6):
        t = k / 6 * math.tau + 0.4
        cx, cy = C + math.cos(t) * 13, C + math.sin(t) * 13
        for z in range(6, 36):
            r = 2.2 if 7 < z < 34 else 3.0
            for x in range(-3, 4):
                for y in range(-3, 4):
                    if x * x + y * y <= r * r:
                        vox[(int(cx + x), int(cy + y), z)] = G.pick(R, STONE, 0.95, 1.12)
    for z in range(36, 39):  # entablement
        for x in range(C - 17, C + 18):
            for y in range(C - 17, C + 18):
                d = math.hypot(x - C, y - C)
                if 12 <= d <= 16.5:
                    vox[(x, y, z)] = G.pick(R, GOLD if z == 38 else STONE)
    for z in range(39, 52):  # coupole
        rr = 16.5 * math.sqrt(max(0.0, 1 - ((z - 39) / 13) ** 2))
        for x in range(C - 17, C + 18):
            for y in range(C - 17, C + 18):
                d = math.hypot(x - C, y - C)
                if rr - 1.6 <= d <= rr:
                    vox[(x, y, z)] = G.pick(R, DOME, 0.9, 1.1)
    for z in range(52, 57):
        for x in range(C - 2, C + 3):
            for y in range(C - 2, C + 3):
                vox[(x, y, z)] = G.pick(R, GOLD)
    glow[(C, C, 57)] = P(["#ffe08a"])[0]
    return vox, glow


def fountain(seed):
    """Fontaine à deux vasques sur un bassin rond : pierre claire, eau calme, filets d'eau qui retombent."""
    R = R0(seed)
    vox, glow = {}, {}
    C = 16
    WAT = P(["#5fb8b8", "#6cc4c0", "#58aab0"])
    for x in range(0, 33):
        for y in range(0, 33):
            d = math.hypot(x - C, y - C)
            if d <= 15.5:
                if d > 13.8:
                    for z in range(0, 5):
                        vox[(x, y, z)] = G.pick(R, STONE, 0.9, 1.05)
                    if (x + y) % 5 == 0:
                        vox[(x, y, 5)] = G.pick(R, P(["#7da44a", "#6a8f3a"]))
                else:
                    vox[(x, y, 0)] = G.pick(R, STONE, 0.7, 0.8)
                    vox[(x, y, 3)] = G.pick(R, WAT, 0.95, 1.05)
    for z in range(4, 24):  # fût
        r = 1.6 if z not in (11, 12, 19) else 0
        for x in range(-2, 3):
            for y in range(-2, 3):
                if x * x + y * y <= r * r + 0.5:
                    vox[(C + x, C + y, z)] = G.pick(R, STONE)
    for zc, rr in ((11, 7.5), (19, 4.2)):
        for x in range(-8, 9):
            for y in range(-8, 9):
                d = math.hypot(x, y)
                if d <= rr:
                    vox[(C + x, C + y, zc)] = G.pick(R, STONE, 0.9, 1.05)
                    if d > rr - 1.2:
                        vox[(C + x, C + y, zc + 1)] = G.pick(R, STONE)
                    else:
                        vox[(C + x, C + y, zc + 1)] = G.pick(R, WAT)
        for a in range(0, 24, 3):  # filets d'eau aux lèvres de la vasque
            t = a / 24 * math.tau
            x, y = C + math.cos(t) * (rr + 0.8), C + math.sin(t) * (rr + 0.8)
            for z in range(4 if zc == 11 else 12, zc):
                glow[(int(round(x)), int(round(y)), z)] = G.tone(WAT[1], 0.45)
    for z in range(24, 27):
        glow[(C, C, z)] = G.tone(WAT[1], 0.5)
    return vox, glow


def rug(seed):
    """Tapis et coussins : là où l'escouade se pose."""
    R = R0(seed)
    vox = {}
    for x in range(1, 15):
        for y in range(3, 13):
            border = x in (1, 14) or y in (3, 12)
            motif = (x + y) % 4 == 0
            vox[(x, y, 0)] = G.tone(RUG[2] if border else (RUG[3] if motif else RUG[(x // 5) % 2]), R.uniform(0.9, 1.05))
    for cx, cy in ((4, 6), (11, 9)):
        for x in range(-2, 3):
            for y in range(-2, 3):
                for z in range(1, 3):
                    vox[(cx + x, cy + y, z)] = G.tone(RUG[1], R.uniform(0.85, 1.1))
    return vox


def jars(seed):
    R = R0(seed)
    vox, glow = {}, {}
    for i in range(5):
        cx, cy = R.randint(3, 12), R.randint(3, 12)
        h = R.randint(4, 9)
        col = R.choice(JARS)
        for z in range(0, h):
            r = 2.4 * math.sin(math.pi * (z + 1) / (h + 1)) + 0.6
            for x in range(-3, 4):
                for y in range(-3, 4):
                    if x * x + y * y <= r * r:
                        vox[(cx + x, cy + y, z)] = G.tone(col, R.uniform(0.88, 1.08))
    return vox, glow


for o in list(G.coll().objects):
    bpy.data.objects.remove(o, do_unlink=True)
kit = []
v, g = stall(801)
kit.append(("haven_etal", v, g, dict(origin=(16, 8, 0))))
v, g = campfire(802)
kit.append(("haven_feu", v, g, dict(origin=(8, 8, 0))))
v, g = gazebo(803)
kit.append(("haven_kiosque", v, g, dict(origin=(24, 24, 0))))
v, g = fountain(804)
kit.append(("haven_fontaine", v, g, dict(origin=(16, 16, 0))))
kit.append(("haven_tapis", rug(805), None, dict(origin=(8, 8, 0))))
v, g = jars(806)
kit.append(("haven_jarres", v, g, dict(origin=(8, 8, 0))))
G.emit(kit)
print("haven ok")
