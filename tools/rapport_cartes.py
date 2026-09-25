# Rapport « 220 cartes : inventaire et concertation » : HTML imprimé en PDF par Chrome.
# python tools/rapport_cartes.py <result.json> <journal.jsonl> <guide.json> <sortie.pdf>
import json, os, sys, html, base64, io, re, subprocess
from PIL import Image

E = html.escape
res, journal, guide_p, out_pdf = sys.argv[1:5]
R = json.load(open(res, encoding="utf8"))
G = json.load(open(guide_p, encoding="utf8"))
ART = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "art")
designs = []
for l in open(journal, encoding="utf8"):
    d = json.loads(l)
    if d.get("type") == "result" and isinstance(d.get("result"), dict) and "archetypes" in d["result"]:
        designs.append(d["result"])
orig = {c["id"]: c for dz in designs for c in dz["cards"]}
final = {c["id"]: c for c in R["classes"]["cards"] + [c for g in R["guilds"] for c in g["cards"]]}
PLAYERS = [("Timmy / Tammy", "veut des moments énormes, sentir sa puissance monter."),
           ("Johnny / Jenny", "veut exprimer des combos, trouver des interactions entre classes."),
           ("Spike", "veut gagner : cherche les cartes cassées, les cartes mortes, les coûts faux."),
           ("Vorthos", "veut un monde cohérent : noms, textes, identité des classes."),
           ("Melvin", "veut l'élégance mécanique : règles claires, implémentables, sans redondance.")]
ORDER = ["garde", "lame", "oracle", "artificier", "moine", "trappeur", "tidiane", "receleur"]
NAME = {k: G["heroes"][k]["name"] for k in ORDER}
COL = {k: "#" + G["heroes"][k]["color"] for k in ORDER}
RAR = {1: "Commune", 2: "Peu commune", 3: "Rare", 4: "Légendaire"}
KIND = {"atk": "Attaque", "skill": "Compétence", "move": "Déplacement", "power": "Pouvoir"}
GUILDS = G["guilds"]


def thumb(cid):
    p = os.path.join(ART, "card_%s.png" % cid)
    if not os.path.exists(p):
        return ""
    im = Image.open(p).convert("RGB")
    im.thumbnail((150, 100))
    b = io.BytesIO()
    im.save(b, "JPEG", quality=72)
    return "<img class='th' src='data:image/jpeg;base64,%s'>" % base64.b64encode(b.getvalue()).decode()


def md(t):
    """Markdown léger du digest : titres, listes, gras."""
    out, inlist = [], False
    for line in t.split("\n"):
        s = E(line.strip())
        s = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", s)
        s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
        if s.startswith("- ") or re.match(r"^\d+\. ", s):
            if not inlist:
                out.append("<ul>")
                inlist = True
            out.append("<li>%s</li>" % re.sub(r"^(- |\d+\. )", "", s))
            continue
        if inlist:
            out.append("</ul>")
            inlist = False
        if s.startswith("### "):
            out.append("<h4>%s</h4>" % s[4:])
        elif s.startswith("## "):
            out.append("<h3>%s</h3>" % s[3:])
        elif s.startswith("# "):
            out.append("<h3>%s</h3>" % s[2:])
        elif s:
            out.append("<p>%s</p>" % s)
    if inlist:
        out.append("</ul>")
    return "\n".join(out)


def ctext(c):
    t = c.get("text", "")
    f = dict(c.get("fields", {}))
    f.update({k: c[k] for k in ("cost",) if k in c})
    for k, v in f.items():
        if isinstance(v, (int, float)) and not isinstance(v, bool):
            t = t.replace("{%s}" % k, str(v))
    if c.get("range"):
        t = t.replace("{rmax}", str(c["range"][1]))
    return t


parts = []
parts.append("""<section class='cover'><div class='kick'>TonerTactic · 25 septembre 2026</div><h1>220 cartes<br>inventaire et concertation</h1>
<p class='lede'>Dix cartes de plus par classe, cinq de plus par guilde. Trois routes par classe, des ponts entre les classes pour que la vocation
fasse naître des combos. Ce carnet montre d'où viennent les cartes, qui les a contestées, et pourquoi elles sont comme elles sont.</p>
<p class='meta'>17 agents · 2,4 millions de jetons · 48 minutes de concertation · 80 cartes de classe · 140 cartes de guilde · %d mécaniques neuves</p></section>""" % (len(R["classes"]["mechanics"]) + sum(len(g["mechanics"]) for g in R["guilds"])))

parts.append("""<section><h2>1. La méthode</h2>
<p>Tidiane a demandé de « discuter entre plusieurs agents et de simuler différents archétypes de joueurs ». La concertation s'est faite en cinq temps, chacun confié à des agents séparés qui ne voyaient que ce qu'on leur donnait :</p>
<ol><li><b>Recherche</b> : un agent a lu les wikis de Duelyst, de Magic (pages Multicolored et Player type) et de One Step From Eden (sorts et marques) et en a tiré un digest actionnable.</li>
<li><b>Classes</b> : quatre designers, deux classes chacun. Pour chaque classe : trois archétypes, dix cartes (4 communes, 4 peu communes, 2 rares), au plus deux mécaniques neuves.</li>
<li><b>Guildes</b> : quatre designers, sept guildes chacun. Cinq cartes par guilde (1 commune, 2 peu communes, 2 rares), chacune reliant un archétype de chaque classe de la paire.</li>
<li><b>Panel</b> : cinq joueurs types de Magic (Timmy, Johnny, Spike, Vorthos, Melvin). Chacun a simulé des runs tour par tour avec 3 énergie et 3 cartes par héros, puis rendu un verdict carte par carte.</li>
<li><b>Révision</b> : trois leads (un pour les classes, deux pour les guildes) ont tranché entre les propositions et les objections, réduit les mécaniques, fermé les boucles infinies.</li></ol>
<p>Les arbitrages du lead ne suivent pas le panel aveuglément : deux alertes de Spike ont été vérifiées dans le code et jugées fausses (voir la partie 5).</p></section>""")

parts.append("<section><h2>2. Ce que la recherche a rapporté</h2><div class='digest'>%s</div></section>" % md(R["research"]))

# archétypes
arch = "<section><h2>3. Trois routes par classe</h2><p>Lisibles dès le premier ou le deuxième butin : le butin propose désormais des cartes d'archétypes différents et affiche leur nom.</p><div class='grid2'>"
notes = R["classes"]["notes"]
m = re.search(r"ARCHÉTYPES PAR CLASSE.*?\n(.*?)\n\n", notes, re.S)
lines = {}
if m:
    for l in m.group(1).split("\n"):
        mm = re.match(r"- (\w+) : (.*)", l.strip())
        if mm:
            lines[mm.group(1).lower()] = mm.group(2)
for k in ORDER:
    arch += "<div class='box' style='border-color:%s'><h4 style='color:%s'>%s</h4><p>%s</p></div>" % (COL[k], COL[k], NAME[k], E(lines.get(NAME[k].lower(), "")))
arch += "</div><h3>Les archétypes de guilde</h3><table class='t'><tr><th>Guilde</th><th>Archétype</th><th>L'idée</th></tr>"
for dz in designs[4:]:
    for a in dz["archetypes"]:
        arch += "<tr><td>%s</td><td><b>%s</b></td><td>%s</td></tr>" % (E(a["classe"]), E(a["name"]), E(a["pitch"]))
arch += "</table></section>"
parts.append(arch)

# mécaniques
mech = "<section><h2>4. Les mécaniques neuves</h2><p>Chaque mécanique est spécifiée pour être codée sans ambiguïté ; toutes sont maintenant dans le moteur.</p>"
for title, ms in [("Classes", R["classes"]["mechanics"])] + [("Guildes %s" % ("0 à 13" if i == 0 else "14 à 27"), g["mechanics"]) for i, g in enumerate(R["guilds"])]:
    mech += "<h3>%s</h3>" % title
    for mm in ms:
        mech += "<div class='mech'><b>%s</b> <span class='tag'>%s</span><p>%s</p></div>" % (E(mm["key"]), E(mm["kind"]), E(mm["spec"]))
mech += "</section>"
parts.append(mech)

# concertation
con = "<section><h2>5. La concertation : arguments et contre-arguments</h2>"
con += "<h3>Le panel des joueurs types</h3>"
for i, rv in enumerate(R["reviews"]):
    pn, pd = PLAYERS[i]
    con += "<div class='player'><h3>%s</h3><p class='who'>%s</p><h4>Ses runs simulées</h4>%s<h4>Ses verdicts</h4><table class='t'><tr><th>Carte</th><th>Verdict</th><th>Argument et proposition</th></tr>" % (pn, pd, md(rv["simulations"]))
    for v in rv["verdicts"]:
        nm = final.get(v["id"], orig.get(v["id"], {})).get("name", v["id"])
        con += "<tr><td><b>%s</b><br><span class='id'>%s</span></td><td class='v %s'>%s</td><td>%s</td></tr>" % (E(nm), E(v["id"]), v["verdict"], v["verdict"], E(v["change"]))
    con += "</table><h4>Son avis global</h4>%s</div>" % md(rv["global"])
con += "<h3>Les arbitrages des leads</h3>"
con += "<div class='lead'><h4>Classes</h4>%s</div>" % md(R["classes"]["notes"])
for i, g in enumerate(R["guilds"]):
    con += "<div class='lead'><h4>Guildes %s</h4>%s</div>" % ("0 à 13" if i == 0 else "14 à 27", md(g["notes"]))
# cartes les plus débattues : proposition, objections, version finale
debate = {}
for i, rv in enumerate(R["reviews"]):
    for v in rv["verdicts"]:
        debate.setdefault(v["id"], []).append((PLAYERS[i][0], v["verdict"], v["change"]))
hot = sorted(debate.items(), key=lambda kv: -len(kv[1]))
con += "<h3>Les cartes les plus débattues</h3><p>Pour chaque carte citée par au moins deux joueurs types : la proposition du designer, les objections, puis ce qui a été gardé.</p>"
for cid, vs in hot:
    if len(vs) < 2:
        continue
    o = orig.get(cid)
    f = final.get(cid)
    con += "<div class='debate'><h4>%s</h4>" % E((f or o or {}).get("name", cid))
    if o:
        con += "<p class='prop'><b>Proposition du designer</b> (%s, coût %s) : %s<br><i>%s</i></p>" % (RAR.get(o["rar"], ""), o["cost"], E(ctext(o)), E(o.get("synergies", "")))
    for pn, vv, ch in vs:
        con += "<p class='obj'><b>%s</b> · <span class='v %s'>%s</span> : %s</p>" % (pn, vv, vv, E(ch))
    if f:
        con += "<p class='fin'><b>Version finale</b> (%s, coût %s) : %s</p>" % (RAR.get(f["rar"], ""), f["cost"], E(ctext(f)))
    else:
        con += "<p class='fin'><b>Retirée</b> de la version finale.</p>"
    con += "</div>"
con += "</section>"
parts.append(con)

# inventaire
inv = "<section><h2>6. Inventaire complet des cartes</h2><p>Toutes les cartes du jeu au niveau 1, les nouvelles marquées ✦. Texte au niveau 1 ; chaque carte a deux niveaux d'amélioration.</p>"
cards = G["cards"]
new_ids = set(final)
for k in ORDER:
    cs = [c for c in cards if c["cls"] == [k]]
    cs.sort(key=lambda c: (c["id"] in new_ids, c["rar"], c["name"]))
    inv += "<h3 style='color:%s'>%s · %d cartes (%d nouvelles)</h3><table class='inv'>" % (COL[k], NAME[k], len(cs), sum(c["id"] in new_ids for c in cs))
    for c in cs:
        inv += "<tr><td>%s</td><td><b>%s%s</b><br><span class='id'>%s · %s · coût %s%s</span></td><td>%s</td></tr>" % (
            thumb(c["id"]), "✦ " if c["id"] in new_ids else "", E(c["name"]), RAR[c["rar"]], KIND.get(c["kind"], ""), c["lv"][0]["cost"],
            (" · " + E(c["arch"])) if c.get("arch") else "", E(c["lv"][0]["text"]).replace("\n", "<br>"))
    inv += "</table>"
for gi, gl in enumerate(GUILDS):
    cs = [c for c in cards if len(c["cls"]) == 2 and c["cls"] == [gl[0], gl[1]]]
    cs.sort(key=lambda c: (c["id"] in new_ids, c["rar"], c["name"]))
    inv += "<h3>%s · %s + %s</h3><p class='rule'>%s</p><table class='inv'>" % (E(gl[2]), NAME[gl[0]], NAME[gl[1]], E(gl[3]))
    for c in cs:
        inv += "<tr><td>%s</td><td><b>%s%s</b><br><span class='id'>%s · %s · coût %s%s</span></td><td>%s</td></tr>" % (
            thumb(c["id"]), "✦ " if c["id"] in new_ids else "", E(c["name"]), RAR[c["rar"]], KIND.get(c["kind"], ""), c["lv"][0]["cost"],
            (" · " + E(c["arch"])) if c.get("arch") else "", E(c["lv"][0]["text"]).replace("\n", "<br>"))
    inv += "</table>"
inv += "</section>"
parts.append(inv)

CSS = """
@page { size: A4; margin: 14mm 13mm; }
body { font-family: 'Lato', 'Segoe UI', sans-serif; font-size: 9.6pt; color: #231c16; line-height: 1.42; }
h1 { font-family: 'Fraunces', Georgia, serif; font-size: 40pt; line-height: 1.05; margin: 8mm 0 6mm; color: #3a2414; }
h2 { font-family: 'Fraunces', Georgia, serif; font-size: 20pt; color: #7a3a1a; border-bottom: 2px solid #e6b84f; padding-bottom: 2mm; page-break-before: always; }
h3 { font-family: 'Fraunces', Georgia, serif; font-size: 13pt; color: #5a2f18; margin: 6mm 0 2mm; }
h4 { font-size: 10.5pt; margin: 3mm 0 1mm; color: #3a2a20; }
.cover { height: 250mm; display: flex; flex-direction: column; justify-content: center; }
.kick { letter-spacing: .2em; text-transform: uppercase; color: #b8643a; font-size: 9pt; }
.lede { font-size: 12pt; max-width: 150mm; }
.meta { color: #6a5a4a; }
.grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 4mm; }
.box { border-left: 4px solid; padding: 2mm 4mm; background: #faf5ec; break-inside: avoid; }
.t, .inv { border-collapse: collapse; width: 100%; font-size: 8.8pt; }
.t td, .t th, .inv td { border-bottom: 1px solid #e8dcc8; padding: 1.4mm 2mm; vertical-align: top; }
.t th { text-align: left; background: #f3e8d4; }
.inv tr { break-inside: avoid; }
.th { width: 36mm; border-radius: 2mm; }
.id { color: #8a7a68; font-size: 8pt; }
.mech { break-inside: avoid; margin: 2mm 0; padding: 2mm 3mm; background: #f6f1fa; border-left: 3px solid #9b50d8; }
.mech p { margin: 1mm 0 0; }
.tag { font-size: 7.5pt; background: #e8dcf4; padding: 0 2mm; border-radius: 2mm; }
.player { break-before: page; }
.who { font-style: italic; color: #6a5a4a; }
.v { font-weight: bold; }
.v.garder { color: #3a8a3a; } .v.ajuster { color: #c9882a; } .v.remplacer { color: #c0402a; }
.lead { background: #fbf6ea; padding: 2mm 4mm; border-left: 3px solid #e6b84f; margin: 3mm 0; }
.debate { break-inside: avoid; border: 1px solid #e8dcc8; border-radius: 2mm; padding: 2mm 4mm; margin: 3mm 0; }
.prop { background: #f3efe6; padding: 1.5mm 2mm; }
.obj { margin: 1mm 0 1mm 4mm; }
.fin { background: #eaf5ea; padding: 1.5mm 2mm; }
.rule { font-style: italic; color: #6a5a4a; margin: 0 0 2mm; }
code { font-size: 8pt; background: #f0e8da; padding: 0 1mm; }
.digest p, .digest li { font-size: 9pt; }
"""
doc = "<!doctype html><html lang='fr'><head><meta charset='utf-8'><title>TonerTactic · cartes et concertation</title><style>%s</style></head><body>%s</body></html>" % (CSS, "\n".join(parts))
html_p = os.path.splitext(out_pdf)[0] + ".html"
open(html_p, "w", encoding="utf8").write(doc)
chrome = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
subprocess.run([chrome, "--headless=new", "--disable-gpu", "--no-pdf-header-footer", "--print-to-pdf=" + out_pdf, "file:///" + html_p.replace("\\", "/")], check=True)
print("PDF :", out_pdf)
