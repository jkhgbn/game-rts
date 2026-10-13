extends SceneTree
## Test for 1.U2 (command card): placement and 4 x 3 grid of 64 px, the slot table for
## nothing / soldier / worker / wizard / mixed / keep / barracks, hotkey letters (M C H X F G B),
## disabled state + reason, training via the card and via the slot keys Z X C V B (physical, only while
## the building is selected): the keep trains workers only (wave 2), soldiers train at a barracks
## (Ember Hall, spawned finished for the test); gather via right click on a crystal node with workers.
## Run:  godot --headless --path . -s tests/test_1_u2.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "1.u2"
const TIMEOUT_FRAMES := 400
## SC2.U1: the wizard's card (orders row 1, spells F / Q / E at r2c1-r2c3).
const WIZARD_IDS := ["move", "stop", "hold", "attack", "", "fireball", "ember_step", "kindle", "", "", "", "", "", ""]

var main: Node
var sel: Node
var card: Node
var eco: Node
var keep: Node
var barracks: Node
var frame := 0
var _wait := 0
var _error := ""
var _done := false
var _soldier: Node
var _workers: Array = []
var _node_b: Node


func _initialize() -> void:
	# UX.1: this test covers the Hero WASD control scheme (W A S D walk, X = attack-move); test_ux_1 covers Classic.
	GameSettings.set_control_scheme(GameSettings.CONTROLS_HERO_WASD, false)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:   # the map is ready when the hero has spawned
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	_step()
	if _error != "":
		print("FAIL %s: %s" % [TASK_ID, _error])
		return true
	if _done:
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _step() -> void:
	match frame:
		5:
			sel = main.selection
			card = main.hud.command_card
			eco = main.get("economy")
			keep = main.get("keep")
			if card == null:
				_error = "GameHUD has no command_card"
				return
			if keep == null or eco == null:
				_error = "main.keep / main.economy missing (systems-coder's 1.S1 / 1.S2)"
				return
			for u in root.get_tree().get_nodes_in_group("units"):
				if u.team != 0 or u.is_in_group("heroes"):
					continue
				if u.has_method("command_gather"):
					_workers.append(u)
				elif _soldier == null:
					_soldier = u
			# A finished Ember Hall near the base (the keep trains only workers since wave 2).
			var hall := BuildingType.find("fire_barracks")
			var spot: Vector3 = main.build_grid.find_spot(hall, keep.global_position + Vector3(10, 0, -10), 0)
			if spot == Vector3.INF:
				_error = "no free spot for a barracks"
				return
			barracks = main.build_grid.spawn_complete(hall, spot, 0)
			_check_layout()
		6:
			_check_unit_tables()
		7:
			_check_keep_table()
		8:
			_check_training()
		9:
			_check_keep_keys_need_keep()
		10:
			# Gather: right click on a crystal node with workers selected (HUD hidden: 64 px window).
			_node_b = main.crystal_nodes.get(&"node_home_b")
			if _node_b == null:
				_error = "no crystal node node_home_b"
				return
			sel.select_units(_workers)
			sel.stop()
			main.hud.visible = false
			main.camera_rig.focus_on(_node_b.global_position)
		12:
			var screen: Vector2 = main.camera_rig.camera.unproject_position(_node_b.global_position + Vector3.UP * 0.6)
			_click(screen, MOUSE_BUTTON_RIGHT)
			for w in _workers:
				if w.gather_node != _node_b:
					_error = "right click on a crystal node did not send workers to gather (%s)" % w.gather_node
					return
			# G then left click on the node does the same.
			sel.stop()
			_key(KEY_G, KEY_G)
			if sel.get_pending_order() != &"gather":
				_error = "G did not start gather targeting"
				return
			_click(screen, MOUSE_BUTTON_LEFT)
			for w in _workers:
				if w.gather_node != _node_b:
					_error = "G + left click on a node did not gather"
					return
			main.hud.visible = true
			_done = true


func _check_layout() -> void:
	var rect: Rect2 = card.get_global_rect()
	var screen: Vector2 = root.get_visible_rect().size
	# SC2.U1 (ui-sc2-console.md 4.4): 5 x 3 of 56 in the console's card zone, (1292, 704) at 1600 x 900.
	var expected := screen - Vector2(308, 196)
	if rect.position.distance_to(expected) > 1.5 or rect.size.distance_to(Vector2(296, 176)) > 1.5:
		_error = "card at %s, expected %s size 296 x 176" % [rect, expected]
		return
	if card.buttons.size() != 15:
		_error = "card has %d buttons, expected 15 (5 x 3)" % card.buttons.size()
		return
	var b0: Rect2 = card.buttons[0].get_global_rect()
	var b6: Rect2 = card.buttons[6].get_global_rect()
	if b0.size.distance_to(Vector2(56, 56)) > 0.5 or b0.position.distance_to(rect.position) > 1.5:
		_error = "button 1 at %s, expected 56 x 56 at the card's corner" % b0
		return
	if b6.position.distance_to(b0.position + Vector2(60, 60)) > 1.5:
		_error = "button r2c2 at %s, expected 60 px right and down of r1c1" % b6.position


func _check_unit_tables() -> void:
	sel.select_units([])
	card.refresh()
	if _ids() != _grid({}):
		_error = "nothing selected shows %s" % [_ids()]
		return
	sel.select_units([_soldier])
	card.refresh()
	if _ids() != _grid({0: "move", 1: "stop", 2: "hold", 3: "attack"}):
		_error = "soldier shows %s" % [_ids()]
		return
	sel.select_units(_workers)
	card.refresh()
	if _ids() != _grid({0: "move", 1: "stop", 2: "hold", 3: "gather", 10: "build"}):
		_error = "workers show %s" % [_ids()]
		return
	sel.select_units([main.hero])
	card.refresh()
	if _ids() != WIZARD_IDS:
		_error = "wizard shows %s" % [_ids()]
		return
	# Mixed (2026-09-27 "Tab by unit type", SC2 subgroups): the card shows the active subgroup, the wizard first; Tab
	# walks to the soldier, then the worker (Gather G), then back to the wizard.
	sel.select_units([main.hero, _soldier, _workers[0]])
	card.refresh()
	if _ids() != WIZARD_IDS:
		_error = "mixed (wizard subgroup) shows %s" % [_ids()]
		return
	if _keys() != _grid({0: "M", 1: "C", 2: "H", 3: "X", 5: "F", 6: "Q", 7: "E"}):
		_error = "mixed hotkey letters %s, expected M C H X / F Q E" % [_keys()]
		return
	sel.cycle_active_unit_type(1)
	sel.cycle_active_unit_type(1)
	card.refresh()
	if _ids() != _grid({0: "move", 1: "stop", 2: "hold", 3: "gather"}) \
			or _keys() != _grid({0: "M", 1: "C", 2: "H", 3: "G"}):
		_error = "mixed (worker subgroup) shows %s / %s, expected Gather G" % [_ids(), _keys()]
		return
	sel.cycle_active_unit_type(1)
	card.refresh()
	if card.buttons[10].visible:
		_error = "empty slot r3c1 is visible"
		return
	# Tooltip format + disabled Fireball.
	if not str(card.buttons[3].tooltip_text).begins_with("Attack-move  [X]\n"):
		_error = "attack tooltip is '%s'" % card.buttons[3].tooltip_text
		return
	main.hero.mana = 0.0
	card.refresh()
	var fb: Button = card.buttons[5]
	if not fb.disabled or absf(fb.modulate.a - 0.45) > 0.01 or not fb.tooltip_text.ends_with("\nNot enough mana"):
		_error = "Fireball not disabled with reason at 0 mana (disabled=%s tip='%s')" % [fb.disabled, fb.tooltip_text]
		return
	main.hero.mana = main.hero.max_mana
	card.refresh()
	if fb.disabled:
		_error = "Fireball still disabled with full mana"
		return
	# Pressing Fireball starts the targeting (through the card, not a hero panel).
	card.press_slot(5)
	if sel.get_pending_order() != &"fireball":
		_error = "Fireball button did not start targeting"
		return
	sel.cancel_targeting()
	# Stop / Hold apply at once; Move is targeted.
	card.press_slot(0)
	if sel.get_pending_order() != &"move":
		_error = "Move button did not start move targeting"
		return
	sel.cancel_targeting()


func _check_keep_table() -> void:
	sel.select_building(keep)
	card.refresh()
	var ids: Array = _ids()
	if ids != _grid({0: "train_cinder_hand", 10: "rally"}):
		_error = "keep shows %s" % [ids]
		return
	if _keys() != _grid({0: "Z"}):
		_error = "keep hotkey letters %s, expected Z (rally has no key)" % [_keys()]
		return
	var tip: String = card.buttons[0].tooltip_text
	if not tip.begins_with("Cinder Hand  [Z]\nCost 50 crystals · Pop 1 · 12 s"):
		_error = "Cinder Hand tooltip is '%s'" % tip
		return
	# The barracks shows its own trainable types, like the keep.
	sel.select_building(barracks)
	card.refresh()
	ids = _ids()
	if ids != _grid({0: "train_flame_guard", 1: "train_ember_archer", 2: "train_blaze_rider", 3: "train_ash_hurler",
			10: "rally"}):
		_error = "barracks shows %s" % [ids]
		return
	if _keys() != _grid({0: "Z", 1: "X", 2: "C", 3: "V"}):
		_error = "barracks hotkey letters %s, expected Z X C V" % [_keys()]
		return
	tip = card.buttons[0].tooltip_text
	if not tip.begins_with("Flame Guard  [Z]\nCost 90 crystals · Pop 1 · 18 s"):
		_error = "Flame Guard tooltip is '%s'" % tip
		return


func _check_training() -> void:
	# Keep: a worker via the button.
	sel.select_building(keep)
	card.refresh()
	var start: int = eco.crystals
	card.press_slot(0)
	if keep.queue.size() != 1 or eco.crystals != start - 50:
		_error = "card button did not queue a Cinder Hand (queue %d, crystals %d)" % [keep.queue.size(), eco.crystals]
		return
	# Barracks: a Flame Guard via the button, a second one via physical Z (AZERTY prints W).
	sel.select_building(barracks)
	card.refresh()
	eco.crystals = 500
	eco.changed.emit()
	card.press_slot(0)
	if barracks.queue.size() != 1 or eco.crystals != 500 - 90:
		_error = "card button did not queue a Flame Guard (queue %d, crystals %d)" % [barracks.queue.size(), eco.crystals]
		return
	_key(KEY_Z, KEY_W)                       # AZERTY prints W on the physical Z key
	if barracks.queue.size() != 2:
		_error = "physical Z did not queue with the barracks selected"
		return
	eco.crystals = 100
	eco.changed.emit()
	_key(KEY_C, KEY_C)                       # Blaze Rider (slot 3) costs 180: refused, message shown
	if barracks.queue.size() != 2:
		_error = "C queued a Blaze Rider without enough crystals"
		return
	if not _hud_shows("Not enough crystals"):
		_error = "refused training did not show its reason"
		return
	card.refresh()
	var br: Button = card.buttons[2]
	if not br.disabled or not br.tooltip_text.ends_with("\nNot enough crystals"):
		_error = "Blaze Rider button not disabled with reason (tip '%s')" % br.tooltip_text
		return
	card.press_slot(10)
	if sel.get_pending_order() != &"rally":
		_error = "Set Rally button did not start rally targeting"
		return
	sel.cancel_targeting()


func _check_keep_keys_need_keep() -> void:
	sel.select_units([_soldier])
	var before: int = keep.queue.size()
	var before_b: int = barracks.queue.size()
	eco.crystals = 1000
	_key(KEY_Z, KEY_W)
	_key(KEY_V, KEY_V)
	sel.cancel_targeting()
	if keep.queue.size() != before or barracks.queue.size() != before_b:
		_error = "building hotkeys trained with units selected"


## SC2.U1 (ui-sc2-console.md 4.4): the 15 slots of the 5 x 3 card, `filled` = {slot: value}, "" elsewhere.
## (Slot 14, r3c5, is left out: a Hall may show its "+" upgrades page there.)
func _grid(filled: Dictionary) -> Array:
	var out := []
	for i in 14:
		out.append(str(filled.get(i, "")))
	return out


func _ids() -> Array:
	var out := []
	var ids: Array = card.slot_ids()
	for i in 14:
		out.append(str(ids[i]))
	return out


func _keys() -> Array:
	var out := []
	for i in 14:
		out.append(card.key_labels[i].text)
	return out


func _hud_shows(text: String) -> bool:
	for node in main.hud.find_children("*", "Label", true, false):
		if (node as Label).text.contains(text):
			return true
	return false


func _key(physical: Key, printed: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.keycode = printed
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)


func _click(pos: Vector2, button: MouseButton) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.position = pos
	ev.global_position = pos
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up)
