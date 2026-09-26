"""Fusionne les lots traduits (en_*.json) dans en.json, puis copie vers assets/i18n/en.json (lu par scripts/lang.gd)."""
import json, glob, os, re, shutil
D = os.path.dirname(os.path.abspath(__file__))
dst = os.path.join(D, "en.json")
out = json.load(open(dst, encoding="utf-8")) if os.path.exists(dst) else {}
for f in sorted(glob.glob(os.path.join(D, "en_*.json"))):
    out.update(json.load(open(f, encoding="utf-8")))
# garde-fous : une traduction vide ou qui perd un trou de format est ignorée
HOLE = re.compile(r"%[-+0-9.]*[dsf]|\{[a-z_0-9]*\}")
bad = [k for k, v in out.items() if not isinstance(v, str) or (v == "" and k != "") or sorted(HOLE.findall(k)) != sorted(HOLE.findall(v))]
for k in bad:
    print("écarté :", repr(k)[:80], "->", repr(out[k])[:80])
    del out[k]
json.dump(out, open(dst, "w", encoding="utf-8"), ensure_ascii=False, indent=0, sort_keys=True)
os.makedirs(os.path.join(D, "..", "..", "assets", "i18n"), exist_ok=True)
shutil.copy(dst, os.path.join(D, "..", "..", "assets", "i18n", "en.json"))
print(len(out), "entrées")
