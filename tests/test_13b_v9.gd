extends SceneTree
## Task 13b.V9: Nature tier-3 effects (art/vfx/unit_nature_t3_vfx.gd, a family of UnitVfx art/vfx/unit_vfx.gd).
## Run:  $GODOT --headless --path . -s tests/test_13b_v9.gd --fixed-fps 60 --quit-after 1400
## Stand-in units (a tiny Node3D script built here: team, body_height, radius, is_alive, attack_target, get_model), the
## real Glade Outrider (13b.V3) and Mossback (13b.V4) models under two of them (group "units"), a stand-in building and
## a stand-in FogOfWar (group "fog": the local team 0 sees x < 100).
## Checks:
##  - UnitVfx joins group "unit_vfx", loads the family, knows the 4 ids; unknown ids / no position do nothing; the
##    family's own play() returns true for its ids and false for others;
##  - each id starts an effect with a target AND without one; parting_shot takes a Vector3, the Outrider unit, its
##    model (get_arrow_origin()), a Dictionary {dir, range}, a Vector3 target point;
##  - the arrow flies the Projectile arc (above the straight line mid-flight), tracks a moving victim, lands in time
##    (dist / 25 m/s) and is gone; a second parting_shot for the same Outrider in the same frame is dropped;
##  - auto-attach: the Outrider model's play_attack() -> arrow_released -> an arrow toward the unit's attack_target, and
##    a gameplay parting_shot for that loose is dropped; the Mossback with its canopy spread pulses by itself every
##    4 s (3 pulses in 9 s), a canopy_pulse call in between is throttled, {force: true} is not; canopy off = no pulse;
##  - canopy_block on a node lands on the side facing the shooter; kite_dust follows its runner;
##  - fog: an enemy effect in the fog is hidden, an own one there shows;
##  - no node, material or mesh is created after _ready, even with 30 shots + 20 kite puffs + 12 pulses + 60 blocks in
##    one frame; 4.5 s later nothing is left (no burst, no piece, every pool full again);
##  - 0 lights; every burst emitter has visibility_range_end 45; bursts farther than 45 m from the camera never start.
## Prints PASS 13b_v9 / FAIL 13b_v9: <reason>.

const TASK_ID := "13b_v9"
const HUB_PATH := "res://art/vfx/unit_vfx.gd"
const FAMILY_PATH := "res://art/vfx/unit_nature_t3_vfx.gd"
const OUTRIDER := "res://art/units/nature/glade_outrider/glade_outrider.tscn"
const MOSSBACK := "res://art/units/nature/mossback/mossback.tscn"
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar body_height: float = 1.8\nvar radius: float = 0.45\nvar alive: bool = true\nvar attack_target: Node3D = null\nvar unit_type: Resource = null\nfunc is_alive() -> bool:\n\treturn alive\nfunc get_model() -> Node3D:\n\treturn get_child(0) as Node3D if get_child_count() > 0 else null\n"
const BUILDING_SRC := "extends Node3D\nvar team: int = 1\nvar building_type: Resource = null\nfunc _ready() -> void:\n\tadd_to_group(&\"buildings\")\nfunc target_radius() -> float:\n\treturn 3.0\n"
const FOG_SRC := "extends Node\nvar enabled: bool = true\nvar local_team: int = 0\nfunc _ready() -> void:\n\tadd_to_group(&\"fog\")\nfunc is_visible(_team: int, pos: Vector3) -> bool:\n\treturn pos.x < 100.0\n"
const IDS: Array[StringName] = [&"parting_shot", &"kite_dust", &"canopy_pulse", &"canopy_block"]

var world: Node3D
var hub: Node3D
var fam: Node3D
var solo: Node3D
var stub: GDScript
var outrider: Node3D          # stand-in unit with the real Outrider model
var omodel: Node3D
var mossback: Node3D          # stand-in unit with the real Mossback model
var mmodel: Node3D
var victim: Node3D
var enemy: Node3D
var mover: Node3D
var runner: Node3D
var keep: Node3D
var cam: Camera3D
var frame := 0
var fails: PackedStringArray = []
var children_before := 0
var mats_before: Dictionary = {}
var pulses := 0
var last_pulse_t := -1.0
var pulses_at_off := -1
var auto_fired := false
var auto_before := 0
var dedupe_ok := false
var solo_heads: Array[Vector3] = []
const T0 := 3                      # the frame every first effect starts
const CANOPY_OFF := 560            # 9.3 s
const STRESS := 910


func _initialize() -> void:
	world = Node3D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world
	stub = _script(STUB_SRC)


func _script(src: String) -> GDScript:
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	return s


func _process(_delta: float) -> bool:
	frame += 1
	if frame >= T0 and fam and mmodel and frame < STRESS:
		_count_pulses()
	match frame:
		2:
			_setup()
		T0:
			_play_all()
		T0 + 6:
			mover.global_position += Vector3(0.0, 0.0, 4.0)
			runner.global_position += Vector3(2.0, 0.0, 0.0)
		T0 + 8:
			_follow_check()
		T0 + 12:   # 0.2 s: the solo arrow is mid-flight (10 m at 25 m/s = 0.4 s)
			_mid_flight_check()
		T0 + 21:   # 0.35 s: the tracking arrow is near the moved victim
			_tracking_check()
		33:
			_fog_checks()
			if int(solo.call(&"arrow_count")) != 0:
				_fail("solo arrows still flying at 0.5 s (%d)" % solo.call(&"arrow_count"))
		40:
			auto_before = int(fam.call(&"arrow_count"))
			omodel.connect(&"arrow_released", _on_auto_arrow)   # after the family's own connection (its scan)
			omodel.call(&"play_attack")
		60:
			if not auto_fired:
				_fail("the Outrider model never emitted arrow_released")
			elif not dedupe_ok:
				_fail("a gameplay parting_shot for the same loose was not dropped")
		CANOPY_OFF:
			if pulses != 3:
				_fail("the Mossback pulsed %d times in 9.2 s (want 3: every 4 s)" % pulses)
			pulses_at_off = pulses
			mmodel.call(&"set_canopy", false)
		STRESS - 10:
			if pulses != pulses_at_off:
				_fail("the Mossback kept pulsing with its canopy folded")
		STRESS:
			_stress()
		STRESS + 270:   # 4.5 s after the stress
			_final_checks()
			print("PASS %s" % TASK_ID if fails.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
			return true
	return false


func _setup() -> void:
	var fog := Node.new()
	fog.set_script(_script(FOG_SRC))
	world.add_child(fog)
	cam = Camera3D.new()
	world.add_child(cam)
	cam.global_position = Vector3(0.0, 25.0, 25.0)
	cam.look_at(Vector3.ZERO)
	cam.make_current()
	victim = _unit(1, Vector3(4.0, 0.0, -2.0))
	enemy = _unit(1, Vector3(-6.0, 0.0, -4.0))
	mover = _unit(1, Vector3(10.0, 0.0, 0.0))
	runner = _unit(0, Vector3(-4.0, 0.0, 6.0))
	keep = Node3D.new()
	keep.set_script(_script(BUILDING_SRC))
	world.add_child(keep)
	keep.global_position = Vector3(8.0, 0.0, 6.0)
	# The real models, under stand-in units in group "units" (auto-attach).
	outrider = _unit(0, Vector3(-3.0, 0.0, 2.0))
	outrider.set(&"attack_target", victim)
	outrider.add_to_group(&"units")
	if ResourceLoader.exists(OUTRIDER):
		omodel = (load(OUTRIDER) as PackedScene).instantiate() as Node3D
		outrider.add_child(omodel)
		if not omodel.has_signal(&"arrow_released") or not omodel.has_method(&"get_arrow_origin"):
			_fail("Outrider model has no arrow_released / get_arrow_origin()")
	else:
		_fail("missing %s" % OUTRIDER)
	mossback = _unit(0, Vector3(-10.0, 0.0, -8.0))
	mossback.add_to_group(&"units")
	if ResourceLoader.exists(MOSSBACK):
		mmodel = (load(MOSSBACK) as PackedScene).instantiate() as Node3D
		mmodel.call(&"set_canopy", true, true)
		mossback.add_child(mmodel)
		if not mmodel.has_method(&"get_canopy_points"):
			_fail("Mossback model has no get_canopy_points()")
	else:
		_fail("missing %s" % MOSSBACK)
	hub = (load(HUB_PATH) as GDScript).new()
	hub.name = "UnitVfx"
	world.add_child(hub)
	if get_first_node_in_group(&"unit_vfx") != hub:
		_fail("UnitVfx is not in group unit_vfx")
	for id in IDS:
		if not bool(hub.call(&"has_effect", id)):
			_fail("UnitVfx does not know %s" % id)
	for f: Node in hub.call(&"families"):
		if f.get_script() and (f.get_script() as Script).resource_path == FAMILY_PATH:
			fam = f
	if fam == null:
		_fail("UnitVfx did not load %s" % FAMILY_PATH)
		fam = (load(FAMILY_PATH) as GDScript).new()
		world.add_child(fam)
	solo = (load(FAMILY_PATH) as GDScript).new()
	solo.set(&"auto_attach", false)
	world.add_child(solo)
	children_before = fam.get_child_count()
	mats_before = _materials(fam)
	for c in fam.get_children():
		if c is Light3D:
			_fail("a light in the family (%s)" % c.name)
		if c is GPUParticles3D and absf((c as GPUParticles3D).visibility_range_end - 45.0) > 0.01:
			_fail("burst %s has visibility_range_end %.1f (want 45)" % [c.name, (c as GPUParticles3D).visibility_range_end])


func _unit(team: int, pos: Vector3) -> Node3D:
	var u := Node3D.new()
	u.set_script(stub)
	u.set(&"team", team)
	world.add_child(u)
	u.global_position = pos
	return u


func _play_all() -> void:
	if int(fam.call(&"attached_canopy_count")) != 1:
		_fail("the Mossback model was not auto-attached (%d)" % fam.call(&"attached_canopy_count"))
	# Unknown id / nothing to place: nothing starts.
	var n0: int = fam.call(&"active_count")
	hub.call(&"play", &"not_a_nature_effect", Vector3.ZERO, victim)
	for id in IDS:
		hub.call(&"play", id, null, null)
	if int(fam.call(&"active_count")) != n0:
		_fail("unknown id / no position started an effect")
	if bool(solo.call(&"play", &"musket_shot", Vector3.ZERO, null)) or not bool(solo.call(&"handles", &"canopy_block")):
		_fail("family play / handles answer wrong")
	# Every id with a target and without (spread out so the parting_shot dedupe does not merge them).
	var k := 0
	for id in IDS:
		var target: Variant = victim
		if id == &"canopy_pulse":
			target = 6.0
		var p := Vector3(1.0 + 3.0 * float(k), 1.5 if id == &"parting_shot" else 0.0, 10.0)
		var q := Vector3(-2.0 - 3.0 * float(k), 1.5 if id == &"parting_shot" else 0.0, 13.0)
		_expect_start(id, p, target, "%s with a target" % id)
		_expect_start(id, q, null, "%s without a target" % id)
		k += 1
	# parting_shot forms.
	_expect_start(&"parting_shot", Vector3(20.0, 2.0, 0.0), Vector3(28.0, 1.0, 3.0), "parting_shot at a point")
	_expect_start(&"parting_shot", Vector3(30.0, 2.0, 0.0), {"dir": Vector3(1, 0, 0), "range": 8.0},
			"parting_shot with {dir, range}")
	_expect_start(&"parting_shot", Vector3(40.0, 2.0, 0.0), keep, "parting_shot at a building")
	if omodel:
		_expect_start(&"parting_shot", omodel, victim, "parting_shot with the Outrider model")
	# Same Outrider, same frame: the second call is dropped.
	var before: int = fam.call(&"active_count")
	hub.call(&"play", &"parting_shot", outrider, victim)
	hub.call(&"play", &"parting_shot", outrider, victim)
	if int(fam.call(&"active_count")) != before:
		_fail("parting_shot for the Outrider unit right after its model's shot was not dropped (%d -> %d)"
				% [before, fam.call(&"active_count")])
	# The solo family: one arrow from (0, 2, 0) to a victim 10 m away, one to the mover (tracked).
	solo.call(&"play", &"parting_shot", Vector3(0.0, 1.0, 0.0), mover)
	solo.call(&"play", &"parting_shot", Vector3(0.0, 1.0, 20.0), Vector3(10.0, 1.0, 20.0))
	if int(solo.call(&"arrow_count")) != 2:
		_fail("solo: %d arrows in flight (want 2)" % solo.call(&"arrow_count"))
	# canopy_pulse with the Mossback unit on the solo family (no auto pulses there): its 3 crowns glow; a second call
	# is throttled, a forced one is not.
	var fl0 := _visible_in_pool(solo, &"flare")
	var s0: int = solo.call(&"active_count")
	solo.call(&"play", &"canopy_pulse", mossback, null)
	solo.call(&"_process", 0.03)
	if int(solo.call(&"active_count")) <= s0:
		_fail("canopy_pulse on the Mossback unit started nothing")
	if _visible_in_pool(solo, &"flare") - fl0 < 3:
		_fail("canopy_pulse on the Mossback lit %d crown flares (want 3)" % (_visible_in_pool(solo, &"flare") - fl0))
	s0 = solo.call(&"active_count")
	solo.call(&"play", &"canopy_pulse", mossback, 6.0)
	solo.call(&"play", &"canopy_pulse", mmodel, null)
	if int(solo.call(&"active_count")) != s0:
		_fail("canopy_pulse right after another on the same Mossback was not throttled")
	solo.call(&"play", &"canopy_pulse", mmodel, {"force": true})
	if int(solo.call(&"active_count")) != s0 + 1:
		_fail("canopy_pulse {force: true} was throttled")
	# canopy_block on a node: the spark sits on the side facing the shooter.
	hub.call(&"play", &"canopy_block", victim, outrider)
	var fxs: Array = fam.get(&"_fx")
	var bp: Vector3 = (fxs[fxs.size() - 1] as Object).get(&"point")
	var vflat := Vector2(victim.global_position.x, victim.global_position.z)
	var sflat := Vector2(outrider.global_position.x, outrider.global_position.z)
	if Vector2(bp.x, bp.z).distance_to(sflat) >= vflat.distance_to(sflat) - 0.2:
		_fail("canopy_block not on the shooter's side of the victim (%s)" % bp)
	# kite_dust on a runner (followed).
	_expect_start(&"kite_dust", runner, enemy, "kite_dust on a runner")
	# Fog: an enemy effect where team 0 does not see, an own one there.
	hub.call(&"play", &"kite_dust", Vector3(150.0, 0.0, 0.0), null)            # team -1 (no node): hidden
	hub.call(&"play", &"canopy_pulse", Vector3(150.0, 0.0, 20.0), {"team": 0})
	hub.call(&"play", &"canopy_pulse", Vector3(150.0, 0.0, 40.0), {"team": 1})
	if fam.get_child_count() != children_before:
		_fail("nodes created at runtime (%d -> %d)" % [children_before, fam.get_child_count()])
	if _materials(fam) != mats_before:
		_fail("materials / meshes created at runtime")
	if int(fam.call(&"live_count")) == 0:
		_fail("nothing visible after playing every effect")


func _expect_start(id: StringName, at: Variant, target: Variant, what: String) -> void:
	var before: int = fam.call(&"active_count")
	hub.call(&"play", id, at, target)
	if int(fam.call(&"active_count")) <= before:
		_fail("%s started nothing" % what)


func _visible_in_pool(v: Node, pool: StringName) -> int:
	var n := 0
	for g: GeometryInstance3D in (v.get(&"_all") as Dictionary)[pool]:
		if g.visible:
			n += 1
	return n


func _follow_check() -> void:
	for f: Object in fam.get(&"_fx"):
		if f.get(&"id") == &"kite_dust" and f.get(&"follow") == runner:
			var p: Vector3 = f.get(&"point")
			if p.distance_to(runner.global_position) > 0.01:
				_fail("kite_dust does not follow its runner")
			return
	_fail("kite_dust on the runner not found")


func _mid_flight_check() -> void:
	var heads: PackedVector3Array = solo.call(&"arrow_heads")
	for h in heads:
		if absf(h.z - 20.0) < 0.5:
			# From (0, 1, 20) to (10, 1, 20): mid-flight it is between, above the straight line (the arc).
			if h.x < 2.5 or h.x > 8.5:
				_fail("arrow at 0.2 s is at x %.2f (want ~5)" % h.x)
			if h.y < 1.3:
				_fail("arrow at 0.2 s does not arc (y %.2f)" % h.y)
			return
	_fail("the point arrow is not in flight at 0.2 s")


func _tracking_check() -> void:
	var heads: PackedVector3Array = solo.call(&"arrow_heads")
	var want := mover.global_position + Vector3.UP
	for h in heads:
		if absf(h.z - 20.0) >= 0.5:
			if h.distance_to(want) > 2.5:
				_fail("the tracking arrow is %.2f m from its moved victim near landing" % h.distance_to(want))
			return
	# Already landed: fine if it landed on the moved victim (its fx target point).
	for f: Object in solo.get(&"_fx"):
		var ar: Object = f.get(&"arrow")
		if ar and absf((ar.get(&"from") as Vector3).z) < 0.5:
			if (ar.get(&"to") as Vector3).distance_to(want) > 0.3:
				_fail("the tracking arrow landed away from its moved victim")
			return


func _on_auto_arrow(_from: Vector3, _dir: Vector3) -> void:
	auto_fired = true
	# The family's own handler ran first (connected at its scan): one more arrow.
	if int(fam.call(&"arrow_count")) <= auto_before:
		_fail("arrow_released did not start an arrow (auto-attach)")
	var heads: PackedVector3Array = fam.call(&"arrow_heads")
	var near := false
	for h in heads:
		if h.distance_to(_from) < 0.6:
			near = true
	if not near:
		_fail("the auto arrow does not start at the signal's origin")
	var before: int = fam.call(&"active_count")
	hub.call(&"play", &"parting_shot", outrider, victim)          # what gameplay would also do for this loose
	hub.call(&"play", &"parting_shot", outrider.global_position + Vector3.UP * 1.95, victim)   # Unit._shot_origin
	dedupe_ok = int(fam.call(&"active_count")) == before


func _count_pulses() -> void:
	var lp: Dictionary = fam.get(&"_last_pulse")
	var key := mmodel.get_instance_id()
	if lp.has(key) and float(lp[key]) != last_pulse_t:
		last_pulse_t = float(lp[key])
		pulses += 1


func _fog_checks() -> void:
	var seen := 0
	for f: Object in fam.get(&"_fx"):
		var p: Vector3 = f.get(&"point")
		if p.x < 100.0:
			continue
		seen += 1
		var team := int(f.get(&"team"))
		if team == 0 and not bool(f.get(&"shown")):
			_fail("own %s in the fog is hidden" % f.get(&"id"))
		if team != 0 and bool(f.get(&"shown")):
			_fail("enemy %s in the fog is shown" % f.get(&"id"))
	if seen < 3:
		_fail("fog test effects missing (%d)" % seen)


## A burst 500 m away from the camera never starts.
func _far_check() -> void:
	var n := (fam.get(&"_live_bursts") as Array).size()
	fam.call(&"play", &"kite_dust", Vector3(500.0, 0.0, 500.0), null)
	fam.call(&"_process", 0.0)
	if (fam.get(&"_live_bursts") as Array).size() > n:
		_fail("a burst started 500 m from the camera")


## 30 shots, 20 kite puffs, 12 forced pulses, 60 blocks in one frame.
func _stress() -> void:
	_far_check()
	for i in 30:
		fam.call(&"play", &"parting_shot", Vector3(-15.0 + 2.0 * float(i), 2.0, 8.0), enemy)
	for i in 20:
		fam.call(&"play", &"kite_dust", Vector3(-10.0 + float(i), 0.0, 4.0), enemy)
	for i in 12:
		fam.call(&"play", &"canopy_pulse", Vector3(-12.0 + 2.0 * float(i), 0.0, -8.0), {"force": true})
	for i in 60:
		fam.call(&"play", &"canopy_block", Vector3(-10.0 + 0.3 * float(i), 1.0, -6.0), enemy)
	if fam.get_child_count() != children_before or _materials(fam) != mats_before:
		_fail("nodes / materials created in the stress (pools ran out)")
	var a := Time.get_ticks_usec()
	fam.call(&"_process", 1.0 / 60.0)
	print("  UnitNatureT3Vfx _process right after the stress: %d us, running %d" % [Time.get_ticks_usec() - a,
			fam.call(&"active_count")])


func _final_checks() -> void:
	for v: Node3D in [fam, solo]:
		if int(v.call(&"live_count")) != 0:
			_fail("%s: %d pieces / bursts still alive at the end" % [v.name, v.call(&"live_count")])
		if int(v.call(&"active_count")) != 0:
			_fail("%s: effects still running at the end (%s)" % [v.name, v.call(&"active_ids")])
		for c in v.get_children():
			if (c is GPUParticles3D or c is MeshInstance3D or c is MultiMeshInstance3D) and (c as Node3D).visible:
				_fail("%s still visible at the end" % c.name)
				break
		var free: Dictionary = v.get(&"_free")
		var sizes: Dictionary = v.get(&"POOL_SIZES")
		for pool: StringName in sizes:
			if (free[pool] as Array).size() != int(sizes[pool]):
				_fail("%s: pool %s has %d free of %d (leak)" % [v.name, pool, (free[pool] as Array).size(), sizes[pool]])
	if fam.get_child_count() != children_before:
		_fail("nodes created during the run")
	if _materials(fam) != mats_before:
		_fail("materials created during the run")


## Instance ids of every material, mesh and process material the pools use.
func _materials(v: Node) -> Dictionary:
	var out: Dictionary = {}
	for c in v.get_children():
		if c is MeshInstance3D:
			out[(c as MeshInstance3D).material_override.get_instance_id()] = true
			out[(c as MeshInstance3D).mesh.get_instance_id()] = true
		elif c is GPUParticles3D:
			var p := c as GPUParticles3D
			out[p.process_material.get_instance_id()] = true
			out[p.draw_pass_1.get_instance_id()] = true
			out[(p.draw_pass_1 as PrimitiveMesh).material.get_instance_id()] = true
	return out


func _fail(why: String) -> void:
	fails.append(why)
	print("  fail: ", why)
