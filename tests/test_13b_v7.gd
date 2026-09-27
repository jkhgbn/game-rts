extends SceneTree
## Task 13b.V7: rune-rifle effects (art/vfx/unit_ice_rifle_vfx.gd, a family of UnitVfx art/vfx/unit_vfx.gd).
## Run:  $GODOT --headless --path . -s tests/test_13b_v7.gd --fixed-fps 60 --quit-after 900
## Stand-in units (a tiny Node3D script built here: team, body_height, radius, is_alive, get_model), a stand-in
## building and a stand-in FogOfWar (group "fog": the local team 0 sees x < 100) replace the game's. The real
## Frostrune Rifleman model (13b.V2) is the shooter of the tracked effects.
## Checks:
##  - UnitVfx loads the family and knows its 8 ids; unknown ids / no position do nothing; the family's own play()
##    returns true for its ids and false for others; 0 lights; every burst has visibility_range_end 45;
##  - each id starts an effect with a target and without; rifle_shot takes a Vector3, a Transform3D, a stand-in unit,
##    the rifleman model and a unit holding it; frost_tracer takes a node, a Vector3, nothing, a Dictionary (impact);
##  - timings: shot and tracer over by 0.25 s, impact running at 0.5 s and over by 1.0 s, the aim line still running
##    at 1.0 s (charge >= 0.8) and gone by 1.7 s, the freeze hit over by 1.5 s, a solo brace circle over by 2.0 s;
##  - Rime Lock: the aim follows a moving target; rime_lock_hit on the aimed victim converts the aim (aim_count drops);
##    rime_lock_cancel ends an aim; fog: an enemy aim at a visible own unit is shown, one wholly in the fog is not; an
##    enemy impact in the fog shows nothing;
##  - brace: held on the braced model after 2 s, a second brace on it adds nothing, it ends when the model stands up;
##    brace_end ends the circle of a unit without a model; freeing a followed unit ends its circle;
##  - no node, material or mesh is created after _ready (a 20-rifle stress: shots, tracers, impacts, aims, hits,
##    braces); 5 s after the stress nothing is left and every pool is full again; a burst 500 m away never starts.
## Prints PASS 13b_v7 / FAIL 13b_v7: <reason>.

const TASK_ID := "13b_v7"
const HUB_PATH := "res://art/vfx/unit_vfx.gd"
const FAMILY_PATH := "res://art/vfx/unit_ice_rifle_vfx.gd"
const RIFLEMAN := "res://art/units/ice/frostrune_rifleman/frostrune_rifleman.tscn"
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar body_height: float = 1.8\nvar radius: float = 0.45\nvar alive: bool = true\nfunc is_alive() -> bool:\n\treturn alive\nfunc get_model() -> Node3D:\n\treturn get_child(0) as Node3D if get_child_count() > 0 else null\n"
const BUILDING_SRC := "extends Node3D\nvar team: int = 1\nvar building_type: Resource = null\nfunc _ready() -> void:\n\tadd_to_group(&\"buildings\")\nfunc target_radius() -> float:\n\treturn 3.0\n"
const FOG_SRC := "extends Node\nvar enabled: bool = true\nvar local_team: int = 0\nfunc _ready() -> void:\n\tadd_to_group(&\"fog\")\nfunc is_visible(_team: int, pos: Vector3) -> bool:\n\treturn pos.x < 100.0\n"
const IDS: Array[StringName] = [&"rifle_shot", &"frost_tracer", &"rifle_impact", &"rime_lock_aim", &"rime_lock_hit",
		&"rime_lock_cancel", &"brace", &"brace_end"]
const T0 := 3

var world: Node3D
var hub: Node3D
var fam: Node3D
var solo: Node3D
var fogfam: Node3D
var stub: GDScript
var rifle_unit: Node3D     # stand-in unit holding the real model
var model: Node3D
var victim: Node3D
var enemy: Node3D
var gunner2: Node3D
var gunner3: Node3D
var plain: Node3D          # a unit without a model (brace_end)
var doomed: Node3D         # a braced unit freed while its circle runs
var keep: Node3D
var cam: Camera3D
var frame := 0
var fails: PackedStringArray = []
var children_before := 0
var mats_before: Dictionary = {}
var aims_before_hit := 0


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
		T0 + 1:
			_fog_checks()
		T0 + 15:   # 0.25 s
			var ids: Array = fam.call(&"active_ids")
			for id: StringName in [&"rifle_shot", &"frost_tracer", &"rime_lock_cancel"]:
				if ids.has(id):
					_fail("%s still running at 0.25 s" % id)
			if int(fam.call(&"aim_count")) != 2:
				_fail("aims at 0.25 s: %d (want 2: node aim + fixed aim; the third was cancelled)" % fam.call(&"aim_count"))
		T0 + 30:   # 0.5 s
			if not (fam.call(&"active_ids") as Array).has(&"rifle_impact"):
				_fail("rifle_impact over before 0.5 s")
			aims_before_hit = int(fam.call(&"aim_count"))
			fam.call(&"play", &"rime_lock_hit", victim, victim)
			if int(fam.call(&"aim_count")) != aims_before_hit - 1:
				_fail("rime_lock_hit did not convert the aim at its victim (%d -> %d)" % [aims_before_hit,
						fam.call(&"aim_count")])
			hub.call(&"play", &"rime_lock_aim", gunner2, enemy)
		T0 + 60:   # 1.0 s
			var ids2: Array = fam.call(&"active_ids")
			if ids2.has(&"rifle_impact"):
				_fail("rifle_impact still running at 1.0 s")
			var charged := false
			for a: Dictionary in fam.call(&"aims"):
				if float(a["charge"]) >= 0.8 and not bool(a["ending"]):
					charged = true
			if not charged:
				_fail("no aim line charged >= 0.8 at 1.0 s")
			enemy.global_position += Vector3(3.0, 0.0, 2.0)
		T0 + 62:
			var tracked := false
			for a: Dictionary in fam.call(&"aims"):
				if (a["to"] as Vector3).distance_to(enemy.global_position + Vector3.UP * 0.99) < 0.05:
					tracked = true
			if not tracked:
				_fail("the aim line does not follow its moving target")
		T0 + 105:   # 1.75 s
			if int(fam.call(&"aim_count")) != 1:
				_fail("aims at 1.75 s: %d (want only the late one)" % fam.call(&"aim_count"))
		T0 + 120:   # 2.0 s (the hit played at 0.5 s is 1.5 s old)
			if (fam.call(&"active_ids") as Array).has(&"rime_lock_hit"):
				_fail("rime_lock_hit still running 1.5 s after it was played")
		T0 + 125:   # 2.08 s
			var n_brace := 0
			for id: StringName in fam.call(&"active_ids"):
				if id == &"brace":
					n_brace += 1
			if n_brace != 3 or int(fam.call(&"brace_count")) != 3:
				_fail("brace circles at 2.1 s: %d running / %d held (want 3: model, plain unit, doomed unit; solo over)"
						% [n_brace, fam.call(&"brace_count")])
			doomed.queue_free()   # a followed unit that leaves the tree ends its circle
			var b0: int = fam.call(&"active_count")
			hub.call(&"play", &"brace", rifle_unit, null)
			hub.call(&"play", &"brace", model, null)
			if int(fam.call(&"active_count")) != b0:
				_fail("a second brace on a braced rifleman started another circle")
			model.call(&"set_braced", false)
			hub.call(&"play", &"brace_end", plain, null)
		T0 + 140:
			if int(fam.call(&"aim_count")) != 0 or (fam.call(&"active_ids") as Array).has(&"rime_lock_aim"):
				_fail("aim lines left at 2.3 s")
		T0 + 185:   # 1 s after the stand-up
			if int(fam.call(&"brace_count")) != 0 or (fam.call(&"active_ids") as Array).has(&"brace"):
				_fail("brace circle still there 1 s after the rifleman stood up / brace_end")
			if int(fam.call(&"active_count")) != 0:
				_fail("effects still running at 3.1 s: %s" % [fam.call(&"active_ids")])
		T0 + 200:
			_stress()
		T0 + 200 + 300:
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
	fogfam = (load(FAMILY_PATH) as GDScript).new()
	world.add_child(fogfam)
	rifle_unit = _unit(0, Vector3(-3.0, 0.0, 2.0))
	victim = _unit(1, Vector3(6.0, 0.0, -2.0))
	enemy = _unit(1, Vector3(8.0, 0.0, 5.0))
	gunner2 = _unit(0, Vector3(-4.0, 0.0, 6.0))
	gunner3 = _unit(0, Vector3(-5.0, 0.0, -6.0))
	plain = _unit(0, Vector3(-8.0, 0.0, 0.0))
	doomed = _unit(0, Vector3(-8.0, 0.0, 4.0))
	keep = Node3D.new()
	keep.set_script(_script(BUILDING_SRC))
	world.add_child(keep)
	keep.global_position = Vector3(10.0, 0.0, 8.0)
	if ResourceLoader.exists(RIFLEMAN):
		model = (load(RIFLEMAN) as PackedScene).instantiate() as Node3D
		rifle_unit.add_child(model)
		for m: StringName in [&"get_muzzle_position", &"get_scope_position", &"set_braced", &"is_braced"]:
			if not model.has_method(m):
				_fail("rifleman model has no %s()" % m)
	else:
		_fail("missing %s" % RIFLEMAN)
	children_before = fam.get_child_count()
	mats_before = _materials(fam)
	for v: Node in [fam, solo]:
		for c in v.get_children():
			if c is Light3D:
				_fail("a light in the family (%s)" % c.name)
			if c is GPUParticles3D and absf((c as GPUParticles3D).visibility_range_end - 45.0) > 0.01:
				_fail("burst %s has visibility_range_end %.1f" % [c.name, (c as GPUParticles3D).visibility_range_end])


func _unit(team: int, pos: Vector3) -> Node3D:
	var u := Node3D.new()
	u.set_script(stub)
	u.set(&"team", team)
	world.add_child(u)
	u.global_position = pos
	return u


func _play_all() -> void:
	var n0: int = fam.call(&"active_count")
	hub.call(&"play", &"not_a_rifle_effect", Vector3.ZERO, victim)
	hub.call(&"play", &"rifle_shot", null, null)
	hub.call(&"play", &"rifle_impact", null, null)
	hub.call(&"play", &"rime_lock_aim", null, victim)
	hub.call(&"play", &"rime_lock_aim", rifle_unit, null)
	hub.call(&"play", &"brace", null, null)
	if int(fam.call(&"active_count")) != n0:
		_fail("unknown id / no position started an effect")
	if bool(solo.call(&"play", &"musket_shot", Vector3.ZERO, null)) or not bool(solo.call(&"handles", &"rifle_shot")):
		_fail("family play / handles answer wrong")
	if not bool(solo.call(&"play", &"rifle_shot", Vector3(0, 1.2, 0), victim)):
		_fail("family play(rifle_shot) returned false")
	# rifle_shot: every muzzle form, with and without a target.
	_expect(&"rifle_shot", Vector3(0.0, 1.2, 0.0), victim, "rifle_shot Vector3 + target")
	_expect(&"rifle_shot", Vector3(0.0, 1.2, 2.0), null, "rifle_shot Vector3 alone")
	_expect(&"rifle_shot", Transform3D(Basis.looking_at(Vector3(1, 0, 0)), Vector3(0, 1.2, -2)), victim,
			"rifle_shot Transform3D")
	_expect(&"rifle_shot", victim, null, "rifle_shot stand-in unit")
	if model:
		_expect(&"rifle_shot", model, victim, "rifle_shot rifleman model")
		_expect(&"rifle_shot", rifle_unit, victim, "rifle_shot unit holding the model")
	# frost_tracer.
	_expect(&"frost_tracer", rifle_unit, victim, "frost_tracer to a node")
	_expect(&"frost_tracer", Vector3(0, 1.2, 0), Vector3(12, 1.0, 0), "frost_tracer to a Vector3")
	_expect(&"frost_tracer", rifle_unit, null, "frost_tracer without a target")
	var n1: int = fam.call(&"active_count")
	hub.call(&"play", &"frost_tracer", Vector3(0, 1.2, 0), {"to": Vector3(4, 1.0, 0), "impact": true})
	if int(fam.call(&"active_count")) <= n1:
		_fail("frost_tracer with a Dictionary started nothing")
	# rifle_impact.
	_expect(&"rifle_impact", Vector3(6.0, 1.0, -2.0), victim, "rifle_impact with a victim")
	_expect(&"rifle_impact", Vector3(2.0, 1.0, 1.0), null, "rifle_impact alone")
	_expect(&"rifle_impact", Vector3(9.0, 1.5, 6.0), keep, "rifle_impact on a building")
	# Rime Lock: node -> node (converted at 0.5 s), fixed points, one cancelled.
	_expect(&"rime_lock_aim", rifle_unit, victim, "rime_lock_aim node -> node")
	_expect(&"rime_lock_aim", Vector3(-2.0, 1.2, -3.0), Vector3(9.0, 1.0, -3.0), "rime_lock_aim Vector3 -> Vector3")
	_expect(&"rime_lock_aim", gunner3, victim, "rime_lock_aim third shooter")
	hub.call(&"play", &"rime_lock_cancel", gunner3, null)
	_expect(&"rime_lock_hit", Vector3(3.0, 1.0, 3.0), null, "rime_lock_hit alone")
	# Brace: tracked on the model (braced), on a plain unit, and a solo one-shot.
	if model:
		model.call(&"set_braced", true)
		_expect(&"brace", rifle_unit, null, "brace on the rifleman")
	_expect(&"brace", plain, null, "brace on a unit without a model")
	_expect(&"brace", doomed, null, "brace on a unit freed later")
	_expect(&"brace", Vector3(2.0, 0.0, -6.0), null, "brace solo")
	if fam.get_child_count() != children_before or _materials(fam) != mats_before:
		_fail("nodes / materials created at runtime")
	if int(fam.call(&"live_count")) == 0:
		_fail("nothing visible after playing every effect")
	# Fog: an enemy impact in the fog; an enemy aim at a visible unit; an enemy aim wholly in the fog.
	var far_enemy := _unit(1, Vector3(150.0, 0.0, 0.0))
	var far_enemy2 := _unit(1, Vector3(160.0, 0.0, 4.0))
	fogfam.call(&"play", &"rifle_impact", far_enemy, far_enemy)
	fogfam.call(&"play", &"rime_lock_aim", far_enemy, rifle_unit)
	fogfam.call(&"play", &"rime_lock_aim", far_enemy2, far_enemy)


func _expect(id: StringName, at: Variant, target: Variant, what: String) -> void:
	var before: int = fam.call(&"active_count")
	hub.call(&"play", id, at, target)
	if int(fam.call(&"active_count")) <= before:
		_fail("%s started nothing" % what)


func _fog_checks() -> void:
	var aims: Array = fogfam.call(&"aims")
	if aims.size() != 2:
		_fail("fog test: %d aims (want 2)" % aims.size())
		return
	var shown_warn := false
	var shown_hidden := true
	for a: Dictionary in aims:
		if (a["to"] as Vector3).x < 100.0:
			shown_warn = bool(a["shown"])
		else:
			shown_hidden = bool(a["shown"])
	if not shown_warn:
		_fail("an enemy aim line at a visible own unit is hidden (both teams must see it)")
	if shown_hidden:
		_fail("an enemy aim line wholly in the fog is shown")
	# Only the aim at the visible unit may draw: its line + reticle + end glow (<= 3 pieces).
	var live: int = fogfam.call(&"live_count")
	if live > 3:
		_fail("fogged effects draw (%d pieces / bursts live, want <= 3)" % live)


## A burst 500 m away from the camera never starts.
func _far_check() -> void:
	var n := (fam.get(&"_live_bursts") as Array).size()
	fam.call(&"play", &"rifle_impact", Vector3(500.0, 1.0, 500.0), null)
	fam.call(&"_process", 0.0)
	if (fam.get(&"_live_bursts") as Array).size() > n:
		_fail("a burst started 500 m from the camera")


## 20 shots + 20 tracers + 20 impacts + 10 aims + 10 freeze hits + 20 brace circles in one frame.
func _stress() -> void:
	_far_check()
	for i in 20:
		var p := Vector3(-10.0 + float(i), 1.2, 4.0)
		fam.call(&"play", &"rifle_shot", Transform3D(Basis.looking_at(Vector3(0, 0, -1)), p), enemy)
		fam.call(&"play", &"frost_tracer", p, Vector3(-10.0 + float(i), 1.0, -8.0))
		fam.call(&"play", &"rifle_impact", Vector3(-10.0 + float(i), 1.0, -8.0), enemy)
		fam.call(&"play", &"brace", Vector3(-10.0 + float(i), 0.0, 4.0), null)
	for i in 10:
		fam.call(&"play", &"rime_lock_aim", Vector3(-10.0 + 2.0 * float(i), 1.2, 4.0), Vector3(-10.0 + 2.0 * float(i), 1.0, -8.0))
	for i in 10:
		fam.call(&"play", &"rime_lock_hit", Vector3(-10.0 + 2.0 * float(i), 1.0, -8.0), enemy)
	if fam.get_child_count() != children_before or _materials(fam) != mats_before:
		_fail("nodes / materials created in the stress (pools ran out)")
	var a := Time.get_ticks_usec()
	fam.call(&"_process", 1.0 / 60.0)
	print("  UnitIceRifleVfx _process right after the stress: %d us, running %d, live %d" % [
			Time.get_ticks_usec() - a, fam.call(&"active_count"), fam.call(&"live_count")])


func _final_checks() -> void:
	for v: Node3D in [fam, solo, fogfam]:
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
		elif c is MultiMeshInstance3D:
			out[(c as MultiMeshInstance3D).material_override.get_instance_id()] = true
			out[(c as MultiMeshInstance3D).multimesh.get_instance_id()] = true
			out[(c as MultiMeshInstance3D).multimesh.mesh.get_instance_id()] = true
		elif c is GPUParticles3D:
			var p := c as GPUParticles3D
			out[p.process_material.get_instance_id()] = true
			out[p.draw_pass_1.get_instance_id()] = true
			out[(p.draw_pass_1 as PrimitiveMesh).material.get_instance_id()] = true
	return out


func _fail(why: String) -> void:
	fails.append(why)
	print("  fail: ", why)
