extends SceneTree
## WS3.C2 (docs/design/wave-strike.md 15.3 / 15.5, spawn-position part of test_ws_formation): on the real Wave Strike
## level, seat 0 owns 30 copies on its Muster Pad (seat 1: 10). One horn snapshot each: every unit spawns within 0.3 m of
## its cell's mapped spot in the spawn box, rows front to back; the field cap (20 here) holds seat 0's back-most copies;
## each seat's copies form one WaveFormation; when LaneMarch has the hold (WS3.G1), no unit moves before the hold ends.
## Gameplay rows (lock, contact / timeout release, release effects) can be added below by WS3.G1 / WS4.G1.
## Prints "PASS ws_formation" or "FAIL ws_formation: <reasons>".
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ws_formation.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "ws_formation"
const SCENE := "res://scenes/wave_strike.tscn"
const FIELD_CAP := 20
const COPIES := [30, 10]

var level: Node
var _frames := 0
var _phase := 0
var _t0 := 0
var _seen: Dictionary = {}        ## Unit -> first position seen
var _expected: Array = [[], []]   ## per seat: [{id, pos, key}]
var _fails: Array[String] = []
var _done: Array[bool] = [false, false]
var _fx_card: StringName = &""
var _fx_want := 0


func _initialize() -> void:
	level = (load(SCENE) as PackedScene).instantiate()
	var rules := WaveStrikeRules.load_default()
	rules.horn_first = 100000.0
	rules.time_limit = 0.0
	rules.field_cap = FIELD_CAP
	level.set(&"rules", rules)
	level.set(&"autopilot_player", true)
	level.set(&"wizards_enabled", false)
	root.add_child(level)
	current_scene = level


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames > 3500:
		return _end("timed out (phase %d)" % _phase)
	if level.get(&"director") == null:
		return false
	if _phase == 0:
		_setup()
		_phase = 1
		_t0 = _frames
		return false
	_record()
	var sp: LaneSpawner = (level.get(&"spawners") as Array)[0]
	for seat in 2:   # each seat once its last copy is out (its muster hold runs 0.5 s more)
		if not _done[seat] and (level.get(&"spawners") as Array)[seat].pending() == 0:
			_done[seat] = true
			_check_positions(seat)
	if _phase == 1 and _done[0] and _done[1]:
		_phase = 2
	if _phase == 2:
		var f := sp.formation
		if f != null and f.state != WaveFormation.State.MUSTER:
			_phase = 3
			_t0 = _frames
	if _phase == 3 and _frames - _t0 > 30:
		return _end("")
	return false


func _setup() -> void:
	var rosters: Array = level.get(&"rosters")
	for seat in 2:
		var r: MusterRoster = rosters[seat]
		r.tier = 3
		r.bank.economy.crystals = 1000000
		var ids: Array[StringName] = []
		for id in r.card_ids():
			var t := UnitType.find(String(id))
			if t != null and t.requires_tier <= 1:
				ids.append(id)
		var n := 0
		var guard := 0
		while r.card_total() < int(COPIES[seat]) and guard < 400:
			guard += 1
			r.buy(ids[n % ids.size()])
			n += 1
		_check(r.card_total() == int(COPIES[seat]), "seat %d bought %d copies" % [seat, r.card_total()])
		for c in r.pad.copies():
			var cell: Vector2i = c["cell"]
			_expected[seat].append({"id": c["id"], "pos": r.pad.cell_to_lane(cell, int(c["size"])),
					"key": LaneSpawner.spawn_key(cell, int(c["size"]))})
		if seat == 0:   # WS4.C2: a B upgrade with a release list reaches the formation
			_check(r.buy_upgrade(ids[0], WaveUpgradeTable.SLOT_B) == "", "buy %s B" % ids[0])
			_fx_card = ids[0]
			_fx_want = (r.upgrade_info(ids[0], WaveUpgradeTable.SLOT_B).get("release", []) as Array).size()
		(level.get(&"spawners") as Array)[seat].queue_horn(r)


func _record() -> void:
	for u: Unit in level.call(&"lane_units"):
		if not _seen.has(u):
			_seen[u] = u.global_position


func _check_positions(seat: int) -> void:
	var units: Array[Unit] = []
	for u: Unit in _seen:
		if int(u.get_meta(&"ws_seat", -1)) == seat:
			units.append(u)
	var want := mini(int(COPIES[seat]), FIELD_CAP)
	_check(units.size() == want, "seat %d spawned %d (want %d)" % [seat, units.size(), want])
	# the spawned copies are the front-most (lowest spawn keys)
	var ordered: Array = _expected[seat].duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["key"]) < float(b["key"]))
	var free: Array = ordered.slice(0, want)
	var worst := 0.0
	for u in units:
		var p: Vector3 = _seen[u]
		var best := -1
		var bd := INF
		for i in free.size():
			if StringName(free[i]["id"]) != StringName(u.get_meta(&"ws_card", &"")):
				continue
			var q: Vector3 = free[i]["pos"]
			var d := Vector2(p.x - q.x, p.z - q.z).length()
			if d < bd:
				bd = d
				best = i
		if best < 0:
			_fails.append("seat %d: %s spawned with no front cell left (a back-most copy was not held)" % [seat, u.get_meta(&"ws_card")])
			continue
		worst = maxf(worst, bd)
		free.remove_at(best)
	_check(worst <= 0.3, "seat %d: a unit spawned %.2f m from its cell" % [seat, worst])
	var sp: LaneSpawner = (level.get(&"spawners") as Array)[seat]
	_check(sp.formation != null and sp.formation.members.size() == want,
			"seat %d formation has %d members" % [seat, sp.formation.members.size() if sp.formation else -1])
	if seat == 0 and sp.formation != null:
		var bad := 0
		for u in units:
			var n := sp.formation.release_effects_of(u).size()
			if n != (_fx_want if StringName(u.get_meta(&"ws_card", &"")) == _fx_card else 0):
				bad += 1
		_check(bad == 0, "seat 0: %d members with a wrong release list (%s B: %d effects)" % [bad, _fx_card, _fx_want])
	print("ws_formation: seat %d %d spawned, worst %.3f m from the cell" % [seat, units.size(), worst])
	# hold (WS3.G1 side present): nobody has walked off its cell
	var lm := units[0].get_node_or_null(^"LaneMarch") if not units.is_empty() else null
	if lm != null and lm.has_method(&"hold"):
		var moved := 0
		for u in units:
			var p: Vector3 = _seen[u]
			if Vector2(u.global_position.x - p.x, u.global_position.z - p.z).length() > 0.3:
				moved += 1
		_check(moved == 0, "seat %d: %d units moved during the muster hold" % [seat, moved])


func _end(reason: String) -> bool:
	if reason != "":
		_fails.append(reason)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)
	return true
