extends SceneTree
## Campaign review 2026-10-16 (part1.md "Missions in this set that feel too similar", item 6): each mission of
## episodes 1-2 owned here (m02, m03, m04, e2m1, e2m2, e2m4) brings Shadow units of its own, the roster grows from
## mission to mission, no raid is the old "Grave Hound pack", and every changed wave keeps the old crystal value
## (within WAVE_TOLERANCE) so the difficulty stays where the sims measured it.
## Run:  godot --headless --path . -s tests/test_cr_waves.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "cr_waves"
const WAVE_TOLERANCE := 0.25
## The m00 / m01 Shadow roster every wave used before the review.
const BASE_ROSTER: Array[StringName] = [&"shade", &"nightbolt", &"grave_hound", &"shadow_knight", &"gloom_deacon",
		&"gloom_thrall"]
const ELITE_VALUE := 300   ## Grave Marshal Corvane (cost 0, a local type): counted as a stronger Barrow Knight.

var _fails: Array[String] = []


func _initialize() -> void:
	_run()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f in _fails:
			print("  - ", f)
		print("FAIL %s: %d check(s)" % [TASK_ID, _fails.size()])
	quit()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


## [mission, wave name, rows, the old wave's crystal value]. Mission order = campaign order.
func _waves() -> Array:
	var e1: Dictionary = MissionE2_01.WAVES
	var e2: Dictionary = MissionE2_02.WAVES
	var e4: Dictionary = MissionE2_04.WAVES
	return [
		["m02", "W1", Mission02.WAVE_ROWS[&"W1"], 440],
		["m02", "reinforcements", Mission02.WAVE_ROWS[&"reinforcements"], 515],
		["m02", "W2", Mission02.WAVE_ROWS[&"W2"], 670],
		["m02", "W3", Mission02.WAVE_ROWS[&"W3"], 700],
		["m02", "pursuit", Mission02.WAVE_ROWS[&"pursuit"], 880],
		["m02", "pursuit_2", Mission02.WAVE_ROWS[&"pursuit_2"], 310],
		["m03", "W1", Mission03.WAVE_ROWS[&"W1"], 600],
		["m03", "W2", Mission03.WAVE_ROWS[&"W2"], 1040],
		["m03", "stake_raid", Mission03.WAVE_ROWS[&"stake_raid"], 385],
		["m03", "race", Mission03.WAVE_ROWS[&"race"], 1200],
		["m03", "D2", Mission03.DRAIN_ROWS[1], 1870],
		["m03", "late drain", Mission03.LATE_DRAIN_ROWS, 1920],
		["m04", "isle_guard", Mission04.WAVE_ROWS[&"isle_guard"], 780],
		["m04", "strike", Mission04.WAVE_ROWS[&"strike"], 520],
		["m04", "raid", Mission04.WAVE_ROWS[&"raid"], 300],
		["m04", "raid_hall_burned", Mission04.WAVE_ROWS[&"raid_hall_burned"], 150],
		["m04", "push (without its knights)", Mission04.WAVE_ROWS[&"push"], 480],
		["e2m1", "P1", MissionE2_01.PROBE_ROWS, 390],
		["e2m1", "H1", e1[&"H1"]["rows"], 670],
		["e2m1", "H3", e1[&"H3"]["rows"], 1080],
		["e2m1", "H5", e1[&"H5"]["rows"], 780],
		["e2m1", "H6", e1[&"H6"]["rows"], 1040],
		["e2m1", "H7", e1[&"H7"]["rows"], 670],
		["e2m1", "raid", MissionE2_01.RAID_ROWS, 150],
		["e2m2", "W2", e2[&"W2"]["rows"], 670],
		["e2m2", "W4", e2[&"W4"]["rows"], 1080],
		["e2m2", "W6", e2[&"W6"]["rows"], 670],
		["e2m2", "VS", e2[&"VS"]["rows"], 1160],
		["e2m2", "VK", e2[&"VK"]["rows"], 520],
		["e2m2", "raid", e2[&"RAID"]["rows"], 150],
		["e2m4", "G4", e4[&"G4"], 225],
		["e2m4", "W1", e4[&"W1"], 470],
		["e2m4", "W2", e4[&"W2"], 780],
		["e2m4", "W3", e4[&"W3"], 1080],
		["e2m4", "W4", e4[&"W4"], 1040],
		["e2m4", "W4K", e4[&"W4K"], 520],
	]


func _value(rows: Array) -> int:
	var v := 0
	for row: Array in rows:
		var id := StringName(row[0])
		var c := ELITE_VALUE if id == MissionE2_02.ELITE_ID else 0
		var t := UnitType.find(String(id))
		if t != null and c == 0:
			c = t.cost
		v += c * int(row[1])
	return v


func _run() -> void:
	var order: Array[String] = ["m02", "m03", "m04", "e2m1", "e2m2", "e2m4"]
	var types_of := {}
	for m in order:
		types_of[m] = {}
	for w: Array in _waves():
		var m: String = w[0]
		var rows: Array = w[2]
		for row: Array in rows:
			var id := StringName(row[0])
			var known := UnitType.find(String(id)) != null or id == MissionE2_02.ELITE_ID
			_check(known, "%s %s: unknown unit type %s" % [m, w[1], id])
			(types_of[m] as Dictionary)[id] = true
		var v := _value(rows)
		var old := int(w[3])
		_check(absf(float(v - old)) <= float(old) * WAVE_TOLERANCE,
				"%s %s: value %d vs old %d (more than %d %%)" % [m, w[1], v, old, roundi(WAVE_TOLERANCE * 100.0)])
	# The roster grows: every mission brings a Shadow type no earlier mission (nor m00 / m01) used.
	var seen := {}
	for id in BASE_ROSTER:
		seen[id] = true
	for m in order:
		var fresh: Array[StringName] = []
		for id: StringName in (types_of[m] as Dictionary).keys():
			if not seen.has(id):
				fresh.append(id)
		_check(not fresh.is_empty(), "%s brings no new enemy type" % m)
		print("  %s new: %s" % [m, ", ".join(fresh)])
		for id: StringName in fresh:
			seen[id] = true
	# Raids: never the Grave Hound pack, and no two missions raid with the same unit.
	var raids := {"m03": Mission03.WAVE_ROWS[&"stake_raid"], "m04": Mission04.WAVE_ROWS[&"raid"],
			"e2m1": MissionE2_01.RAID_ROWS, "e2m2": MissionE2_02.WAVES[&"RAID"]["rows"]}
	var raid_types := {}
	for m: String in raids.keys():
		for row: Array in raids[m]:
			var id := StringName(row[0])
			_check(id != &"grave_hound", "%s raids with Grave Hounds" % m)
			_check(not raid_types.has(id), "%s raids with %s like %s" % [m, id, raid_types.get(id, "")])
			raid_types[id] = m
	# e2m2's named elite.
	var elite := MissionE2_02.make_elite_type()
	_check(elite.id == MissionE2_02.ELITE_ID and elite.display_name == "Grave Marshal Corvane", "elite type id / name")
	_check(elite.on_hit_status == &"marked" and elite.on_hit_duration > 0.0, "elite blows mark the target")
	_check(elite.max_hp > 310.0 and not elite.commandable, "elite HP / not commandable")
	# e2m1: the ghouls rise near their target, not at the Shadow camp.
	_check(MissionE2_01.RAID_RISE_DIST < 25.0 and MissionE2_01.RAID_WARN > 0.0, "e2m1 raid rises near its target")
