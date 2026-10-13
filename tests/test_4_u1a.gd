extends SceneTree
## Test for 4.U1a on the 1v1 map (scenes/skirmish.tscn):
## - inventory bar (SC2.U3 hero tile): 6 slots 32 at (10 + i x 33, 612), artifact slot at (212, 552) (1600 x 900);
## - essence in the top bar (520 x 40 at (540, 8); spec 500 at 550 + the 20 px pop-200 number) matching EssenceBank.for_team(0);
## - an Ember Shard shows "ES", its tooltip "Ember Shard  [Num 1]" / "+12 damage" / "Sell 100";
## - Numpad 2 uses the Ember Draught in slot 2 (a charge goes, cooldown sweep) and never touches groups;
## - swap, drop (right click away from shops) and right-click pickup round-trip;
## - Numpad on a Blink item starts the item targeting.
## Run:  godot --headless --path . -s tests/test_4_u1a.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "4.u1a"
const TIMEOUT_FRAMES := 900
const WARM_UP := 60

var main: Node
var hud: Node
var bar: Node
var sel: Node
var hero: Node
var inv: Node
var frame := 0
var _wait := 0
var _warm := 0
var _error := ""
var _done := false
var _pickup: Node = null
var _stage := 0


func _initialize() -> void:
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
	_warm += 1
	if _warm < WARM_UP:
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
		print("FAIL %s: timed out at frame %d (stage %d)" % [TASK_ID, frame, _stage])
		return true
	return false


func _type(id: String) -> Object:
	var script: Script = load("res://scripts/items/item_type.gd")
	return script.call(&"find", StringName(id))


func _key(code: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate()
	up.pressed = false
	root.push_input(up)


func _step() -> void:
	match frame:
		1:
			hud = main.get("hud")
			sel = main.get("selection")
			hero = main.hero
			if hud == null or hud.get("inventory_bar") == null:
				_error = "no inventory bar on the HUD"
				return
			bar = hud.inventory_bar
			inv = bar.inventory()
			if inv == null:
				_error = "Vessa has no inventory"
				return
			root.size = Vector2i(1600, 900)
		4:
			var vp: Vector2 = root.get_visible_rect().size
			print("viewport ", vp)
			if vp == Vector2(1600, 900):
				for i in 6:
					var p: Vector2 = bar.slot_controls[i].get_global_rect().position
					if p != Vector2(10 + i * 33, 612):
						_error = "slot %d at %s" % [i, p]
						return
				var a: Vector2 = bar.slot_controls[6].get_global_rect().position
				if a != Vector2(212, 552):
					_error = "artifact slot at %s" % a
					return
		5:
			var tb: Node = hud.top_bar
			if tb.essence_bank == null or not tb.essence_label.visible:
				_error = "essence not in the top bar"
				return
			if tb.essence_label.text != str(int(tb.essence_bank.essence)):
				_error = "essence label %s vs %s" % [tb.essence_label.text, tb.essence_bank.essence]
				return
			var r: Rect2 = tb.get_global_rect()
			# SC2.U2 (ui-sc2-console.md 1): 96 x 32 items ending at x 1592 (the pop item a little wider: "200 / 200").
			var gold_on: bool = tb.get("gold_bank") != null
			var min_w := 384.0 if gold_on else 288.0
			if root.get_visible_rect().size == Vector2(1600, 900) and (absf(r.end.x - 1592.0) > 0.5 or r.position.y != 8.0
					or r.size.y != 32.0 or r.size.x < min_w):
				_error = "top bar rect %s" % r
				return
			inv.add_item(_type("ember_shard"))
			inv.add_item(_type("ember_draught"), 3)
		8:
			if str(bar.entry_type(0).id) != "ember_shard" or ItemTooltip.abbrev(bar.entry_type(0)) != "ES":
				_error = "slot 1 does not show Ember Shard (%s)" % ItemTooltip.abbrev(bar.entry_type(0))
				return
			var tip: String = bar.slot_tooltip_text(0)
			if not tip.begins_with("Ember Shard  [Num 1]") or not tip.contains("+12 damage") or not tip.contains("Sell 100"):
				_error = "tooltip: %s" % tip.c_escape()
				return
			if bar.entry_count(1) != 3:
				_error = "draught count %d" % bar.entry_count(1)
				return
			hero.take_damage(200.0, null)
			_key(KEY_KP_2)
		14:
			if bar.entry_count(1) != 2:
				_error = "Numpad 2 did not use the draught (count %d)" % bar.entry_count(1)
				return
			if bar.cooldown_ratio(1) <= 0.0:
				_error = "no cooldown sweep on slot 2"
				return
			if not sel.control_groups().is_empty():
				_error = "Numpad touched a control group"
				return
			bar.swap_slots(0, 1)
		16:
			if str(bar.entry_type(1).id) != "ember_shard":
				_error = "swap failed"
				return
			# Away from every shop: right click = drop.
			hero.global_position = Vector3(0, hero.global_position.y, 0)
			hero.command_stop()
		20:
			var shop: Variant = inv.nearest_shop()
			if shop != null:
				print("note: a shop is in range at the centre, skipping the drop check")
				_stage = 3
				return
			bar.sell_or_drop(1)
		24:
			if _stage == 3:
				return
			if bar.entry_type(1) != null:
				_error = "right click away from a shop did not drop"
				return
			for p in get_nodes_in_group("item_pickups"):
				_pickup = p
			if _pickup == null:
				_error = "no ground item after the drop"
				return
			sel.select_units([hero])
			hero.global_position += Vector3(5, 0, 0)
			sel.pick_up_item(_pickup)
			if sel.pickup_target() != _pickup:
				_error = "pick_up_item did not start the walk"
				return
			_stage = 1
	if frame == 30:
		inv.add_item(_type("shadowstride"))
	if frame == 32:
		var slot := -1
		for i in 6:
			if bar.entry_type(i) != null and str(bar.entry_type(i).id) == "shadowstride":
				slot = i
		if slot < 0:
			_error = "no shadowstride slot"
			return
		_key([KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5, KEY_KP_6][slot])
	if frame == 35:
		if sel.get_pending_order() != &"item":
			_error = "Numpad on Blink did not start targeting (%s)" % sel.get_pending_order()
			return
		sel.cancel_targeting()
		_stage = maxi(_stage, 2) if _stage != 1 else 1
	if frame > 35 and (_stage == 3 or _stage == 2):
		_done = true
	elif frame > 35 and _stage == 1:
		var has := false
		for i in 6:
			if bar.entry_type(i) != null and str(bar.entry_type(i).id) == "ember_shard":
				has = true
		if has and not is_instance_valid(_pickup):
			_done = true
