# Personnages de Delve, v3 : voxels de 1/20 m, volumes arrondis (ellipsoïdes, capsules),
# ombrage sur trois valeurs, yeux lumineux, poses asymétriques. Ennemis en basalte fissuré de braise.
# blender -b --factory-startup -P gen_chars.py
import bpy, random, math, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_assets import lin, tone, mesh, export, coll, OUT, EMBER, AUTUMN, MOSS

VC = 1 / 20


def P(*h):
    return [lin(x) for x in h]


def ell(vox, c, r, col, R=None, keep=None):
    cx, cy, cz = c
    rx, ry, rz = r
    for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for z in range(int(cz - rz) - 1, int(cz + rz) + 2):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 + ((z - cz) / rz) ** 2 <= 1.0:
                    if keep and not keep(x, y, z):
                        continue
                    vox[(x, y, z)] = col(x, y, z) if callable(col) else col


def cap(vox, a, b, rad, col, rad_b=None):
    """Capsule de a vers b, rayon interpolé."""
    rad_b = rad if rad_b is None else rad_b
    L = math.dist(a, b)
    n = max(2, int(L * 2))
    for i in range(n + 1):
        t = i / n
        p = [a[k] + (b[k] - a[k]) * t for k in range(3)]
        r = rad + (rad_b - rad) * t
        ell(vox, p, (r, r, r), col)


def shade(vox, R, lo=0.8, hi=1.12, jitter=0.035):
    """Trois valeurs : dessus éclairés, dessous sombres, bruit léger."""
    out = {}
    for (x, y, z), c in vox.items():
        f = 1.0
        if (x, y, z + 1) not in vox:
            f = hi
        elif (x, y, z - 1) not in vox:
            f = lo
        out[(x, y, z)] = tone(c, f * R.uniform(1 - jitter, 1 + jitter))
    return out


def cracks(vox, glow, R, n, length, palette=None):
    """Fissures de braise : marches aléatoires sur la surface, retirées du corps vers le glow."""
    palette = palette or EMBER
    surf = [p for p in vox if any((p[0] + d[0], p[1] + d[1], p[2] + d[2]) not in vox
                                  for d in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0)))]
    for _ in range(n):
        p = R.choice(surf)
        for _ in range(length):
            for pp in (p, (p[0], p[1], p[2] + 1)):
                if pp in vox:
                    vox.pop(pp)
                    glow[pp] = R.choice(palette)
            q = (p[0] + R.choice((-1, 0, 1)), p[1] + R.choice((-1, 0, 1)), p[2] + R.choice((-1, -1, 0, 1)))
            if q in vox:
                p = q


def unit(name, body, weapon=None, grip=(0, 0, 0), glow=None, wglow=None):
    objs = [mesh(name + "_body", body, VC)]
    if weapon:
        w = mesh(name + "_weapon", weapon, VC)
        w.location = (grip[0] * VC, grip[1] * VC, grip[2] * VC)
        objs.append(w)
        if wglow:
            wg = mesh(name + "_weaponglow", wglow, VC, ao=False, glow=True)
            wg.parent = w
            objs.append(wg)
    if glow:
        objs.append(mesh(name + "_glow", glow, VC, ao=False, glow=True))
    export("u_" + name, objs)


# ------------------------------------------------------------------ héros (face vers -y)

def garde():
    R = random.Random(11)
    STL, STM, STD = P("#d4dbe0", "#98a4ad", "#56606a")
    BLU, BLD = P("#3d63e0", "#233a90")
    GOLD, LEA, WHT = P("#e6b84f", "#5c3f2c", "#f1ede2")
    b, g = {}, {}
    for s in (-1, 1):
        ell(b, (3 * s, -0.5, 2), (2.4, 3.2, 2.2), STD)
        cap(b, (3 * s, 0, 3), (3 * s, 0, 11), 2.0, STM)
        ell(b, (3 * s, -1.4, 7), (1.6, 1.2, 1.4), STL)
    for z in range(9, 15):
        rr = 5.8 - (z - 9) * 0.15
        ell(b, (0, 0, z), (rr, 4.0, 0.6), lambda x, y, zz: GOLD if x == 0 and y < -2 else BLU)
    ell(b, (0, 0, 13), (5.4, 3.8, 1.1), LEA)
    b[(0, -4, 13)] = GOLD
    ell(b, (0, 0, 18), (6.4, 4.4, 4.8), STL)
    ell(b, (0, -3.6, 18.5), (3.2, 1.2, 3.0), lambda x, y, z: WHT if abs(x) <= 1 or z == 18 else BLU)
    for s in (-1, 1):
        ell(b, (7 * s, 0, 21), (3.6, 3.6, 2.7), STL)
        for x in range(-10, 11):
            for y in range(-4, 5):
                if (x, y, 19) in b and abs(x) >= 5 and (x, y, 18) not in b:
                    b[(x, y, 19)] = GOLD
        cap(b, (7.5 * s, 0, 19), (8 * s, -1.5, 13), 1.8, STM)
        ell(b, (8 * s, -2, 12), (2.0, 2.0, 1.8), STD)
    ell(b, (0, 0, 26.5), (4.6, 4.6, 5.0), STL)
    for x in range(-3, 4):
        g[(x, -5, 27)] = (0.55, 0.75, 1.0)
    for z in range(24, 27):
        b[(0, -5, z)] = STD
    for x in range(-4, 5):
        b[(x, -5, 28)] = STL
    for i in range(12):
        t = i / 11
        cap(b, (0, -1 + t * 7, 31 - t * t * 6), (0, -1 + t * 7, 31 - t * t * 6), 1.4 - t * 0.5, BLU if i % 3 else lin("#6a8cff"))
    # cape
    for z in range(3, 22):
        w = 5 + (22 - z) * 0.12
        for x in range(int(-w), int(w) + 1):
            y = 4 + (22 - z) * 0.1
            b[(x, int(y), z)] = GOLD if z == 3 else BLD
    # grand pavois au bras gauche (x négatif)
    for y in range(-7, 5):
        for z in range(5, 21):
            half = 6 if z > 10 else 6 - (10 - z) * 0.9
            if abs(y + 1) > half:
                continue
            edge = abs(y + 1) > half - 1.2 or z == 20
            b[(-11, y, z)] = GOLD if edge else BLU
            b[(-10, y, z)] = STD
    for z in range(9, 18):
        b[(-12, -1, z)] = WHT
    for y in range(-4, 3):
        b[(-12, y, 15)] = WHT
    b = shade(b, R)
    sw = {}
    for z in range(-4, 0):
        sw[(0, 0, z)] = LEA
    sw[(0, 0, -5)] = GOLD
    for x in range(-3, 4):
        sw[(x, 0, 0)] = GOLD
    for i in range(1, 20):
        y = -int(i * 0.35)
        sw[(0, y, i)] = lin("#eef3f5")
        sw[(1, y, i)] = lin("#bfc9cf") if i < 19 else lin("#eef3f5")
    unit("garde", b, sw, grip=(8, -3, 12), glow=g)


def lame():
    R = random.Random(12)
    DK, DM = P("#2a2830", "#403d49")
    LEA, RED, RDD, SKIN, MET = P("#5b4130", "#e0344f", "#8f1d30", "#d9a27c", "#e6ebee")
    b, g = {}, {}
    for s in (-1, 1):
        ell(b, (2.5 * s, -0.5, 1.6), (1.9, 2.8, 1.7), DK)
        cap(b, (2.5 * s, 0, 2), (2.3 * s, 0.4, 11), 1.6, DM)
    ell(b, (0, 0.5, 12), (4.2, 3.0, 1.4), LEA)
    ell(b, (0, 0.6, 16), (4.6, 3.4, 4.2), DM)
    for i in range(-4, 5):
        b[(i, -2 - (i == 0), 13 + (i + 4) // 2)] = RED
    ell(b, (0, 0.6, 20.5), (4.2, 3.6, 1.4), RED)
    for i in range(14):
        t = i / 13
        cap(b, (2 + t * 3, 3 + t * 7, 20 - t * 9), (2 + t * 3, 3 + t * 7, 20 - t * 9), 1.3 - t * 0.4, RED if i % 4 else RDD)
    for s in (-1, 1):
        cap(b, (5 * s, 0.5, 18), (6 * s, -1, 12), 1.4, DK)
    ell(b, (0, 0.5, 25), (4.4, 4.8, 4.8), DK)
    cap(b, (0, 2.5, 28), (0, 7, 31), 1.8, DK, 0.8)
    ell(b, (0, -4.2, 24.5), (2.6, 1.6, 2.4), lin("#0d0c10"))
    for x in (-1, 0, 1):
        b[(x, -4, 22)] = SKIN
        b[(x, -5, 22)] = RED
    g[(-1, -5, 25)] = (1.0, 0.35, 0.3)
    g[(1, -5, 25)] = (1.0, 0.35, 0.3)
    for p in g:
        b.pop(p, None)
    for i in range(7):
        b[(-6, -2 - i, 12 - i // 3)] = MET
    b = shade(b, R)
    bl = {}
    for z in range(-3, 1):
        bl[(0, 0, z)] = LEA
    for x in (-2, -1, 1, 2):
        bl[(x, 0, 1)] = lin("#c9a24a")
    for i in range(2, 20):
        y = -int((i / 19) ** 2 * 5)
        bl[(0, y, i)] = MET
        bl[(0, y + 1, i)] = lin("#b8c0c6")
    unit("lame", b, bl, grip=(6, -1, 12), glow=g)


def oracle():
    R = random.Random(13)
    PL, PLD = P("#9b50d8", "#5c2a8c")
    GOLD, SHD, WOOD, SKIN = P("#e6b84f", "#1a1320", "#6a4a32", "#c99273")
    b, g = {}, {}
    for z in range(0, 20):
        rx = 7.0 - z * 0.2
        ry = 5.0 - z * 0.12
        ell(b, (0, 0, z), (rx, ry, 0.6), lambda x, y, zz: GOLD if zz <= 1 or (abs(x) <= 1 and y < 0) else PL)
    for s in (-1, 1):
        cap(b, (5 * s, 0, 19), (7.5 * s, -2, 12), 2.2, PL, 3.0)
        ell(b, (7.5 * s, -2, 11), (3.0, 3.0, 1.0), GOLD)
    ell(b, (0, 0, 23), (4.2, 4.2, 4.2), PLD)
    ell(b, (0, -3.6, 22.5), (2.8, 1.4, 2.6), SHD)
    b[(0, -4, 21)] = SKIN
    g[(-1, -5, 23)] = EMBER[2]
    g[(1, -5, 23)] = EMBER[2]
    for x in range(-9, 10):
        for y in range(-9, 10):
            d = x * x + y * y
            if d <= 81:
                b[(x, y, 27)] = GOLD if d > 64 else PLD
    for i in range(14):
        t = i / 13
        r = 5.0 * (1 - t) + 0.6
        ell(b, (0, t * t * 7, 28 + i), (r, r, 0.7), PL)
    ell(b, (0, 0, 28), (5.2, 5.2, 0.7), GOLD)
    b = shade(b, R)
    st, sg = {}, {}
    for z in range(-10, 26):
        st[(0, 0, z)] = WOOD
    for a in range(20):
        t = a / 20 * math.tau
        st[(int(round(math.cos(t) * 4)), 0, 29 + int(round(math.sin(t) * 4)))] = GOLD
    ell(sg, (0, 0, 29), (2.6, 2.6, 2.6), lambda x, y, z: random.Random(x * 7 + y * 3 + z).choice(EMBER))
    unit("oracle", b, st, grip=(8, -2, 12), glow=g, wglow=sg)



def artificier():
    """Trapu, manteau sarcelle et tablier, lunettes de cuivre, réservoir lumineux au dos, clé à molette."""
    R = random.Random(14)
    TEA, TED = P("#22b8a6", "#136b62")
    LEA, BRS, IRN, SKIN, DK, BRD = P("#6a4a30", "#d9a441", "#4a4d52", "#d9a27c", "#2a2830", "#7a4a2a")
    b, g = {}, {}
    for s in (-1, 1):
        ell(b, (2.8 * s, -0.5, 1.8), (2.2, 3.0, 1.9), DK)
        cap(b, (2.8 * s, 0, 2), (2.8 * s, 0, 10), 1.9, LEA)
    for z in range(9, 21):
        rr = 5.8 - abs(z - 15) * 0.1
        ell(b, (0, 0, z), (rr, 4.1, 0.6), TEA if z > 10 else TED)
    for z in range(8, 18):
        for x in range(-3, 4):
            b[(x, -4 - (z < 12), z)] = LEA
    ell(b, (0, 0, 12), (6.0, 4.3, 0.8), LEA)
    for x in (-5, -3, 3, 5):
        b[(x, -4, 11)] = BRS
        b[(x, -4, 10)] = IRN
    for s in (-1, 1):
        ell(b, (6.8 * s, 0, 19.5), (3.1, 3.1, 2.5), TED)
        cap(b, (7.2 * s, 0, 18), (7.6 * s, -1.5, 11), 1.8, TEA)
        ell(b, (7.7 * s, -2, 10), (2.1, 2.1, 1.8), LEA)
    ell(b, (0, 0, 24.5), (4.3, 4.3, 4.4), SKIN)
    ell(b, (0, -2.0, 22.2), (3.8, 2.6, 2.4), BRD)
    for x in (-1, 1):
        b[(x, -4, 25)] = lin("#1a1410")
    ell(b, (0, 0.6, 28), (4.7, 4.7, 2.3), DK)
    for s in (-1, 1):
        ell(b, (2.0 * s, -3.6, 28.6), (1.6, 1.0, 1.6), BRS)
        g[(int(2.0 * s), -5, 29)] = (0.45, 1.0, 0.9)
    ell(b, (0, 5.8, 17), (4.3, 2.7, 5.6), IRN)
    for z in range(13, 22):
        for x in (-1, 0, 1):
            g[(x, 9, z)] = (0.3, 1.0, 0.85)
    for i in range(9):
        b[(3, 6 + i // 3, 22 + i)] = BRS
        b[(-3, 6 + i // 3, 22 + i // 2)] = BRS
    for q in g:
        b.pop(q, None)
    b = shade(b, R)
    w = {}
    for z in range(-4, 13):
        w[(0, 0, z)] = IRN
    for y in range(-3, 4):
        for z in (13, 14, 15, 16):
            if not (abs(y) <= 1 and z >= 14):
                w[(0, y, z)] = tone(IRN, 1.25)
    unit("artificier", b, w, grip=(8, -2, 11), glow=g)


def moine():
    """Robe de jade et ceinture safran, crâne rasé à chignon, chapelet, poings bandés où couve le souffle."""
    R = random.Random(15)
    JAD, JDD = P("#6cc24a", "#3d7a2a")
    CRM, SKIN, WOOD, SAF, HAIR = P("#e8dfc4", "#c98f68", "#5a3d27", "#e39a2e", "#1a1410")
    b, g = {}, {}
    for s in (-1, 1):
        ell(b, (2.4 * s, -0.4, 1.1), (1.6, 2.6, 1.1), SKIN)
        cap(b, (2.4 * s, 0, 2), (2.7 * s, 0, 9), 1.8, CRM)
    for z in range(6, 20):
        rx = 5.0 + max(0, 11 - z) * 0.3
        ell(b, (0, 0, z), (rx, 3.7, 0.6), JAD if z > 8 else JDD)
    ell(b, (0, 0, 12), (5.5, 4.0, 0.8), SAF)
    for i in range(7):
        b[(-3 + i // 3, -4, 11 - i)] = SAF
    for i in range(14):
        t = i / 13
        b[(int(-4 + t * 8), -4, int(19 - t * 7))] = CRM
    for s in (-1, 1):
        ell(b, (6 * s, 0, 18.5), (2.7, 2.7, 2.3), JAD)
        cap(b, (6.5 * s, 0, 17), (7.6 * s, -2, 11), 1.6, SKIN)
        ell(b, (7.9 * s, -2.4, 10), (2.1, 2.1, 1.9), CRM)
        for q in ((0, -5, 10), (0, -5, 11), (1, -5, 10), (-1, -5, 10), (0, -4, 12)):
            g[(int(7.9 * s) + q[0], q[1], q[2])] = (0.55, 1.0, 0.45)
    ell(b, (0, 0, 23.5), (3.9, 3.9, 4.0), SKIN)
    ell(b, (0, 1.4, 28), (1.7, 1.7, 1.7), HAIR)
    for x in (-1, 1):
        b[(x, -4, 24)] = HAIR
    for a in range(24):
        t = a / 24 * math.tau
        b[(int(round(math.cos(t) * 4.4)), int(round(math.sin(t) * 3.4)) - 1, 20 - int(abs(math.sin(t)) * 2))] = WOOD
    for q in g:
        b.pop(q, None)
    b = shade(b, R)
    unit("moine", b, glow=g)


def trappeur():
    """Pourpoint ocre, capuche de fourrure, carquois, piège pendu à la ceinture, arc de frêne."""
    R = random.Random(16)
    OCH, OCD = P("#c9a23a", "#7a5e1e")
    FUR, FUD, LEA, DK, SKIN, WOOD = P("#8a7560", "#6a5846", "#5b4130", "#2e2a26", "#d0a07a", "#6a4a32")
    b, g = {}, {}
    for s in (-1, 1):
        ell(b, (2.5 * s, -0.5, 1.7), (1.9, 2.9, 1.8), DK)
        cap(b, (2.5 * s, 0, 2), (2.4 * s, 0.3, 11), 1.7, LEA)
    for z in range(10, 21):
        rr = 4.9 - abs(z - 15) * 0.06
        ell(b, (0, 0.3, z), (rr, 3.4, 0.6), OCH if z > 11 else OCD)
    ell(b, (0, 0.3, 12), (5.2, 3.6, 0.8), LEA)
    for x in range(-3, 4):
        for y in range(-4, -2):
            b[(x, y, 9 + (abs(x) % 2))] = lin("#5a5550")
    for s in (-1, 1):
        ell(b, (5.8 * s, 0.3, 19.5), (2.9, 2.9, 2.4), FUR)
        cap(b, (6.2 * s, 0.3, 18), (6.8 * s, -1.5, 11), 1.5, OCH)
        ell(b, (6.9 * s, -1.8, 10), (1.8, 1.8, 1.6), LEA)
    for z in range(4, 22):
        w = 4.5 + (22 - z) * 0.12
        for x in range(int(-w), int(w) + 1):
            b[(x, int(3.6 + (22 - z) * 0.08), z)] = FUD if z < 6 else FUR
    ell(b, (0, 0.3, 24.8), (3.9, 3.9, 4.1), SKIN)
    ell(b, (0, 1.0, 26), (5.0, 5.0, 4.8), FUR, keep=lambda x, y, z: not (y < -1 and z < 29 and abs(x) < 4))
    for x in (-1, 1):
        b[(x, -4, 25)] = lin("#1a1410")
    for x in range(-3, 4):
        b[(x, -4, 23)] = lin("#5a3a22")
    ell(b, (-3, 5.5, 19), (1.6, 1.6, 5.5), WOOD)
    for i in range(4):
        b[(-3 + i % 2, 5 + i // 2, 26)] = lin("#e8e2cc")
        b[(-3 + i % 2, 5 + i // 2, 27)] = lin("#b8322a")
    g[(3, -5, 12)] = EMBER[0]
    for q in g:
        b.pop(q, None)
    b = shade(b, R)
    bow = {}
    for a in range(25):
        t = (a / 24 - 0.5) * 2.4
        bow[(0, int(round(-math.cos(t) * 5)), int(round(math.sin(t) * 13)))] = tone(WOOD, R.uniform(0.9, 1.15))
    for z in range(-12, 13):
        bow[(0, 1, z)] = lin("#e8e2cc")
    unit("trappeur", b, bow, grip=(-7, -3, 14), glow=g)


def tidiane():
    """Artisan Grixis : dreadlocks, bonnet marine à croix, long manteau brun taché de peinture, grand pinceau tricolore."""
    R = random.Random(17)
    SKIN, SKD = P("#6e4430", "#5a3624")
    LOC, LOD = P("#3e2718", "#5a3a22")
    BEA, CRS = P("#1f2440", "#d8d8e4")
    COAT, COD = P("#5e3d27", "#4a2f1e")
    SHIRT, JEAN, BOOT, BELT = P("#1c1b20", "#232633", "#4a3020", "#6a4a2a")
    PB, PR, PN = P("#3f8fd8", "#e0483f", "#9b6dd6")
    b, g = {}, {}
    for s in (-1, 1):
        ell(b, (2.6 * s, -0.6, 1.8), (2.0, 3.0, 1.9), BOOT)
        cap(b, (2.6 * s, 0, 3), (2.5 * s, 0.2, 11), 1.8, JEAN)
    for z in range(10, 21):
        ell(b, (0, 0.2, z), (4.4, 3.1, 0.6), SHIRT)
    ell(b, (0, 0.2, 11.5), (4.7, 3.3, 0.7), BELT)
    b[(0, -3, 11)] = lin("#b8b2a0")
    # long manteau ouvert : pans jusqu'aux genoux, dos plein
    for z in range(5, 22):
        w = 5.0 + (22 - z) * 0.06
        for x in range(int(-w), int(w) + 1):
            y = int(3.3 + (22 - z) * 0.05)
            b[(x, y, z)] = COAT if (x + z) % 5 else COD
        for s in (-1, 1):
            for x in range(int(w) - 2, int(w) + 1):
                b[(x * s, -3, z)] = COAT
            b[(int(w) * s, -2, z)] = COD
    for s in (-1, 1):
        ell(b, (5.4 * s, 0.2, 20), (2.7, 2.7, 2.3), COAT)
        cap(b, (5.9 * s, 0.2, 18.5), (6.4 * s, -1.2, 11.5), 1.6, COAT)
        ell(b, (6.5 * s, -1.6, 10.5), (1.4, 1.4, 1.4), SKIN)
    # éclaboussures des trois voix sur le manteau
    for q in [(-5, -3, 9), (-4, -3, 14), (5, -3, 7), (4, 3, 12), (-3, 4, 16), (2, 4, 8), (6, -2, 17), (-6, -1, 11)]:
        if q in b:
            b[q] = R.choice([PB, PR, PN])
    ell(b, (0, 0.2, 24.3), (3.6, 3.6, 3.9), SKIN)
    for x in (-1, 1):
        b[(x, -3, 25)] = lin("#140c08")
    b[(0, -4, 24)] = SKD
    # bonnet marine, croix claire
    ell(b, (0, 0.5, 28), (4.3, 4.3, 2.8), BEA, keep=lambda x, y, z: z >= 26)
    for q in [(0, -4, 27), (-1, -4, 27), (1, -4, 27), (0, -4, 28), (0, -4, 26)]:
        b[q] = CRS
    # dreadlocks : mèches épaisses qui tombent sur les épaules et dans le dos, laissant le visage dégagé
    for a in range(26):
        t = a / 26 * math.tau
        sx, sy = math.cos(t) * 4.2, math.sin(t) * 4.2 + 0.5
        if sy < -2.2 and abs(sx) < 2.6:
            continue
        L = R.randint(10, 15) if sy > -1 else R.randint(7, 10)
        for i in range(L):
            x = int(round(sx * (1 + i * 0.03)))
            y = int(round(sy + i * 0.1))
            col = LOC if (i + a) % 3 else LOD
            b[(x, y, 26 - i)] = col
            b[(x + (1 if sx > 0 else -1), y, 26 - i)] = col
    for q in g:
        b.pop(q, None)
    b = shade(b, R)
    # grand pinceau : manche de bois, virole, poils aux trois couleurs
    br, bg = {}, {}
    for z in range(-8, 14):
        br[(0, 0, z)] = lin("#6a4a32")
    for z in range(14, 16):
        for x in (-1, 0, 1):
            br[(x, 0, z)] = lin("#b8b2a0")
    for z in range(16, 21):
        for x in (-1, 0, 1):
            bg[(x, 0, z)] = [PB, PR, PN][x + 1]
    unit("tidiane", b, br, grip=(7, -2, 11), glow=g, wglow=bg)

def receleur():
    """Manteau gris acier à capuche, foulard rouille sur le nez, ceinture de fioles lumineuses,
    ballot de brocante au dos (couverture roulée, poêle, lanterne), pied-de-biche."""
    R = random.Random(18)
    COAT, COD = P("#6f8290", "#4a5a66")
    HOOD, SCARF, SKIN = P("#56646e", "#a8452e", "#b98a64")
    LEA, DK, BRS, CLOTH, CLD = P("#5b4130", "#26282e", "#c9a24a", "#8a7a5a", "#6a5c42")
    b, g = {}, {}
    for s in (-1, 1):
        ell(b, (2.5 * s, -0.5, 1.7), (1.9, 2.9, 1.8), DK)
        cap(b, (2.5 * s, 0, 2), (2.4 * s, 0.2, 10), 1.7, LEA)
    # manteau long, évasé vers le bas
    for z in range(4, 21):
        rx = 4.6 + max(0, 12 - z) * 0.2
        ell(b, (0, 0.3, z), (rx, 3.4, 0.6), COAT if z > 5 else COD)
    for z in range(4, 12):
        b[(0, -4, z)] = COD
    # ceinture de fioles aux couleurs vives
    ell(b, (0, 0.3, 12), (5.4, 3.7, 0.8), LEA)
    for x, col in zip((-4, -2, 2, 4), ((0.35, 1.0, 0.5), (1.0, 0.35, 0.3), (0.4, 0.7, 1.0), (1.0, 0.8, 0.3))):
        g[(x, -4, 11)] = col
        g[(x, -4, 10)] = col
        b[(x, -4, 12)] = BRS
    # bandoulières croisées
    for i in range(10):
        b[(-4 + i, -4, 20 - i)] = LEA
    for s in (-1, 1):
        ell(b, (5.6 * s, 0.3, 19.5), (2.8, 2.8, 2.3), COD)
        cap(b, (6.0 * s, 0.3, 18), (6.6 * s, -1.4, 11), 1.6, COAT)
        ell(b, (6.7 * s, -1.7, 10), (1.6, 1.6, 1.5), LEA)
    # tête, capuche, foulard
    ell(b, (0, 0.3, 24.5), (3.8, 3.8, 4.0), SKIN)
    ell(b, (0, 0.9, 25.8), (4.8, 4.9, 4.9), HOOD, keep=lambda x, y, z: not (y < -1 and z < 28 and abs(x) < 4))
    ell(b, (0, -2.4, 22.6), (3.8, 2.0, 1.7), SCARF)
    for i in range(6):
        b[(3, 3 + i, 22 - i)] = SCARF
    for x in (-1, 1):
        b[(x, -4, 25)] = lin("#140c08")
    # ballot de brocante au dos
    ell(b, (0, 6.2, 17.5), (4.6, 3.0, 5.5), CLOTH)
    cap(b, (-4.5, 6.5, 23.5), (4.5, 6.5, 23.5), 1.6, lin("#7a4a2a"))
    for z in range(13, 23):
        b[(0, 9, z)] = CLD
    ell(b, (-5.2, 7.5, 15), (0.7, 2.3, 2.3), lin("#3a3d44"))
    cap(b, (-5.2, 7.5, 12.5), (-5.2, 8.5, 9), 0.6, lin("#3a3d44"))
    ell(g, (5.0, 8.0, 13.5), (1.2, 1.2, 1.6), lambda x, y, z: (1.0, 0.75, 0.35))
    b[(5, 8, 16)] = BRS
    for q in g:
        b.pop(q, None)
    b = shade(b, R)
    # pied-de-biche : tige de fer, griffe en haut, pied plat en bas
    IRN = lin("#5a5e66")
    w = {}
    for z in range(-7, 15):
        w[(0, 0, z)] = IRN
        w[(1, 0, z)] = tone(IRN, 0.8)
    for q in ((0, -1, 15), (0, -2, 15), (0, -3, 14), (0, -3, 13), (1, -1, 15), (1, -2, 15)):
        w[q] = tone(IRN, 1.2)
    for q in ((0, 1, -7), (0, 2, -8), (1, 1, -7), (1, 2, -8)):
        w[q] = IRN
    for z in range(-2, 4):
        w[(0, 0, z)] = lin("#a8452e")
    unit("receleur", b, w, grip=(7, -2, 11), glow=g)

# ------------------------------------------------------------------ ennemis : basalte et braise

BAS = P("#23262e", "#1b1d24", "#2c3039")


def basalt(R):
    return lambda x, y, z: tone(R.choice(BAS), R.uniform(0.9, 1.1))


def husk():
    R = random.Random(21)
    b, g = {}, {}
    col = basalt(R)
    for s in (-1, 1):
        cap(b, (3 * s, 0, 1), (3 * s, -1, 8), 2.0, col)
    ell(b, (0, -1, 13), (6.0, 4.5, 5.5), col)
    ell(b, (0, -4, 18), (5.5, 4.2, 3.5), col)
    for s in (-1, 1):
        cap(b, (7 * s, -3, 17), (8 * s, -6, 4), 1.9, col, 2.4)
    ell(b, (0, -8, 18), (3.2, 3.2, 3.0), col)
    for x in (-2, -1, 1, 2):
        g[(x, -11, 19)] = EMBER[1]
    cracks(b, g, R, 6, 12)
    unit("husk", shade(b, R), glow=g)


def guetteur():
    R = random.Random(22)
    BONE, RED, RDD = P("#b9b2a0", "#3a3d46", "#26282f")
    b, g = {}, {}
    for s in (-1, 1):
        cap(b, (2 * s, 0, 0), (2 * s, 0, 9), 0.9, BONE)
    for z in range(6, 22):
        w = 3.2 + max(0, 12 - z) * 0.35
        ell(b, (0, 0.5, z), (w, 2.8, 0.6), lambda x, y, zz: tone(RED if zz > 8 else RDD, R.uniform(0.8, 1.05)),
            keep=lambda x, y, zz: not (zz < 10 and R.random() < 0.18))
    ell(b, (0, 0, 24), (3.6, 3.8, 3.6), RED)
    cap(b, (0, 1.5, 26), (0, 5, 29), 1.6, RED, 0.6)
    ell(b, (0, -3.2, 23.5), (2.2, 1.2, 2.2), lin("#120d0b"))
    g[(-1, -4, 24)] = EMBER[0]
    g[(1, -4, 24)] = EMBER[0]
    for s in (-1, 1):
        cap(b, (4 * s, 0, 19), (5 * s, -3, 14), 0.9, BONE)
    bow = {}
    for a in range(25):
        t = (a / 24 - 0.5) * 2.3
        bow[(0, int(round(-math.cos(t) * 5)), int(round(math.sin(t) * 12)))] = tone(lin("#5a4030"), R.uniform(0.9, 1.1))
    for z in range(-11, 12):
        bow[(0, 1, z)] = lin("#e8e2cc")
    unit("guetteur", shade(b, R), bow, grip=(-6, -4, 15), glow=g)


def sentinelle():
    R = random.Random(23)
    b, g = {}, {}
    col = basalt(R)
    for s in (-1, 1):
        cap(b, (4 * s, 0, 1), (4.5 * s, 0, 11), 3.0, col)
    ell(b, (0, 0, 20), (9, 6, 8), col)
    for s in (-1, 1):
        ell(b, (11 * s, 0, 25), (4.5, 4.5, 4), col)
        cap(b, (12 * s, 0, 23), (13 * s, -3, 9), 3.2, col, 4.0)
    ell(b, (0, -2, 30), (4, 4, 3.5), col)
    for x in range(-2, 3):
        g[(x, -6, 30)] = EMBER[0]
    ell(g, (0, -6.5, 20), (3, 1, 3), lambda x, y, z: R.choice(EMBER))
    for p in g:
        b.pop(p, None)
    cracks(b, g, R, 7, 14)
    ell(b, (-11, 0, 29), (3.5, 3.5, 2), lambda x, y, z: R.choice(AUTUMN), keep=lambda x, y, z: R.random() < 0.55)
    unit("sentinelle", shade(b, R), glow=g)


def wisp():
    R = random.Random(24)
    b, g = {}, {}
    ell(g, (0, 0, 12), (3.5, 3.5, 3.5), lambda x, y, z: R.choice(EMBER))
    for k in range(90):
        a = R.uniform(0, math.tau)
        z = R.randint(7, 22)
        r = R.uniform(3.8, 5.6) * (1 - (z - 7) / 20)
        p = (int(math.cos(a) * r), int(math.sin(a) * r), z)
        if p not in g:
            b[p] = tone(R.choice(AUTUMN), R.uniform(1.0, 1.3))
    unit("wisp", b, glow=g)


def gardien():
    """Colosse de l'Écluse : basalte, une arche en ruine soudée sur le dos, cœur de magma."""
    R = random.Random(29)
    b, g = {}, {}
    col = basalt(R)
    STONE_ARCH = P("#cfc6b2", "#bdb39e")
    for s in (-1, 1):
        cap(b, (8 * s, 0, 1), (9 * s, 0, 22), 5.0, col, 6.0)
    ell(b, (0, 0, 38), (16, 11, 16), col)
    ell(b, (0, -4, 55), (8, 7, 7), col)
    for x in range(-7, 8):
        for z in range(50, 62):
            if abs(x) < 7 - max(0, z - 57):
                b[(x, -11, z)] = tone(lin("#d9cfb8"), R.uniform(0.85, 1.05))
    for s in (-1, 1):
        cap(b, (6 * s, -8, 60), (15 * s, -9, 72), 2.2, lin("#d9cfb8"), 0.8)
        g[(3 * s, -12, 56)] = EMBER[0]
        g[(2 * s, -12, 56)] = EMBER[1]
        g[(3 * s, -12, 55)] = EMBER[1]
    for s in (-1, 1):
        ell(b, (20 * s, 0, 48), (8, 8, 7), col)
        cap(b, (22 * s, 0, 44), (25 * s, -6, 16), 6.0, col, 7.5)
    # arche en ruine sur le dos
    for x in range(-18, 19):
        for z in range(40, 78):
            for y in range(9, 15):
                inner = (x / 11.0) ** 2 + ((z - 50) / 18.0) ** 2 < 1.0 and z > 40
                outer = (x / 18.0) ** 2 + ((z - 50) / 27.0) ** 2 < 1.0
                if outer and not inner and not (x > 9 and z > 64 and R.random() < 0.7):
                    b[(x, y, z)] = tone(R.choice(STONE_ARCH), R.uniform(0.8, 1.05))
    ell(g, (0, -11, 40), (6, 2, 7), lambda x, y, z: R.choice(EMBER))
    for p in g:
        b.pop(p, None)
    cracks(b, g, R, 18, 20)
    for k in range(10):
        x = R.randint(-16, 16)
        L = R.randint(6, 26)
        for z in range(L):
            b[(x, 16, 72 - z)] = tone(R.choice(AUTUMN), 1 - z / 40)
    unit("gardien", shade(b, R), glow=g)


def chaman():
    R = random.Random(25)
    b, g = {}, {}
    col = basalt(R)
    for z in range(0, 18):
        r = 5.0 - z * 0.12
        ell(b, (0, 0, z), (r, r * 0.8, 0.6), col)
    ell(b, (0, -1, 21), (3.6, 3.6, 3.4), col)
    for s in (-1, 1):
        cap(b, (2 * s, -1, 23), (6 * s, 1, 30), 1.1, lin("#d9cfb8"), 0.5)
        cap(b, (5 * s, 0, 16), (6 * s, -3, 11), 1.3, col)
    g[(-1, -5, 21)] = EMBER[0]
    g[(1, -5, 21)] = EMBER[0]
    cracks(b, g, R, 5, 10)
    st, sg = {}, {}
    for z in range(-10, 16):
        st[(0, 0, z)] = lin("#5a4030")
    ell(sg, (0, 0, 18), (2.2, 2.2, 2.6), lambda x, y, z: R.choice(EMBER))
    unit("chaman", shade(b, R), st, grip=(6, -3, 11), glow=g, wglow=sg)


def carapace():
    R = random.Random(26)
    b, g = {}, {}
    col = basalt(R)
    for s in (-1, 1):
        for t in (-1, 1):
            cap(b, (5 * s, 4 * t, 0), (5 * s, 4 * t, 4), 1.8, col)
    ell(b, (0, 0, 8), (9, 8, 6), col, keep=lambda x, y, z: z >= 3)
    for x in range(-9, 10):
        for y in range(-8, 9):
            for z in range(3, 15):
                if (x, y, z) in b and ((x + 20) % 5 == 0 or (y + 20) % 5 == 0) and (x, y, z + 1) not in b:
                    b.pop((x, y, z))
                    g[(x, y, z)] = R.choice(EMBER)
    ell(b, (0, -9, 6), (2.6, 2.6, 2.4), col)
    g[(-1, -11, 7)] = EMBER[0]
    g[(1, -11, 7)] = EMBER[0]
    unit("carapace", shade(b, R), glow=g)


def rodeur():
    R = random.Random(27)
    b, g = {}, {}
    col = basalt(R)
    for s in (-1, 1):
        cap(b, (2.5 * s, 1, 0), (3 * s, -1, 5), 1.2, col)
        cap(b, (3 * s, -1, 5), (2.5 * s, 1, 10), 1.3, col)
    ell(b, (0, 0, 15), (4.0, 3.0, 4.5), col)
    ell(b, (0, -3, 21), (3.0, 3.4, 3.0), col)
    cap(b, (0, -1, 23), (0, 5, 27), 1.2, col, 0.5)
    g[(-1, -6, 21)] = EMBER[0]
    g[(1, -6, 21)] = EMBER[0]
    for s in (-1, 1):
        cap(b, (4.5 * s, 0, 18), (6 * s, -4, 13), 1.1, col)
        for i in range(12):
            g[(int(6 * s + s * i * 0.3), -5 - i // 2, 13 - i // 3)] = R.choice(EMBER)
    cracks(b, g, R, 4, 10)
    unit("rodeur", shade(b, R), glow=g)


def build():
    for f in os.listdir(OUT):
        if f.startswith("u_") and f.endswith(".glb"):
            os.remove(os.path.join(OUT, f))
    garde(); lame(); oracle(); artificier(); moine(); trappeur(); tidiane(); receleur()
    husk(); guetteur(); sentinelle(); wisp(); gardien()
    chaman(); carapace(); rodeur()
    print("persos ok")


if __name__ == "__main__":
    build()
