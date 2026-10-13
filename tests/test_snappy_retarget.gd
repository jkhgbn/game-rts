extends SceneTree
## Snappy retarget (JS 2026-10-13): a unit whose target dies picks a new one within 1-2 physics frames, whatever its
## retarget timer or scan bucket says. Mission 1 map (no UnitGrid), then the same with a UnitGrid. Checks:
## (a) a skirmish-style unit (scan_bucket -1, timer forced to 10 s): target killed -> new target within 2 frames;
## (b) a lane-style unit (scan_bucket set to a bucket 7 frames away): same;
## (c) a burst: 30 attackers (half with buckets) lose their targets on one frame -> all retargeted within 2 frames,
##     at most Unit.EVENT_SCANS_PER_FRAME event scans in any frame.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_snappy_retarget.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "snappy_retarget"
const MAX_FRAMES := 2
const BURST := 30

var main: Node
var _wait := 0
var _stage := 0
var _pass := 0               # 0 = no grid, 1 = with a UnitGrid
var _base := Vector3.ZERO
var _attackers: Array[Unit] = []
var _old: Array[Node3D] = []
var _spawned: Array[Unit] = []
var _kill_frame := -1
var _settle := 0
var _events_last := 0
var _max_events := 0
var _report: Array[String] = []
var _done := false


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _physics_process(_delta: float) -> bool:
	if _done:
		return true
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			return _fail("navigation never finished baking")
		return false
	if _stage == 0:
		_base = (main.hero as Node3D).global_position + Vector3(12, 0, 12)
		_stage = 1
		_setup_single(-1)
		return false
	if _kill_frame < 0:
		_settle += 1
		if _settle < 30:
			return false
		for i in _attackers.size():
			if _attackers[i].attack_target != _old[i]:
				return _fail("stage %d: attacker %d is not on its first target (%s)" % [_stage, i, _attackers[i].attack_target])
		_kill()
		return false
	_count_events()
	var f := Engine.get_physics_frames() - _kill_frame
	var ok := 0
	for i in _attackers.size():
		var t := _attackers[i].attack_target
		if t != null and t != _old[i] and Unit._target_alive(t):
			ok += 1
	if ok == _attackers.size():
		_report.append("grid=%d stage %s: %d unit(s) retargeted in %d frame(s), max event scans/frame %d" % [
				_pass, ["", "a", "b", "c"][_stage], ok, f, _max_events])
		if f > MAX_FRAMES:
			return _fail("stage %d: took %d frames" % [_stage, f])
		if _max_events > Unit.EVENT_SCANS_PER_FRAME:
			return _fail("stage %d: %d event scans in one frame" % [_stage, _max_events])
		_next_stage()
		return false
	if f > 30:
		return _fail("stage %d: only %d / %d retargeted after %d frames" % [_stage, ok, _attackers.size(), f])
	return false


func _next_stage() -> void:
	_clear()
	_stage += 1
	if _stage == 2:
		_setup_single(-2)
	elif _stage == 3:
		_setup_burst()
	elif _pass == 0:
		_pass = 1
		UnitGrid.ensure(main)
		_stage = 1
		_setup_single(-1)
	else:
		for line in _report:
			print(line)
		print("PASS %s" % TASK_ID)
		_done = true


## bucket -1 = timer unit; -2 = a bucket far from the kill frame (set at the kill).
func _setup_single(bucket: int) -> void:
	var a := _spawn(&"flame_guard", Unit.Team.PLAYER, _base)
	var t1 := _spawn(&"shade", Unit.Team.ENEMY, _base + Vector3(1.5, 0, 0))
	_spawn(&"shade", Unit.Team.ENEMY, _base + Vector3(-3.5, 0, 0))
	a.set_auto_target(t1)
	a.scan_bucket = bucket
	_attackers.append(a)
	_old.append(t1)


func _setup_burst() -> void:
	for i in BURST:
		var p := _base + Vector3(float(i % 6) * 3.0 - 7.5, 0, float(i / 6) * 3.0 - 6.0)
		var a := _spawn(&"ember_archer", Unit.Team.PLAYER, p)
		var t := _spawn(&"shade", Unit.Team.ENEMY, p + Vector3(1.2, 0, 0))
		_spawn(&"shade", Unit.Team.ENEMY, p + Vector3(0, 0, 1.4))
		a.set_auto_target(t)
		a.scan_bucket = -2 if i % 2 == 0 else -1
		_attackers.append(a)
		_old.append(t)


func _spawn(id: StringName, team: int, p: Vector3) -> Unit:
	var u: Unit = main.make_unit(str(id))
	u.set(&"team", team)
	main.add_child(u)
	u.set_down(p)   # also moves the leash anchor here
	u.attacks_blocked = true   # nobody kills anybody before the test does (targets are kept)
	if team != Unit.Team.PLAYER:
		u.command_hold()
	_spawned.append(u)
	return u


func _kill() -> void:
	var now := Engine.get_physics_frames()
	for a in _attackers:
		a.set(&"_retarget_left", 10.0)   # the periodic timer is far away: only the event can explain a quick switch
		if a.scan_bucket == -2:
			a.scan_bucket = (now + 7) % Unit.SCAN_BUCKETS
		elif a.scan_bucket >= 0:
			a.scan_bucket = (now + 7) % Unit.SCAN_BUCKETS
	for t in _old:
		(t as Unit).take_damage(1.0e9, null)
	_kill_frame = now
	_events_last = Unit.event_scans
	_max_events = 0


func _count_events() -> void:
	var n := Unit.event_scans - _events_last
	_events_last = Unit.event_scans
	_max_events = maxi(_max_events, n)


func _clear() -> void:
	for u in _spawned:
		if is_instance_valid(u):
			u.queue_free()
	_spawned.clear()
	_attackers.clear()
	_old.clear()
	_kill_frame = -1
	_settle = 0


func _fail(why: String) -> bool:
	for line in _report:
		print(line)
	print("FAIL %s: %s" % [TASK_ID, why])
	_done = true
	return true
