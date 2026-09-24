extends SceneTree
## Vérif logique sans rendu : godot --headless --path . --script res://tests/check.gd

func _init() -> void:
	var fails := 0
	# chaque script doit compiler (une erreur de typage bloque le jeu entier)
	for path in ["res://scripts/main.gd", "res://scripts/battle.gd", "res://scripts/ui.gd", "res://scripts/unit.gd", "res://scripts/fx.gd"]:
		var sc: GDScript = load(path)
		if sc == null or not sc.can_instantiate():
			print("ne compile pas : ", path)
			fails += 1
	for k in Data.STARTER:
		assert(Data.HEROES.has(k), k)
		for id in Data.STARTER[k]:
			assert(Data.CARDS.has(id), id)
	for id in Data.CARDS:
		var c := Data.card({"id": id, "lvl": 5})
		if Data.card_text(c).contains("{"):
			print("texte non résolu : ", id)
			fails += 1
		if not Data.HEROES.has(c.owner):
			fails += 1
	var b := Board.new()
	for s in 200:
		for bi in 3:
			b.generate(s * 31 + bi, Data.BIOMES[bi], [12, 14, 16, 18][s % 4], Board.ARCHETYPES[s % 4])
			if not b._connected():
				print("non connexe seed ", s)
				fails += 1
			var hs := b.spawn_cells("hero", 3)
			var fs := b.spawn_cells("foe", 5, hs)
			if hs.size() < 3 or fs.size() < 5:
				print("spawns manquants seed ", s)
				fails += 1
			for c in hs:
				if fs.has(c):
					print("spawn partagé seed ", s)
					fails += 1
	b.free()
	print("OK" if fails == 0 else "ÉCHECS : %d" % fails)
	quit(1 if fails else 0)
