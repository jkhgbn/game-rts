extends SceneTree
## Code-review fixes on five unit models (2026-10-02):
##  (a) Nightblood Reaver: an auto-attack replacing a running cast resets the glow flare (no cast_end fires).
##  (b) Shardguard: settled braced idle takes the fast idle path (no full write every frame) and keeps the stance.
##  (c) Ashveil Saboteur / Stormbottle Genie: revive at tier 2 leaves the loop particles off.
##  (d) Glade Outrider rider: revive clears the aim target and the head look.
##  (e) Stormbottle Genie: the bolt hides when the unit dies mid-attack; fly_height is the FLY_HEIGHT const.
## Run: godot --headless --path . -s tests/test_unit_review_fixes.gd --fixed-fps 60 --quit-after 6000
## Prints "PASS unit_review_fixes" or "FAIL unit_review_fixes: <reasons>".

const TASK_ID := "unit_review_fixes"
const REAVER := "res://art/units/shadow/nightblood_reaver/nightblood_reaver.tscn"
const SHARDGUARD := "res://art/units/ice/shardguard/shardguard.tscn"
const ASHVEIL := "res://art/units/fire/ashveil_saboteur/ashveil_saboteur.tscn"
const GENIE := "res://art/units/neutral/stormbottle_genie/stormbottle_genie.tscn"
const OUTRIDER := "res://art/units/nature/glade_outrider/glade_outrider.tscn"

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var cam := Camera3D.new()   # close camera: tier 0, full animation
	cam.position = Vector3(0, 6, 10)
	_world.add_child(cam)
	cam.look_at_from_position(cam.position, Vector3.ZERO)
	cam.make_current()
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _wait(sec: float) -> void:
	for i: int in int(ceil(sec * 60.0)):
		await process_frame


func _spawn(path: String, at: Vector3) -> Node3D:
	var m: Node3D = (load(path) as PackedScene).instantiate()
	m.position = at
	_world.add_child(m)
	return m


func _run() -> void:
	await _test_reaver()
	await _test_shardguard()
	await _test_revive_tier2(ASHVEIL, &"_sparks_fuse", "ashveil")
	await _test_revive_tier2(GENIE, &"_lip_sparks", "genie")
	await _test_genie_bolt()
	await _test_outrider()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


# (a) cast -> attack mid-cast -> the flare goes back to rest.
func _test_reaver() -> void:
	var m := _spawn(REAVER, Vector3(0, 0, 0))
	await _wait(0.3)
	var base := float(m.call(&"glow_level"))
	m.call(&"play_cast", &"blood_drink")
	await _wait(0.5)
	var mid := float(m.get(&"_flare"))
	print("reaver: flare mid-cast %.2f" % mid)
	_check(mid > 0.5, "reaver: the cast flares the glow (%.2f)" % mid)
	m.call(&"play_attack")
	await _wait(3.0)
	var after := float(m.get(&"_flare"))
	var glow := float(m.call(&"glow_level"))
	print("reaver: flare 3 s after the attack %.2f, glow %.3f (rest %.3f)" % [after, glow, base])
	_check(after == 0.0, "reaver: flare back to 0 after an attack replaced the cast (%.2f)" % after)
	_check(is_equal_approx(glow, base), "reaver: glow back at rest (%.3f vs %.3f)" % [glow, base])
	m.queue_free()
	await _wait(0.05)


# (b) braced settled -> fast path (no forced write), the stance offsets stay on the pivots; unbraced -> back to rest.
func _test_shardguard() -> void:
	var m := _spawn(SHARDGUARD, Vector3(3, 0, 0))
	m.set(&"fidget_every", 0.0)
	await _wait(0.5)
	var arm_r := m.get_node("Root/Chest/ArmR") as Node3D
	var leg_l := m.get_node("Root/Hips/LegL") as Node3D
	var rest_arm := arm_r.rotation.x
	var rest_leg := leg_l.rotation.x
	m.call(&"set_braced", true)
	await _wait(1.0)
	var forced := 0
	var arm_min := 99.0
	var arm_max := -99.0
	for i: int in 60:
		await process_frame
		if bool(m.get(&"_force_write")):
			forced += 1
		arm_min = minf(arm_min, arm_r.rotation.x)
		arm_max = maxf(arm_max, arm_r.rotation.x)
	var d_arm := rad_to_deg(arm_r.rotation.x - rest_arm)
	var d_leg := rad_to_deg(leg_l.rotation.x - rest_leg)
	print("shardguard braced: forced writes %d / 60, arm +%.1f deg (jitter %.2f), leg %.1f deg" % [forced, d_arm,
		rad_to_deg(arm_max - arm_min), d_leg])
	_check(float(m.get(&"_brace_w")) == 1.0, "shardguard: brace settled")
	_check(forced == 0, "shardguard: no forced full write while settled braced (%d)" % forced)
	_check(absf(d_arm - 18.0) < 0.5, "shardguard: braced arm stays at +18 deg on the fast path (%.1f)" % d_arm)
	_check(absf(d_leg + 16.0) < 0.5, "shardguard: braced leg stays at -16 deg (%.1f)" % d_leg)
	_check(arm_max - arm_min < 0.001, "shardguard: offsets do not pile up on the fast path")
	m.call(&"set_braced", false)
	await _wait(1.0)
	var back := rad_to_deg(arm_r.rotation.x - rest_arm)
	print("shardguard unbraced: arm %.2f deg from rest" % back)
	_check(absf(back) < 0.05, "shardguard: unbraced arm back at rest (%.2f)" % back)
	m.queue_free()
	await _wait(0.05)


# (c) revive while at tier 2 (far) keeps the loop particles off.
func _test_revive_tier2(path: String, prop: StringName, label: String) -> void:
	var m := _spawn(path, Vector3(-3, 0, 0))
	await _wait(0.3)
	m.call(&"play_death")
	await _wait(1.6)
	var p := m.get(prop) as GPUParticles3D
	_check(p != null, "%s: particles %s exist" % [label, prop])
	m.set(&"_tier", 2)
	m.call(&"revive")
	if p:
		_check(not p.emitting, "%s: revive at tier 2 leaves %s off" % [label, prop])
	m.set(&"_tier", 0)
	m.call(&"play_death")
	await _wait(1.6)
	m.call(&"revive")
	if p:
		_check(p.emitting, "%s: revive at tier 0 turns %s on" % [label, prop])
	m.queue_free()
	await _wait(0.05)


# (e) the bolt hides when the genie dies between the release (0.15 s) and the bolt-off (0.32 s).
func _test_genie_bolt() -> void:
	var m := _spawn(GENIE, Vector3(-6, 0, 0))
	await _wait(0.3)
	_check(is_equal_approx(float(m.get(&"fly_height")), 0.22), "genie: fly_height reads FLY_HEIGHT 0.22")
	m.set(&"fly_height", 3.0)
	_check(is_equal_approx(float(m.get(&"fly_height")), 0.22), "genie: fly_height is read-only")
	var bolt := m.get(&"_bolt") as Node3D
	m.call(&"play_attack")
	await _wait(0.2)
	var shown := bolt.visible
	m.call(&"play_death")
	await _wait(0.1)
	print("genie: bolt at 0.2 s %s, after death %s" % [shown, bolt.visible])
	_check(shown, "genie: the bolt shows at 0.2 s into the attack")
	_check(not bolt.visible, "genie: the bolt hides when the genie dies mid-attack")
	await _wait(0.6)
	_check(not bolt.visible, "genie: the bolt stays hidden through the death")
	m.queue_free()
	await _wait(0.05)


# (d) revive clears the rider's aim (target, phi, head look).
func _test_outrider() -> void:
	var a := _spawn(OUTRIDER, Vector3(0, 0, -6))
	await _wait(0.3)
	var rider: Node3D = a.call(&"rider_model")
	var tgt := Node3D.new()
	_world.add_child(tgt)
	tgt.global_position = Vector3(8, 0, -6)
	a.call(&"set_aim_target", tgt)
	await _wait(1.0)
	_check(bool(rider.get(&"_phi_valid")) and float(rider.get(&"_look_w")) > 0.5, "outrider: aiming before death")
	a.call(&"play_death")
	await _wait(1.5)
	a.call(&"revive")
	var mode := int(rider.get(&"_aim_mode"))
	var node: Variant = rider.get(&"_aim_node")
	var valid := bool(rider.get(&"_phi_valid"))
	var look := float(rider.get(&"_look_w"))
	var pt := rider.get(&"_aim_point") as Vector3
	print("outrider revive: mode %d, node %s, phi_valid %s, look %.2f" % [mode, node, valid, look])
	_check(mode == 0 and node == null and not valid and look == 0.0 and pt == Vector3.ZERO,
		"outrider: revive clears the aim (mode %d, valid %s, look %.2f)" % [mode, valid, look])
	await _wait(0.5)
	_check(float(rider.get(&"_look_w")) == 0.0, "outrider: no head look after revive")
	a.queue_free()
	tgt.queue_free()
	await _wait(0.05)
