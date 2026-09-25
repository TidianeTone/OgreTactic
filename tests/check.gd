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
	for id in Data.all_ids():
		for lv in [1, 2, 3]:
			var c := Data.card({"id": id, "lvl": lv})
			if Data.card_text(c).contains("{"):
				print("texte non résolu : ", id, " niveau ", lv)
				fails += 1
			if not Data.HEROES.has(c.owner):
				fails += 1
			if c.has("trig") and not Data.TRIGGERS.has(c.trig.on):
				print("déclencheur inconnu : ", id)
				fails += 1
		if Data.upgrade_diff({"id": id, "lvl": 1}, {"id": id, "lvl": 2}) == "" or Data.upgrade_diff({"id": id, "lvl": 2}, {"id": id, "lvl": 3}) == "":
			print("palier vide : ", id)
			fails += 1
	# multiclasse : 28 guildes de 11 cartes
	for g in Guildes.LIST.size():
		var n := [0, 0, 0, 0, 0]
		for id in Guildes.cards_of(g):
			n[Guildes.CARDS[id].rar] += 1
		if n != [0, 2, 3, 5, 1]:  # 6 d'origine + 5 du 25/09 (1 commune, 2 peu communes, 2 rares)
			print("guilde incomplète : ", Guildes.LIST[g][2], " ", n)
			fails += 1
	if Guildes.index("lame", "garde") != 0 or Guildes.index("receleur", "tidiane") != 27:
		print("index de guilde faux")
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
