extends SceneTree
## Task 13b.V6: gunpowder effects (art/vfx/unit_fire_gun_vfx.gd, a family of UnitVfx art/vfx/unit_vfx.gd).
## Run:  $GODOT --headless --path . -s tests/test_13b_v6.gd --fixed-fps 60 --quit-after 900
## Stand-in units (a tiny Node3D script built here: team, body_height, radius, is_alive), a stand-in building (group
## "buildings", building_type) and a stand-in FogOfWar (group "fog": the local team 0 sees x < 100) replace the game's.
## Checks:
##  - UnitVfx joins group "unit_vfx", loads the family, knows the 5 ids; unknown ids / no position do nothing; the
##    family's own play() returns true for its ids and false for others;
##  - each id starts an effect with a target AND without one; musket_shot takes a Transform3D, a Vector3, a stand-in
##    unit and the real Cinderlock model (its get_muzzle_xf());
##  - no node, material or mesh is created after _ready, even with a 20-gun volley + 20 impacts + 10 breaches +
##    8 clouds per team in one frame; at most 6 clouds per team (the oldest replaced), 60 puffs per team MultiMesh;
##  - powder_smoke radius clamped to 2.5-4.0 (float / Dictionary / shooter node forms); an enemy cloud in the fog is
##    hidden (alpha 0) while an own cloud there shows;
##  - timings: at 1.0 s the shot / breach are over, impact / volley / smoke still run; at 1.6 s only the smoke; at 3.3 s
##    nothing (no cloud); 4.5 s after the stress nothing is left (no burst, no puff, every pool full again);
##  - 0 lights; every burst emitter has visibility_range_end 45; bursts farther than 45 m from the camera never start.
## Prints PASS 13b_v6 / FAIL 13b_v6: <reason>.

const TASK_ID := "13b_v6"
const HUB_PATH := "res://art/vfx/unit_vfx.gd"
const FAMILY_PATH := "res://art/vfx/unit_fire_gun_vfx.gd"
const CINDERLOCK := "res://art/units/fire/cinderlock/cinderlock.tscn"
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar body_height: float = 1.8\nvar radius: float = 0.45\nvar alive: bool = true\nfunc is_alive() -> bool:\n\treturn alive\n"
const BUILDING_SRC := "extends Node3D\nvar team: int = 1\nvar building_type: Resource = null\nfunc _ready() -> void:\n\tadd_to_group(&\"buildings\")\nfunc target_radius() -> float:\n\treturn 3.0\n"
const FOG_SRC := "extends Node\nvar enabled: bool = true\nvar local_team: int = 0\nfunc _ready() -> void:\n\tadd_to_group(&\"fog\")\nfunc is_visible(_team: int, pos: Vector3) -> bool:\n\treturn pos.x < 100.0\n"
const IDS: Array[StringName] = [&"musket_shot", &"powder_volley", &"powder_smoke", &"musket_impact", &"musket_breach"]

var world: Node3D
var hub: Node3D
var fam: Node3D
var solo: Node3D
var stub: GDScript
var shooter: Node3D
var victim: Node3D
var enemy: Node3D
var keep: Node3D
var model: Node3D
var cam: Camera3D
var frame := 0
var fails: PackedStringArray = []
var children_before := 0
var mats_before: Dictionary = {}
const T0 := 3                      # the frame every first effect starts


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
	match frame:
		2:
			_setup()
		T0:
			_play_all()
		33:
			_fog_checks()
		63:   # 1.0 s
			var ids: Array = fam.call(&"active_ids")
			for id: StringName in [&"musket_shot", &"musket_breach"]:
				if ids.has(id):
					_fail("%s still running at 1.0 s" % id)
			for id: StringName in [&"musket_impact", &"powder_volley", &"powder_smoke"]:
				if not ids.has(id):
					_fail("%s already over at 1.0 s" % id)
		99:   # 1.6 s
			var ids2: Array = fam.call(&"active_ids")
			for id: StringName in [&"musket_impact", &"powder_volley"]:
				if ids2.has(id):
					_fail("%s still running at 1.6 s" % id)
			if not ids2.has(&"powder_smoke") or int(fam.call(&"smoke_cloud_count")) == 0:
				_fail("powder smoke over before 3 s")
		T0 + 198:   # 3.3 s
			if int(fam.call(&"active_count")) != 0:
				_fail("effects still running at 3.3 s: %s" % [fam.call(&"active_ids")])
			if int(fam.call(&"smoke_cloud_count")) != 0:
				_fail("%d smoke clouds alive at 3.3 s" % fam.call(&"smoke_cloud_count"))
		210:
			_stress()
		210 + 270:   # 4.5 s after the stress
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
	world.add_child(solo)
	shooter = _unit(0, Vector3(-3.0, 0.0, 2.0))
	victim = _unit(1, Vector3(4.0, 0.0, -2.0))
	enemy = _unit(1, Vector3(-6.0, 0.0, -4.0))
	keep = Node3D.new()
	keep.set_script(_script(BUILDING_SRC))
	world.add_child(keep)
	keep.global_position = Vector3(8.0, 0.0, 6.0)
	if ResourceLoader.exists(CINDERLOCK):
		model = (load(CINDERLOCK) as PackedScene).instantiate() as Node3D
		shooter.add_child(model)
		if not model.has_method(&"get_muzzle_xf"):
			_fail("Cinderlock model has no get_muzzle_xf()")
	else:
		_fail("missing %s" % CINDERLOCK)
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
	# Unknown id / nothing to place: nothing starts.
	var n0: int = fam.call(&"active_count")
	hub.call(&"play", &"not_a_gun_effect", Vector3.ZERO, victim)
	hub.call(&"play", &"musket_shot", null, null)
	hub.call(&"play", &"musket_impact", null, null)
	if int(fam.call(&"active_count")) != n0:
		_fail("unknown id / no position started an effect")
	if bool(solo.call(&"play", &"rifle_shot", Vector3.ZERO, null)) or not bool(solo.call(&"handles", &"musket_shot")):
		_fail("family play / handles answer wrong")
	if not bool(solo.call(&"play", &"musket_shot", Vector3.ZERO, victim)):
		_fail("family play(musket_shot) returned false")
	# Every id with a target and without.
	for id in IDS:
		var target: Variant = victim
		if id == &"musket_breach":
			target = keep
		elif id == &"powder_smoke":
			target = shooter
		_expect_start(id, Vector3(1.0, 0.0, 1.0) if id != &"musket_shot" else Vector3(1.0, 1.3, 1.0), target,
				"%s with a target" % id)
		_expect_start(id, Vector3(-2.0, 0.0, 3.0) if id != &"musket_shot" else Vector3(-2.0, 1.3, 3.0), null,
				"%s without a target" % id)
	# musket_shot: muzzle forms.
	var xf := Transform3D(Basis.looking_at(Vector3(1, 0, 0)), Vector3(0.0, 1.3, 0.0))
	_expect_start(&"musket_shot", xf, victim, "musket_shot with a Transform3D")
	_expect_start(&"musket_shot", shooter, victim, "musket_shot with the shooter node")
	if model:
		_expect_start(&"musket_shot", model, victim, "musket_shot with the Cinderlock model")
		_expect_start(&"musket_shot", model.call(&"get_muzzle_xf"), victim, "musket_shot with get_muzzle_xf()")
	# musket_impact on a building = the breach look; `at` as a node = its chest.
	_expect_start(&"musket_impact", Vector3(6.5, 1.6, 5.0), keep, "musket_impact on a building")
	_expect_start(&"musket_impact", victim, victim, "musket_impact with a node `at`")
	# Smoke forms: radius clamps.
	hub.call(&"play", &"powder_smoke", Vector3(10.0, 0.0, -8.0), 10.0)
	hub.call(&"play", &"powder_smoke", Vector3(12.0, 0.0, -8.0), {"radius": 3.1, "team": 1})
	hub.call(&"play", &"powder_smoke", Vector3(14.0, 0.0, -8.0), 1.0)
	var radii: Dictionary = {}
	for c: Dictionary in fam.call(&"smoke_clouds"):
		radii[snappedf(float(c["radius"]), 0.01)] = int(c["team"])
	if not radii.has(4.0):
		_fail("powder_smoke radius 10 not clamped to 4.0 (%s)" % [radii])
	if not radii.has(3.1) or int(radii[3.1]) != 1:
		_fail("powder_smoke Dictionary {radius 3.1, team 1} not applied (%s)" % [radii])
	if not radii.has(2.5):
		_fail("powder_smoke radius 1.0 not clamped to 2.5 (%s)" % [radii])
	# Fog: an enemy cloud where team 0 does not see, an own cloud there.
	hub.call(&"play", &"powder_smoke", Vector3(150.0, 0.0, 0.0), {"team": 1})
	hub.call(&"play", &"powder_smoke", Vector3(150.0, 0.0, 20.0), {"team": 0})
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


func _fog_checks() -> void:
	var seen_enemy := false
	var seen_own := false
	for c: Dictionary in fam.call(&"smoke_clouds"):
		var p: Vector3 = c["point"]
		if p.x > 100.0 and int(c["team"]) == 1:
			seen_enemy = true
			if bool(c["shown"]):
				_fail("enemy cloud in the fog is shown")
		if p.x > 100.0 and int(c["team"]) == 0:
			seen_own = true
			if not bool(c["shown"]):
				_fail("own cloud in the fog is hidden")
	if not seen_enemy or not seen_own:
		_fail("fog test clouds missing")


## A burst 500 m away from the camera never starts.
func _far_check() -> void:
	var live: Array = fam.get(&"_live_bursts")
	var n := live.size()
	fam.call(&"play", &"musket_impact", Vector3(500.0, 0.0, 500.0), null)
	fam.call(&"_process", 0.0)
	if (fam.get(&"_live_bursts") as Array).size() > n:
		_fail("a burst started 500 m from the camera")


## A 20-gun volley, 20 impacts, 10 breaches, 8 clouds per team in one frame.
func _stress() -> void:
	_far_check()
	for i in 20:
		var p := Vector3(-10.0 + float(i), 1.3, 4.0)
		fam.call(&"play", &"musket_shot", Transform3D(Basis.looking_at(Vector3(0, 0, -1)), p), enemy)
	fam.call(&"play", &"powder_volley", Vector3(0.0, 0.0, 4.0), enemy)
	for i in 20:
		fam.call(&"play", &"musket_impact", Vector3(-10.0 + float(i), 1.0, -6.0), enemy)
	for i in 10:
		fam.call(&"play", &"musket_impact", Vector3(6.0, 1.0 + 0.2 * float(i), 4.0), keep)
	for i in 8:
		fam.call(&"play", &"powder_smoke", Vector3(-8.0 + 2.0 * float(i), 0.0, 4.0), {"radius": 2.5 + 0.3 * float(i % 6), "team": 0})
		fam.call(&"play", &"powder_smoke", Vector3(-8.0 + 2.0 * float(i), 0.0, -8.0), {"radius": 3.0, "team": 1})
	for t in [0, 1]:
		if int(fam.call(&"smoke_cloud_count", t)) != 6:
			_fail("team %d has %d clouds after 8 (want 6: the oldest replaced)" % [t, fam.call(&"smoke_cloud_count", t)])
	for c in fam.get_children():
		if c is MultiMeshInstance3D and (c as MultiMeshInstance3D).multimesh.instance_count > 72:
			_fail("%s has %d puffs" % [c.name, (c as MultiMeshInstance3D).multimesh.instance_count])
	if fam.get_child_count() != children_before or _materials(fam) != mats_before:
		_fail("nodes / materials created in the stress (pools ran out)")
	var a := Time.get_ticks_usec()
	fam.call(&"_process", 1.0 / 60.0)
	print("  UnitFireGunVfx _process right after the stress: %d us, running %d" % [Time.get_ticks_usec() - a,
			fam.call(&"active_count")])


func _final_checks() -> void:
	for v: Node3D in [fam, solo]:
		if int(v.call(&"live_count")) != 0:
			_fail("%s: %d pieces / bursts / clouds still alive at the end" % [v.name, v.call(&"live_count")])
		if int(v.call(&"active_count")) != 0:
			_fail("%s: effects still running at the end" % v.name)
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
		elif c is MultiMeshInstance3D:
			out[(c as MultiMeshInstance3D).material_override.get_instance_id()] = true
			out[(c as MultiMeshInstance3D).multimesh.get_instance_id()] = true
		elif c is GPUParticles3D:
			var p := c as GPUParticles3D
			out[p.process_material.get_instance_id()] = true
			out[p.draw_pass_1.get_instance_id()] = true
			out[(p.draw_pass_1 as PrimitiveMesh).material.get_instance_id()] = true
	return out


func _fail(why: String) -> void:
	fails.append(why)
	print("  fail: ", why)
