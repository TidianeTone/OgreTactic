extends SceneTree
## Exporte toutes les cartes (texte résolu au niveau 1) en JSON, pour écrire les prompts d'illustration.
func _init() -> void:
	var out := []
	for id in Data.all_ids():
		var d: Dictionary = Data.def(id)
		var c := Data.card({"id": id, "lvl": 1, "h": Data.classes_of(id)[0]})
		out.append({"id": id, "name": d.name, "cls": Data.classes_of(id), "rar": d.get("rar", 1), "kind": d.kind, "target": d.get("target", "foe"),
			"range": d.get("range", [1, 1]), "text": Data.card_text(c), "keys": d.keys()})
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "\t"))
	quit()
