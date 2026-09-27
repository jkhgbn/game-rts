extends SceneTree
## Test for 4.U1b (shop window, scripts/ui/shop_window.gd) on the 1v1 map:
## - Vessa next to her keep: `open(keep)` shows the window at (480, 200), 640 x 440, with the item grid;
## - the grid lists the base stock (real data/items when present, else 3 stand-in items);
## - the Buy button calls `inventory.buy(type)` (a recording inventory proves the call; the real one is
##   also tried when it exists and its answer shown);
## - Esc closes, toggle() reopens, walking 20 m away closes it; `open()` far from shops says "No shop nearby".
## Run:  godot --headless --path . -s tests/test_4_u1b.gd --fixed-fps 60 --quit-after 3000
## Windowed screenshot:  godot --path . -s tests/test_4_u1b.gd --fixed-fps 60 --quit-after 3000 -- --shot=<png>

const TASK_ID := "4.u1b"
const TIMEOUT_FRAMES := 900
const WARM_UP := 60

var main: Node
var hero: Node
var keep: Node
var win: Node
var fake_inv: Object
var frame := 0
var _wait := 0
var _step := 0
var _step_frame := 0
var _error := ""
var _shot := ""
var _messages: Array = []
var _real_note := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_shot = a.trim_prefix("--shot=")
	main = load("res://scenes/skirmish.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame < WARM_UP:
		return false
	if frame == WARM_UP:
		_setup()
	if _error == "":
		_run()
	if _error != "":
		print("FAIL %s: %s" % [TASK_ID, _error])
		return true
	if _step >= 99:
		print("PASS %s%s" % [TASK_ID, _real_note])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out at step %d" % [TASK_ID, _step])
		return true
	return false


func _setup() -> void:
	hero = main.hero
	keep = main.keep
	var shop_script: Variant = load("res://scripts/ui/shop_window.gd")
	win = shop_script.attach(main.hud, hero)
	win.message.connect(func(t: String) -> void: _messages.append(t))
	# Park Vessa 7 m from her keep, standing still.
	_place_hero(7.0)
	# Stand-in items when data/items is not written yet.
	var types: Array = win.all_item_types()
	if types.is_empty():
		types.append_array(_fake_types())
	# The real inventory, when it exists, gets one real buy attempt (answer printed).
	var real_inv: Variant = hero.get("inventory")
	if real_inv != null and real_inv.has_method(&"buy"):
		_real_note = " (real inventory present)"
	fake_inv = _fake_inventory()


func _run() -> void:
	match _step:
		0:
			if not win.open(keep):
				_error = "open(keep) refused next to the keep: %s" % str(_messages)
				return
			if not win.visible or win.position != Vector2(480, 200) or win.size != Vector2(640, 440):
				_error = "window not shown at (480, 200) 640 x 440: %s %s" % [win.position, win.size]
				return
			if win.item_buttons.is_empty():
				_error = "the grid lists no items"
				return
			_next()
		1:
			if _since() < 5:
				return
			# Real inventory: one real buy through the button (whatever the answer, it must come back).
			if hero.get("inventory") != null:
				win.last_buy_result = "<unset>"
				win._buy.disabled = false
				win._buy.pressed.emit()
				if win.last_buy_result == "<unset>":
					_error = "Buy button did not call the real inventory"
					return
				_real_note += " real buy -> '%s'" % win.last_buy_result
			# Recording inventory: the Buy button calls buy(type) with the selected item.
			win.inventory_override = fake_inv
			win._build_grid()
			win._refresh()
			var first: Variant = win.item_buttons[0].get_meta("item_type")
			win.item_buttons[0].pressed.emit()
			if win._buy.disabled:
				_error = "Buy disabled with the recording inventory (reason '%s')" % win._reason.text
				return
			win._buy.pressed.emit()
			if fake_inv.get("buy_calls") != [first]:
				_error = "Buy did not call inventory.buy(first item): %s" % str(fake_inv.get("buy_calls"))
				return
			if not _messages.has("Bought %s" % win.name_of(first)):
				_error = "no 'Bought ...' message: %s" % str(_messages)
				return
			# A refusal shows its reason.
			fake_inv.set("refuse", "Not enough essence")
			win._buy.pressed.emit()
			if win._reason.text != "Not enough essence" or _messages.back() != "Not enough essence":
				_error = "refusal reason not shown: '%s'" % win._reason.text
				return
			fake_inv.set("refuse", "")
			win.inventory_override = null
			_next()
		2:
			if _shot != "" and _since() < 40:
				return
			if _shot != "":
				var img := root.get_viewport().get_texture().get_image()
				img.save_png(_shot)
				print("screenshot saved: ", _shot)
			# Esc closes.
			var esc := InputEventKey.new()
			esc.physical_keycode = KEY_ESCAPE
			esc.keycode = KEY_ESCAPE
			esc.pressed = true
			root.push_input(esc)
			_next()
		3:
			if _since() < 3:
				return
			if win.visible:
				_error = "Esc did not close the window"
				return
			win.toggle()   # T: reopens on the nearest shop (the keep answers is_shop() when 4.S1 is in)
			if not win.visible:
				win.open(keep)
			if not win.visible:
				_error = "could not reopen"
				return
			_place_hero(20.0)
			_next()
		4:
			if _since() < 5:
				return
			if win.visible:
				_error = "still open 20 m from the keep"
				return
			_messages.clear()
			if win.open(keep) or not _messages.has("No shop nearby"):
				_error = "open() out of range did not answer 'No shop nearby': %s" % str(_messages)
				return
			_step = 99


func _next() -> void:
	_step += 1
	_step_frame = frame


func _since() -> int:
	return frame - _step_frame


func _place_hero(dist: float) -> void:
	var k: Vector3 = keep.global_position
	var toward_centre := Vector3(-k.x, 0, -k.z).normalized()
	if toward_centre == Vector3.ZERO:
		toward_centre = Vector3.RIGHT
	var p := k + toward_centre * dist
	p.y = hero.global_position.y
	hero.global_position = p
	if hero.has_method(&"command_stop"):
		hero.call(&"command_stop")
	elif hero.has_method(&"command_move"):
		hero.call(&"command_move", p)


func _fake_types() -> Array:
	var src := """extends Resource
var id := ""
var display_name := ""
var tier := 0
var cost := 0
var parts: Array = []
var stats := {}
var tooltip := ""
func total_cost() -> int:
	var t := cost
	for p in parts:
		t += p.total_cost()
	return t
"""
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	var a: Resource = s.new()
	a.id = "ember_shard"; a.display_name = "Ember Shard"; a.tier = 0; a.cost = 200; a.stats = {"attack_damage": 12}
	var b: Resource = s.new()
	b.id = "whetted_fang"; b.display_name = "Whetted Fang"; b.tier = 0; b.cost = 200
	b.stats = {"attack_cooldown_pct": -0.12}
	var c: Resource = s.new()
	c.id = "blazing_edge"; c.display_name = "Blazing Edge"; c.tier = 1; c.cost = 250; c.parts = [a, b]
	c.stats = {"attack_damage": 20, "attack_cooldown_pct": -0.12}
	c.tooltip = "Searing Strikes: attacks burn for 16 over 2 s."
	return [a, b, c]


func _fake_inventory() -> Object:
	var src := """extends RefCounted
var slots: Array = [null, null, null, null, null, null]
var artifacts: Array = [null, null]
var buy_calls: Array = []
var refuse := ""
func can_buy(_type) -> String:
	return refuse
func buy(type) -> String:
	buy_calls.append(type)
	return refuse
func sell(_slot: int) -> int:
	return 0
"""
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	return s.new()
