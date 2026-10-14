extends SceneTree
## WS3.G1 + WS4.G1 (wave-strike.md 15.3 / 16.2): LaneMarch formation hold / lock / release and release effects, driven
## directly (no pad, no WaveFormation: a stub formation with members + release()). Wave Strike level, no horns, no wizards.
## Phases:
## A  30 copies (front row flame_guard, riders on the wings, a second guard row, archers behind) spawned one every
##    0.15 s on pad-mapped cells and held: none moves > 0.3 m before the hold ends; then locked at the slowest speed:
##    10 s in, each row still >= 1.0 m behind the row in front and no rider ahead of row 0; contact with a held enemy
##    group releases every member in the same frame, ws_lock gone, release effects (haste / braced / shroud / shield 150)
##    applied exactly once.
## B  the 45 s timeout releases a locked formation (wave speed 1.5: no contact on the way), measured speed ~1.5.
## C  a hit (HP loss) on one held+locked member releases all in the same frame.
## D  lock off (march(0)): release effects wait for the first contact, then fire once.
## Always: LaneMarch.stall_events == 0.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ws_formation_march.gd --fixed-fps 60 --quit-after 12000

const TASK_ID := "ws_formation_march"
const SCENE := "res://scenes/wave_strike.tscn"
const STAGGER_FRAMES := 9          ## 0.15 s
const HOLD_EXTRA_FRAMES := 30      ## 0.5 s
const ENEMY_AHEAD := 85.0


class Form extends RefCounted:
	var members: Array[LaneMarch] = []
	var calls := 0

	var reason := ""

	func release(p_reason: String = "contact") -> void:
		calls += 1
		reason = p_reason
		for lm in members:
			if is_instance_valid(lm):
				lm.release()

	func released_count() -> int:
		var n := 0
		for lm in members:
			if is_instance_valid(lm) and lm.is_released():
				n += 1
		return n

	func alive() -> Array[LaneMarch]:
		var out: Array[LaneMarch] = []
		for lm in members:
			if is_instance_valid(lm) and lm.unit and is_instance_valid(lm.unit) and lm.unit.is_alive():
				out.append(lm)
		return out


var level: Node
var _frames := 0
var _phase := ""
var _t := 0                        ## frames in the current phase
var _gate := Vector3.ZERO
var _fwd := Vector3.RIGHT
var _side := Vector3.ZERO
var _plan: Array[Dictionary] = []  ## {id, c, r, f, row, fx}
var _form: Form
var _spawn_pos: Dictionary = {}    ## LaneMarch -> Vector3
var _row_of: Dictionary = {}       ## LaneMarch -> row tag
var _max_hold_move := 0.0
var _march_frame := -1
var _release_frame := -1
var _rider_speed := 0.0
var _probe_pos := Vector3.ZERO
var _done := false
var _d_seen: Dictionary = {}
var _log: Array[String] = []


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


func _process(_delta: float) -> bool:
	_frames += 1
	if _done:
		return true
	if level.get(&"director") == null:
		if _frames > 3000:
			return _fail("the level never started")
		return false
	if _phase == "":
		if _frames < 30:
			return false
		_start_a()
	_t += 1
	match _phase:
		"a_hold":
			return _tick_a_hold()
		"a_march":
			return _tick_a_march()
		"a_after":
			return _tick_a_after()
		"b":
			return _tick_b()
		"c":
			return _tick_c()
		"d":
			return _tick_d()
		"e":
			return _tick_e()
	return false


# ------------------------------------------------------------------ helpers

func _cell_pos(c: int, r: int, f: int) -> Vector3:
	var lat := (float(c) + f * 0.5 - 8.0) * 1.5
	var fwd := 12.0 - (float(r) + f * 0.5) * 1.5
	return _gate + _side * lat + _fwd * fwd


func _progress(u: Node3D) -> float:
	return (u.global_position - _gate).dot(_fwd)


func _spawn(team: int, id: StringName, pos: Vector3, lat: float) -> Unit:
	return level.call(&"spawn_lane_unit", team, id, pos, lat) as Unit


## An enemy that stands still (no LaneMarch).
func _enemy(id: StringName, pos: Vector3) -> Unit:
	var u := _spawn(1, id, pos, 0.0)
	if u:
		var lm := u.get_node_or_null(^"LaneMarch")
		if lm:
			u.remove_child(lm)
			lm.free()
		u.command_hold()
	return u


func _kill_all() -> void:
	for u: Unit in level.call(&"lane_units", -1):
		u.take_damage(1.0e9, null)
	for n in root.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and (u.has_meta(&"ws_card")):
			u.take_damage(1.0e9, null)


func _next(p: String) -> void:
	_phase = p
	_t = 0


# ------------------------------------------------------------------ A: hold, lock, contact, effects

func _start_a() -> void:
	(load("res://scripts/units/lane_march.gd") as Script).call(&"reset_counters")
	_gate = level.call(&"gate_position", 0)
	_fwd = Vector3.RIGHT
	_side = Vector3(-_fwd.z, 0.0, _fwd.x)
	# front to back, centre outward (15.3 step 1)
	for c: int in [7, 8, 6, 9, 5, 10, 4, 11, 3, 12]:
		_plan.append({"id": &"flame_guard", "c": c, "r": 0, "f": 1, "row": 0,
				"fx": [{"status": "braced", "duration": 6.0}]})
	for rc: Array in [[0, 0], [14, 0], [0, 2], [14, 2]]:
		_plan.append({"id": &"blaze_rider", "c": rc[0], "r": rc[1], "f": 2, "row": -1,
				"fx": [{"status": "haste", "duration": 6.0}]})
	for c: int in [7, 8, 6, 9, 5, 10, 4, 11]:
		_plan.append({"id": &"flame_guard", "c": c, "r": 2, "f": 1, "row": 2,
				"fx": [{"status": "shroud", "duration": 5.0}]})
	for c: int in [7, 8, 6, 9, 5, 10, 4, 11]:
		_plan.append({"id": &"ember_archer", "c": c, "r": 4, "f": 1, "row": 4,
				"fx": [{"shield": 150.0, "duration": 10.0}]})
	_form = Form.new()
	for i in 6:
		_enemy(&"shade", _gate + _fwd * ENEMY_AHEAD + _side * (float(i) - 2.5) * 2.0)
	_next("a_hold")


func _tick_a_hold() -> bool:
	var k := (_t - 1) / STAGGER_FRAMES
	if (_t - 1) % STAGGER_FRAMES == 0 and k < _plan.size():
		var p: Dictionary = _plan[k]
		var want := _cell_pos(int(p["c"]), int(p["r"]), int(p["f"]))
		var lat := (float(p["c"]) + float(p["f"]) * 0.5 - 8.0) * 1.5
		var u := _spawn(0, p["id"], want, lat)
		if u == null:
			return _fail("spawn %d refused" % k)
		var lm := u.get_node(^"LaneMarch") as LaneMarch
		lm.set_release_effects(p["fx"])
		lm.hold(_form)
		_form.members.append(lm)
		_spawn_pos[lm] = u.global_position
		_row_of[lm] = int(p["row"])
		var off := Vector2(u.global_position.x - want.x, u.global_position.z - want.z).length()
		if off > 0.3:
			return _fail("copy %d spawned %.2f m from its cell" % [k, off])
	for lm: LaneMarch in _form.members:
		if not lm.is_held():
			return _fail("a member left the hold early (frame %d)" % _t)
		var sp: Vector3 = _spawn_pos[lm]
		_max_hold_move = maxf(_max_hold_move, Vector2(lm.unit.global_position.x - sp.x, lm.unit.global_position.z - sp.z).length())
	if _max_hold_move > 0.3:
		return _fail("a held unit moved %.2f m" % _max_hold_move)
	if _t >= _plan.size() * STAGGER_FRAMES + HOLD_EXTRA_FRAMES:
		var units: Array = []
		for lm in _form.members:
			units.append(lm.unit)
		var speed: float = LaneMarch.march_speed(units, 4.0)
		if absf(speed - 5.0) > 0.01:
			return _fail("march speed %.2f (want 5.0, the slowest)" % speed)
		for lm in _form.members:
			lm.march(speed)
		for lm in _form.members:
			if not lm.is_locked():
				return _fail("march did not lock")
			if lm.unit.get_stat(&"move_speed") > speed + 0.01:
				return _fail("%s locked at %.2f > %.2f" % [lm.unit.name, lm.unit.get_stat(&"move_speed"), speed])
		_log.append("A hold: 30 held, max move %.2f m" % _max_hold_move)
		_march_frame = _frames
		_next("a_march")
	return false


func _tick_a_march() -> bool:
	var n_rel := _form.released_count()
	if n_rel > 0:
		var alive := _form.alive()
		if n_rel < _form.members.size():
			return _fail("contact released %d / %d members in one frame" % [n_rel, _form.members.size()])
		_release_frame = _frames
		var any_target := false
		for lm in alive:
			if lm.unit.attack_target != null:
				any_target = true
			if lm.unit.has_modifier(&"ws_lock"):
				return _fail("ws_lock left on a released unit")
			if lm.effects_applied != 1:
				return _fail("release effects applied %d times" % lm.effects_applied)
			var fx: Array = lm.release_effects
			var d: Dictionary = fx[0]
			if d.has("status") and not lm.unit.has_status(StringName(str(d["status"]))):
				return _fail("status %s missing at release" % d["status"])
			if d.has("shield") and lm.unit.shield < 149.0:
				return _fail("shield %.0f at release (want 150)" % lm.unit.shield)
		if not any_target:
			return _fail("released without a target (not a contact release)")
		_log.append("A release: %d members in frame %d, %.1f s into the march, formation.release calls %d" % [
				n_rel, _frames, float(_frames - _march_frame) / 60.0, _form.calls])
		_next("a_after")
		return false
	var mf := _frames - _march_frame
	if mf == 60:
		for lm in _form.members:
			if _row_of[lm] == -1:
				_probe_pos = lm.unit.global_position
				break
	if mf == 360:
		for lm in _form.members:
			if _row_of[lm] == -1:
				_rider_speed = (lm.unit.global_position - _probe_pos).length() / 5.0
				break
	if mf == 600:
		var rows := {0: [], 2: [], 4: []}
		var rider_max := -INF
		for lm in _form.members:
			var r: int = _row_of[lm]
			if r < 0:
				rider_max = maxf(rider_max, _progress(lm.unit))
			else:
				(rows[r] as Array).append(_progress(lm.unit))
		var mean := {}
		var front_max := -INF
		for r: int in rows:
			var s := 0.0
			for v: float in rows[r]:
				s += v
				if r == 0:
					front_max = maxf(front_max, v)
			mean[r] = s / float((rows[r] as Array).size())
		_log.append("A 10 s: row means %.1f / %.1f / %.1f, rider max %.1f (front max %.1f), rider speed %.2f" % [
				mean[0], mean[2], mean[4], rider_max, front_max, _rider_speed])
		if float(mean[0]) - float(mean[2]) < 1.0 or float(mean[2]) - float(mean[4]) < 1.0:
			return _fail("rows lost their order: %.1f / %.1f / %.1f" % [mean[0], mean[2], mean[4]])
		if rider_max > front_max + 0.5:
			return _fail("a rider (%.1f) is ahead of row 0 (%.1f)" % [rider_max, front_max])
		if _rider_speed > 5.3:
			return _fail("a locked rider walked %.2f m/s" % _rider_speed)
		if float(mean[0]) < 35.0:
			return _fail("the formation barely moved (%.1f m)" % mean[0])
	if mf > 40 * 60:
		return _fail("no contact in 40 s")
	return false


func _tick_a_after() -> bool:
	if _t == 300:
		for lm in _form.members:
			if is_instance_valid(lm) and lm.effects_applied > 1:
				return _fail("release effects applied twice")
		_kill_all()
		_start_b()
	return false


# ------------------------------------------------------------------ B: 45 s timeout

func _start_b() -> void:
	_form = Form.new()
	for i in 4:
		var u := _spawn(0, &"flame_guard", _gate + _side * (float(i) - 1.5) * 1.5 + _fwd * 6.0, (float(i) - 1.5) * 1.5)
		var lm := u.get_node(^"LaneMarch") as LaneMarch
		lm.hold(_form)
		_form.members.append(lm)
	_next("b")


func _tick_b() -> bool:
	if _t == 30:
		for lm in _form.members:
			lm.march(1.5)
		_march_frame = _frames
	if _march_frame < 0 or _t <= 30:
		return false
	var mf := _frames - _march_frame
	if mf == 300:
		_probe_pos = _form.members[0].unit.global_position
	if mf == 1500:
		var v := Vector2(_form.members[0].unit.global_position.x - _probe_pos.x,
				_form.members[0].unit.global_position.z - _probe_pos.z).length() / 20.0
		_log.append("B locked speed %.2f m/s (wave speed 1.5)" % v)
		if absf(v - 1.5) > 0.3:
			return _fail("locked at 1.5 but walked %.2f m/s" % v)
	var n := _form.released_count()
	if n > 0:
		var s := float(mf) / 60.0
		if n < _form.members.size():
			return _fail("timeout released %d / %d in one frame" % [n, _form.members.size()])
		if s < 44.5 or s > 45.8:
			return _fail("released after %.2f s (want 45)" % s)
		_log.append("B timeout release after %.2f s (reason %s)" % [s, _form.reason])
		if _form.reason != "timeout":
			return _fail("timeout release reason %s" % _form.reason)
		_kill_all()
		_start_c()
	elif mf > 50 * 60:
		return _fail("no timeout release")
	return false


# ------------------------------------------------------------------ C: a hit releases the whole formation

func _start_c() -> void:
	_form = Form.new()
	for i in 3:
		var u := _spawn(0, &"flame_guard", _gate + _side * (float(i) - 1.0) * 1.5 + _fwd * 6.0, (float(i) - 1.0) * 1.5)
		var lm := u.get_node(^"LaneMarch") as LaneMarch
		lm.hold(_form)
		_form.members.append(lm)
	_march_frame = -1
	_next("c")


func _tick_c() -> bool:
	if _t == 20:
		for lm in _form.members:
			lm.march(4.0)
	if _t == 60:
		_form.members[2].unit.take_damage(5.0, null)
		_march_frame = _frames
	if _march_frame < 0:
		return false
	var n := _form.released_count()
	if n > 0:
		if n < _form.members.size():
			return _fail("a hit released %d / %d in one frame" % [n, _form.members.size()])
		_log.append("C hit release after %d frames" % (_frames - _march_frame))
		_kill_all()
		_start_d()
	elif _frames - _march_frame > 30:
		return _fail("a hit did not release the formation")
	return false


# ------------------------------------------------------------------ D: lock off = effects at the first contact

func _start_d() -> void:
	_form = Form.new()
	for i in 3:
		var u := _spawn(0, &"flame_guard", _gate + _side * (float(i) - 1.0) * 1.5 + _fwd * 6.0, (float(i) - 1.0) * 1.5)
		var lm := u.get_node(^"LaneMarch") as LaneMarch
		lm.set_release_effects([{"status": "haste", "duration": 4.0}])
		lm.march(0.0)
		_form.members.append(lm)
		if not lm.is_released() or lm.unit.has_modifier(&"ws_lock"):
			_fail("lock off still locked")
	_enemy(&"barrow_knight", _gate + _fwd * 40.0 + _side * 1.5)
	_enemy(&"barrow_knight", _gate + _fwd * 40.0 - _side * 1.5)
	_next("d")


func _tick_d() -> bool:
	var fired := 0
	for lm in _form.members:
		if lm.effects_applied > 1:
			return _fail("lock off: effects applied twice")
		if lm.effects_applied == 1:
			fired += 1
			if not _d_seen.has(lm):
				_d_seen[lm] = true
				if lm.unit.attack_target == null:
					return _fail("lock off: effects fired without a contact")
				if not lm.unit.has_status(&"haste"):
					return _fail("lock off: effects fired without haste")
	if fired == _form.members.size():
		_log.append("D lock off: effects at first contact on %d units (%.1f s)" % [fired, float(_t) / 60.0])
		_kill_all()
		return _start_e()
	if _t > 30 * 60:
		return _fail("lock off: effects on %d / %d units after 30 s" % [fired, _form.members.size()])
	return false


# ------------------------------------------------------------------ E: the real WaveFormation (WS3.C2), when present

const WF_PATH := "res://scripts/world/wave_strike/wave_formation.gd"
var _wf: Object = null
var _e_units: Array[Unit] = []


func _start_e() -> bool:
	if not ResourceLoader.exists(WF_PATH):
		_log.append("E WaveFormation absent: skipped")
		return _report()
	_wf = (load(WF_PATH) as Script).new()
	var ids: Array[StringName] = [&"flame_guard", &"blaze_rider", &"ember_archer"]
	for i in 3:
		var u := _spawn(0, ids[i], _gate + _side * (float(i) - 1.0) * 3.0 + _fwd * 6.0, (float(i) - 1.0) * 3.0)
		_wf.call(&"add_member", u, [{"shield": 150.0, "duration": 10.0}])
		_e_units.append(u)
		if not (u.get_node(^"LaneMarch") as LaneMarch).is_held():
			return _fail("WaveFormation.add_member did not hold the unit")
	_next("e")
	return false


func _tick_e() -> bool:
	if _t == 30:
		_wf.call(&"start_march")
		var rider := _e_units[1]
		if not rider.has_modifier(&"ws_lock") or absf(rider.get_stat(&"move_speed") - 5.0) > 0.01:
			return _fail("WaveFormation march: rider at %.2f (want 5.0, ws_lock)" % rider.get_stat(&"move_speed"))
	if _t == 90:
		_e_units[2].take_damage(5.0, null)
	if _t > 90 and bool(_wf.call(&"is_released")):
		for u in _e_units:
			var lm := u.get_node(^"LaneMarch") as LaneMarch
			if not lm.is_released() or u.has_modifier(&"ws_lock") or lm.effects_applied != 1 or u.shield < 149.0:
				return _fail("WaveFormation release: %s released %s, lock %s, effects %d, shield %.0f" % [
						u.name, lm.is_released(), u.has_modifier(&"ws_lock"), lm.effects_applied, u.shield])
		_log.append("E WaveFormation: hold / lock / hit release / shield OK (reason %s)" % str(_wf.get(&"release_reason")))
		return _report()
	if _t > 150:
		return _fail("WaveFormation: a hit did not release")
	return false


func _report() -> bool:
	var lm: Script = load("res://scripts/units/lane_march.gd") as Script
	var stalls := int(lm.get(&"stall_events"))
	for line in _log:
		print("  " + line)
	print("%s: stalls %d (longest %.1f s)" % [TASK_ID, stalls, float(lm.get(&"longest_stall"))])
	if stalls > 0:
		return _fail("%d stall events" % stalls)
	print("PASS %s" % TASK_ID)
	_done = true
	return true


func _fail(why: String) -> bool:
	for line in _log:
		print("  " + line)
	print("FAIL %s: %s" % [TASK_ID, why])
	_done = true
	return true
