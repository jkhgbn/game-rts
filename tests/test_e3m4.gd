extends SceneTree
## Mission e3m4 "The Storm on the Ridge" (docs/design/mission-e3-04.md, scripted through MissionHarness). Parts:
##   start   3 seats (Shadow + Ice vs Fire), the Citadel, Malrik L6 cap 8 with the Shard, Hush, Torvald at Birch Watch,
##           3 watch points owned by side 0, the river.
##   storm   A1 at 5:30 brings Vey (3 600 HP); 0 HP is a break (no death, +200 essence, +250 XP), he rests on the crest;
##           A2 at its clock (13:00, or 75 s after the break when later); three breaks = victory + flags.
##   ridge   side 1 on all three points starts the 30 s countdown; retaking one stops it; 0 = defeat.
##   knight  the Paddock refuses before 4:00, then trains a Nightmare Knight; its charge on Vey -> sec_knight.
## Run: godot --headless --path . -s tests/test_e3m4.gd --fixed-fps 60 --quit-after 60000 [-- --only=start|...]

const TASK_ID := "e3m4"
const MISSION := "res://missions/mission_e3_04.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "storm", "ridge", "knight"]
var _part := ""
var h: MissionHarness
var main: MissionE3_04
var _errors: Array[String] = []
var _v := {}
var _gap := 0
var _finished := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			_parts.assign(a.trim_prefix("--only=").split(","))
	_open_next()


func _process(_delta: float) -> bool:
	if _finished:
		return true
	if _gap > 0:
		_gap -= 1
		if _gap == 0:
			_open_next()
		return _finished
	if h == null or main == null:
		return _finished
	if h.tick():
		for e in h.errors:
			_errors.append("%s: %s" % [_part, e])
		main.queue_free()
		main = null
		h = null
		_gap = GAP_FRAMES
	return _finished


func _open_next() -> void:
	if _parts.is_empty():
		_finished = true
		print("PASS %s" % TASK_ID if _errors.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return
	_part = _parts.pop_front()
	_v = {}
	h = MissionHarness.new()
	h.task_id = "%s/%s" % [TASK_ID, _part]
	h.timeout_frames = 30000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e3m4_none.json"}}) as MissionE3_04
	match _part:
		"start":
			h.steps.add("start state", _start, 10)
		"storm":
			h.steps.add("A1 brings Vey", _a1, 600)
			h.steps.add("a break", _break1, 600)
			h.steps.add("three breaks -> victory", _three, 6000)
		"ridge":
			h.steps.add("countdown", _ridge, 600)
			h.steps.add("ridge falls -> defeat", _ridge_fall, 3000)
		"knight":
			h.steps.add("Paddock refusals", _paddock_early, 30)
			h.steps.add("Paddock + Knight", _paddock, 9000)
			h.steps.add("charge on Vey", _charge, 600)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


func _start() -> bool:
	_ok(Teams.multi and Teams.seats().size() == 3, "3 seats")
	_ok(main.keep != null and main.keep.tier == 3, "the Dusk Keep a Citadel")
	_ok(main.hero is ShadowWizard and main.hero.level == 6 and main.hero.level_cap == 8, "Malrik L6 cap 8")
	_ok(main.hush != null and main.torvald != null and main.vessa != null, "Hush, Torvald, Vessa")
	_ok(main.watch.size() == 3 and main.watch_owned(0) == 3, "3 watch points, side 0")
	_ok(_units(0, "nightblood_reaver").size() == 2 and _units(0, "gloom_thrall").size() == 7, "the start army")
	_ok(RiverSystem.instance(main.get_tree()) != null, "the river")
	_ok(main.vey == null and main.breaks == 0, "Vey off the field")
	_ok(Economy.for_team(0).crystals == 450, "450 crystals")
	return true


func _a1() -> bool:
	if main.mission_time() < 329.0:
		MissionHarness.skip_time(main, 329.0 - main.mission_time())
		return false
	if main.vey == null or main.vey_state != &"fighting":
		return false
	_ok(main.vey.max_hp == 3600.0 and main.assault == 1, "Vey 3 600 HP, A1 (%d)" % main.vey.max_hp)
	_ok(main.has_fired(&"E4"), "E4")
	return true


func _break1() -> bool:
	MissionHarness.immortal(main.hero)
	if not _v.has("e"):
		_v["e"] = EssenceBank.for_team(0).essence
		main.vey.take_damage(1.0e7, null)
		return false
	if main.breaks < 1:
		return false
	_ok(main.vey.is_inside_tree() and main.vey_state != &"fighting", "a break, not a death")
	_ok(EssenceBank.for_team(0).essence >= int(_v["e"]) + 200, "+200 essence")
	_ok(main.objective_state("obj_storm") == "active", "obj_storm counter")
	return true


func _three() -> bool:
	MissionHarness.immortal(main.hero)
	for id: StringName in main.watch:
		(main.watch[id] as MissionZone).set_owner_side(0)
	if h.ended >= 0:
		_ok(h.ended == 1 and main.breaks == 3, "victory after three breaks")
		var f := main.mission_flags()
		_ok(f.has("e3m4_shard_uses") and f.has(CampaignState.MALRIK_ESSENCE_FLAG) and f.has("shadow_never_used"), "flags %s" % str(f))
		return true
	if main.vey and main.vey_state == &"fighting":
		main.vey.take_damage(1.0e7, null)
	elif main.mission_time() < 1199.0:
		MissionHarness.skip_time(main, 20.0)
	return false


func _ridge() -> bool:
	for id: StringName in main.watch:
		(main.watch[id] as MissionZone).set_owner_side(1)
	if main.ridge_left < 0.0:
		return false
	_ok(main.ridge_left <= 30.0 and main.has_fired(&"E14"), "the 30 s countdown")
	(main.watch[&"W1"] as MissionZone).set_owner_side(0)
	_v["stop"] = true
	return true


func _ridge_fall() -> bool:
	if _v.has("stop"):
		if main.ridge_left >= 0.0:
			return false
		_v.erase("stop")
		for id: StringName in main.watch:
			(main.watch[id] as MissionZone).set_owner_side(1)
		return false
	for id: StringName in main.watch:
		(main.watch[id] as MissionZone).set_owner_side(1)
	if h.ended < 0:
		return false
	_ok(h.ended == 0 and main.objective_state("obj_ridge") == "failed", "the ridge falls = defeat")
	return true


func _paddock_early() -> bool:
	_ok(main.raise_paddock() == MissionE3_04.REFUSE_EARLY, "Not yet (4:00)")
	return true


func _paddock() -> bool:
	if main.mission_time() < 241.0:
		MissionHarness.skip_time(main, 241.0 - main.mission_time())
		return false
	if main.paddock == null:
		Economy.for_team(0).add(2000)
		var r := main.raise_paddock()
		_ok(r == "", "the Paddock placed (%s)" % r)
		return false
	var pd := main.paddock as TrainingBuilding
	if not pd.is_constructed():
		for w in main.workers_of(0):
			w.call(&"command_build", pd)
		return false
	if main.knights == 0:
		if pd.queue.is_empty():
			_ok(pd.queue_unit(pd.trainable_types()[0]) == "", "a Nightmare Knight queued")
		return false
	return true


func _charge() -> bool:
	if not _v.has("k"):
		var kn: Array = _units(0, "nightmare_knight")
		if kn.is_empty():
			return false
		_v["k"] = kn[0]
		MissionHarness.skip_time(main, 330.0 - main.mission_time() if main.mission_time() < 330.0 else 0.0)
		return false
	if main.vey == null or main.vey_state != &"fighting":
		return false
	var k: Unit = _v["k"]
	MissionHarness.immortal(k)
	MissionHarness.immortal(main.vey)
	if not _v.has("run"):
		_v["run"] = true
		k.global_position = main.vey.global_position + Vector3(12.0, 0.0, 0.0)
		k.command_attack(main.vey)
	if not main.knight_charged:
		return false
	_ok(main.objective_state("sec_knight") == "done", "sec_knight done")
	return true
