class_name UI
extends CanvasLayer
## Interface : main de cartes, héros, énergie, étiquettes au-dessus des unités, écrans de choix.

signal picked(i: int)

const INK := Color("#efe6d2")
const DIM := Color("#a79d8b")
const GOLD := Color("#e3b45c")
const CARD := Vector2(164, 232)
const KIND_NAME := {"atk": "Attaque", "skill": "Technique", "move": "Mouvement", "power": "Pouvoir"}
const ICON := {
	"frappe": "⚔", "pavois": "🛡", "charge": "➤", "defi": "⚑", "rempart": "✠", "marteau": "⚒", "bastion": "🛡",
	"estoc": "†", "ombre": "☾", "double": "⚔", "venin": "☠", "couperet": "⚔", "ricochet": "↯",
	"braise": "✺", "seve": "✚", "colonne": "✹", "maree": "≋", "surveil": "◉", "delve": "⛏", "lotus": "✿",
}

var main: Node3D
var battle: Battle
var root: Control
var hud: Control
var hand_layer: Control
var header: Label
var sub: Label
var energy_lbl: Label
var pile_lbl: Label
var end_btn: Button
var tip: Label
var banner_box: VBoxContainer
var banner_title: Label
var banner_sub: Label
var toast_lbl: Label
var toast_plate: PanelContainer
var tip_plate: PanelContainer
var relic_row: HBoxContainer
var hero_box: VBoxContainer
var gold_lbl: Label
var frieze: HBoxContainer
var boss_bar: VBoxContainer
var hero_panels := {}
var tags := {}
var tag_layer: Control
var overlay: Control
var title_f: Font
var wide_f: FontVariation
var body_f: Font
var _hand_sig := ""
var _cards: Array = []
var _hover_card := -1
var sheet_plate: PanelContainer
var sheet_title: Label
var sheet_body: Label
var menu: Control
var powers_lbl: Label
var keys_plate: PanelContainer
var show_keys := false      # H : garder l'aide affichée
var explore_box: VBoxContainer
var explore_title: Label
var explore_sub: Label
var explore_party: Label
var besace_row: HBoxContainer
var _besace_sig := ""


func _ready() -> void:
	title_f = Fx.title_font()
	wide_f = FontVariation.new()
	wide_f.base_font = title_f
	wide_f.spacing_glyph = 14
	wide_f.fallbacks = title_f.fallbacks
	body_f = Fx.body_font()
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var th := Theme.new()
	th.default_font = body_f
	th.default_font_size = 15
	th.set_constant("line_spacing", "Label", -4)
	# infobulles lisibles : plaque sombre, texte clair et plus grand
	var tst := sb(Color(0.07, 0.065, 0.07, 0.96), GOLD.darkened(0.25), 8, 1, 8)
	tst.content_margin_left = 12
	tst.content_margin_right = 12
	tst.content_margin_top = 8
	tst.content_margin_bottom = 8
	th.set_stylebox("panel", "TooltipPanel", tst)
	th.set_font_size("font_size", "TooltipLabel", 16)
	th.set_color("font_color", "TooltipLabel", INK)
	root.theme = th
	add_child(root)
	tag_layer = _full(root)
	hud = _full(root)
	_build_hud()
	hand_layer = _full(hud)
	_build_banner()
	_build_explore()
	hud.visible = false


# ------------------------------------------------------------------ helpers

func _full(parent: Control) -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c


static func sb(bg: Color, border := Color(0, 0, 0, 0), radius := 10, bw := 0, shadow := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.anti_aliasing = true
	if shadow > 0:
		s.shadow_color = Color(0, 0, 0, 0.45)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, 3)
	return s


func _label(text: String, size: int, col: Color, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if font:
		l.add_theme_font_override("font", font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _shadowed(l: Label, outline := 6) -> Label:
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.03, 0.85))
	return l


func _panel(parent: Control, style: StyleBox) -> Panel:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", style)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


# ------------------------------------------------------------------ HUD

func _build_hud() -> void:
	var head := VBoxContainer.new()
	head.position = Vector2(28, 20)
	head.add_theme_constant_override("separation", 0)
	hud.add_child(head)
	header = _shadowed(_label("", 30, INK, title_f), 8)
	sub = _shadowed(_label("", 14, GOLD), 5)
	head.add_child(header)
	head.add_child(sub)

	gold_lbl = _shadowed(_label("", 20, Color("#ffd27a"), title_f), 6)
	gold_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	gold_lbl.position = Vector2(-200, 70)
	gold_lbl.size = Vector2(172, 26)
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(gold_lbl)

	relic_row = HBoxContainer.new()
	relic_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	relic_row.position = Vector2(-28, 24)
	relic_row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	relic_row.add_theme_constant_override("separation", 6)
	hud.add_child(relic_row)

	hero_box = VBoxContainer.new()
	hero_box.position = Vector2(24, 110)
	hero_box.add_theme_constant_override("separation", 10)
	hud.add_child(hero_box)

	# énergie
	var orb := Panel.new()
	orb.add_theme_stylebox_override("panel", _orb_style())
	orb.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	orb.position = Vector2(40, -150)
	orb.size = Vector2(104, 104)
	orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(orb)
	energy_lbl = _shadowed(_label("3", 44, Color("#2a1606"), title_f), 0)
	energy_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	energy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	orb.add_child(energy_lbl)
	pile_lbl = _shadowed(_label("", 15, INK), 6)
	pile_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	pile_lbl.position = Vector2(24, -40)
	pile_lbl.size = Vector2(160, 20)
	pile_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(pile_lbl)
	var pb := Button.new()
	pb.flat = true
	pb.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	pb.position = Vector2(24, -42)
	pb.size = Vector2(160, 24)
	pb.focus_mode = Control.FOCUS_NONE
	pb.tooltip_text = "Voir la pioche · P : tout le paquet"
	pb.pressed.connect(func(): main.view_deck("pioche"))
	hud.add_child(pb)
	besace_row = HBoxContainer.new()
	besace_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	besace_row.position = Vector2(24, -246)
	besace_row.add_theme_constant_override("separation", 6)
	hud.add_child(besace_row)
	powers_lbl = _shadowed(_label("", 14, Color("#d8c3ff")), 6)
	powers_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	powers_lbl.position = Vector2(24, -186)
	powers_lbl.size = Vector2(380, 20)
	hud.add_child(powers_lbl)

	end_btn = Button.new()
	end_btn.text = "Fin du tour"
	end_btn.add_theme_font_override("font", title_f)
	end_btn.add_theme_font_size_override("font_size", 22)
	end_btn.add_theme_color_override("font_color", Color("#2a1606"))
	end_btn.add_theme_color_override("font_hover_color", Color("#1a0d02"))
	end_btn.add_theme_color_override("font_disabled_color", Color(0.3, 0.25, 0.2))
	end_btn.add_theme_stylebox_override("normal", sb(GOLD, Color("#fff0c8"), 12, 2, 8))
	end_btn.add_theme_stylebox_override("hover", sb(GOLD.lightened(0.18), Color("#fff6dc"), 12, 2, 10))
	end_btn.add_theme_stylebox_override("pressed", sb(GOLD.darkened(0.15), Color("#fff0c8"), 12, 2, 4))
	end_btn.add_theme_stylebox_override("disabled", sb(Color(0.35, 0.3, 0.25, 0.8), Color(0.5, 0.45, 0.4), 12, 2, 0))
	end_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	end_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	end_btn.position = Vector2(-230, -118)
	end_btn.size = Vector2(190, 58)
	end_btn.pressed.connect(func(): battle.end_turn())
	end_btn.focus_mode = Control.FOCUS_NONE
	hud.add_child(end_btn)
	var hint := _shadowed(_label("Espace", 12, DIM))
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.position = Vector2(-230, -54)
	hint.size = Vector2(190, 18)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(hint)

	# aide des commandes : une touche, une action, lisible d'un coup d'œil
	var keys := _plate(hud)
	keys_plate = keys
	keys.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	keys.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	keys.grow_vertical = Control.GROW_DIRECTION_BEGIN
	keys.offset_left = -40
	keys.offset_top = -140
	keys.offset_right = -40
	keys.offset_bottom = -140
	var kv := VBoxContainer.new()
	kv.add_theme_constant_override("separation", 6)
	kv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keys.add_child(kv)
	kv.add_child(_shadowed(_label("Commandes", 16, GOLD, title_f), 4))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 3)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kv.add_child(grid)
	for row in [["Clic", "héros, carte, case, objet de besace"], ["Clic ennemi", "épingler / retirer sa fiche"],
			["Survol", "infos de la case ou de l'objet"], ["Clic droit", "annuler · maintenu : caméra"],
			["ZQSD", "déplacer la caméra (clic droit tenu)"], ["Q / E · molette", "pivoter · zoomer"],
			["Espace", "fin du tour"], ["Tab · 1 à 9", "héros suivant · jouer une carte"],
			["Alt", "montrer les objets interactifs"], ["P · M", "paquet · musique"], ["H · Échap", "cette aide · menu"]]:
		var k := _label(row[0], 14, Color("#ffe3a3"), title_f)
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(k)
		grid.add_child(_label(row[1], 14, INK))

	# fiche d'unité, à droite
	sheet_plate = _plate(hud)
	sheet_plate.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	sheet_plate.offset_left = -348
	sheet_plate.offset_right = -24
	sheet_plate.offset_top = 108
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 6)
	sv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet_plate.add_child(sv)
	sheet_title = _shadowed(_label("", 21, INK, title_f), 4)
	sv.add_child(sheet_title)
	sheet_body = _label("", 14, INK)
	sheet_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sheet_body.custom_minimum_size = Vector2(296, 0)
	sv.add_child(sheet_body)
	sheet_plate.visible = false

	# frise de tour : qui agit, dans quel ordre, avec quelle intention
	frieze = HBoxContainer.new()
	frieze.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	frieze.position = Vector2(-300, 18)
	frieze.size = Vector2(600, 56)
	frieze.alignment = BoxContainer.ALIGNMENT_CENTER
	frieze.add_theme_constant_override("separation", 6)
	frieze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(frieze)

	boss_bar = VBoxContainer.new()
	boss_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	boss_bar.position = Vector2(-300, 82)
	boss_bar.size = Vector2(600, 40)
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(boss_bar)
	var bn := _shadowed(_label("Le Gardien des ruines", 18, Color("#ffc48a"), title_f), 6)
	bn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_bar.add_child(bn)
	var bb := ProgressBar.new()
	bb.show_percentage = false
	bb.custom_minimum_size = Vector2(600, 14)
	bb.add_theme_stylebox_override("background", sb(Color(0, 0, 0, 0.7), Color(1, 0.5, 0.25, 0.6), 4, 1))
	bb.add_theme_stylebox_override("fill", sb(Color("#e0582a"), Color(0, 0, 0, 0), 4))
	boss_bar.add_child(bb)
	boss_bar.set_meta("bar", bb)
	boss_bar.visible = false

	tip_plate = _plate(hud)
	tip_plate.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_pin_bottom(tip_plate, -256)
	tip_plate.z_index = 70  # au-dessus d'une carte survolée
	tip = _label("", 17, INK)
	tip_plate.add_child(tip)


func _build_explore() -> void:
	explore_box = VBoxContainer.new()
	explore_box.position = Vector2(28, 20)
	explore_box.add_theme_constant_override("separation", 2)
	explore_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(explore_box)
	explore_title = _shadowed(_label("", 30, INK, title_f), 8)
	explore_sub = _shadowed(_label("", 14, GOLD), 5)
	explore_party = _shadowed(_label("", 15, INK), 6)
	explore_box.add_child(explore_title)
	explore_box.add_child(explore_sub)
	explore_box.add_child(explore_party)
	var hint := _plate(explore_box)
	hint.add_child(_label("Clic : avancer · croiser un monstre lance le combat · clic droit maintenu : caméra · P : paquet · Échap : menu", 12, DIM))
	explore_box.visible = false


func show_explore(on: bool, title := "", sub := "", party := "") -> void:
	explore_box.visible = on
	if on:
		explore_title.text = title
		explore_sub.text = sub
		explore_party.text = party


func _orb_style() -> StyleBoxFlat:
	var s := sb(Color("#e8a33c"), Color("#ffe3a3"), 52, 3, 14)
	s.shadow_color = Color(1.0, 0.55, 0.15, 0.45)
	s.shadow_offset = Vector2.ZERO
	return s


func _build_banner() -> void:
	banner_box = VBoxContainer.new()
	banner_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner_box.position = Vector2(-400, 150)
	banner_box.size = Vector2(800, 100)
	banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_box.modulate.a = 0
	root.add_child(banner_box)
	banner_title = _shadowed(_label("", 52, INK, wide_f), 12)
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_sub = _shadowed(_label("", 16, GOLD), 6)
	banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_box.add_child(banner_title)
	banner_box.add_child(banner_sub)
	toast_plate = _plate(root)
	toast_plate.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_pin_bottom(toast_plate, -318)
	toast_plate.modulate.a = 0
	toast_lbl = _label("", 17, Color("#ffe2bf"))
	toast_plate.add_child(toast_lbl)


func banner(title: String, subtitle := "") -> void:
	banner_title.text = title
	banner_sub.text = subtitle
	var tw := create_tween()
	banner_box.position.y = 130
	tw.tween_property(banner_box, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(banner_box, "position:y", 150.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.9)
	tw.tween_property(banner_box, "modulate:a", 0.0, 0.4)


func toast(text: String) -> void:
	toast_lbl.text = text
	_fit(toast_plate)
	var tw := create_tween()
	tw.tween_property(toast_plate, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.4)
	tw.tween_property(toast_plate, "modulate:a", 0.0, 0.4)


func announce(c: Dictionary) -> void:
	toast("%s — %s" % [Data.HEROES[c.owner].name, c.name])


func set_gold(g: int) -> void:
	gold_lbl.text = "%d or" % g


func set_header(title: String, subtitle: String) -> void:
	header.text = title
	sub.text = subtitle


func set_sheet(u: Unit) -> void:
	sheet_plate.visible = u != null and is_instance_valid(u) and u.alive
	if not sheet_plate.visible:
		return
	var col: Color = Data.CLASS_COLOR.get(u.key, Color("#ff8a1e")) if u.side == "hero" else Color("#ff9a3c")
	sheet_title.text = u.nm + ("   · épinglé" if u == battle.inspect else "")
	sheet_title.add_theme_color_override("font_color", col.lightened(0.25))
	sheet_body.text = battle.sheet(u)
	sheet_plate.reset_size()


func menu_open() -> bool:
	return menu != null and is_instance_valid(menu)


func toggle_menu() -> void:
	## Pause : reprendre, abandonner la run (retour au titre) ou quitter.
	if menu_open():
		menu.queue_free()
		menu = null
		return
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.z_index = 100  # au-dessus des cartes de la main
	root.add_child(menu)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.03, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(box)
	var t := _shadowed(_label("PAUSE", 56, INK, wide_f), 12)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var first: Button
	for e in [["Reprendre", func(): toggle_menu()], ["Abandonner la run", func(): main.abandon()], ["Quitter le jeu", func(): get_tree().quit()]]:
		var b := Button.new()
		b.text = e[0]
		b.add_theme_font_override("font", title_f)
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_color_override("font_color", INK)
		b.add_theme_color_override("font_focus_color", Color("#2a1606"))
		b.add_theme_color_override("font_hover_color", Color("#2a1606"))
		b.add_theme_stylebox_override("normal", sb(Color(0.08, 0.07, 0.075, 0.92), GOLD.darkened(0.3), 12, 2, 6))
		b.add_theme_stylebox_override("hover", sb(GOLD, Color("#fff0c8"), 12, 2, 8))
		b.add_theme_stylebox_override("focus", sb(GOLD, Color("#fff0c8"), 12, 2, 8))
		b.add_theme_stylebox_override("pressed", sb(GOLD.darkened(0.15), Color("#fff0c8"), 12, 2, 4))
		b.custom_minimum_size = Vector2(340, 58)
		b.pressed.connect(e[1])
		var c := CenterContainer.new()
		c.add_child(b)
		box.add_child(c)
		if first == null:
			first = b
	# volume de la musique
	var vr := HBoxContainer.new()
	vr.alignment = BoxContainer.ALIGNMENT_CENTER
	vr.add_theme_constant_override("separation", 14)
	var vl := _shadowed(_label("Musique", 20, INK, title_f), 6)
	vr.add_child(vl)
	var sl := HSlider.new()
	sl.min_value = 0
	sl.max_value = 100
	sl.step = 1
	sl.value = main.music_vol * 100.0
	sl.custom_minimum_size = Vector2(240, 28)
	sl.add_theme_stylebox_override("slider", sb(Color(0, 0, 0, 0.6), GOLD.darkened(0.3), 6, 1))
	sl.add_theme_stylebox_override("grabber_area", sb(GOLD.darkened(0.1), Color(0, 0, 0, 0), 6))
	sl.add_theme_stylebox_override("grabber_area_highlight", sb(GOLD, Color(0, 0, 0, 0), 6))
	var pct := _shadowed(_label("%d %%" % int(sl.value), 16, DIM), 5)
	pct.custom_minimum_size = Vector2(52, 0)
	sl.value_changed.connect(func(v: float):
		pct.text = "%d %%" % int(v)
		main.set_music_volume(v / 100.0))
	vr.add_child(sl)
	vr.add_child(pct)
	box.add_child(vr)
	var hint := _label("M : couper / remettre la musique", 13, DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	first.grab_focus()


func set_tip(t: String) -> void:
	tip.text = t
	tip_plate.visible = t != ""
	_fit(tip_plate)


func _plate(parent: Control) -> PanelContainer:
	## Plaque sombre centrée : le texte ne flotte jamais seul sur la scène.
	var p := PanelContainer.new()
	var st := sb(Color(0.06, 0.055, 0.06, 0.86), Color(1, 0.85, 0.6, 0.25), 8, 1, 6)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 6
	st.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", st)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


func _pin_bottom(p: Control, y: float) -> void:
	## Ancré en bas au centre, grandit vers le haut : ne sort jamais de l'écran.
	p.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	p.offset_top = y
	p.offset_bottom = y


func _fit(p: PanelContainer) -> void:
	p.reset_size()
	var w := p.get_combined_minimum_size().x
	p.offset_left = -w * 0.5
	p.offset_right = w * 0.5


func show_hud(on: bool) -> void:
	hud.visible = on
	tag_layer.visible = on
	if on:
		_rebuild_heroes()
		refresh()


# ------------------------------------------------------------------ héros et reliques

func _rebuild_heroes() -> void:
	for c in hero_box.get_children():
		c.queue_free()
	hero_panels.clear()
	for h in battle.heroes:
		var col: Color = Data.CLASS_COLOR[h.key]
		var p := Panel.new()
		p.custom_minimum_size = Vector2(270, 78)
		p.add_theme_stylebox_override("panel", sb(Color(0.07, 0.065, 0.07, 0.78), col.darkened(0.2), 10, 1, 6))
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and h.alive:
				battle.select(h))
		hero_box.add_child(p)
		var badge := _panel(p, sb(col, col.lightened(0.4), 8, 2))
		badge.position = Vector2(12, 13)
		badge.size = Vector2(52, 52)
		var por := TextureRect.new()
		por.texture = load("res://assets/art/portrait_%s.png" % h.key)
		por.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		por.offset_left = 3
		por.offset_top = 3
		por.offset_right = -3
		por.offset_bottom = -3
		por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		por.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(por)
		var nm := _label(h.nm, 19, INK, title_f)
		nm.position = Vector2(76, 6)
		p.add_child(nm)
		var tr := _label(Data.TRAITS[h.trait_id].name, 12, col.lightened(0.45))
		tr.position = Vector2(76, 30)
		var tip_txt: String = "%s : %s" % [Data.TRAITS[h.trait_id].name, Data.TRAITS[h.trait_id].text]
		for q in h.passives():
			tip_txt += "\n%s : %s" % [Data.PASSIVES[q].name, Data.PASSIVES[q].text]
		tr.tooltip_text = tip_txt
		p.tooltip_text = tip_txt
		if h.passives().size() > 0:
			tr.text += "  ·  " + ", ".join(h.passives().map(func(q): return Data.PASSIVES[q].name))
		tr.mouse_filter = Control.MOUSE_FILTER_PASS
		p.add_child(tr)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.position = Vector2(76, 52)
		bar.size = Vector2(180, 12)
		bar.add_theme_stylebox_override("background", sb(Color(0, 0, 0, 0.55), Color(0, 0, 0, 0), 5))
		bar.add_theme_stylebox_override("fill", sb(col, Color(0, 0, 0, 0), 5))
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(bar)
		var hp := _shadowed(_label("", 12, INK), 4)
		hp.position = Vector2(76, 50)
		hp.size = Vector2(180, 16)
		hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_child(hp)
		var st := _label("", 12, DIM)
		st.position = Vector2(150, 12)
		st.size = Vector2(108, 16)
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		p.add_child(st)
		hero_panels[h] = {"panel": p, "bar": bar, "hp": hp, "st": st, "col": col}


func _refresh_heroes() -> void:
	for h in hero_panels:
		var d: Dictionary = hero_panels[h]
		d.bar.max_value = h.max_hp
		d.bar.value = h.hp
		d.hp.text = "%d / %d" % [h.hp, h.max_hp] if h.alive else "tombé"
		var s := ""
		if h.block > 0:
			s += "🛡 %d  " % h.block
		s += "a bougé" if h.moved else "peut bouger"
		d.st.text = s if h.alive else ""
		var sel: bool = battle.selected == h
		d.panel.add_theme_stylebox_override("panel", sb(Color(0.1, 0.09, 0.08, 0.88) if sel else Color(0.07, 0.065, 0.07, 0.78), GOLD if sel else d.col.darkened(0.2), 10, 2 if sel else 1, 6))
		d.panel.modulate = Color(1, 1, 1, 1) if h.alive else Color(0.5, 0.5, 0.5, 0.8)


func refresh_relics(relics: Array) -> void:
	for c in relic_row.get_children():
		c.queue_free()
	for r in relics:
		var p := Panel.new()
		p.custom_minimum_size = Vector2(40, 40)
		p.add_theme_stylebox_override("panel", sb(Color(0.08, 0.07, 0.07, 0.85), GOLD.darkened(0.2), 20, 2, 4))
		p.tooltip_text = "%s\n%s" % [Data.RELICS[r].name, Data.RELICS[r].text]
		var g := _label(Data.RELICS[r].glyph, 20, GOLD)
		g.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		g.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p.add_child(g)
		relic_row.add_child(p)


# ------------------------------------------------------------------ rafraîchissement

func refresh() -> void:
	if not hud.visible:
		return
	if hero_panels.size() != battle.heroes.size():
		_rebuild_heroes()
	_refresh_heroes()
	_refresh_frieze()
	energy_lbl.text = str(battle.energy)
	pile_lbl.text = "Pioche %d · Défausse %d" % [battle.draw_pile.size(), battle.discard.size()]
	var pw: Array = []
	for id in Data.CARDS:
		if Data.CARDS[id].get("power", "") in battle.powers:
			pw.append(Data.CARDS[id].name)
	powers_lbl.text = ("Pouvoirs : " + " · ".join(pw)) if pw.size() > 0 else ""
	end_btn.disabled = not battle.player_turn or battle.busy
	keys_plate.visible = battle.turn <= 1 or show_keys
	var bsig := "%s|%d|%d|%d" % [JSON.stringify(battle.besace), battle.tool_sel, battle.besace_cap(), battle.bricole]
	if bsig != _besace_sig:
		_besace_sig = bsig
		_rebuild_besace()
	var sig := JSON.stringify(battle.hand)
	if sig != _hand_sig:
		_hand_sig = sig
		_rebuild_hand()
	for i in _cards.size():
		var c := Data.card(battle.hand[i])
		var h := battle.owner_of(c)
		var ok: bool = h and h.alive and battle.cost_of(c) <= battle.energy and battle.player_turn
		_cards[i].modulate = Color.WHITE if ok else Color(0.55, 0.53, 0.5)
		var orb_l: Label = _cards[i].get_meta("cost")
		orb_l.text = str(battle.cost_of(c))
		(_cards[i].get_meta("live") as Control).visible = ok and battle.trig_live(c)
	_sync_tags()
	main.refresh_hover()


func _rebuild_besace() -> void:
	## Besace : une case par place ; clic sur un objet, puis sur sa cible.
	for c in besace_row.get_children():
		c.queue_free()
	var edge := Color("#7fe0c8")
	for i in battle.besace_cap():
		var b := Button.new()
		b.custom_minimum_size = Vector2(48, 48)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_override("font", title_f)
		b.add_theme_font_size_override("font_size", 24)
		var full := i < battle.besace.size()
		var sel := full and i == battle.tool_sel
		var st := sb(Color(0.08, 0.07, 0.075, 0.9) if full else Color(0.05, 0.05, 0.05, 0.45), GOLD if sel else (edge.darkened(0.25) if full else Color(1, 1, 1, 0.12)), 10, 3 if sel else (2 if full else 1), 4)
		b.add_theme_stylebox_override("normal", st)
		b.add_theme_stylebox_override("disabled", st)
		b.add_theme_stylebox_override("hover", sb(Color(0.12, 0.2, 0.18, 0.95), Color.WHITE, 10, 2, 6))
		b.add_theme_stylebox_override("pressed", sb(Color(0.12, 0.2, 0.18, 0.95), GOLD, 10, 3, 2))
		b.add_theme_color_override("font_color", Color("#dff8ee"))
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		if full:
			var td: Dictionary = Data.TOOLS[battle.besace[i]]
			b.text = td.glyph
			b.tooltip_text = "%s\n%s\n(clic, puis la cible · sans énergie · héros sélectionné)" % [td.name, td.text]
			var idx := i
			b.pressed.connect(func(): battle.select_tool(idx))
		else:
			b.disabled = true
			b.tooltip_text = "Place libre dans la besace"
		besace_row.add_child(b)
	if battle.heroes.any(func(h): return h.key == "receleur"):
		var bl := _shadowed(_label("Bricole " + "●".repeat(battle.bricole) + "○".repeat(3 - battle.bricole), 13, Data.CLASS_COLOR.receleur.lightened(0.35)), 5)
		bl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		besace_row.add_child(bl)


func _rebuild_hand() -> void:
	for c in _cards:
		c.queue_free()
	_cards.clear()
	_hover_card = -1
	for i in battle.hand.size():
		var card := make_card(battle.hand[i])
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx := i
		card.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				battle.select_card(idx))
		card.mouse_entered.connect(func(): _hover_card = idx)
		card.mouse_exited.connect(func():
			if _hover_card == idx:
				_hover_card = -1)
		var vp := root.size
		card.position = Vector2(vp.x * 0.5 - CARD.x * 0.5, vp.y + 40)
		hand_layer.add_child(card)
		_cards.append(card)


func make_card(ci: Dictionary) -> Control:
	var c := Data.card(ci)
	var col: Color = Data.CLASS_COLOR[c.owner]
	var card := Control.new()
	card.size = CARD
	card.custom_minimum_size = CARD
	card.pivot_offset = Vector2(CARD.x * 0.5, CARD.y)
	var bg := _panel(card, sb(Color("#1b181d"), col.darkened(0.05), 12, 2, 10))
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var inner := _panel(card, sb(Color(0, 0, 0, 0), Color(1, 0.9, 0.7, 0.12), 9, 1))
	inner.position = Vector2(5, 5)
	inner.size = CARD - Vector2(10, 10)
	var art := TextureRect.new()
	var path := "res://assets/art/card_%s.png" % c.id
	art.texture = load(path) if ResourceLoader.exists(path) else _art(col, c.kind)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.clip_contents = true
	art.position = Vector2(12, 36)
	art.size = Vector2(CARD.x - 24, 96)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(art)
	var lvc: int = c.get("lvl", 1)
	var fcol: Color = Color("#ffcf5a") if lvc >= 5 else (Color("#d8e0e8") if lvc >= 3 else col.lightened(0.25))
	var frame := _panel(card, sb(Color(0, 0, 0, 0), fcol, 4, 3 if lvc >= 3 else 1))
	frame.position = art.position
	frame.size = art.size
	var nm := _label(c.name, 16 if c.name.length() <= 12 else (14 if c.name.length() <= 15 else 13), INK, title_f)
	nm.position = Vector2(36, 8)
	nm.size = Vector2(CARD.x - 58, 24)
	nm.clip_text = true
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(nm)
	var orb := _panel(card, sb(Color("#e8a33c"), Color("#fff0c8"), 17, 2, 4))
	orb.position = Vector2(-7, -7)
	orb.size = Vector2(36, 36)
	var cl := _label(str(c.cost), 20, Color("#2a1606"), title_f)
	cl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	orb.add_child(cl)
	card.set_meta("cost", cl)
	var lv: int = c.get("lvl", 1)
	var lvl_l := _shadowed(_label("niv %d" % lv, 11, Color("#ffe3a3") if lv >= 3 else DIM, title_f), 4)
	lvl_l.position = Vector2(-6, 30)
	lvl_l.visible = false
	var pips := _shadowed(_label("●".repeat(lv) + "○".repeat(5 - lv), 12, Color("#ffcf5a") if lv >= 5 else (Color("#e8eef4") if lv >= 3 else DIM)), 4)
	pips.position = Vector2(0, 118)
	pips.size = Vector2(CARD.x, 16)
	pips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(pips)
	lvl_l.size = Vector2(36, 14)
	lvl_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(lvl_l)
	var live := _panel(card, sb(Color(0, 0, 0, 0), Color(1.0, 0.82, 0.35), 13, 3, 16))
	live.position = Vector2(-3, -3)
	live.size = CARD + Vector2(6, 6)
	live.visible = false
	card.set_meta("live", live)
	card.tooltip_text = Data.keyword_tip(c)
	var rar: int = c.get("rar", 1)
	var gem := _label("◆", 15, Data.RARITY_COL[rar], title_f)
	gem.position = Vector2(CARD.x - 22, 9)
	card.add_child(gem)
	if rar > 1:
		nm.add_theme_color_override("font_color", Data.RARITY_COL[rar].lightened(0.25))
		gem.add_theme_font_size_override("font_size", 19 if rar == 3 else 15)
	var kl := _label("%s · %s" % [KIND_NAME[c.kind], Data.VOIX[c.voix][0] if c.has("voix") else Data.HEROES[c.owner].name], 11, Data.VOIX[c.voix][1].lightened(0.3) if c.has("voix") else col.lightened(0.45))
	kl.position = Vector2(8, 136)
	kl.size = Vector2(CARD.x - 16, 16)
	kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(kl)
	var txt := Data.card_text(c)
	var tx := _label(txt, 14 if txt.length() <= 46 else (13 if txt.length() <= 64 else 12), INK)
	tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tx.position = Vector2(12, 156)
	tx.size = Vector2(CARD.x - 24, 70)
	tx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(tx)
	return card


static var _arts := {}
func _art(col: Color, kind: String) -> Texture2D:
	var key := "%s%s" % [col.to_html(), kind]
	if _arts.has(key):
		return _arts[key]
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([col.lightened(0.35), col.darkened(0.2), col.darkened(0.75)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.45)
	t.fill_to = Vector2(1.1, 1.1)
	t.width = 128
	t.height = 80
	_arts[key] = t
	return t


func _process(dt: float) -> void:
	if not hud.visible:
		return
	_layout_hand(dt)
	_place_tags()


func _layout_hand(dt: float) -> void:
	var n := _cards.size()
	if n == 0:
		return
	var vp := root.size
	var spacing := minf(146.0, 900.0 / n)
	var k := 1.0 - exp(-dt * 14.0)
	for i in n:
		var card: Control = _cards[i]
		var off := i - (n - 1) * 0.5
		var pos := Vector2(vp.x * 0.5 + off * spacing - CARD.x * 0.5, vp.y - CARD.y - 8 + off * off * 3.0)
		var rot := off * 0.03
		var sc := 0.84
		var z := i
		if i == battle.card_sel:
			pos.y -= 40
			rot = 0.0
			sc = 0.98
			z = 50
		if i == _hover_card:
			pos.y -= 60
			rot = 0.0
			sc = 1.12
			z = 60
		card.position = card.position.lerp(pos, k)
		card.rotation = lerpf(card.rotation, rot, k)
		card.scale = card.scale.lerp(Vector2.ONE * sc, k)
		card.z_index = z


# ------------------------------------------------------------------ frise de tour

func _refresh_frieze() -> void:
	for c in frieze.get_children():
		c.queue_free()
	var boss: Unit = null
	var units: Array = battle.alive_heroes() + battle.alive_foes()
	for u in units:
		if u.key == "gardien":
			boss = u
		var col: Color = Data.CLASS_COLOR.get(u.key, Color("#c9463a"))
		var p := PanelContainer.new()
		var st := sb(Color(0.07, 0.06, 0.065, 0.88), col, 6, 2 if u == battle.selected else 1, 4)
		st.content_margin_left = 6
		st.content_margin_right = 6
		st.content_margin_top = 2
		st.content_margin_bottom = 2
		p.add_theme_stylebox_override("panel", st)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l := _label("", 13, INK, title_f)
		if u.side == "hero":
			l.text = u.nm + ("" if not u.moved else " ·")
		else:
			l.text = "%s %s" % [u.nm.split(" ")[0], battle.intent(u)]
			l.add_theme_color_override("font_color", Color("#ffc48a"))
		p.add_child(l)
		frieze.add_child(p)
		if u.side == "hero" and units.find(u) == battle.alive_heroes().size() - 1:
			var sep := _label("⟩", 18, GOLD, title_f)
			frieze.add_child(sep)
	boss_bar.visible = boss != null
	if boss:
		var bb: ProgressBar = boss_bar.get_meta("bar")
		bb.max_value = boss.max_hp
		bb.value = boss.hp


# ------------------------------------------------------------------ étiquettes des unités

func _sync_tags() -> void:
	var all: Array = battle.heroes + battle.foes
	for u in tags.keys():
		if not all.has(u) or not is_instance_valid(u):
			tags[u].queue_free()
			tags.erase(u)
	for u in all:
		if not tags.has(u):
			tags[u] = _make_tag(u)
		var t: Control = tags[u]
		var bar: ProgressBar = t.get_meta("bar")
		bar.max_value = u.max_hp
		bar.value = u.hp
		var lbl: Label = t.get_meta("hp")
		lbl.text = str(u.hp) + ("  🛡%d" % u.block if u.block > 0 else "") + ("  ☠%d" % u.poison if u.poison > 0 else "") \
			+ ("  ◎" if u.mark > 0 else "") + ("  ⛓" if u.root > 0 else "")
		var pv: Label = t.get_meta("pv")
		var pr := battle.predict(u, main.hover)
		if pr.is_empty():
			pv.text = ""
		else:
			var after := maxi(0, u.hp - maxi(0, pr.dmg - u.block))
			var tag := ""
			for n in pr.notes:
				if n.begins_with("dos"):
					tag = "  DOS"
				elif n.begins_with("flanc") and tag == "":
					tag = "  FLANC"
			pv.text = "%d → %d%s" % [u.hp, after, tag]
		var it: Label = t.get_meta("intent")
		it.text = battle.intent(u) if u.side == "foe" else ""
		it.visible = it.text != ""


func _make_tag(u: Unit) -> Control:
	var t := Control.new()
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size = Vector2(70, 40)
	tag_layer.add_child(t)
	var it := _label("", 19, Color("#ffc48a"), title_f)
	it.position = Vector2(5, -24)
	it.size = Vector2(60, 28)
	it.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	it.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var ist := sb(Color(0.12, 0.03, 0.02, 0.85), Color(1.0, 0.45, 0.25, 0.8), 6, 1, 4)
	it.add_theme_stylebox_override("normal", ist)
	t.add_child(it)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.position = Vector2(-1, 10)
	bar.size = Vector2(72, 14)
	var hero := u.side == "hero"
	var fill_col: Color = Data.CLASS_COLOR.get(u.key, Color("#d2452f")) if hero else Color("#ff8a1e")
	bar.add_theme_stylebox_override("background", sb(Color(0, 0, 0, 0.75), Color(0.95, 0.92, 0.85, 0.95) if hero else Color(0.25, 0.05, 0.02, 0.95), 4, 2 if hero else 1))
	bar.add_theme_stylebox_override("fill", sb(fill_col, Color(0, 0, 0, 0), 4))
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_child(bar)
	var hp := _shadowed(_label("", 12, Color.WHITE, title_f), 4)
	hp.position = Vector2(-20, 8)
	hp.size = Vector2(110, 18)
	hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_child(hp)
	var pv := _shadowed(_label("", 15, Color("#ffe08a"), title_f), 6)
	pv.position = Vector2(-40, 26)
	pv.size = Vector2(150, 20)
	pv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_child(pv)
	t.set_meta("pv", pv)
	t.set_meta("bar", bar)
	t.set_meta("hp", hp)
	t.set_meta("intent", it)
	return t


func _place_tags() -> void:
	var cam: Camera3D = main.cam
	for u in tags:
		var t: Control = tags[u]
		if not is_instance_valid(u) or not u.alive:
			t.visible = false
			continue
		var p: Vector3 = u.global_position + Vector3(0, u.head, 0)
		if cam.is_position_behind(p):
			t.visible = false
			continue
		t.visible = true
		t.position = cam.unproject_position(p) - Vector2(35, 20)
	# pile : une étiquette qui en recouvre une autre descend d'un cran ; rien sous la frise ni la barre du boss
	var top := 158.0 if boss_bar.visible else 118.0
	var vis: Array = tags.values().filter(func(t): return t.visible)
	vis.sort_custom(func(a, b): return a.position.y < b.position.y)
	for i in vis.size():
		var t: Control = vis[i]
		t.position.y = maxf(t.position.y, top)
		for j in i:
			var o: Control = vis[j]
			if absf(o.position.x - t.position.x) < 74.0 and absf(o.position.y - t.position.y) < 46.0:
				t.position.y = o.position.y + 46.0


# ------------------------------------------------------------------ écrans de choix

var last_n := 0            # nombre d'options du dernier choix (pilote de test)
func choose(title: String, subtitle: String, options: Array, allow_skip := false, skip_text := "Passer") -> int:
	_close_overlay()
	last_n = options.size()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100  # au-dessus des cartes de la main
	root.add_child(overlay)
	var opened := Time.get_ticks_msec()
	var fresh := func() -> bool: return Time.get_ticks_msec() - opened < 300  # le clic de l'écran précédent ne valide pas celui-ci
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.04, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(box)
	var tl := _shadowed(_label(title, 44, INK, wide_f), 10)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tl)
	var sl := _shadowed(_label(subtitle, 16, GOLD), 6)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sl)
	var many: bool = options.size() > 7 and options[0].has("card")
	var row: Container
	if many:
		var grid := GridContainer.new()
		grid.columns = 8
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 14)
		var sc := ScrollContainer.new()
		sc.custom_minimum_size = Vector2(1400, 600)
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var cc := CenterContainer.new()
		cc.custom_minimum_size = Vector2(1390, 0)
		cc.add_child(grid)
		sc.add_child(cc)
		var sco := CenterContainer.new()
		sco.add_child(sc)
		box.add_child(sco)
		row = grid
	else:
		var hb := HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_theme_constant_override("separation", 26 if options.size() <= 6 else 12)
		box.add_child(hb)
		row = hb
	for i in options.size():
		var o: Dictionary = options[i]
		var w: Control
		if o.has("card"):
			w = make_card(o.card)
			var holder := Control.new()
			var sc_k := 0.8 if many else 1.2
			holder.custom_minimum_size = CARD * sc_k
			holder.tooltip_text = w.tooltip_text
			w.scale = Vector2.ONE * sc_k
			w.pivot_offset = Vector2.ZERO
			holder.add_child(w)
			if o.has("tag"):
				w.position.y = 38
				holder.custom_minimum_size.y += 38
				var tg := _shadowed(_label(o.tag, 22, GOLD if o.tag == "Après" else DIM, title_f), 6)
				tg.position = Vector2(0, 0)
				tg.size = Vector2(CARD.x * sc_k, 30)
				tg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				holder.add_child(tg)
			_passthrough(w)
			w = holder
		else:
			w = _option(o, 250 if options.size() <= 4 else (205 if options.size() <= 6 else (186 if options.size() <= 7 else 170)))
		w.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx := i
		w.focus_mode = Control.FOCUS_ALL
		w.gui_input.connect(func(e):
			if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or e.is_action_pressed("ui_accept"):
				w.accept_event()
				if not fresh.call():
					picked.emit(idx))
		w.mouse_entered.connect(func(): w.modulate = Color(1.15, 1.1, 1.0))
		w.mouse_exited.connect(func(): w.modulate = Color.WHITE)
		w.focus_entered.connect(func(): w.modulate = Color(1.2, 1.12, 0.95))
		w.focus_exited.connect(func(): w.modulate = Color.WHITE)
		row.add_child(w)
		if i == 0 and Input.get_connected_joypads().size() > 0:
			w.grab_focus.call_deferred()
	if allow_skip:
		var sk := Button.new()
		sk.text = skip_text
		sk.flat = true
		sk.add_theme_color_override("font_color", DIM)
		sk.add_theme_font_size_override("font_size", 16)
		sk.pressed.connect(func():
			if not fresh.call():
				picked.emit(-1))
		var c := CenterContainer.new()
		c.add_child(sk)
		box.add_child(c)
	overlay.modulate.a = 0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.25)
	var i: int = await picked
	_close_overlay()
	return i


func map_screen(title: String, subtitle: String, fmap: Array, step: int, lane: int, nexts: Array, visited: Array, equip_txt: String) -> int:
	## Carte de l'étage : salles déjà faites, chemins ouverts, suite du parcours jusqu'au gardien.
	_close_overlay()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.04, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(box)
	var tl := _shadowed(_label(title, 44, INK, wide_f), 10)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tl)
	var sl := _shadowed(_label(subtitle, 16, GOLD), 6)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sl)
	var area := Control.new()
	area.custom_minimum_size = Vector2(1000, 440)
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ac := CenterContainer.new()
	ac.add_child(area)
	box.add_child(ac)
	var info := _shadowed(_label("Choisissez la prochaine salle.", 17, INK), 6)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.custom_minimum_size = Vector2(0, 52)
	box.add_child(info)
	var pos := func(k: int, i: int) -> Vector2:
		var n: int = fmap[k].size()
		return Vector2(90 + k * 205, 220 + (i - (n - 1) * 0.5) * 150)
	for k in fmap.size() - 1:
		for i in fmap[k].size():
			for j in fmap[k][i].links:
				var ln := Line2D.new()
				ln.points = PackedVector2Array([pos.call(k, i), pos.call(k + 1, j)])
				var trod: bool = visited.has(Vector2i(k, i)) and visited.has(Vector2i(k + 1, j))
				var open: bool = k == step - 1 and i == lane and nexts.has(j)
				ln.width = 5.0 if trod or open else 3.0
				ln.default_color = GOLD if open else (INK if trod else Color(1, 1, 1, 0.16))
				area.add_child(ln)
	var first: Button
	for k in fmap.size():
		for i in fmap[k].size():
			var n: Dictionary = fmap[k][i]
			var r: Dictionary = Data.ROOMS[n.type]
			var col: Color = {"elite": Color("#e0583a"), "boss": Color("#ff5a3a"), "sanctuaire": Color("#8fd0a0"), "reliquaire": Color("#d08aff"), "marchand": Color("#ffd27a")}.get(n.type, INK)
			var open: bool = k == step and nexts.has(i)
			var done: bool = visited.has(Vector2i(k, i))
			var b := Button.new()
			b.text = r.glyph
			b.add_theme_font_override("font", title_f)
			b.add_theme_font_size_override("font_size", 30)
			var sz := 76.0 if n.type == "boss" else 62.0
			if n.get("mods", []).size() > 0:
				var mk := _shadowed(_label(Data.MODIFIERS[n.mods[0]].glyph, 28, Color("#ffb05a"), title_f), 8)
				mk.position = pos.call(k, i) + Vector2(sz * 0.3, -sz * 0.75)
				area.add_child(mk)
			b.size = Vector2(sz, sz)
			b.position = pos.call(k, i) - Vector2(sz, sz) * 0.5
			b.pivot_offset = Vector2(sz, sz) * 0.5
			b.add_theme_stylebox_override("normal", sb(Color(0.1, 0.09, 0.1, 0.96), col, int(sz / 2), 3, 8))
			b.add_theme_stylebox_override("hover", sb(col.darkened(0.55), Color.WHITE, int(sz / 2), 3, 12))
			b.add_theme_stylebox_override("focus", sb(col.darkened(0.55), Color.WHITE, int(sz / 2), 3, 12))
			b.add_theme_stylebox_override("pressed", sb(col.darkened(0.3), Color.WHITE, int(sz / 2), 3, 4))
			b.add_theme_stylebox_override("disabled", sb(col.darkened(0.62) if done else Color(0.07, 0.065, 0.075, 0.9), col.darkened(0.25 if done else 0.55), int(sz / 2), 2))
			b.add_theme_color_override("font_color", col)
			b.add_theme_color_override("font_hover_color", Color.WHITE)
			b.add_theme_color_override("font_focus_color", Color.WHITE)
			b.add_theme_color_override("font_disabled_color", INK if done else col.darkened(0.4))
			b.disabled = not open
			var desc: String = n.desc
			b.mouse_entered.connect(func(): info.text = desc)
			b.focus_entered.connect(func(): info.text = desc)
			if open:
				var idx: int = i
				b.pressed.connect(func(): picked.emit(idx))
				var tw := b.create_tween().set_loops()
				tw.tween_property(b, "scale", Vector2.ONE * 1.1, 0.6).set_trans(Tween.TRANS_SINE)
				tw.tween_property(b, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
				if first == null:
					first = b
			else:
				b.mouse_filter = Control.MOUSE_FILTER_PASS
			area.add_child(b)
	if lane >= 0 and step > 0:
		var here := _shadowed(_label("vous", 13, GOLD), 4)
		here.position = pos.call(step - 1, lane) + Vector2(-20, 36)
		area.add_child(here)
	var eq := Button.new()
	eq.text = equip_txt
	eq.add_theme_font_override("font", title_f)
	eq.add_theme_font_size_override("font_size", 18)
	eq.add_theme_color_override("font_color", INK)
	eq.add_theme_stylebox_override("normal", sb(Color(0.08, 0.07, 0.075, 0.92), Color("#8fa3b8"), 10, 2, 6))
	eq.add_theme_stylebox_override("hover", sb(Color(0.16, 0.18, 0.2, 0.95), Color.WHITE, 10, 2, 6))
	eq.add_theme_stylebox_override("focus", sb(Color(0.16, 0.18, 0.2, 0.95), Color.WHITE, 10, 2, 6))
	eq.custom_minimum_size = Vector2(320, 46)
	eq.pressed.connect(func(): picked.emit(-2))
	var fu := eq.duplicate(0)
	fu.text = "Fusionner des doubles"
	fu.pressed.connect(func(): picked.emit(-3))
	var dk := eq.duplicate(0)
	dk.text = "Voir le paquet"
	dk.pressed.connect(func(): picked.emit(-4))
	var ec := HBoxContainer.new()
	ec.alignment = BoxContainer.ALIGNMENT_CENTER
	ec.add_theme_constant_override("separation", 20)
	ec.add_child(eq)
	ec.add_child(fu)
	ec.add_child(dk)
	box.add_child(ec)
	if first and Input.get_connected_joypads().size() > 0:
		first.grab_focus.call_deferred()
	overlay.modulate.a = 0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.25)
	var i: int = await picked
	_close_overlay()
	return i


func _passthrough(n: Node) -> void:
	## Les clics traversent l'illustration jusqu'au porteur de l'option.
	if n is Control:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for ch in n.get_children():
		_passthrough(ch)


func _option(o: Dictionary, w := 250) -> Control:
	var col: Color = o.get("color", GOLD)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(w, 300)
	var s := sb(Color(0.08, 0.07, 0.075, 0.92), col, 14, 2, 14)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 26
	s.content_margin_bottom = 20
	p.add_theme_stylebox_override("panel", s)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	if o.has("image"):
		var im := TextureRect.new()
		im.texture = load(o.image)
		im.custom_minimum_size = Vector2(110, 110)
		im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		im.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(im)
	else:
		var g := _shadowed(_label(o.get("glyph", "✦"), 64, col.lightened(0.2), title_f), 8)
		g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(g)
	var t := _label(o.title, 24, INK, title_f)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var d := _label(o.get("text", ""), 15, DIM)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	return p


func _close_overlay() -> void:
	if overlay and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null


func title_screen() -> void:
	_close_overlay()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var grad := TextureRect.new()
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.02, 0.02, 0.03, 0.0), Color(0.02, 0.02, 0.03, 0.75)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0.3)
	gt.fill_to = Vector2(0, 1)
	grad.texture = gt
	grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(grad)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	box.position = Vector2(-400, -330)
	box.size = Vector2(800, 280)
	box.add_theme_constant_override("separation", 6)
	overlay.add_child(box)
	var t := _shadowed(_label("TONERTACTIC", 104, INK, wide_f), 16)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var s := _shadowed(_label("Roguelike tactique à cartes · les ruines de l'Écluse", 18, GOLD), 6)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(s)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 30)
	box.add_child(sp)
	var b := Button.new()
	b.text = "Nouvelle descente"
	b.add_theme_font_override("font", title_f)
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", Color("#2a1606"))
	b.add_theme_stylebox_override("normal", sb(GOLD, Color("#fff0c8"), 12, 2, 10))
	b.add_theme_stylebox_override("hover", sb(GOLD.lightened(0.18), Color("#fff6dc"), 12, 2, 12))
	b.add_theme_stylebox_override("pressed", sb(GOLD.darkened(0.15), Color("#fff0c8"), 12, 2, 4))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.custom_minimum_size = Vector2(300, 60)
	b.pressed.connect(func(): picked.emit(0))
	var c := CenterContainer.new()
	c.add_child(b)
	box.add_child(c)
	if Input.get_connected_joypads().size() > 0:
		b.grab_focus.call_deferred()
	await picked
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 0.0, 0.4)
	await tw.finished
	_close_overlay()


func game_over(victory: bool, summary: String) -> void:
	await choose("L'ÉCLUSE EST TOMBÉE" if victory else "LA DESCENTE S'ACHÈVE", summary,
		[{"title": "Nouvelle descente", "glyph": "↻", "text": "Nouveaux traits, nouvelles salles.", "color": GOLD}])
