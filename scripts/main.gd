extends Node3D
## Monde (lumière, caméra), boucle de run, entrées, mode capture pour le critique.

const ROOMS_PER_FLOOR := 5
const CENTER := Vector3(7.5, 1.2, 7.5)

var ui: UI
var battle: Battle
var board: Board
var units_root: Node3D
var ambient_root: Node3D
var cam: Camera3D
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var env: Environment
var cam_attr: CameraAttributesPractical

var yaw := 45.0
var pitch := 38.0
var dist := 24.0
var target := CENTER
var _yaw := 45.0
var _pitch := 38.0
var _dist := 24.0
var _target := CENTER
var _focus = null
var _shake := 0.0
var _punch := 1.0
var hover = null
var quality := 1
var orbit := false
var pad := false            # la manette a la main : le curseur ne suit plus la souris
var _pad_rep := 0.0
var _rmb_drag := 0.0

var heroes: Array = []
var deck: Array = []
var relics: Array = []
var floor_i := 1
var step := 0
var run_seed := 0
var fights := 0
var gold := 0
var bag: Array = []
var besace: Array = []     # objets à usage unique de l'escouade
var besace_max := 3
var run_start := 0
var next_arch := ""
var next_obj := "kill"
var floor_biomes: Array = []
var party: Array = ["garde", "lame", "oracle"]
var leader: Unit            # pion du mode aventure
var mode := "descente"      # "descente" (carte d'étage) | "aventure" (exploration)
var aboard: Board           # le donjon du mode aventure, gardé à part de l'arène
var adv_root: Node3D
var rooms: Array = []       # salles du donjon : {rect, type, cell, ids, arch, mods, done, seen, node, fog}
var exploring := false
var _adv_busy := false
var _adv_hover = null
var _fog_mat: StandardMaterial3D
var followers: Array = []
var trail: Array = []       # dernières cases du chef, que les compagnons reprennent
signal floor_done(result: String)
static var difficulty := 1   # index dans Data.DIFFICULTY ; retenu d'une run à l'autre
var pacts: Array = []
var next_mods: Array = []
var fmap: Array = []        # carte de l'étage : étapes -> nœuds {type, arch, obj, links, desc}
var lane := -1
var visited: Array = []
var args := {}
static var _globals_ready := false
var rng := RandomNumberGenerator.new()
var _music: Array = []      # deux lecteurs pour le fondu enchaîné
var _music_kind := ""
var _mute := false


func _ready() -> void:
	if not _globals_ready:  # déjà déclarés si la scène est rechargée après un abandon
		_globals_ready = true
		RenderingServer.global_shader_parameter_add("cut_dir", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2(0.7, 0.7))
		RenderingServer.global_shader_parameter_add("cut_center", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2(7.5, 7.5))
		RenderingServer.global_shader_parameter_add("cut_half", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 8.0)
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if args.has("party"):
		party = Array(args.party.split(","))
	if args.has("difficulty"):
		difficulty = clampi(int(args.difficulty) - 1, 0, 4)
	_setup_world()
	board = Board.new()
	add_child(board)
	units_root = Node3D.new()
	add_child(units_root)
	ambient_root = Node3D.new()
	add_child(ambient_root)
	battle = Battle.new()
	battle.main = self
	battle.board = board
	battle.units_root = units_root
	add_child(battle)
	ui = UI.new()
	ui.main = self
	ui.battle = battle
	add_child(ui)
	battle.changed.connect(ui.refresh)
	if args.has("quality"):
		quality = int(args.quality)
	_apply_quality()
	if args.has("autoplay"):
		_autoplay.call_deferred()
	elif args.has("uitest"):
		_uitest.call_deferred()
	elif args.has("advtest"):
		_advtest.call_deferred()
	elif args.has("capture"):
		_capture.call_deferred()
	else:
		_title.call_deferred()


# ------------------------------------------------------------------ monde

func _setup_world() -> void:
	for i in 2:
		var mp := AudioStreamPlayer.new()
		mp.volume_db = -80.0
		add_child(mp)
		_music.append(mp)
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.ssao_radius = 0.8
	env.ssao_intensity = 2.4
	env.ssao_power = 1.6
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 26.0
	env.fog_depth_end = 80.0
	env.fog_height = 0.7
	env.fog_height_density = 0.35
	env.fog_sun_scatter = 0.3
	env.fog_aerial_perspective = 0.35
	env.fog_sky_affect = 0.25
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	env.adjustment_contrast = 1.05
	var we := WorldEnvironment.new()
	we.environment = env
	cam_attr = CameraAttributesPractical.new()
	cam_attr.dof_blur_amount = 0.05
	we.camera_attributes = cam_attr
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 60.0
	sun.shadow_blur = 1.3
	sun.shadow_bias = 0.04
	add_child(sun)
	moon = DirectionalLight3D.new()
	moon.shadow_enabled = false
	moon.light_specular = 0.3
	add_child(moon)
	cam = Camera3D.new()
	cam.fov = 30
	cam.far = 250
	add_child(cam)
	cam.current = true


func apply_biome(b: Dictionary) -> void:
	var sm: ProceduralSkyMaterial = env.sky.sky_material
	sm.sky_top_color = b.sky_top
	sm.sky_horizon_color = b.sky_hor
	sm.ground_horizon_color = b.sky_hor
	sm.ground_bottom_color = b.water_deep
	env.ambient_light_energy = b.ambient
	env.fog_light_color = b.fog
	env.fog_density = 0.85
	env.volumetric_fog_albedo = b.fog
	sun.light_color = b.sun
	sun.light_energy = b.sun_energy
	sun.rotation_degrees = Vector3(-b.sun_elev, b.sun_az, 0)
	moon.visible = b.has("moon")
	if b.has("moon"):
		moon.light_color = b.moon
		moon.light_energy = 0.7
		moon.rotation_degrees = Vector3(-40, b.sun_az + 180.0, 0)


func _apply_quality() -> void:
	## 0 portable, 1 normal, 2 ultra
	env.ssao_enabled = quality >= 1
	env.ssil_enabled = quality >= 2
	env.sdfgi_enabled = quality >= 2
	env.volumetric_fog_enabled = quality >= 2
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_length = 48.0
	cam_attr.dof_blur_far_enabled = quality >= 1
	cam_attr.dof_blur_near_enabled = quality >= 1
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if quality == 0 else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if quality == 0 else Viewport.MSAA_2X
	get_viewport().scaling_3d_scale = 0.8 if quality == 0 else 1.0


func focus(p) -> void:
	_focus = p


func shake(a: float) -> void:
	_shake = maxf(_shake, a)


func hitstop(t: float) -> void:
	Engine.time_scale = 0.06
	await get_tree().create_timer(t, true, false, true).timeout
	Engine.time_scale = 1.0


func punch(p: Vector3) -> void:
	## Recadre brièvement sur l'échange de coups.
	_focus = p
	_punch = 0.82
	await get_tree().create_timer(0.9).timeout
	_punch = 1.0
	if not battle.player_turn:
		return
	_focus = null


# ------------------------------------------------------------------ caméra et entrées

func _process(dt: float) -> void:
	if orbit:
		yaw += dt * 3.0
	var k := 1.0 - exp(-dt * 7.0)
	_yaw = lerpf(_yaw, yaw, k)
	_pitch = lerpf(_pitch, pitch, k)
	_dist = lerpf(_dist, dist * _punch, k)
	var goal: Vector3 = target if _focus == null else target.lerp(_focus, 0.35 if _punch == 1.0 else 0.6)
	_target = _target.lerp(goal, 1.0 - exp(-dt * 3.0))
	_place_cam()
	if _shake > 0.0:
		cam.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * _shake * 0.12
		_shake = maxf(0.0, _shake - dt * 2.2)
	_free_cam(dt)
	_pad_process(dt)
	_feed_units()
	if exploring:
		_adv_process(dt)
	if ui and ui.hud.visible and not args.has("capture") and not pad and not ui.menu_open():
		var mp := get_viewport().get_mouse_position()
		var h = board.pick(cam.project_ray_origin(mp), cam.project_ray_normal(mp))
		if h != hover:
			hover = h
			refresh_hover()


func _place_cam() -> void:
	var yr := deg_to_rad(_yaw)
	var pr := deg_to_rad(_pitch)
	cam.position = _target + Vector3(sin(yr) * cos(pr), sin(pr), cos(yr) * cos(pr)) * _dist
	cam.look_at(_target)
	# le plateau se cadre dans la zone libre : au-dessus de la main, à droite des portraits
	cam.v_offset = -0.06 * _dist if ui.hud.visible else 0.0
	cam.h_offset = -0.09 * _dist if ui.hud.visible else 0.0
	var cd := Vector2(sin(yr), cos(yr))
	RenderingServer.global_shader_parameter_set("cut_dir", cd)
	cam_attr.dof_blur_far_distance = _dist + 8.0
	cam_attr.dof_blur_far_transition = 12.0
	cam_attr.dof_blur_near_distance = maxf(1.0, _dist - 9.0)
	cam_attr.dof_blur_near_transition = 5.0


func _snap_cam() -> void:
	_yaw = yaw
	_pitch = pitch
	_dist = dist
	_target = target
	_place_cam()


func refresh_hover() -> void:
	battle.refresh_highlight(hover)
	ui.set_tip(battle.preview(hover))
	var look: Unit = battle.inspect if battle.inspect and battle.inspect.alive else null
	if look == null and hover != null:
		look = battle.unit_at(hover)
	ui.set_sheet(look)
	ui._sync_tags()


func _feed_units() -> void:
	## Donne au décor la position des unités, pour qu'il s'efface devant elles.
	var arr := PackedVector4Array()
	var list: Array = (battle.heroes + battle.foes) if ui.hud.visible else []
	for u in list:
		if is_instance_valid(u) and u.alive and arr.size() < 16:
			var p: Vector3 = u.global_position + Vector3(0, 0.75, 0)
			arr.append(Vector4(p.x, p.y, p.z, 1.0))
	if leader and is_instance_valid(leader) and leader.visible and arr.size() < 16:
		var lp := leader.global_position + Vector3(0, 0.75, 0)
		arr.append(Vector4(lp.x, lp.y, lp.z, 1.0))
	while arr.size() < 16:
		arr.append(Vector4.ZERO)
	for k in ["stone", "foliage"]:
		var m: ShaderMaterial = Board.material(k)
		m.set_shader_parameter("units", arr)
		m.set_shader_parameter("unit_n", mini(16, list.size() + (1 if leader and is_instance_valid(leader) and leader.visible else 0)))


func abandon() -> void:
	## Retour à l'écran titre : la scène repart de zéro.
	get_tree().reload_current_scene()


func _free_cam(dt: float) -> void:
	## Clic droit maintenu : ZQSD (ou WASD) déplace la caméra.
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or ui.menu_open():
		return
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		v.y -= 1
	if Input.is_physical_key_pressed(KEY_S):
		v.y += 1
	if Input.is_physical_key_pressed(KEY_A):
		v.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		v.x += 1
	if v != Vector2.ZERO:
		_pan(v.normalized() * dt * 900.0)


func _pan(rel: Vector2) -> void:
	var yr := deg_to_rad(_yaw)
	var right := Vector3(cos(yr), 0, -sin(yr))
	var fwd := Vector3(sin(yr), 0, cos(yr))
	target += (right * rel.x + fwd * rel.y) * _dist * 0.0016
	target = target.clamp(Vector3(-3, 0, -3), Vector3(board.dim + 2, 4, board.dim + 2))


func _pad_process(dt: float) -> void:
	## Manette Xbox : stick gauche / croix = curseur de case, stick droit = caméra, gâchettes = zoom.
	if Input.get_connected_joypads().is_empty() or ui.menu_open() or not ui.hud.visible or ui.overlay != null:
		return
	var r := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if r.length() > 0.2:
		yaw -= r.x * dt * 140.0
		pitch = clampf(pitch + r.y * dt * 70.0, 12.0, 82.0)
	var z := Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)
	if absf(z) > 0.2:
		dist = clampf(dist - z * dt * 30.0, 7.0, 60.0)
	var v := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if v.length() < 0.5:
		v = Vector2.ZERO
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT):
		v.x = -1
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT):
		v.x = 1
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
		v.y = -1
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
		v.y = 1
	_pad_rep -= dt
	if v == Vector2.ZERO:
		_pad_rep = 0.0
		return
	if _pad_rep > 0.0:
		return
	_pad_rep = 0.17
	pad = true
	# axes de la grille tournés avec la caméra (droite = +x, haut = -z vu de 45°)
	var yr := deg_to_rad(_yaw - 45.0)
	var w := Vector2(cos(yr), -sin(yr)) * v.x - Vector2(sin(yr), cos(yr)) * -v.y
	var st := Vector2i(int(signf(w.x)), 0) if absf(w.x) >= absf(w.y) else Vector2i(0, int(signf(w.y)))
	var cur: Vector2i = hover if hover != null else (battle.selected.cell if battle.selected else heroes[0].cell)
	var nx := Vector2i(clampi(cur.x + st.x, 0, board.dim - 1), clampi(cur.y + st.y, 0, board.dim - 1))
	hover = nx
	var wp := board.world(nx)
	target = target.lerp(Vector3(wp.x, target.y, wp.z), 0.35)
	refresh_hover()


func _pad_button(b: int) -> void:
	match b:
		JOY_BUTTON_A:
			if hover != null:
				battle.click(hover)
		JOY_BUTTON_B:
			battle.cancel()
		JOY_BUTTON_X:
			battle.end_turn()
		JOY_BUTTON_Y:
			if hover != null:
				battle.toggle_inspect(battle.unit_at(hover))
		JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
			var n := battle.hand.size()
			if n > 0:
				var s := 1 if b == JOY_BUTTON_RIGHT_SHOULDER else -1
				var i := posmod((battle.card_sel if battle.card_sel >= 0 else (-1 if s > 0 else 0)) + s, n)
				battle.select_card(i)
		JOY_BUTTON_BACK:
			var live := battle.alive_heroes()
			if live.size() > 0:
				battle.select(live[(live.find(battle.selected) + 1) % live.size()])


func _unhandled_input(e: InputEvent) -> void:
	var esc: bool = (e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE) \
		or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_START)
	if esc:
		if ui.menu_open() or not (battle.card_sel >= 0 or battle.inspect):
			ui.toggle_menu()
		else:
			battle.cancel()
		return
	if ui.menu_open() or ui.overlay != null:
		return
	if e is InputEventKey and e.keycode == KEY_ALT and not e.echo:
		refresh_hover()  # Alt montre les objets interactifs
		return
	if e is InputEventJoypadButton and e.pressed:
		pad = true
		if ui.hud.visible and ui.overlay == null:
			_pad_button(e.button_index)
		return
	if e is InputEventMouseMotion and e.relative.length() > 2.0:
		pad = false
	if e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
		_pan(-e.relative)
	elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_RIGHT):
		# caméra libre : orbite autour du point visé
		_rmb_drag += e.relative.length()
		yaw -= e.relative.x * 0.3
		pitch = clampf(pitch + e.relative.y * 0.2, 12.0, 82.0)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT:
		if e.pressed:
			_rmb_drag = 0.0
		elif _rmb_drag < 6.0:
			battle.cancel()  # un clic droit bref annule toujours
	elif e is InputEventMouseButton and e.pressed:
		match e.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				dist = clampf(dist - 1.8, 7.0, 60.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				dist = clampf(dist + 1.8, 7.0, 60.0)
			MOUSE_BUTTON_LEFT:
				if exploring and ui.overlay == null:
					if _adv_hover != null:
						_adv_click(_adv_hover)
				elif hover != null and ui.hud.visible:
					battle.click(hover)
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_Q:
				if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
					yaw -= 90.0
			KEY_E:
				if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
					yaw += 90.0
			KEY_SPACE:
				battle.end_turn()
			KEY_P:
				view_deck()
			KEY_M:
				_mute = not _mute
				(_music[1] as AudioStreamPlayer).volume_db = _music_vol()
				ui.toast("Musique coupée" if _mute else "Musique")
			KEY_TAB:
				var live := battle.alive_heroes()
				if live.size() > 0:
					var i := (live.find(battle.selected) + 1) % live.size()
					battle.select(live[i])
			KEY_G:
				quality = (quality + 1) % 3
				_apply_quality()
				ui.toast("Qualité : " + ["portable", "normale", "ultra"][quality])
			_:
				if e.keycode >= KEY_1 and e.keycode <= KEY_9:
					battle.select_card(e.keycode - KEY_1)


# ------------------------------------------------------------------ run

func _title() -> void:
	play_music("calme")
	orbit = true
	_build_room(4242, 0, 16, "ecluse")
	dist = 34.0
	pitch = 30.0
	_snap_cam()
	await ui.title_screen()
	orbit = false
	new_run()


func _make_party(keys: Array = party) -> void:
	for u in heroes:
		u.queue_free()
	heroes.clear()
	var traits := Data.TRAITS.keys()
	for i in range(traits.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = traits[i]
		traits[i] = traits[j]
		traits[j] = t
	var i := 0
	for k in keys:
		var u := Unit.new()
		u.setup(k, "hero")
		u.trait_id = traits[i]
		i += 1
		match u.trait_id:
			"vertige":
				u.base_jump -= 1
				u.base_hp += 6
			"leger":
				u.base_move += 1
			"colosse":
				u.base_hp += 8
				u.base_move -= 1
		u.base_hp = int(round(u.base_hp * Data.DIFFICULTY[difficulty].hp * (0.85 if pacts.has("sang") else 1.0)))
		u.max_hp = u.base_hp
		u.hp = u.max_hp
		u.apply_gear()
		units_root.add_child(u)
		heroes.append(u)


func new_run() -> void:
	exploring = false
	if aboard:
		aboard.visible = false
		adv_root.visible = false
	run_seed = int(args.seed) if args.has("seed") else randi()
	rng.seed = run_seed
	mode = await _pick_mode()
	difficulty = await _pick_difficulty()
	pacts = await _pick_pacts()
	party = await _draft()
	floor_i = 1
	step = 0
	fights = 0
	gold = 40
	floor_biomes = range(Data.BIOMES.size())
	for i in range(floor_biomes.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = floor_biomes[i]
		floor_biomes[i] = floor_biomes[j]
		floor_biomes[j] = t
	bag = []
	relics = []
	deck = []
	run_start = Time.get_ticks_msec()
	deck = Data.starter(party)
	besace = ["fiole"]
	besace_max = 3 + (2 if party.has("receleur") else 0)
	if party.has("receleur"):
		besace.append("picots")
	ui.refresh_relics(relics)
	ui.set_gold(gold)
	_make_party()
	if mode == "aventure":
		_adventure()
	else:
		_loop()


func _pick_difficulty() -> int:
	var opts: Array = []
	var cols := [Color("#8fd0a0"), UI.GOLD, Color("#e0a050"), Color("#e0583a"), Color("#b0305a")]
	for i in Data.DIFFICULTY.size():
		var d: Dictionary = Data.DIFFICULTY[i]
		opts.append({"title": d.name + ("  ·  dernière" if i == difficulty else ""), "glyph": "%d/5" % (i + 1), "text": d.text, "color": cols[i]})
	return await ui.choose("DIFFICULTÉ", "De 1 (Oklm) à 5 (Anathème)", opts)


func _pick_pacts() -> Array:
	## Malus choisis contre du butin : chaque pacte ajoute 25 % d'or et des cartes plus rares.
	var on: Array = []
	while true:
		var opts: Array = []
		for k in Data.PACTS:
			var act: bool = on.has(k)
			opts.append({"title": ("✓ " if act else "") + Data.PACTS[k].name, "glyph": "☠" if act else "○", "text": Data.PACTS[k].text,
				"color": Color("#e0583a") if act else Color("#8f86a8")})
		var i := await ui.choose("PACTES", "Chaque pacte : +25 % d'or et plus de cartes rares. %d actif(s)." % on.size(), opts, true,
			"Descendre avec %d pacte(s)" % on.size() if on.size() > 0 else "Aucun pacte")
		if i < 0:
			return on
		var k: String = Data.PACTS.keys()[i]
		if on.has(k):
			on.erase(k)
		else:
			on.append(k)
	return on


func _draft() -> Array:
	## Trois héros parmi six ; « au hasard » complète l'escouade.
	var out: Array = []
	while out.size() < 3:
		var left: Array = Data.HEROES.keys().filter(func(k): return not out.has(k))
		var opts: Array = []
		for k in left:
			var d: Dictionary = Data.HEROES[k]
			opts.append({"title": d.name, "image": "res://assets/art/portrait_%s.png" % k, "color": Data.CLASS_COLOR[k],
				"text": "%s\n%d PV · dépl. %d\n%s" % [d.title, d.hp, d.move, d.role]})
		var chosen: String = ", ".join(out.map(func(k): return Data.HEROES[k].name))
		var i := await ui.choose("L'ESCOUADE", "Choisissez trois héros (%d / 3)%s" % [out.size(), ("  ·  " + chosen) if chosen != "" else ""], opts, true, "Compléter au hasard")
		if i < 0:
			while out.size() < 3:
				left = Data.HEROES.keys().filter(func(k): return not out.has(k))
				out.append(left[rng.randi_range(0, left.size() - 1)])
		else:
			out.append(left[i])
	return out


func _biome() -> int:
	return floor_biomes[floor_i - 1] if floor_biomes.size() >= floor_i else floor_i - 1


func _minutes() -> int:
	return int((Time.get_ticks_msec() - run_start) / 60000.0)


func _loop() -> void:
	while true:
		var type: String = await _door()
		if type in ["combat", "elite", "boss"]:
			var won: bool = await _fight(type)
			if not won:
				await ui.game_over(false, "Étage %d, %d combats remportés, %d min, difficulté %d/5." % [floor_i, fights, _minutes(), difficulty + 1])
				new_run.call_deferred()
				return
			await _post_fight(type)
			if type == "boss":
				await ui.game_over(true, "Le Gardien est tombé : %d combats, %d min, difficulté %d/5." % [fights, _minutes(), difficulty + 1])
				new_run.call_deferred()
				return
		elif type == "sanctuaire":
			await _sanctuary()
		elif type == "marchand":
			await _merchant()
		else:
			await _relic_pick("Reliquaire", "Une relique parmi trois")
		step += 1
		if step >= ROOMS_PER_FLOOR:
			floor_i += 1
			step = 0


func _post_fight(type: String) -> void:
	fights += 1
	for h in heroes:
		if not h.alive:
			h.revive()
			h.hp = maxi(1, int(h.max_hp * Data.DIFFICULTY[difficulty].revive))
		else:
			h.hp = mini(h.max_hp, h.hp + int(h.max_hp * Data.DIFFICULTY[difficulty].heal))
		if relics.has("lotus_pale"):
			h.hp = mini(h.max_hp, h.hp + 4)
	if type != "boss":
		await _rewards(type)


func _door() -> String:
	## Carte de l'étage, tirée à la première salle : on voit où mène chaque chemin.
	if step == 0:
		await _ancient()
		_gen_map()
	var nexts: Array = range(fmap[step].size()) if lane < 0 else fmap[step - 1][lane].links
	while true:
		var i := await ui.map_screen("ÉTAGE %d" % floor_i, "%s · salle %d / %d · %d or · difficulté %d/5" % [Data.BIOMES[_biome()].name, step + 1, ROOMS_PER_FLOOR, gold, difficulty + 1],
			fmap, step, lane, nexts, visited, "Équipement · %d objet(s) au sac" % bag.size())
		if i == -2:
			await _equipment()
			continue
		if i == -3:
			await _fuse()
			continue
		if i == -4:
			await view_deck()
			continue
		lane = i
		visited.append(Vector2i(step, i))
		var n: Dictionary = fmap[step][i]
		next_arch = n.arch
		next_obj = n.obj
		next_mods = n.get("mods", [])
		return n.type
	return "combat"


func _gen_map() -> void:
	## Trois voies, reliées aux voisines ; marchand au milieu de l'étage, sanctuaire avant le gardien.
	fmap = []
	visited = []
	lane = -1
	var pool := ["combat", "combat", "combat", "elite", "sanctuaire", "reliquaire"]
	for k in ROOMS_PER_FLOOR:
		var row: Array = []
		var last := k == ROOMS_PER_FLOOR - 1
		for i in (1 if last else 3):
			var t: String = pool[rng.randi_range(0, pool.size() - 1)]
			if last:
				t = "boss" if floor_i == 3 else "elite"
			elif k == 0:
				t = "combat"
			elif k == 2 and i == 1:
				t = "marchand"
			elif k == ROOMS_PER_FLOOR - 2 and i == 1:
				t = "sanctuaire"
			var arch: String = Board.ARCHETYPES[rng.randi_range(0, 3)]
			while i > 0 and arch == row[i - 1].arch:
				arch = Board.ARCHETYPES[rng.randi_range(0, 3)]
			var obj := "portal" if t == "combat" and rng.randf() < 0.3 else "kill"
			var mods: Array = []
			if t == "elite" or (t == "combat" and k > 0 and rng.randf() < 0.3):
				mods.append(Data.MODIFIERS.keys()[rng.randi_range(0, Data.MODIFIERS.size() - 1)])
			row.append({"type": t, "arch": arch, "obj": obj, "links": [], "mods": mods})
		fmap.append(row)
	for k in ROOMS_PER_FLOOR - 1:
		for i in fmap[k].size():
			for j in fmap[k + 1].size():
				if fmap[k + 1].size() == 1 or absi(i - j) <= 1:
					fmap[k][i].links.append(j)
	for row in fmap:
		for n in row:
			var r: Dictionary = Data.ROOMS[n.type]
			n["desc"] = "%s — %s" % [r.name, r.text]
			if n.type in ["combat", "elite", "boss"]:
				n["desc"] += "\nTerrain : %s.%s" % [ARCH_NAMES[n.arch], "  Objectif : atteindre le portail." if n.obj == "portal" else ""]
			for m in n.mods:
				n["desc"] += "\n%s %s : %s  Butin +50 %%, cartes plus rares." % [Data.MODIFIERS[m].glyph, Data.MODIFIERS[m].name, Data.MODIFIERS[m].text]

const ARCH_NAMES := {"ecluse": "écluse et ponts", "terrasses": "terrasses en gradins", "cour": "cour fortifiée", "ilots": "îlots et pont-levis"}


func _build_room(seed: int, bi: int, size := 14, arch := "", with_props := false) -> void:
	var b: Dictionary = Data.BIOMES[bi]
	board.visible = true
	units_root.visible = true
	exploring = false
	env.fog_depth_begin = 26.0
	env.fog_depth_end = 80.0
	ui.show_explore(false)
	if aboard:
		aboard.visible = false
		adv_root.visible = false
	board.generate(seed, b, size, arch, with_props)
	board.build_visuals()
	apply_biome(b)
	var c3 := board.center()
	RenderingServer.global_shader_parameter_set("cut_center", Vector2(c3.x, c3.z))
	RenderingServer.global_shader_parameter_set("cut_half", board.dim * 0.5)
	for c in ambient_root.get_children():
		c.queue_free()
	Fx.ambient(ambient_root, b, Vector3(c3.x, 0, c3.z))
	for f in battle.foes:
		f.queue_free()
	battle.foes.clear()
	for n in battle.prop_nodes.values():
		n.queue_free()
	battle.prop_nodes.clear()
	if heroes.size() > 0:
		var hc := board.spawn_cells("hero", heroes.size())
		for i in heroes.size():
			heroes[i].place(hc[i], board)
			heroes[i].face(Vector2i(board.dim / 2, board.dim / 2) - hc[i])
	ui.set_header(b.name, ("Étage %d · donjon" % floor_i) if mode == "aventure" else ("Étage %d · salle %d / %d" % [floor_i, step + 1, ROOMS_PER_FLOOR]))
	target = c3
	dist = 14.0 + board.dim * 1.05


func _fight(type: String, ids_override: Array = []) -> bool:
	var ids: Array
	var size := 14 + 2 * rng.randi_range(0, 1)
	var arch := next_arch
	match type:
		"elite":
			ids = Data.ELITES[floor_i]
			size = 16
		"boss":
			ids = Data.BOSS
			size = 18
		_:
			var pool: Array = Data.ENCOUNTERS[floor_i]
			ids = pool[rng.randi_range(0, pool.size() - 1)]
	if ids_override.size() > 0:
		ids = ids_override
	# difficulté : un ennemi de plus (tiré dans les escouades de l'étage) ou de moins
	ids = ids.duplicate()
	var extra: int = Data.DIFFICULTY[difficulty].extra[floor_i - 1] + (1 if pacts.has("horde") else 0)
	if extra > 0 and type != "boss":
		var flat: Array = []
		for e in Data.ENCOUNTERS[floor_i]:
			flat.append_array(e)
		for k in extra:
			ids.append(flat[rng.randi_range(0, flat.size() - 1)])
	elif extra < 0 and type == "combat" and ids.size() > 3:
		ids.resize(ids.size() + extra)
	_build_room(run_seed + floor_i * 1009 + step * 37 + fights * 131, _biome(), size, arch, true)
	pitch = 40.0
	battle.objective = next_obj if type == "combat" else "kill"
	battle.champions = maxi(0, (floor_i - 1) + (1 if type == "elite" else 0) + Data.DIFFICULTY[difficulty].champ)
	battle.rng.seed = run_seed + floor_i * 13 + step
	Battle.foe_mult = Data.DIFFICULTY[difficulty].foe[floor_i - 1]
	var mods: Array = next_mods.duplicate() if type != "boss" else []
	for pk in [["acier", "blindes"], ["rage", "enrages"], ["brume", "brume"]]:
		if pacts.has(pk[0]) and not mods.has(pk[1]):
			mods.append(pk[1])
	battle.mods = mods
	Battle.foe_bonus = 2 if mods.has("enrages") else 0
	battle.hand_size = 4 if pacts.has("main") else 5
	battle.besace = besace
	battle.besace_max = besace_max + (1 if relics.has("sacoche") else 0)
	battle.tool_rate = 0.3 + 0.1 * (floor_i - 1)
	if pacts.has("champion"):
		battle.champions += 1
	if mods.size() > 0:
		ui.set_header(Data.BIOMES[_biome()].name, "Étage %d · salle %d / %d  ·  %s" % [floor_i, step + 1, ROOMS_PER_FLOOR,
			" · ".join(mods.map(func(m): return Data.MODIFIERS[m].glyph + " " + Data.MODIFIERS[m].name))])
	ui.show_hud(true)
	play_music("combat")
	battle.start(heroes, ids, deck, relics)
	target = _units_center()
	ui.show_hud(true)
	var won: bool = await battle.ended
	play_music("calme")
	ui.show_hud(false)
	board.highlight({})
	return won


func _roll_item(min_rarity := 1) -> String:
	## Rareté pondérée par l'étage : les objets rares arrivent plus tard.
	var roll := rng.randf() - 0.04 * pacts.size() + floor_i * 0.15
	var rar := 3 if roll > 1.05 else (2 if roll > 0.6 else 1)
	rar = maxi(rar, min_rarity)
	var ids: Array = []
	while ids.is_empty() and rar > 0:
		ids = Data.ITEMS.keys().filter(func(id): return Data.ITEMS[id].rarity == rar and (Data.ITEMS[id].owner == "any" or party.has(Data.ITEMS[id].owner)))
		rar -= 1
	return ids[rng.randi_range(0, ids.size() - 1)]


func _gain_item(id: String, h: Unit = null) -> void:
	## Au sac, ou équipé d'office si l'emplacement du héros qui l'a trouvé est libre.
	var it: Dictionary = Data.ITEMS[id]
	var who: Array = [h] if h else heroes
	for u in who:
		if (it.owner == "any" or it.owner == u.key) and u.equip[it.slot] == "":
			u.equip[it.slot] = id
			u.apply_gear()
			ui.toast("%s : %s, équipé." % [u.nm, it.name])
			return
	bag.append(id)
	ui.toast("%s rejoint le sac." % it.name)


func open_chest(h: Unit) -> void:
	var g := 0
	if h.has_p("chasseur"):
		g += 25
	if rng.randf() < 0.35:
		_gain_tool(_tool_roll())
	if rng.randf() < 0.65:
		_gain_item(_roll_item(), h)
	else:
		g += rng.randi_range(30, 55)
	if g > 0:
		gold += g
		ui.set_gold(gold)
		Fx.number(self, h.position + Vector3(0, 0.6, 0), "+%d or" % g, Color(1.0, 0.85, 0.4))


func _rewards(type: String) -> void:
	var g := int((rng.randi_range(18, 28) + (30 if type == "elite" else 0)) * (1.0 + 0.25 * pacts.size()) * (1.5 if next_mods.size() > 0 else 1.0))
	gold += g
	ui.set_gold(gold)
	if type == "elite" or rng.randf() < 0.4:
		_gain_tool(_tool_roll(3 if type == "elite" else 2))
	var opts: Array = []
	var n := 4 if relics.has("oeil") else 3
	while opts.size() < n:
		var id := _card_roll(2 if (type == "elite" or next_mods.size() > 0) and opts.is_empty() else 1)
		if opts.any(func(o): return o.card.id == id):
			continue
		opts.append({"card": {"id": id, "lvl": 2 if type == "elite" and opts.is_empty() else 1}})
	var i := await ui.choose("BUTIN", "+%d or · ajoutez une carte au paquet (%d cartes)" % [g, deck.size()], opts, true)
	if i >= 0:
		deck.append(opts[i].card)
	if type == "elite":
		_gain_item(_roll_item(2))
		await _relic_pick("RELIQUE D'ÉLITE", "Les gardiens tombés laissent un trésor")


func _card_roll(min_rar := 1) -> String:
	## Commune 60 %, peu commune 30 %, rare 10 % ; seulement les cartes de l'escouade.
	var roll := rng.randf()
	var rar := maxi(3 if roll < 0.1 else (2 if roll < 0.4 else 1), min_rar)
	var ids: Array = Data.CARDS.keys().filter(func(id): return party.has(Data.CARDS[id].owner) and Data.CARDS[id].get("rar", 1) == rar)
	return ids[rng.randi_range(0, ids.size() - 1)]


func _item_opt(id: String, price := 0) -> Dictionary:
	var it: Dictionary = Data.ITEMS[id]
	var title: String = it.name + ("  ·  %d or" % price if price > 0 else "")
	return {"title": title, "glyph": "⚔" if it.slot == "arme" else "◈", "text": Data.item_text(id),
		"color": [UI.GOLD, Color("#8fa3b8"), Color("#6fb0e0"), Color("#d08aff")][it.rarity]}


func _equipment() -> void:
	while true:
		var opts: Array = []
		for h in heroes:
			var gear: Array = []
			for slot in ["arme", "talisman"]:
				gear.append(Data.ITEMS[h.equip[slot]].name if h.equip[slot] != "" else "—")
			opts.append({"title": h.nm, "glyph": "", "text": "Arme : %s\nTalisman : %s" % gear, "color": Data.CLASS_COLOR[h.key]})
		for id in bag:
			opts.append(_item_opt(id))
		var i := await ui.choose("ÉQUIPEMENT", "Choisissez un objet du sac pour l'équiper", opts, true)
		if i < heroes.size():
			return
		var id: String = bag[i - heroes.size()]
		var it: Dictionary = Data.ITEMS[id]
		var fits: Array = heroes.filter(func(u): return it.owner == "any" or it.owner == u.key)
		var hopts: Array = []
		for u in fits:
			var cur: String = u.equip[it.slot]
			hopts.append({"title": u.nm, "glyph": "", "text": "Remplace : %s" % (Data.ITEMS[cur].name if cur != "" else "rien"), "color": Data.CLASS_COLOR[u.key]})
		var j := await ui.choose(it.name.to_upper(), Data.item_text(id), hopts, true)
		if j < 0:
			continue
		var u: Unit = fits[j]
		bag.erase(id)
		if u.equip[it.slot] != "":
			bag.append(u.equip[it.slot])
		u.equip[it.slot] = id
		u.apply_gear()


func _merchant() -> void:
	if mode != "aventure":
		_build_room(run_seed + floor_i * 311 + step, _biome(), 12, "cour")
	var stock: Array = []
	while stock.size() < 3:
		var id := _roll_item()
		if not stock.has(id):
			stock.append(id)
	var card := {"id": _card_roll(2), "lvl": 2}
	var tstock: Array = [_tool_roll(), _tool_roll(3)]
	var healed := false
	while true:
		var opts: Array = []
		for id in stock:
			opts.append(_item_opt(id, Data.PRICE[Data.ITEMS[id].rarity]))
		for id in tstock:
			opts.append({"title": "%s  ·  %d or" % [Data.TOOLS[id].name, _tool_price(id)], "glyph": Data.TOOLS[id].glyph, "text": "Besace — " + Data.TOOLS[id].text, "color": Color("#7fe0c8")})
		if card:
			opts.append({"title": "%s niv 2  ·  50 or" % Data.CARDS[card.id].name, "glyph": "✦", "text": Data.card_text(Data.card(card))})
		if not healed:
			opts.append({"title": "Soins  ·  35 or", "glyph": "✚", "text": "Chaque héros récupère 50 % de ses PV max."})
		opts.append({"title": "Épurer  ·  40 or", "glyph": "✂", "text": "Retirer une carte du paquet."})
		opts.append({"title": "Forge  ·  35 or", "glyph": "⚒", "text": "Une carte du paquet gagne un niveau."})
		var i := await ui.choose("MARCHAND", "Vous avez %d or" % gold, opts, true)
		if i < 0:
			return
		if i < stock.size():
			var id: String = stock[i]
			var price: int = Data.PRICE[Data.ITEMS[id].rarity]
			if gold < price:
				ui.toast("Pas assez d'or.")
				continue
			gold -= price
			stock.remove_at(i)
			_gain_item(id)
		elif i < stock.size() + tstock.size():
			var tid: String = tstock[i - stock.size()]
			if gold < _tool_price(tid):
				ui.toast("Pas assez d'or.")
				continue
			if besace.size() >= besace_max + (1 if relics.has("sacoche") else 0):
				ui.toast("Besace pleine.")
				continue
			gold -= _tool_price(tid)
			tstock.remove_at(i - stock.size())
			_gain_tool(tid)
		else:
			var rest: Array = ["card", "heal", "purge", "forge"].filter(func(k): return (k != "card" or card) and (k != "heal" or not healed))
			var k: String = rest[i - stock.size() - tstock.size()]
			var price: int = {"card": 50, "heal": 35, "purge": 40, "forge": 35}[k]
			if gold < price:
				ui.toast("Pas assez d'or.")
				continue
			if k == "card":
				deck.append(card)
				card = {}
			elif k == "heal":
				for h in heroes:
					h.hp = mini(h.max_hp, h.hp + h.max_hp / 2)
				healed = true
			elif k == "forge":
				if not await _forge("FORGE", "Quelle carte forger ? (+1 niveau)"):
					continue
			else:
				var copts: Array = deck.map(func(c): return {"card": c})
				var j := await ui.choose("ÉPURER", "Quelle carte retirer ?", copts, true)
				if j < 0:
					continue
				deck.remove_at(j)
			gold -= price
		ui.set_gold(gold)


func _relic_pick(title: String, subtitle: String) -> void:
	var free: Array = Data.RELICS.keys().filter(func(r): return not relics.has(r))
	var opts: Array = []
	var ids: Array = []
	while opts.size() < mini(3, free.size()):
		var r: String = free[rng.randi_range(0, free.size() - 1)]
		if ids.has(r):
			continue
		ids.append(r)
		opts.append({"title": Data.RELICS[r].name, "glyph": Data.RELICS[r].glyph, "text": Data.RELICS[r].text})
	if opts.is_empty():
		return
	var i := await ui.choose(title.to_upper(), subtitle, opts)
	_add_relic(ids[i])


func _add_relic(r: String) -> void:
	relics.append(r)
	if r == "heron":
		for h in heroes:
			h.base_move += 1
			h.apply_gear()
	ui.refresh_relics(relics)


func _sanctuary() -> void:
	if mode != "aventure":
		_build_room(run_seed + floor_i * 577 + step, _biome(), 12, "ecluse")
	while true:
		var i := await ui.choose("SANCTUAIRE", "Une eau calme sous les arches", [
			{"title": "Se reposer", "glyph": "✚", "text": "Chaque héros récupère 35 % de ses PV max."},
			{"title": "Forger", "glyph": "⚒", "text": "Une carte du paquet gagne un niveau (5 au maximum)."},
			{"title": "Fusionner", "glyph": "⧉", "text": "Deux exemplaires de même niveau n'en font plus qu'un, d'un niveau au-dessus."},
		])
		if i == 0:
			for h in heroes:
				h.hp = mini(h.max_hp, h.hp + int(h.max_hp * 0.35))
			ui.toast("Le groupe reprend son souffle.")
			return
		if i == 1 and await _forge("FORGE", "Quelle carte forger ? (+1 niveau)"):
			return
		if i == 2 and await _fuse():
			return


func _forge(title: String, subtitle: String) -> bool:
	var idx: Array = []
	for k in deck.size():
		if Data.level(deck[k]) < 5:
			idx.append(k)
	if idx.is_empty():
		ui.toast("Tout le paquet est déjà au niveau 5.")
		return false
	var j := await ui.choose(title, subtitle, idx.map(func(k): return {"card": {"id": deck[k].id, "lvl": Data.level(deck[k]) + 1}}), true)
	if j < 0:
		return false
	_level_up(idx[j])
	ui.toast("%s passe au niveau %d." % [Data.CARDS[deck[idx[j]].id].name, deck[idx[j]].lvl])
	return true


func _level_up(k: int) -> void:
	var nc: Dictionary = deck[k].duplicate()
	nc["lvl"] = Data.level(deck[k]) + 1
	nc.erase("up")
	deck[k] = nc


func _fuse() -> bool:
	## Deux doubles de même niveau -> un seul exemplaire au niveau suivant. Les cartes de départ ne fusionnent pas.
	var seen := {}
	var pairs: Array = []
	for k in deck.size():
		if deck[k].get("st", false):
			continue
		var key := "%s|%d" % [deck[k].id, Data.level(deck[k])]
		if seen.has(key) and Data.level(deck[k]) < 5:
			pairs.append([seen[key], k])
			seen.erase(key)
		else:
			seen[key] = k
	if pairs.is_empty():
		ui.toast("Aucun double de même niveau à fusionner (les cartes de départ ne fusionnent pas).")
		return false
	var j := await ui.choose("FUSION", "Deux exemplaires deviennent un seul, au niveau suivant", pairs.map(func(pr): return {"card": {"id": deck[pr[0]].id, "lvl": Data.level(deck[pr[0]]) + 1}}), true)
	if j < 0:
		return false
	var pr: Array = pairs[j]
	var fused := {"id": deck[pr[0]].id, "lvl": Data.level(deck[pr[0]]) + 1}
	deck.remove_at(pr[1])
	deck[pr[0]] = fused
	ui.toast("Fusion : %s niveau %d." % [Data.CARDS[fused.id].name, fused.lvl])
	return true


# ------------------------------------------------------------------ capture pour le critique

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(dir: String, name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(dir.path_join(name + ".png"))
	print("capture ", name)


func _capture() -> void:
	var dir: String = args.capture
	DirAccess.make_dir_recursive_absolute(dir)
	run_seed = int(args.get("seed", "7"))
	rng.seed = run_seed
	floor_i = int(args.get("floor", "1"))
	var bi := int(args.get("biome", str(floor_i - 1)))
	floor_biomes = [bi, bi, bi]
	battle.champions = floor_i - 1
	deck = Data.starter(party)
	_make_party()
	heroes[0].equip.arme = "epee_ecluse"
	heroes[1].equip.talisman = "bottes_heron"
	var ids: Array = Data.BOSS if args.has("boss") else Data.ENCOUNTERS[floor_i][0]
	var size := 18 if args.has("boss") else int(args.get("size", "16"))
	_build_room(run_seed, _biome(), size, "cour" if args.has("boss") else args.get("arch", ""), true)
	ui.show_hud(true)
	battle.start(heroes, ids, deck, relics)
	target = _units_center()
	battle.hand = Data.starter(party).slice(0, 5)
	battle.changed.emit()
	await _frames(150)
	var hero: Unit = heroes[0]
	var foe: Unit = battle.foes[0]
	var c3 := _units_center()
	var far := 14.0 + board.dim * 1.05
	var views := [
		{"n": "01_jeu", "yaw": 45.0, "pitch": 40.0, "dist": far, "ui": true},
		{"n": "07_dessus", "yaw": 45.0, "pitch": 72.0, "dist": far * 1.2, "ui": false},
		{"n": "02_visee", "yaw": 45.0, "pitch": 40.0, "dist": far * 0.8, "ui": true, "card": 2},
		{"n": "03_large", "yaw": 135.0, "pitch": 44.0, "dist": far * 1.4, "ui": false},
		{"n": "04_rasant", "yaw": 225.0, "pitch": 18.0, "dist": far * 0.7, "ui": false},
		{"n": "05_heros", "yaw": 45.0, "pitch": 30.0, "dist": 7.0, "ui": false, "at": hero},
		{"n": "06_ennemi", "yaw": 45.0, "pitch": 30.0, "dist": 7.0, "ui": false, "at": foe},
	]
	for v in views:
		yaw = v.yaw
		pitch = v.pitch
		dist = v.dist
		target = c3 if not v.has("at") else v.at.position + Vector3(0, 0.7, 0)
		_snap_cam()
		ui.root.visible = v.ui
		if v.has("card"):
			# un ennemi à portée de Braise pour montrer une vraie visée
			var ora: Unit = heroes[2]
			for c in board.walkable_cells():
				if Battle.dist(c, ora.cell) == 3 and battle.unit_at(c) == null:
					foe.place(c, board)
					break
			target = ora.position
			_snap_cam()
			battle.select_card(v.card)
			hover = foe.cell
			refresh_hover()
		else:
			battle.card_sel = -1
			hover = null
			refresh_hover()
		await _frames(30)
		_shot(dir, v.n)
	# plan d'action : un ennemi collé au Garde, frappe en cours, caméra de jeu
	ui.root.visible = true
	var spot := hero.cell
	for d in Board.DIRS:
		if board.walkable(hero.cell + d) and battle.unit_at(hero.cell + d) == null:
			spot = hero.cell + d
			break
	foe.place(spot, board)
	foe.face(hero.cell - spot)
	yaw = 45.0
	pitch = 36.0
	dist = 13.0
	target = hero.position + Vector3(0, 0.6, 0)
	_snap_cam()
	battle.card_sel = -1
	battle.changed.emit()
	await _frames(10)
	battle.play_card(0, foe.cell)
	await get_tree().create_timer(0.32).timeout
	_shot(dir, "08_action")
	await get_tree().create_timer(1.2).timeout
	get_tree().quit()


# ------------------------------------------------------------------ auto-jeu (test de fumée)

func _autoplay() -> void:
	## Joue plusieurs combats au hasard (toutes topologies, objets, champions, portail) pour
	## débusquer les erreurs d'exécution. Imprime un bilan puis quitte.
	Engine.time_scale = 8.0
	var fights_n := int(args.get("autoplay", "6"))
	run_seed = int(args.get("seed", "3"))
	rng.seed = run_seed
	deck = Data.starter(party)
	# toutes les cartes de l'escouade : chaque mécanique passe au moins une fois
	for id in Data.CARDS:
		if party.has(Data.CARDS[id].owner) and not Data.STARTER[Data.CARDS[id].owner].has(id):
			deck.append({"id": id, "lvl": 2})
	_make_party()
	if party == ["garde", "lame", "oracle"]:
		heroes[0].equip = {"arme": "masse_os", "talisman": "anneau_bouclier"}
		heroes[1].equip = {"arme": "kriss", "talisman": "ecaille_eau"}
		heroes[2].equip = {"arme": "sceptre_maree", "talisman": "miroir"}
	var won := 0
	for n in fights_n:
		floor_i = 1 + n % 3
		floor_biomes = [n % Data.BIOMES.size(), (n + 1) % Data.BIOMES.size(), (n + 2) % Data.BIOMES.size()]
		for h in heroes:
			h.revive()
			h.hp = h.max_hp
		battle.objective = "portal" if n % 3 == 2 else "kill"
		battle.champions = floor_i - 1
		besace = Data.TOOLS.keys().duplicate()
		battle.besace = besace
		battle.besace_max = 20
		battle.tool_rate = 1.0
		Battle.foe_mult = Data.DIFFICULTY[difficulty].foe[floor_i - 1]
		_build_room(run_seed + n * 101, _biome(), [14, 16, 18][n % 3], Board.ARCHETYPES[n % 4], true)
		var ids: Array = Data.BOSS if n == fights_n - 1 else Data.ENCOUNTERS[floor_i][n % Data.ENCOUNTERS[floor_i].size()]
		ui.show_hud(true)
		battle.start(heroes, ids, deck, relics)
		var turns := 0
		while not battle.over and turns < 14:
			turns += 1
			await _auto_turn()
			if battle.over:
				break
			await battle.end_turn()
		if battle.over and not battle.alive_heroes().is_empty():
			won += 1
		print("combat %d (%s, %s, %s) : %d tours, héros vivants %d, ennemis vivants %d" % [n, board.archetype, Data.BIOMES[_biome()].name, battle.objective, turns, battle.alive_heroes().size(), battle.alive_foes().size()])
		await get_tree().create_timer(0.5).timeout
	# boutique et équipement sans interface : juste les chemins de code
	bag = ["gantelet", "bottes_heron"]
	_gain_item("coeur_pierre", heroes[0])
	open_chest(heroes[1])
	print("AUTOPLAY OK, %d/%d combats gagnés" % [won, fights_n])
	get_tree().quit()


func _auto_turn() -> void:
	## Un tour de joueur naïf : chaque héros s'approche, puis on joue ce qui a une cible.
	for h in battle.alive_heroes():
		if battle.over:
			return
		battle.select(h)
		var R := battle.reach(h)
		var foes_ := battle.alive_foes()
		if foes_.is_empty():
			return
		var goal: Vector2i = battle.board.portal if battle.objective == "portal" else foes_[0].cell
		var best: Vector2i = h.cell
		for c in R.cells:
			if Battle.dist(c, goal) < Battle.dist(best, goal):
				best = c
		if best != h.cell:
			await battle.click(best)
		for pc in board.props.keys():
			if board.props.get(pc, "") in ["coffre", "levier"] and Battle.dist(pc, h.cell) == 1 and not h.moved:
				await battle.interact(h, pc)
	if battle.besace.size() > 0 and not battle.over:
		var used := false
		for h in battle.alive_heroes():
			battle.select(h)
			var tg := battle.tool_targets(battle.besace[0], h)
			if tg.size() > 0:
				await battle.use_tool(0, tg[-1])
				used = true
				break
		if not used and battle.besace.size() > 0:
			battle.besace.pop_front()
	var guard := 0
	while guard < 12 and not battle.over:
		guard += 1
		var played := false
		for i in battle.hand.size():
			var c := Data.card(battle.hand[i])
			var h := battle.owner_of(c)
			if h == null or not h.alive or battle.cost_of(c) > battle.energy:
				continue
			var tg := battle.card_targets(c, h)
			if tg.is_empty():
				continue
			await battle.play_card(i, tg[0])
			played = true
			break
		if not played:
			break


func _units_center() -> Vector3:
	## Milieu de l'emprise des unités : c'est là que se joue le combat, pas au centre de la carte.
	var box := AABB(heroes[0].position, Vector3.ZERO)
	for u in battle.heroes + battle.foes:
		box = box.expand(u.position)
	return box.get_center()


func _uitest() -> void:
	## Vérifie l'interface avec de vrais clics : carte de butin, fiche d'ennemi, menu.
	var dir: String = args.uitest
	DirAccess.make_dir_recursive_absolute(dir)
	run_seed = 7
	rng.seed = run_seed
	deck = Data.starter(party)
	_make_party()
	_build_room(run_seed, 0, 16, "", true)
	ui.show_hud(true)
	besace = ["fiole", "bombe", "gland"]
	battle.besace = besace
	battle.besace_max = 5
	battle.tool_rate = 1.0
	battle.start(heroes, Data.ENCOUNTERS[1][0], deck, relics)
	target = _units_center()
	_snap_cam()
	await _frames(90)
	var foe: Unit = battle.foes[0]
	hover = foe.cell
	refresh_hover()
	await _frames(20)
	_shot(dir, "fiche")
	print("fiche visible : ", ui.sheet_plate.visible, " · zone : ", battle.reach(foe).cells.size())
	ui.toggle_menu()
	await _frames(20)
	_shot(dir, "menu")
	ui.toggle_menu()
	var per_hero := true
	for n in 30:
		battle.discard.append_array(battle.hand)
		battle.hand.clear()
		battle.draw(5)
		for h in battle.alive_heroes():
			if not battle.hand.any(func(ci): return Data.card(ci).owner == h.key):
				per_hero = false
	print("chaque héros a une carte sur 30 pioches : ", per_hero)
	ui.show_hud(false)
	var got := [-2]
	var chooser := func(): got[0] = await _rewards_probe()
	chooser.call()
	await _frames(30)
	_shot(dir, "butin")
	var holder: Control = ui.overlay.find_children("*", "Control", true, false).filter(func(c): return c.custom_minimum_size == UI.CARD * 1.2)[1]
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = holder.get_global_rect().get_center()
	ev.global_position = ev.position
	get_viewport().push_input(ev)
	await _frames(10)
	print("carte de butin cliquée : ", got[0])
	# écrans de run : escouade, carte d'étage, butin rare
	var probe := func(): await _draft()
	probe.call()
	await _frames(30)
	_shot(dir, "escouade")
	ui.picked.emit(-1)
	await _frames(10)
	floor_i = 1
	step = 0
	_gen_map()
	visited = [Vector2i(0, 1)]
	lane = 1
	step = 1
	var mp := func(): await ui.map_screen("ÉTAGE 1", "test", fmap, step, lane, fmap[0][1].links, visited, "Équipement · 0 objet(s) au sac")
	mp.call()
	await _frames(30)
	_shot(dir, "carte")
	ui.picked.emit(0)
	await _frames(10)
	var rw := func(): await ui.choose("BUTIN", "test", [{"card": {"id": "tourelle", "lvl": 1}}, {"card": {"id": "voie", "lvl": 3}}, {"card": {"id": "harpon", "lvl": 5}}], true)
	rw.call()
	await _frames(30)
	_shot(dir, "butin2")
	get_tree().quit()


func _rewards_probe() -> int:
	var opts: Array = []
	for id in ["frappe", "braise", "estoc"]:
		opts.append({"card": {"id": id, "lvl": 1}})
	return await ui.choose("BUTIN", "test", opts, true)


# ------------------------------------------------------------------ mode aventure

func _pick_mode() -> String:
	var i := await ui.choose("MODE", "Deux façons de descendre", [
		{"title": "Descente", "glyph": "⇣", "text": "Carte d'étage à trois voies : on choisit ses salles, combat après combat.", "color": UI.GOLD},
		{"title": "Aventure", "glyph": "✥", "text": "On mène l'escouade dans le donjon, salle par salle, dans le brouillard. Croiser un monstre lance le combat.", "color": Color("#8fd0a0")},
	])
	return ["descente", "aventure"][i]


func _adventure() -> void:
	## Trois étages de donjon ; un gardien d'élite garde l'escalier, le Gardien de l'Écluse attend au dernier.
	while true:
		_gen_dungeon()
		_show_dungeon()
		await _ancient()
		_explore_hud()
		var r: String = await floor_done
		if r == "lost":
			await ui.game_over(false, "Étage %d, %d combats remportés, %d min, difficulté %d/5." % [floor_i, fights, _minutes(), difficulty + 1])
			new_run.call_deferred()
			return
		if r == "won":
			await ui.game_over(true, "Le Gardien est tombé : %d combats, %d min, difficulté %d/5." % [fights, _minutes(), difficulty + 1])
			new_run.call_deferred()
			return
		floor_i += 1
		ui.banner("Étage %d" % floor_i, Data.BIOMES[_biome()].name)


func _gen_dungeon() -> void:
	var b: Dictionary = Data.BIOMES[_biome()]
	if aboard == null:
		aboard = Board.new()
		add_child(aboard)
		adv_root = Node3D.new()
		add_child(adv_root)
	for ch in adv_root.get_children():
		ch.queue_free()
	aboard.generate(run_seed + floor_i * 4447, b, 36 if floor_i == 1 else 45, "donjon", false)
	aboard.build_visuals()
	# distances dans le graphe des salles : le gardien au plus loin du départ
	var start_i := _room_index(aboard.rects, aboard.start)
	var gd := {start_i: 0}
	var q: Array = [start_i]
	while q.size() > 0:
		var a: int = q.pop_front()
		for l in aboard.links:
			for pair in [[l[0], l[1]], [l[1], l[0]]]:
				if pair[0] == a and not gd.has(pair[1]):
					gd[pair[1]] = gd[a] + 1
					q.append(pair[1])
	var far := start_i
	for k in gd:
		if gd[k] > gd[far]:
			far = k
	var others: Array = range(aboard.rects.size()).filter(func(k): return k != start_i and k != far)
	for i in range(others.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = others[i]
		others[i] = others[j]
		others[j] = t
	# peu de monstres, beaucoup de salles « ? » et de caches ; les essentiels d'abord si le donjon est petit
	var deck_types: Array = ["elite"]
	if floor_i > 1:
		deck_types.append("elite")
	for k in 2 + floor_i:
		deck_types.append("combat")
	deck_types += ["marchand", "sanctuaire", "reliquaire", "coffre"]
	var fill := ["mystere", "mystere", "reserve", "mystere", "coffre", "mystere", "reserve", "vide"]
	var fi := 0
	while deck_types.size() < others.size():
		deck_types.append(fill[fi % fill.size()])
		fi += 1
	rooms = []
	for k in aboard.rects.size():
		var t: String = "depart"
		if k == far:
			t = "boss" if floor_i == 3 else "gardien"
		elif k != start_i:
			t = deck_types[others.find(k)]
		var ids: Array = []
		match t:
			"combat":
				var pool: Array = Data.ENCOUNTERS[floor_i]
				ids = pool[rng.randi_range(0, pool.size() - 1)]
			"elite", "gardien":
				ids = Data.ELITES[floor_i] if Data.ELITES.has(floor_i) else Data.ELITES[2]
			"boss":
				ids = Data.BOSS
		var mods: Array = []
		if t in ["elite", "gardien"] or (t == "combat" and rng.randf() < 0.3):
			mods.append(Data.MODIFIERS.keys()[rng.randi_range(0, Data.MODIFIERS.size() - 1)])
		var r := {"rect": aboard.rects[k], "type": t, "cell": aboard._nearest_walkable(aboard.rects[k].get_center()), "ids": ids,
			"arch": Board.ARCHETYPES[rng.randi_range(0, 3)], "mods": mods, "done": t in ["depart", "vide"], "seen": false, "node": null, "fog": null}
		rooms.append(r)
		r.node = _room_node(r)
		r.fog = _fog(r.rect)
	leader = Unit.new()
	leader.setup(party[0], "hero")
	adv_root.add_child(leader)
	leader.place(aboard._nearest_walkable(aboard.start), aboard)
	followers.clear()
	for k in range(1, party.size()):
		var f := Unit.new()
		f.setup(party[k], "hero")
		adv_root.add_child(f)
		f.place(leader.cell, aboard)
		f.visible = false
		followers.append(f)
	trail.clear()
	_reveal(start_i, true)


func _room_index(rects: Array, c: Vector2i) -> int:
	for k in rects.size():
		if (rects[k] as Rect2i).has_point(c):
			return k
	return 0


func _room_at(c: Vector2i) -> int:
	for k in rooms.size():
		if (rooms[k].rect as Rect2i).has_point(c):
			return k
	return -1


func _room_node(r: Dictionary) -> Node3D:
	## Ce qui attend dans la salle : un monstre, un coffre, un marchand...
	var t: String = r.type
	if t in ["depart", "vide"]:
		return null
	var n := Node3D.new()
	adv_root.add_child(n)
	n.position = aboard.world(r.cell)
	var glyph: Array = {"combat": ["⚔", Color(1.0, 0.6, 0.3)], "elite": ["☠", Color(1.0, 0.4, 0.3)], "gardien": ["☠", Color(1.0, 0.35, 0.25)],
		"boss": ["♜", Color(1.0, 0.3, 0.2)], "coffre": ["◆", Color(1.0, 0.85, 0.35)], "marchand": ["⚖", Color(1.0, 0.85, 0.5)],
		"sanctuaire": ["✚", Color(0.6, 1.0, 0.65)], "reliquaire": ["◆", Color(0.85, 0.6, 1.0)], "escalier": ["⇩", Color(0.55, 0.9, 1.0)],
		"mystere": ["?", Color(0.75, 0.85, 1.0)], "reserve": ["❖", Color(0.5, 1.0, 0.8)]}.get(t, ["?", Color.WHITE])
	if t in ["combat", "elite", "gardien", "boss"]:
		var u := Unit.new()
		u.setup(r.ids[0], "foe")
		n.add_child(u)
		u.face(Vector2i(0, 1))
		if t != "combat":
			u.scale = Vector3.ONE * 1.2
	else:
		var key: String = {"coffre": "prop_coffre", "marchand": "lantern", "sanctuaire": "crystal_0", "reliquaire": "crystal_1", "escalier": "portal",
			"mystere": "statue", "reserve": "prop_sac"}.get(t, "")
		if key != "":
			var md := Board.mesh_of(key)
			for part in ["mesh", "glow"]:
				if md[part] == null:
					continue
				var mi := MeshInstance3D.new()
				mi.mesh = md[part]
				mi.material_override = Board.material("glow" if part == "glow" else "prop")
				if t == "mystere":
					mi.scale = Vector3.ONE * 0.55
				n.add_child(mi)
	var l3 := Label3D.new()
	l3.text = glyph[0]
	l3.font = Fx.title_font()
	l3.font_size = 90
	l3.pixel_size = 0.006
	l3.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l3.no_depth_test = true
	l3.modulate = glyph[1]
	l3.outline_size = 18
	l3.outline_modulate = Color(0.05, 0.03, 0.02, 0.85)
	l3.position.y = 2.1
	n.add_child(l3)
	n.visible = not (t in ["combat", "elite"])
	if t in ["coffre", "marchand", "sanctuaire", "reliquaire", "escalier", "gardien", "boss", "mystere", "reserve"]:
		var beam := OmniLight3D.new()
		beam.light_color = glyph[1]
		beam.light_energy = 2.0
		beam.omni_range = 3.5
		beam.position.y = 1.2
		n.add_child(beam)
	return n


func _fog(rc: Rect2i) -> MeshInstance3D:
	## Nappe de nuée plate, bleutée, posée juste au-dessus du sol de la salle ; les tours la percent en silhouette.
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(rc.size.x + 1.6, rc.size.y + 1.6)
	mi.mesh = pm
	if _fog_mat == null:
		_fog_mat = StandardMaterial3D.new()
		_fog_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_fog_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_fog_mat.proximity_fade_enabled = true
		_fog_mat.proximity_fade_distance = 0.8
		var nz := FastNoiseLite.new()
		nz.frequency = 0.05
		var t := NoiseTexture2D.new()
		t.noise = nz
		t.seamless = true
		var g := Gradient.new()
		g.colors = PackedColorArray([Color(0.2, 0.26, 0.34), Color(0.55, 0.64, 0.72)])
		t.color_ramp = g
		_fog_mat.albedo_texture = t
		_fog_mat.uv1_scale = Vector3(2, 2, 1)
	var m: StandardMaterial3D = _fog_mat.duplicate()
	m.albedo_color = Color(1, 1, 1, 0.96)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var top := 0
	for x in range(rc.position.x, rc.end.x):
		for z in range(rc.position.y, rc.end.y):
			if aboard.kind.get(Vector2i(x, z), "") != "tower":
				top = maxi(top, aboard.h.get(Vector2i(x, z), 0))
	mi.position = Vector3(rc.position.x + rc.size.x * 0.5 - 0.5, top * Board.LH + 0.9, rc.position.y + rc.size.y * 0.5 - 0.5)
	adv_root.add_child(mi)
	return mi


func _reveal(k: int, instant := false) -> void:
	## La salle où l'on entre se dévoile ; ses voisines s'entrevoient à travers une brume plus légère.
	var near: Array = [k]
	for l in aboard.links:
		if l[0] == k:
			near.append(l[1])
		elif l[1] == k:
			near.append(l[0])
	for i in near:
		var r: Dictionary = rooms[i]
		var full: bool = i == k
		if r.node:
			r.node.visible = true
		if r.fog == null:
			continue
		var m: StandardMaterial3D = r.fog.material_override
		var a := 0.0 if full else minf(m.albedo_color.a, 0.5)
		if instant:
			m.albedo_color.a = a
		else:
			r.fog.create_tween().tween_property(m, "albedo_color:a", a, 0.6)
		if full:
			r.seen = true
			var f: MeshInstance3D = r.fog
			r.fog = null
			f.create_tween().tween_interval(0.7).finished.connect(f.queue_free)


func _show_dungeon() -> void:
	var b: Dictionary = Data.BIOMES[_biome()]
	exploring = true
	board.visible = false
	units_root.visible = false
	aboard.visible = true
	adv_root.visible = true
	apply_biome(b)
	RenderingServer.global_shader_parameter_set("cut_half", 999.0)
	env.fog_depth_begin = 55.0
	env.fog_depth_end = 170.0
	for c in ambient_root.get_children():
		c.queue_free()
	Fx.ambient(ambient_root, b, leader.position)
	ui.show_hud(false)
	_explore_hud()
	target = leader.position + Vector3(0, 0.6, 0)
	dist = 18.0
	pitch = 50.0


func _explore_hud() -> void:
	var line: Array = heroes.map(func(h): return "%s %d/%d" % [h.nm, h.hp, h.max_hp])
	var bz: String = " ".join(besace.map(func(id): return Data.TOOLS[id].glyph))
	ui.show_explore(true, Data.BIOMES[_biome()].name, "Étage %d · donjon · difficulté %d/5" % [floor_i, difficulty + 1],
		" · ".join(line) + (("   ·   Besace  " + bz) if bz != "" else ""))


func _adv_process(dt: float) -> void:
	target = target.lerp(leader.position + Vector3(0, 0.6, 0), 1.0 - exp(-dt * 3.0))
	if ui.menu_open() or ui.overlay != null or _adv_busy:
		return
	var mp := get_viewport().get_mouse_position()
	var hc = aboard.pick(cam.project_ray_origin(mp), cam.project_ray_normal(mp))
	if hc != _adv_hover:
		_adv_hover = hc
		aboard.highlight({hc: Color(1, 1, 1, 0.7)} if hc != null and aboard.walkable(hc) else {})


func _adv_path(goal: Vector2i) -> Array:
	var prev := {leader.cell: leader.cell}
	var q: Array = [leader.cell]
	var i := 0
	while i < q.size():
		var c: Vector2i = q[i]
		i += 1
		if c == goal:
			break
		for d in Board.DIRS:
			var nb: Vector2i = c + d
			if prev.has(nb) or not aboard.walkable(nb) or absi(aboard.h[nb] - aboard.h[c]) > 2:
				continue
			prev[nb] = c
			q.append(nb)
	if not prev.has(goal) or goal == leader.cell:
		return []
	var p: Array = []
	var c := goal
	while c != leader.cell:
		p.push_front(c)
		c = prev[c]
	return p


func _adv_click(goal: Vector2i) -> void:
	if _adv_busy:
		return
	var path := _adv_path(goal)
	if path.is_empty():
		return
	_adv_busy = true
	aboard.highlight({})
	for c in path:
		trail.push_front(leader.cell)
		trail.resize(mini(trail.size(), 4))
		for k in followers.size():
			var f: Unit = followers[k]
			if trail.size() > k and is_instance_valid(f):
				f.visible = true
				f.walk([trail[k]], aboard)
		await leader.walk([c], aboard)
		var k := _room_at(c)
		if k >= 0 and not rooms[k].seen:
			_reveal(k)
		var ev := _adv_trigger(c)
		if ev >= 0:
			await _adv_event(ev)
			break
	_adv_busy = false
	_adv_hover = null


func _adv_trigger(c: Vector2i) -> int:
	for k in rooms.size():
		var r: Dictionary = rooms[k]
		if r.done:
			continue
		if r.type in ["combat", "elite", "gardien", "boss"]:
			if Battle.dist(c, r.cell) <= 1:
				return k
		elif c == r.cell:
			return k
	return -1


func _adv_event(k: int) -> void:
	var r: Dictionary = rooms[k]
	match r.type:
		"combat", "elite", "gardien", "boss":
			var ft: String = {"combat": "combat", "elite": "elite", "gardien": "elite", "boss": "boss"}[r.type]
			ui.banner(Data.ROOMS[ft].name if ft != "combat" else "Embuscade", " · ".join(r.mods.map(func(m): return Data.MODIFIERS[m].name)))
			await get_tree().create_timer(0.6).timeout
			next_arch = r.arch
			next_obj = "kill"
			next_mods = r.mods
			var won: bool = await _fight(ft, r.ids)
			if not won:
				floor_done.emit("lost")
				return
			await _post_fight(ft)
			if ft == "boss":
				floor_done.emit("won")
				return
			if r.node:
				r.node.queue_free()
				r.node = null
			r.done = true
			if r.type == "gardien":
				r.type = "escalier"
				r.done = false
				r.node = _room_node(r)
				r.node.visible = true
				ui.toast("L'escalier vers l'étage suivant est libre.")
			_show_dungeon()
		"coffre":
			r.done = true
			if r.node:
				r.node.queue_free()
			open_chest(heroes[0])
			_explore_hud()
		"marchand":
			await _merchant()
			_explore_hud()
		"sanctuaire":
			r.done = true
			await _sanctuary()
			_explore_hud()
		"reliquaire":
			r.done = true
			if r.node:
				r.node.queue_free()
			await _relic_pick("Reliquaire", "Une relique parmi trois")
			_explore_hud()
		"escalier":
			floor_done.emit("next")
		"mystere":
			await _mystery(r)
		"reserve":
			r.done = true
			if r.node:
				r.node.queue_free()
				r.node = null
			for n in rng.randi_range(1, 2):
				_gain_tool(_tool_roll())
			_explore_hud()


func _advtest() -> void:
	## Mode aventure sans les mains : captures du donjon, marche vers un monstre, combat joué, retour.
	var dir: String = args.advtest
	DirAccess.make_dir_recursive_absolute(dir)
	run_seed = int(args.get("seed", "3"))
	rng.seed = run_seed
	mode = "aventure"
	floor_i = 1
	var bi := int(args.get("biome", "0"))
	floor_biomes = [bi, bi, bi]
	deck = Data.starter(party)
	_make_party()
	_gen_dungeon()
	_show_dungeon()
	_snap_cam()
	await _frames(90)
	_shot(dir, "01_depart")
	var keep := [target, dist, pitch]
	target = Vector3(aboard.dim * 0.5, 0, aboard.dim * 0.5)
	dist = aboard.dim * 1.5
	pitch = 62.0
	_snap_cam()
	await _frames(40)
	_shot(dir, "02_donjon")
	target = keep[0]
	dist = keep[1]
	pitch = keep[2]
	_snap_cam()
	# le monstre le plus proche
	var goal = null
	var best := 1 << 30
	for r in rooms:
		if r.type == "combat" and not r.done:
			for d in Board.DIRS:
				var c: Vector2i = r.cell + d
				if aboard.walkable(c):
					var pl := _adv_path(c).size()
					if pl > 0 and pl < best:
						best = pl
						goal = c
	print("monstre à ", best, " cases")
	_test_driver()
	Engine.time_scale = 3.0
	await _adv_click(goal)
	Engine.time_scale = 1.0
	await _frames(60)
	_shot(dir, "03_retour")
	print("retour au donjon : ", exploring, " · combats ", fights)
	# chemins d'événements : Ancien, bienfaits, salles « ? », paquet
	besace = ["fiole"]
	Engine.time_scale = 3.0
	await _ancient()
	for bk in Data.BOONS:
		await _boon(bk)
	for n in 10:
		await _mystery({"done": false, "node": null, "arch": "cour"})
	await view_deck()
	Engine.time_scale = 1.0
	print("événements OK · paquet %d · besace %d · or %d" % [deck.size(), besace.size(), gold])
	get_tree().quit()


func _test_driver() -> void:
	## Joue à la place du joueur pendant les tests : combats et écrans de choix.
	while is_inside_tree():
		await get_tree().process_frame
		if ui.overlay != null:
			await _frames(15)
			if ui.overlay != null:
				ui.picked.emit(0)
			continue
		if ui.hud.visible and battle.player_turn and not battle.busy and not battle.over:
			if battle.turn > 25:
				# le bot peut tourner en rond : on abrège le combat plutôt que de boucler
				print("bot : combat abrégé au tour %d" % battle.turn)
				for f in battle.alive_foes():
					battle.kill(f)
				continue
			await _auto_turn()
			if not battle.over:
				await battle.end_turn()


# ------------------------------------------------------------------ besace, paquet, Anciens, salles « ? »

func _tool_roll(max_rar := 2) -> String:
	var ids: Array = Data.TOOLS.keys().filter(func(id): return Data.TOOLS[id].rar <= max_rar)
	return ids[rng.randi_range(0, ids.size() - 1)]


func _tool_price(id: String) -> int:
	return 20 + 15 * (int(Data.TOOLS[id].rar) - 1)


func _gain_tool(id: String) -> void:
	if besace.size() >= besace_max + (1 if relics.has("sacoche") else 0):
		ui.toast("Besace pleine : %s reste là." % Data.TOOLS[id].name)
		return
	besace.append(id)
	ui.toast("Besace : + %s %s" % [Data.TOOLS[id].glyph, Data.TOOLS[id].name])


func view_deck(which := "deck") -> void:
	## P : tout le paquet ; en combat, clic sur le compteur : la pioche (ordre caché).
	if ui.overlay != null or ui.menu_open():
		return
	var cards: Array = deck.duplicate()
	var title := "PAQUET"
	var sub := "%d cartes · survol : détails" % cards.size()
	if which == "pioche" and ui.hud.visible:
		cards = battle.draw_pile.duplicate()
		title = "PIOCHE"
		sub = "%d cartes, ordre caché · défausse %d · épuisées %d" % [cards.size(), battle.discard.size(), battle.exhausted.size()]
	var key := func(c: Dictionary) -> String: return "%s|%s|%d" % [Data.CARDS[c.id].owner, c.id, 9 - Data.level(c)]
	cards.sort_custom(func(a, b): return key.call(a) < key.call(b))
	await ui.choose(title, sub, cards.map(func(c): return {"card": c}), true, "Fermer")


func _ancient() -> void:
	## Au seuil de chaque étage, un Ancien (esprit Slay the Spire 2) offre un bienfait parmi trois.
	var keys: Array = Data.ANCIENTS.keys()
	var an: Dictionary = Data.ANCIENTS[keys[posmod(run_seed + floor_i, keys.size())]]
	var pool: Array = an.boons.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = pool[i]
		pool[i] = pool[j]
		pool[j] = t
	var picks: Array = pool.slice(0, 3)
	var opts: Array = picks.map(func(b): return {"title": Data.BOONS[b].name, "glyph": Data.BOONS[b].glyph, "text": Data.BOONS[b].text, "color": an.col})
	var i := await ui.choose("%s  %s" % [an.glyph, an.name.to_upper()], "%s · « %s »" % [an.title, an.line], opts)
	await _boon(picks[i])
	ui.refresh_relics(relics)
	ui.set_gold(gold)


func _boon(k: String) -> void:
	match k:
		"relique":
			var free: Array = Data.RELICS.keys().filter(func(r): return not relics.has(r))
			if free.size() > 0:
				_add_relic(free[rng.randi_range(0, free.size() - 1)])
		"relique_sang":
			await _relic_pick("RELIQUE DE SANG", "Chaque héros perd 5 PV max")
			for h in heroes:
				h.base_hp = maxi(10, h.base_hp - 5)
				h.apply_gear()
		"rare":
			var opts: Array = []
			var guard := 0
			while opts.size() < 3 and guard < 60:
				guard += 1
				var id := _card_roll(3)
				if not opts.any(func(o): return o.card.id == id):
					opts.append({"card": {"id": id, "lvl": 1}})
			var j := await ui.choose("SAVOIR INTERDIT", "Une carte rare pour le paquet", opts, true)
			if j >= 0:
				deck.append(opts[j].card)
		"epure":
			for n in 2:
				var j := await ui.choose("OUBLI", "Retirer une carte (%d / 2)" % (n + 1), deck.map(func(c): return {"card": c}), true, "Garder le reste")
				if j < 0:
					break
				deck.remove_at(j)
		"or":
			gold += 100
		"pvmax":
			for h in heroes:
				h.base_hp += 6
				h.apply_gear()
		"soin":
			for h in heroes:
				h.hp = h.max_hp
		"forge2":
			var idx: Array = range(deck.size()).filter(func(q): return Data.level(deck[q]) < 5)
			var names: Array = []
			for n in mini(2, idx.size()):
				var q: int = idx.pop_at(rng.randi_range(0, idx.size() - 1))
				_level_up(q)
				names.append(Data.CARDS[deck[q].id].name)
			ui.toast("Plus fortes : " + ", ".join(names))
		"racines":
			var hopts: Array = heroes.map(func(h): return {"title": h.nm, "image": "res://assets/art/portrait_%s.png" % h.key, "text": "Ses cartes de départ gagnent un niveau.", "color": Data.CLASS_COLOR[h.key]})
			var j := await ui.choose("RACINES", "Quel héros ?", hopts)
			for q in deck.size():
				if deck[q].get("st", false) and Data.CARDS[deck[q].id].owner == heroes[j].key and Data.level(deck[q]) < 5:
					_level_up(q)
		"besace":
			for n in 3:
				_gain_tool(_tool_roll())
		"place":
			besace_max += 1
			_gain_tool(_tool_roll(3))
		"arme":
			_gain_item(_roll_item(3))
		"reflet":
			var j := await ui.choose("REFLET", "Quelle carte copier ?", deck.map(func(c): return {"card": c}), true)
			if j >= 0:
				deck.append({"id": deck[j].id, "lvl": Data.level(deck[j])})


func _mystery(r: Dictionary) -> void:
	## Salle « ? » : un événement tiré au sort, parfois une embuscade.
	r.done = true
	if r.node:
		r.node.queue_free()
		r.node = null
	var evs := ["fontaine", "cadavre", "enclume", "puits", "cage", "autel", "atelier", "bibliotheque"]
	var ev: String = evs[rng.randi_range(0, evs.size() - 1)]
	var green := Color("#8fd0a0")
	match ev:
		"fontaine":
			var i := await ui.choose("FONTAINE TROUBLE", "Une eau verte suinte d'un mascaron.", [
				{"title": "Boire", "glyph": "✚", "text": "Chaque héros récupère 30 % de ses PV max.", "color": green},
				{"title": "Remplir une fiole", "glyph": "♥", "text": "Une Fiole de sève dans la besace.", "color": green},
			], true, "Passer son chemin")
			if i == 0:
				for h in heroes:
					h.hp = mini(h.max_hp, h.hp + int(h.max_hp * 0.3))
			elif i == 1:
				_gain_tool("fiole")
		"cadavre":
			var i := await ui.choose("AVENTURIER TOMBÉ", "Son sac est encore plein. Quelque chose rôde peut-être.", [
				{"title": "Fouiller", "glyph": "❖", "text": "Deux objets de besace et 30 or. Une chance sur trois d'être surpris.", "color": UI.GOLD},
			], true, "Le laisser en paix")
			if i == 0:
				_gain_tool(_tool_roll())
				_gain_tool(_tool_roll())
				gold += 30
				if rng.randf() < 0.33:
					ui.banner("Embuscade", "Le sac était un appât")
					await get_tree().create_timer(0.6).timeout
					next_arch = r.arch
					next_obj = "kill"
					next_mods = []
					var won: bool = await _fight("combat")
					if not won:
						floor_done.emit("lost")
						return
					await _post_fight("combat")
					_show_dungeon()
		"enclume":
			var i := await ui.choose("ENCLUME ABANDONNÉE", "Le feu couve encore sous les cendres.", [
				{"title": "Forger", "glyph": "⚒", "text": "Une carte du paquet gagne un niveau.", "color": UI.GOLD},
			], true, "Passer son chemin")
			if i == 0:
				await _forge("FORGE", "Quelle carte forger ? (+1 niveau)")
		"puits":
			var i := await ui.choose("PUITS AUX SOUHAITS", "Des pièces brillent au fond. Vous avez %d or." % gold, [
				{"title": "Jeter 30 or", "glyph": "●", "text": "Une chance sur deux qu'une relique remonte.", "color": UI.GOLD},
			], true, "Garder son or")
			if i == 0:
				if gold < 30:
					ui.toast("Pas assez d'or.")
				else:
					gold -= 30
					if rng.randf() < 0.5:
						await _boon("relique")
					else:
						ui.toast("Rien ne remonte.")
		"cage":
			var i := await ui.choose("CAGE ROUILLÉE", "Un contrebandier y croupit, sa marchandise à ses pieds.", [
				{"title": "Le libérer", "glyph": "⌂","text": "Il vous laisse un équipement pour la peine.", "color": green},
				{"title": "Le rançonner", "glyph": "●", "text": "+60 or, mais il crie : chaque héros perd 4 PV.", "color": Color("#e0583a")},
			], true, "Passer son chemin")
			if i == 0:
				_gain_item(_roll_item(2))
			elif i == 1:
				gold += 60
				for h in heroes:
					h.hp = maxi(1, h.hp - 4)
		"autel":
			var big: Unit = heroes.reduce(func(a, b): return a if a.max_hp >= b.max_hp else b)
			var i := await ui.choose("AUTEL DE SANG", "La pierre a soif.", [
				{"title": "Offrir du sang", "glyph": "♦", "text": "%s perd 6 PV max ; une carte rare au choix." % big.nm, "color": Color("#e0583a")},
			], true, "Passer son chemin")
			if i == 0:
				big.base_hp -= 6
				big.apply_gear()
				await _boon("rare")
		"atelier":
			var i := await ui.choose("ATELIER EN RUINE", "Établis renversés, outils rouillés, poudre humide.", [
				{"title": "Récupérer", "glyph": "❖", "text": "Deux objets de besace.", "color": Color("#7fe0c8")},
				{"title": "Démonter", "glyph": "●", "text": "+45 or.", "color": UI.GOLD},
			], true, "Passer son chemin")
			if i == 0:
				_gain_tool(_tool_roll())
				_gain_tool(_tool_roll(3))
			elif i == 1:
				gold += 45
		"bibliotheque":
			var i := await ui.choose("BIBLIOTHÈQUE NOYÉE", "Des pages gonflées d'eau, quelques-unes lisibles.", [
				{"title": "Lire", "glyph": "✎", "text": "Une carte au choix parmi trois, niveau 2.", "color": Color("#6fb0e0")},
				{"title": "Brûler une page", "glyph": "✂", "text": "Retirer une carte du paquet.", "color": UI.GOLD},
			], true, "Passer son chemin")
			if i == 0:
				var opts: Array = []
				while opts.size() < 3:
					var id := _card_roll(1)
					if not opts.any(func(o): return o.card.id == id):
						opts.append({"card": {"id": id, "lvl": 2}})
				var j := await ui.choose("BIBLIOTHÈQUE", "Une carte pour le paquet", opts, true)
				if j >= 0:
					deck.append(opts[j].card)
			elif i == 1:
				var j := await ui.choose("BRÛLER", "Quelle carte retirer ?", deck.map(func(c): return {"card": c}), true)
				if j >= 0:
					deck.remove_at(j)
	ui.set_gold(gold)
	_explore_hud()


# ------------------------------------------------------------------ musique

func _music_vol() -> float:
	return -80.0 if _mute else -9.0


func play_music(kind: String) -> void:
	## « calme » : titre, cartes, exploration ; « combat » : combats. Fondu enchaîné.
	if kind == _music_kind or _music.is_empty():
		return
	_music_kind = kind
	var path := "res://assets/music/%s.mp3" % ("dark_is_the_sun" if kind == "combat" else "far_away")
	if not ResourceLoader.exists(path):
		path = "res://assets/music/dark_is_the_sun.mp3"  # la version en ligne n'a qu'un morceau
	if not ResourceLoader.exists(path):
		return
	var st: AudioStreamMP3 = load(path)
	st.loop = true
	var old: AudioStreamPlayer = _music[1]
	if old.stream == st and old.playing:
		return
	_music.reverse()
	var nw: AudioStreamPlayer = _music[1]
	nw.stream = st
	nw.volume_db = -40.0
	nw.play()
	var tw := create_tween().set_parallel()
	tw.tween_property(nw, "volume_db", _music_vol(), 1.5)
	tw.tween_property(old, "volume_db", -80.0, 1.5)
	tw.chain().tween_callback(func():
		if _music[0] == old:
			old.stop())
