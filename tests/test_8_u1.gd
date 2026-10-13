extends SceneTree
## Task 8.U1: kingdom select + any-wizard HUD + Sapling lifetime bar + Nature pop cap.
## - Skirmish setup: two rows of 4 kingdom cards (Fire / Shadow / Ice / Nature = Vessa / Malrik / Torvald /
##   Ysolde), one selected per row, mirror allowed, the matchup line, Ysolde's tooltip lists her spells;
##   MenuFlow gets player_kingdom / enemy_kingdom and sets them on a fresh skirmish instance.
## - HUD with Ysolde as the player's wizard: Nature skin (UIStyle tokens), hero column name, help text names
##   her, F / Q / E spell tooltips of kingdom-nature.md 3.1, W walks her (wizard_control.gd).
## - A Sapling selected alone shows the lifetime bar ("Withers in N s", draining); a Flame Guard does not.
## - Nature economy: the top bar shows "/ 200" at the cap (pop-200 rule; was "/ 50") and "200 / 200" fits.
## Run: godot --headless --path . -s tests/test_8_u1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "8.u1"
const TIMEOUT_FRAMES := 2400
const SETTINGS_PATH := "user://settings.cfg"

var main: Node
var _menu: Node
var _menu_frames := 0
var frame := 0
var step := 0
var _wait := 0
var _ysolde: Node
var _sapling: Node
var _start_pos := Vector3.ZERO
var _phys0 := 0
var _proc0 := 0
var _notes: Array[String] = []
var _backup := PackedByteArray()
var _had_backup := false


func _initialize() -> void:
	# UX.1: this test covers the Hero WASD control scheme (W A S D walk, X = attack-move); test_ux_1 covers Classic.
	GameSettings.set_control_scheme(GameSettings.CONTROLS_HERO_WASD, false)
	if FileAccess.file_exists(SETTINGS_PATH):
		_had_backup = true
		_backup = FileAccess.get_file_as_bytes(SETTINGS_PATH)
	_menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(_menu)
	current_scene = _menu


## The skirmish setup cards (runs once, before the map loads).
func _check_menu() -> String:
	var menu: Node = _menu
	menu.show_skirmish_setup()
	var you: Array = menu.kingdom_buttons
	var foe: Array = menu.enemy_buttons
	if you.size() != 4 or foe.size() != 4:
		return "expected 2 rows of 4 cards, got %d / %d" % [you.size(), foe.size()]
	var wizards := ["vessa", "malrik", "torvald", "ysolde"]
	var kingdoms := [&"fire", &"shadow", &"ice", &"nature"]
	# Cards follow Skirmish.kingdom_available (greyed when false; step 8 expects all 4 available).
	var sk: Script = load("res://scripts/world/skirmish.gd")
	for i in 4:
		var avail := bool(sk.call(&"kingdom_available", kingdoms[i])) if sk.has_method(&"kingdom_available") else true
		for row: Array in [you, foe]:
			var card: Node = row[i]
			if card.get(&"kingdom") != kingdoms[i]:
				return "card %d is %s" % [i, card.get(&"kingdom")]
			if card.disabled == avail:
				return "card %s disabled=%s but kingdom_available=%s" % [kingdoms[i], card.disabled, avail]
			if str(card.wizard_label.text).to_lower() != wizards[i]:
				return "card %d shows wizard '%s'" % [i, card.wizard_label.text]
			if avail and str(card.style_label.text).length() < 20:
				return "card %d has no play-style line" % i
		if not avail:
			return "kingdom %s is not available (Skirmish.kingdom_available)" % kingdoms[i]
	# Emblem polygons: always simple and triangulable, at every size the UI uses.
	var ui: Script = load("res://scripts/ui/ui_style.gd")
	for k: StringName in kingdoms:
		for r: float in [8.0, 12.0, 17.0, 20.0, 30.0, 56.0, 80.0]:
			var polys: Array = ui.call(&"emblem_polygons", k, Vector2(100, 100), r)
			var want_count: int = {&"fire": 3, &"shadow": 2, &"ice": 0, &"nature": 3}[k]
			if r >= 17.0 and polys.size() != want_count:
				return "emblem %s at radius %s has %d shapes, expected %d" % [k, r, polys.size(), want_count]
			for poly: PackedVector2Array in polys:
				if Geometry2D.triangulate_polygon(poly).is_empty():
					return "emblem %s at radius %s: a polygon does not triangulate" % [k, r]
	var tip := str(you[3].tooltip_text)
	for want in ["Ysolde, Nature Wizard", "Thornburst [F]", "Wild Bloom [Q]", "Call the Thicket [E]"]:
		if not tip.contains(want):
			return "Ysolde's card tooltip misses '%s': %s" % [want, tip]
	# Defaults: Fire vs Shadow.
	if menu.get_player_kingdom() != &"fire" or not you[0].button_pressed or not foe[1].button_pressed:
		return "default selection is not Fire vs Shadow"
	# Pick Nature on both sides (mirror).
	you[3].pressed.emit()
	foe[3].pressed.emit()
	if menu.get_player_kingdom() != &"nature" or menu.get_enemy() != &"nature":
		return "Nature mirror not selected (%s vs %s)" % [menu.get_player_kingdom(), menu.get_enemy()]
	var on := 0
	for row: Array in [you, foe]:
		for card: Node in row:
			on += 1 if card.button_pressed else 0
	if on != 2 or not you[3].button_pressed or not foe[3].button_pressed:
		return "exactly one card per row should be selected (%d)" % on
	if menu.foe_label.text != "Ysolde of Nature  vs  Ysolde of Nature":
		return "matchup line is '%s'" % menu.foe_label.text
	menu.set_player_kingdom(&"ice")
	menu.set_enemy(&"fire")
	if not you[2].button_pressed or you[3].button_pressed or not foe[0].button_pressed:
		return "set_player_kingdom / set_enemy did not move the selection"
	# MenuFlow carries both kingdoms onto a fresh skirmish before it enters the tree.
	MenuFlow.player_kingdom = &"nature"
	MenuFlow.enemy_kingdom = &"ice"
	var probe: Node = (load(MenuFlow.SKIRMISH) as PackedScene).instantiate()
	var has_player := MenuFlow.apply_kingdoms(probe)
	if has_player and StringName(str(probe.get(&"player_kingdom"))) != &"nature":
		return "skirmish player_kingdom is %s" % probe.get(&"player_kingdom")
	if &"enemy_kingdom" in probe and StringName(str(probe.get(&"enemy_kingdom"))) != &"ice":
		return "skirmish enemy_kingdom is %s" % probe.get(&"enemy_kingdom")
	if not has_player:
		_notes.append("Skirmish has no player_kingdom property yet (8.S2)")
	probe.free()
	MenuFlow.player_kingdom = &"fire"
	MenuFlow.enemy_kingdom = &"shadow"
	menu.free()
	return ""


func _process(_delta: float) -> bool:
	if main == null:
		_menu_frames += 1
		if _menu_frames < 3:
			return false
		var err := _check_menu()
		if err != "":
			return _finish(err)
		main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		current_scene = main
		return false
	if main.get("hero") == null:
		_wait += 1
		return _wait > 5000 and _finish("navigation never finished baking")
	frame += 1
	if frame > TIMEOUT_FRAMES:
		return _finish("timed out at step %d" % step)
	var hud: Node = main.get("hud")
	var sel: Node = main.get("selection")
	match step:
		0:
			if frame < 5:
				return false
			# Swap the player's wizard for Ysolde (as a Nature skirmish would) and re-run the HUD setup.
			_ysolde = (load("res://scripts/units/nature_wizard.gd") as Script).new()
			_ysolde.set(&"team", 0)
			main.add_child(_ysolde)
			_ysolde.global_position = main.hero.global_position + Vector3(3, 0, 0)
			_ysolde.command_stop()
			sel.set(&"hero", _ysolde)
			hud.setup(_ysolde, sel)
			if hud.get_script().call(&"kingdom_of", _ysolde) != &"nature":
				return _finish("kingdom_of(Ysolde) is not nature")
			var ui: Script = load("res://scripts/ui/ui_style.gd")
			if ui.call(&"get_kingdom") != &"nature":
				return _finish("HUD skin is %s, expected nature" % ui.call(&"get_kingdom"))
			var glow: Color = ui.call(&"token", &"trim_glow")
			var metal: Color = ui.call(&"token", &"frame_metal")
			if not glow.is_equal_approx(Color(0.75, 1.00, 0.40)) or not metal.is_equal_approx(Color(0.40, 0.28, 0.16)):
				return _finish("Nature skin tokens wrong: glow %s metal %s" % [glow, metal])
			var panel: Node = hud.selection_panel
			if panel.hero_name.text != "Ysolde":   # SC2.U3 hero tile: the short name (ui-sc2-console.md 3.1)
				return _finish("hero column shows '%s'" % panel.hero_name.text)
			var help: String = hud.get(&"_help_label").text
			if not help.contains("W A S D: walk Ysolde") or not help.contains("Space: find Ysolde") or help.contains("Vessa"):
				return _finish("help text does not name Ysolde: %s" % help)
			var info: Script = load("res://scripts/ui/spell_info.gd")
			var ids: Array = info.call(&"ids", _ysolde)
			if str(ids) != str([&"thornburst", &"wild_bloom", &"call_the_thicket"]):
				return _finish("Ysolde's spells are %s" % str(ids))
			var want := ["35 mana · 40 damage · radius 3", "50 mana · 16 s cooldown · radius 5",
					"60 mana · 45 s cooldown · 3 Saplings"]
			var keys := ["F", "Q", "E"]
			for i in 3:
				var t := str(info.call(&"tooltip", _ysolde, ids[i], i))
				if not t.contains(want[i]) or not t.contains("[%s]" % keys[i]):
					return _finish("tooltip %s is '%s', expected '%s'" % [keys[i], t, want[i]])
			var ct := str(info.call(&"next_rank_line", _ysolde, &"call_the_thicket", 1))
			if not ct.contains("5 Saplings"):
				return _finish("Call the Thicket rank 2 line is '%s'" % ct)
			# The command card lists her 3 spells when she is selected.
			sel.select_units([_ysolde])
			step = 1
			_wait = 0
		1:
			_wait += 1
			if _wait < 3:
				return false
			var card: Node = hud.command_card
			var names: Array[String] = []
			for s: Dictionary in card.slots:
				if s.has("spell"):
					names.append(String(s["spell"]))
			if names != ["thornburst", "wild_bloom", "call_the_thicket"]:
				return _finish("command card spells are %s" % str(names))
			# W walks Ysolde (wizard_control.gd, physical W).
			_start_pos = _ysolde.global_position
			_key(KEY_W, true)
			_phys0 = Engine.get_physics_frames()
			step = 2
		2:
			# 0.75 s of simulation time (physics ticks; movement runs in _physics_process), not 45 process frames.
			if Engine.get_physics_frames() - _phys0 < 45:
				return false
			_key(KEY_W, false)
			var moved: float = (_ysolde.global_position - _start_pos).length()
			if moved < 1.0:
				return _finish("W did not walk Ysolde (moved %.2f m)" % moved)
			# A Sapling (summon) of the player's side, selected alone.
			_sapling = main.make_unit("sapling")
			_sapling.set(&"team", 0)
			main.add_child(_sapling)
			_sapling.global_position = _ysolde.global_position + Vector3(0, 0, 3)
			_sapling.command_stop()
			_sapling.set_lifetime(25.0)
			sel.select_units([_sapling])
			_phys0 = Engine.get_physics_frames()
			_proc0 = Engine.get_process_frames()
			step = 3
		3:
			# Wait 1 s of SIMULATION time (physics ticks; the lifetime drains in Unit._physics_process), not 60
			# process frames: without --fixed-fps (or with a different one) a fast PC runs several process frames
			# per physics tick and the bar had drained only ~0.43 s ("24.57 / 25.0 after 1 s", 2026-10-07).
			if Engine.get_physics_frames() - _phys0 < Engine.physics_ticks_per_second:
				return false
			print("lifetime after %d physics ticks (%d process frames): %.3f s left" % [Engine.get_physics_frames() - _phys0,
					Engine.get_process_frames() - _proc0, _sapling.lifetime_left()])
			var panel: Node = hud.selection_panel
			if panel.current_view() != "single" or not panel.single_lifetime.visible:
				return _finish("no lifetime bar for the Sapling (view %s)" % panel.current_view())
			var left: float = panel.single_lifetime.value
			if panel.single_lifetime.max_value != 25.0 or left >= 24.5 or left < 22.0:
				return _finish("lifetime bar %s / %s after 1 s" % [left, panel.single_lifetime.max_value])
			if panel.single_lifetime_text.text != "Withers in %d s" % ceili(float(_sapling.lifetime_left())):
				return _finish("lifetime text '%s'" % panel.single_lifetime_text.text)
			# A Flame Guard: no lifetime bar.
			var guard: Node = main.make_unit("flame_guard")
			guard.set(&"team", 0)
			main.add_child(guard)
			guard.global_position = _ysolde.global_position + Vector3(2, 0, 3)
			guard.command_stop()
			sel.select_units([guard])
			step = 4
			_wait = 0
		4:
			_wait += 1
			if _wait < 3:
				return false
			if hud.selection_panel.single_lifetime.visible:
				return _finish("a Flame Guard shows a lifetime bar")
			# Nature economy: the cap reaches the hard cap (200 for every kingdom since the pop-200 rule,
			# economy.md 2026-09-27; was Nature 50) and the top bar shows it, clamped, in full.
			var eco: Node = null
			for e in get_nodes_in_group(&"economies"):
				if int(e.get(&"team")) == 0:
					eco = e
			if eco == null:
				return _finish("no player Economy")
			eco.set_kingdom(&"nature")
			eco.add_pop_bonus(300)
			hud.top_bar.refresh()
			var pop_label: Label = hud.top_bar.pop_label
			var pop: String = pop_label.text
			if not pop.ends_with("/ 200"):
				return _finish("top bar pop is '%s', expected '/ 200'" % pop)
			pop_label.text = "200 / 200"
			var need := pop_label.get_theme_font(&"font").get_string_size("200 / 200", HORIZONTAL_ALIGNMENT_LEFT, -1,
					pop_label.get_theme_font_size(&"font_size")).x
			hud.top_bar.refresh()
			if need > pop_label.size.x + 0.5:
				return _finish("top bar pop label %.0f px wide, '200 / 200' needs %.0f" % [pop_label.size.x, need])
			return _finish("")
	return false


func _key(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = pressed
	root.push_input(ev)


func _finish(reason: String) -> bool:
	if _had_backup:
		var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
		if f:
			f.store_buffer(_backup)
			f.close()
	elif FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	for n in _notes:
		print("note: " + n)
	if reason == "":
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, reason])
	return true
