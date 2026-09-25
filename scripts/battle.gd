class_name Battle
extends Node
## Un combat : pioche, main, énergie, cartes, déplacement libre, objets du décor,
## passifs d'équipement (à la FFTA), IA ennemie.

signal ended(victory: bool)
signal changed

const EMBER := Color(1.0, 0.55, 0.22)
const DMG_COL := Color(1.0, 0.93, 0.7)

var main: Node3D
var log_lines: Array = []   # journal du combat, affiché à gauche
var danger := false         # zone de danger : tout ce que les ennemis menacent
var _extra_move := {}       # héros qui ont déjà payé leur course (3 mana) ce tour
var glyph_t := {}           # glyphe instable -> tours avant l'explosion
var glyph_lbl := {}
var orienting := false      # fin du tour à la FFT : le héros choisit où il regarde
var _orient_from := Vector2i.ZERO
var _orient_mark: Label3D    # flèche dorée sur la case regardée, visible à travers le décor
var board: Board
var units_root: Node3D
var heroes: Array = []
var foes: Array = []
var deck: Array = []
var relics: Array = []
var draw_pile: Array = []
var discard: Array = []
var exhausted: Array = []
var hand: Array = []
var energy := 3
var bonus_energy := 0
var turn := 0
var busy := false
var player_turn := false
var over := false
var first_free := false
var selected: Unit
var card_sel := -1
var prop_nodes := {}      # Vector2i -> Node3D
var _eco_used := {}       # héros -> vrai si Demi-coût déjà servi ce tour
var _elan_used := {}
var champions := 0          # nombre d'ennemis rares (réglé par la run)
var objective := "kill"     # "kill" | "portal"
var rng := RandomNumberGenerator.new()
var _portal_node: Node3D
var inspect: Unit           # unité dont la fiche est épinglée
var powers: Array = []      # pouvoirs actifs jusqu'à la fin du combat
var traps := {}             # case -> nœud du piège
var turrets := {}           # case -> {turns, dmg}
var trap_dmg := {}          # case -> dégâts du piège
var echo := false           # la prochaine carte agit deux fois
var played := 0             # cartes jouées ce tour
var voices: Array = []      # voix Grixis jouées ce tour par Tidiane
var _killed := false        # la carte en cours a tué
static var foe_mult := 1.0  # dégâts ennemis selon l'étage
static var foe_bonus := 0   # dégâts ennemis en plus (Enragés, Rage)
var mods: Array = []        # modificateurs de la salle et des pactes
var hand_size := 3            # cartes piochées par tour de héros
static var foe_hp := 1.8      # PV des ennemis : chaque héros joue son propre tour
var active: Unit              # héros dont c'est le tour (null pendant un ennemi)
var order: Array = []         # ordre du round, par vitesse
var qi := -1                  # position dans l'ordre
var piles := {}               # héros -> {draw, discard, exhausted} : chacun son paquet
var _first_turn := {}         # héros -> a déjà joué (Ambre du Gué)
var power_val := {}           # pouvoir -> force, selon le niveau de la carte
var bonus := {}               # héros -> énergie en plus à son prochain tour
var besace: Array = []      # objets à usage unique de l'escouade (tableau de la run)
var besace_max := 3
var tool_sel := -1
var tool_rate := 0.3        # part des ennemis qui portent un objet
var bricole := 0            # réserve du Receleur : améliore le prochain objet fabriqué
var smoke := {}             # case -> tours de fumée restants
var smoke_nodes := {}
var trap_kind := {}         # case -> "piege" | "picots"
var tiles := {}             # case -> rune au sol (Data.TILES)
var twins := {}             # portail -> portail jumeau
var tile_nodes: Array = []
var oaks := {}              # case -> chêne planté
var loot := {}              # case -> [objet, nœud] lâché par un ennemi
var _blast := false         # les dégâts en cours viennent d'une explosion
# multiclasse : cartes de guilde
var power_owner := {}       # pouvoir -> héros qui l'a joué
var booms := 0              # barils sautés ce tour (Poudre, 174 BPM)
var hurt_turn := false      # un héros a perdu des PV ce tour (Blessure)
var stolen_turn := 0        # objets volés ce tour (Filière)
var played_ids := {}        # héros -> cartes jouées ce combat (Grand Journal)
var item_poison := 0        # Lame enduite
var fiole2 := false         # Alchimie
var trophy := false         # Trophée
var double_trap := false    # Rabatteur : le piège frappe deux fois
var pending_relics := 0     # Découpe : reliques à choisir après le combat
var elite_fight := false
var suien_hits := 0
var oriel_back := {}        # objet -> déjà revenu (Dame Oriel)
var plume_used := false
var _overload := false
var _start_draw := false
var _enclume_q: Array = []
const TRAP_KINDS := ["piege", "mine", "epieu", "ombre", "collet"]
const BOOM := ["brasero", "baril"]
const RING8: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]


func log_add(t: String) -> void:
	log_lines.append(t)
	if log_lines.size() > 60:
		log_lines.pop_front()
	main.ui.refresh_log()


func has(relic: String) -> bool:
	return relics.has(relic)


func start(hs: Array, foe_ids: Array, deck_ref: Array, relics_ref: Array) -> void:
	heroes = hs
	deck = deck_ref
	relics = relics_ref
	for f in foes:
		f.queue_free()
	foes.clear()
	over = false
	turn = 0
	card_sel = -1
	selected = null
	inspect = null
	powers.clear()
	for n in traps.values():
		n.queue_free()
	traps.clear()
	trap_kind.clear()
	for d in [smoke_nodes, oaks]:
		for n in d.values():
			n.queue_free()
		d.clear()
	smoke.clear()
	for e in loot.values():
		e[1].queue_free()
	loot.clear()
	tool_sel = -1
	bricole = 0
	turrets.clear()
	echo = false
	bonus_energy = 0
	_elan_used.clear()
	var center := Vector2i(board.dim / 2, board.dim / 2)
	var hc := board.spawn_cells("hero", heroes.size())
	for i in heroes.size():
		var h: Unit = heroes[i]
		h.apply_gear()
		h.place(hc[i], board)
		h.face(center - h.cell)
		h.block = 6 if has("ecaille") else 0
		h.poison = 0
		h.taunt = false
		h.reset_fight()
		h.set_selected(false)
	var fc := board.spawn_cells("foe", foe_ids.size(), hc)
	for i in foe_ids.size():
		var u := spawn_foe(foe_ids[i], fc[i])
		u.face(center - u.cell)
	for f in foes:
		if f.data.get("structure", false):
			_isolate(f)
	var pool: Array = foes.filter(func(f): return f.key != "gardien")
	for i in mini(champions, pool.size()):
		var f: Unit = pool[rng.randi_range(0, pool.size() - 1)]
		pool.erase(f)
		f.make_champion(Data.AFFIXES.keys()[rng.randi_range(0, Data.AFFIXES.size() - 1)])
	for f in foes:
		if f.key != "gardien" and (f.affix != "" or rng.randf() < tool_rate):
			f.tool = Data.FOE_TOOLS[rng.randi_range(0, Data.FOE_TOOLS.size() - 1)]
	spawn_props()
	_place_tiles()
	if has("alambic"):
		_craft(1)
	if mods.has("hate"):
		for f in foes:
			f.move += 1
	if mods.has("poudriere"):
		var free: Array = board.walkable_cells().filter(func(c): return unit_at(c) == null and not board.props.has(c))
		free.shuffle()
		for i in mini(4, free.size()):
			board.props[free[i]] = "baril"
			_make_prop(free[i])
	piles.clear()
	log_lines.clear()
	for ci in deck:
		for k in ["bump", "free", "cut"]:
			ci.erase(k)
	for ci in deck:
		var cls: Array = Data.classes_of(ci.id)
		if ci.has("h") and cls.size() == 1 and cls[0] != ci.h:
			var ok: Array = heroes.filter(func(u): return u.key == cls[0] or u.voc == cls[0] or u.voc2 == cls[0])
			if ok.size() > 1:
				ci["h"] = ok[rng.randi_range(0, ok.size() - 1)].key  # tirée au sort à chaque combat
	for h in heroes:
		var d: Array = deck.filter(func(ci): return Data.holder(ci) == h.key)
		d.shuffle()
		piles[h] = {"draw": d, "discard": [], "exhausted": [], "keep": []}
	power_owner.clear()
	played_ids.clear()
	item_poison = 0
	fiole2 = false
	trophy = false
	pending_relics = 0
	suien_hits = 0
	oriel_back.clear()
	_enclume_q.clear()
	draw_pile = []
	discard = []
	exhausted = []
	hand = []
	power_val.clear()
	bonus.clear()
	_first_turn.clear()
	trap_dmg.clear()
	active = null
	order = []
	qi = -1
	_next_round()


func spawn_foe(id: String, c: Vector2i) -> Unit:
	var u := Unit.new()
	u.setup(id, "foe")
	u.max_hp = int(round(u.max_hp * (1.5 if id == "gardien" else foe_hp)))
	u.hp = u.max_hp
	units_root.add_child(u)
	u.place(c, board)
	foes.append(u)
	return u


func _isolate(f: Unit) -> void:
	## Une structure se place loin des autres ennemis, à 6-11 cases des héros : il faut aller la chercher.
	var best := f.cell
	var bs := -INF
	for c in board.walkable_cells():
		if unit_at(c) != null or board.props.has(c):
			continue
		var dh := _hero_dist(c)
		if dh < 6 or dh > 11:
			continue
		var df := 99
		for o in foes:
			if o != f:
				df = mini(df, dist(o.cell, c))
		var s := df * 2.0 - absi(dh - 8)
		if s > bs:
			bs = s
			best = c
	f.place(best, board)


func alive_heroes() -> Array:
	return heroes.filter(func(u): return u.alive)


func alive_foes() -> Array:
	return foes.filter(func(u): return u.alive)


func unit_at(c: Vector2i) -> Unit:
	for u in heroes:
		if u.alive and u.cell == c:
			return u
	for u in foes:
		if u.alive and u.cell == c:
			return u
	return null


func owner_of(c: Dictionary) -> Unit:
	for h in heroes:
		if h.key == c.owner:
			return h
	return null


static func dist(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


# ------------------------------------------------------------------ objets du décor

func spawn_props() -> void:
	for n in prop_nodes.values():
		n.queue_free()
	prop_nodes.clear()
	for c in board.props:
		_make_prop(c)
	if _portal_node:
		_portal_node.queue_free()
		_portal_node = null
	if objective == "portal":
		board.place_portal()
		_portal_node = Node3D.new()
		var md := Board.mesh_of("portal")
		for part in ["mesh", "glow"]:
			var mi := MeshInstance3D.new()
			mi.mesh = md[part]
			mi.material_override = Board.material("glow" if part == "glow" else "prop")
			_portal_node.add_child(mi)
		var l := OmniLight3D.new()
		l.light_color = Color(0.55, 0.9, 1.0)
		l.light_energy = 2.5
		l.omni_range = 4.0
		l.position.y = 0.8
		_portal_node.add_child(l)
		_portal_node.position = board.world(board.portal) - Vector3(0, Board.SLAB, 0)
		units_root.add_child(_portal_node)


func _check_portal(h: Unit) -> void:
	if objective == "portal" and h.alive and h.cell == board.portal and not over:
		over = true
		player_turn = false
		main.ui.banner("Sortie atteinte", "Le groupe franchit le portail")
		_finish(true)


func _make_prop(c: Vector2i) -> void:
	var node := Node3D.new()
	var md := Board.mesh_of("prop_" + board.props[c])
	for part in ["mesh", "glow"]:
		if md[part] == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = md[part]
		mi.material_override = Board.material("glow" if part == "glow" else "prop")
		node.add_child(mi)
	node.position = board.world(c)
	node.rotation.y = randi_range(0, 3) * PI * 0.5
	var mk: Array = {"coffre": ["◆", Color(1.0, 0.85, 0.35)], "levier": ["⚙", Color(0.5, 0.9, 1.0)],
		"brasero": ["✹", Color(1.0, 0.55, 0.2)], "baril": ["✹", Color(1.0, 0.55, 0.2)], "pilier": ["⚠", Color(0.95, 0.9, 0.8)]}.get(board.props[c], [])
	if mk.size() > 0:
		var l3 := Label3D.new()
		l3.text = mk[0]
		l3.font = Fx.title_font()
		l3.font_size = 72
		l3.pixel_size = 0.0042
		l3.visible = false
		l3.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l3.no_depth_test = true
		l3.modulate = mk[1]
		l3.outline_size = 16
		l3.outline_modulate = Color(0.05, 0.03, 0.02, 0.85)
		l3.position.y = 1.45
		node.add_child(l3)
		node.set_meta("mark", l3)
		var tw := l3.create_tween().set_loops()
		tw.tween_property(l3, "position:y", 1.65, 0.9).set_trans(Tween.TRANS_SINE)
		tw.tween_property(l3, "position:y", 1.45, 0.9).set_trans(Tween.TRANS_SINE)
	if board.props[c] == "brasero":
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.55, 0.25)
		l.light_energy = 1.6
		l.omni_range = 3.0
		l.position.y = 0.7
		node.add_child(l)
	units_root.add_child(node)
	prop_nodes[c] = node


func _remove_prop(c: Vector2i) -> void:
	board.props.erase(c)
	var node: Node3D = prop_nodes.get(c)
	prop_nodes.erase(c)
	if node:
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector3(1.2, 0.05, 1.2), 0.25)
		tw.tween_callback(node.queue_free)


func _open_chest(h: Unit, c: Vector2i) -> void:
	_remove_prop(c)
	Fx.burst(main, board.world(c) + Vector3(0, 0.5, 0), Color(1.0, 0.85, 0.4), 50, 3.0, 6.0)
	main.open_chest(h)


func interact(h: Unit, c: Vector2i) -> void:
	var k: String = board.props[c]
	busy = true
	h.face(c - h.cell)
	await h.cast()
	match k:
		"coffre":
			_open_chest(h, c)
			busy = false
			changed.emit()
			return  # ouvrir un coffre au contact est gratuit : le déplacement reste
		"levier":
			board.props[c] = "levier_ok"
			if prop_nodes.has(c) and prop_nodes[c].has_meta("mark"):
				prop_nodes[c].get_meta("mark").queue_free()
				prop_nodes[c].remove_meta("mark")
			board.lower_drawbridge()
			board.build_visuals()
			main.shake(0.4)
			main.ui.toast("Le pont-levis s'abaisse.")
	h.moved = true
	busy = false
	changed.emit()
	_after_action()


func trigger_prop(c: Vector2i, d: Vector2i) -> void:
	## Brasero : explosion. Pilier : effondrement dans la direction d.
	var k: String = board.props.get(c, "")
	if k in BOOM:
		booms += 1
		if powers.has("pip"):
			_craft(1)
		_remove_prop(c)
		var p := board.world(c)
		Fx.burst(main, p + Vector3(0, 0.6, 0), EMBER, 90, 6.0)
		Fx.number(main, p, "Boum", EMBER, true)
		main.shake(0.6)
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				var t := c + Vector2i(dx, dz)
				var u := unit_at(t)
				if u:
					_blast = true
					damage(u, 7)
					_blast = false
				if oaks.has(t):
					_burn(t)
				if board.props.get(t, "") in BOOM:
					await wait(0.12)
					await trigger_prop(t, d)
	elif k == "pilier":
		_remove_prop(c)
		main.shake(0.5)
		for i: int in [1, 2]:
			var t := c + d * i
			Fx.burst(main, board.world(t) + Vector3(0, 0.3, 0), Color(0.75, 0.72, 0.66), 40, 3.0)
			var u := unit_at(t)
			if u:
				damage(u, 9)
			if board.props.get(t, "") in BOOM + ["pilier"]:
				await trigger_prop(t, d)
		Fx.number(main, board.world(c), "Effondrement", Color(1, 0.85, 0.6))
	changed.emit()


# ------------------------------------------------------------------ tours

func _next_round() -> void:
	## Nouveau round : tout le monde joue une fois, du plus rapide au plus lent (FFT).
	turn += 1
	log_add("— Round %d —" % turn)
	if turn > 1:
		_smoke_tick()
		await _turrets_fire()
		if over:
			return
	if turn == 3 and mods.has("renforts"):
		_reinforce()
	if turn > 1:
		await _glyphs()
	order = alive_heroes() + alive_foes()
	order.sort_custom(func(a, b): return _init_key(a) > _init_key(b))
	for u in order.duplicate():
		if u.has_meta("delay"):
			var n: int = u.get_meta("delay")
			u.remove_meta("delay")
			var i := order.find(u)
			order.remove_at(i)
			order.insert(mini(i + n, order.size()), u)
	qi = -1
	main.ui.banner("Round %d" % turn, "Du plus rapide au plus lent")
	await wait(0.5)
	await _advance()


func _init_key(u: Unit) -> float:
	## Vitesse ; à égalité, les héros d'abord.
	return u.speed * 10.0 + (5.0 if u.side == "hero" else 0.0) + (u.get_instance_id() % 7) * 0.1


func _advance() -> void:
	## Au suivant : un héros attend le joueur, un ennemi joue seul.
	while not over:
		qi += 1
		if qi >= order.size():
			await _next_round()
			return
		var u: Unit = order[qi]
		if not is_instance_valid(u) or not u.alive:
			continue
		if main.args.has("trace"):
			print("  tour de ", u.nm, " (", u.side, ")")
		if u.side == "hero":
			_hero_turn(u)
			if player_turn:
				changed.emit()
				return
			continue
		await _foe_turn(u)


func _gain_energy(h: Unit, n: int) -> void:
	## L'énergie gagnée hors de son tour attend le prochain.
	if h == active and player_turn:
		energy += n
	else:
		bonus[h] = bonus.get(h, 0) + n


func _hero_turn(h: Unit) -> void:
	active = h
	_eco_used.clear()
	var korin: bool = powers.has("korin") and power_owner.get("korin") == h
	if _first_turn.has(h) and not powers.has("forteresse") and not h.keep_block and not korin:
		h.block = 0
	h.keep_block = false
	for k in ["bait", "parry", "dodge_next", "tele", "triple", "lvl_next"]:
		h.set(k, false)
	h.bph = 0
	h.inner = 0
	h.hits = 0
	h.fuse = 0
	booms = 0
	hurt_turn = false
	stolen_turn = 0
	plume_used = false
	for f in foes:
		f.pushed = false
	h.combo = 0
	h.ambush = false
	h.moved = false
	h.taunt = false
	h.struck = false
	if h.poison > 0:
		Fx.number(main, h.position, "☠ %d" % h.poison, Color(0.6, 0.9, 0.3))
		damage(h, h.poison, null, false)
		h.poison -= 1
		if not h.alive:
			active = null
			return
	if h.has_p("bouclier"):
		gain_block(h, 3)
	if h.has_p("regen") and h.hp < h.max_hp:
		heal(h, 2)
	if h.root > 0:
		h.moved = true
		h.root -= 1
		Fx.number(main, h.position + Vector3(0, 0.5, 0), "⛓ Entravé", Color(0.8, 0.9, 1.0))
	if oaks.keys().any(func(o): return dist(o, h.cell) == 1):
		gain_block(h, 3)
	echo = false
	played = 0
	voices.clear()
	energy = 3 + (1 if not _first_turn.has(h) and has("ambre") else 0) + int(bonus.get(h, 0)) \
		+ (1 if h.key == "tidiane" and powers.has("obsession") else 0)
	bonus.erase(h)
	_tile_turn(h)
	_power_ticks(h)
	var pl: Dictionary = piles[h]
	draw_pile = pl.draw
	discard = pl.discard
	exhausted = pl.exhausted
	hand = pl.keep
	pl.keep = []
	_start_draw = true
	draw(hand_size + (1 if has("grimoire") else 0) + ((1 + int(power_val.get("dnb", 0))) if h.key == "tidiane" and powers.has("dnb") else 0)
		+ (1 if tiles.get(h.cell, "") == "autel" else 0))
	_extra_move.erase(h)
	_start_draw = false
	first_free = has("sablier")
	_first_turn[h] = true
	tool_sel = -1
	card_sel = -1
	player_turn = true
	busy = false
	select(h)
	main.focus(h.position)
	main.ui.banner(h.nm, "À toi · %d mana" % energy)
	if powers.has("journal") and power_owner.get("journal") == h and played_ids.get(h, []).size() > 0:
		_journal.call_deferred(h)


func _journal(h: Unit) -> void:
	## Le Grand Journal : Découvre une carte déjà jouée ce combat.
	busy = true
	var ids: Array = []
	for id in played_ids.get(h, []):
		if not ids.has(id):
			ids.append(id)
	await _discover(h, ids, "LE GRAND JOURNAL", "Une page déjà écrite ce combat ; elle coûte 0")
	busy = false
	changed.emit()


func draw(n: int) -> void:
	## Le héros actif pioche dans son propre paquet.
	var got := 0
	while got < n and hand.size() < 10:
		if draw_pile.is_empty():
			draw_pile.append_array(discard)
			discard.clear()
			draw_pile.shuffle()
		if draw_pile.is_empty():
			break
		hand.append(draw_pile.pop_back())
		got += 1
	if got > 0 and powers.has("ignar"):
		for f in alive_foes():
			damage(f, got * int(power_val.get("ignar", 1)), null, true, true)
	if got > 0 and not _start_draw and powers.has("nyxa"):
		for k in got:
			var live := alive_foes()
			if live.size() > 0:
				var v: Unit = live[randi() % live.size()]
				v.poison += int(power_val.get("nyxa", 2))
				Fx.number(main, v.position + Vector3(0, 0.4, 0), "☠ +%d" % int(power_val.get("nyxa", 2)), Color(0.6, 0.9, 0.3))


func end_turn() -> void:
	if not player_turn or busy or over:
		return
	if not orienting and active and active.alive and not main._testing():
		# d'abord l'orientation : le dos exposé compte (coups de dos, pièges, Tenaille)
		orienting = true
		_orient_from = active.facing
		card_sel = -1
		tool_sel = -1
		main.ui.banner("Orientation", "Où regarde %s ? · souris, flèches ou manette, puis clic ou Espace" % active.nm)
		main.refresh_hover()
		changed.emit()
		return
	orienting = false
	player_turn = false
	card_sel = -1
	tool_sel = -1
	var keep: Array = []
	for ci in hand:
		var c := Data.card(ci)
		ci.erase("free")
		ci.erase("cut")
		if c.get("retain", false):
			keep.append(ci)
		elif c.get("eph", false):
			pass  # copie éphémère : elle s'efface
		elif c.get("ethereal", false):
			exhausted.append(ci)
		else:
			discard.append(ci)
	if active and piles.has(active):
		piles[active].keep = keep
	hand.clear()
	if active and active.alive and active.fuse > 0:
		Fx.number(main, active.position + Vector3(0, 1.0, 0), "Burn-out", EMBER, true)
		_explode(active.cell, active.fuse)
		active.fuse = 0
	for f in foes:
		if f.alive and f.stick > 0:
			var sd: int = f.stick
			f.stick = 0
			_explode(f.cell, sd)
	active = null
	board.highlight({})
	main.focus(null)
	changed.emit()
	await _advance()


func _after_action() -> void:
	## Le héros actif est tombé pendant son propre tour : on passe au suivant.
	if player_turn and not over and active and not active.alive:
		busy = false
		end_turn()


func pick_hero(h: Unit) -> void:
	## Clic sur un héros : le héros actif se sélectionne, les autres montrent leur fiche.
	if h == active:
		select(h)
	else:
		toggle_inspect(h)


func _foe_turn(f: Unit) -> void:
	f.block = 0
	f.struck = false
	f.struck_hero = false
	if f.mark > 0 and powers.has("vesk"):
		f.poison += int(power_val.get("vesk", 3))
	if f.poison > 0:
		Fx.number(main, f.position, "☠ %d" % f.poison, Color(0.6, 0.9, 0.3))
		damage(f, f.poison, null, false)
		f.poison -= 1
		await wait(0.3)
		if not f.alive:
			return
	var arm: int = int(f.data.get("armor", 0)) + f.extra_armor + (4 if mods.has("blindes") else 0)
	if arm > 0:
		gain_block(f, arm)
	_tile_turn(f)
	main.focus(f.position)
	changed.emit()
	await foe_act(f)
	while _enclume_q.size() > 0 and not over:
		var e: Array = _enclume_q.pop_front()
		await _enclume(e[0], e[1])
	f.mark = maxi(0, f.mark - 1)
	if f.alive:
		# fin de tour : il se tourne vers le héros le plus proche, comme un joueur prudent
		var hs := alive_heroes()
		hs.sort_custom(func(a, b): return dist(a.cell, f.cell) < dist(b.cell, f.cell))
		if hs.size() > 0:
			f.face(hs[0].cell - f.cell)
	await wait(0.2)
	main.focus(null)


# ------------------------------------------------------------------ sélection et clics

func select(u: Unit) -> void:
	if selected:
		selected.set_selected(false)
	selected = u
	for h in heroes:
		h.set_xray(h == u)
	if u:
		u.set_selected(true)
	changed.emit()


func select_card(i: int) -> void:
	if not player_turn or busy or orienting or i >= hand.size():
		return
	tool_sel = -1
	if card_sel == i:
		card_sel = -1
		changed.emit()
		return
	var c := Data.card(hand[i])
	var h := owner_of(c)
	if h == null or not h.alive:
		main.ui.toast("%s est tombé : cette carte est morte." % Data.HEROES[c.owner].name)
		return
	if cost_of(c) > energy:
		main.ui.toast("Pas assez d'énergie.")
		return
	select(h)
	card_sel = i
	var tg := card_targets(c, h)
	if c.get("target", "foe") == "self" or (c.get("target", "foe") == "ally" and tg.size() == 1):
		play_card(i, h.cell)
		return
	if tg.is_empty():
		main.ui.toast("Aucune cible à portée.")
	changed.emit()


func cost_of(c: Dictionary) -> int:
	if first_free or c.get("free", false):
		return 0
	var h := owner_of(c)
	if h and h.triple and c.kind == "atk":
		return 0
	var cost: int = int(c.cost) - int(c.get("cut", 0))
	if c.has("guild") and has("medaille") and c.cls.all(func(k): return heroes.any(func(u): return u.key == k)):
		cost -= 1
	if h and cost >= 2 and h.has_p("economie") and not _eco_used.has(h):
		cost -= 1
	return maxi(0, cost)


func click(c: Vector2i) -> void:
	if not player_turn or busy or over:
		return
	if orienting:
		if c != active.cell:
			active.face(c - active.cell)
		end_turn()
		return
	if tool_sel >= 0:
		if tool_sel < besace.size() and selected and tool_targets(besace[tool_sel], selected).has(c):
			use_tool(tool_sel, c)
		else:
			tool_sel = -1
			changed.emit()
		return
	if card_sel >= 0:
		var card := Data.card(hand[card_sel])
		var h := owner_of(card)
		if card_targets(card, h).has(c):
			play_card(card_sel, c)
		else:
			card_sel = -1
			changed.emit()
		return
	var u := unit_at(c)
	if u and u.side == "hero":
		pick_hero(u)
		return
	if u and u.side == "foe":
		toggle_inspect(u)  # la fiche reste affichée jusqu'au prochain clic
		return
	var pk: String = board.props.get(c, "")
	if pk in ["coffre", "levier"] and selected:
		var near := dist(selected.cell, c) == 1 and absi(board.h[selected.cell] - board.h[c]) <= 2
		if near and (pk == "coffre" or not selected.moved):
			interact(selected, c)
		elif not selected.moved:
			# le héros y va tout seul : la case libre la plus proche au contact, puis il ouvre
			var R := reach(selected)
			var best = null
			for cell in R.cells:
				if dist(cell, c) == 1 and absi(board.h[cell] - board.h[c]) <= 2 and (best == null or R.dist[cell] < R.dist[best]):
					best = cell
			if best == null:
				main.ui.toast("Trop loin : frappez le coffre avec une attaque, ou approchez-vous.")
				return
			busy = true
			var mover := selected
			await mover.walk(path_to(R.prev, best), board)
			mover.moved = true
			await _landed(mover)
			busy = false
			if mover.alive:
				interact(mover, c)
		else:
			main.ui.toast("Frappez le coffre avec une attaque pour l'ouvrir." if pk == "coffre" else "%s a déjà utilisé son déplacement." % selected.nm)
		return
	var sprint := can_sprint(selected)
	if selected and (not selected.moved or sprint):
		var R := reach(selected)
		if R.cells.has(c) and c != selected.cell:
			busy = true
			changed.emit()
			var mover := selected  # la sélection peut changer pendant la marche
			if sprint:
				energy -= 3
				_extra_move[mover] = true
				Fx.number(main, mover.position + Vector3(0, 1.1, 0), "Course · 3 mana", GOLD_FX)
			var path := path_to(R.prev, c)
			await mover.walk(path, board)
			mover.moved = true
			for pc in path:
				if loot.has(pc):
					_pick_loot(mover, pc)
			await _landed(mover)
			_check_portal(mover)
			busy = false
			changed.emit()
			_after_action()
			return


func can_sprint(u: Unit) -> bool:
	## Course : un héros qui a déjà bougé peut repartir une fois pour 3 mana.
	return u != null and u == active and u.moved and energy >= 3 and not _extra_move.has(u) and u.root <= 0


func toggle_inspect(u: Unit) -> void:
	inspect = null if u == null or u == inspect else u
	main.refresh_hover()


func turn_facing(s: int) -> void:
	## Flèches gauche/droite pendant l'orientation : un quart de tour.
	if orienting:
		active.facing = Vector2i(-active.facing.y * s, active.facing.x * s)
		main.pad = true  # la souris ne reprend pas la main tant qu'elle ne bouge pas
		refresh_highlight(null)


func cancel() -> void:
	if orienting:
		orienting = false
		active.facing = _orient_from
		main.refresh_hover()
		changed.emit()
		return
	if inspect:
		inspect = null
		main.refresh_hover()
		return
	if tool_sel >= 0:
		tool_sel = -1
	elif card_sel >= 0:
		card_sel = -1
	changed.emit()


# ------------------------------------------------------------------ déplacement

func _can_stand(u: Unit, c: Vector2i) -> bool:
	return board.walkable(c) or (board._in(c) and board.kind[c] == "water" and u.has_p("eau"))


func reach(u: Unit) -> Dictionary:
	## prev : case -> case précédente ; cells : cases où l'unité peut s'arrêter.
	var mv: int = u.move
	var prev := {u.cell: u.cell}
	var d := {u.cell: 0}
	var q: Array = [u.cell]
	var i := 0
	while i < q.size():
		var c: Vector2i = q[i]
		i += 1
		if d[c] >= mv:
			continue
		for dir in Board.DIRS:
			var n: Vector2i = c + dir
			if d.has(n) or not board._in(n):
				continue
			var ok: bool = _can_stand(u, n) or (u.fly and board.kind[n] == "water")
			if not ok:
				continue
			if not u.fly and absi(board.h[n] - board.h[c]) > u.jump:
				continue
			var o := unit_at(n)
			if o and o.side != u.side:
				continue
			d[n] = d[c] + 1
			prev[n] = c
			q.append(n)
	var cells := {}
	for c in prev:
		if c == u.cell or (_can_stand(u, c) and unit_at(c) == null):
			cells[c] = true
	return {"prev": prev, "cells": cells, "dist": d}


func path_to(prev: Dictionary, c: Vector2i) -> Array:
	var p: Array = []
	while prev[c] != c:
		p.push_front(c)
		c = prev[c]
	return p


# ------------------------------------------------------------------ cartes

func card_range(c: Dictionary, h: Unit) -> Vector2i:
	var r: Array = c.get("range", [0, 0])
	var hi: int = r[1]
	if hi > 1 and h.trait_id == "myope":
		hi -= 1
	if hi > 2 and mods.has("brume") and not powers.has("aelis"):
		hi -= 1
	if hi > 1 and h.has_p("concentration"):
		hi += 1
	return Vector2i(r[0], hi)


func card_targets(c: Dictionary, h: Unit) -> Array:
	var out: Array = []
	var r := card_range(c, h)
	match c.get("target", "foe"):
		"self":
			out.append(h.cell)
		"ally":
			for a in alive_heroes():
				var dd := dist(h.cell, a.cell)
				if dd >= r.x and dd <= r.y:
					out.append(a.cell)
		"tile":
			for x in board.dim:
				for z in board.dim:
					var t := Vector2i(x, z)
					var dd := dist(h.cell, t)
					if dd < r.x or dd > r.y:
						continue
					if c.id == "ombre" or c.get("blink", false):
						if board.walkable(t) and unit_at(t) == null and (not c.get("near_ally", false) or alive_heroes().any(func(a): return a != h and dist(a.cell, t) == 1)):
							out.append(t)
					elif c.has("place"):
						if board.walkable(t) and unit_at(t) == null and not traps.has(t):
							out.append(t)
					elif board.kind[t] != "tower":
						out.append(t)
		"line":
			for dir in Board.DIRS:
				var p := h.cell
				for i in r.y:
					var n := p + dir
					if board.props.get(n, "") in BOOM + ["pilier"]:
						out.append(n)
						break
					if not board.walkable(n) or absi(board.h[n] - board.h[p]) > 2:
						break
					var o := unit_at(n)
					if o:
						if o.side == "foe":
							out.append(n)
						break
					out.append(n)
					p = n
		_:
			var cells: Array = [] if c.get("detonate", false) else alive_foes().map(func(f): return f.cell)
			for pc in board.props:
				if board.props[pc] in (BOOM if c.get("detonate", false) else BOOM + ["pilier", "coffre"]):
					cells.append(pc)
			for t in cells:
				var dd := dist(h.cell, t)
				if dd < r.x or dd > r.y:
					continue
				if r.y == 1 and absi(board.h[h.cell] - board.h[t]) > 3:
					continue
				if dd > 1 and smoke.has(t) and not powers.has("aelis"):
					continue  # fumée : on n'y vise pas de loin
				out.append(t)
	return out


func range_cells(c: Dictionary, h: Unit) -> Array:
	var out: Array = []
	var r := card_range(c, h)
	if c.get("target", "foe") == "self":
		return out
	for x in board.dim:
		for z in board.dim:
			var t := Vector2i(x, z)
			var dd := dist(h.cell, t)
			if dd >= maxi(r.x, 1) and dd <= r.y and board.kind[t] != "tower":
				out.append(t)
	return out


func play_card(i: int, t: Vector2i) -> void:
	var ci: Dictionary = hand[i]
	var c := Data.card(ci)
	var h := owner_of(c)
	if h.lvl_next and not c.get("lvl_next", false):
		# Geste technique : la carte monte d'un niveau jusqu'à la fin du combat
		h.lvl_next = false
		ci["bump"] = int(ci.get("bump", 0)) + 1
		c = Data.card(ci)
		Fx.number(main, h.position + Vector3(0, 1.0, 0), "Geste technique : niveau %d" % c.lvl, GOLD_FX)
	var cost := cost_of(c)
	if energy < cost:
		return
	if cost < int(c.cost) and not first_free and h.has_p("economie"):
		_eco_used[h] = true
	energy -= cost
	first_free = false
	if h.triple and c.kind == "atk":
		cost = 0
	_overload = false
	if c.has("overload") and energy >= int(c.overload) - cost and int(c.overload) > cost:
		energy -= int(c.overload) - cost
		_overload = true
		Fx.number(main, h.position + Vector3(0, 1.2, 0), "Surcharge !", Color(0.5, 0.8, 1.0), true)
	if has("plume") and not plume_used and c.cls != [h.key]:
		plume_used = true
		draw(1)
	if not played_ids.has(h):
		played_ids[h] = []
	played_ids[h].append(ci.id)
	hand.remove_at(i)
	card_sel = -1
	busy = true
	board.highlight({})
	log_add("%s joue %s" % [h.nm, c.name])
	main.ui.announce(c)
	changed.emit()
	var pre := _trig_ok(c, h, t)
	_killed = false
	if c.get("selfdmg", 0) > 0:
		# le prix en PV ne tue jamais
		var cost_hp := mini(int(c.selfdmg), h.hp - 1)
		h.hp -= cost_hp
		Fx.number(main, h.position + Vector3(0, 0.3, 0), "-%d PV" % cost_hp, Color(0.8, 0.45, 1.0))
		h.hurt()
	await resolve(c, h, t)
	if c.kind == "atk" and c.get("draw", 0) > 0:
		draw(c.draw)
	if c.has("voix") and not voices.has(c.voix):
		voices.append(c.voix)
	var refund := false
	if c.has("trig") and (pre or (c.trig.on == "grace" and _killed)) and h.alive:
		refund = _trig_apply(c, h, t)
	played += 1
	if echo and not c.get("echo", false) and c.kind != "power" and h.alive and not over:
		echo = false
		if c.get("target", "foe") in ["self", "tile", "line", "ally"] or card_targets(c, h).has(t):
			Fx.number(main, h.position + Vector3(0, 0.9, 0), "Écho", Color(0.85, 0.7, 1.0))
			await wait(0.2)
			await resolve(c, h, t)
	if powers.has("kaede") and power_owner.get("kaede") == h and played == 3 and h.alive and not over:
		await _kaede(h)
	if powers.has("coupures") and not over:
		var live := alive_foes()
		if live.size() > 0:
			var v: Unit = live[randi() % live.size()]
			Fx.burst(main, v.position + Vector3(0, 0.7, 0), Data.CLASS_COLOR.lame, 14, 2.5)
			damage(v, 1 + int(power_val.get("coupures", 0)))
	ci.erase("free")
	ci.erase("cut")
	if refund:
		hand.append(ci)
	elif c.get("eph", false):
		pass
	elif c.get("exhaust", false) or c.kind == "power":
		exhausted.append(ci)
	else:
		discard.append(ci)
	busy = false
	changed.emit()
	_after_action()


func resolve(c: Dictionary, h: Unit, t: Vector2i) -> void:
	var tgt: String = c.get("target", "foe")
	var col: Color = Data.CLASS_COLOR[c.owner]
	if c.kind == "power":
		await h.cast()
		powers.append(c.power)
		power_owner[c.power] = h
		power_val[c.power] = maxi(int(power_val.get(c.power, 0)), int(c.get("val", 0)))
		power_val[c.power + "2"] = maxi(int(power_val.get(c.power + "2", 0)), int(c.get("val2", 0)))
		if c.get("block", 0) > 0:
			for a in alive_heroes():
				gain_block(a, c.block)
		Fx.burst(main, h.position + Vector3(0, 0.8, 0), col.lightened(0.3), 50, 2.5, 5.0)
		Fx.number(main, h.position + Vector3(0, 0.6, 0), c.name, col.lightened(0.4))
		return
	if c.get("scatter", 0) > 0:
		await h.cast()
		var near: Array = []
		for d in Board.DIRS:
			var o := unit_at(h.cell + d)
			if o and o.side == "foe":
				near.append(o)
		for k in int(c.scatter):
			near = near.filter(func(o): return o.alive)
			if near.is_empty():
				break
			var o: Unit = near[k % near.size()]
			await h.lunge(o.position)
			var back := _is_back(h, o)
			damage(o, calc(h, o, _base(c, h, o.cell), c).dmg, h)
			_on_hit(h, o, back)
			await wait(0.08)
		_count_hit(h)
		return
	if c.get("around", false):
		await h.cast()
		main.shake(0.3)
		var tele: bool = c.get("back_if_tele", false) and h.tele
		for d in Board.DIRS:
			var o := unit_at(h.cell + d)
			Fx.burst(main, board.world(h.cell + d) + Vector3(0, 0.4, 0), col.lightened(0.3), 16, 3.0)
			if o and o.side == "foe":
				if tele:
					h.ambush = true
				var back := _is_back(h, o)
				damage(o, calc(h, o, c.dmg, c).dmg, h)
				_on_hit(h, o, back)
				if o.alive and c.get("push", 0) > 0:
					await push(o, d, c.push)
			elif board.props.get(h.cell + d, "") in BOOM + ["pilier"]:
				await trigger_prop(h.cell + d, d)
		h.ambush = false
		if c.get("block", 0) > 0:
			gain_block(h, c.block)
		_count_hit(h)
		await wait(0.3)
		return
	if c.has("place"):
		if c.get("consume", false) and _consume(h) == "":
			return
		await _place(c, t, h)
		if c.get("draw", 0) > 0:
			draw(c.draw)
		if c.get("block", 0) > 0:
			gain_block(h, c.block)
		if c.get("bricole", 0) > 0:
			_add_bricole(h, c.bricole)
		if c.get("energy", 0) > 0:
			energy += c.energy
		if c.has("rune") and not tiles.has(t):
			tiles[t] = c.rune
			_make_tile(t, c.rune)
		if c.get("lure", 0) > 0:
			await _lure(t, c.lure)
		if c.get("ambush", false):
			h.ambush = true
		return
	if tgt == "tile" and not c.get("aoe", false) and not c.get("blink", false) and c.id != "ombre":
		h.face(t - h.cell)
		await h.cast()
		if c.get("smoke", 0) > 0:
			for cc in [t] + Board.DIRS.map(func(d): return t + d):
				if board._in(cc) and board.kind[cc] != "tower":
					_smoke(cc, c.smoke)
		if c.get("lure", 0) > 0:
			await _lure(t, c.lure)
		if c.get("draw", 0) > 0:
			draw(c.draw)
		return
	if tgt == "self":
		h.cast()
		await _self_fx(c, h)
		if c.get("heal", 0) > 0:
			heal(h, c.heal)
		if c.get("energy", 0) > 0:
			energy += c.energy
			Fx.number(main, h.position + Vector3(0, 0.6, 0), "+%d énergie" % c.energy, GOLD_FX)
		if c.get("ambush", false):
			h.ambush = true
			Fx.number(main, h.position + Vector3(0, 0.6, 0), "Embuscade", col.lightened(0.4))
		if c.get("echo", false):
			echo = true
			Fx.number(main, h.position + Vector3(0, 0.6, 0), "Écho", col.lightened(0.4))
		if c.has("block"):
			for a in (alive_heroes() if c.get("all", false) else [h]):
				gain_block(a, c.block)
			if c.get("adj", false):
				for a in alive_heroes():
					if a != h and dist(a.cell, h.cell) == 1:
						gain_block(a, c.block)
		if c.get("craft", 0) > 0:
			_craft(c.craft, h)
		if c.get("recycle", false):
			if besace.is_empty():
				main.ui.toast("La besace est vide.")
			else:
				var gone: String = besace.pop_front()
				energy += 1 + int(c.get("val", 0))
				_add_bricole(h, 1)
				Fx.number(main, h.position + Vector3(0, 0.6, 0), "%s recyclé · +1 énergie" % Data.TOOLS[gone].name, GOLD_FX)
		if c.get("dupe", false):
			if besace.is_empty() or besace.size() >= besace_cap():
				main.ui.toast("Rien à copier, ou besace pleine.")
			else:
				besace.append(besace.back())
				Fx.number(main, h.position + Vector3(0, 0.6, 0), "Copie : " + Data.TOOLS[besace.back()].name, GOLD_FX)
		if c.get("taunt", false):
			h.taunt = true
			Fx.number(main, h.position + Vector3(0, 0.4, 0), "Défi !", Color(1, 0.8, 0.4))
		if c.has("heal_all"):
			for a in alive_heroes():
				heal(a, c.heal_all)
		if c.get("draw", 0) > 0:
			draw(c.draw)
		await wait(0.3)
		return
	if tgt == "ally":
		h.face(t - h.cell)
		await h.cast()
		var a := unit_at(t)
		if a and c.get("swap", false) and a != h:
			var hc := h.cell
			var ac := a.cell
			h.cell = Vector2i(-99, -99)
			await a.teleport(hc, board)
			await h.teleport(ac, board)
		if a:
			if c.get("heal", 0) > 0:
				var amt := int(c.heal * (1.5 if a.trait_id == "beni" else 1.0))
				var extra := maxi(0, amt - (a.max_hp - a.hp))
				heal(a, c.heal)
				if c.get("overheal", false) and extra > 0:
					gain_block(a, extra * 2)
			if c.get("block", 0) > 0:
				gain_block(a, c.block)
		if c.get("ambush", false):
			h.ambush = true
		if c.get("draw", 0) > 0:
			draw(c.draw)
		await wait(0.2)
		return
	if c.id == "ombre" or c.get("blink", false):
		Fx.burst(main, h.position + Vector3(0, 0.6, 0), Color(0.5, 0.2, 0.25), 30, 2.0)
		await h.teleport(t, board)
		h.tele = true
		Fx.burst(main, h.position + Vector3(0, 0.6, 0), Color(0.5, 0.2, 0.25), 30, 2.0)
		if loot.has(h.cell):
			_pick_loot(h, h.cell)
		if c.get("block", 0) > 0:
			gain_block(h, c.block)
			if c.get("near_ally", false):
				for a in alive_heroes():
					if a != h and dist(a.cell, h.cell) == 1:
						gain_block(a, c.block)
		if c.get("craft", 0) > 0:
			_craft(c.craft, h)
		if c.get("energy", 0) > 0:
			energy += c.energy
		if c.get("hitcount", false):
			h.hits += 1
			_count_hit(h)
		if c.get("dmg", 0) > 0:
			# Bond de grue niveau 3 : l'atterrissage frappe les voisins
			main.shake(0.3)
			for d in Board.DIRS:
				var o := unit_at(h.cell + d)
				if o and o.side == "foe":
					damage(o, calc(h, o, c.dmg, c).dmg, h)
		if c.get("draw", 0) > 0:
			draw(c.draw)
		await _landed(h)
		_check_portal(h)
		return
	if tgt == "line":
		await charge(h, t, c)
		return
	if c.get("aoe", false):
		h.face(t - h.cell)
		await h.cast()
		await Fx.bolt(main, h.position, board.world(t), col)
		main.shake(0.25)
		var cells := [t]
		for d in Board.DIRS:
			cells.append(t + d)
		if _overload:
			cells = alive_foes().map(func(f): return f.cell)
		for cell in cells:
			if board._in(cell):
				Fx.burst(main, board.world(cell) + Vector3(0, 0.2, 0), col, 16, 3.5, 3.0)
			var u := unit_at(cell)
			if u and u.side == "foe":
				_blast = c.owner in ["artificier", "oracle"]  # grenades, mortier, cendre : du feu
				damage(u, calc(h, u, c.dmg + _trig_dmg(c, h, t), c).dmg, h, true, true)
				_blast = false
			elif oaks.has(cell) and c.owner in ["artificier", "oracle"]:
				_burn(cell)
			elif board.props.get(cell, "") in BOOM:
				await trigger_prop(cell, _dir(h.cell, cell))
		if c.get("aoe_baril", false) and board.walkable(t) and unit_at(t) == null and not board.props.has(t) and not traps.has(t):
			board.props[t] = "baril"
			_make_prop(t)
		await wait(0.3)
		return
	var f := unit_at(t)
	if f and _overload and f.side == "foe":
		for o in alive_foes():
			if not over:
				await attack(h, o, c)
	elif f:
		await attack(h, f, c)
	elif board.props.has(t):
		h.face(t - h.cell)
		if card_range(c, h).y > 1:
			await h.cast()
			await Fx.bolt(main, h.position, board.world(t), col.lightened(0.3))
		else:
			await h.lunge(board.world(t))
		if board.props.get(t, "") == "coffre":
			_open_chest(h, t)  # un coup suffit à faire sauter le couvercle
		else:
			await trigger_prop(t, _dir(h.cell, t))


func attack(h: Unit, f: Unit, c: Dictionary) -> void:
	var col: Color = Data.CLASS_COLOR[c.owner]
	var origin := h.cell
	if c.get("rechute", false) and h.hp * 10 < h.max_hp * 3:
		await h.cast()
		heal(h, 12)
		return
	if c.get("shadow_ally", false):
		var ally: Unit = h
		for a in alive_heroes():
			if a != h and (ally == h or dist(a.cell, f.cell) < dist(ally.cell, f.cell)):
				ally = a
		await _go_behind(ally, f)
		ally.ambush = true
		Fx.number(main, ally.position + Vector3(0, 0.8, 0), "Dans son dos", col.lightened(0.4))
		if f.alive and c.get("mark", 0) > 0:
			f.mark = maxi(f.mark, c.mark)
		return
	if c.get("behind", false):
		await _go_behind(h, f)
		h.ambush = true
	elif c.get("dash", false) and dist(h.cell, f.cell) > 1:
		var best := h.cell
		for d in Board.DIRS:
			var n: Vector2i = f.cell + d
			if board.walkable(n) and unit_at(n) == null and (best == h.cell or dist(n, h.cell) < dist(best, h.cell)):
				best = n
		if best != h.cell:
			await h.teleport(best, board)
			h.tele = true
	elif c.get("vault", false):
		var land: Vector2i = f.cell + (f.cell - h.cell)
		if board.walkable(land) and unit_at(land) == null:
			await h.teleport(land, board)
			h.tele = true
	h.face(f.cell - h.cell)
	main.punch((h.position + f.position) * 0.5)
	f.set_xray(true)
	var ranged: bool = card_range(c, h).y > 1 and not c.get("behind", false) and not c.get("dash", false)
	if c.get("steal", false) and not _steal(h, f) and c.get("craft_else", false):
		_craft(1, h)
	if c.get("throw", false) and besace.size() > 0:
		var tid: String = besace.pop_front()
		await Fx.bolt(main, h.position, f.position, GOLD_FX)
		if not tid in ["grappin", "tonnelet", "gland", "picots"]:
			await _apply_tool(tid, h, f.cell if Data.TOOLS[tid].target in ["foe", "tile", "ally"] else h.cell)
		if not f.alive:
			return
	var base := _base(c, h, f.cell)
	if c.get("need_item", false):
		if _consume(h) == "":
			base = 0
	if c.get("pierce", false) and f.block > 0:
		Fx.number(main, f.position + Vector3(0, 0.5, 0), "Perce", col.lightened(0.4))
		f.block = 0
	if c.get("delve", false):
		base = (2 + int(c.get("val", 0))) * discard.size()
		exhausted.append_array(discard)
		discard.clear()
	var had_poison := f.poison > 0
	var dealt := 0
	var n_hits: int = (1 + played) if c.get("hits_flow", false) else int(c.get("hits", 1))
	for k in n_hits:
		if not f.alive:
			break
		if ranged:
			await h.cast()
			await Fx.bolt(main, h.position, f.position, col.lightened(0.3))
		else:
			await h.lunge(f.position)
		var back := _is_back(h, f)
		var dm: int = calc(h, f, base, c).dmg
		dealt += dm
		damage(f, dm, h, true, ranged)
		f.exposed = false
		h.struck = true
		if base > 0 or c.get("dmg", 0) > 0:
			_on_hit(h, f, back)
		await wait(0.12)
	h.ambush = false
	if h.triple and c.kind == "atk":
		h.triple = false
	if c.get("heal_adj", false) and dealt > 0:
		var w: Unit = null
		for a in alive_heroes():
			if a != h and dist(a.cell, h.cell) <= 2 and a.hp < a.max_hp and (w == null or a.hp * w.max_hp < w.hp * a.max_hp):
				w = a
		if w:
			heal(w, dealt)
	if c.get("craft_id", "") != "":
		_craft_id(c.craft_id, 1, h)
	if c.get("det_near", false) or c.get("volt", false):
		for pc in board.props.keys():
			if board.props.get(pc, "") in BOOM and (dist(pc, f.cell) <= (3 if c.get("volt", false) else 1)):
				await trigger_prop(pc, _dir(f.cell, pc))
				if not c.get("volt", false):
					break
	if f.alive and c.get("stick", 0) > 0:
		f.stick = int(c.stick)
		Fx.number(main, f.position + Vector3(0, 0.9, 0), "Charge collée", EMBER)
	if f.alive and c.get("bounty", false):
		f.bounty = true
	if f.alive and c.get("delay", 0) > 0:
		_delay(f, int(c.delay))
	if c.get("rechute", false):
		var lose := mini(4, h.hp - 1)
		h.hp -= lose
		Fx.number(main, h.position + Vector3(0, 0.3, 0), "-%d PV" % lose, Color(0.8, 0.45, 1.0))
	if c.get("decoupe", false) and not f.alive and (elite_fight or f.affix != "" or f.key == "gardien"):
		pending_relics += 1
		Fx.number(main, f.position + Vector3(0, 1.2, 0), "Découpe : une relique !", GOLD_FX, true)
	if c.get("iblock", 0) > 0:
		gain_block(h, int(c.iblock) * besace.size())
	if c.get("bricole", 0) > 0:
		_add_bricole(h, c.bricole)
	if c.get("leech", 0) > 0:
		heal(h, c.leech)
	if c.kind == "atk" and c.get("block", 0) > 0:
		gain_block(h, c.block)
	if f.alive and c.get("mark", 0) > 0:
		f.mark = maxi(f.mark, c.mark)
		Fx.number(main, f.position + Vector3(0, 0.5, 0), "◎ Marqué", Color(1.0, 0.85, 0.4))
	if f.alive and c.get("root", 0) > 0:
		f.root = maxi(f.root, c.root)
		Fx.number(main, f.position + Vector3(0, 0.5, 0), "⛓ Entravé", Color(0.8, 0.9, 1.0))
	if f.alive and c.get("pull", 0) > 0:
		var n := mini(c.pull, dist(h.cell, f.cell) - 1)
		if n > 0:
			await push(f, _dir(f.cell, h.cell), n)
	if c.get("chain", 0) > 1:
		var hit: Array = [f]
		var last := f
		for k in c.chain - 1:
			var nxt: Unit = null
			for o in alive_foes():
				if not hit.has(o) and dist(o.cell, last.cell) <= 3 and (nxt == null or dist(o.cell, last.cell) < dist(nxt.cell, last.cell)):
					nxt = o
			if nxt == null:
				break
			await Fx.bolt(main, last.position, nxt.position, col.lightened(0.3))
			damage(nxt, calc(h, nxt, base, c).dmg, h, true, true)
			hit.append(nxt)
			last = nxt
	_count_hit(h)
	if f.alive and c.get("poison", 0) > 0:
		var pz: int = int(c.poison) * (2 if c.get("x2_marked", false) and f.mark > 0 else 1)
		f.poison += pz
		if c.get("poison_x2", false) and had_poison:
			f.poison *= 2
		Fx.number(main, f.position + Vector3(0, 0.4, 0), "☠ %d" % f.poison, Color(0.6, 0.9, 0.3))
	if f.alive and c.get("push", 0) > 0:
		double_trap = c.get("trap2", false)
		await push(f, _dir(h.cell, f.cell), c.push)
		double_trap = false
	if c.get("recoil", 0) > 0 and h.alive:
		await push(h, _dir(f.cell, h.cell), int(c.recoil))
	if c.get("ret", false) and h.alive and h.cell != origin and unit_at(origin) == null:
		await h.teleport(origin, board)
	if c.get("bounce", false):
		for d in Board.DIRS:
			var o := unit_at(f.cell + d)
			if o and o.side == "foe":
				await Fx.bolt(main, f.position, o.position, col.lightened(0.3))
				damage(o, calc(h, o, base, c).dmg, h, true, true)
				break
	f.set_xray(false)
	await wait(0.15)


func charge(h: Unit, t: Vector2i, c: Dictionary) -> void:
	var d := _dir(h.cell, t)
	var path: Array = []
	var p := h.cell
	while p != t:
		var n := p + d
		if unit_at(n) or board.props.has(n):
			break
		path.append(n)
		p = n
	if path.size() > 0:
		await h.walk(path, board)
		for pc in path:
			if loot.has(pc):
				_pick_loot(h, pc)
	h.face(d)
	var nx := h.cell + d
	var f := unit_at(nx)
	if f and f.side == "foe":
		await h.lunge(f.position)
		damage(f, calc(h, f, c.dmg + _trig_dmg(c, h, nx), c).dmg, h)
		if f.alive and c.get("push", 0) > 0:
			await push(f, d, c.push)
	elif board.props.get(nx, "") in BOOM + ["pilier"]:
		await h.lunge(board.world(nx))
		await trigger_prop(nx, d)


func _dir(a: Vector2i, b: Vector2i) -> Vector2i:
	var d := b - a
	if absi(d.x) >= absi(d.y):
		return Vector2i(signi(d.x), 0)
	return Vector2i(0, signi(d.y))


# ------------------------------------------------------------------ dégâts

func calc(att: Unit, tgt: Unit, base: int, c := {}) -> Dictionary:
	var mult := 1.0
	var flat := att.gear_dmg()
	var notes: Array = []
	var ranged: bool = c.has("range") and card_range(c, att).y > 1 if att.side == "hero" else att.data.get("range", [1, 1])[1] > 1
	var dh: int = board.h[att.cell] - board.h[tgt.cell]
	if dh != 0:
		var hb := 0.1 * clampi(dh, -3, 3) * (2.0 if has("tuile") and att.side == "hero" else 1.0)
		mult += hb
		notes.append("hauteur %+d %%" % int(round(hb * 100)))
	var to_att := att.cell - tgt.cell
	var dot := tgt.facing.x * signi(to_att.x) + tgt.facing.y * signi(to_att.y)
	if dot < 0 and tgt.has_p("vigilance"):
		dot = 0
	if att.side == "hero" and att.ambush:
		dot = -1
	if tgt.exposed:
		dot = -1
	if smoke.has(tgt.cell) and dist(att.cell, tgt.cell) == 1:
		dot = -1  # dans la fumée, on ne voit pas venir le coup
	if dot < 0:
		var bs: float = c.get("backstab", 1.5)
		mult *= bs
		notes.append("dos ×%s" % str(bs))
		if att.side == "hero":
			flat += (3 if has("feuille") else 0) + (2 if att.trait_id == "gaucher" else 0)
	elif dot == 0:
		mult *= 1.2
		notes.append("flanc ×1.2")
	if tiles.get(att.cell, "") == "force":
		flat += 3
		notes.append("rune de force +3")
	if att.side == "hero" and att.key == "tidiane" and powers.has("hyperfocus"):
		flat += 3 + int(power_val.get("hyperfocus", 0))
	if att.trait_id == "rancune" and att.hp * 2 < att.max_hp:
		flat += 3
	if att.trait_id == "myope" and ranged:
		flat += 2
	if not ranged and att.has_p("arme_plus"):
		flat += 2
	if att.has_p("deux_mains") and not att.struck:
		mult *= 1.5
		notes.append("deux mains ×1.5")
	if tgt.mark > 0:
		mult *= 1.5
		notes.append("marqué ×1.5")
	if att.side == "hero" and att.triple and c.get("kind", "") == "atk":
		mult *= 3.0
		notes.append("just frame ×3")
	if att.side == "hero" and powers.has("tetsu") and tgt.root > 0 and not ranged:
		flat += int(power_val.get("tetsu", 4))
	if c.get("execute", false) and tgt.hp * 2 < tgt.max_hp:
		mult *= 2.0
		notes.append("exécution ×2")
	if ranged and tgt.fly:
		mult *= 1.5
		notes.append("tir sur volant ×1.5")
	if tiles.get(tgt.cell, "") == "fourre":
		mult *= 0.7
		notes.append("fourré ×0.7")
	# soutien : un allié au contact
	if att.side == "hero" and alive_heroes().any(func(a): return a != att and dist(a.cell, att.cell) == 1):
		flat += 2
		notes.append("soutien +2")
	if tgt.side == "hero" and alive_heroes().any(func(a): return a != tgt and dist(a.cell, tgt.cell) == 1):
		flat -= 2
		notes.append("soutien −2")
	if att.side == "foe" and att.key != "capitaine" and alive_foes().any(func(o): return o.key == "capitaine" and dist(o.cell, att.cell) <= 2):
		flat += 2
		notes.append("ordre du capitaine +2")
	return {"dmg": maxi(0, int(round(base * mult)) + flat), "notes": notes}



func damage(u: Unit, amount: int, src: Unit = null, show := true, ranged := false) -> void:
	if not u.alive:
		return
	# réactions d'esquive
	if src and ((not ranged and u.has_p("reflexe") and randf() < 0.25) or (ranged and u.has_p("parade") and randf() < 0.5)):
		Fx.number(main, u.position, "Esquive", Color(0.8, 0.95, 1.0))
		u.dodge()
		return
	var melee_hit: bool = src != null and not ranged and dist(src.cell, u.cell) == 1
	if u.aegis and amount > 0:
		u.aegis = false
		Fx.number(main, u.position + Vector3(0, 0.5, 0), "Égide", Color(1.0, 0.95, 0.7), true)
		return
	if u.dodge_next and src:
		u.dodge_next = false
		Fx.number(main, u.position, "Iframe", Color(0.8, 0.95, 1.0), true)
		u.dodge()
		return
	if u.parry and melee_hit and src.alive:
		u.parry = false
		Fx.number(main, u.position + Vector3(0, 0.6, 0), "Parry !", GOLD_FX, true)
		main.hitstop(0.12)
		damage(src, amount)
		return
	if u.side == "hero" and src and src.side == "foe":
		if u.bait:
			src.exposed = true
		if u.boomguard > 0 and melee_hit:
			var bg := u.boomguard
			u.boomguard = 0
			_boom_foes(src.cell, bg)
		if melee_hit and powers.has("octroi") and power_owner.get("octroi") == u and src.alive:
			if src.tool != "" and besace.size() < besace_cap():
				_steal(u, src)
			else:
				Fx.number(main, src.position + Vector3(0, 0.7, 0), "Octroi", GOLD_FX)
				damage(src, int(power_val.get("octroi", 5)))
		if melee_hit and powers.has("enclume"):
			_enclume_q.append([src, u])
	var absorbed := mini(u.block, amount)
	u.block -= absorbed
	var rest := amount - absorbed
	u.hp -= rest
	if u.side == "hero" and rest > 0:
		hurt_turn = true
	if u.side == "hero" and u.hp <= 0 and powers.has("quarante") and not u.q40:
		u.q40 = true
		u.hp = 1
		u.block += int(power_val.get("quarante", 15))
		bonus[u] = bonus.get(u, 0) + 2
		Fx.number(main, u.position + Vector3(0, 1.0, 0), "La règle des 40 % !", GOLD_FX, true)
	if rest > 0 or absorbed > 0:
		log_add("%s%s : −%d PV%s" % [(src.nm + " → ") if src and src != u else "", u.nm, rest, (" (armure %d)" % absorbed) if absorbed > 0 else ""])
	if show:
		if rest > 0:
			Fx.number(main, u.position, str(rest), DMG_COL if u.side == "foe" else Color(1.0, 0.4, 0.35), rest >= 10)
		if absorbed > 0:
			Fx.number(main, u.position + Vector3(0.3, 0.3, 0), "🛡 %d" % absorbed, Color(0.7, 0.85, 0.95))
	u.hurt()
	if src:
		main.hitstop(0.05 + mini(rest, 15) * 0.005)
		if u.side == "foe":
			Fx.burst(main, u.position + Vector3(0, 0.8, 0), Color(0.42, 0.4, 0.44), 12 + rest, 3.5)
	Fx.burst(main, u.position + Vector3(0, 0.6, 0), EMBER if u.side == "foe" else Color(1, 0.3, 0.25), 14 + rest, 2.5)
	main.shake(0.06 + rest * 0.012)
	if src and src.affix == "vampire" and rest > 1 and src.alive:
		heal(src, rest / 2)
	if _blast and u.tool == "bombe":
		# la bombe qu'il portait lui saute entre les mains
		u.tool = ""
		Fx.number(main, u.position + Vector3(0, 1.0, 0), "Sa bombe saute !", EMBER, true)
		_explode.call_deferred(u.cell, 6, true)
	if u.hp <= 0:
		kill(u, src)
	else:
		if u.side == "hero" and u.has_p("elan") and u.hp * 4 < u.max_hp and not _elan_used.has(u):
			_elan_used[u] = true
			Fx.number(main, u.position + Vector3(0, 0.5, 0), "Dernier élan", GOLD_FX)
			_gain_energy(u, 2)
		if src and src.alive and src != u:
			if ranged and u.has_p("retour"):
				Fx.number(main, u.position + Vector3(0, 0.6, 0), "Retour", Color(1, 0.8, 0.5))
				damage(src, maxi(1, rest / 2))
			elif not ranged and dist(src.cell, u.cell) == 1:
				var riposte := 0
				if u.has_p("casseur") and u.hp * 2 < u.max_hp:
					riposte = 8
				elif u.has_p("contre"):
					riposte = 4
				if riposte > 0:
					Fx.number(main, u.position + Vector3(0, 0.6, 0), "Contre", Color(1, 0.75, 0.4))
					damage(src, riposte)
	changed.emit()

const GOLD_FX := Color(1.0, 0.82, 0.4)


func kill(u: Unit, src: Unit = null) -> void:
	log_add("✝ %s tombe%s" % [u.nm, (" (%s)" % src.nm) if src and src != u else ""])
	if u.side == "foe":
		_killed = true
	u.hp = 0
	u.die()
	Fx.burst(main, u.position + Vector3(0, 0.5, 0), EMBER, 40, 3.5)
	if u.side == "foe":
		if u.mark > 0 and (u.bounty or trophy):
			main.gold += (25 if u.bounty else 0) + (10 if trophy else 0)
			main.ui.set_gold(main.gold)
			Fx.number(main, u.position + Vector3(0, 1.3, 0), "Prime !", GOLD_FX, true)
			if u.bounty and player_turn:
				draw(2)
		if u.mark > 0 and powers.has("vesk"):
			var vh: Unit = power_owner.get("vesk")
			if vh and vh.alive:
				_gain_energy(vh, 1)
			var nx: Unit = null
			for o in alive_foes():
				if o != u and (nx == null or dist(o.cell, u.cell) < dist(nx.cell, u.cell)):
					nx = o
			if nx:
				nx.mark = maxi(nx.mark, 2)
		_drop(u)
		if src and src.side == "hero" and src.has_p("absorbe"):
			_gain_energy(src, 1)
			Fx.number(main, src.position + Vector3(0, 0.5, 0), "+1 énergie", GOLD_FX)
		if has("cendre"):
			for d in Board.DIRS:
				var o := unit_at(u.cell + d)
				if o and o.side == "foe":
					damage(o, 4)
	check_end()


func heal(u: Unit, amt: int) -> void:
	var a := int(amt * (1.5 if u.trait_id == "beni" else 1.0))
	u.hp = mini(u.max_hp, u.hp + a)
	Fx.number(main, u.position, "+%d" % a, Color(0.6, 1.0, 0.55))
	Fx.burst(main, u.position + Vector3(0, 0.5, 0), Color(0.8, 1.0, 0.5), 20, 1.5, 7.0)
	changed.emit()


func gain_block(u: Unit, v: int) -> void:
	u.block += v
	Fx.number(main, u.position + Vector3(0, 0.2, 0), "🛡 +%d" % v, Color(0.7, 0.85, 0.95))
	changed.emit()


func push(u: Unit, d: Vector2i, n: int) -> void:
	if mods.has("glissant"):
		n += 1
	if has("crochet") and u.side == "foe":
		n += 1
	var from := u.cell
	if u.side == "foe" and powers.has("hallali"):
		u.mark = maxi(u.mark, 2)
	await _push_steps(u, d, n)
	if u.cell != from:
		u.pushed = true
	if u.alive and u.cell != from:
		if u.side == "foe" and traps.has(u.cell):
			await _spring(u)
		await _landed(u)


func _push_steps(u: Unit, d: Vector2i, n: int) -> void:
	for i in n:
		if not u.alive:
			return
		var nx := u.cell + d
		var o := unit_at(nx)
		if o:
			Fx.number(main, u.position, "Choc", Color(1, 0.8, 0.5))
			damage(u, 3)
			damage(o, 3)
			return
		if board.props.get(nx, "") in BOOM + ["pilier"]:
			Fx.number(main, u.position, "Choc", Color(1, 0.8, 0.5))
			damage(u, 3)
			await trigger_prop(nx, d)
			return
		if not board._in(nx) or board.kind[nx] == "tower" or board.blocked.has(nx) or board.props.has(nx) or (board.kind[nx] != "water" and board.h[nx] > board.h[u.cell] + 1):
			Fx.number(main, u.position, "Choc", Color(1, 0.8, 0.5))
			damage(u, 3)
			return
		if board.kind[nx] == "water" and not u.has_p("eau") and not u.fly:
			await _slide(u, Vector3(nx.x, Board.WATER_Y - 0.3, nx.y))
			Fx.burst(main, Vector3(nx.x, Board.WATER_Y + 0.1, nx.y), Color(0.75, 0.95, 1.0), 40, 3.0, 2.0)
			main.shake(0.2)
			if u.data.get("heavy", false):
				Fx.number(main, u.position, "Coulé", Color(0.6, 0.85, 1.0), true)
				kill(u)
				return
			if u.trait_id != "nageur":
				Fx.number(main, u.position, "Noyade", Color(0.6, 0.85, 1.0))
				damage(u, 8 + (6 if has("cloche") and u.side == "foe" else 0))
			if u.alive:
				var free := _nearest_free(nx)
				u.cell = free
				await u.teleport(free, board)
			return
		var drop: int = board.h[u.cell] - board.h[nx]
		u.cell = nx
		await _slide(u, board.world(nx))
		if drop >= 3:
			Fx.number(main, u.position, "Chute", Color(1, 0.8, 0.5))
			damage(u, drop)


func _slide(u: Unit, to: Vector3) -> void:
	var tw := u.create_tween()
	tw.tween_property(u, "position", to, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished


func _nearest_free(from: Vector2i) -> Vector2i:
	var best := from
	var bd := 1 << 30
	for c in board.walkable_cells():
		if unit_at(c) == null:
			var dd := dist(c, from)
			if dd < bd:
				bd = dd
				best = c
	return best


func check_end() -> void:
	if over:
		return
	if alive_foes().is_empty():
		over = true
		player_turn = false
		_finish(true)
	elif alive_heroes().is_empty():
		over = true
		player_turn = false
		_finish(false)


func _finish(v: bool) -> void:
	await wait(1.1)
	ended.emit(v)


# ------------------------------------------------------------------ IA

func can_hit(f: Unit, from: Vector2i, h: Unit) -> bool:
	var r: Array = f.data.range
	var hi: int = r[1] - (1 if r[1] > 2 and mods.has("brume") else 0)
	var dd := dist(from, h.cell)
	if dd < r[0] or dd > hi:
		return false
	if dd > 1 and smoke.has(h.cell):
		return false
	return r[1] > 1 or absi(board.h[from] - board.h[h.cell]) <= 3


func _wounded_ally(f: Unit) -> Unit:
	var best: Unit = null
	for o in alive_foes():
		if o != f and o.hp < o.max_hp * 0.75 and (best == null or o.hp * best.max_hp < best.hp * o.max_hp):
			best = o
	return best


func intent(f: Unit) -> String:
	var s := _intent(f)
	if f.tool != "":
		s += "  ⟨%s⟩" % Data.TOOLS[f.tool].glyph
	return ("♛ " + s) if f.affix != "" else s


func _intent(f: Unit) -> String:
	var dmg: int = f.atk()
	match f.data.ai:
		"bomb":
			return "✹ %d" % dmg
		"ranged":
			return "➶ %d" % dmg
		"healer":
			return "✚ %d" % f.data.heal if _wounded_ally(f) else "➶ %d" % dmg
		"assassin":
			return "† %d" % dmg
		"boss":
			return "☖ Appel" if (f.turns + 1) % 3 == 0 else "⚔ %d" % dmg
		"canto":
			return "⚔ %d ↩" % dmg
		"dancer":
			return "♪ Danse"
		"spawner":
			return "✺ Appel"
		"puller":
			return "⤶ %d" % dmg
		"commander":
			return "⚑ %d" % dmg
	return "⚔ %d" % dmg


func foe_act(f: Unit) -> void:
	var ai: String = f.data.ai
	f.turns += 1
	if ai == "boss" and f.turns % 3 == 0 and alive_foes().size() < 6:
		await f.cast()
		Fx.number(main, f.position + Vector3(0, 1.2, 0), "Appel !", EMBER, true)
		var free: Array = board.walkable_cells().filter(func(c): return unit_at(c) == null)
		free.sort_custom(func(a, b): return dist(a, f.cell) < dist(b, f.cell))
		for i in mini(2, free.size()):
			var u := spawn_foe("husk", free[i])
			u.face(f.cell - u.cell)
			Fx.burst(main, u.position + Vector3(0, 0.5, 0), EMBER, 30, 2.0, 6.0)
		await wait(0.5)
		return
	if f.tool != "":
		await _foe_tool(f)  # l'objet ne coûte pas son action
		if not f.alive or over:
			return
	var rooted := f.root > 0
	if rooted:
		f.root -= 1
		Fx.number(main, f.position + Vector3(0, 0.5, 0), "⛓", Color(0.8, 0.9, 1.0))
	var R := reach(f) if not rooted else {"prev": {f.cell: f.cell}, "cells": {f.cell: true}, "dist": {f.cell: 0}}
	if ai == "dancer":
		await _dance(f, R)
		return
	if ai == "spawner":
		await _summon(f)
		return
	if ai == "commander" and not alive_heroes().any(func(h): return dist(h.cell, f.cell) <= 4):
		Fx.number(main, f.position + Vector3(0, 1.1, 0), "Tient la position", Color(0.6, 0.95, 0.9))
		return  # il garde sa position : il attend qu'on vienne
	if ai == "healer":
		var w := _wounded_ally(f)
		if w:
			# se placer à portée du blessé, le plus loin possible des héros
			var go := f.cell
			var gs := -INF
			for cell in R.cells:
				var dd := dist(cell, w.cell)
				if dd < 1 or dd > 4:
					continue
				var s := 0.0
				for h in alive_heroes():
					s += minf(dist(cell, h.cell), 6)
				if s > gs:
					gs = s
					go = cell
			if gs > -INF:
				if go != f.cell:
					await _foe_walk(f, path_to(R.prev, go))
				if not f.alive or dist(f.cell, w.cell) > 4:
					return
				f.face(w.cell - f.cell)
				await f.cast()
				await Fx.bolt(main, f.position, w.position, Color(1.0, 0.7, 0.3))
				heal(w, f.data.heal)
				return
	var live := alive_heroes()
	if live.is_empty():
		return
	var taunter: Unit = null
	for h in live:
		if h.taunt:
			taunter = h
	var best_cell = null
	var best_t: Unit = null
	var best_s := -INF
	var saved := f.cell
	for cell in R.cells:
		f.cell = cell
		for h in live:
			if taunter and h != taunter and dist(cell, taunter.cell) <= 6:
				continue
			if not can_hit(f, cell, h):
				continue
			var dmg: int = calc(f, h, f.atk()).dmg
			var s: float = dmg * 10.0 - R.dist[cell] * 0.5
			if tiles.get(cell, "") in ["lave", "ronces", "glyphe"]:
				s -= 40  # il évite les pièges du terrain
			elif tiles.get(cell, "") in ["fourre", "fort"]:
				s += 12
			if dmg >= h.hp + h.block:
				s += 60
			if ai == "ranged" or ai == "healer":
				s += board.h[cell] * 3 + dist(cell, h.cell) * 2
			if ai == "assassin":
				s += (40 - h.hp) * 2
			if s > best_s:
				best_s = s
				best_cell = cell
				best_t = h
	f.cell = saved
	if best_cell != null:
		if best_cell != f.cell:
			await _foe_walk(f, path_to(R.prev, best_cell))
		if f.alive and can_hit(f, f.cell, best_t):
			await foe_strike(f, best_t)
		if ai == "canto" and f.alive and not over:
			await _canto(f)
		return
	# approche : la case la plus proche d'un héros (le plus faible pour l'assassin)
	var targets: Array = [taunter] if taunter else live
	if ai == "assassin" and not taunter:
		targets = [live.reduce(func(a, b): return a if a.hp < b.hp else b)]
	var dm := board.bfs_dist(targets.map(func(u): return u.cell), f.jump, f.fly)
	var go := f.cell
	var gd: int = dm.get(f.cell, 999)
	for cell in R.cells:
		var v: int = dm.get(cell, 999)
		if v < gd or (v == gd and board.h[cell] > board.h[go]):
			gd = v
			go = cell
	if go != f.cell:
		await _foe_walk(f, path_to(R.prev, go))
	if not f.alive:
		return
	for h in live:
		if can_hit(f, f.cell, h):
			await foe_strike(f, h)
			return


func _summon(f: Unit) -> void:
	## L'obélisque appelle une créature à côté de lui (8 ennemis au plus).
	if alive_foes().size() >= 8:
		return
	var free: Array = Board.DIRS.map(func(d): return f.cell + d).filter(func(c): return board.walkable(c) and unit_at(c) == null and not board.props.has(c))
	if free.is_empty():
		return
	var id: String = ["husk", "wisp", "harpie"][f.turns % (2 if floor_bonus() < 1 else 3)]
	await f.cast()
	var u := spawn_foe(id, free[randi() % free.size()])
	u.face(u.cell - f.cell)
	Fx.burst(main, u.position + Vector3(0, 0.6, 0), Data.TILES.glyphe.col, 40, 3.0, 5.0)
	Fx.number(main, f.position + Vector3(0, 2.2, 0), "Appel : %s" % u.nm, Data.TILES.glyphe.col, true)
	await wait(0.4)


func floor_bonus() -> int:
	return champions  # 0 au premier étage, 1 au deuxième...


func _canto(f: Unit) -> void:
	## Canto : le cavalier frappe puis se replie loin des héros.
	var R2 := reach(f)
	var go := f.cell
	var gs := -INF
	for cell in R2.cells:
		if R2.dist.get(cell, 99) > 3 or tiles.get(cell, "") in ["lave", "ronces"]:
			continue
		var s := 0.0
		for h in alive_heroes():
			s += minf(dist(cell, h.cell), 5)
		if s > gs:
			gs = s
			go = cell
	if go != f.cell:
		Fx.number(main, f.position + Vector3(0, 1.1, 0), "Canto", Color(0.6, 0.95, 0.9))
		await _foe_walk(f, path_to(R2.prev, go))


func _dance(f: Unit, R: Dictionary) -> void:
	## La Danseuse fait rejouer un allié qui a déjà agi ce round ; sinon elle se tient à l'abri.
	var done: Array = order.slice(0, qi).filter(func(o): return is_instance_valid(o) and o.alive and o.side == "foe" and o.data.ai != "dancer")
	done.sort_custom(func(a, b): return a.atk() > b.atk())
	for ally in done:
		var spot = null
		var sd := 999
		for cell in R.cells:
			if dist(cell, ally.cell) == 1 and R.dist[cell] < sd and not tiles.get(cell, "") in ["lave", "ronces"]:
				sd = R.dist[cell]
				spot = cell
		if spot == null:
			continue
		if spot != f.cell:
			await _foe_walk(f, path_to(R.prev, spot))
		if not f.alive:
			return
		f.face(ally.cell - f.cell)
		await f.cast()
		Fx.burst(main, ally.position + Vector3(0, 0.8, 0), Color(0.4, 1.0, 0.9), 40, 3.0)
		Fx.number(main, ally.position + Vector3(0, 1.3, 0), "Danse : rejoue !", Color(0.5, 1.0, 0.9), true)
		await wait(0.3)
		await foe_act(ally)
		return
	# personne à faire danser : rester loin des héros, près des siens
	var go := f.cell
	var gs := -INF
	for cell in R.cells:
		var s := 0.0
		for h in alive_heroes():
			s += minf(dist(cell, h.cell), 6)
		for o in alive_foes():
			if o != f and dist(o.cell, cell) <= 2:
				s += 2
		if s > gs:
			gs = s
			go = cell
	if go != f.cell:
		await _foe_walk(f, path_to(R.prev, go))


func foe_strike(f: Unit, h: Unit) -> void:
	f.face(h.cell - f.cell)
	var ai: String = f.data.ai
	if ai == "bomb":
		await f.lunge(h.position)
		Fx.burst(main, f.position + Vector3(0, 0.6, 0), EMBER, 70, 5.0)
		main.shake(0.45)
		for d in Board.DIRS:
			var o := unit_at(f.cell + d)
			if o:
				damage(o, f.atk(), f)
		kill(f)
		return
	var ranged: bool = f.data.range[1] > 1
	if ranged:
		await f.cast()
		await Fx.bolt(main, f.position, h.position, EMBER)
	else:
		await f.lunge(h.position)
	if ai == "puller" and dist(f.cell, h.cell) > 1:
		# la langue du crapaud ramène sa proie au contact
		Fx.number(main, h.position + Vector3(0, 1.0, 0), "Happé !", Color(0.9, 0.4, 0.5), true)
		await push(h, _dir(h.cell, f.cell), dist(f.cell, h.cell) - 1)
		if not h.alive:
			return
	f.struck_hero = true
	var dmg: int = calc(f, h, f.atk()).dmg
	if randf() < float(f.data.get("crit", 0.0)):
		dmg *= 2
		Fx.number(main, h.position + Vector3(0, 1.1, 0), "Critique !", Color(1.0, 0.9, 0.3), true)
		main.shake(0.4)
	if f.data.get("arme", "") == "magie" and f.data.ai != "healer":
		var keep := h.block  # la magie passe sous l'armure
		h.block = 0
		damage(h, dmg, f, true, ranged)
		h.block = keep
	else:
		damage(h, dmg, f, true, ranged)
	if ai == "boss":
		main.shake(0.5)
		for d in Board.DIRS:
			var o := unit_at(h.cell + d)
			if o and o.side == "hero":
				damage(o, 4, f)
	if f.data.get("shove", 0) > 0 and h.alive and f.alive:
		await push(h, _dir(f.cell, h.cell), int(f.data.shove))


# ------------------------------------------------------------------ surbrillance

func refresh_highlight(hover) -> void:
	## Pas de grille permanente : contours pour la portée, cases pleines pour les choix.
	var cells := {}
	if _orient_mark:
		_orient_mark.visible = orienting and active != null
	if orienting and active:
		if hover != null and hover != active.cell:
			active.face(hover - active.cell)
		if _orient_mark == null:
			_orient_mark = Label3D.new()
			_orient_mark.text = "⇩"
			_orient_mark.font = Fx.title_font()
			_orient_mark.font_size = 120
			_orient_mark.pixel_size = 0.006
			_orient_mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			_orient_mark.no_depth_test = true
			_orient_mark.modulate = Color(1.0, 0.82, 0.35)
			_orient_mark.outline_size = 20
			_orient_mark.outline_modulate = Color(0.1, 0.05, 0.02, 0.9)
			_orient_mark.render_priority = 10
			_orient_mark.outline_render_priority = 9
			units_root.add_child(_orient_mark)
		_orient_mark.visible = true
		var fp := board.world(active.cell + active.facing)
		_orient_mark.position = Vector3(fp.x, maxf(fp.y, active.position.y) + 0.8, fp.z)
		for d in Board.DIRS:
			if board._in(active.cell + d):
				cells[active.cell + d] = Color(1.0, 0.82, 0.35, 0.95) if d == active.facing else 					(Color(1.0, 0.3, 0.22, 0.45) if d == -active.facing else Color(1, 1, 1, 0.3))
		board.highlight(cells)
		return
	if player_turn and not busy:
		if tool_sel >= 0 and tool_sel < besace.size() and selected:
			var tid: String = besace[tool_sel]
			var tg := tool_targets(tid, selected)
			for t in tg:
				cells[t] = Color(0.3, 1.0, 0.8, 0.9)
			if hover != null and tg.has(hover) and tid in ["bombe", "fumigene", "picots"]:
				for d in Board.DIRS:
					if board._in(hover + d):
						cells[hover + d] = Color(1.0, 0.6, 0.2, 0.9)
		elif card_sel >= 0 and card_sel < hand.size():
			var c := Data.card(hand[card_sel])
			var h := owner_of(c)
			var col := Color(1.0, 0.3, 0.22)
			if c.has("heal") or c.has("heal_all") or c.has("block"):
				col = Color(0.45, 1.0, 0.5)
			elif c.kind == "move" or c.has("place"):
				col = Color(0.15, 0.9, 1.0)
			for t in range_cells(c, h):
				cells[t] = Color(col.r, col.g, col.b, 0.35)
			var tg := card_targets(c, h)
			for t in tg:
				cells[t] = Color(col.r, col.g, col.b, 0.95)
			if hover != null and tg.has(hover) and c.get("aoe", false):
				for d in Board.DIRS:
					if board._in(hover + d):
						cells[hover + d] = Color(1.0, 0.6, 0.2, 0.9)
		elif selected and selected.alive and (not selected.moved or can_sprint(selected)):
			var sp := selected.moved
			for t in reach(selected).cells:
				if t != selected.cell:
					cells[t] = Color(0.85, 0.6, 1.0, 0.45) if sp else Color(0.4, 0.68, 1.0, 0.75)
			for pc in board.props:
				if board.props[pc] in ["coffre", "levier"] and dist(pc, selected.cell) == 1:
					cells[pc] = Color(1.0, 0.85, 0.35, 0.95)
		# zone de déplacement de l'ennemi épinglé ou survolé
		var look: Unit = inspect if inspect and inspect.alive else null
		if look == null and hover != null:
			look = unit_at(hover)
		if card_sel < 0 and tool_sel < 0 and look and look.side == "foe":
			for t in reach(look).cells:
				cells[t] = Color(1.0, 0.45, 0.2, 0.6)
	if danger:
		for t in threat_cells():
			if not cells.has(t):
				cells[t] = Color(1.0, 0.25, 0.2, 0.34)
	if hover != null:
		cells[hover] = Color(1, 1, 1, 0.45) if not cells.has(hover) else Color(cells[hover].lightened(0.45), maxf(cells[hover].a, 0.6))
	for f in foes:
		if f.alive:
			f.set_xray(hover != null and f.cell == hover)
	var alt := Input.is_key_pressed(KEY_ALT)
	for pc in prop_nodes:
		var nd: Node3D = prop_nodes[pc]
		if nd.has_meta("mark"):
			nd.get_meta("mark").visible = alt or pc == hover or cells.has(pc)
	board.highlight(cells)


func threat_cells() -> Dictionary:
	## Toutes les cases qu'un ennemi peut frapper ce tour (déplacement + portée).
	var out := {}
	for f in alive_foes():
		if f.data.ai in ["dancer", "spawner"]:
			continue
		var r: Array = f.data.range
		var from: Dictionary = reach(f).cells if f.root <= 0 else {f.cell: true}
		for c in from:
			for dx in range(-r[1], r[1] + 1):
				var w: int = r[1] - absi(dx)
				for dz in range(-w, w + 1):
					var t: Vector2i = c + Vector2i(dx, dz)
					if absi(dx) + absi(dz) >= r[0] and board._in(t) and board.kind[t] != "tower":
						out[t] = true
	return out


func predict(u: Unit, hover) -> Dictionary:
	## Dégâts prévus sur u par la carte en main, si u est la cible survolée.
	if card_sel < 0 or card_sel >= hand.size() or hover == null or u.cell != hover:
		return {}
	var c := Data.card(hand[card_sel])
	var h := owner_of(c)
	if c.get("dmg", 0) <= 0 or not card_targets(c, h).has(hover):
		return {}
	var r := calc(h, u, _base(c, h, u.cell), c)
	r.dmg *= int(c.get("hits", 1))
	if _trig_dmg(c, h, u.cell) > 0:
		r.notes.append(Data.TRIGGERS[c.trig.on].name)
	return r


func preview(hover) -> String:
	if hover == null:
		return ""
	var u := unit_at(hover)
	if card_sel >= 0 and card_sel < hand.size() and u and u.side == "foe":
		var c := Data.card(hand[card_sel])
		var h := owner_of(c)
		if card_targets(c, h).has(hover) and c.get("dmg", 0) > 0:
			var r := calc(h, u, _base(c, h, u.cell), c)
			var t := "%s — %d dégâts" % [u.nm, r.dmg * int(c.get("hits", 1))]
			if r.notes.size() > 0:
				t += "  (" + " · ".join(r.notes) + ")"
			return t
	if u:
		var t := "%s  %d/%d PV" % [u.nm, u.hp, u.max_hp]
		if u.block > 0:
			t += "  🛡%d" % u.block
		if u.poison > 0:
			t += "  ☠%d" % u.poison
		if u.side == "foe":
			t += "  —  %s" % Data.FOE_TIPS.get(u.key, "")
			if u.affix != "":
				t += "  ♛ " + Data.AFFIXES[u.affix].text
			if u.tool != "":
				t += "  ·  porte %s %s" % [Data.TOOLS[u.tool].glyph, Data.TOOLS[u.tool].name]
		if tiles.has(hover):
			t += "  ·  sur %s" % Data.TILES[tiles[hover]].name
		var ps: Array = u.passives()
		if ps.size() > 0:
			t += "  ·  " + ", ".join(ps.map(func(p): return Data.PASSIVES[p].name))
		return t
	if loot.has(hover):
		var lt: Dictionary = Data.TOOLS[loot[hover][0]]
		return "Butin : %s — %s  (un héros qui y passe le ramasse)" % [lt.name, lt.text]
	if tiles.has(hover):
		var tl: Dictionary = Data.TILES[tiles[hover]]
		return "%s — %s" % [tl.name, tl.text]
	if oaks.has(hover):
		return "Chêne planté — barre la case ; +3 armure aux héros voisins ; une explosion l'embrase"
	if smoke.has(hover):
		return "Fumée (%d tour(s)) — on n'y vise pas de loin ; au contact, coups de dos" % smoke[hover]
	if traps.has(hover):
		return "Picots — l'ennemi qui y marche s'arrête et subit 5" if trap_kind.get(hover, "") == "picots" else "Piège à mâchoires — 8 dégâts et entrave"
	if board.props.has(hover):
		var pk: String = board.props[hover]
		if Data.PROPS.has(pk):
			return "%s — %s" % [Data.PROPS[pk].name, Data.PROPS[pk].text]
		return "Levier actionné"
	if objective == "portal" and hover == board.portal:
		return "Portail — un héros qui s'y arrête termine le combat"
	if board._in(hover):
		var k: String = board.kind[hover]
		if k == "water":
			return "Eau profonde — y pousser un ennemi le noie" + (" (pont-levis)" if board.drawbridge.has(hover) else "")
		if board.blocked.has(hover):
			return "Arbre" if board.blocked[hover] == "tree" else "Lanterne"
		if k == "tower":
			return "Tour"
		return "Hauteur %d" % board.h[hover]
	return ""


# ------------------------------------------------------------------ fiche d'unité

func sheet(u: Unit) -> String:
	var L: Array = []
	L.append("PV %d / %d%s%s" % [u.hp, u.max_hp, "   🛡 %d" % u.block if u.block > 0 else "", "   ☠ %d" % u.poison if u.poison > 0 else ""])
	L.append("Déplacement %d · Saut %d%s" % [u.move, u.jump, " · vole" if u.fly else ""])
	if u.mark > 0:
		L.append("◎ Marqué %d tour(s) : +50 %% de dégâts reçus" % u.mark)
	if u.root > 0:
		L.append("⛓ Entravé %d tour(s) : ne bouge plus" % u.root)
	if u.side == "hero":
		L.append("Trait — %s : %s" % [Data.TRAITS[u.trait_id].name, Data.TRAITS[u.trait_id].text])
		L.append(main.voc_line(u))
		for slot in ["arme", "talisman"]:
			var id: String = u.equip[slot]
			L.append("%s — %s" % [slot.capitalize(), "%s : %s" % [Data.ITEMS[id].name, Data.item_text(id)] if id != "" else "rien"])
		if u.key == "receleur":
			L.append("Bricole %d / 3" % bricole)
		if tiles.has(u.cell):
			L.append("Sur %s : %s" % [Data.TILES[tiles[u.cell]].name, Data.TILES[tiles[u.cell]].text])
		var n := hand.filter(func(ci): return Data.card(ci).owner == u.key).size()
		L.append("Cartes en main : %d%s" % [n, " · a déjà bougé" if u.moved else ""])
		return "\n".join(L)
	var arm := int(u.data.get("armor", 0)) + u.extra_armor
	if arm > 0:
		L.append("Armure +%d à chaque tour" % arm)
	if u.data.get("arme", "") == "magie":
		L.append("Magie : ses coups passent sous l'armure.")
	L.append("Prochaine action : %s" % intent(u))
	L.append(_intent_text(u))
	if u.tool != "":
		var td: Dictionary = Data.TOOLS[u.tool]
		L.append("%s Porte : %s — %s. À voler, ou il le lâche en tombant." % [td.glyph, td.name, td.get("foe_ai", "")])
	L.append(Data.FOE_TIPS.get(u.key, ""))
	if u.affix != "":
		L.append("♛ %s : %s" % [Data.AFFIXES[u.affix].name, Data.AFFIXES[u.affix].text])
	for q in u.passives():
		L.append("%s : %s" % [Data.PASSIVES[q].name, Data.PASSIVES[q].text])
	L.append("Zone orange : où il peut aller ce tour.")
	return "\n".join(L)


func _intent_text(f: Unit) -> String:
	var dmg: int = f.atk()
	var rg: Array = f.data.range
	match f.data.ai:
		"melee":
			return "Avance et frappe au contact : %d dégâts." % dmg
		"ranged":
			return "Tire entre %d et %d cases : %d dégâts." % [rg[0], rg[1], dmg]
		"bomb":
			return "Fonce et explose au contact : %d dégâts autour de lui." % dmg
		"healer":
			return "Soigne %d un allié blessé, sinon tire : %d dégâts." % [f.data.heal, dmg]
		"assassin":
			return "Fond sur le héros le plus faible : %d dégâts." % dmg
		"boss":
			return "Frappe %d au contact ; appelle des renforts tous les 3 tours." % dmg
		"canto":
			return "Frappe %d au contact, puis se replie jusqu'à 3 cases (Canto)." % dmg
		"dancer":
			return "Fait rejouer un allié qui a déjà agi ce round."
		"spawner":
			return "Invoque une créature à côté de lui à chacun de ses tours."
		"puller":
			return "Attire un héros jusqu'à lui depuis %d cases, puis mord : %d dégâts." % [rg[1], dmg]
		"commander":
			return "Attend qu'un héros approche à 4 cases, puis frappe %d. Ses soldats à 2 cases frappent +2." % dmg
	return ""


# ------------------------------------------------------------------ pièges, tourelles, pouvoirs

func _count_hit(h: Unit) -> void:
	## Enchaînement du Moine ; la Voie du poing récompense chaque 3e coup.
	if h.key != "moine" and h.voc != "moine" and h.voc2 != "moine":
		return
	h.combo += 1
	if h.combo >= 2:
		Fx.number(main, h.position + Vector3(0, 1.0, 0), "Enchaînement ×%d" % h.combo, Data.CLASS_COLOR.moine.lightened(0.3))
	if powers.has("voie") and h.combo % (3 - int(power_val.get("voie", 0))) == 0:
		energy += 1
		draw(1)
		Fx.number(main, h.position + Vector3(0, 1.3, 0), "+1 énergie", GOLD_FX)


func _place(c: Dictionary, t: Vector2i, h: Unit) -> void:
	var k: String = c.place
	h.face(t - h.cell)
	await h.cast()
	if unit_at(t) or board.props.has(t) or traps.has(t) or not board.walkable(t):
		return
	if k in TRAP_KINDS:
		var spots: Array = [t]
		if c.get("twin", false):
			for d in Board.DIRS:
				var n: Vector2i = t + d
				if board.walkable(n) and unit_at(n) == null and not traps.has(n) and not board.props.has(n):
					spots.append(n)
					break
		for sp: Vector2i in spots:
			_make_trap(sp, k, int(c.get("tdmg", 8)))
		if c.get("plus_baril", false):
			for d in Board.DIRS:
				var n: Vector2i = t + d
				if board.walkable(n) and unit_at(n) == null and not traps.has(n) and not board.props.has(n):
					board.props[n] = "baril"
					_make_prop(n)
					break
	else:
		board.props[t] = k
		_make_prop(t)
		if k == "tourelle":
			var tt := int(c.get("turns", 3))
			if c.get("turns_items", false):
				tt = maxi(tt, besace.size())
			turrets[t] = {"turns": tt, "dmg": int(c.get("tdmg", 4)), "push": int(c.get("tpush", 0)), "mark": c.get("tmark", false),
				"pierce": c.get("tpierce", false), "far": c.get("tfar", false), "range": int(c.get("trange", 5))}
	Fx.burst(main, board.world(t) + Vector3(0, 0.3, 0), Data.CLASS_COLOR[h.key].lightened(0.2), 26, 2.5, 5.0)
	await wait(0.2)


func _make_trap(sp: Vector2i, k: String, td: int) -> void:
	var node := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = Board.mesh_of("prop_picots" if k == "epieu" else "prop_piege").mesh
	mi.material_override = Board.material("prop")
	node.add_child(mi)
	node.position = board.world(sp)
	if k in ["mine", "ombre", "collet"]:
		var l3 := Label3D.new()
		l3.text = {"mine": "✹", "ombre": "◎", "collet": "◆"}[k]
		l3.font = Fx.title_font()
		l3.font_size = 64
		l3.pixel_size = 0.004
		l3.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l3.modulate = {"mine": EMBER, "ombre": Color(0.85, 0.6, 1.0), "collet": GOLD_FX}[k]
		l3.outline_size = 14
		l3.outline_modulate = Color(0.05, 0.03, 0.02, 0.85)
		l3.position.y = 0.45
		node.add_child(l3)
	units_root.add_child(node)
	traps[sp] = node
	trap_kind[sp] = k
	trap_dmg[sp] = td


func _foe_walk(f: Unit, path: Array) -> void:
	## Un piège sur le chemin arrête l'ennemi net.
	var cut := path.size()
	for i in path.size():
		if traps.has(path[i]) and (unit_at(path[i]) == null or unit_at(path[i]) == f):
			cut = i + 1
			break
	path = path.slice(0, cut)
	if path.is_empty():
		return
	await f.walk(path, board)
	if traps.has(f.cell):
		await _spring(f)
	if f.alive:
		await _landed(f)


func _spring(f: Unit) -> void:
	## Piège à mâchoires (8, entrave) ou picots (5) : l'ennemi s'arrête dessus.
	var node: Node3D = traps[f.cell]
	var k: String = trap_kind.get(f.cell, "piege")
	var td: int = trap_dmg.get(f.cell, 8)
	traps.erase(f.cell)
	trap_kind.erase(f.cell)
	trap_dmg.erase(f.cell)
	node.queue_free()
	main.shake(0.35 if k == "piege" else 0.2)
	Fx.number(main, f.position + Vector3(0, 0.6, 0), "Piège !" if k == "piege" else "Picots !", Color(1.0, 0.8, 0.4), true)
	Fx.burst(main, f.position + Vector3(0, 0.3, 0), Color(0.75, 0.7, 0.6), 30, 3.0)
	var plus := (int(power_val.get("hallali", 4)) if powers.has("hallali") else 0) + (int(power_val.get("crane", 3)) if powers.has("crane") else 0)
	var cell := f.cell
	for rep_i in (2 if double_trap else 1):
		if not f.alive:
			break
		match k:
			"piege":
				f.root = maxi(f.root, 1)
				if powers.has("instinct"):
					f.mark = maxi(f.mark, 2)
				damage(f, td + plus + (6 + int(power_val.get("instinct", 0)) if powers.has("instinct") else 0))
			"mine":
				f.mark = maxi(f.mark, 2)
				_explode(cell, td + plus)
			"epieu":
				f.root = maxi(f.root, 2)
				damage(f, td + plus)
			"ombre":
				f.root = maxi(f.root, 2)
				f.mark = maxi(f.mark, 2)
				damage(f, td + plus)
			"collet":
				f.root = maxi(f.root, 1)
				_steal(active if active else heroes[0], f)
				damage(f, td + plus)
			_:
				damage(f, 5 + plus)
		if double_trap and rep_i == 0:
			Fx.number(main, f.position + Vector3(0, 0.9, 0), "Deux fois !", Color(1.0, 0.8, 0.4), true)
			await wait(0.2)
	if powers.has("crane"):
		_craft(1)
	await wait(0.3)


func _turrets_fire() -> void:
	for c in turrets.keys():
		var tr: Dictionary = turrets[c]
		var rg: int = int(tr.get("range", 5))
		var best: Unit = null
		var cands: Array = alive_foes().filter(func(f): return dist(f.cell, c) <= rg)
		if tr.get("far", false) and cands.any(func(f): return f.mark > 0):
			cands = cands.filter(func(f): return f.mark > 0)
		for f in cands:
			if best == null or (dist(f.cell, c) > dist(best.cell, c) if tr.get("far", false) else dist(f.cell, c) < dist(best.cell, c)):
				best = f
		if best:
			await Fx.bolt(main, board.world(c) + Vector3(0, 0.7, 0), best.position, Data.CLASS_COLOR.artificier.lightened(0.3))
			if tr.get("pierce", false):
				best.block = 0
			damage(best, int(tr.dmg))
			if best.alive and tr.get("mark", false):
				best.mark = maxi(best.mark, 2)
			if best.alive and int(tr.get("push", 0)) > 0:
				await push(best, _dir(c, best.cell), int(tr.push))
			await wait(0.15)
		turrets[c].turns -= 1
		if turrets[c].turns <= 0:
			turrets.erase(c)
			_remove_prop(c)
		if over:
			return


func _power_ticks(h: Unit) -> void:
	## Au début du tour de leur héros : cendres de l'Oracle, barils de l'Artificier, bricolage du Receleur.
	if h.key == "oracle" and powers.has("cendres"):
		var near: Array = alive_foes()
		near.sort_custom(func(a, b): return dist(a.cell, h.cell) < dist(b.cell, h.cell))
		for f in near.slice(0, 1 + int(power_val.get("cendres2", 0))):
			Fx.burst(main, f.position + Vector3(0, 1.2, 0), EMBER, 40, 4.0)
			damage(f, 4 + int(power_val.get("cendres", 0)))
	if h.key == "artificier" and powers.has("atelier"):
		for n in 1 + int(power_val.get("atelier", 0)):
			var live := alive_foes()
			if live.is_empty():
				break
			var f: Unit = live[randi() % live.size()]
			for d in Board.DIRS:
				var t: Vector2i = f.cell + d
				if board.walkable(t) and unit_at(t) == null and not traps.has(t):
					board.props[t] = "baril"
					_make_prop(t)
					Fx.burst(main, board.world(t) + Vector3(0, 0.3, 0), Data.CLASS_COLOR.artificier, 20, 2.0)
					break
	if h.key == "receleur" and powers.has("poches"):
		_craft(1 + int(power_val.get("poches", 0)), h)


# ------------------------------------------------------------------ déclencheurs

func _trig_ok(c: Dictionary, h: Unit, t) -> bool:
	## Condition du déclencheur avant de jouer (Coup de grâce se vérifie après).
	if not c.has("trig") or h == null:
		return false
	match c.trig.on:
		"mur":
			return h.hp * 10 < h.max_hp * 3
		"enchaine":
			return played >= 1
		"premier":
			return played == 0
		"surplomb":
			return t != null and board._in(t) and board.h[h.cell] > board.h[t]
		"precision":
			return t != null and absi(dist(h.cell, t) - card_range(c, h).y) <= (1 if powers.has("aelis") else 0)
		"tenaille":
			var f: Unit = unit_at(t) if t != null else null
			if f == null or f.side != "foe":
				return false
			var o := unit_at(t + _dir(h.cell, t))
			return o != null and o.side == "hero" and o != h
		"proie":
			var f: Unit = unit_at(t) if t != null else null
			return f != null and f.side == "foe" and (f.mark > 0 or f.root > 0)
		"attaque":
			var f: Unit = unit_at(t) if t != null else null
			return f != null and f.side == "foe" and f.struck_hero
		"chasse":
			var f: Unit = unit_at(t) if t != null else null
			return f != null and f.side == "foe" and f.pushed
		"poudre":
			return booms > 0
		"blesse":
			return hurt_turn
		"grixis":
			var v: Array = voices.duplicate()
			if c.has("voix") and not v.has(c.voix):
				v.append(c.voix)
			return v.has("B") and v.has("R") and v.has("N")
	return false


func trig_live(c: Dictionary) -> bool:
	## Pour faire briller la carte en main : conditions qui ne dépendent pas de la cible.
	var h := owner_of(c)
	return c.has("trig") and h != null and h.alive and c.trig.on in ["mur", "enchaine", "premier", "grixis", "poudre", "blesse"] and _trig_ok(c, h, null)


func _trig_dmg(c: Dictionary, h: Unit, t) -> int:
	return int(c.trig.get("dmg", 0)) if c.has("trig") and c.trig.on != "grace" and _trig_ok(c, h, t) else 0


func _trig_apply(c: Dictionary, h: Unit, t) -> bool:
	## Effets hors dégâts ; renvoie vrai si la carte revient en main.
	var tr: Dictionary = c.trig
	Fx.number(main, h.position + Vector3(0, 1.1, 0), Data.TRIGGERS[tr.on].name + " !", Color(1.0, 0.85, 0.4))
	if tr.has("block"):
		gain_block(h, tr.block)
	if tr.has("heal"):
		heal(h, tr.heal)
	if tr.has("draw"):
		draw(tr.draw)
	if tr.has("energy"):
		energy += tr.energy
	if tr.has("poison") and t != null:
		var f := unit_at(t)
		if f and f.alive and f.side == "foe":
			f.poison += tr.poison
	if tr.get("keep", false):
		h.keep_block = true
	if (tr.has("mark") or tr.has("boom")) and t != null:
		var f := unit_at(t)
		if f and f.alive and f.side == "foe":
			if tr.has("mark"):
				f.mark = maxi(f.mark, int(tr.mark))
			if tr.has("boom"):
				_boom_foes(f.cell, int(tr.boom))
	changed.emit()
	return tr.get("refund", false)


func _reinforce() -> void:
	## Modificateur Renforts : deux Moussus au plus loin des héros.
	var free: Array = board.walkable_cells().filter(func(c): return unit_at(c) == null and not board.props.has(c))
	free.sort_custom(func(a, b): return _hero_dist(a) > _hero_dist(b))
	for i in mini(2, free.size()):
		var u := spawn_foe("husk", free[i])
		Fx.burst(main, u.position + Vector3(0, 0.5, 0), EMBER, 30, 2.0, 6.0)
	main.ui.toast("Renforts ennemis !")


func _hero_dist(c: Vector2i) -> int:
	var best := 999
	for h in alive_heroes():
		best = mini(best, dist(c, h.cell))
	return best


# ------------------------------------------------------------------ besace : objets à usage unique

func besace_cap() -> int:
	return besace_max + ((2 + int(power_val.get("poches", 0))) if powers.has("poches") else 0)


func _base(c: Dictionary, h: Unit, t) -> int:
	## Dégâts de base d'une carte avant hauteur, dos, marque...
	return int(c.get("dmg", 0)) + int(c.get("combo", 0)) * h.combo + _trig_dmg(c, h, t) + int(c.get("flow", 0)) * played + int(c.get("junk", 0)) * besace.size() \
		+ int(h.block * float(c.get("per_block", 0.0))) + int(c.get("per_boom", 0)) * booms


func select_tool(i: int) -> void:
	if not player_turn or busy or over or i >= besace.size():
		return
	if tool_sel == i:
		tool_sel = -1
		changed.emit()
		return
	if selected == null or not selected.alive:
		main.ui.toast("Choisissez d'abord le héros qui s'en sert.")
		return
	card_sel = -1
	tool_sel = i
	if Data.TOOLS[besace[i]].target == "self":
		use_tool(i, selected.cell)
		return
	if tool_targets(besace[i], selected).is_empty():
		main.ui.toast("Aucune cible à portée de %s." % selected.nm)
	changed.emit()


func tool_targets(id: String, h: Unit) -> Array:
	var t: Dictionary = Data.TOOLS[id]
	var r: Array = t.get("range", [0, 0])
	var out: Array = []
	match t.target:
		"self":
			out.append(h.cell)
		"ally":
			for a in alive_heroes():
				if dist(h.cell, a.cell) >= r[0] and dist(h.cell, a.cell) <= r[1]:
					out.append(a.cell)
		"foe":
			for f in alive_foes():
				if dist(h.cell, f.cell) >= r[0] and dist(h.cell, f.cell) <= r[1]:
					out.append(f.cell)
		"free":
			for c in board.walkable_cells():
				if dist(h.cell, c) >= r[0] and dist(h.cell, c) <= r[1] and unit_at(c) == null and not traps.has(c):
					out.append(c)
		"tile":
			for x in board.dim:
				for z in board.dim:
					var c := Vector2i(x, z)
					if dist(h.cell, c) >= r[0] and dist(h.cell, c) <= r[1] and board.kind[c] != "tower":
						out.append(c)
	return out


func use_tool(i: int, t: Vector2i) -> void:
	var id: String = besace[i]
	var h := selected
	besace.remove_at(i)
	if powers.has("oriel") and not oriel_back.has(id):
		oriel_back[id] = true
		besace.append(id)
		Fx.number(main, h.position + Vector3(0, 1.2, 0), "Dame Oriel : %s revient" % Data.TOOLS[id].name, GOLD_FX)
	if powers.has("linfei") and power_owner.get("linfei") == h:
		h.hits += 1
		_count_hit(h)
	tool_sel = -1
	busy = true
	board.highlight({})
	main.ui.toast("%s — %s" % [h.nm, Data.TOOLS[id].name])
	changed.emit()
	await _apply_tool(id, h, t)
	if powers.has("marchenoir") and not over:
		var near: Unit = null
		for f in alive_foes():
			if near == null or dist(f.cell, h.cell) < dist(near.cell, h.cell):
				near = f
		if near:
			await Fx.bolt(main, h.position, near.position, Data.CLASS_COLOR.receleur.lightened(0.3))
			damage(near, 4 + int(power_val.get("marchenoir", 0)))
	busy = false
	changed.emit()
	_after_action()


func _apply_tool(id: String, u: Unit, t: Vector2i) -> void:
	## Effet d'un objet, qu'un héros ou un ennemi s'en serve.
	if t != u.cell:
		u.face(t - u.cell)
	await u.cast()
	var tgt := unit_at(t)
	if item_poison > 0 and u.side == "hero" and tgt and tgt.side == "foe":
		tgt.poison += item_poison
	match id:
		"fiole":
			if tgt:
				heal(tgt, 20 if fiole2 and u.side == "hero" else 10)
		"sels":
			if tgt:
				tgt.poison = 0
				tgt.root = 0
				gain_block(tgt, 6)
		"elixir":
			energy += 2
			Fx.number(main, u.position + Vector3(0, 0.6, 0), "+2 énergie", GOLD_FX)
		"carnet":
			draw(3)
		"de":
			var n := hand.size()
			discard.append_array(hand)
			hand.clear()
			draw(n)
		"sablier":
			for f in alive_foes():
				f.root = maxi(f.root, 1)
				Fx.number(main, f.position + Vector3(0, 0.5, 0), "⛓", Color(0.8, 0.9, 1.0))
		"filet":
			if tgt:
				await Fx.bolt(main, u.position, tgt.position, Color(0.9, 0.85, 0.7))
				tgt.root = maxi(tgt.root, 2)
				Fx.number(main, tgt.position + Vector3(0, 0.5, 0), "⛓ Entravé", Color(0.8, 0.9, 1.0))
		"fumigene":
			await Fx.bolt(main, u.position, board.world(t), Color(0.85, 0.85, 0.85))
			for c in [t, t + Vector2i(1, 0), t + Vector2i(-1, 0), t + Vector2i(0, 1), t + Vector2i(0, -1)]:
				if board._in(c) and board.kind[c] != "tower":
					_smoke(c, 2)
		"bombe":
			await Fx.bolt(main, u.position, board.world(t), EMBER)
			_explode(t, 8 if u.side == "hero" else 6, true)
		"tonnelet":
			board.props[t] = "baril"
			_make_prop(t)
		"picots":
			for c in [t, t + Vector2i(1, 0), t + Vector2i(-1, 0), t + Vector2i(0, 1), t + Vector2i(0, -1)]:
				if board.walkable(c) and unit_at(c) == null and not traps.has(c):
					var node := Node3D.new()
					var mi := MeshInstance3D.new()
					mi.mesh = Board.mesh_of("prop_picots").mesh
					mi.material_override = Board.material("prop")
					node.add_child(mi)
					node.position = board.world(c)
					node.rotation.y = randf() * TAU
					units_root.add_child(node)
					traps[c] = node
					trap_kind[c] = "picots"
		"grappin":
			await Fx.bolt(main, u.position + Vector3(0, 0.8, 0), board.world(t) + Vector3(0, 0.3, 0), Color(0.85, 0.85, 0.8))
			await u.teleport(t, board)
			if loot.has(u.cell):
				_pick_loot(u, u.cell)
			await _landed(u)
			_check_portal(u)
		"gland":
			_plant(t)
	await wait(0.2)


func _craft(n: int, h: Unit = null) -> void:
	## Bricolage : un objet tiré selon la Bricole accumulée, qui se vide.
	for k in n:
		if besace.size() >= besace_cap():
			main.ui.toast("Besace pleine.")
			break
		var top := 1 + mini(bricole, 2)
		var rar: int = top if rng.randf() < 0.6 else rng.randi_range(1, top)
		var ids: Array = Data.TOOLS.keys().filter(func(id): return Data.TOOLS[id].rar == rar)
		var id: String = ids[rng.randi_range(0, ids.size() - 1)]
		besace.append(id)
		bricole = 0
		var at: Vector3 = h.position if h else main.target
		Fx.number(main, at + Vector3(0, 1.0 + k * 0.35, 0), "+ " + Data.TOOLS[id].name, GOLD_FX)
	changed.emit()


func _add_bricole(h: Unit, n: int) -> void:
	bricole = mini(3, bricole + n)
	Fx.number(main, h.position + Vector3(0, 1.1, 0), "Bricole %d / 3" % bricole, Data.CLASS_COLOR.receleur.lightened(0.3))


func _steal(h: Unit, f: Unit) -> bool:
	## Voler rapporte toujours : l'objet porté, sinon ce qui traîne dans ses poches ; besace pleine, on revend.
	if f.tool == "":
		var common: Array = Data.TOOLS.keys().filter(func(k): return Data.TOOLS[k].rar == 1)
		f.tool = common[randi() % common.size()]
		Fx.number(main, f.position + Vector3(0, 1.5, 0), "Poches fouillées", GOLD_FX)
	if besace.size() >= besace_cap():
		main.gold += 12
		main.ui.set_gold(main.gold)
		Fx.number(main, f.position + Vector3(0, 1.2, 0), "Revendu : +12 or", GOLD_FX, true)
		f.tool = ""
		stolen_turn += 1
		changed.emit()
		return true
	besace.append(f.tool)
	stolen_turn += 1
	Fx.number(main, f.position + Vector3(0, 1.2, 0), "Volé : " + Data.TOOLS[f.tool].name, GOLD_FX, true)
	f.tool = ""
	changed.emit()
	return true


func _drop(u: Unit) -> void:
	## L'ennemi qui portait un objet le lâche en tombant : un héros qui passe dessus le ramasse.
	if u.tool == "":
		return
	var c := u.cell if board.walkable(u.cell) else _nearest_free(u.cell)
	if loot.has(c):
		return
	var node := Node3D.new()
	var md := Board.mesh_of("prop_sac")
	for part in ["mesh", "glow"]:
		if md[part] == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = md[part]
		mi.material_override = Board.material("glow" if part == "glow" else "prop")
		node.add_child(mi)
	var l3 := Label3D.new()
	l3.text = Data.TOOLS[u.tool].glyph
	l3.font = Fx.title_font()
	l3.font_size = 72
	l3.pixel_size = 0.0045
	l3.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l3.no_depth_test = true
	l3.modulate = Color(1.0, 0.85, 0.4)
	l3.outline_size = 16
	l3.outline_modulate = Color(0.05, 0.03, 0.02, 0.85)
	l3.position.y = 1.0
	node.add_child(l3)
	var tw := l3.create_tween().set_loops()
	tw.tween_property(l3, "position:y", 1.2, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(l3, "position:y", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	node.position = board.world(c)
	units_root.add_child(node)
	loot[c] = [u.tool, node]
	u.tool = ""


func _pick_loot(h: Unit, c: Vector2i) -> void:
	var e: Array = loot[c]
	if besace.size() >= besace_cap():
		main.ui.toast("Besace pleine : %s reste au sol." % Data.TOOLS[e[0]].name)
		return
	loot.erase(c)
	e[1].queue_free()
	besace.append(e[0])
	Fx.number(main, h.position + Vector3(0, 1.1, 0), "+ " + Data.TOOLS[e[0]].name, GOLD_FX)
	changed.emit()


func _foe_tool(f: Unit) -> void:
	## Un ennemi se sert parfois de ce qu'il porte ; l'objet est alors perdu.
	var id := f.tool
	var t = null
	match id:
		"fiole":
			if f.hp * 2 < f.max_hp:
				t = f.cell
		"sels":
			if f.hp * 10 < f.max_hp * 6 or f.poison > 0 or f.root > 0:
				t = f.cell
		"fumigene":
			if f.hp * 2 < f.max_hp and rng.randf() < 0.6:
				t = f.cell
		"filet":
			for h in alive_heroes():
				if dist(f.cell, h.cell) <= 4 and rng.randf() < 0.4:
					t = h.cell
					break
		"bombe":
			var best := 0
			for h in alive_heroes():
				var dd := dist(f.cell, h.cell)
				if dd < 2 or dd > 4:
					continue
				var sc := 0
				for c in [h.cell, h.cell + Vector2i(1, 0), h.cell + Vector2i(-1, 0), h.cell + Vector2i(0, 1), h.cell + Vector2i(0, -1)]:
					var o := unit_at(c)
					if o:
						sc += 1 if o.side == "hero" else -2
				if sc > best:
					best = sc
					t = h.cell
			if best < 2 and rng.randf() < 0.6:
				t = null
	if t == null:
		return
	f.tool = ""
	Fx.number(main, f.position + Vector3(0, 1.4, 0), Data.TOOLS[id].name + " !", Color(1.0, 0.75, 0.4), true)
	await _apply_tool(id, f, t)


func _explode(c: Vector2i, dmg: int, cross := false) -> void:
	## Explosion : dégâts autour, barils en chaîne, chênes qui flambent, bombes portées qui sautent.
	if over:
		return
	Fx.burst(main, board.world(c) + Vector3(0, 0.6, 0), EMBER, 80, 5.0)
	Fx.number(main, board.world(c), "Boum", EMBER, true)
	main.shake(0.5)
	var cells: Array = [c]
	for d in (Board.DIRS if cross else RING8):
		cells.append(c + d)
	for t in cells:
		var o := unit_at(t)
		if o:
			_blast = true
			damage(o, dmg)
			_blast = false
	for t in cells:
		if oaks.has(t):
			_burn(t)
		elif board.props.get(t, "") in BOOM:
			trigger_prop(t, Vector2i.ZERO)
	changed.emit()


func _plant(c: Vector2i) -> void:
	board.blocked[c] = "oak"
	var ess: String = board.biome.get("tree", "green")
	if ess in ["", "pine"]:
		ess = "green"
	var node := Node3D.new()
	var md := Board.mesh_of("tree_%s_small" % ess)
	for part in ["mesh", "glow"]:
		if md[part] == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = md[part]
		mi.material_override = Board.material_for("tree", part == "glow")
		node.add_child(mi)
	node.position = board.world(c)
	node.scale = Vector3.ONE * 0.1
	node.create_tween().tween_property(node, "scale", Vector3.ONE * 0.95, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	units_root.add_child(node)
	oaks[c] = node
	Fx.burst(main, board.world(c) + Vector3(0, 0.4, 0), Color(0.5, 0.9, 0.4), 30, 2.5, 5.0)


func _burn(c: Vector2i) -> void:
	var node: Node3D = oaks[c]
	oaks.erase(c)
	board.blocked.erase(c)
	Fx.burst(main, board.world(c) + Vector3(0, 0.8, 0), EMBER, 70, 4.0)
	Fx.number(main, board.world(c) + Vector3(0, 1.0, 0), "Le chêne flambe", EMBER, true)
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector3(1.2, 0.05, 1.2), 0.4)
	tw.tween_callback(node.queue_free)
	for d in RING8:
		var o := unit_at(c + d)
		if o:
			_blast = true
			damage(o, 6)
			_blast = false


func _smoke(c: Vector2i, turns: int) -> void:
	smoke[c] = maxi(smoke.get(c, 0), turns)
	if smoke_nodes.has(c):
		return
	smoke_nodes[c] = Fx.smoke_cloud(units_root, board.world(c) + Vector3(0, 0.35, 0))


func _smoke_tick() -> void:
	for c in smoke.keys():
		smoke[c] -= 1
		if smoke[c] <= 0:
			smoke.erase(c)
			var n: Node3D = smoke_nodes[c]
			smoke_nodes.erase(c)
			var tw := n.create_tween()
			tw.tween_property(n, "scale", Vector3.ONE * 0.05, 0.4)
			tw.tween_callback(n.queue_free)


# ------------------------------------------------------------------ runes au sol (Dofus Arena)

func _place_tiles() -> void:
	for n in tile_nodes:
		n.queue_free()
	tile_nodes.clear()
	tiles.clear()
	twins.clear()
	var free: Array = board.walkable_cells().filter(func(c): return unit_at(c) == null and _hero_dist(c) >= 2)
	for i in range(free.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = free[i]
		free[i] = free[j]
		free[j] = tmp
	var kinds: Array = Data.TILES.keys()
	glyph_t.clear()
	glyph_lbl.clear()
	var want := 4 + board.dim / 8
	for c: Vector2i in free:
		if want <= 0:
			break
		if tiles.keys().any(func(o): return dist(o, c) < 3):
			continue
		var k: String = kinds[rng.randi_range(0, kinds.size() - 1)]
		if k == "portail":
			if twins.size() > 0:
				continue
			var twin = null
			for o: Vector2i in free:
				if dist(o, c) >= 6 and not tiles.keys().any(func(q): return dist(q, o) < 3):
					twin = o
					break
			if twin == null:
				continue
			tiles[twin] = k
			twins[c] = twin
			twins[twin] = c
			_make_tile(twin, k)
		tiles[c] = k
		_make_tile(c, k)
		want -= 1


static var _rune_tex: GradientTexture2D
func _make_tile(c: Vector2i, k: String) -> void:
	var td: Dictionary = Data.TILES[k]
	var col: Color = td.col
	if _rune_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.6, 0.68, 0.8, 0.86, 1.0])
		g.colors = PackedColorArray([Color(0.55, 0.55, 0.55, 0.6), Color(0.7, 0.7, 0.7, 0.7), Color(1, 1, 1, 1.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)])
		_rune_tex = GradientTexture2D.new()
		_rune_tex.gradient = g
		_rune_tex.fill = GradientTexture2D.FILL_RADIAL
		_rune_tex.fill_from = Vector2(0.5, 0.5)
		_rune_tex.fill_to = Vector2(1.0, 0.5)
		_rune_tex.width = 128
		_rune_tex.height = 128
	var node := Node3D.new()
	node.position = board.world(c) + Vector3(0, 0.03, 0)
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.96, 0.96)
	q.orientation = PlaneMesh.FACE_Y
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = _rune_tex
	m.albedo_color = col
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mi)
	var l3 := Label3D.new()
	l3.text = td.glyph
	l3.font = Fx.title_font()
	l3.font_size = 96
	l3.pixel_size = 0.0058
	l3.modulate = col.lightened(0.55)
	l3.outline_size = 20
	l3.outline_modulate = Color(0.05, 0.03, 0.02, 0.9)
	l3.rotation.x = -PI * 0.5
	l3.position.y = 0.02
	node.add_child(l3)
	# un peu de volume pour les terrains : buisson, murets, braises, compte à rebours
	var deco: String = {"fourre": "bush_green_0", "fort": "rubble", "autel": "crystal_0"}.get(k, "")
	if deco != "":
		var md := Board.mesh_of(deco)
		for part in ["mesh", "glow"]:
			if md[part] == null:
				continue
			var dm := MeshInstance3D.new()
			dm.mesh = md[part]
			dm.material_override = Board.material_for(deco, part == "glow")
			dm.scale = Vector3.ONE * (0.8 if k == "fourre" else 0.6)
			node.add_child(dm)
	if k == "glyphe":
		glyph_t[c] = 3
		var cd := Label3D.new()
		cd.text = "3"
		cd.font = Fx.title_font()
		cd.font_size = 110
		cd.pixel_size = 0.006
		cd.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		cd.no_depth_test = true
		cd.render_priority = 10
		cd.modulate = col.lightened(0.4)
		cd.outline_size = 18
		cd.outline_modulate = Color(0.05, 0.02, 0.08, 0.9)
		cd.position.y = 1.1
		node.add_child(cd)
		glyph_lbl[c] = cd
	var tw := l3.create_tween().set_loops()
	tw.tween_property(l3, "modulate:a", 0.45, 1.1).set_trans(Tween.TRANS_SINE)
	tw.tween_property(l3, "modulate:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE)
	var gl := OmniLight3D.new()
	gl.light_color = col
	gl.light_energy = 0.9
	gl.omni_range = 1.6
	gl.position.y = 0.4
	node.add_child(gl)
	if k == "lave":
		gl.light_energy = 2.2  # la faille rougeoie
		gl.omni_range = 2.2
	units_root.add_child(node)
	tile_nodes.append(node)


func _glyphs() -> void:
	## Les glyphes instables comptent à rebours et explosent en croix.
	for c in glyph_t.keys():
		glyph_t[c] -= 1
		if glyph_t[c] <= 0:
			glyph_t[c] = 3
			Fx.number(main, board.world(c) + Vector3(0, 1.0, 0), "Glyphe !", Data.TILES.glyphe.col, true)
			Fx.burst(main, board.world(c) + Vector3(0, 0.5, 0), Data.TILES.glyphe.col, 60, 4.0)
			main.shake(0.35)
			for d in [Vector2i.ZERO] + Board.DIRS:
				var u := unit_at(c + d)
				if u:
					damage(u, 6)
			await wait(0.3)
		if glyph_lbl.has(c) and is_instance_valid(glyph_lbl[c]):
			glyph_lbl[c].text = str(glyph_t[c])
	if over:
		return


func _tile_turn(u: Unit) -> void:
	## Début du tour de l'unité : ce que lui donne sa rune.
	if not u.alive:
		return
	match tiles.get(u.cell, ""):
		"fort":
			if u.hp < u.max_hp:
				heal(u, 3)
			gain_block(u, 3)
		"lave":
			Fx.number(main, u.position + Vector3(0, 0.5, 0), "Braise", Color(1.0, 0.5, 0.2))
			damage(u, 5)
		"source":
			if u.hp < u.max_hp:
				heal(u, 4)
		"garde":
			gain_block(u, 5)
		"elan":
			if u.side == "hero":
				energy += 1
				Fx.number(main, u.position + Vector3(0, 0.7, 0), "+1 énergie", GOLD_FX)


func _landed(u: Unit) -> void:
	## Fin d'un déplacement : ronces, portail jumeau.
	if not u.alive:
		return
	var k: String = tiles.get(u.cell, "")
	if k == "ronces":
		Fx.number(main, u.position + Vector3(0, 0.5, 0), "Ronces", Color(0.85, 0.6, 0.35))
		damage(u, 4)
	elif k == "lave":
		Fx.number(main, u.position + Vector3(0, 0.5, 0), "Braise", Color(1.0, 0.5, 0.2))
		Fx.burst(main, u.position + Vector3(0, 0.3, 0), EMBER, 30, 2.5)
		damage(u, 5)
	elif k == "portail" and twins.has(u.cell) and unit_at(twins[u.cell]) == null:
		var to: Vector2i = twins[u.cell]
		Fx.burst(main, u.position + Vector3(0, 0.6, 0), Data.TILES.portail.col, 30, 2.5)
		await u.teleport(to, board)
		Fx.burst(main, u.position + Vector3(0, 0.6, 0), Data.TILES.portail.col, 30, 2.5)
		if u.side == "hero" and loot.has(u.cell):
			_pick_loot(u, u.cell)


# ------------------------------------------------------------------ multiclasse : cartes de guilde

func _is_back(att: Unit, tgt: Unit) -> bool:
	## Le coup vient-il de dos ? (même règle que calc)
	if att.ambush or tgt.exposed or (smoke.has(tgt.cell) and dist(att.cell, tgt.cell) == 1):
		return true
	var to_att := att.cell - tgt.cell
	var dot := tgt.facing.x * signi(to_att.x) + tgt.facing.y * signi(to_att.y)
	return dot < 0 and not tgt.has_p("vigilance")


func _on_hit(h: Unit, f: Unit, back: bool) -> void:
	## Après chaque coup d'un héros : pouvoirs de guilde qui comptent les coups.
	if h.side != "hero":
		return
	h.hits += 1
	if h.bph > 0:
		gain_block(h, h.bph)
	if h.inner > 0 and dist(h.cell, f.cell) == 1:
		var nx: Unit = null
		for o in alive_foes():
			if o != f and (nx == null or dist(o.cell, h.cell) < dist(nx.cell, h.cell)):
				nx = o
		if nx:
			Fx.burst(main, nx.position + Vector3(0, 0.8, 0), EMBER, 18, 2.5)
			damage(nx, h.inner)
	var own := func(p: String) -> bool: return powers.has(p) and power_owner.get(p) == h
	if powers.has("suien") and power_owner.get("suien") == h:
		for a in alive_heroes():
			if a.hp < a.max_hp:
				a.hp = mini(a.max_hp, a.hp + int(power_val.get("suien", 1)))
		suien_hits += 1
		if suien_hits == 10:
			for a in heroes:
				if not a.alive:
					_revive(a, 0.3)
					break
	if back and own.call("cador"):
		if not (f.alive and _steal(h, f)):
			_craft(1, h)
	if powers.has("tetsu") and f.root > 0:
		h.moved = false
	if h.hits == 3:
		if own.call("korin") and f.alive and h.block > 0:
			Fx.number(main, f.position + Vector3(0, 1.0, 0), "Kōrin", Data.CLASS_COLOR.garde.lightened(0.4))
			damage(f, h.block, h)
		if own.call("hazan"):
			_boom_foes(f.cell, int(power_val.get("hazan", 7)))
		if own.call("linfei"):
			if not (f.alive and _steal(h, f)):
				_craft(1, h)


func _boom_foes(c: Vector2i, dmg: int) -> void:
	## Explosion qui épargne les héros : la cible et les ennemis autour.
	Fx.burst(main, board.world(c) + Vector3(0, 0.6, 0), EMBER, 60, 4.5)
	Fx.number(main, board.world(c) + Vector3(0, 0.4, 0), "Boum", EMBER, true)
	main.shake(0.4)
	for d in [Vector2i.ZERO] + RING8:
		var o := unit_at(c + d)
		if o and o.side == "foe":
			_blast = true
			damage(o, dmg)
			_blast = false


func _behind_cell(f: Unit) -> Vector2i:
	## Case dans le dos de l'unité, sinon une case libre à côté (-99 si rien).
	var back: Vector2i = f.cell - f.facing
	if board._in(back) and board.walkable(back) and unit_at(back) == null:
		return back
	for d in RING8:
		var n: Vector2i = f.cell + d
		if Board.DIRS.has(d) and board._in(n) and board.walkable(n) and unit_at(n) == null:
			return n
	return Vector2i(-99, -99)


func _go_behind(u: Unit, f: Unit) -> void:
	var b := _behind_cell(f)
	if b.x < -50 or b == u.cell:
		return
	Fx.burst(main, u.position + Vector3(0, 0.6, 0), Color(0.5, 0.2, 0.25), 24, 2.0)
	await u.teleport(b, board)
	u.tele = true
	u.face(f.cell - u.cell)
	if loot.has(u.cell):
		_pick_loot(u, u.cell)


func _revive(a: Unit, frac: float) -> void:
	var c := a.cell if board.walkable(a.cell) and unit_at(a.cell) == null else _nearest_free(a.cell)
	a.revive()
	a.hp = maxi(1, int(a.max_hp * frac))
	a.place(c, board)
	Fx.burst(main, a.position + Vector3(0, 0.6, 0), Color(1.0, 0.95, 0.7), 60, 3.0, 7.0)
	Fx.number(main, a.position + Vector3(0, 1.0, 0), "Relevé !", GOLD_FX, true)


func _delay(f: Unit, n: int) -> void:
	## Recule dans l'initiative : maintenant s'il n'a pas encore joué ce round, sinon au prochain.
	var i := order.find(f)
	if i > qi:
		order.remove_at(i)
		order.insert(mini(i + n, order.size()), f)
	else:
		f.set_meta("delay", n)
	Fx.number(main, f.position + Vector3(0, 0.9, 0), "Recule de %d" % n, Color(0.7, 0.85, 1.0))


func _consume(h: Unit) -> String:
	## Détruit le premier objet de la besace ; "" si elle est vide.
	if besace.is_empty():
		main.ui.toast("La besace est vide.")
		return ""
	var id: String = besace.pop_front()
	Fx.number(main, h.position + Vector3(0, 1.0, 0), "Détruit : " + Data.TOOLS[id].name, GOLD_FX)
	changed.emit()
	return id


func _craft_id(id: String, n: int, h: Unit) -> void:
	for k in n:
		if besace.size() >= besace_cap():
			main.ui.toast("Besace pleine.")
			break
		besace.append(id)
		Fx.number(main, h.position + Vector3(0, 1.0 + k * 0.35, 0), "+ " + Data.TOOLS[id].name, GOLD_FX)
	changed.emit()


func _lure(t: Vector2i, n: int) -> void:
	## Les ennemis à 4 cases avancent vers la case ; un piège sur la route les prend.
	var near: Array = alive_foes().filter(func(f): return dist(f.cell, t) <= 4 and f.cell != t)
	near.sort_custom(func(a, b): return dist(a.cell, t) < dist(b.cell, t))
	for f in near:
		for i in n:
			if not f.alive or f.cell == t or f.root > 0:
				break
			var nx: Vector2i = f.cell + _dir(f.cell, t)
			if not board.walkable(nx) or unit_at(nx) or board.props.has(nx) or absi(board.h[nx] - board.h[f.cell]) > f.jump:
				break
			f.cell = nx
			await _slide(f, board.world(nx))
			if traps.has(nx):
				await _spring(f)
				break


func _kaede(h: Unit) -> void:
	var nx: Unit = null
	for o in alive_foes():
		if nx == null or dist(o.cell, h.cell) < dist(nx.cell, h.cell):
			nx = o
	if nx == null:
		return
	await _go_behind(h, nx)
	h.ambush = true
	await h.lunge(nx.position)
	Fx.number(main, h.position + Vector3(0, 1.0, 0), "Kaede", Data.CLASS_COLOR.lame.lightened(0.4))
	damage(nx, calc(h, nx, int(power_val.get("kaede", 5))).dmg, h)
	_on_hit(h, nx, true)
	h.ambush = false


func _enclume(src: Unit, hit: Unit) -> void:
	## Serment de l'Enclume : l'allié le plus proche prend l'ennemi à revers.
	if not src.alive or over:
		return
	var ally: Unit = null
	for a in alive_heroes():
		if a != hit and (ally == null or dist(a.cell, src.cell) < dist(ally.cell, src.cell)):
			ally = a
	if ally == null:
		return
	await _go_behind(ally, src)
	ally.ambush = true
	await ally.lunge(src.position)
	Fx.number(main, ally.position + Vector3(0, 1.0, 0), "Enclume", Data.CLASS_COLOR.garde.lightened(0.4))
	damage(src, calc(ally, src, int(power_val.get("enclume", 6))).dmg, ally)
	ally.ambush = false


func _discover(h: Unit, ids: Array, title: String, sub: String, free := true) -> void:
	## Découvre : trois cartes au choix, la choisie arrive en main (coût 0, ou 1 de moins).
	ids = ids.duplicate()
	ids.shuffle()
	var picks: Array = ids.slice(0, 3)
	if picks.is_empty() or hand.size() >= 10:
		return
	var opts: Array = picks.map(func(id): return {"card": {"id": id, "lvl": 1, "h": h.key}})
	for o in opts:
		main.library_see(o.card.id)
	var j: int = await main.ui.choose(title, sub, opts, true)
	if j < 0:
		return
	var ci: Dictionary = {"id": picks[j], "lvl": 1, "h": h.key}
	ci["free" if free else "cut"] = true if free else 1
	hand.append(ci)
	changed.emit()


func _self_fx(c: Dictionary, h: Unit) -> void:
	## Effets des compétences de guilde sur soi.
	if c.get("revive", false):
		for a in heroes:
			if not a.alive:
				_revive(a, 0.25)
	if c.get("aegis_all", false):
		for a in alive_heroes():
			a.aegis = true
			Fx.number(main, a.position + Vector3(0, 0.9, 0), "Égide", Color(1.0, 0.95, 0.7))
	if c.has("rune") and not tiles.has(h.cell):
		tiles[h.cell] = c.rune
		_make_tile(h.cell, c.rune)
	if c.get("bait", false):
		h.bait = true
	if c.get("parry", false):
		h.parry = true
		Fx.number(main, h.position + Vector3(0, 0.8, 0), "En garde", GOLD_FX)
	if c.get("iframe", false):
		h.dodge_next = true
		Fx.number(main, h.position + Vector3(0, 0.8, 0), "Iframe", Color(0.8, 0.95, 1.0))
	if c.get("boom", 0) > 0:
		h.boomguard = int(c.boom)
	if c.get("bph", 0) > 0:
		h.bph = int(c.bph)
	if c.get("inner", 0) > 0:
		h.inner = int(c.inner)
	if c.get("lvl_next", false):
		h.lvl_next = true
	if c.get("fuse", 0) > 0:
		h.fuse = int(c.fuse)
	if c.get("justframe", false):
		if played == 0:
			h.triple = true
			Fx.number(main, h.position + Vector3(0, 1.0, 0), "Just frame !", GOLD_FX, true)
		else:
			draw(1)
	if c.get("item_poison", 0) > 0:
		item_poison = maxi(item_poison, int(c.item_poison))
	if c.get("fiole2", false):
		fiole2 = true
	if c.get("trophy", false):
		trophy = true
	if c.get("traps_around", 0) > 0:
		var n := int(c.traps_around)
		for d in Board.DIRS + RING8:
			var sp: Vector2i = h.cell + d
			if n > 0 and board.walkable(sp) and unit_at(sp) == null and not traps.has(sp) and not board.props.has(sp):
				_make_trap(sp, "piege", 8)
				n -= 1
	if c.get("consume", false):
		if _consume(h) != "":
			if c.get("c_block", 0) > 0:
				gain_block(h, c.c_block)
			if c.get("c_energy", 0) > 0:
				energy += c.c_energy
				Fx.number(main, h.position + Vector3(0, 0.6, 0), "+%d énergie" % c.c_energy, GOLD_FX)
	if c.get("craft_id", "") != "":
		_craft_id(c.craft_id, int(c.get("craft_n", 1)), h)
	if c.get("iblock", 0) > 0 and besace.size() > 0:
		gain_block(h, int(c.iblock) * besace.size())
	if c.get("idraw", 0) > 0:
		draw(mini(int(c.idraw), besace.size()))
	if c.get("filiere", false):
		var n := mini(2, stolen_turn)
		if n > 0:
			draw(n)
			energy += n
	if c.get("bricole", 0) > 0:
		_add_bricole(h, c.bricole)
	if c.get("rpoison", 0) > 0:
		var live := alive_foes()
		if live.size() > 0:
			var v: Unit = live[randi() % live.size()]
			v.poison += int(c.rpoison)
			Fx.number(main, v.position + Vector3(0, 0.4, 0), "☠ +%d" % c.rpoison, Color(0.6, 0.9, 0.3))
	if c.get("mark_near", 0) > 0:
		var nx: Unit = null
		for o in alive_foes():
			if nx == null or dist(o.cell, h.cell) < dist(nx.cell, h.cell):
				nx = o
		if nx:
			nx.mark = maxi(nx.mark, int(c.mark_near))
			Fx.number(main, nx.position + Vector3(0, 0.5, 0), "◎ Marqué", Color(1.0, 0.85, 0.4))
	if c.get("mark_all", 0) > 0:
		for o in alive_foes():
			o.mark = maxi(o.mark, int(c.mark_all))
			Fx.number(main, o.position + Vector3(0, 0.5, 0), "◎", Color(1.0, 0.85, 0.4))
	if c.get("heal_ally", 0) > 0:
		var w: Unit = null
		for a in alive_heroes():
			if a != h and a.hp < a.max_hp and (w == null or a.hp * w.max_hp < w.hp * a.max_hp):
				w = a
		if w:
			heal(w, int(c.heal_ally))
	if c.get("barrels_behind", false):
		var n := 0
		for f in alive_foes():
			var b: Vector2i = f.cell - f.facing
			if board._in(b) and board.walkable(b) and unit_at(b) == null and not board.props.has(b) and not traps.has(b):
				board.props[b] = "baril"
				_make_prop(b)
				n += 1
		draw(n)
	if c.get("hitcount", false):
		h.hits += 1
		_count_hit(h)
	if c.get("recall", 0) > 0:
		discard.shuffle()
		for k in int(c.recall):
			if discard.is_empty() or hand.size() >= 10:
				break
			var ci: Dictionary = discard.pop_back()
			ci["cut"] = 1
			hand.append(ci)
	if c.get("copy_hand", false) and hand.size() > 0:
		var j: int = await main.ui.choose("FAUX INVENTAIRE", "Quelle carte copier ? La copie est Éphémère.", hand.map(func(ci): return {"card": ci}), true)
		if j >= 0 and hand.size() < 10:
			var cp: Dictionary = hand[j].duplicate()
			cp["eph"] = true
			hand.append(cp)
	if c.get("discover", "") == "guild":
		var pool: Array = Data.CARDS.keys().filter(func(id): return c.cls.has(Data.CARDS[id].owner) and not Data.STARTER[Data.CARDS[id].owner].has(id))
		await _discover(h, pool, "DÉCOUVRE", "Une carte de %s ; elle coûte 0 ce tour" % " ou ".join(c.cls.map(func(k): return Data.HEROES[k].name)))
	if c.get("heist", 0) > 0:
		var absent: Array = Data.HEROES.keys().filter(func(k): return not heroes.any(func(u): return u.key == k))
		for n in int(c.heist):
			var pool: Array = Data.CARDS.keys().filter(func(id): return absent.has(Data.CARDS[id].owner))
			await _discover(h, pool, "BRAQUAGE", "Trois cartes d'un paquet qui n'est pas le tien (%d / %d)" % [n + 1, c.heist], c.get("heist_free", false))
	if c.get("oeuvre", false):
		var idx: Array = range(deck.size()).filter(func(q): return Data.level(deck[q]) < Data.MAX_LVL)
		if idx.size() > 0:
			var j: int = await main.ui.choose("L'ŒUVRE", "Quelle carte passe au niveau 3 pour toute la run ?", idx.map(func(q): return {"card": deck[q]}), true)
			if j >= 0:
				deck[idx[j]]["lvl"] = Data.MAX_LVL
				main.ui.banner("L'Œuvre", "%s passe au niveau 3" % Data.def(deck[idx[j]].id).name)
