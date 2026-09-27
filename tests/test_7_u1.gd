extends SceneTree
## Task 7.U1: Ice support in the HUD and the menu.
## - Build menu for Ice workers: Snow Lodge Z, Frost Hall X, Rime Spire C, Back r1c4, Ice Wall V at r2c1,
##   Ice Wall tooltip as written in kingdom-ice.md 5.
## - Torvald's spell tooltips (kingdom-ice.md 4.1).
## - Status marks chill / frozen / rooted (chips + multi-select dots, their colours).
## - UIStyle ice skin, GameHUD.kingdom_of(Torvald) = ice.
## - Main menu: Enemy Shadow / Ice sets `enemy_kingdom` on the skirmish before it enters the tree;
##   Campaign is active with Mission 1 "The Crown in the Ashes" playable and later missions greyed.
## Run: godot --headless --path . -s tests/test_7_u1.gd --fixed-fps 60 --quit-after 1500

const TASK_ID := "7.u1"
const TIMEOUT_FRAMES := 1200
const WALL_TIP := "Ice Wall  [V]\nCost 20 crystals · 8 s · 500 HP\nBlocks the way. Max 16."
const SPELL_TIPS := {
	&"rime_bolt": ["35 mana · 45 damage · range 13", "Chills the target: slower attacks and movement."],
	&"flash_freeze": ["50 mana · 20 s cooldown · radius 3", "Freezes every enemy in the circle."],
	&"rime_aegis": ["60 mana · 40 s cooldown · radius 8", "Shields Torvald and nearby soldiers."],
}

var frame := 0
var step := 0
var menu: Node
var _errors: Array[String] = []
var _notes: Array[String] = []


class FakeSelection extends SelectionManager:
	var kingdom: StringName = &"ice"

	func buildable_types() -> Array[BuildingType]:
		return BuildingType.buildable_for(kingdom)

	func build_reason(_type: BuildingType) -> String:
		return ""


class FakeUnit extends Node:
	var on: Array = []

	func has_status(id: StringName) -> bool:
		return on.has(id)

	func status_time_left(_id: StringName) -> float:
		return 2.4


func _initialize() -> void:
	pass


func _process(_delta: float) -> bool:
	frame += 1
	if frame > TIMEOUT_FRAMES:
		return _finish("timed out at step %d" % step)
	match step:
		0:
			_check_build_menu()
			_check_spells()
			_check_skin()
			step = 1
		1:
			_check_statuses()
			menu = load("res://scenes/ui/main_menu.tscn").instantiate()
			root.add_child(menu)
			current_scene = menu
			step = 2
		2:
			if frame < 6:
				return false
			return _check_menu()
	return false


# ---------------------------------------------------------------- HUD

func _check_build_menu() -> void:
	var types := BuildingType.buildable_for(&"ice")
	if types.size() != 4:
		_errors.append("Ice buildable types: %d (want 4)" % types.size())
		return
	var sel := FakeSelection.new()
	sel.build_menu_open = true
	var card := CommandCard.new()
	root.add_child(card)
	card.setup(sel)
	var ids := card.slot_ids()
	var want := ["build_ice_lodge", "build_ice_barracks", "build_ice_tower", "back", "build_ice_wall"]
	for i in want.size():
		if ids[i] != want[i]:
			_errors.append("build menu slots %s (want %s)" % [str(ids.slice(0, 5)), str(want)])
			break
	if card.slots[4].get("key", "") != "V":
		_errors.append("Ice Wall key badge is '%s'" % card.slots[4].get("key", ""))
	var tip := str(card.slots[4].get("tooltip", ""))
	if tip != WALL_TIP:
		_errors.append("Ice Wall tooltip:\n%s" % tip)
	# Fire keeps its three entries on Z X C and nothing at r2c1.
	sel.kingdom = &"fire"
	card.refresh()
	ids = card.slot_ids()
	if ids[3] != "back" or ids[4] != "" or not ids[0].begins_with("build_fire"):
		_errors.append("fire build menu changed: %s" % str(ids.slice(0, 5)))
	card.queue_free()
	sel.free()


func _check_spells() -> void:
	for id: StringName in SPELL_TIPS:
		var tip := SpellInfo.tooltip(null, id, [&"rime_bolt", &"flash_freeze", &"rime_aegis"].find(id))
		var lines := tip.split("\n")
		if lines.size() < 3 or lines[1] != SPELL_TIPS[id][0] or lines[2] != SPELL_TIPS[id][1]:
			_errors.append("%s tooltip:\n%s" % [id, tip])
	if SpellInfo.abbrev(&"rime_bolt") != "RB" or SpellInfo.abbrev(&"flash_freeze") != "FF" \
			or SpellInfo.abbrev(&"rime_aegis") != "RA":
		_errors.append("Ice spell icons are not RB / FF / RA")


func _check_skin() -> void:
	UIStyle.set_kingdom(&"ice")
	if UIStyle.get_kingdom() != &"ice" or not UIStyle.token(&"frame_metal").is_equal_approx(Color(0.70, 0.78, 0.88)) \
			or not UIStyle.token(&"trim_glow").is_equal_approx(Color(0.75, 0.92, 1.00)):
		_errors.append("UIStyle ice skin tokens wrong")
	var frame_tex := UIStyle.frame_texture()
	if frame_tex == null:
		_errors.append("ice frame texture missing")
	UIStyle.set_kingdom(&"fire")
	var named := FakeNamed.new()
	named.unit_name = "Torvald, Ice Wizard"
	if GameHUD.kingdom_of(named) != &"ice":
		_errors.append("kingdom_of(Torvald) is not ice")
	named.free()
	var hud := GameHUD.new()
	root.add_child(hud)
	hud.set_objective_visible(false)
	var hidden: bool = not hud.is_objective_visible()
	hud.set_objective_visible(true)
	if not hidden or not hud.is_objective_visible():
		_errors.append("GameHUD.set_objective_visible does not toggle the objective panel")
	hud.queue_free()


class FakeNamed extends Node:
	var unit_name := ""


func _check_statuses() -> void:
	var ids := SelectionPanel.status_ids()
	var colors := {&"chill": Color(0.62, 0.82, 1.00), &"frozen": Color(0.88, 0.96, 1.00),
			&"rooted": Color(0.48, 0.52, 0.22)}
	for id: StringName in colors:
		if not ids.has(id):
			_errors.append("status %s has no mark" % id)
		elif not SelectionPanel.status_color(id).is_equal_approx(colors[id]):
			_errors.append("status %s colour %s" % [id, SelectionPanel.status_color(id)])
	var panel := SelectionPanel.new()
	root.add_child(panel)
	var u := FakeUnit.new()
	u.on = [&"chill", &"frozen"]
	panel._update_status_row(panel.single_statuses, u)
	var text := panel.status_row_text(panel.single_statuses)
	if text != "C 3, F 3":
		_errors.append("status chips '%s' (want 'C 3, F 3')" % text)
	var dots: Dictionary = panel._icon_status_dots[0]
	for id: StringName in colors:
		if not dots.has(id) or not (dots[id] as ColorRect).color.is_equal_approx(colors[id]):
			_errors.append("multi-select icon has no %s dot" % id)
	u.free()
	panel.queue_free()


# ---------------------------------------------------------------- menu

func _check_menu() -> bool:
	if menu.campaign_button.disabled:
		return _finish("Campaign button disabled")
	menu.campaign_button.pressed.emit()
	if not menu.campaign_panel.visible:
		return _finish("campaign panel did not open")
	if menu.mission_buttons.is_empty() or not str(menu.mission_buttons[0].text).contains("The Crown in the Ashes"):
		return _finish("mission 1 missing from the list")
	if menu.mission_scene(&"m01") != "res://missions/mission_01.tscn":
		return _finish("mission 1 scene is %s" % menu.mission_scene(&"m01"))
	if ResourceLoader.exists("res://missions/mission_01.tscn"):
		if menu.mission_buttons[0].disabled or menu.get_mission() != &"m01" or menu.campaign_start_button.disabled:
			return _finish("mission 1 exists but is not playable / selected")
	else:
		# Scene not built yet (systems, M7.S*): unlocked but greyed "coming soon", Start disabled.
		if not menu.mission_buttons[0].disabled or not str(menu.mission_buttons[0].text).contains("coming soon") \
				or not menu.campaign_start_button.disabled:
			return _finish("mission 1 without a scene should be greyed 'coming soon'")
		_notes.append("missions/mission_01.tscn not built yet: mission 1 shows 'coming soon'")
	for i in range(1, menu.mission_buttons.size()):
		if not menu.mission_buttons[i].disabled:
			_notes.append("mission %d is playable" % (i + 1))
	menu.campaign_difficulty_buttons[0].pressed.emit()
	if menu.get_difficulty() != 0 or not menu.difficulty_buttons[0].button_pressed:
		return _finish("campaign difficulty not shared")
	menu.show_main()
	menu.skirmish_button.pressed.emit()
	# 8.U1: the enemy row is 4 kingdom cards (Fire, Shadow, Ice, Nature); Ice = Torvald.
	if menu.enemy_buttons.size() != 4 or menu.enemy_buttons[2].get(&"kingdom") != &"ice":
		return _finish("Enemy row missing")
	menu.enemy_buttons[2].pressed.emit()
	if menu.get_enemy() != &"ice" or not str(menu.foe_label.text).contains("Torvald"):
		return _finish("Ice enemy not selected")
	# The level gets enemy_kingdom before it enters the tree: check on a fresh instance through MenuFlow.
	var probe: Node = (load(MenuFlow.SKIRMISH) as PackedScene).instantiate()
	var has_prop := MenuFlow.apply_enemy_kingdom(probe)
	probe.free()
	menu.start_button.pressed.emit()
	var level: Node = current_scene
	if level == null or level.name != "Skirmish":
		return _finish("Start did not launch the skirmish")
	if MenuFlow.enemy_kingdom != &"ice":
		return _finish("MenuFlow.enemy_kingdom is not ice")
	if has_prop:
		if StringName(str(level.get(&"enemy_kingdom"))) != &"ice":
			return _finish("skirmish enemy_kingdom is %s" % str(level.get(&"enemy_kingdom")))
	else:
		_notes.append("Skirmish has no enemy_kingdom property yet (7.S2)")
	MenuFlow.enemy_kingdom = &"shadow"
	return _finish("")


func _finish(reason: String) -> bool:
	for n in _notes:
		print("note: " + n)
	if reason == "" and not _errors.is_empty():
		reason = "; ".join(_errors)
	elif not _errors.is_empty():
		reason += "; " + "; ".join(_errors)
	if reason == "":
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, reason])
	return true
