extends SceneTree
## Génère et construit des salles sur tous les biomes ; signale les lentes et la mémoire.
func _init() -> void:
	var root3 := Node3D.new()
	get_root().add_child(root3)
	var b := Board.new()
	root3.add_child(b)
	for bi in Data.BIOMES.size():
		for s in 12:
			var seed := 5 + s * 7 + bi * 1000
			var t := Time.get_ticks_msec()
			b.generate(seed, Data.BIOMES[bi], 16 + 2 * (s % 3), Board.ARCHETYPES[s % 4], true)
			var t2 := Time.get_ticks_msec()
			b.build_visuals()
			var t3 := Time.get_ticks_msec()
			if t3 - t > 1500:
				printerr("LENT biome %d graine %d : génération %d ms, visuels %d ms" % [bi, seed, t2 - t, t3 - t2])
		printerr("biome %d ok, mémoire %d Mo" % [bi, OS.get_static_memory_usage() / 1048576])
	quit()
