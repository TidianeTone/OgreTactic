"""Extrait les textes affichables des scripts (.gd) -> tools/i18n/pieces.json.
Chaque littéral est découpé aux trous de format (%d, %s, {dmg}, \n, BBCode) ; on garde
le littéral entier (correspondance exacte) et ses morceaux (traduction par fragments)."""
import json, re, sys, pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
HOLE = re.compile(r'%[-+0-9.]*[dsfvx]|\{[a-z_0-9]*\}|\n|\t|\[/?[a-z_]+(?:=[^\]]*)?\]|[\n\t]')
EDGE = " \t·—–-:;,.!?()«»\"'/|+×=→←↑↓•…"
ACC = re.compile(r"[À-ÿœŒ]")

def lits(line):
    """Littéraux "..." d'une ligne (scanner à la main : la regex s'emballait)."""
    out, i, n = [], 0, len(line)
    while i < n:
        c = line[i]
        if c == "#":
            break
        if c == '"':
            j, buf = i + 1, []
            while j < n and line[j] != '"':
                if line[j] == "\\" and j + 1 < n:
                    buf.append(line[j:j + 2] if line[j + 1] != '"' else '"')
                    j += 2
                    continue
                buf.append(line[j])
                j += 1
            out.append("".join(buf))
            i = j + 1
            continue
        i += 1
    return out


def keep(s):
    if len(s) < 2 or s.startswith(("res://", "user://", "#", "%")) or "://" in s:
        return False
    if not re.search(r"[A-Za-zÀ-ÿ]", s):
        return False
    if re.fullmatch(r"[a-z0-9_#./:\-]+", s) and not ACC.search(s):
        return False  # identifiant
    return True

def pieces(s):
    out = []
    for p in HOLE.split(s):
        p = p.strip(EDGE)
        if len(p) >= 2 and re.search(r"[A-Za-zÀ-ÿ]", p):
            out.append(p)
    return out

def main():
    full, frag = set(), set()
    for f in sorted((ROOT / "scripts").glob("*.gd")):
        txt = f.read_text(encoding="utf-8")
        for line in txt.splitlines():
            code = line.split("##")[0] if line.lstrip().startswith("##") else line
            if code.lstrip().startswith("#"):
                continue
            for s in lits(code):
                if not keep(s):
                    continue
                full.add(s)
                for p in pieces(s):
                    frag.add(p)
    old = {}
    dst = ROOT / "tools/i18n/en.json"
    if dst.exists():
        old = json.loads(dst.read_text(encoding="utf-8"))
    todo = sorted((full | frag) - set(old))
    (ROOT / "tools/i18n/todo.json").write_text(json.dumps(todo, ensure_ascii=False, indent=0), encoding="utf-8")
    print(len(full), "littéraux,", len(frag), "morceaux,", len(todo), "à traduire")

main()
