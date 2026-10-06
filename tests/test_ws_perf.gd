extends SceneTree
## Wave Strike perf probe (docs/design/wave-strike.md 7.8, M1 "ws150" / the 200-unit question): Ashwind Reach, no horns,
## no wizards; 100 lane units per side (the 4 M1 cards of each kingdom) spawned at both gates, all marching (LaneMarch)
## and then clashing in the middle. Frame time (process + physics, headless: no rendering) in two windows: MARCH
## (all 200 alive, walking) and CLASH (the fight). Prints "WS_PERF {...}" and "PASS ws_perf" when MARCH p95 <= budget
## (default 16.7 ms) and no lane unit stalled. Models and their animation run (sim mode off).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ws_perf.gd --fixed-fps 60 --quit-after 6000 '--' --per-side=100

const SCENE := "res://scenes/wave_strike.tscn"
const IDS := [[&"flame_guard", &"ember_archer", &"blaze_rider", &"cinder_arbalest"], [&"shade", &"grave_hound", &"bleakbow", &"hollow_oathsworn"]]

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


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		if s.begins_with("per-side="):
			per_side = int(s.substr(9))
		elif s.begins_with("budget="):
			budget_ms = float(s.substr(7))
	level = (load(SCENE) as PackedScene).instantiate()
	var rules: Resource = (load("res://scripts/world/wave_strike/wave_strike_rules.gd") as Script).call(&"load_default")
	rules.set(&"horn_first", 100000.0)
	rules.set(&"time_limit", 0.0)
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
		"p95_ms": snappedf(s[int(s.size() * 0.95)] / 1000.0, 0.01), "max_ms": snappedf(s[s.size() - 1] / 1000.0, 0.01)}


func _report() -> void:
	var lm: Script = load("res://scripts/units/lane_march.gd") as Script
	var m := _stats(_march)
	var c := _stats(_clash)
	var line := {"per_side": per_side, "march": m, "clash": c, "clash_alive_min": _alive_min_clash,
		"stalls": int(lm.get(&"stall_events"))}
	print("WS_PERF " + JSON.stringify(line))
	var ok := int(m.get("frames", 0)) > 30 and float(m.get("p95_ms", 999.0)) <= budget_ms and int(line["stalls"]) == 0
	if ok:
		print("PASS ws_perf (march p95 %.2f ms, clash p95 %.2f ms at %d units)" % [m["p95_ms"], c.get("p95_ms", -1.0), per_side * 2])
	else:
		print("FAIL ws_perf: march %s clash %s stalls %d (budget %.1f ms)" % [str(m), str(c), line["stalls"], budget_ms])
	quit(0 if ok else 1)
