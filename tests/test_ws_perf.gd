extends SceneTree
## Wave Strike perf probe (docs/design/wave-strike.md 7.8, M1 "ws150" / the 200-unit question): Ashwind Reach, no horns,
## no wizards; 100 lane units per side (the 4 M1 cards of each kingdom) spawned at both gates, all marching (LaneMarch)
## and then clashing in the middle. Frame time (process + physics, headless: no rendering) in two windows: MARCH
## (all 200 alive, walking) and CLASH (the fight). Prints "WS_PERF {...}" and "PASS ws_perf" when MARCH p95 <= budget
## (default 16.7 ms) and no lane unit stalled. Models and their animation run (sim mode off).
## Load calibration (2026-10-07, as test_20_a3 / test_9_c5 / test_12_a1): CI on the busy laptop measured march p95 17.3 to
## 20.7 ms with an average of 14-17 ms (every frame slower, not a few spikes: the PC, not the code), and 12.1 ms on a
## quieter run of the same code. The test times test_20_a3's fixed GDScript loop (_calib_once) every CAL_EVERY frames,
## best of CAL_REPEAT, OUTSIDE the timed frames, and scales the budget by how much slower that loop runs than on the
## quiet laptop (CAL_QUIET_MS, never below 1x): budget x max(1, loop / quiet). On a quiet PC the verdict is the plain
## 16.7 ms p95 line. p50 (median) is printed for march and clash, and the unscaled verdict is printed as info.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ws_perf.gd --fixed-fps 60 --quit-after 6000 '--' --per-side=100

const SCENE := "res://scenes/wave_strike.tscn"
const IDS := [[&"flame_guard", &"ember_archer", &"blaze_rider", &"cinder_arbalest"], [&"shade", &"nightbolt", &"gloam_rider", &"barrow_knight"]]

var level: Node
var per_side := 100
var budget_ms := 16.7
var _frames := 0
var _spawned := false
var _next_i := 0
var _spawn_frame := 0
var _last := 0
var _march: Array[int] = []
var _clash: Array[int] = []
var _alive_min_clash := 1 << 30
var _valve_fail := ""
## test_20_a3's calibration loop median on the quiet laptop (2026-10-02): 0.232 ms.
const CAL_QUIET_MS := 0.232
const CAL_EVERY := 30
const CAL_REPEAT := 3
var _cal_pts: Array[Vector3] = []
var _cal_dict := {}
var _cal_samples: Array[int] = []
var _cal_sink := 0.0


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		if s.begins_with("per-side="):
			per_side = int(s.substr(9))
		elif s.begins_with("budget="):
			budget_ms = float(s.substr(7))
	for i in 256:
		_cal_pts.append(Vector3(float((i * 37) % 101) - 50.0, 0.0, float((i * 53) % 97) - 48.0))
	for i in 64:
		_cal_dict[i] = i * 0.5
	level = (load(SCENE) as PackedScene).instantiate()
	var rules: Resource = (load("res://scripts/world/wave_strike/wave_strike_rules.gd") as Script).call(&"load_default")
	rules.set(&"horn_first", 100000.0)
	rules.set(&"time_limit", 0.0)
	rules.set(&"field_cap", per_side)   # the field valve (balance pass 2): one more spawn per side must be refused
	level.set(&"rules", rules)
	level.set(&"autopilot_player", true)
	level.set(&"wizards_enabled", false)
	root.add_child(level)
	current_scene = level


func _process(_delta: float) -> bool:
	_frames += 1
	var now := Time.get_ticks_usec()
	var dt := now - _last
	_last = now
	if _frames % CAL_EVERY == 0:
		# Calibration sample; _last restarts after it, so the next frame's dt does not include the loop.
		var best := 1 << 30
		for r in CAL_REPEAT:
			best = mini(best, _calib_once())
		_cal_samples.append(best)
		_last = Time.get_ticks_usec()
	if level.get(&"director") == null:
		return _frames > 3000
	if not _spawned:
		# like the game's spawners (one unit per 0.15 s per gate, so their 0.25 s retarget scans spread over frames),
		# but faster: 2 per side per frame; rows go forward from the gate (never into the Bastion plaza)
		for k in 2:
			var i := _next_i
			for team in 2:
				var gate: Vector3 = level.call(&"gate_position", team)
				var fwd := Vector3.RIGHT if team == 0 else Vector3.LEFT
				var lat := (float(i % 10) - 4.5) / 4.5 * 8.0
				var pos := gate + Vector3(0, 0, lat * 1.6) + fwd * (i / 10) * 1.6
				level.call(&"spawn_lane_unit", team, IDS[team][i % 4], pos, lat)
			_next_i += 1
			if _next_i >= per_side:
				_spawned = true
				break
		if _spawned:
			_spawn_frame = _frames
			for team in 2:
				var extra: Variant = level.call(&"spawn_lane_unit", team, IDS[team][0], level.call(&"gate_position", team), 0.0)
				if extra != null:
					_valve_fail = "field cap %d: spawn %d of team %d was not refused" % [per_side, per_side + 1, team]
		return false
	var f := _frames - _spawn_frame
	if f < 30:
		return false   # spawn / first nav queries settle
	var alive: int = (level.call(&"lane_units", -1) as Array).size()
	var enemies_close := _front_gap() < 14.0
	if not enemies_close and alive >= per_side * 2 - 2:
		_march.append(dt)
	elif enemies_close:
		_clash.append(dt)
		_alive_min_clash = mini(_alive_min_clash, alive)
	if _clash.size() >= 600 or f > 3600:
		_report()
		return true
	return false


## The x gap between the most advanced units of both sides.
func _front_gap() -> float:
	var a := -INF
	var b := INF
	for u: Node3D in level.call(&"lane_units", -1):
		if int(u.get(&"team")) == 0:
			a = maxf(a, u.global_position.x)
		else:
			b = minf(b, u.global_position.x)
	return b - a


static func _stats(arr: Array[int]) -> Dictionary:
	if arr.is_empty():
		return {"frames": 0}
	var s := arr.duplicate()
	s.sort()
	var sum := 0
	for v in s:
		sum += v
	return {"frames": s.size(), "avg_ms": snappedf(sum / float(s.size()) / 1000.0, 0.01),
		"p50_ms": snappedf(s[s.size() / 2] / 1000.0, 0.01),
		"p95_ms": snappedf(s[int(s.size() * 0.95)] / 1000.0, 0.01), "max_ms": snappedf(s[s.size() - 1] / 1000.0, 0.01)}


func _report() -> void:
	var lm: Script = load("res://scripts/units/lane_march.gd") as Script
	var m := _stats(_march)
	var c := _stats(_clash)
	var cal_ms := _cal_median_usec() / 1000.0
	var load_x := maxf(1.0, cal_ms / CAL_QUIET_MS) if cal_ms > 0.0 else 1.0
	var eff_budget := budget_ms * load_x
	var line := {"per_side": per_side, "march": m, "clash": c, "clash_alive_min": _alive_min_clash,
		"stalls": int(lm.get(&"stall_events")), "cal_ms": snappedf(cal_ms, 0.001), "cal_samples": _cal_samples.size(),
		"load": snappedf(load_x, 0.01), "budget_ms": budget_ms, "budget_scaled_ms": snappedf(eff_budget, 0.01)}
	print("WS_PERF " + JSON.stringify(line))
	var p95: float = float(m.get("p95_ms", 999.0))
	print("ws_perf: march p50 %.2f / p95 %.2f ms, clash p50 %.2f / p95 %.2f ms; calibration loop %.3f ms (quiet %.3f) = load x%.2f -> budget %.2f ms (plain %.1f ms line: %s)" % [
			float(m.get("p50_ms", -1.0)), p95, float(c.get("p50_ms", -1.0)), float(c.get("p95_ms", -1.0)), cal_ms,
			CAL_QUIET_MS, load_x, eff_budget, budget_ms, "under" if p95 <= budget_ms else "over"])
	var ok := int(m.get("frames", 0)) > 30 and p95 <= eff_budget and int(line["stalls"]) == 0 \
			and _valve_fail == ""
	if _valve_fail != "":
		print("FAIL ws_perf: %s" % _valve_fail)
	if ok:
		print("PASS ws_perf (march p50 %.2f / p95 %.2f ms, clash p95 %.2f ms at %d units; budget %.2f ms = %.1f x load %.2f)" % [
				m["p50_ms"], m["p95_ms"], c.get("p95_ms", -1.0), per_side * 2, eff_budget, budget_ms, load_x])
	else:
		print("FAIL ws_perf: march %s clash %s stalls %d (budget %.2f ms = %.1f x load %.2f)" % [str(m), str(c), line["stalls"],
				eff_budget, budget_ms, load_x])
	quit(0 if ok else 1)


## The calibration workload (usec), test_20_a3's: a fixed loop of Vector3 math, typed-array reads and Dictionary lookups.
func _calib_once() -> int:
	var t0 := Time.get_ticks_usec()
	var acc := 0.0
	var n := _cal_pts.size()
	for r in 8:
		for i in n:
			var p := _cal_pts[i]
			var d := p.distance_squared_to(_cal_pts[(i * 7 + r) % n])
			if d < 400.0:
				acc += sqrt(d)
			acc += float(_cal_dict.get(i & 63, 0.0))
	_cal_sink += acc
	return Time.get_ticks_usec() - t0


func _cal_median_usec() -> float:
	if _cal_samples.is_empty():
		return 0.0
	var s := _cal_samples.duplicate()
	s.sort()
	return float(s[s.size() / 2])
