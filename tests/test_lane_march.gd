extends SceneTree
## WS2.G3 (wave-strike.md 14.2 P2 / P3): lane units' scans in fixed frame buckets, RVO avoidance gated off while no
## enemy is within 30 m. Wave Strike level, no horns, no wizards; a burst of PER_SIDE lane units per side spawned on ONE
## frame at both gates, then they march and clash. Checks:
## - P2: at most ceil(n / 15) + 2 auto-aggro scans (Unit.retarget_scans) in any physics frame, burst included;
## - P3: while the fronts are > 75 m apart every lane unit walks gated (avoidance off); during the clash no unit with an
##   enemy within 15 m is gated; a gated unit walks at its own speed (no double move);
## - the waves meet, fight, and LaneMarch.stall_events stays 0.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_lane_march.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "lane_march"
const SCENE := "res://scenes/wave_strike.tscn"
const PER_SIDE := 45
const IDS := [[&"flame_guard", &"ember_archer", &"blaze_rider", &"cinder_arbalest"], [&"shade", &"nightbolt", &"gloam_rider", &"barrow_knight"]]
const CLASH_FRAMES := 900

var level: Node
var _frames := 0
var _spawn_frame := -1
var _scans_last := 0
var _max_scans := 0
var _max_scan_frame := -1
var _march_checks := 0
var _march_ungated_max := 0
var _clash_start := -1
var _clash_bad := 0
var _clash_on_max := 0
var _probe: Node3D = null
var _probe_pos := Vector3.ZERO
var _probe_frame := -1
var _probe_ratio := -1.0
var _done := false


func _initialize() -> void:
	level = (load(SCENE) as PackedScene).instantiate()
	var rules: Resource = (load("res://scripts/world/wave_strike/wave_strike_rules.gd") as Script).call(&"load_default")
	rules.set(&"horn_first", 100000.0)
	rules.set(&"time_limit", 0.0)
	rules.set(&"field_cap", 0)
	level.set(&"rules", rules)
	level.set(&"autopilot_player", true)
	level.set(&"wizards_enabled", false)
	root.add_child(level)
	current_scene = level


func _physics_process(_delta: float) -> bool:
	if _spawn_frame < 0 or _done:
		return false
	var scans: int = int((load("res://scripts/units/unit.gd") as Script).get(&"retarget_scans"))
	var n := scans - _scans_last
	_scans_last = scans
	if n > _max_scans:
		_max_scans = n
		_max_scan_frame = _frames - _spawn_frame
	return false


func _process(_delta: float) -> bool:
	_frames += 1
	if _done:
		return true
	if level.get(&"director") == null:
		if _frames > 3000:
			return _fail("the level never started")
		return false
	if _spawn_frame < 0:
		if _frames < 30:
			return false
		_spawn_burst()
		return false
	var f := _frames - _spawn_frame
	var units: Array = level.call(&"lane_units", -1)
	var gap := _front_gap(units)
	if f >= 45 and gap > 75.0 and _clash_start < 0:
		_march_checks += 1
		var on := 0
		for u: Unit in units:
			if not u.is_avoidance_gated():
				on += 1
		_march_ungated_max = maxi(_march_ungated_max, on)
		_track_probe(units)
	if gap < 10.0 and _clash_start < 0:
		_clash_start = f
	if _clash_start >= 0:
		var on2 := 0
		for u: Unit in units:
			if not u.is_avoidance_gated():
				on2 += 1
			elif u.has_enemy_within(15.0):
				_clash_bad += 1
		_clash_on_max = maxi(_clash_on_max, on2)
		if f - _clash_start >= CLASH_FRAMES:
			return _report()
	if f > 4200:
		return _fail("the waves never met (front gap %.1f m)" % gap)
	return false


func _spawn_burst() -> void:
	var lm: Script = load("res://scripts/units/lane_march.gd") as Script
	lm.call(&"reset_counters")
	for i in PER_SIDE:
		for team in 2:
			var gate: Vector3 = level.call(&"gate_position", team)
			var fwd := Vector3.RIGHT if team == 0 else Vector3.LEFT
			var lat := (float(i % 9) - 4.0) / 4.0 * 8.0
			var pos := gate + Vector3(0, 0, lat * 1.6) + fwd * (i / 9) * 1.6
			level.call(&"spawn_lane_unit", team, IDS[team][i % 4], pos, lat)
	_spawn_frame = _frames
	_scans_last = int((load("res://scripts/units/unit.gd") as Script).get(&"retarget_scans"))


## A gated unit must walk at its own speed (no double move from a direct apply + an RVO answer).
func _track_probe(units: Array) -> void:
	if _probe_ratio >= 0.0:
		return
	if _probe == null:
		for u: Unit in units:
			if u.team == 0 and u.is_avoidance_gated():
				_probe = u
				_probe_pos = u.global_position
				_probe_frame = _frames
				return
		return
	if not is_instance_valid(_probe):
		_probe = null
		return
	if _frames - _probe_frame >= 60:
		var d := Vector2(_probe.global_position.x - _probe_pos.x, _probe.global_position.z - _probe_pos.z).length()
		var spd: float = (_probe as Unit).get_stat(&"move_speed")
		_probe_ratio = d / maxf(spd, 0.01)


func _front_gap(units: Array) -> float:
	var a := -INF
	var b := INF
	for u: Node3D in units:
		if int(u.get(&"team")) == 0:
			a = maxf(a, u.global_position.x)
		else:
			b = minf(b, u.global_position.x)
	return b - a


func _report() -> bool:
	var lm: Script = load("res://scripts/units/lane_march.gd") as Script
	var stalls := int(lm.get(&"stall_events"))
	var n := PER_SIDE * 2
	var cap := ceili(n / 15.0) + 2
	print("lane_march: %d units, max scans/frame %d (cap %d, at frame %d); march checks %d, ungated max %d; clash at f %d, avoidance-on max %d, gated-with-enemy-in-15m %d; probe speed ratio %.2f; stalls %d (longest %.1f s)" % [
			n, _max_scans, cap, _max_scan_frame, _march_checks, _march_ungated_max, _clash_start, _clash_on_max, _clash_bad,
			_probe_ratio, stalls, float(lm.get(&"longest_stall"))])
	if _max_scans > cap:
		return _fail("%d scans in one frame (cap %d)" % [_max_scans, cap])
	if _march_checks < 30 or _march_ungated_max > 0:
		return _fail("march: %d units kept avoidance on (%d checks)" % [_march_ungated_max, _march_checks])
	if _clash_on_max == 0 or _clash_bad > 0:
		return _fail("clash: avoidance on max %d, gated next to an enemy %d" % [_clash_on_max, _clash_bad])
	if _probe_ratio < 0.5 or _probe_ratio > 1.08:
		return _fail("a gated unit walked %.2f x its speed" % _probe_ratio)
	if stalls > 0:
		return _fail("%d stall events" % stalls)
	print("PASS %s" % TASK_ID)
	_done = true
	return true


func _fail(why: String) -> bool:
	print("FAIL %s: %s" % [TASK_ID, why])
	_done = true
	return true
