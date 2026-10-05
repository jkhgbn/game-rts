extends SceneTree
## Unit Lab sandbox (scenes/unit_lab.tscn, docs/plan/unit-lab.md part B) boots headless and a scripted session works:
## spawn two groups at points, the tree stays paused before Start, Step runs ~0.5 s then pauses, Start plays the
## fight to its end (the damage meter / records fill), Reset respawns the same setup, a status / modifier applies,
## save -> load round-trips the setup through the runner's spec format, the screenshot is skipped headless.
## Run:  godot --headless --path . -s tests/test_unit_lab_sandbox.gd --fixed-fps 60 --quit-after 30000

const TASK_ID := "unit_lab_sandbox"
const SCENE := "res://scenes/unit_lab.tscn"
const SPEC := preload("res://tools/unit_lab/unit_lab_spec.gd")
const TIMEOUT_FRAMES := 28000

var lab: Node3D
var frame := 0
var _started := false
var _done := false
var _errors: Array[String] = []
var _cases := 0


func _initialize() -> void:
	lab = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(lab)
	current_scene = lab


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 3 and not _started:
		_started = true
		_run()
	if _done:
		paused = false
		if _errors.is_empty():
			print("PASS %s (%d checks)" % [TASK_ID, _cases])
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 20))])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out; %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _check(ok: bool, what: String) -> void:
	_cases += 1
	if not ok:
		_errors.append(what)
		print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _run() -> void:
	_check(lab.get(&"camera") != null and lab.get(&"ui") != null, "the sandbox built its camera and UI")
	_check(paused, "the tree waits paused before Start")
	var a: Array = lab.call(&"spawn_group_at", {"id": "flame_guard", "count": 3}, 0, Vector3(-6, 0, 0))
	var b: Array = lab.call(&"spawn_group_at", {"id": "shade", "count": 3, "level": 2}, 1, Vector3(6, 0, 0))
	_check(a.size() == 3 and b.size() == 3, "spawned 3 + 3 at the points")
	_check((lab.call(&"living_units", 0) as Array).size() == 3 and (lab.call(&"living_units", 1) as Array).size() == 3,
			"living units per side")
	_check(int((b[0] as Unit).level) == 2, "level 2 applied")
	lab.call(&"apply_status_to_team", 1, "chill", 5.0)
	_check((b[0] as Unit).has_status(&"chill"), "status applied to side B")
	lab.call(&"apply_buff_to_team", 0, 0)
	_check((a[0] as Unit).has_modifier(&"unit_lab_buff_0"), "modifier applied to side A")
	await _frames(10)
	_check(float(lab.get(&"time")) == 0.0, "nothing runs before Start")
	# scripted step
	lab.call(&"step", 0.5)
	var f := 0
	while not paused and f < 600:
		await physics_frame
		f += 1
	var t := float(lab.get(&"time"))
	_check(paused and t > 0.3 and t < 0.8, "Step ran ~0.5 s then paused (t %.2f)" % t)
	# play to the end
	lab.call(&"start_fight")
	f = 0
	while not bool(lab.get(&"ended")) and f < 60 * 90:
		await physics_frame
		f += 1
	_check(bool(lab.get(&"ended")), "the fight ended")
	var r: Dictionary = lab.get(&"result")
	_check(String(r.get("winner", "")) in ["a", "b", "draw"], "a result with a winner (%s)" % r.get("winner", "?"))
	_check(float(r["a"]["dealt"]) > 0.0 and float(r["b"]["dealt"]) > 0.0, "the meter counted damage both ways")
	_check(not (lab.get(&"log_lines") as Array).is_empty(), "the fight log has lines")
	# reset keeps the setup
	lab.call(&"reset_setup")
	await _frames(2)
	_check((lab.call(&"living_units", 0) as Array).size() == 3 and (lab.call(&"living_units", 1) as Array).size() == 3,
			"Reset respawns the same 3 + 3")
	_check(float(lab.get(&"time")) == 0.0 and paused, "Reset waits paused at t 0")
	# save / load
	var path: String = lab.call(&"save_setup", "user://unit_lab_sandbox_test.json")
	_check(path != "" and FileAccess.file_exists(path), "setup saved (%s)" % path)
	var errs: Array = []
	var spec := SPEC.load_any(path, errs)
	_check(errs.is_empty() and (spec["arms"] as Array).size() == 1 and \
			int(spec["arms"][0]["b"]["groups"][0]["count"]) == 3, "the saved file is a runner spec (%s)" % str(errs))
	lab.call(&"clear_setup")
	_check((lab.call(&"living_units", 0) as Array).is_empty(), "Clear empties the arena")
	_check(bool(lab.call(&"load_setup", path)), "load_setup")
	await _frames(2)
	_check((lab.call(&"living_units", 1) as Array).size() == 3, "the loaded setup respawned side B")
	_check(bool(lab.call(&"load_setup", "c1_kilnwarden")), "a preset loads in the sandbox")
	await _frames(2)
	_check((lab.call(&"living_units", 0) as Array).size() == 7, "C1 caster arm: 6 + 1 on side A")
	_check(String(lab.call(&"screenshot")) == "", "no screenshot headless")
	lab.call(&"set_speed_index", 0)
	_check(is_equal_approx(Engine.time_scale, 0.1), "slow motion 0.1x")
	lab.call(&"set_speed_index", 3)
	_done = true
