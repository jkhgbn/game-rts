extends SceneTree
## Fix batch F6 (items, docs/handoff/fix-batches-2026-10-12.md; ids in code-review-2026-10-12.md):
##  - R1-1: swapping a max_hp item between slots, or dropping and picking it up again, never heals; a full-HP
##    wizard stays full through a swap; a new item still heals its gain;
##  - R5-4: consumable cooldowns reset when the wizard respawns;
##  - R5-6: the Homeward Seal channel cancels when the seal leaves the inventory (no teleport);
##  - U2-5: Inventory.drop refuses a campaign_only item;
##  - R5-7: EssenceBank.for_team called twice before the deferred add_child gives one bank;
##  - R5-5: a ground ItemPickup (type, count, position) comes back after SaveGame.capture -> instantiate_level.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_f6_items.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "f6_items"
const TEST_PATH := "user://saves/_test_f6_items.save"
const HP_ITEM := &"bone_charm"        # +60 max_hp
const PICKUP_POS := Vector3(6.0, 0.0, 6.0)

var errors: Array[String] = []
var level: Node
var step := "start"
var frames := 0
var total := 0
var data: Dictionary = {}
var restorer_done := false
var seal_pos := Vector3.ZERO
var pickup_pos := Vector3.ZERO


func _initialize() -> void:
	level = load("res://scenes/skirmish.tscn").instantiate()
	level.set(&"time_limit_s", 0.0)
	root.add_child(level)
	current_scene = level


func _process(_delta: float) -> bool:
	total += 1
	frames += 1
	if total > 5500:
		_fail("timed out at step %s" % step)
		return _finish()
	match step:
		"start":
			if level.get(&"hero") != null and bool(level.get(&"match_started")):
				_bots_off()
				_check_heal()
				_check_respawn_cooldowns()
				_check_campaign_drop()
				_check_bank()
				_start_seal()
				_goto("seal")
		"seal":
			if frames >= 300:   # 5 s: past the 3 s channel
				_check_seal()
				_place_pickup()
				_goto("settle")
		"settle":
			if frames >= 10:
				_save()
				_reload()
				_goto("wait")
		"wait":
			if restorer_done:
				_goto("after")
		"after":
			if frames >= 10:
				_check_pickup_loaded()
				return _finish()
	return false


func _goto(s: String) -> void:
	step = s
	frames = 0


func _fail(msg: String) -> void:
	errors.append(msg)
	print("  x ", msg)


func _finish() -> bool:
	DirAccess.remove_absolute(TEST_PATH)
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(errors)])
	return true


func _bots_off() -> void:
	for n in level.find_children("*", "Commander", true, false):
		n.set(&"enabled", false)


func _hero() -> Wizard:
	return level.get(&"hero") as Wizard


func _clear(inv: Inventory) -> void:
	for i in inv.slots.size():
		if inv.slots[i] != null:
			inv.remove_item(i)


# ---------------------------------------------------------------- R1-1

func _check_heal() -> void:
	var w := _hero()
	var inv := w.inventory as Inventory
	_clear(inv)
	var t := ItemType.find(HP_ITEM)
	# full HP: a swap keeps her full
	inv.add_item(t)
	w.heal(99999.0)
	var full := w.max_hp
	inv.swap(0, 3)
	if absf(w.hp - w.max_hp) > 0.01 or absf(w.max_hp - full) > 0.01:
		_fail("R1-1: full-HP swap gave %.1f / %.1f (was %.1f full)" % [w.hp, w.max_hp, full])
	_clear(inv)
	# full HP, two different max_hp items (+250 / +60) swapped: still full, same maximum
	inv.add_item(ItemType.find(&"banner_of_embers"))
	inv.add_item(t)
	w.heal(99999.0)
	full = w.max_hp
	inv.swap(0, 1)
	inv.swap(1, 0)
	inv.swap(0, 1)
	if absf(w.hp - full) > 0.01 or absf(w.max_hp - full) > 0.01:
		_fail("R1-1: full-HP swap of two max_hp items gave %.1f / %.1f (was %.1f full)" % [w.hp, w.max_hp, full])
	_clear(inv)
	# hurt: a new item heals its gain, a swap / drop + pick up does not
	w.take_damage(w.max_hp * 0.5, null)
	var hp0 := w.hp
	inv.add_item(t)
	if w.hp < hp0 + 59.0:
		_fail("R1-1: a new +60 max_hp item healed %.1f (expected 60)" % (w.hp - hp0))
	var hp1 := w.hp
	inv.swap(0, 2)
	inv.swap(2, 5)
	if absf(w.hp - hp1) > 0.01:
		_fail("R1-1: swaps changed HP %.1f -> %.1f" % [hp1, w.hp])
	var p := inv.drop(5)
	if p == null:
		_fail("R1-1: drop gave no pickup")
		return
	if not p.pick_up(w):
		_fail("R1-1: pick up refused")
	if absf(w.hp - hp1) > 0.01:
		_fail("R1-1: drop + pick up changed HP %.1f -> %.1f" % [hp1, w.hp])
	if not inv.has_item(HP_ITEM):
		_fail("R1-1: the item is not carried after the pick up")
	_clear(inv)
	w.heal(99999.0)


# ---------------------------------------------------------------- R5-4

func _check_respawn_cooldowns() -> void:
	var w := _hero()
	var inv := w.inventory as Inventory
	inv.add_item(ItemType.find(&"ember_draught"), 2)
	var slot := inv.find_slot(&"ember_draught")
	inv.start_cooldown(slot, 30.0)
	if inv.cooldown_left(slot) <= 0.0:
		_fail("R5-4: setup, no cooldown started")
	w.respawned.emit(w)
	if inv.cooldown_left(slot) > 0.0:
		_fail("R5-4: consumable cooldown %.1f s kept after respawn" % inv.cooldown_left(slot))
	_clear(inv)


# ---------------------------------------------------------------- U2-5

func _check_campaign_drop() -> void:
	var inv := _hero().inventory as Inventory
	var t := ItemType.find(&"oath_of_embers")
	if t == null or not t.campaign_only or t.is_artifact:
		_fail("U2-5: setup, oath_of_embers is not a campaign_only item")
		return
	inv.add_item(t)
	var slot := inv.find_slot(t.id)
	if inv.drop(slot) != null or not inv.has_item(t.id):
		_fail("U2-5: a campaign_only item was dropped")
	_clear(inv)


# ---------------------------------------------------------------- R5-7

func _check_bank() -> void:
	var holder := Node.new()
	holder.name = "F6Holder"
	root.add_child(holder)
	holder.request_ready()   # in the tree but not ready: for_team defers its add_child
	current_scene = holder
	var a := EssenceBank.for_team(7)
	var b := EssenceBank.for_team(7)
	current_scene = level
	if a == null or a != b:
		_fail("R5-7: two banks for one team before the deferred add_child")
	elif a.is_inside_tree():
		_fail("R5-7: setup, the bank was not deferred (the case is not exercised)")
	holder.queue_free()
	# a waiting bank whose parent dies before the deferred add_child is never handed out again
	var holder2 := Node.new()
	root.add_child(holder2)
	holder2.request_ready()
	current_scene = holder2
	var orphan := EssenceBank.for_team(8)
	holder2.free()
	current_scene = level
	var fresh := EssenceBank.for_team(8)
	if fresh == orphan or fresh == null or not fresh.is_inside_tree():
		_fail("R5-7: an orphan bank (parent freed) was returned to the next caller")
	if fresh:
		fresh.queue_free()


# ---------------------------------------------------------------- R5-6

func _start_seal() -> void:
	var w := _hero()
	var inv := w.inventory as Inventory
	inv.add_item(ItemType.find(&"homeward_seal"))
	var slot := inv.find_slot(&"homeward_seal")
	w.global_position += Vector3(10.0, 0.0, 0.0)
	seal_pos = w.global_position
	var why := inv.use_item(slot, null)
	if why != "":
		_fail("R5-6: setup, the seal refused: %s" % why)
		return
	var act := ItemActives.for_inventory(inv)
	if not act.is_channeling():
		_fail("R5-6: setup, no channel")
	inv.remove_item(slot)   # sold / dropped mid-channel
	if act.is_channeling():
		_fail("R5-6: the channel goes on after the seal left")


func _check_seal() -> void:
	var w := _hero()
	if w.global_position.distance_to(seal_pos) > 1.0:
		_fail("R5-6: the wizard was sent home without her seal")


# ---------------------------------------------------------------- R5-5

func _place_pickup() -> void:
	for p in get_nodes_in_group(&"item_pickups"):
		p.free()
	var p := ItemPickup.spawn(ItemType.find(&"ember_draught"), PICKUP_POS, 2, level)
	pickup_pos = p.global_position


func _save() -> void:
	var why := SaveGame.write_file(TEST_PATH, SaveGame.capture(level))
	if why != "":
		_fail("write_file: %s" % why)
	data = SaveGame.read_file(TEST_PATH)
	if data.has("error"):
		_fail("read_file: %s" % data["error"])


func _reload() -> void:
	var old := level
	root.remove_child(old)
	old.queue_free()
	level = SaveGame.instantiate_level(data)
	if level == null:
		_fail("instantiate_level returned null")
		return
	restorer_done = false
	var r := level.get_node(NodePath(SaveGame.RESTORER_NAME))
	r.connect(&"finished", func(ok: bool) -> void:
		restorer_done = true
		if not ok:
			_fail("the restorer reported a failure"))
	root.add_child(level)
	current_scene = level


func _check_pickup_loaded() -> void:
	var found: Array = []
	for n in get_nodes_in_group(&"item_pickups"):
		if not n.is_queued_for_deletion():
			found.append(n)
	if found.size() != 1:
		_fail("R5-5: %d ground items after the load (expected 1)" % found.size())
		return
	var p := found[0] as ItemPickup
	if p.type == null or p.type.id != &"ember_draught" or p.count != 2:
		_fail("R5-5: loaded pickup %s x%d" % [p.type.id if p.type else &"?", p.count])
	if p.global_position.distance_to(pickup_pos) > 0.1:
		_fail("R5-5: loaded pickup at %s, saved at %s" % [p.global_position, pickup_pos])
	if not p.get_parent() == level:
		_fail("R5-5: loaded pickup not under the level")
