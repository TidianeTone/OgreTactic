# Héros de guilde : un vrai modèle par paire de classes (28), pas un recoloriage. Chaque guilde a sa silhouette,
# sa coiffe et son arme. Le même dessin sert aux deux héros de la paire : la couleur dominante (A) est celle de la
# classe du héros, la seconde (B) celle de sa vocation -> u_<classe>__<vocation>.glb, arme <classe>_weapon.
# blender -b --factory-startup -P gen_guildes.py            (tout)
# DELVE_ONLY=tenaille,murmures blender -b --factory-startup -P gen_guildes.py
import random, math, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_assets import lin, tone, export, EMBER
from gen_chars import Vox, ell, px, line, cap, shade, realize, mesh, VC, K, DOWN

H = lambda h: lin(h)
PAL = {  # m : tenue, d : sombre, t : liseré, g : lueur
    "garde": dict(m=H("#3d63e0"), d=H("#233a90"), t=H("#e6b84f"), g=(0.55, 0.75, 1.0)),
    "lame": dict(m=H("#e0344f"), d=H("#8f1d30"), t=H("#2a2830"), g=(1.0, 0.35, 0.3)),
    "oracle": dict(m=H("#9b50d8"), d=H("#5c2a8c"), t=H("#e6b84f"), g=(1.0, 0.7, 0.3)),
    "artificier": dict(m=H("#22b8a6"), d=H("#136b62"), t=H("#d9a441"), g=(0.3, 1.0, 0.85)),
    "moine": dict(m=H("#6cc24a"), d=H("#3d7a2a"), t=H("#e39a2e"), g=(0.55, 1.0, 0.45)),
    "trappeur": dict(m=H("#c9a23a"), d=H("#7a5e1e"), t=H("#8a7560"), g=(1.0, 0.6, 0.25)),
    "tidiane": dict(m=H("#c83c8a"), d=H("#6a1f4a"), t=H("#f4f1ea"), g=(1.0, 0.45, 0.8)),
    "receleur": dict(m=H("#6f8290"), d=H("#4a5a66"), t=H("#a8452e"), g=(1.0, 0.8, 0.35)),
}
STL, STM, STD = H("#d4dbe0"), H("#98a4ad"), H("#56606a")
LEA, DK, WOOD, BRS, GOLD = H("#5b4130"), H("#2a2830"), H("#6a4a32"), H("#d9a441"), H("#e6b84f")
IRN, BONE, SHD, FUR, EYE = H("#4a4d52"), H("#f1ede2"), H("#1a1320"), H("#8a7560"), H("#140c08")
SK = [H("#d9a27c"), H("#c98f68"), H("#b98a64"), H("#6e4430"), H("#8a5a3a")]
TRI = [H("#3f8fd8"), H("#e0483f"), H("#9b6dd6")]  # les trois voix de Tidiane


# ------------------------------------------------------------------ pièces communes (face vers -y, main d'arme en +x)

def jambes(b, pant, boot, sep=2.5, top=11, r=1.7):
    for s in (-1, 1):
        ell(b, (sep * s, -0.5, 1.7), (r + 0.2, r + 1.2, 1.8), boot)
        cap(b, (sep * s, 0, 2), (sep * s, 0.2, top), r, pant)


def jupe(b, z0, z1, rx0, rx1, ry0, ry1, col, y=0.2):
    for z in range(z0, z1):
        t = (z - z0) / max(1, z1 - z0 - 1)
        ell(b, (0, y, z), (rx0 + (rx1 - rx0) * t, ry0 + (ry1 - ry0) * t, 0.6), col)


def torse(b, col, z0=12, z1=21, rx=4.7, ry=3.3, y=0.2):
    for z in range(z0, z1):
        ell(b, (0, y, z), (rx - abs(z - (z0 + z1) / 2) * 0.05, ry, 0.6), col)


def bras(b, sh, arm, hand, sx=5.6, z=19.5, shr=2.7, ar=1.6, hr=1.5):
    for s in (-1, 1):
        if sh:
            ell(b, (sx * s, 0.3, z), (shr, shr, shr * 0.85), sh)
        cap(b, ((sx + 0.4) * s, 0.3, z - 1.5), ((sx + 1.0) * s, -1.4, 11), ar, arm)
        ell(b, ((sx + 1.1) * s, -1.7, 10), (hr, hr, hr), hand)


def tete(b, skin, cz=24.5, r=3.8, eyes=EYE, g=None):
    ell(b, (0, 0.3, cz), (r, r, r * 1.05), skin)
    for x in (-1, 1) if eyes else ():
        (g if g is not None else b)[(x, -4, int(cz + 0.5))] = eyes


def cape(b, z0, z1, w, col, col2=None, y0=3.4, flare=0.12):
    for z in range(z0, z1):
        ww = w + (z1 - z) * flare
        for x in range(int(-ww), int(ww) + 1):
            b[(x, int(y0 + (z1 - z) * 0.08), z)] = col2 if (col2 and (x + z) % 5 == 0) else col


def masque(b, g, cz=24.5, r=3.8, left=TRI[1], right=TRI[0], crack=None):
    """Masque de porcelaine de Tidiane : plaque blanche, orbites noires, une lueur par œil."""
    y = -int(r + 0.4)
    for x in range(-2, 3):
        for z in range(int(cz - 1), int(cz + 3)):
            if abs(x) == 2 and z == int(cz - 1):
                continue
            b[(x, y, z)] = BONE
    for x in (-1, 1):
        b[(x, y, int(cz + 1))] = EYE
        g[(x, y - 1, int(cz + 1))] = left if x < 0 else right
    if crack:
        for x, z in ((0, int(cz + 2)), (1, int(cz)), (0, int(cz - 1))):
            g[(x, y - 1, z)] = crack


def epee(n=19, bend=0.35, blade=H("#e6ebee"), edge=H("#b8c0c6"), guard=GOLD, hilt=LEA, gw=3):
    s = Vox()
    for z in range(-4, 0):
        s[(0, 0, z)] = hilt
    s[(0, 0, -5)] = guard
    for x in range(-gw, gw + 1):
        s[(x, 0, 0)] = guard
    for i in range(1, n):
        y = -int(i * bend)
        s[(0, y, i)] = blade
        s[(1, y, i)] = edge
    return s


def hampe(lo, hi, col=WOOD):
    s = Vox()
    for z in range(lo, hi):
        s[(0, 0, z)] = col
    return s


# ------------------------------------------------------------------ les 28 guildes
# Chaque fonction reçoit A (palette de la classe du héros), B (celle de sa vocation), R ;
# elle rend (corps, lueurs, arme, prise, lueur d'arme).

def tenaille(A, B, R):
    """La Tenaille : duelliste en demi-armure, grande spalière, rondache au bras, cimier à crins."""
    b, g = Vox(), Vox()
    jambes(b, DK, STD)
    jupe(b, 6, 12, 5.4, 4.8, 3.6, 3.4, lambda x, y, z: A["m"] if abs(x) > 1 or y > 0 else A["t"] if A["t"] != DK else GOLD)
    torse(b, DK)
    ell(b, (0, -0.2, 17), (5.0, 3.6, 4.0), STL)
    for i in range(10):
        b[(-4 + i, -4, 20 - i)] = B["m"]
        b[(-4 + i, -4, 19 - i)] = B["d"]
    ell(b, (0, 0.2, 12), (5.0, 3.6, 0.8), LEA)
    bras(b, None, DK, LEA)
    ell(b, (-6.4, 0.3, 20), (3.6, 3.4, 2.8), STL)  # grande spalière
    ell(b, (-6.4, 0.3, 21.8), (2.6, 2.4, 1.0), A["m"])
    ell(b, (5.8, 0.3, 19.6), (2.2, 2.2, 1.8), LEA)
    for y in range(-4, 4):  # rondache
        for z in range(9, 18):
            d = (y + 0.5) ** 2 + (z - 13.5) ** 2
            if d <= 16:
                b[(-9, y, z)] = STM if d > 11 else (B["m"] if (y + z) % 4 else A["m"])
    tete(b, SK[0])
    ell(b, (0, 0.5, 26.2), (4.3, 4.3, 3.2), STL, keep=lambda x, y, z: z >= 26)
    for z in range(22, 27):
        b[(0, -4, z)] = STM
    for i in range(12):
        t = i / 11
        cap(b, (0, -2 + t * 8, 30.5 - t * t * 7), (0, -2 + t * 8, 30.5 - t * t * 7), 1.1 - t * 0.3, B["m"] if i % 3 else B["d"])
    w = epee(21, 0.3)
    return b, g, w, (8, -2, 11), None


def seuil(A, B, R):
    """Les Veilleurs du Seuil : prêtre en plates, robe longue, mitre, auréole, bâton-lanterne."""
    b, g = Vox(), Vox()
    jupe(b, 0, 13, 6.4, 4.8, 4.6, 3.6, lambda x, y, z: GOLD if z <= 1 else (A["m"] if abs(x) <= 1 and y < 0 else B["m"]))
    ell(b, (0, 0, 17), (5.6, 4.0, 4.6), STL)
    for z in range(13, 21):
        b[(0, -4, z)] = A["m"]
        b[(0, -5, z)] = GOLD if z in (15, 18) else A["m"]
    bras(b, STL, B["m"], STM, shr=3.0, ar=2.0)
    ell(b, (0, 0, 12.5), (5.2, 3.8, 0.8), GOLD)
    tete(b, SK[1], cz=24)
    for i in range(9):  # mitre
        rr = 4.2 - i * 0.35
        ell(b, (0, 0.3, 27 + i), (rr, rr * 0.75, 0.7), B["m"] if i % 4 else GOLD)
    for z in range(27, 36):
        b[(0, -3, z)] = GOLD
    for a in range(40):  # auréole dans le dos
        t = a / 40 * math.tau
        g[(int(round(math.cos(t) * 6)), 5, int(round(26 + math.sin(t) * 6)))] = A["g"]
    w, wg = hampe(-12, 24, STM), Vox()
    for a in range(16):
        t = a / 16 * math.tau
        w[(int(round(math.cos(t) * 2.6)), int(round(math.sin(t) * 2.6)), 27)] = GOLD
    for z in range(24, 32):
        for x in (-2, 2):
            w[(x, 0, z)] = GOLD
    ell(wg, (0, 0, 27.5), (1.6, 1.6, 2.4), lambda x, y, z: A["g"])
    return b, g, w, (8, -2, 11), wg


def bastion(A, B, R):
    """Les Bastionniers : sapeur en armure lourde, boucliers empilés au dos, mortier sur l'épaule, marteau-piston."""
    b, g = Vox(), Vox()
    jambes(b, STD, DK, sep=2.8, r=2.1)
    ell(b, (0, 0, 16), (6.4, 4.8, 5.4), STL)
    for x in range(-5, 6, 2):
        px(b, (x, -4.8, 18), BRS)
        px(b, (x, -4.6, 13), BRS)
    jupe(b, 7, 12, 6.0, 5.6, 4.4, 4.2, A["m"])
    ell(b, (0, 0, 11.5), (6.2, 4.6, 0.9), LEA)
    bras(b, STL, STM, STD, sx=6.4, shr=3.4, ar=2.1, hr=2.0)
    for k in range(3):  # pavois empilés
        for x in range(-5 + k, 6 - k):
            for z in range(9 + k * 4, 16 + k * 4):
                b[(x, 6 + k, z)] = A["m"] if 1 < z - 9 - k * 4 < 6 and abs(x) < 4 - k else STM
    for i in range(12):  # tube de mortier
        cap(b, (-4 + i * 0.25, 5, 22 + i * 0.6), (-4 + i * 0.25, 5, 22 + i * 0.6), 1.7, IRN)
    ell(g, (-1, 5, 29.5), (1.0, 1.0, 0.8), lambda x, y, z: B["g"])
    tete(b, STL, cz=25, r=4.3, eyes=None)
    for x in range(-3, 4):
        g[(x, -5, 25)] = B["g"]
    for x in range(-4, 5):
        b[(x, -5, 26)] = STM
    ell(b, (0, 0.5, 29), (1.4, 3.6, 1.2), A["m"])
    w = hampe(-5, 14, IRN)
    for y in range(-3, 4):
        for z in range(14, 19):
            for x in (-1, 0, 1):
                w[(x, y, z)] = BRS if abs(y) == 3 else IRN
    return b, g, w, (9, -2, 11), None


def ascetes(A, B, R):
    """Les Ascètes de fer : moine torse nu, gantelets énormes, collier de fer, bandeau d'acier."""
    b, g = Vox(), Vox()
    sk = SK[2]
    jambes(b, B["m"], sk, r=2.0)
    for z in range(3, 7):
        for s in (-1, 1):
            ell(b, (2.5 * s, 0, z), (2.1, 2.1, 0.5), BONE)
    jupe(b, 8, 12, 5.4, 5.0, 3.8, 3.6, B["m"])
    ell(b, (0, 0, 12), (5.4, 3.8, 0.9), A["m"])
    ell(b, (0, 0, 17), (5.4, 3.8, 4.6), sk)
    for i in range(11):
        b[(-5 + i, -4, 21 - i)] = A["m"]
    for s in (-1, 1):
        ell(b, (6.0 * s, 0.3, 19.5), (2.6, 2.6, 2.2), sk)
        cap(b, (6.4 * s, 0.3, 18), (7.0 * s, -1.4, 14), 1.8, sk)
        ell(b, (7.6 * s, -1.8, 10.5), (2.9, 2.9, 3.6), STL)
        for z in (9, 12):
            ell(b, (7.6 * s, -1.8, z), (3.1, 3.1, 0.5), A["m"])
        for x in (-1, 0, 1):
            g[(int(7.6 * s) + x, -5, 8)] = B["g"]
    for a in range(26):
        t = a / 26 * math.tau
        b[(int(round(math.cos(t) * 3.4)), int(round(math.sin(t) * 2.8)), 21)] = STM
    tete(b, sk, cz=24.5, r=3.9)
    for a in range(34):
        t = a / 34 * math.tau
        b[(int(round(math.cos(t) * 4.2)), int(round(math.sin(t) * 4.2 + 0.3)), 26)] = STL
    b[(0, -4, 26)] = A["m"]
    b[(0, -5, 26)] = A["m"]
    return b, g, None, None, None


def gardechasse(A, B, R):
    """Les Gardes-chasse : gambison, mante de fourrure, rondache à mâchoires au dos, épieu à ailettes."""
    b, g = Vox(), Vox()
    jambes(b, LEA, DK)
    torse(b, A["m"], 8, 21, rx=5.0, ry=3.6)
    for z in range(9, 20, 2):
        ell(b, (0, 0.2, z), (5.1, 3.7, 0.3), A["d"])
    ell(b, (0, 0.2, 12), (5.3, 3.8, 0.8), LEA)
    b[(0, -4, 12)] = STL
    ell(b, (0, 0.8, 20.5), (7.4, 5.0, 2.4), FUR)  # mante
    cape(b, 5, 20, 5.2, B["d"], FUR)
    bras(b, None, A["m"], LEA)
    tete(b, SK[1])
    ell(b, (0, 0.5, 27.5), (4.4, 4.4, 2.5), FUR, keep=lambda x, y, z: z >= 26)
    for a in range(30):
        t = a / 30 * math.tau
        b[(int(round(math.cos(t) * 4.4)), int(round(math.sin(t) * 4.4 + 0.5)), 26)] = B["m"]
    for y in range(-4, 5):
        for z in range(10, 20):
            d = y * y + (z - 15) ** 2
            if d <= 20:
                b[(y, 7, z)] = STM if d > 15 else A["m"]
    for i in range(8):
        t = i / 8 * math.tau
        b[(int(round(math.cos(t) * 3.2)), 8, int(round(15 + math.sin(t) * 3.2)))] = STL
    w = hampe(-10, 22)
    for x in (-2, -1, 1, 2):
        w[(x, 0, 21)] = STM
    for z in range(22, 29):
        hw = 1.5 - abs(z - 24.5) * 0.35
        for x in range(-int(hw + 0.5), int(hw + 0.5) + 1):
            w[(x, 0, z)] = STL
    return b, g, w, (8, -2, 11), None


def endurcis(A, B, R):
    """Les Endurcis : un côté en plates, l'autre à nu et bandé ; manteau magenta, masque fêlé, espadon peint."""
    b, g = Vox(), Vox()
    sk = SK[3]
    jambes(b, DK, STD, r=1.9)
    ell(b, (-2.5, -0.8, 7), (2.1, 1.6, 1.8), STL)
    ell(b, (0, 0, 16.5), (5.2, 3.8, 4.8), STL)
    cape(b, 4, 22, 5.2, B["m"], B["d"])
    for z in range(4, 22):
        for x in (4, 5):
            b[(x, -3, z)] = B["m"]
        b[(-5, -3, z)] = B["m"]
    ell(b, (0, 0.2, 12), (5.3, 3.8, 0.8), B["d"])
    ell(b, (-6.2, 0.3, 20), (3.8, 3.6, 3.0), STL)
    ell(b, (-6.2, 0.3, 22.4), (2.4, 2.4, 1.0), A["m"])
    cap(b, (-6.4, 0.3, 18), (-7.2, -1.4, 11), 2.0, STM)
    ell(b, (-7.3, -1.8, 10), (1.8, 1.8, 1.7), STD)
    ell(b, (5.6, 0.3, 19.6), (2.5, 2.5, 2.1), sk)
    cap(b, (6.0, 0.3, 18), (6.6, -1.4, 11), 1.6, sk)
    for z in (13, 15, 17):
        ell(b, (6.3, -0.6, z), (1.8, 1.8, 0.45), BONE)
    ell(b, (6.7, -1.7, 10), (1.6, 1.6, 1.5), BONE)
    tete(b, sk, eyes=None)
    masque(b, g, crack=B["g"])
    for a in range(20):
        t = a / 20 * math.tau
        if math.sin(t) < -0.5:
            continue
        for i in range(R.randint(4, 7)):
            b[(int(round(math.cos(t) * 4.2)), int(round(math.sin(t) * 4.2 + 0.5 + i * 0.1)), 27 - i)] = H("#3e2718")
    w, wg = epee(24, 0.2, gw=4), Vox()
    for y in range(-5, 1):
        for i in range(2, 24):
            if -int(i * 0.2) - 1 <= y <= -int(i * 0.2) + 1:
                w[(0, y, i)] = H("#e6ebee")
    for i in range(3, 23):
        wg[(1, -int(i * 0.2), i)] = TRI[(i // 4) % 3]
    return b, g, w, (8, -2, 11), wg


def douane(A, B, R):
    """La Douane : capote longue à boutons d'or, shako à plaque, coffre cadenassé au dos, hallebarde-clé."""
    b, g = Vox(), Vox()
    jambes(b, DK, DK)
    jupe(b, 4, 21, 5.8, 4.6, 3.9, 3.4, lambda x, y, z: A["m"] if abs(x) <= 1 and y < 0 and z > 12 else B["m"])
    for z in range(13, 21, 2):
        for x in (-1, 1):
            b[(x, -4, z)] = GOLD
    ell(b, (0, 0.2, 12.5), (5.2, 3.7, 0.8), DK)
    bras(b, A["m"], B["m"], LEA)
    for s in (-1, 1):
        for x in range(4, 8):
            b[(x * s, 0, 21)] = GOLD
    tete(b, SK[0])
    ell(b, (0, -2.6, 22.8), (2.4, 1.2, 0.8), H("#3a2a20"))  # moustache
    for z in range(27, 33):
        ell(b, (0, 0.3, z), (3.6 + (z - 27) * 0.08, 3.6 + (z - 27) * 0.08, 0.6), A["d"])
    ell(b, (0, -1.2, 27), (4.2, 3.2, 0.5), DK)
    for x in (-1, 0, 1):
        for z in (29, 30):
            b[(x, -4, z)] = GOLD
    cap(b, (0, 0, 33), (0, -1, 36), 0.9, B["t"])
    for x in range(-4, 5):
        for z in range(11, 20):
            b[(x, 5, z)] = IRN if abs(x) == 4 or z in (11, 19) else STD
    b[(0, 6, 15)] = BRS
    b[(0, 6, 14)] = BRS
    ell(g, (-4, -4.5, 10), (0.9, 0.9, 1.3), lambda x, y, z: B["g"])
    w = hampe(-12, 26)
    for z in range(20, 27):
        for y in range(-4, 0):
            if z < 26 or y == -1:
                w[(0, y, z)] = STL if y > -4 or z % 2 else STM
    for a in range(12):
        t = a / 12 * math.tau
        w[(0, int(round(2 + math.cos(t) * 1.8)), int(round(23 + math.sin(t) * 1.8)))] = STL
    for z in range(26, 30):
        w[(0, 0, z)] = STL
    return b, g, w, (8, -2, 11), None


def murmures(A, B, R):
    """Les Murmures (la magilame) : lame encapuchonnée, capuche en pointe, cape runique, sabre au fil ardent."""
    b, g = Vox(), Vox()
    jambes(b, DK, SHD)
    torse(b, DK, rx=4.4, ry=3.0)
    for i in range(-4, 5):
        b[(i, -3, 13 + (i + 4) // 2)] = A["m"]
    ell(b, (0, 0.4, 12), (4.6, 3.2, 0.8), LEA)
    jupe(b, 5, 12, 4.8, 4.4, 3.4, 3.1, B["d"])
    for z in range(4, 22):
        ww = 5.4 + (22 - z) * 0.2
        for x in range(int(-ww), int(ww) + 1):
            y = int(3.4 + (22 - z) * 0.12 + abs(x) * 0.1)
            b[(x, y, z)] = B["m"]
            if (x * 3 + z * 5) % 17 == 0 and 5 < z < 19:
                g[(x, y + 1, z)] = B["g"]
    bras(b, B["d"], DK, SHD)
    tete(b, SHD, cz=24.5, eyes=A["g"], g=g)
    ell(b, (0, 0.6, 26), (4.8, 4.9, 4.9), B["m"], keep=lambda x, y, z: not (y < -1 and z < 28 and abs(x) < 4))
    for i in range(12):  # la pointe de la capuche retombe dans le dos
        t = i / 11
        cap(b, (0, 1 + t * 5, 30 + t * 3 - t * t * 7), (0, 1 + t * 5, 30 + t * 3 - t * t * 7), 2.4 - t * 1.8, B["m"] if i < 10 else A["m"])
    ell(b, (0, -3.2, 22.5), (3.2, 1.4, 1.6), A["m"])
    w, wg = Vox(), Vox()
    for z in range(-3, 1):
        w[(0, 0, z)] = LEA
    for x in (-2, -1, 1, 2):
        w[(x, 0, 1)] = B["t"] if B["t"] != DK else GOLD
    for i in range(2, 21):
        y = -int((i / 20) ** 2 * 6)
        w[(0, y, i)] = H("#2e2a36")
        wg[(0, y - 1, i)] = B["g"]
    return b, g, w, (7, -1, 11), wg


def saboteurs(A, B, R):
    """Les Saboteurs : foulard, lunettes à verres luisants, bandoulière de grenades, poignard et bombe au poing."""
    b, g = Vox(), Vox()
    jambes(b, DK, LEA)
    torse(b, DK, rx=4.4, ry=3.1)
    for z in range(13, 21):  # veste courte ouverte
        for s in (-1, 1):
            for x in (3, 4):
                b[(x * s, -3, z)] = B["m"]
        ell(b, (0, 1.2, z), (4.6, 2.4, 0.6), B["m"], keep=lambda x, y, zz: y >= 1)
    ell(b, (0, 0.3, 12), (4.7, 3.3, 0.8), LEA)
    for i in range(11):
        q = (-5 + i, -4, 21 - i)
        b[q] = LEA
        if i % 3 == 1:
            ell(b, (q[0], -4.6, q[2] - 1), (0.9, 0.9, 1.0), IRN)
            g[(q[0], -5, q[2] + 1)] = B["g"] if i % 2 else EMBER[2]
    bras(b, B["d"], DK, LEA)
    ell(b, (-7.0, -2.6, 9.2), (1.8, 1.8, 1.8), IRN)
    g[(-7, -3, 12)] = EMBER[2]
    g[(-7, -3, 13)] = H("#ffd07a")
    tete(b, SK[0], eyes=None)
    ell(b, (0, -2.4, 22.8), (3.9, 2.0, 1.9), A["m"])
    for i in range(6):
        b[(3, 3 + i, 23 - i)] = A["m"]
    ell(b, (0, 0.6, 27.2), (4.4, 4.4, 2.6), DK, keep=lambda x, y, z: z >= 26)
    for x in range(-4, 5):
        b[(x, -4, 25)] = LEA
    for s in (-1, 1):
        ell(b, (1.8 * s, -4.2, 25), (1.3, 0.8, 1.3), BRS)
        g[(int(1.8 * s), -5, 25)] = B["g"]
    ell(b, (0, 5.2, 16), (2.8, 2.2, 3.4), WOOD)
    for z in (14, 18):
        ell(b, (0, 5.2, z), (2.9, 2.3, 0.4), IRN)
    w = epee(9, 0.2, gw=1)
    return b, g, w, (7, -2, 11), None


def vent(A, B, R):
    """L'École du Vent : kimono croisé, hakama large, longue écharpe qui fuit derrière, chignon, lame droite."""
    b, g = Vox(), Vox()
    sk = SK[0]
    for s in (-1, 1):
        ell(b, (2.4 * s, -0.4, 1.1), (1.5, 2.5, 1.1), DK)
    jupe(b, 1, 12, 6.2, 4.6, 4.2, 3.4, lambda x, y, z: A["d"] if (x + 20) % 4 else tone(A["d"], 0.8))
    torse(b, B["m"], rx=4.4, ry=3.1)
    for i in range(8):
        b[(-3 + i, -3, 20 - i)] = BONE
        b[(3 - i, -4, 20 - i)] = B["d"]
    ell(b, (0, 0.2, 12.5), (4.8, 3.4, 1.0), A["m"])
    bras(b, B["m"], B["m"], sk, shr=2.6)
    ell(b, (0, 0.5, 21.5), (3.4, 2.8, 1.2), A["m"])
    for i in range(26):  # écharpe au vent
        t = i / 25
        x, y, z = 2 + t * 5, 3 + t * 14, 21.5 + math.sin(t * 7) * 1.4 + t * 2
        for w in (0, 1):
            b[(int(x) + w, int(y), int(z))] = A["m"] if i % 5 else A["d"]
    tete(b, sk, cz=24.3, r=3.7)
    ell(b, (0, 0.6, 26.5), (3.9, 3.9, 2.4), H("#1a1410"), keep=lambda x, y, z: z >= 26 or y > 1)
    ell(b, (0, 1.4, 29.5), (1.4, 1.4, 1.6), H("#1a1410"))
    for x in range(-4, 5):
        b[(x, -4, 26)] = A["m"]
    g[(0, -4, 27)] = A["g"]
    w = epee(15, 0.1, blade=H("#eef3f5"), guard=DK, hilt=A["d"], gw=1)
    return b, g, w, (7, -2, 11), None


def primes(A, B, R):
    """Les Chasseurs de primes : chapeau à large bord, poncho rayé, foulard, arbalète de poing."""
    b, g = Vox(), Vox()
    jambes(b, LEA, DK)
    torse(b, DK, rx=4.4, ry=3.1)
    for z in range(11, 22):  # poncho
        rx = 5.8 + (21 - z) * 0.35
        ell(b, (0, 0.3, z), (rx, 3.8 + (21 - z) * 0.1, 0.6),
            lambda x, y, zz: A["m"] if zz in (13, 17) else (BONE if zz == 15 else B["m"]))
    for s in (-1, 1):
        cap(b, (6.5 * s, -0.6, 14), (6.8 * s, -1.4, 11), 1.5, DK)
        ell(b, (6.9 * s, -1.7, 10), (1.5, 1.5, 1.4), LEA)
    tete(b, SK[4])
    ell(b, (0, -2.4, 22.7), (3.8, 2.0, 1.8), A["m"])
    for x in range(-8, 9):
        for y in range(-8, 9):
            if x * x + y * y <= 64:
                b[(x, y, 27 + (1 if x * x + y * y > 49 and abs(x) > 5 else 0))] = LEA
    ell(b, (0, 0.3, 29.5), (3.8, 3.8, 2.6), LEA, keep=lambda x, y, z: z >= 28)
    for a in range(30):
        t = a / 30 * math.tau
        b[(int(round(math.cos(t) * 3.9)), int(round(math.sin(t) * 3.9 + 0.3)), 28)] = A["m"]
    ell(b, (-3, 5, 17), (1.3, 1.3, 4.6), LEA)
    for i in range(3):
        b[(-3 + i - 1, 5, 22)] = H("#b8322a")
    w = Vox()
    for z in range(-3, 2):
        w[(0, 0, z)] = WOOD
    for y in range(-8, 2):
        w[(0, y, 2)] = WOOD
        w[(0, y, 3)] = WOOD
    for x in range(-5, 6):
        w[(x, -7, 3 + abs(x) // 3)] = STD
    line(w, (-5, -7, 4.5), (0, 0, 3.5), BONE)
    line(w, (5, -7, 4.5), (0, 0, 3.5), BONE)
    return b, g, w, (7, -2, 10), None


def frame(A, B, R):
    """La Frame parfaite : escrimeur masqué, habit à basques magenta doublé, jabot blanc, rapière à coquille."""
    b, g = Vox(), Vox()
    jambes(b, DK, DK, r=1.5)
    torse(b, A["d"], rx=4.1, ry=2.9)
    for z in range(6, 21):
        w = 4.6 + max(0, 12 - z) * 0.1
        for x in range(int(-w), int(w) + 1):
            if z >= 12 or abs(x) >= 2:
                b[(x, int(3.0 + (21 - z) * 0.1), z)] = B["m"]
        for s in (-1, 1):
            b[(4 * s, -3, z)] = B["m"] if z > 12 else A["m"]
            b[(5 * s, -2, z)] = B["m"]
    for z in (20, 19, 18, 17):
        for x in range(-2 + (20 - z) // 2, 3 - (20 - z) // 2):
            b[(x, -4, z)] = BONE
    ell(b, (0, 0.2, 12.5), (4.4, 3.1, 0.7), A["m"])
    bras(b, B["m"], B["m"], BONE, shr=2.4, ar=1.4)
    tete(b, SK[3], eyes=None)
    masque(b, g, left=A["g"], right=B["g"])
    ell(b, (0, 1.6, 28), (1.8, 1.8, 1.8), H("#3e2718"))
    for i in range(7):
        b[(0, int(2 + i * 0.4), 27 - i)] = H("#3e2718")
    w, wg = Vox(), Vox()
    for z in range(-3, 1):
        w[(0, 0, z)] = DK
    ell(w, (0, -0.6, 0.6), (1.8, 1.4, 0.9), GOLD, keep=lambda x, y, z: z >= 0)
    for i in range(1, 25):
        w[(0, -int(i * 0.15), i)] = H("#eef3f5")
    wg[(0, -4, 25)] = A["g"]
    return b, g, w, (7, -2, 11), wg


def pegre(A, B, R):
    """La Pègre des Quais : capuche, foulard sur le nez, poches partout, sac de butin, crochet à chaîne."""
    b, g = Vox(), Vox()
    jambes(b, LEA, DK)
    jupe(b, 6, 21, 5.0, 4.4, 3.6, 3.3, B["m"])
    ell(b, (0, 0.3, 12), (5.2, 3.7, 0.8), LEA)
    for x, z in ((-4, 10), (4, 10), (-3, 16), (3, 15), (0, 9)):
        ell(b, (x, -3.6, z), (1.1, 0.8, 1.1), LEA)
    for i in range(10):
        b[(-4 + i, -4, 20 - i)] = LEA
    bras(b, B["d"], B["m"], LEA)
    tete(b, SK[2])
    ell(b, (0, 0.9, 25.8), (4.8, 4.9, 4.9), B["d"], keep=lambda x, y, z: not (y < -1 and z < 28 and abs(x) < 4))
    ell(b, (0, -2.4, 22.6), (3.8, 2.0, 1.7), A["m"])
    for i in range(6):
        b[(-3, 3 + i, 22 - i)] = A["m"]
    ell(b, (0, 6.4, 16), (4.4, 3.2, 5.0), H("#8a7a5a"))
    for x in (-1, 0, 1):
        b[(x, 6, 21)] = LEA
    ell(g, (2, 8.5, 18), (0.9, 0.6, 0.9), lambda x, y, z: GOLD)
    w = Vox()
    for z in range(-3, 2):
        w[(0, 0, z)] = WOOD
    for i in range(12):
        t = i / 11 * math.pi * 1.2
        w[(0, int(round(-math.sin(t) * 3.5)), int(round(2 + i * 0.7 + (1 - math.cos(t)) * 0.5)))] = H("#c8d2d8")
    chain_end = (0, 0, -3)
    line(w, chain_end, (0, 2, -8), IRN)
    return b, g, w, (7, -2, 11), None


def forge(A, B, R):
    """La Forge-Braise : robe cerclée de tuyaux de laiton, réservoir de braise au dos, chapeau à cheminée, bâton-brasero."""
    b, g = Vox(), Vox()
    jupe(b, 0, 20, 6.8, 4.6, 4.8, 3.4, lambda x, y, z: BRS if z in (3, 10) else (B["t"] if z <= 1 else A["m"]))
    for z in range(4, 18):
        for s in (-1, 1):
            b[(int(3 * s), -4 - (z < 8), z)] = BRS
    bras(b, A["d"], A["m"], LEA, shr=3.0, ar=2.1)
    ell(b, (0, 0, 12.5), (5.0, 3.8, 0.8), LEA)
    ell(b, (0, 5.2, 17), (3.8, 2.6, 5.4), IRN)
    for z in range(13, 22):
        for x in (-1, 0, 1):
            g[(x, 8, z)] = R.choice(EMBER)
    for i in range(8):
        b[(3, 5 + i // 3, 22 + i)] = BRS
    tete(b, SK[1], cz=24)
    for s in (-1, 1):
        ell(b, (1.8 * s, -3.8, 25), (1.3, 0.8, 1.3), BRS)
        g[(int(1.8 * s), -5, 25)] = B["g"]
    for x in range(-7, 8):
        for y in range(-7, 8):
            if x * x + y * y <= 49:
                b[(x, y, 27)] = A["t"] if x * x + y * y > 36 else A["d"]
    for i in range(7):
        ell(b, (0, 0.3, 28 + i), (3.4 - i * 0.2, 3.4 - i * 0.2, 0.6), A["d"] if i != 1 else BRS)
    for z in range(35, 39):
        ell(b, (0, 0.3, z), (1.3, 1.3, 0.6), BRS)
    for z in range(39, 42):
        g[(0, 0, z)] = R.choice(EMBER)
    w, wg = hampe(-10, 24, IRN), Vox()
    for z in range(24, 30):
        for a in range(8):
            t = a / 8 * math.tau
            if z in (24, 29) or a % 2 == 0:
                w[(int(round(math.cos(t) * 2.4)), int(round(math.sin(t) * 2.4)), z)] = BRS
    ell(wg, (0, 0, 26.5), (1.6, 1.6, 2.4), lambda x, y, z: random.Random(x * 7 + y * 3 + z).choice(EMBER))
    return b, g, w, (8, -2, 11), wg


def souffle(A, B, R):
    """Les Sages du Souffle : vieillard à grandes manches, longue barbe, chapelet, orbes de souffle, bâton-gourde."""
    b, g = Vox(), Vox()
    jupe(b, 0, 21, 6.2, 5.0, 4.4, 3.6, lambda x, y, z: A["m"] if abs(x) >= 2 or y > 0 else B["m"])
    ell(b, (0, 0, 12.5), (5.4, 4.0, 1.0), B["t"])
    for s in (-1, 1):
        ell(b, (5.8 * s, 0.3, 19.5), (2.8, 2.8, 2.4), A["m"])
        cap(b, (6.4 * s, 0.3, 17.5), (7.6 * s, -1.6, 12), 2.2, A["m"], 3.4)
        ell(b, (7.9 * s, -2.4, 10), (1.4, 1.4, 1.4), SK[0])
    tete(b, SK[0], cz=24)
    ell(b, (0, -2.6, 20.5), (3.2, 1.8, 4.6), BONE)
    for z in range(15, 19):
        b[(0, -4, z)] = BONE
    for x in (-3, -2, -1, 1, 2, 3):
        b[(x, -4, 25)] = BONE
    ell(b, (0, 1.2, 28), (1.6, 1.6, 1.8), BONE)
    for a in range(26):
        t = a / 26 * math.tau
        ell(b, (math.cos(t) * 4.9, math.sin(t) * 3.9 - 0.4, 19 - abs(math.sin(t)) * 3), (0.7, 0.7, 0.7), WOOD)
    for k, (x, y, z) in enumerate(((-7, 3, 27), (7, 4, 30), (0, 6, 33))):
        ell(g, (x, y, z), (1.2, 1.2, 1.2), lambda xx, yy, zz: B["g"])
    w = hampe(-10, 25)
    for z in range(20, 25):
        w[(1, 0, z)] = WOOD
    ell(w, (0, 0, 26.5), (1.6, 1.6, 1.5), BRS)
    ell(w, (0, 0, 29), (2.2, 2.2, 1.9), BRS)
    line(w, (0, 0, 25), (0, -1, 21), B["t"])
    return b, g, w, (8, -2, 11), None


def augures(A, B, R):
    """Les Augures : capuche à bois de cerf, cape de plumes à pointes sombres, visage d'ombre, arc à corde luisante."""
    b, g = Vox(), Vox()
    jambes(b, LEA, DK)
    torse(b, B["d"], rx=4.4, ry=3.1)
    ell(b, (0, 0.3, 12), (4.7, 3.3, 0.8), LEA)
    for z in range(5, 22):  # cape de plumes en écailles
        ww = 5.4 + (22 - z) * 0.16
        for x in range(int(-ww), int(ww) + 1):
            y = int(3.2 + (22 - z) * 0.1)
            b[(x, y, z)] = A["d"] if (z + (x % 2)) % 3 == 0 else A["m"]
        for s in (-1, 1):
            b[(int(ww) * s, 1, z)] = A["m"]
    ell(b, (0, 0.6, 20.5), (6.4, 4.4, 2.2), A["m"])
    bras(b, None, B["d"], LEA)
    tete(b, SHD, eyes=A["g"], g=g)
    ell(b, (0, 0.8, 26), (4.7, 4.8, 4.8), B["t"], keep=lambda x, y, z: not (y < -1 and z < 28 and abs(x) < 4))
    for s in (-1, 1):  # bois de cerf
        for i in range(10):
            t = i / 9
            b[(int(s * (3 + t * 4)), int(0.5 + t), int(29 + t * 6 - t * t * 2))] = BONE
        for k in (3, 6):
            t = k / 9
            bx, bz = s * (3 + t * 4), 29 + t * 6 - t * t * 2
            for j in range(3):
                b[(int(bx - s * j * 0.4), 1, int(bz + j + 1))] = BONE
    for x in range(-2, 3):
        g[(x, -5, 27)] = A["g"] if x % 2 == 0 else A["m"]
    w, wg = Vox(), Vox()
    for a in range(27):
        t = (a / 26 - 0.5) * 2.4
        w[(0, int(round(-math.cos(t) * 5)), int(round(math.sin(t) * 14)))] = tone(WOOD, R.uniform(0.9, 1.15))
    for z in range(-13, 14):
        wg[(0, 1, z)] = A["g"]
    return b, g, w, (-7, -3, 14), wg


def diaristes(A, B, R):
    """Les Diaristes : scribe masqué, redingote aux pages volantes, béret, livre ouvert qui flotte, plume-pinceau."""
    b, g = Vox(), Vox()
    jambes(b, DK, LEA)
    torse(b, DK, rx=4.3, ry=3.0)
    for z in range(4, 21):
        w = 4.8 + (21 - z) * 0.08
        for x in range(int(-w), int(w) + 1):
            b[(x, int(3.2 + (21 - z) * 0.06), z)] = A["m"]
        for s in (-1, 1):
            for x in (3, 4):
                b[(x * s, -3, z)] = A["m"]
    ell(b, (0, 0.2, 12), (4.8, 3.4, 0.8), LEA)
    for i, x in enumerate((-4, -2, 2, 4, 0)):  # pages pendues à la ceinture
        for z in range(7 - i % 2, 11):
            b[(x, -4, z)] = BONE if z % 3 else H("#c9c1a8")
    bras(b, A["d"], A["m"], LEA)
    tete(b, SK[3], eyes=None)
    masque(b, g, left=B["g"], right=A["g"])
    ell(b, (0.8, 0.5, 28.2), (4.9, 4.6, 1.6), B["m"])
    b[(1, 0, 30)] = B["d"]
    for x in range(-9, -5):  # livre ouvert flottant devant la main gauche
        for y in range(-6, -2):
            b[(x, y, 13 + abs(x + 7) // 2)] = BONE
    for y in range(-6, -2):
        b[(-7, y, 12)] = B["d"]
    for x in (-9, -8, -6, -5):
        g[(x, -4, 15)] = B["g"]
    w, wg = hampe(-8, 16), Vox()
    for i in range(12):
        hw = 2.4 * math.sin(i / 11 * math.pi)
        for x in range(-int(hw), int(hw) + 1):
            w[(x, 0, 16 + i)] = BONE if x else H("#c9c1a8")
    for i in range(3):
        wg[(0, -1, -9 - i)] = TRI[i]
    return b, g, w, (7, -2, 11), wg


def antiquaires(A, B, R):
    """Les Antiquaires : haut-de-forme, monocle luisant, redingote, hotte de curiosités, canne à orbe."""
    b, g = Vox(), Vox()
    jambes(b, DK, DK, r=1.6)
    jupe(b, 6, 21, 5.0, 4.4, 3.6, 3.2, lambda x, y, z: BONE if abs(x) <= 1 and y < 0 and z > 15 else B["m"])
    ell(b, (0, 0.3, 12.5), (4.6, 3.5, 0.8), A["m"])
    for z in (14, 17):
        b[(2, -4, z)] = GOLD
    bras(b, B["d"], B["m"], BONE)
    tete(b, SK[0])
    g[(1, -5, 25)] = A["g"]
    ell(b, (1, -4, 25), (1.2, 0.5, 1.2), GOLD)
    b.pop((1, -4, 25), None)
    ell(b, (0, -2.5, 22.2), (2.6, 1.0, 0.8), BONE)
    for x in range(-6, 7):
        for y in range(-6, 7):
            if x * x + y * y <= 36:
                b[(x, y, 27)] = DK
    for z in range(28, 35):
        ell(b, (0, 0.3, z), (3.6, 3.6, 0.6), DK if z != 29 else A["m"])
    for z in range(10, 24):  # hotte : cadre et curiosités
        for x in (-5, 5):
            b[(x, 6, z)] = WOOD
    for x in range(-5, 6):
        for z in (10, 17, 24):
            b[(x, 6, z)] = WOOD
    ell(b, (-2.5, 7.5, 13), (2.0, 1.8, 2.6), H("#3f8a8a"))
    ell(b, (2.5, 7.5, 13.5), (1.8, 1.6, 3.0), H("#b8643a"))
    ell(b, (0, 7.5, 20.5), (3.0, 1.0, 3.0), GOLD)
    ell(b, (0, 6.8, 20.5), (2.4, 0.5, 2.4), BONE)
    b[(0, 6, 21)] = DK
    b[(1, 6, 21)] = DK
    w, wg = hampe(-10, 24, DK), Vox()
    w[(0, 0, -11)] = GOLD
    ell(w, (0, 0, 24.5), (1.4, 1.4, 1.0), GOLD)
    ell(wg, (0, 0, 27), (1.9, 1.9, 1.9), lambda x, y, z: A["g"])
    return b, g, w, (8, -2, 11), wg


def canons(A, B, R):
    """Les Poings-Canons : colosse torse nu, gantelets-canons aux bouches ardentes, sac à cheminées, lunettes relevées."""
    b, g = Vox(), Vox()
    sk = SK[1]
    jambes(b, B["m"], DK, sep=2.8, r=2.1)
    jupe(b, 8, 12, 5.8, 5.4, 4.2, 4.0, B["m"])
    ell(b, (0, 0, 12), (6.0, 4.3, 1.0), B["t"])
    ell(b, (0, 0, 17), (6.2, 4.4, 4.8), sk)
    for i in range(12):
        b[(-5 + i, -5, 21 - i)] = LEA
    for s in (-1, 1):
        ell(b, (7.0 * s, 0.3, 20), (3.2, 3.2, 2.6), sk)
        cap(b, (7.4 * s, 0.3, 18), (8.0 * s, -1.2, 14), 2.2, sk)
        for z in range(6, 14):  # gantelet-canon
            ell(b, (8.4 * s, -1.8, z), (3.0, 3.0, 0.6), BRS if z in (7, 11) else IRN)
        for x in (-1, 0, 1):
            for y in (-3, -2, -1):
                g[(int(8.4 * s) + x, y, 5)] = R.choice(EMBER)
    ell(b, (0, 5.6, 17), (4.6, 2.6, 5.0), A["m"])
    for s in (-1, 1):
        for z in range(20, 27):
            b[(3 * s, 6, z)] = IRN
        g[(3 * s, 6, 27)] = A["g"]
    tete(b, sk, cz=25, r=4.0)
    ell(b, (0, 0.6, 27.2), (4.2, 4.2, 2.2), sk, keep=lambda x, y, z: z >= 26)
    for x in range(-4, 5):
        b[(x, -3, 28)] = LEA
    for s in (-1, 1):
        ell(b, (1.9 * s, -3.4, 28.8), (1.4, 0.8, 1.4), BRS)
        g[(int(1.9 * s), -4, 29)] = A["g"]
    return b, g, None, None, None


def artilleurs(A, B, R):
    """Les Artilleurs de brousse : tenue de feuillage, chapeau mou, lunettes luisantes, long fusil à lunette."""
    b, g = Vox(), Vox()
    jambes(b, B["d"], LEA)
    torse(b, B["d"], 10, 21, rx=4.6, ry=3.2)
    ell(b, (0, 0.3, 12), (4.9, 3.5, 0.8), LEA)
    bras(b, B["d"], B["d"], LEA)
    leaf = [B["m"], B["d"], H("#5a7a3a"), H("#7a8a3a"), A["d"]]
    for _ in range(90):  # touffes de feuillage
        a = R.uniform(0, math.tau)
        z = R.uniform(8, 22)
        rx = 5.2 if z < 18 else 6.5
        ell(b, (math.cos(a) * rx, math.sin(a) * 3.8 + 0.5, z), (1.0, 1.0, 1.4), R.choice(leaf))
    tete(b, SK[2], eyes=None)
    for s in (-1, 1):
        ell(b, (1.8 * s, -3.8, 25), (1.3, 0.8, 1.3), BRS)
        g[(int(1.8 * s), -5, 25)] = A["g"]
    for x in range(-6, 7):
        for y in range(-6, 7):
            if x * x + y * y <= 36:
                b[(x, y, 27 - (1 if x * x + y * y > 25 else 0))] = B["t"]
    ell(b, (0, 0.3, 28.5), (3.6, 3.6, 1.8), B["t"], keep=lambda x, y, z: z >= 27)
    for i in range(5):
        ell(b, (R.uniform(-4, 4), R.uniform(-3, 4), 29), (1.0, 1.0, 1.0), R.choice(leaf))
    w = Vox()
    for z in range(-7, 0):
        for y in (0, 1):
            w[(0, y, z)] = WOOD
    for z in range(0, 24):
        w[(0, 0, z)] = IRN
    for z in (5, 12):
        w[(0, 0, z)] = BRS
    for z in range(4, 11):
        w[(0, 2, z)] = BRS
    ell(w, (0, 2, 3.5), (0.6, 0.6, 0.6), A["m"])
    return b, g, w, (7, -2, 11), None


def artisans(A, B, R):
    """Les Artisans : tablier de cuir, ceinture à outils, foulard magenta, masque, marteau-pinceau."""
    b, g = Vox(), Vox()
    jambes(b, DK, LEA)
    torse(b, A["m"], 10, 21, rx=4.6, ry=3.2)
    for z in range(5, 21):
        for x in range(-4, 5):
            if z < 19 or abs(x) < 3:
                b[(x, -4, z)] = LEA
    for x in range(-2, 3):
        b[(x, -5, 16)] = H("#4a3020")
    for s in (-1, 1):
        for z in range(18, 22):
            b[(3 * s, -4, z)] = LEA
    ell(b, (0, 0.2, 12), (5.0, 3.6, 0.9), H("#4a3020"))
    for x, c in ((-4, IRN), (-2, BRS), (3, WOOD), (5, IRN)):
        for z in range(9, 12):
            b[(x, -5, z)] = c
    for q, c in (((-4, -5, 14), TRI[0]), ((3, -5, 8), TRI[1]), ((1, -5, 11), TRI[2])):
        b[q] = c
    bras(b, A["d"], A["m"], LEA)
    tete(b, SK[3], eyes=None)
    masque(b, g)
    ell(b, (0, 0.8, 27.5), (4.3, 4.3, 2.3), B["m"], keep=lambda x, y, z: z >= 26)
    for i in range(5):
        b[(2 + i // 2, 4 + i, 26 - i)] = B["m"]
    for i in range(8):
        for k, c in enumerate(TRI):
            b[(-3 + k * 2, 5 + (i > 5), 14 + i)] = WOOD if i < 6 else c
    w, wg = hampe(-6, 15), Vox()
    for y in range(-3, 2):
        for z in range(15, 19):
            for x in (-1, 0, 1):
                w[(x, y, z)] = IRN
    for y in range(2, 5):
        for z in range(16, 18):
            for x in (-1, 0, 1):
                wg[(x, y, z)] = TRI[x + 1]
    return b, g, w, (7, -2, 11), wg


def ferrailleurs(A, B, R):
    """Les Ferrailleurs : armure de rebut dépareillée, marmite en casque, baril aux fentes luisantes, clé à molette géante."""
    b, g = Vox(), Vox()
    jambes(b, IRN, DK, r=1.9)
    torse(b, LEA, rx=5.0, ry=3.6)
    junk = [A["m"], B["m"], IRN, H("#8a4a2a"), STM, BRS]
    for _ in range(14):  # plaques dépareillées
        x, z = R.uniform(-4, 4), R.uniform(9, 20)
        c = R.choice(junk)
        for dx in range(-1, 2):
            for dz in range(-1, 2):
                b[(int(x + dx), -4, int(z + dz))] = c
        px(b, (x, -4.6, z), BRS)
    ell(b, (-6.2, 0.3, 20), (3.4, 3.2, 2.6), A["m"])
    ell(b, (6.0, 0.3, 20), (2.8, 3.0, 2.2), STM)
    bras(b, None, IRN, LEA)
    tete(b, SK[4])
    for z in range(26, 31):
        ell(b, (0, 0.3, z), (4.6, 4.6, 0.6), IRN if z != 27 else BRS)
    for x in (-6, -5, 5, 6):
        b[(x, 0, 29)] = IRN
    ell(b, (0, 6, 17), (3.6, 2.8, 5.4), WOOD)
    for z in (13, 17, 21):
        ell(b, (0, 6, z), (3.7, 2.9, 0.4), IRN)
    for z in range(14, 21):
        if z != 17:
            g[(0, 9, z)] = A["g"]
    w = hampe(-6, 14, IRN)
    for y in range(-3, 4):
        for z in range(14, 20):
            if not (abs(y) <= 1 and z >= 16):
                w[(0, y, z)] = tone(IRN, 1.25)
                w[(1, y, z)] = IRN
    return b, g, w, (8, -2, 11), None


def berges(A, B, R):
    """Les Coureurs des berges : pieds nus, pagne de fourrure, collier de crocs, crinière à plume, harpon à corde."""
    b, g = Vox(), Vox()
    sk = SK[1]
    for s in (-1, 1):
        ell(b, (2.5 * s, -0.4, 1.1), (1.5, 2.5, 1.1), sk)
        cap(b, (2.5 * s, 0, 2), (2.6 * s, 0.2, 10), 1.7, sk)
        for z in (3, 5, 7):
            ell(b, (2.5 * s, 0, z), (1.9, 1.9, 0.5), B["t"])
    jupe(b, 7, 12, 5.0, 4.6, 3.6, 3.4, lambda x, y, z: FUR if (x + z) % 3 else B["t"])
    ell(b, (0, 0.2, 12), (4.8, 3.4, 0.9), A["m"])
    torse(b, sk, rx=4.6, ry=3.2)
    for a in range(20):
        t = a / 20 * math.pi
        x, y = math.cos(t) * 3.6, -math.sin(t) * 3.0
        b[(int(round(x)), int(round(y)) - 1, 20 - int(math.sin(t) * 2))] = LEA
        if a % 3 == 0:
            b[(int(round(x)), int(round(y)) - 1, 19 - int(math.sin(t) * 2))] = BONE
    bras(b, sk, sk, B["t"])
    tete(b, sk, cz=24.5)
    for a in range(24):
        t = a / 24 * math.tau
        if math.sin(t) < -0.55:
            continue
        for i in range(R.randint(5, 9)):
            b[(int(round(math.cos(t) * (4.3 + i * 0.12))), int(round(math.sin(t) * 4.3 + 0.8 + i * 0.3)), 28 - i)] = H("#2a1a12")
    ell(b, (0, 1, 28), (3.8, 3.8, 1.4), H("#2a1a12"))
    for i in range(9):
        b[(3 + i // 4, int(2 + i * 0.3), 27 + i)] = B["m"] if i % 3 else A["m"]
    w = hampe(-12, 22)
    for z in range(22, 29):
        w[(0, 0, z)] = STL
    for k in range(3):
        w[(0, -1 - k // 2, 27 - k * 2)] = STL
    line(w, (0, 0, -4), (0, 3, -10), BONE)
    return b, g, w, (8, -2, 11), None


def dojo(A, B, R):
    """Le Dojo : kimono d'entraînement, ceinture noire, bandeau à longs pans, masque, poings bandés qui luisent."""
    b, g = Vox(), Vox()
    sk = SK[3]
    for s in (-1, 1):
        ell(b, (2.5 * s, -0.4, 1.1), (1.5, 2.5, 1.1), sk)
        cap(b, (2.6 * s, 0, 2), (2.6 * s, 0.2, 11), 2.0, A["m"])
    torse(b, A["m"], 12, 21, rx=4.7, ry=3.3)
    jupe(b, 9, 13, 5.0, 4.8, 3.6, 3.4, A["m"])
    for i in range(9):
        b[(-4 + i, -4, 21 - i)] = A["d"]
    ell(b, (0, 0.2, 12.5), (5.0, 3.6, 0.9), DK)
    for x, z in ((-1, 11), (-1, 10), (-1, 9), (1, 10), (1, 9)):
        b[(x, -4, z)] = DK
    bras(b, A["m"], A["m"], BONE, shr=2.8, hr=1.8)
    for s in (-1, 1):
        for k in range(3):
            g[(int(6.7 * s) + (k - 1), -4, 10)] = TRI[k]
    tete(b, sk, eyes=None)
    masque(b, g)
    for a in range(34):
        t = a / 34 * math.tau
        b[(int(round(math.cos(t) * 4.1)), int(round(math.sin(t) * 4.1 + 0.3)), 27)] = B["m"]
    for k in (-1, 1):
        for i in range(12):
            b[(int(k * (1 + i * 0.25)), int(4 + i * 0.8), int(27 - i * 0.55))] = B["m"] if i % 4 else B["d"]
    ell(b, (0, 1, 28.5), (3.8, 3.8, 1.4), H("#2a1a12"))
    return b, g, None, None, None


def acrobates(A, B, R):
    """Les Acrobates de foire : losanges d'arlequin, fraise blanche, bonnet à grelots, balles en l'air, massue."""
    b, g = Vox(), Vox()
    harl = lambda x, y, z: A["m"] if ((x + z) // 3 + (x - z) // 3) % 2 else B["m"]
    for s in (-1, 1):
        ell(b, (2.4 * s, -0.8, 1.2), (1.5, 2.8, 1.1), DK)
        b[(int(2.4 * s), -4, 3)] = GOLD
        cap(b, (2.4 * s, 0, 2), (2.4 * s, 0.2, 11), 1.6, harl(int(s * 3), 0, 5))
    for z in range(10, 21):
        ell(b, (0, 0.2, z), (4.4, 3.1, 0.6), harl)
    for z in range(20, 23):
        ell(b, (0, 0.2, z), (5.4 - (z - 20), 4.2 - (z - 20) * 0.6, 0.6), BONE)
    bras(b, None, A["m"], BONE, ar=1.4)
    tete(b, SK[0], cz=25)
    b[(0, -4, 24)] = A["d"]
    for s in (-1, 1):
        for i in range(12):
            t = i / 11
            cap(b, (s * (1 + t * 5), 0.5, 27.5 + t * 3 - t * t * 5), (s * (1 + t * 5), 0.5, 27.5 + t * 3 - t * t * 5), 1.8 - t * 0.9,
                A["m"] if s < 0 else B["m"])
        ell(b, (s * 6.4, 0.5, 25), (1.0, 1.0, 1.0), GOLD)
    ell(b, (0, 0.5, 27.8), (3.9, 3.9, 1.8), A["d"])
    for k, (x, z) in enumerate(((-8, 17), (-6, 22), (-9, 26))):
        ell(g, (x, -3, z), (1.0, 1.0, 1.0), lambda xx, yy, zz, k=k: [A["g"], B["g"], (1.0, 0.85, 0.4)][k])
    w = Vox()
    for z in range(-3, 4):
        w[(0, 0, z)] = WOOD
    ell(w, (0, 0, 8), (1.8, 1.8, 4.4), lambda x, y, z: BONE if z % 3 else A["m"])
    return b, g, w, (7, -2, 11), None


def patterns(A, B, R):
    """Les Chasseurs de patterns : armure de peaux et d'écailles, crâne de bête en spalière, masque, lame-dalle."""
    b, g = Vox(), Vox()
    jambes(b, LEA, A["d"], sep=2.7, r=2.0)
    for s in (-1, 1):
        for z in (4, 7):
            ell(b, (2.7 * s, -0.5, z), (2.3, 2.3, 1.0), A["m"])
    torse(b, LEA, 11, 21, rx=5.0, ry=3.6)
    for z in range(12, 21, 2):  # écailles
        ell(b, (0, -0.4, z), (5.2, 3.6, 0.8), A["m"] if z % 4 else A["d"], keep=lambda x, y, zz: y < 0)
    jupe(b, 6, 12, 5.8, 5.0, 4.2, 3.8, lambda x, y, z: FUR if (x + z) % 3 else A["t"])
    ell(b, (0, 0.2, 11.5), (5.4, 3.8, 0.9), DK)
    for i in range(10):
        b[(-5 + i, -4, 20 - i)] = B["m"]
    bras(b, FUR, LEA, LEA, shr=3.0)
    ell(b, (6.6, 0.3, 21), (3.4, 3.8, 2.8), BONE)  # crâne de bête
    for x in (5, 7):
        b[(x, -3, 21)] = EYE
    for k in range(5):
        b[(6 + k // 2, -3 - k, 23 + k)] = BONE
    for i in range(6):
        ell(b, (-5 - i * 0.3, 1 + i * 0.4, 21 + i * 0.8), (1.2, 1.2, 1.2), FUR)
    tete(b, SK[3], eyes=None)
    masque(b, g, crack=B["g"])
    ell(b, (0, 1.2, 27), (4.4, 4.4, 2.8), FUR, keep=lambda x, y, z: z >= 26)
    for x in range(-4, 5):
        b[(x, -4, 28)] = B["m"]
    w = Vox()
    for z in range(-5, 0):
        w[(0, 0, z)] = LEA
    for x in range(-3, 4):
        w[(x, 0, 0)] = IRN
    for i in range(1, 22):
        hw = 3 if i < 19 else 3 - (i - 18)
        for y in range(-hw, hw + 1):
            w[(0, y - 1, i)] = STM if abs(y) == hw else (BONE if i % 6 == 3 and y == 0 else H("#b8c0c6"))
            w[(1, y - 1, i)] = STD
    return b, g, w, (8, -2, 11), None


def braconniers(A, B, R):
    """Les Braconniers : houppelande élimée, capuche fourrée, piège à mâchoires au dos, lanterne, couperet."""
    b, g = Vox(), Vox()
    jambes(b, LEA, DK)
    for z in range(3, 21):
        rx = 4.8 + max(0, 12 - z) * 0.22
        ell(b, (0, 0.3, z), (rx, 3.5, 0.6), lambda x, y, zz: B["d"] if zz < 5 and (x + y) % 2 else B["m"],
            keep=(lambda x, y, zz: (x * 7 + y * 3) % 4 != 0) if z == 3 else None)
    ell(b, (0, 0.3, 12), (5.3, 3.8, 0.8), LEA)
    bras(b, B["d"], B["m"], LEA)
    tete(b, SK[4])
    ell(b, (0, 0.2, 22.4), (2.8, 1.8, 1.4), H("#3a2a20"))
    ell(b, (0, 0.9, 25.8), (4.8, 4.9, 4.9), A["m"], keep=lambda x, y, z: not (y < -1 and z < 28 and abs(x) < 4))
    for a in range(30):
        t = a / 30 * math.tau
        if math.sin(t) < -0.3:
            ell(b, (math.cos(t) * 4.5, math.sin(t) * 4.5 + 0.9, 25.8), (0.9, 0.9, 0.9) , FUR)
    for a in range(24):  # piège à mâchoires
        t = a / 24 * math.tau
        x, z = math.cos(t) * 4.4, 16 + math.sin(t) * 4.4
        b[(int(round(x)), 5, int(round(z)))] = IRN
        if a % 2 == 0:
            b[(int(round(x * 0.75)), 5, int(round(16 + math.sin(t) * 3.3)))] = STM
    for x in range(-4, 5):
        b[(x, 5, 16)] = IRN
    ell(g, (-4.5, -3.8, 9), (0.9, 0.9, 1.3), lambda x, y, z: A["g"])
    b[(-4, -4, 11)] = IRN
    w = hampe(-4, 4)
    for y in range(-4, 1):
        for z in range(4, 12):
            w[(0, y, z)] = STL if y > -4 else STM
    return b, g, w, (7, -2, 11), None


def chaos(A, B, R):
    """Chaos Agent : habit noir doublé de la couleur, haut-de-forme, masque de porcelaine, cartes qui flottent, canne."""
    b, g = Vox(), Vox()
    jambes(b, DK, DK, r=1.5)
    torse(b, DK, rx=4.3, ry=3.0)
    for z in range(15, 21):
        b[(0, -3, z)] = BONE
    for z in range(16, 20):
        b[(0, -4, z)] = A["m"]
    for z in range(5, 21):  # habit à basques
        w = 4.6 + max(0, 12 - z) * 0.15
        for x in range(int(-w), int(w) + 1):
            if z >= 12 or abs(x) >= 1:
                b[(x, int(3.0 + (21 - z) * 0.12), z)] = DK
                if z < 12:
                    b[(x, int(2.0 + (21 - z) * 0.12), z)] = A["m"]
        for s in (-1, 1):
            b[(3 * s, -3, z)] = DK if z > 12 else A["m"]
            b[(4 * s, -2, z)] = DK
    ell(b, (0, 0.2, 12.5), (4.5, 3.2, 0.7), A["m"])
    bras(b, DK, DK, BONE, shr=2.5, ar=1.5)
    tete(b, SK[3], eyes=None)
    masque(b, g, left=TRI[1], right=B["g"])
    for x in range(-6, 7):
        for y in range(-6, 7):
            if x * x + y * y <= 34:
                b[(x, y, 27)] = DK
    for z in range(28, 36):
        ell(b, (0, 0.3, z), (3.5, 3.5, 0.6), DK if z != 29 else A["m"])
    for k, (x, y, z, c) in enumerate(((-8, -2, 16, TRI[0]), (-9, 1, 21, TRI[1]), (-7, -4, 24, TRI[2]), (8, 3, 25, B["g"]))):
        for dx in (0, 1):
            for dz in range(3):
                g[(x + dx, y, z + dz + (k % 2) * dx)] = c if (dx, dz) != (0, 1) else BONE
    w, wg = hampe(-10, 23, DK), Vox()
    w[(0, 0, -11)] = GOLD
    ell(w, (0, 0, 23.5), (1.3, 1.3, 1.0), GOLD)
    ell(wg, (0, 0, 25.5), (1.5, 1.5, 1.5), lambda x, y, z: B["g"])
    return b, g, w, (8, -2, 11), wg


GUILDES = {  # paire -> dessin
    ("garde", "lame"): tenaille, ("garde", "oracle"): seuil, ("garde", "artificier"): bastion,
    ("garde", "moine"): ascetes, ("garde", "trappeur"): gardechasse, ("garde", "tidiane"): endurcis,
    ("garde", "receleur"): douane, ("lame", "oracle"): murmures, ("lame", "artificier"): saboteurs,
    ("lame", "moine"): vent, ("lame", "trappeur"): primes, ("lame", "tidiane"): frame, ("lame", "receleur"): pegre,
    ("oracle", "artificier"): forge, ("oracle", "moine"): souffle, ("oracle", "trappeur"): augures,
    ("oracle", "tidiane"): diaristes, ("oracle", "receleur"): antiquaires, ("artificier", "moine"): canons,
    ("artificier", "trappeur"): artilleurs, ("artificier", "tidiane"): artisans, ("artificier", "receleur"): ferrailleurs,
    ("moine", "trappeur"): berges, ("moine", "tidiane"): dojo, ("moine", "receleur"): acrobates,
    ("trappeur", "tidiane"): patterns, ("trappeur", "receleur"): braconniers, ("tidiane", "receleur"): chaos,
}


def sortie(hero, voc, fn):
    """Exporte le dessin de la paire pour ce héros : sa classe domine la tenue."""
    R = random.Random(sum(map(ord, fn.__name__)))
    b, g, w, grip, wg = fn(PAL[hero], PAL[voc], R)
    for q in g:  # une lueur ne se cache pas dans un voxel opaque
        b.pop(q, None)
    b = shade(b, R)
    name, sd, v = "u_%s__%s" % (hero, voc), sum(map(ord, hero + voc)), VC / K
    objs = [mesh(hero + "_body", realize(b, sd), v, skip=DOWN)]
    if w:
        wm = mesh(hero + "_weapon", realize(w, sd + 1), v)
        wm.location = (grip[0] * VC, grip[1] * VC, grip[2] * VC)
        objs.append(wm)
        if wg:
            wgm = mesh(hero + "_weaponglow", realize(wg, 0), v, ao=False, glow=True)
            wgm.parent = wm
            objs.append(wgm)
    if g:
        objs.append(mesh(hero + "_glow", realize(g, 0), v, ao=False, glow=True))
    export(name, objs)


def build(only=()):
    for (a, c), fn in GUILDES.items():
        if only and fn.__name__ not in only:
            continue
        sortie(a, c, fn)
        sortie(c, a, fn)
    print("guildes ok")


if __name__ == "__main__":
    build([s for s in os.environ.get("DELVE_ONLY", "").split(",") if s])
