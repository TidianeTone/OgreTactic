class_name Lang
extends Translation
## L'anglais : le jeu est écrit en français, chaque texte affiché passe par ici (traduction automatique
## des Label, Button, RichTextLabel, Label3D, infobulles). Correspondance exacte d'abord, sinon on
## recolle les morceaux traduits (tools/i18n : extract.py -> agents -> en.json) autour des nombres.

static var on := false
var exact := {}        # phrase entière -> traduction
var by_word := {}      # premier mot d'un morceau -> [morceaux, du plus long au plus court]
var cache := {}
var made := {}         # sorties déjà anglaises : ne pas les retraduire


static func setup(english: bool) -> void:
	## À appeler au démarrage et quand le réglage change.
	on = english
	if english and TranslationServer.get_translation_object("en") == null:
		var t := Lang.new()
		t.locale = "en"
		t.load_dict("res://assets/i18n/en.json")
		TranslationServer.add_translation(t)
	TranslationServer.set_locale("en" if english else "fr")


static func teardown() -> void:
	## À la sortie : le serveur de traduction ne doit pas survivre au script (plantage à la fermeture).
	var o := TranslationServer.get_translation_object("en")
	if o is Lang:
		TranslationServer.remove_translation(o)


static func t(s: String) -> String:
	## Pour les textes qui ne passent pas par un nœud (modèles de cartes avant leurs {valeurs}, etc.).
	return String(TranslationServer.translate(s)) if on else s


static func mark(s: String) -> String:
	## Ce texte est déjà en anglais : un nœud qui l'affiche ne le retraduira pas.
	var o := TranslationServer.get_translation_object("en")
	if on and o is Lang:
		(o as Lang).made[s] = true
	return s


func load_dict(path: String) -> void:
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not d is Dictionary:
		push_warning("i18n : %s illisible" % path)
		return
	for k: String in d:
		var v: String = d[k]
		exact[k] = v
		var w := _first_word(k)
		if w == "":
			continue
		if not by_word.has(w):
			by_word[w] = []
		by_word[w].append(k)
	for w in by_word:
		by_word[w].sort_custom(func(a, b): return a.length() > b.length())


static func _is_letter(ch: String) -> bool:
	return ch.to_upper() != ch.to_lower() or (ch >= "0" and ch <= "9")


static func _first_word(s: String) -> String:
	var i := 0
	while i < s.length() and _is_letter(s[i]):
		i += 1
	return s.substr(0, i)


func _get_message(src: StringName, _ctx: StringName) -> StringName:
	var s := String(src)
	if s.length() < 2 or made.has(s):
		return src
	if cache.has(s):
		return cache[s]
	var out: String = exact.get(s, "")
	if out == "":
		# entre les balises et les retours à la ligne, puis phrase par phrase : la plupart retombent sur une entrée exacte
		out = _split(s, _rx(0), 1)
	if cache.size() > 20000:
		cache.clear()
		made.clear()
	cache[s] = out
	made[out] = true
	return out


var _cuts: Array = []


func _rx(k: int) -> RegEx:
	if _cuts.is_empty():
		_cuts = [RegEx.create_from_string("\\[[^\\]]*\\]|\\n|\\{[a-z_0-9]*\\}"), RegEx.create_from_string("[.!?] | [·—] ")]
	return _cuts[k]


func _split(s: String, rx: RegEx, depth: int) -> String:
	## Découpe s ; au niveau des phrases, on recolle le plus long groupe de phrases voisines qui existe tel quel.
	var parts: Array = []  # [début, fin] des segments ; les séparateurs sont entre deux
	var last := 0
	for m in rx.search_all(s):
		parts.append([last, m.get_start()])
		last = m.get_end()
	parts.append([last, s.length()])
	var out := ""
	var i := 0
	while i < parts.size():
		var done := false
		if depth == 2:
			for j in range(parts.size() - 1, i, -1):
				var r := _exact(s.substr(parts[i][0], parts[j][1] - parts[i][0]))
				if r != "":
					out += r + s.substr(parts[j][1], (parts[j + 1][0] if j + 1 < parts.size() else s.length()) - parts[j][1])
					i = j + 1
					done = true
					break
		if done:
			continue
		out += _seg(s.substr(parts[i][0], parts[i][1] - parts[i][0]), depth)
		if i + 1 < parts.size():
			out += s.substr(parts[i][1], parts[i + 1][0] - parts[i][1])
		i += 1
	return out


func _exact(seg: String) -> String:
	## Entrée exacte (espaces et ponctuation finale mis à part, majuscules tolérées), "" sinon.
	var core := seg.strip_edges()
	if core.length() < 2:
		return seg
	var lead := seg.substr(0, seg.find(core))
	var trail := seg.substr(lead.length() + core.length())
	if exact.has(core):
		return lead + exact[core] + trail
	var punct := ""
	while core.length() > 1 and core[core.length() - 1] in [".", ":", "!", "?", ",", ";"]:
		punct = core[core.length() - 1] + punct
		core = core.substr(0, core.length() - 1).strip_edges()
	punct = punct.replace(" ", "")
	if exact.has(core):
		return lead + exact[core] + punct + trail
	if core == core.to_upper() and core.to_lower() != core:
		var low := core[0] + core.substr(1).to_lower()
		if exact.has(low):
			return lead + String(exact[low]).to_upper() + punct + trail
	return ""


func _seg(seg: String, depth: int) -> String:
	## Un segment sans balise : entrée exacte, sinon phrase par phrase, sinon les morceaux.
	var r := _exact(seg)
	if r != "":
		return r
	if depth == 1:
		return _split(seg, _rx(1), 2)
	return _pieces(seg)


func _pieces(s: String) -> String:
	## Balayage unique : à chaque début de mot, le plus long morceau connu qui commence là.
	var out := ""
	var i := 0
	var n := s.length()
	while i < n:
		if s[i] == "[" or s[i] == "{":  # balise BBCode ou {valeur} recopiée telle quelle, et le chemin d'une image aussi
			var img := s.substr(i, 4) == "[img"
			var e := s.find("[/img]" if img else ("]" if s[i] == "[" else "}"), i)
			var close := e + (6 if img else 1)
			if e >= 0:
				out += s.substr(i, close - i)
				i = close
				continue
		if not _is_letter(s[i]) or (i > 0 and (_is_letter(s[i - 1]) or s[i - 1] in ["_", "/"])):
			out += s[i]
			i += 1
			continue
		var j := i
		while j < n and _is_letter(s[j]):
			j += 1
		var w := s.substr(i, j - i)
		var hit := ""
		for cand in [w, w[0].to_upper() + w.substr(1), w[0].to_lower() + w.substr(1)]:
			if hit != "" or not by_word.has(cand):
				continue
			for k: String in by_word[cand]:
				var seg := s.substr(i, k.length())
				var ok: bool = seg == k or (cand != w and seg.substr(1) == k.substr(1))
				if ok and (i + k.length() >= n or not (_is_letter(s[i + k.length()]) or s[i + k.length()] == "_")):
					hit = k
					break
		if hit == "":
			out += w
			i = j
			continue
		var tr: String = exact[hit]
		if hit[0] != s[i] and tr != "":  # même morceau, casse de la première lettre différente
			tr = (tr[0].to_upper() if s[i] == s[i].to_upper() else tr[0].to_lower()) + tr.substr(1)
		out += tr
		i += hit.length()
	# typographie anglaise : pas d'espace avant « : ; ! ? »
	for p in [" :", " ;", " !", " ?"]:
		out = out.replace(p, p.substr(1))
	return out.replace("« ", "\"").replace(" »", "\"")
