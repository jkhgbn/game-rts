extends SceneTree
## Task 9.C7 (champions.md 9 + ui-champions.md 3-5 and "Done when" 9.C7): champion bar, tavern window, read-only
## champion view, Y / F5-F7, the help line. Runs on the mission 1 map (no taverns / guilds of its own) with stub
## champions, a stub guild, a stub bounty and a stub tavern, so it does not depend on 9.C1-9.C4 / 9.C8.
## Checks, at 1600 x 900:
## - no guild and no tavern: the bar is hidden and Y does nothing; the help panel has the 8th line;
## - the bar: 3 slots 240 x 72 at (16, 408 / 486 / 564) with portrait, name, level, key badge, HP, intent in its
##   colour, purse at the 3.2 offsets; fallen / reviving / empty looks; the 5-line tooltip + 4 item frames;
## - a slot click and F5 / F6 centre the camera and never select or order; a fallen slot (click or F7) opens the
##   tavern with its row highlighted; an empty slot opens it too;
## - the tavern window: 760 x 464 at (420, 156), rows of 90 px at y 204 + 96 k; names A / B, prices, refusal reasons,
##   Hire / Hired / Revive / Returns in / Dismiss (two clicks within 3 s, disarmed after 3 s), closed line + footer;
##   Y opens / closes, Esc closes, a tavern click opens it, the shop and the tavern never show together;
## - the champion view: `current_view() == "champion"`, read-only (no buttons), name / title, HP, XP, stats, intent
##   with target, purse, items, 3 abilities (cooldown sweep, locked L4), autocast line, rects of section 4; own
##   fallen champions stay; a selection change clears it; the enemy variant (no XP / purse / intent) and an enemy
##   hidden by the fog is dropped;
## - nothing in the 9.C7 files calls a `_private` function of another object; the stubs never got an order.
## Run:  godot --headless --path . -s tests/test_9_c7.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "9.c7"
const TIMEOUT_FRAMES := 2400
const WARM_UP := 30
const WARN := Color(0.95, 0.35, 0.3)

## Stands in for Champion (9.C1): the frozen fields the UI reads; it counts every order it receives.
class StubChampion extends Unit:
	var champion_id: StringName = &"coin_cutter"
	var variant := 0
	var display_name := "Sable Quint"
	var purse := 120
	var intent: StringName = &"Hunting bounty"
	var intent_target: Node3D = null
	var inventory: Node = null
	var abilities: Node = null
	var is_unpaid := false
	var fallen := false
	var orders := 0

	func _ready() -> void:
		super._ready()
		add_to_group(&"champions")

	func type_id() -> StringName:
		return champion_id

	func is_commandable() -> bool:
		return false

	func is_alive() -> bool:
		return not fallen and super.is_alive()

	func xp_to_next() -> int:
		return 750

	func take_damage(_amount: float, _attacker: Node3D = null) -> void:
		pass   # the stubs never die during the test (the hero would kill the enemy one)

	func command_move(_p: Vector3) -> void:
		orders += 1

	func command_attack(_t: Unit) -> void:
		orders += 1

	func command_stop() -> void:
		orders += 1


class StubAbilities extends Node:
	func ability_ids() -> Array[StringName]:
		return [&"cutpurse", &"smoke_pouch", &"marked_for_coin"]

	func is_unlocked(id: StringName) -> bool:
		return id != &"marked_for_coin"

	func cooldown_left(id: StringName) -> float:
		return 5.0 if id == &"smoke_pouch" else 0.0


class StubInventory extends Node:
	var slots: Array = [null, null, null, null]


class StubBounty extends Node3D:
	var stake := 150
	var kind := 0
	var target: Node3D = null


class StubTarget extends Node3D:
	var display_name := "Gloom Hall"


## Stands in for ChampionGuild (9.C3): the frozen API, recording the calls.
class StubGuild extends Node:
	var team := 0
	var champions: Array = []
	var open := true
	var reasons := {}
	var cost := {"crystals": 250, "essence": 100}
	var reviving := {}
	var hired: Array = []
	var revived: Array = []
	var dismissed: Array = []

	func _init() -> void:
		add_to_group(&"champion_guilds")

	func is_open() -> bool:
		return open

	func hire_cost(_id: StringName = &"") -> Dictionary:
		return cost

	func can_hire(id: StringName) -> String:
		if not open:
			return "Tavern closed"
		return str(reasons.get(id, ""))

	func hire(id: StringName) -> String:
		var r := can_hire(id)
		if r == "":
			hired.append(id)
		return r

	func can_revive(ch: Node) -> String:
		if ch.is_alive():
			return "Not fallen"
		return "Already reviving" if reviving.has(ch) else ""

	func revive(ch: Node) -> String:
		var r := can_revive(ch)
		if r == "":
			revived.append(ch)
			reviving[ch] = 24.0
		return r

	func revive_time_left(ch: Node) -> float:
		return float(reviving.get(ch, 0.0))

	func dismiss(ch: Node) -> int:
		dismissed.append(ch)
		champions.erase(ch)
		return 10


var main: Node
var hud: Node
var sel: Node
var hero: Node
var bar: Node
var panel: Node
var tavern: Node
var guild: StubGuild
var champs: Array = []        # [coin_cutter alive, oathwall fleeing, mender fallen]
var enemy_champ: StubChampion
var tavern_body: StaticBody3D
var frame := 0
var _wait := 0
var _warm := 0
var _step := 0
var _step_frame := 0
var _error := ""
var _done := false
var _notes: Array[String] = []


var _shot := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_shot = a.trim_prefix("--shot=")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	_warm += 1
	if _warm < WARM_UP:
		return false
	frame += 1
	_run()
	if _error != "":
		print("FAIL %s: %s (step %d)" % [TASK_ID, _error, _step])
		return true
	if _done:
		for n in _notes:
			print("note: ", n)
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out at step %d" % [TASK_ID, _step])
		return true
	return false


func _next() -> void:
	_step += 1
	_step_frame = frame


func _since() -> int:
	return frame - _step_frame


## Windowed runs only:  godot --path . -s tests/test_9_c7.gd --fixed-fps 60 --quit-after 4000 -- --shot=<prefix>
func _save(tag: String) -> void:
	if _shot == "":
		return
	var path := "%s_%s.png" % [_shot, tag]
	root.get_viewport().get_texture().get_image().save_png(path)
	print("screenshot saved: ", path)


func _fail(msg: String) -> void:
	if _error == "":
		_error = msg


func _key(code: Key, pressed := true) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = pressed
	root.push_input(ev)


func _tap(code: Key) -> void:
	_key(code, true)
	_key(code, false)


func _rig() -> Node3D:
	return sel.camera.get_parent() as Node3D


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## True when `c`'s global rect starts at `pos` (+- 1 px) and, when given, has `size`.
func _at(c: Control, pos: Vector2, size := Vector2.ZERO) -> bool:
	var r := c.get_global_rect()
	return r.position.distance_to(pos) <= 1.0 and (size == Vector2.ZERO or r.size.distance_to(size) <= 1.0)


func _run() -> void:
	match _step:
		0:
			root.size = Vector2i(1600, 900)
			hud = main.get("hud")
			sel = main.get("selection")
			hero = main.hero
			if hud == null or sel == null:
				_fail("no HUD / selection")
				return
			_rig().set("edge_pan_enabled", false)   # the headless mouse sits at (0, 0): no edge pan
			bar = hud.get("champion_bar")
			panel = hud.get("selection_panel")
			tavern = hud.get("tavern_window")
			if bar == null or tavern == null:
				_fail("HUD has no champion_bar / tavern_window")
				return
			# A map without taverns: no guild -> bar hidden, Y does nothing.
			for g in get_nodes_in_group(&"champion_guilds"):
				g.remove_from_group(&"champion_guilds")
			for t in get_nodes_in_group(&"taverns"):
				t.remove_from_group(&"taverns")
			bar.refresh()
			if bar.visible:
				_fail("champion bar visible without a guild / tavern")
				return
			_tap(KEY_Y)
			_check_help()
			_next()
		1:
			if tavern.is_open():
				_fail("Y opened the tavern window without a guild")
				return
			_spawn_stubs()
			_next()
		2:
			if _since() < 3:
				return
			bar.refresh()
			_check_bar()
			if _error == "":
				_check_bar_clicks()
			_next()
		3:
			_save("bar")
			# F6: centre on champion 2 (never selects).
			sel.select_units([hero])
			_rig().position = Vector3(40, 0, 40)
			_tap(KEY_F6)
			_next()
		4:
			if _flat(_rig().position, champs[1].global_position) > 0.5:
				_fail("F6 did not centre the camera on champion 2")
				return
			if sel.selected.size() != 1 or sel.selected[0] != hero or champs[1].selected:
				_fail("F6 changed the selection")
				return
			_rig().position = Vector3(40, 0, 40)
			_tap(KEY_F5)
			_next()
		5:
			if _flat(_rig().position, champs[0].global_position) > 0.5:
				_fail("F5 did not centre the camera on champion 1")
				return
			# F7 on the fallen champion opens the tavern at its row.
			_tap(KEY_F7)
			_next()
		6:
			if not tavern.is_open() or tavern.highlighted != &"mender":
				_fail("F7 on a fallen champion did not open the tavern at the Mender row (open %s, row %s)"
						% [tavern.is_open(), tavern.highlighted])
				return
			_tap(KEY_ESCAPE)
			_next()
		7:
			if tavern.is_open():
				_fail("Esc did not close the tavern window")
				return
			bar.press_slot(2)   # a click on the fallen slot does the same
			if not tavern.is_open() or tavern.highlighted != &"mender":
				_fail("fallen slot click did not open the tavern at the Mender row")
				return
			tavern.close()
			_tap(KEY_Y)
			_next()
		8:
			if not tavern.is_open():
				_fail("Y did not open the tavern window")
				return
			if tavern.highlighted != &"":
				_fail("Y highlighted a row")
				return
			_check_tavern_rows()
			if _error != "":
				return
			_check_revive_dismiss()
			_next()
		9:
			# The first Dismiss click armed row 1 (Oathwall); after 3 s it disarms.
			if _since() == 5:
				_save("tavern")
			if _since() < 190:
				return
			if tavern.is_dismiss_armed(1) or tavern.rows[1].dismiss_button.text != "Dismiss":
				_fail("dismiss still armed after 3 s")
				return
			if tavern.press_dismiss(1):
				_fail("a single click after the 3 s window dismissed the champion")
				return
			if not tavern.press_dismiss(1) or not guild.dismissed.has(champs[1]):
				_fail("two clicks within 3 s did not dismiss the Oathwall")
				return
			tavern.refresh()
			if not tavern.rows[1].hire_button.visible:
				_fail("the Oathwall row does not offer Hire again after the dismiss")
				return
			_tap(KEY_Y)
			_next()
		10:
			if tavern.is_open():
				_fail("Y did not close the tavern window")
				return
			bar.refresh()
			var s2: Node = bar.slots[2]
			if s2.state != &"empty" or not s2.plus_label.visible or s2.hire_label.text != "Hire a champion" \
					or s2.tavern_label.text != "Y · tavern":
				_fail("empty slot look: state %s, '%s' / '%s'" % [s2.state, s2.hire_label.text, s2.tavern_label.text])
				return
			bar.press_slot(2)
			if not tavern.is_open() or tavern.highlighted != &"":
				_fail("empty slot click did not open the tavern window (without a highlight)")
				return
			# Hire: the Wayfinder is free now.
			guild.reasons.erase(&"wayfinder")
			tavern.refresh()
			if tavern.rows[0].hire_button.disabled or tavern.press_hire(0) != "" or not guild.hired.has(&"wayfinder"):
				_fail("Hire did not call guild.hire(wayfinder)")
				return
			# Closed tavern: row reason, title line, footer; the empty bar slot says so too.
			guild.open = false
			tavern.refresh()
			bar.refresh()
			if tavern.rows[0].reason_label.text != "Tavern closed" or not tavern.rows[0].hire_button.disabled \
					or tavern.closed_label.text != "The tavern opens at 2:00":
				_fail("closed tavern: reason '%s', line '%s'" % [tavern.rows[0].reason_label.text, tavern.closed_label.text])
				return
			if not (tavern.footer.text == "Upkeep 1 essence / 10 s per champion · Tavern opens at 2:00"
					or tavern.footer.text == "Champions not available"):
				_fail("footer '%s'" % tavern.footer.text)
				return
			if tavern.footer.text == "Champions not available":
				_notes.append("no data/champions/*.tres yet: footer says 'Champions not available'")
			if s2.tavern_label.text != "Tavern opens at 2:00" or not s2.tooltip_text.ends_with("Tavern opens at 2:00"):
				_fail("closed tavern: empty slot says '%s'" % s2.tavern_label.text)
				return
			guild.open = true
			# The shop and the tavern never show together.
			var shop: Control = hud.get("shop_window")
			shop.visible = true
			tavern.open()
			if shop.visible:
				_fail("opening the tavern left the shop open")
				return
			shop.emit_signal(&"opened")
			if tavern.is_open():
				_fail("opening the shop left the tavern open")
				return
			_add_tavern()
			_next()
		11:
			if _since() < 3:
				return
			# A left click on the tavern opens the window.
			var pos: Vector2 = sel.camera.unproject_position(tavern_body.global_position + Vector3(0, 1, 0))
			var ev := InputEventMouseButton.new()
			ev.button_index = MOUSE_BUTTON_LEFT
			ev.position = pos
			ev.global_position = pos
			ev.pressed = true
			root.push_input(ev)
			var up := ev.duplicate() as InputEventMouseButton
			up.pressed = false
			root.push_input(up)
			_next()
		12:
			if not tavern.is_open():
				_fail("clicking the tavern did not open the window")
				return
			tavern.close()
			sel.select_units([hero])
			panel.inspect(champs[0])   # (the area lays the view out at the end of the frame)
			_next()
		13:
			if _since() < 12:   # the view fades in over 0.1 s
				return
			_save("champion")
			_check_champion_view()
			_next()
		14:
			if _since() < 2:
				return
			_check_champion_view_cleared()
			_next()
		15:
			if _since() < 2:
				return
			_check_enemy_view()
			_next()
		16:
			if _since() < 3:
				return
			if panel.inspected_champion() != null:
				_fail("an enemy champion hidden by the fog stays inspected")
				return
			_check_no_private_calls()
			if _error != "":
				return
			# The selection manager's own inspect (9.C8), when it exists: the panel follows `selection.inspected`.
			if not sel.has_method(&"inspect_unit"):
				_notes.append("SelectionManager.inspect_unit missing: selection.inspected path not exercised")
				_step = 18
				return
			sel.call(&"inspect_unit", champs[0])
			_next()
		17:
			if _since() < 2:
				return
			if panel.current_view() != "champion" or panel.champion_name.text != "Sable Quint":
				_fail("selection.inspected not shown (view %s)" % panel.current_view())
				return
			var card: Node = hud.get("command_card")
			var hint := false
			for l in card.find_children("*", "Label", true, false):
				if (l as Label).is_visible_in_tree() and (l as Label).text.contains("Champions act on their own"):
					hint = true
			if not hint:
				_fail("command card lacks 'Champions act on their own.' while a champion is inspected")
				return
			sel.select_units([hero])
			_next()
		18:
			if panel.current_view() == "champion":
				_fail("the champion view stayed after selecting the wizard")
				return
			for c: StubChampion in champs:
				if is_instance_valid(c) and c.orders > 0:
					_fail("%s received %d orders" % [c.display_name, c.orders])
					return
			_done = true


# ---------------------------------------------------------------- setup

func _spawn_stubs() -> void:
	guild = StubGuild.new()
	guild.name = "StubGuild"
	main.add_child(guild)
	var base: Vector3 = hero.global_position
	var specs := [
		[&"coin_cutter", "Sable Quint", 3, 500, &"Hunting bounty", Vector3(4, 0, 3)],
		[&"oathwall", "Garran Stoneward", 2, 200, &"fleeing", Vector3(-4, 0, 3)],
		[&"mender", "Orla Fenwick", 3, 450, &"Fallen", Vector3(0, 0, -5)],
	]
	for s in specs:
		var c := StubChampion.new()
		c.champion_id = s[0]
		c.display_name = s[1]
		c.unit_name = s[1]
		c.team = Unit.Team.PLAYER
		c.max_hp = 300.0
		c.attack_damage = 17.0
		c.attack_range = 1.6
		c.move_speed = 5.6
		main.add_child(c)
		c.global_position = base + (s[5] as Vector3)
		c.level = s[2]
		c.xp = s[3]
		c.intent = s[4]
		champs.append(c)
		guild.champions.append(c)
	var cc: StubChampion = champs[0]
	cc.hp = 210.0
	cc.set_base_stat(&"armor", 5.0)
	cc.abilities = StubAbilities.new()
	cc.add_child(cc.abilities)
	var inv := StubInventory.new()
	cc.add_child(inv)
	cc.inventory = inv
	if ResourceLoader.exists("res://data/items/ember_shard.tres"):
		inv.slots[0] = {"type": load("res://data/items/ember_shard.tres"), "count": 1}
	else:
		_notes.append("no ember_shard.tres: item icon check skipped")
	var bounty := StubBounty.new()
	var target := StubTarget.new()
	main.add_child(target)
	main.add_child(bounty)
	bounty.target = target
	cc.intent_target = bounty
	champs[1].purse = 35
	champs[2].fallen = true
	champs[2].purse = 80
	guild.reasons = {&"wayfinder": "Max 3 champions", &"oathwall": "Already hired"}
	sel.select_units([hero])


func _add_tavern() -> void:
	tavern_body = StaticBody3D.new()
	tavern_body.collision_layer = 2
	tavern_body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6, 6, 6)
	shape.shape = box
	shape.position = Vector3(0, 3, 0)
	tavern_body.add_child(shape)
	tavern_body.add_to_group(&"taverns")
	main.add_child(tavern_body)
	var spot: Vector3 = hero.global_position + Vector3(10, 0, 10)
	tavern_body.global_position = spot
	_rig().position = Vector3(spot.x, 0, spot.z)


# ---------------------------------------------------------------- checks

func _check_help() -> void:
	var ok := false
	for node in hud.find_children("*", "Label", true, false):
		# Step 10 reflowed the help text to 11 lines (ui-trade.md 14.1): the champion keys now span two lines.
		if (node as Label).text.contains("R: bounty (Shift+click: stay)    Y: tavern    F5-F7: find champion\n"
				+ "Flag: Z raise · Delete remove"):
			ok = true
	if not ok:
		_fail("help text lacks the champion line")


func _check_bar() -> void:
	if not bar.visible:
		_fail("champion bar hidden with a guild")
		return
	# SC2.U3 (ui-sc2-console.md 3.2): three compact 240 x 52 slots from (8, 380).
	if bar.slots.size() != 3 or not _at(bar, Vector2(8, 380), Vector2(240, 164)):
		_fail("bar rect %s" % bar.get_global_rect())
		return
	for k in 3:
		if not _at(bar.slots[k], Vector2(8, 380 + 56 * k), Vector2(240, 52)):
			_fail("slot %d rect %s" % [k, bar.slots[k].get_global_rect()])
			return
	var s0: Node = bar.slots[0]
	var o := Vector2(8, 380)
	if not _at(s0.face, o + Vector2(4, 4), Vector2(44, 44)) or not _at(s0.name_label, o + Vector2(54, 3)) \
			or not _at(s0.key_badge, o + Vector2(210, 4), Vector2(26, 15)) \
			or not _at(s0.hp_bar, o + Vector2(54, 22), Vector2(150, 10)) or not _at(s0.intent_label, o + Vector2(54, 34)) \
			or not _at(s0.medallion, o + Vector2(36, 32), Vector2(18, 18)):
		_fail("slot parts not at the 3.2 offsets")
		return
	if s0.name_label.text != "Sable Quint" or s0.level_label.text != "3" or s0.purse_label.text != "120" \
			or s0.key_label.text != "F5":
		_fail("slot 1 shows '%s' L%s purse %s" % [s0.name_label.text, s0.level_label.text, s0.purse_label.text])
		return
	if not s0.face.visible or s0.face.champion_id != &"coin_cutter" or (s0.face.is_placeholder() and s0.face.letters() != "SQ"):
		_fail("slot 1 portrait: id %s letters '%s'" % [s0.face.champion_id, s0.face.letters()])
		return
	if absf(s0.hp_bar.value - 210.0) > 0.5 or absf(s0.hp_bar.max_value - 300.0) > 0.5 or s0.hp_text.text != "210 / 300":
		_fail("slot 1 HP bar %.0f / %.0f '%s'" % [s0.hp_bar.value, s0.hp_bar.max_value, s0.hp_text.text])
		return
	if s0.intent_label.text != "Hunting bounty" \
			or not s0.intent_label.get_theme_color("font_color").is_equal_approx(Color(1.0, 0.85, 0.4)):
		_fail("slot 1 intent '%s' colour %s" % [s0.intent_label.text, s0.intent_label.get_theme_color("font_color")])
		return
	var s1: Node = bar.slots[1]
	if s1.intent_label.text != "Fleeing" \
			or not s1.intent_label.get_theme_color("font_color").is_equal_approx(Color(0.95, 0.35, 0.3)):
		_fail("slot 2 intent '%s' (from &\"fleeing\")" % s1.intent_label.text)
		return
	var s2: Node = bar.slots[2]
	if s2.state != &"fallen" or s2.intent_label.text != "Fallen" or s2.hp_text.text != "0 / 300" \
			or s2.purse_label.text != "80" or not s2.purse_box.visible:
		_fail("fallen slot: state %s '%s' HP '%s'" % [s2.state, s2.intent_label.text, s2.hp_text.text])
		return
	guild.reviving[champs[2]] = 23.2
	bar.refresh()
	if s2.state != &"reviving" or s2.intent_label.text != "Returns in 24 s" \
			or not s2.intent_label.get_theme_color("font_color").is_equal_approx(WARN):
		_fail("reviving slot shows '%s'" % s2.intent_label.text)
		return
	guild.reviving.erase(champs[2])
	bar.refresh()
	# Tooltip (3.4): 5 lines; the custom tooltip adds the 4 item frames.
	var lines: PackedStringArray = s0.tooltip_text.split("\n")
	if lines.size() != 5 or lines[0] != "Sable Quint  [F5]  the Coin-Cutter" \
			or lines[1] != "Level 3 · XP 500 / 750 · HP 210 / 300 · Purse 120" \
			or lines[2] != "Loves a bounty more than a fair fight." or lines[3] != "Hunting bounty: Gloom Hall (150)" \
			or not lines[4].begins_with("Items: "):
		_fail("slot 1 tooltip:\n%s" % s0.tooltip_text)
		return
	var custom: Control = s0._make_custom_tooltip(s0.tooltip_text)
	var icons := custom.find_children("*", "Panel", true, false).filter(
			func(n: Node) -> bool: return n.has_method(&"set_item"))
	custom.free()
	if icons.size() != 4:
		_fail("slot tooltip shows %d item frames, expected 4" % icons.size())


func _check_bar_clicks() -> void:
	sel.select_units([hero])
	_rig().position = Vector3(40, 0, 40)
	bar.press_slot(0)
	if _flat(_rig().position, champs[0].global_position) > 0.5:
		_fail("slot click did not centre the camera (%s vs %s)" % [_rig().position, champs[0].global_position])
		return
	if sel.selected.size() != 1 or sel.selected[0] != hero or sel.selected_building != null or champs[0].selected:
		_fail("slot click changed the selection")
		return
	if sel.get("inspected") != null:
		_fail("slot click set selection.inspected")
		return
	if tavern.is_open():
		_fail("a living champion's slot opened the tavern window")


func _check_tavern_rows() -> void:
	if not _at(tavern, Vector2(420, 156), Vector2(760, 464)):
		_fail("tavern rect %s" % tavern.get_global_rect())
		return
	if tavern.rows.size() != 4:
		_fail("tavern has %d rows" % tavern.rows.size())
		return
	for k in 4:
		if not _at(tavern.rows[k], Vector2(430, 204 + 96 * k), Vector2(740, 90)):
			_fail("row %d rect %s" % [k, tavern.rows[k].get_global_rect()])
			return
	var names := ["Tamsin Farrow", "Garran Stoneward", "Sable Quint", "Orla Fenwick"]
	var titles := [" · the Wayfinder", " · the Oathwall", " · the Coin-Cutter", " · the Mender"]
	for k in 4:
		var r: Node = tavern.rows[k]
		if r.name_label.text != names[k] or r.title_label.text != titles[k]:
			_fail("row %d name '%s%s'" % [k, r.name_label.text, r.title_label.text])
			return
		if r.personality_label.text == "" or r.ability_labels.size() != 3 or r.role_label.text == "":
			_fail("row %d lacks personality / role / 3 ability lines" % k)
			return
	var cc: Node = tavern.rows[2]
	if not cc.stats_label.text.begins_with("300 HP · 17 damage · 1.6 range · 5.6 speed") \
			or cc.role_label.text != "Raider, melee" or not cc.ability_labels[0].text.begins_with("Cutpurse · "):
		_fail("Coin-Cutter stats '%s' role '%s' ability '%s'" % [cc.stats_label.text, cc.role_label.text,
				cc.ability_labels[0].text])
		return
	# Wayfinder: not hired, price + refusal reason, Hire disabled.
	var w: Node = tavern.rows[0]
	if w.price_crystals.text != "250" or w.price_essence.text != "100" or w.pop_label.text != "Pop 2":
		_fail("price %s / %s / '%s'" % [w.price_crystals.text, w.price_essence.text, w.pop_label.text])
		return
	# The row's own key (2026-09-29): row 1 hires with Z (Y only opens / closes the window).
	if not w.hire_button.visible or not w.hire_button.disabled or w.reason_label.text != "Max 3 champions" \
			or not w.reason_label.visible or not w.hire_button.tooltip_text.begins_with("Hire  [Z]"):
		_fail("Wayfinder Hire: visible %s disabled %s reason '%s'" % [w.hire_button.visible, w.hire_button.disabled,
				w.reason_label.text])
		return
	if tavern.press_hire(0) != "Max 3 champions" or not guild.hired.is_empty():
		_fail("a refused hire went through")
		return
	# Coin-Cutter: hired, alive.
	if cc.state != &"hired" or cc.status_label.text != "Hired · Level 3" \
			or cc.intent_label.text != "Hunting bounty: Gloom Hall (150)" or cc.purse_label.text != "120" \
			or cc.hire_button.visible or not cc.dismiss_button.visible or cc.revive_button.visible:
		_fail("hired row: '%s' / '%s'" % [cc.status_label.text, cc.intent_label.text])
		return
	# Mender: fallen -> Revive 185 (step 11 fallback: 80 + 35 x 3) + Dismiss.
	var m: Node = tavern.rows[3]
	if m.state != &"fallen" or m.status_label.text != "Fallen · Level 3" or not m.revive_button.visible \
			or m.revive_button.text != "Revive 185" or m.revive_button.disabled or not m.dismiss_button.visible:
		_fail("fallen row: '%s' revive '%s'" % [m.status_label.text, m.revive_button.text])
		return
	# An enemy Wayfinder (name A) makes ours name B.
	enemy_champ = StubChampion.new()
	enemy_champ.champion_id = &"wayfinder"
	enemy_champ.display_name = "Tamsin Farrow"
	enemy_champ.unit_name = "Tamsin Farrow"
	enemy_champ.team = Unit.Team.ENEMY
	enemy_champ.attack_damage = 0.0
	enemy_champ.intent = &"exploring"
	main.add_child(enemy_champ)
	enemy_champ.global_position = hero.global_position + Vector3(3, 0, 0)
	tavern.refresh()
	if w.name_label.text != "Tobin Farrow":
		_fail("our Wayfinder should be name B when the enemy has name A: '%s'" % w.name_label.text)


func _check_revive_dismiss() -> void:
	if tavern.press_revive(3) != "" or not guild.revived.has(champs[2]):
		_fail("Revive did not call guild.revive(mender)")
		return
	var m: Node = tavern.rows[3]
	if m.state != &"reviving" or m.intent_label.text != "Returns in 24 s" or m.revive_button.visible:
		_fail("reviving row: '%s'" % m.intent_label.text)
		return
	# Dismiss: the first click only arms it.
	if tavern.press_dismiss(1) or not guild.dismissed.is_empty():
		_fail("one Dismiss click dismissed the champion")
		return
	if not tavern.is_dismiss_armed(1) or tavern.rows[1].dismiss_button.text != "Confirm?":
		_fail("Dismiss not armed after one click ('%s')" % tavern.rows[1].dismiss_button.text)


func _check_champion_view() -> void:
	if panel.current_view() != "champion":
		_fail("champion view not shown (view %s)" % panel.current_view())
		return
	if panel.champion_name.text != "Sable Quint" or panel.champion_title.text != " · the Coin-Cutter":
		_fail("champion name '%s%s'" % [panel.champion_name.text, panel.champion_title.text])
		return
	# SC2.U1 / U4 (ui-sc2-console.md 4.2-4.3): the view from the selection block's content (252, 696), the portrait in
	# the portrait window (1144, 696).
	if not _at(panel.champion_hp, Vector2(252, 726), Vector2(280, 22)) \
			or not _at(panel.champion_xp, Vector2(252, 752), Vector2(280, 14)) \
			or not _at(panel.champion_items[0], Vector2(252, 852), Vector2(36, 36)) \
			or not _at(panel.champion_items[3], Vector2(372, 852)) \
			or not _at(panel.champion_abilities[0], Vector2(660, 710), Vector2(48, 48)) \
			or not _at(panel.champion_abilities[2], Vector2(768, 710)) or not _at(panel.portrait, Vector2(1144, 696)):
		_fail("champion view rects: HP %s items %s abilities %s portrait %s (panel %s, view %s)" % [
				panel.champion_hp.get_global_rect(), panel.champion_items[0].get_global_rect(),
				panel.champion_abilities[0].get_global_rect(), panel.portrait.get_global_rect(), panel.get_global_rect(),
				panel.champion_view.get_global_rect()])
		return
	if panel.champion_hp_text.text != "HP  210 / 300" or panel.champion_xp_text.text != "XP  500 / 750" \
			or not panel.champion_xp.visible:
		_fail("champion HP '%s' XP '%s'" % [panel.champion_hp_text.text, panel.champion_xp_text.text])
		return
	var stats: String = panel.champion_stats.text
	if stats != "Level 3 · Damage 17 · Range 1.6 · Speed 5.6 · Armor 5":
		_fail("champion stats '%s'" % stats)
		return
	if panel.champion_intent.text != "Hunting bounty: Gloom Hall (150)" or panel.champion_purse.text != "120" \
			or not panel.champion_purse_box.visible:
		_fail("champion intent '%s' purse '%s'" % [panel.champion_intent.text, panel.champion_purse.text])
		return
	if panel.champion_items.size() != 4:
		_fail("champion view shows %d item slots" % panel.champion_items.size())
		return
	if champs[0].inventory.slots[0] != null and panel.champion_items[0].item_type == null:
		_fail("champion item slot 1 empty")
		return
	if panel.champion_ability_list() != "Cutpurse, Smoke Pouch, Marked for Coin":
		_fail("champion abilities '%s'" % panel.champion_ability_list())
		return
	var smoke: Node = panel.champion_abilities[1]
	if smoke.seconds.text != "5" or smoke.ratio <= 0.0:
		_fail("Smoke Pouch cooldown not shown ('%s', %.2f)" % [smoke.seconds.text, smoke.ratio])
		return
	var mark: Node = panel.champion_abilities[2]
	if mark.modulate.a > 0.5 or not mark.badge.visible or not mark.tooltip_text.contains("Unlocks at level 4"):
		_fail("locked Marked for Coin not dimmed / badged")
		return
	# Step 11 (ui-champions.md 15.3): the lowest unlock level still ahead (the 3rd ability at 4; the `?` class slots).
	if panel.champion_autocast.text != "Autocast · next at level 4":
		_fail("autocast line '%s'" % panel.champion_autocast.text)
		return
	# Read only: no buttons at all in the view.
	if not panel.champion_view.find_children("*", "BaseButton", true, false).is_empty():
		_fail("champion view has buttons")
		return
	if sel.selected.size() != 1 or sel.selected[0] != hero:
		_fail("inspecting changed the selection")
		return
	# An own fallen champion stays inspectable (the Mender is reviving since the tavern step).
	panel.inspect(champs[2])
	if panel.current_view() != "champion" or panel.champion_intent.text != "Returns in 24 s" \
			or not panel.champion_intent.get_theme_color("font_color").is_equal_approx(WARN):
		_fail("own fallen champion: view %s intent '%s'" % [panel.current_view(), panel.champion_intent.text])
		return
	panel.inspect(champs[0])


func _check_champion_view_cleared() -> void:
	if panel.current_view() != "champion":
		_fail("champion view did not stay")
		return
	sel.select_units([hero])   # any selection change drops the inspected champion
	panel.refresh()
	if panel.current_view() != "single" or panel.inspected != null:
		_fail("selection change kept the champion view (%s)" % panel.current_view())


func _check_enemy_view() -> void:
	panel.inspect(enemy_champ)
	if panel.current_view() != "champion" or panel.champion_name.text != "Tamsin Farrow":
		_fail("visible enemy champion not inspectable (view %s)" % panel.current_view())
		return
	if panel.champion_intent.text != "Enemy champion" or panel.champion_purse_box.visible or panel.champion_xp.visible:
		_fail("enemy variant: intent '%s' purse %s XP %s" % [panel.champion_intent.text,
				panel.champion_purse_box.visible, panel.champion_xp.visible])
		return
	enemy_champ.visible = false   # the fog hides it


## "Nothing in scripts/ui/ calls a _private function": the 9.C7 files never call `x._name(` or `call(&"_name"`.
func _check_no_private_calls() -> void:
	var re := RegEx.create_from_string("[A-Za-z0-9_\\)\\]]\\._[a-z]\\w*\\(|call\\(&?\"_")
	for path in ["res://scripts/ui/champion_bar.gd", "res://scripts/ui/tavern_window.gd",
			"res://scripts/ui/selection_panel.gd", "res://scripts/ui/hud.gd"]:
		var text := FileAccess.get_file_as_string(path)
		var lines := text.split("\n")
		for i in lines.size():
			var line: String = lines[i]
			if line.strip_edges().begins_with("#") or line.contains("super._"):
				continue
			if re.search(line) != null:
				_fail("%s:%d calls a private function: %s" % [path, i + 1, line.strip_edges()])
				return
