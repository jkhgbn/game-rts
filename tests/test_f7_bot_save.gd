extends SceneTree
## Fix batch F7 (bots, 2026-10-12): runtime metas renamed (`_ai_casters_hits`, `_contract`), and the bot state a
## quickload used to lose is saved through the generic "saved_state" group hook (save_key / save_state / load_state,
## static create_for_save): the Commander's counters (attacks_launched...) + build-row -> building map + AI children
## progress, and a running Greywater Lodge contract (HuntersGuild.restore_contract with the saved time left, nothing
## charged; refunded pro rata when the guild can't).
## Part 1: direct calls (metas, Commander save / load, refund-only stub). Part 2: a real round trip through
## SaveGame.capture / SaveGame.instantiate_level (SaveWorld + SaveRestorer) of a skirmish with a bot and a running Sweep;
## the rebuilt bot is held (enabled = false) so the load arrives before its _setup (pending path), then released.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_f7_bot_save.gd --fixed-fps 60 --quit-after 16000

const TASK_ID := "f7_bot_save"
const TIMEOUT_FRAMES := 15000
const ENEMY := 1
const PLAYER := 0

var level: Node
var level_b: Node
var frame := 0
var _done := false
var _stage := 0
var _wait := 0
var _restored := false
var _restore_ok := false
var _row_id := ""
var _slot_pos := Vector3.INF
var _gold_saved := 0
var _left_saved := 0.0


func _initialize() -> void:
	level = load("res://scenes/skirmish.tscn").instantiate()
	level.set(&"time_limit_s", 0.0)
	root.add_child(level)
	current_scene = level


func _process(_delta: float) -> bool:
	if _done:
		return true
	frame += 1
	if frame > TIMEOUT_FRAMES:
		_finish("timed out at stage %d" % _stage)
		return true
	_wait += 1
	match _stage:
		0:   # level A: the bot set up
			var c := Commander.for_team(level, ENEMY)
			if frame < 240 or c == null or c.items == null:
				return false
			var err := _check(c)
			if err != "":
				_finish(err)
				return true
			err = _prepare_save(c)
			if err != "":
				_finish(err)
				return true
			_stage = 1
			_wait = 0
		1:   # let the contract run a little, then capture and rebuild
			if _wait < 120:
				return false
			var err := _capture_and_rebuild()
			if err != "":
				_finish(err)
				return true
			_stage = 2
			_wait = 0
		2:   # the restorer finishes; the held bot got the state as pending
			if not _restored:
				return false
			if not _restore_ok:
				_finish("SaveRestorer reported failure")
				return true
			var err := _check_after_restore()
			if err != "":
				_finish(err)
				return true
			_stage = 3
			_wait = 0
		3:   # released bot: the pending state applies after its _setup
			var c := Commander.for_team(level_b, ENEMY)
			if c == null or c.items == null:
				return false
			_finish(_check_pending_applied(c))
			return true
	return false


func _finish(err: String) -> void:
	print("PASS %s" % TASK_ID if err == "" else "FAIL %s: %s" % [TASK_ID, err])
	_done = true


func _prepare_save(c: Commander) -> String:
	# Commander counters + a real row -> building pair (an own enemy building mapped on the first build row).
	var rows: Array = c.get(&"_rows")
	var own: Building = null
	for n in get_nodes_in_group(&"buildings"):
		var b := n as Building
		if b and b.is_alive() and int(b.team) == ENEMY:
			own = b
			break
	if rows.is_empty() or own == null:
		return "no build row / enemy building to map"
	_row_id = String((rows[0] as Dictionary)["id"])
	var map: Dictionary = c.get(&"_slot_building")
	map.clear()
	map[StringName(_row_id)] = own
	_slot_pos = own.global_position
	c.attacks_launched = 5
	c.first_attack_time = 222.0
	c.worker_losses = 3
	c.items.build_index = 1
	# A running Sweep for the player (the Lodge opened through a test clock, gold topped up for the price).
	var guild := HuntersGuild.instance(self)
	var bank := GoldBank.for_team(PLAYER)
	guild.match_time_source = func() -> float: return 400.0
	bank.gold += guild.contract_cost(&"sweep")
	var r := guild.hire(PLAYER, &"sweep")
	if r != "":
		return "hire Sweep refused: %s" % r
	return ""


func _capture_and_rebuild() -> String:
	var guild := HuntersGuild.instance(self)
	var k: Node = guild.contract_of(PLAYER, &"sweep")
	if k == null:
		return "Sweep not running before the save"
	_left_saved = float(k.call(&"time_left"))
	_gold_saved = GoldBank.for_team(PLAYER).gold
	var data := SaveGame.capture(level)
	var states: Array = (data["world"] as Dictionary).get("saved_states", [])
	var keys: Array[String] = []
	for row: Dictionary in states:
		keys.append(String(row.get("key", "")))
	if not keys.has("commander:%d" % ENEMY) or not keys.has("tracker_contract:%d:sweep" % PLAYER):
		return "saved_states rows %s" % str(keys)
	root.remove_child(level)   # out of the tree first: the rebuilt level's banks / guilds are one per match
	level.queue_free()
	level_b = SaveGame.instantiate_level(data)
	if level_b == null:
		return "instantiate_level returned null"
	var restorer := level_b.get_node_or_null(NodePath(SaveGame.RESTORER_NAME))
	if restorer == null:
		return "no SaveRestorer on the rebuilt level"
	restorer.connect(&"finished", func(ok: bool) -> void:
		_restored = true
		_restore_ok = ok)
	root.add_child(level_b)
	current_scene = level_b
	var cb := Commander.for_team(level_b, ENEMY)
	if cb == null:
		return "no enemy Commander in the rebuilt level"
	cb.enabled = false   # hold it: the load must arrive before its _setup
	return ""


func _check_after_restore() -> String:
	var c := Commander.for_team(level_b, ENEMY)
	if c.items != null:
		return "the held bot set up anyway (pending path not exercised)"
	var pending: Dictionary = c.get(&"_pending_load")
	if pending.is_empty() or int(pending.get("attacks_launched", 0)) != 5:
		return "no pending load on the held bot: %s" % str(pending.keys())
	if c.attacks_launched != 5 or not is_equal_approx(c.first_attack_time, 222.0):
		return "held bot (enabled = false) did not apply its counters: attacks %d" % c.attacks_launched
	var guild := HuntersGuild.instance(self)
	if guild == null or not guild.is_running(PLAYER, &"sweep"):
		return "Sweep not restored by the guild"
	var k: Node = guild.contract_of(PLAYER, &"sweep")
	var left := float(k.call(&"time_left"))
	if absf(left - _left_saved) > 1.0:
		return "contract time left %.1f after load, saved %.1f" % [left, _left_saved]
	var bank_b := GoldBank.for_team(PLAYER)
	if bank_b == null:
		var info: Array = []
		for n in get_nodes_in_group(&"gold_banks"):
			info.append([n.get(&"team"), n.is_queued_for_deletion(), n.get_path()])
		return "no player GoldBank after the load: %s; level_b banks %s" % [str(info), str(level_b.get(&"gold_banks"))]
	var gold := bank_b.gold
	if gold != _gold_saved:
		return "gold %d after load, saved %d (the restore charged / refunded)" % [gold, _gold_saved]
	if get_nodes_in_group(&"trackers").is_empty():
		return "no trackers out after the restore"
	c.enabled = true
	return ""


func _check_pending_applied(c: Commander) -> String:
	if c.attacks_launched != 5 or not is_equal_approx(c.first_attack_time, 222.0) or c.worker_losses != 3 			or c.items.build_index != 1:
		return "pending state not applied: attacks %d first %.0f losses %d items %d" % [c.attacks_launched,
				c.first_attack_time, c.worker_losses, c.items.build_index]
	var map: Dictionary = c.get(&"_slot_building")
	var b: Variant = map.get(StringName(_row_id))
	if not (b is Building) or not is_instance_valid(b) or not (b as Building).is_inside_tree() 			or (b as Building).global_position.distance_to(_slot_pos) > 2.5:
		return "row %s not mapped to the rebuilt building (%s)" % [_row_id, str(b)]
	return ""


func _check(c: Commander) -> String:
	# 1. Metas.
	var src := FileAccess.get_file_as_string("res://scripts/ai/ai_casters.gd")
	if src.contains("&\"ai_casters_hits\"") or not src.contains("&\"_ai_casters_hits\""):
		return "ai_casters still uses the plain meta ai_casters_hits"
	var tracker: Unit = null
	for n in get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == int(Unit.Team.PLAYER) and not (u is Wizard):
			tracker = u
			break
	if tracker == null:
		return "no player unit to stand in for a tracker"
	var k := TrackerContract.new()
	k.enabled = false
	k.setup(null, int(Unit.Team.PLAYER), TrackerContract.SWEEP, [tracker], 120.0)
	if tracker.has_meta(&"contract") or tracker.get_meta(&"_contract", null) != k:
		return "TrackerContract still sets the plain meta 'contract'"
	tracker.remove_meta(&"_contract")
	tracker.remove_from_group(&"trackers")
	k.free()

	# 2. Commander counters.
	if not c.is_in_group(&"saved_state") or c.save_key() != "commander:%d" % int(Unit.Team.ENEMY):
		return "Commander not in group saved_state / wrong key '%s'" % c.save_key()
	c.attacks_launched = 3
	c.first_attack_time = 321.0
	c.workers_queued = 7
	c.items.build_index = 2
	var d := c.save_state({})
	c.attacks_launched = 0
	c.first_attack_time = -1.0
	c.workers_queued = 0
	c.items.build_index = 0
	c.load_state(d, {})
	if c.attacks_launched != 3 or not is_equal_approx(c.first_attack_time, 321.0) or c.workers_queued != 7 \
			or c.items.build_index != 2:
		return "Commander state not restored: attacks %d first %.0f workers %d items %d" % [c.attacks_launched,
				c.first_attack_time, c.workers_queued, c.items.build_index]

	# 3. Refund-only stub: the guild can't restore the contract (unknown kind here) -> the unused share comes back.
	var team := int(Unit.Team.PLAYER)
	var bank := GoldBank.for_team(team)
	var guild := HuntersGuild.instance(self)
	if bank == null or guild == null:
		return "no GoldBank / HuntersGuild in the skirmish (trade off?)"
	var key := "tracker_contract:%d:retired_kind" % team
	var cost := 120
	var row := {"team": team, "kind": "retired_kind", "left": 90.0, "duration": 180.0, "cost": cost}
	var gold0 := bank.gold
	var stub := TrackerContract.create_for_save(level, key)
	if stub == null:
		return "create_for_save returned null"
	stub.call(&"load_state", row, {})
	var half := int(round(float(cost) * 0.5))
	if bank.gold != gold0 + half:
		return "refund-only: gold %d -> %d, expected +%d" % [gold0, bank.gold, half]
	if not (stub is TrackerContract) or stub.is_inside_tree():
		return "refund-only: create_for_save did not return a stub outside the tree"
	bank.gold = gold0

	return ""
