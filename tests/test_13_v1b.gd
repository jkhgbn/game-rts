extends SceneTree
## Task 13.V1b: the seated rider in the shared CharacterModel kit (art/units/kit/character_model.gd), on the Rimehorn
## (art/units/mounts/rimehorn/). Riders: a wizard (Torvald), a champion (Oathwall), a soldier (Rimeshield).
## Run: $GODOT --headless --path . -s tests/test_13_v1b.gd --fixed-fps 60 --quit-after 6000
## Checks: hooks / signal / exports; unseated models unchanged (defaults, set_seated on+off restores everything); the
## hips sit on the live Seat with no frame lag (rider added BEFORE its mount) standing, walking, galloping; legs
## astride (splay measured, clears the barrel); walk off while seated; the rider bob (hips + chest follow the gait);
## seat_offset; play_mount / play_dismount (0.3 s, left flank, lands on its origin, dismount_finished once, priority /
## blob restored); play_thrown (0.5 s tumble, lands, gets up); death seated on a living mount (thrown, stays down) and
## on a dying mount (rides the fall); revive -> on foot; an attack from the saddle (root motion damped, ends); pending
## calls before _ready; the mount freed while seated; far-camera tiers (rider freezes with its mount); no nodes added.
## Prints "PASS 13.v1b" or "FAIL 13.v1b: <reasons>".

const TASK_ID := "13.v1b"
const MOUNT := "res://art/units/mounts/rimehorn/rimehorn.tscn"
const RIDERS: Dictionary = {
	"wizard": "res://art/units/wizards/torvald.tscn",
	"champion": "res://art/units/champions/oathwall/oathwall.tscn",
	"soldier": "res://art/units/ice/rimeshield.tscn",
}
const DEG := PI / 180.0

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D
var _cam: Camera3D
var _landed: Dictionary = {}   # rider instance id -> dismount_finished count


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_cam = Camera3D.new()   # close: tier 0, the full animation runs
	_world.add_child(_cam)
	_cam.look_at_from_position(Vector3(0, 8, 12), Vector3.ZERO)
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _wait(sec: float) -> void:
	await _frames(int(ceil(sec * 60.0)))


## A unit-like holder with the rider added FIRST and the mount second (the rider must still read the seat after the
## mount posed it).
func _pair(at: Vector3, rider_path: String, seat: bool = true) -> Array:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation.y = 0.4
	_world.add_child(holder)
	var r: Node3D = (load(rider_path) as PackedScene).instantiate()
	var m: Node3D = (load(MOUNT) as PackedScene).instantiate()
	m.set(&"fidget_every", 0.0)
	holder.add_child(r)
	holder.add_child(m)
	_landed[r.get_instance_id()] = 0
	r.connect(&"dismount_finished", func() -> void: _landed[r.get_instance_id()] += 1)
	if seat:
		r.call(&"set_seated", true, m)
	return [r, m]


func _hips(r: Node3D) -> Node3D:
	return r.get_node(^"Root/Hips") as Node3D


func _seat(m: Node3D) -> Node3D:
	return m.get_node(^"Root/Mount/Seat") as Node3D


func _hip_err(r: Node3D, m: Node3D) -> float:
	return _hips(r).global_position.distance_to(_seat(m).global_position)


func _root(r: Node3D) -> Node3D:
	return r.get_node(^"Root") as Node3D


func _run() -> void:
	await _frames(2)
	# ---------------------------------------------------------------- hooks, defaults
	var solo: Node3D = (load(RIDERS["soldier"]) as PackedScene).instantiate()
	var solo_h := Node3D.new()
	solo_h.position = Vector3(-12, 0, 0)
	_world.add_child(solo_h)
	solo_h.add_child(solo)
	_landed[solo.get_instance_id()] = 0
	solo.connect(&"dismount_finished", func() -> void: _landed[solo.get_instance_id()] += 1)
	await _frames(3)
	for h: String in ["set_seated", "is_seated", "seat_mount", "seat_action", "play_mount", "play_dismount", "play_thrown"]:
		_check(solo.has_method(h), "hook %s" % h)
	_check(solo.has_signal(&"dismount_finished"), "signal dismount_finished")
	for p: String in ["seat_offset", "seat_leg_splay_deg", "seat_leg_forward_deg"]:
		_check(p in solo, "export %s" % p)
	_check(not bool(solo.call(&"is_seated")) and solo.call(&"seat_mount") == null, "unseated by default")
	_check(solo.process_priority == 0 and int(solo.get(&"_par_id")) == solo.get_instance_id(), "default priority / parity")
	var nodes_before: int = solo.find_children("*", "", true, false).size()
	# unseated calls are no-ops
	solo.call(&"play_mount")
	solo.call(&"play_dismount")
	solo.call(&"play_thrown")
	await _frames(2)
	_check(StringName(solo.call(&"seat_action")) == &"" and not bool(solo.call(&"is_seated")), "hops are no-ops when not seated")
	# unseated walk still swings the legs (the kit walk untouched)
	solo.call(&"set_moving", 4.2)
	var leg_max := 0.0
	for i: int in 40:
		await process_frame
		leg_max = maxf(leg_max, absf((solo.get_node(^"Root/Hips/LegL") as Node3D).rotation.x))
	solo.call(&"set_moving", 0.0)
	_check(leg_max > 15.0 * DEG, "unseated walk swings the legs (%.1f deg)" % (leg_max / DEG))

	# ---------------------------------------------------------------- three riders seated, standing
	var pairs: Dictionary = {}
	var x := -6.0
	for k: String in RIDERS:
		pairs[k] = _pair(Vector3(x, 0, 0), RIDERS[k])
		x += 6.0
	await _wait(0.5)
	for k: String in pairs:
		var r: Node3D = pairs[k][0]
		var m: Node3D = pairs[k][1]
		var worst := 0.0
		for i: int in 30:
			await process_frame
			worst = maxf(worst, _hip_err(r, m))
		var spl: float = float(r.get(&"_rd_splay"))
		var ll := (r.get_node(^"Root/Hips/LegL") as Node3D).rotation
		var lr := (r.get_node(^"Root/Hips/LegR") as Node3D).rotation
		print("%s: hip error standing %.4f m, splay %.1f deg, legL (%.0f, %.0f) legR (%.0f, %.0f)" % [k, worst, spl,
			ll.x / DEG, ll.z / DEG, lr.x / DEG, lr.z / DEG])
		_check(bool(r.call(&"is_seated")) and r.call(&"seat_mount") == m, "%s is_seated / seat_mount" % k)
		_check(worst < 0.01, "%s hips on the seat standing (%.4f m)" % [k, worst])
		_check(spl >= 12.0 and spl <= 50.0, "%s splay measured 12-50 (%.1f)" % [k, spl])
		_check(ll.z < -10.0 * DEG and lr.z > 10.0 * DEG and ll.x < -15.0 * DEG and lr.x < -15.0 * DEG, "%s legs astride" % k)
		_check(r.process_priority > m.process_priority, "%s processes after its mount" % k)
		var sh := r.get_node_or_null(^"Shadow") as Node3D
		_check(sh == null or not sh.visible, "%s blob hidden while seated" % k)
		_check(r.find_children("*", "", true, false).size() == _count_nodes(k), "%s seating adds no nodes" % k)
		_check(r.find_children("*", "Light3D", true, false).size() == _lights(k), "%s no light added" % k)

	# ---------------------------------------------------------------- walk + gallop: live seat, bob, no walk legs
	for speed: float in [1.7, 6.0]:
		for k: String in pairs:
			(pairs[k][1] as Node3D).call(&"set_moving", speed)
			(pairs[k][0] as Node3D).call(&"set_moving", speed)   # the unit still reports its speed: ignored
		await _wait(1.2)
		for k: String in pairs:
			var r: Node3D = pairs[k][0]
			var m: Node3D = pairs[k][1]
			var worst := 0.0
			var y_lo := 99.0
			var y_hi := -99.0
			var c_lo := 99.0
			var c_hi := -99.0
			var leg_lo := 99.0
			var leg_hi := -99.0
			for i: int in 60:
				await process_frame
				worst = maxf(worst, _hip_err(r, m))
				var hy := _hips(r).global_position.y
				y_lo = minf(y_lo, hy)
				y_hi = maxf(y_hi, hy)
				var cx := (r.get_node(^"Root/Chest") as Node3D).rotation.x
				c_lo = minf(c_lo, cx)
				c_hi = maxf(c_hi, cx)
				var lx := (r.get_node(^"Root/Hips/LegL") as Node3D).rotation.x
				leg_lo = minf(leg_lo, lx)
				leg_hi = maxf(leg_hi, lx)
			print("%s @%.1f: hip error %.4f, hips bob %.3f m, chest pitch range %.1f deg, leg range %.1f deg" % [k, speed,
				worst, y_hi - y_lo, (c_hi - c_lo) / DEG, (leg_hi - leg_lo) / DEG])
			_check(worst < 0.012, "%s hips follow the seat at %.1f m/s, no lag (%.4f)" % [k, speed, worst])
			_check(leg_hi - leg_lo < 14.0 * DEG, "%s no walk leg swing while seated at %.1f" % [k, speed])
			if speed > 5.0:
				_check(y_hi - y_lo > 0.03, "%s rider bob with the gallop (%.3f m)" % [k, y_hi - y_lo])
				_check(c_hi - c_lo > 4.0 * DEG, "%s chest rides the gallop (%.1f deg)" % [k, (c_hi - c_lo) / DEG])
	for k: String in pairs:
		(pairs[k][1] as Node3D).call(&"set_moving", 0.0)
		(pairs[k][0] as Node3D).call(&"set_moving", 0.0)
	await _wait(1.0)

	# ---------------------------------------------------------------- seat_offset
	var sol: Array = pairs["soldier"]
	var sr: Node3D = sol[0]
	var sm: Node3D = sol[1]
	sr.set(&"seat_offset", Vector3(0, 0.1, 0))
	await _frames(3)
	var up_d: float = _hips(sr).global_position.y - _seat(sm).global_position.y
	_check(absf(up_d - 0.1) < 0.02, "seat_offset raises the hips (%.3f)" % up_d)
	sr.set(&"seat_offset", Vector3.ZERO)

	# ---------------------------------------------------------------- attack from the saddle
	sr.call(&"play_attack")
	var aw := 0.0
	var arm_moved := 0.0
	var arm0: float = (sr.get_node(^"Root/Chest/ArmR") as Node3D).rotation.x
	for i: int in 36:
		await process_frame
		aw = maxf(aw, _hip_err(sr, sm))
		arm_moved = maxf(arm_moved, absf((sr.get_node(^"Root/Chest/ArmR") as Node3D).rotation.x - arm0))
	_check(aw < 0.16, "attack from the saddle keeps the hips near the seat (%.3f)" % aw)
	_check(arm_moved > 40.0 * DEG, "the attack swings the arm while seated")
	_check(StringName(sr.get(&"_action")) == &"", "the attack ends")
	await _wait(0.3)
	_check(_hip_err(sr, sm) < 0.01, "back on the seat after the attack")

	# ---------------------------------------------------------------- dismount
	var wiz: Array = pairs["wizard"]
	var wr: Node3D = wiz[0]
	var wm: Node3D = wiz[1]
	var prio_before: int = 0
	wr.call(&"play_dismount")
	_check(StringName(wr.call(&"seat_action")) == &"dismount", "dismount starts")
	var min_x := 99.0
	var hip_rest: Vector3 = (wr.get(&"_rest_pos") as PackedVector3Array)[1]
	for i: int in 19:
		await process_frame
		var lp: Vector3 = wr.to_local(_hips(wr).global_position)
		min_x = minf(min_x, lp.x)
	_check(not bool(wr.call(&"is_seated")), "unseated after the 0.3 s hop-off")
	_check(int(_landed[wr.get_instance_id()]) == 1, "dismount_finished once (%d)" % int(_landed[wr.get_instance_id()]))
	_check(min_x < -0.2, "hops off over the left flank (x %.2f)" % min_x)
	await _frames(12)
	_check(_root(wr).position.length() < 0.03 and _root(wr).rotation.length() < 2.0 * DEG, "stands on its origin after the hop-off")
	_check(wr.to_local(_hips(wr).global_position).distance_to(hip_rest) < 0.05, "hips back at the standing height")
	_check(absf((wr.get_node(^"Root/Hips/LegL") as Node3D).rotation.z) < 2.0 * DEG, "legs back under the body")
	_check(wr.process_priority == prio_before and int(wr.get(&"_par_id")) == wr.get_instance_id(), "priority / parity restored")
	var wsh := wr.get_node_or_null(^"Shadow") as Node3D
	_check(wsh == null or wsh.visible, "blob visible again")
	_check(int(_landed[wr.get_instance_id()]) == 1, "no second dismount_finished")

	# ---------------------------------------------------------------- mount (hop-on)
	wr.call(&"set_seated", true, wm)
	wr.call(&"play_mount")
	await process_frame
	var y_start: float = wr.to_local(_hips(wr).global_position).y
	_check(y_start < hip_rest.y + 0.15, "hop-on starts from the standing pose (%.2f)" % y_start)
	min_x = 99.0
	var y_peak := -99.0
	for i: int in 17:
		await process_frame
		var lp: Vector3 = wr.to_local(_hips(wr).global_position)
		min_x = minf(min_x, lp.x)
		y_peak = maxf(y_peak, lp.y)
	_check(min_x < -0.15, "hops on from the left flank (x %.2f)" % min_x)
	_check(StringName(wr.call(&"seat_action")) == &"" and bool(wr.call(&"is_seated")), "hop-on done in 0.3 s")
	_check(_hip_err(wr, wm) < 0.01, "in the saddle after the hop-on (%.4f)" % _hip_err(wr, wm))

	# ---------------------------------------------------------------- thrown
	var ch: Array = pairs["champion"]
	var cr: Node3D = ch[0]
	var cm: Node3D = ch[1]
	cr.call(&"play_thrown")
	var tilt := 0.0
	var low := 99.0
	for i: int in 31:
		await process_frame
		var up: Vector3 = _root(cr).global_transform.basis.y.normalized()
		tilt = maxf(tilt, acos(clampf(up.dot(Vector3.UP), -1.0, 1.0)))
		low = minf(low, cr.to_local(_hips(cr).global_position).y)
	_check(tilt > 90.0 * DEG, "thrown: the body tumbles (%.0f deg)" % (tilt / DEG))
	_check(low < 0.5, "thrown: hits the ground (hips %.2f)" % low)
	_check(not bool(cr.call(&"is_seated")) and int(_landed[cr.get_instance_id()]) == 1, "thrown: back on its feet, unseated, dismount_finished")
	await _frames(12)
	_check(_root(cr).position.length() < 0.03 and _root(cr).rotation.length() < 2.0 * DEG, "thrown: stands upright on its origin")

	# ---------------------------------------------------------------- death seated on a living mount: thrown, stays down
	cr.call(&"set_seated", true, cm)
	await _wait(0.3)
	var died := [0]
	cr.connect(&"death_finished", func() -> void: died[0] += 1)
	cr.call(&"play_death")
	await _wait(0.7)
	_check(StringName(cr.call(&"seat_action")) == &"thrown", "dies seated -> thrown")
	_check(cr.to_local(_hips(cr).global_position).y < 0.6, "dead rider lies on the ground (%.2f)" % cr.to_local(_hips(cr).global_position).y)
	await _wait(0.5)
	_check(died[0] == 1, "death_finished after the thrown death")
	cr.call(&"revive")
	await _frames(6)
	_check(not bool(cr.call(&"is_seated")) and _root(cr).position.length() < 0.05, "revive -> on foot")

	# ---------------------------------------------------------------- mount and rider die together: rides the fall
	sr.call(&"play_hit")
	sm.call(&"play_death")
	sr.call(&"play_death")
	var fall_err := 0.0
	for i: int in 60:
		await process_frame
		fall_err = maxf(fall_err, _hip_err(sr, sm))
	_check(bool(sr.call(&"is_seated")) and StringName(sr.call(&"seat_action")) == &"", "rides the mount's fall")
	_check(fall_err < 0.02, "hips stay on the rolling seat (%.4f)" % fall_err)

	# ---------------------------------------------------------------- pending calls before _ready
	var ph := Node3D.new()
	ph.position = Vector3(0, 0, 8)
	_world.add_child(ph)
	var pm: Node3D = (load(MOUNT) as PackedScene).instantiate()
	var pr: Node3D = (load(RIDERS["soldier"]) as PackedScene).instantiate()
	pr.call(&"set_seated", true, pm)
	pr.call(&"play_mount")
	ph.add_child(pr)
	ph.add_child(pm)
	await process_frame
	_check(bool(pr.call(&"is_seated")) and StringName(pr.call(&"seat_action")) == &"mount", "set_seated + play_mount before _ready")
	await _wait(0.5)
	_check(_hip_err(pr, pm) < 0.01, "pending hop-on lands in the saddle (%.4f)" % _hip_err(pr, pm))

	# ---------------------------------------------------------------- far camera: the rider freezes with its mount
	pm.call(&"set_moving", 1.7)
	_cam.look_at_from_position(Vector3(0, 60, 60), Vector3.ZERO)
	await _wait(1.5)
	_check(bool(pm.get(&"_frozen")) and bool(pr.get(&"_frozen")), "beyond 45 m the rider freezes with its mount")
	_check(_hip_err(pr, pm) < 0.03, "frozen rider still on the frozen seat (%.4f)" % _hip_err(pr, pm))
	_cam.look_at_from_position(Vector3(0, 25, 35), Vector3.ZERO)   # ~37 m: tier 1, half rate
	await _wait(1.2)
	var t1 := 0.0
	for i: int in 40:
		await process_frame
		t1 = maxf(t1, _hip_err(pr, pm))
	_check(int(pr.get(&"_tier")) == int(pm.get(&"_tier")), "tier follows the mount")
	_check(t1 < 0.02, "tier-1 rider on the seat, same parity as its mount (%.4f)" % t1)
	_cam.look_at_from_position(Vector3(0, 8, 12), Vector3.ZERO)

	# ---------------------------------------------------------------- the mount freed while seated
	pm.queue_free()
	await _frames(3)
	_check(not bool(pr.call(&"is_seated")), "mount freed -> unseated")
	await _frames(5)
	_check(_root(pr).position.length() < 0.05, "stands after its mount vanished")

	# ---------------------------------------------------------------- the mount freed right after play_thrown: the tumble finishes
	var th := _pair(Vector3(-6, 0, 8), RIDERS["wizard"])
	var tr: Node3D = th[0]
	await _wait(0.3)
	tr.call(&"play_thrown")
	(th[1] as Node3D).queue_free()
	await _frames(10)
	_check(bool(tr.call(&"is_seated")) and StringName(tr.call(&"seat_action")) == &"thrown" and tr.call(&"seat_mount") == null,
		"thrown goes on after the mount is freed")
	await _wait(0.45)
	_check(not bool(tr.call(&"is_seated")) and int(_landed[tr.get_instance_id()]) == 1, "thrown lands without its mount")
	await _frames(6)
	_check(_root(tr).position.length() < 0.03, "stands after a mount-less thrown")

	# ---------------------------------------------------------------- set_seated on then off restores the defaults
	var sm2: Node3D = (load(MOUNT) as PackedScene).instantiate()
	solo_h.add_child(sm2)
	solo.call(&"set_seated", true, sm2)
	await _frames(4)
	solo.call(&"set_seated", false)
	await _frames(4)
	_check(solo.process_priority == 0 and int(solo.get(&"_par_id")) == solo.get_instance_id(), "set_seated(false) restores priority / parity")
	_check(_root(solo).position.length() < 0.03, "set_seated(false) stands at once")
	_check(solo.find_children("*", "", true, false).size() == nodes_before, "no nodes left behind")
	_check(int(_landed[solo.get_instance_id()]) == 0, "no dismount_finished for the instant unseat")

	# ---------------------------------------------------------------- info: the measured splay on the other mounts (not checked:
	# those scenes are still being built by other tasks)
	for mp: String in ["res://art/units/mounts/ember_boar/ember_boar.tscn", "res://art/units/mounts/dusk_steed/dusk_steed.tscn",
			"res://art/units/mounts/grove_stag/grove_stag.tscn"]:
		if not ResourceLoader.exists(mp):
			continue
		var oh := Node3D.new()
		oh.position = Vector3(12, 0, -8)
		_world.add_child(oh)
		var om: Node3D = (load(mp) as PackedScene).instantiate()
		if not om.has_method(&"seat_transform"):
			oh.queue_free()
			continue
		var orr: Node3D = (load(RIDERS["soldier"]) as PackedScene).instantiate()
		oh.add_child(orr)
		oh.add_child(om)
		orr.call(&"set_seated", true, om)
		await _frames(3)
		print("info: %s splay %.1f deg, hip error %.4f" % [mp.get_file(), float(orr.get(&"_rd_splay")), _hip_err(orr, om)])
		oh.queue_free()
		await _frames(1)

	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


var _node_counts: Dictionary = {}
var _light_counts: Dictionary = {}


## Node / light count of a fresh, unseated instance of the rider kind (for "seating adds nothing").
func _count_nodes(k: String) -> int:
	if not _node_counts.has(k):
		_fresh(k)
	return _node_counts[k]


func _lights(k: String) -> int:
	if not _light_counts.has(k):
		_fresh(k)
	return _light_counts[k]


func _fresh(k: String) -> void:
	var r: Node3D = (load(RIDERS[k]) as PackedScene).instantiate()
	var h := Node3D.new()
	h.position = Vector3(20, 0, 20)
	_world.add_child(h)
	h.add_child(r)
	_node_counts[k] = r.find_children("*", "", true, false).size()
	_light_counts[k] = r.find_children("*", "Light3D", true, false).size()
	h.queue_free()
