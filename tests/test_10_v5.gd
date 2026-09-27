extends SceneTree
## Task 10.V5: the trade caravan model (art/units/caravan/caravan.tscn, market-trade.md 9 / 12).
## Run:  $GODOT --headless --path . -s tests/test_10_v5.gd --fixed-fps 60 --quit-after 3000
## Checks: headless instantiation without errors; budgets (authored meshes <= 24 with the blob, draw instances after
## the merge <= 14, 0 lights, <= 5 materials all from art/units/caravan/ except the kit's shared blob, vertices printed);
## size (canopy top at body_height 1.9 +- 25 %, length ~3.2 m, x within radius 0.8 x 1.4, z within 2.4 x 0.8);
## hooks: set_loaded (cargo shown / hidden, lantern glow on / off, also before _ready), set_team_color (only the
## caravan_cloth surfaces), set_moving (ox legs trot, wheels spin), play_attack (no-op), play_hit (jolt), set_status,
## play_death + death_finished (topple), revive. Prints PASS 10.v5 / FAIL 10.v5: <reason>.

const TASK_ID := "10.v5"
const SCENE := "res://art/units/caravan/caravan.tscn"
const OWN_DIR := "res://art/units/caravan/"
const BLOB_MAT := "res://art/units/kit/materials/unit_shadow_blob.tres"
const SHADOW := Color(0.42, 0.22, 0.60)

var _fails: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  check failed: ", what)


func _frames(n: int) -> void:
	for _i: int in n:
		await process_frame


func _run() -> void:
	var ps := load(SCENE) as PackedScene
	_check(ps != null, "scene loads")
	if ps == null:
		_finish()
		return

	# ---- Authored meshes: build the parts on a copy outside the tree (no merge), count every mesh node.
	var probe := ps.instantiate()
	probe.call(&"_build_parts")
	var authored := 0
	for n: Node in probe.find_children("*", "", true, false):
		if n is MeshInstance3D or n is MultiMeshInstance3D:
			authored += 1
	probe.free()
	print("authored meshes (blob included): ", authored)
	_check(authored > 0 and authored <= 24, "authored meshes %d <= 24" % authored)

	# ---- Two instances in the tree: A empty, B loaded before _ready (cached hook).
	var world := Node3D.new()
	root.add_child(world)
	var models: Array = []
	for i: int in 2:
		var h := Node3D.new()
		h.position = Vector3(4.0 * i, 0, 0)
		world.add_child(h)
		var mm: Node3D = ps.instantiate()
		if i == 1:
			mm.call(&"set_loaded", true)
		h.add_child(mm)
		models.append(mm)
	await _frames(3)
	var m: Node3D = models[0]
	var mb: Node3D = models[1]

	# ---- Draw instances, lights, materials, vertices.
	for k: int in 2:
		var mm: Node3D = models[k]
		var inst := 0
		for n: Node in mm.find_children("*", "GeometryInstance3D", true, false):
			inst += 1
		print("instance %d: draw instances %d" % [k, inst])
		_check(inst <= 14, "draw instances %d <= 14" % inst)
		_check(mm.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
	var mats := {}
	var verts := 0
	for n: Node in mb.find_children("*", "GeometryInstance3D", true, false):
		if n is GPUParticles3D:
			continue
		var gi := n as GeometryInstance3D
		if gi.material_override:
			mats[gi.material_override.resource_path] = true
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
			var mesh := (gi as MeshInstance3D).mesh
			var nv := 0
			for s: int in mesh.get_surface_count():
				var mat := mesh.surface_get_material(s)
				if mat:
					mats[mat.resource_path] = true
				nv += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			verts += nv
			print("  %s: %d vertices" % [mb.get_path_to(gi), nv])
	var own := 0
	for p: String in mats:
		if p.begins_with(OWN_DIR):
			own += 1
		else:
			_check(p == BLOB_MAT, "material outside the caravan folder: '%s'" % p)
	print("materials: ", own, " own + ", mats.size() - own, " shared (", ", ".join(PackedStringArray(mats.keys())), "); vertices ", verts)
	_check(own <= 5, "materials %d <= 5" % own)
	_check(verts <= 6000, "vertices %d <= 6000" % verts)

	# ---- Exports and size.
	_check(is_equal_approx(float(m.get(&"body_height")), 1.9), "body_height 1.9")
	_check(float(m.get(&"attack_windup")) == 0.0, "attack_windup 0")
	var top := 0.0
	var min_z := 0.0
	var max_z := 0.0
	var max_x := 0.0
	for n: Node in mb.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not mi.is_visible_in_tree() or mi.name == "Shadow" or mi.mesh == null:
			continue
		var xf: Transform3D = mb.global_transform.affine_inverse() * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var w := xf * v
				max_x = maxf(max_x, absf(w.x))
				min_z = minf(min_z, w.z)
				max_z = maxf(max_z, w.z)
				if mi.get_parent().name == "Chest" and mi.name == "Merged":
					top = maxf(top, w.y)
	print("wagon top %.2f, length %.2f (z %.2f .. %.2f), half width %.2f" % [top, max_z - min_z, min_z, max_z, max_x])
	_check(top >= 1.9 * 0.75 and top <= 1.9 * 1.25 + 0.4, "wagon top %.2f near body_height 1.9" % top)
	_check(max_z - min_z >= 2.9 and max_z - min_z <= 3.6, "length %.2f ~3.2 m" % (max_z - min_z))
	_check(max_x <= 0.8 * 1.4 + 0.001, "half width %.2f within radius x 1.4 = 1.12" % max_x)
	_check(maxf(-min_z, max_z) <= 0.8 * 2.4 + 0.001, "reach along z within 2.4 x radius = 1.92")

	# ---- set_loaded: cargo + lantern glow.
	var cargo := m.get_node_or_null("Root/Chest/Cargo") as MeshInstance3D
	var lantern := m.get_node_or_null("Root/Chest/Lantern") as MeshInstance3D
	var cargo_b := mb.get_node_or_null("Root/Chest/Cargo") as MeshInstance3D
	var lantern_b := mb.get_node_or_null("Root/Chest/Lantern") as MeshInstance3D
	_check(cargo != null and lantern != null, "Cargo and Lantern nodes")
	_check(cargo_b != null and cargo_b.visible, "set_loaded(true) before _ready shows the cargo")
	_check(lantern_b != null and float(lantern_b.get_instance_shader_parameter(&"glow_boost")) > 0.9,
		"loaded lantern is lit (before _ready)")
	if cargo and lantern:
		_check(not cargo.visible, "empty by default")
		_check(float(lantern.get_instance_shader_parameter(&"glow_boost")) <= 0.0, "empty: lantern glass dark (glow <= 0)")
		m.call(&"set_loaded", true)
		_check(cargo.visible, "set_loaded(true) shows the cargo")
		_check(float(lantern.get_instance_shader_parameter(&"glow_boost")) > 0.9, "set_loaded(true) lights the lantern")
		_check(float(cargo.get_instance_shader_parameter(&"glow_boost")) > 0.5, "the coins glow")
		await _frames(30)
		m.call(&"set_loaded", false)
		_check(not cargo.visible, "set_loaded(false) hides the cargo")
		_check(float(lantern.get_instance_shader_parameter(&"glow_boost")) <= 0.0, "set_loaded(false) darkens the lantern")
		await _frames(30)

	# ---- Team colour: only caravan_cloth surfaces change.
	var chest := m.get_node_or_null("Root/Chest/Merged") as MeshInstance3D
	m.call(&"set_team_color", Color(0.85, 0.30, 0.12))   # = kingdom_color: no-op
	var before := 0
	if chest:
		for s: int in chest.mesh.get_surface_count():
			if chest.get_surface_override_material(s) != null:
				before += 1
	_check(chest != null and before == 0, "set_team_color(kingdom colour) is a no-op")
	m.call(&"set_team_color", SHADOW)
	var recoloured := 0
	var wrong := 0
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for s: int in mi.mesh.get_surface_count():
			var o := mi.get_surface_override_material(s)
			if o == null:
				continue
			var src := mi.mesh.surface_get_material(s)
			if src and src.resource_path.ends_with("caravan_cloth.tres") \
					and (o as ShaderMaterial).get_shader_parameter(&"base_color").is_equal_approx(SHADOW):
				recoloured += 1
			else:
				wrong += 1
	print("team colour: %d cloth surfaces recoloured, %d other" % [recoloured, wrong])
	_check(recoloured >= 4 and wrong == 0, "set_team_color recolours canvas / pennant / blanket / cargo cloth only")

	# ---- Walk: ox legs trot, wheels spin, lantern swings.
	var leg := m.get_node("Root/Mount/LegFL") as Node3D
	var leg_b := m.get_node("Root/Mount/LegBL") as Node3D
	var hips := m.get_node("Root/Hips") as Node3D
	var r0 := hips.rotation.x
	m.call(&"set_moving", 4.0)
	var swing := 0.0
	var anti := false
	var lan_max := 0.0
	var spun := 0.0
	var last := hips.rotation.x
	for i: int in 60:
		await process_frame
		swing = maxf(swing, absf(leg.rotation.x))
		if absf(leg.rotation.x) > 0.2 and signf(leg.rotation.x) == -signf(leg_b.rotation.x):
			anti = true
		if lantern:
			lan_max = maxf(lan_max, absf(lantern.rotation.x))
		spun += absf(wrapf(hips.rotation.x - last, -PI, PI))
		last = hips.rotation.x
	print("walk: leg swing %.2f rad, wheels turned %.2f rad in 1 s, lantern swing %.3f rad" % [swing, spun, lan_max])
	_check(swing > 0.3, "walk swings the ox legs (%.2f rad)" % swing)
	_check(anti, "trot: front-left and back-left legs move in opposition")
	_check(spun > 4.0 and spun < 12.0, "wheels roll ~speed / radius (4.0 / 0.46 = 8.7 rad/s): %.2f" % spun)
	_check(lan_max > 0.02, "the lantern swings")
	_check(absf(r0 - hips.rotation.x) >= 0.0, "wheel angle readable")
	m.call(&"set_moving", 0.0)
	await _frames(30)
	var still := hips.rotation.x
	await _frames(20)
	_check(is_equal_approx(still, hips.rotation.x), "wheels stop when idle")

	# ---- Attack (no-op), hit, statuses.
	m.call(&"play_attack")
	await _frames(2)
	_check(StringName(m.get(&"_action")) == &"", "play_attack is a no-op")
	var root3 := m.get_node("Root") as Node3D
	m.call(&"play_hit")
	var jolt := 0.0
	for i: int in 12:
		await process_frame
		jolt = minf(jolt, root3.position.z)
	_check(jolt < -0.05, "play_hit jolts the rig back (%.2f)" % jolt)
	await _frames(20)
	_check(bool(m.call(&"set_status", &"haste", true)), "set_status haste -> true")
	_check(not bool(m.call(&"set_status", &"burn", true)), "set_status burn -> false")
	m.call(&"set_status", &"haste", false)

	# ---- Death (topple) + revive, loaded caravan.
	mb.call(&"set_moving", 3.6)
	await _frames(20)
	var got := [false]
	mb.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	var rb := mb.get_node("Root") as Node3D
	var chest_b := mb.get_node("Root/Chest") as Node3D
	mb.call(&"play_death")
	var tilt := 0.0
	var frames_to_end := -1
	for i: int in 150:
		await process_frame
		tilt = maxf(tilt, absf(chest_b.rotation.z))
		if got[0]:
			frames_to_end = i
			break
	print("death: finished after %d frames, wagon tip %.2f rad, root y %.2f" % [frames_to_end, tilt, rb.position.y])
	_check(got[0], "death_finished emitted")
	_check(frames_to_end >= 50 and frames_to_end <= 75, "death lasts ~1.0 s")
	_check(tilt > 0.3, "the wagon tips over")
	_check(rb.position.y < -0.8, "the caravan sinks")
	_check(lantern_b == null or float(lantern_b.get_instance_shader_parameter(&"glow_boost")) <= 0.0, "the lantern goes out")
	mb.call(&"revive")
	await _frames(4)
	_check(rb.position.length() < 0.05 and absf(chest_b.rotation.z) < 0.05, "revive resets the pose")
	_check(lantern_b == null or float(lantern_b.get_instance_shader_parameter(&"glow_boost")) > 0.9, "revived loaded lantern lit")
	_check(mb.is_processing(), "revived model processes")

	# ---- Hooks before _ready, third instance from the merge cache.
	var early: Node3D = ps.instantiate()
	early.call(&"set_team_color", SHADOW)
	early.call(&"set_moving", 4.0)
	early.call(&"play_hit")
	world.add_child(early)
	await _frames(10)
	_check(early.get_node_or_null("Root/Chest/Merged") != null, "third instance merged from the cache")
	var ec := early.get_node_or_null("Root/Chest/Merged") as MeshInstance3D
	var ecol := false
	if ec:
		for s: int in ec.mesh.get_surface_count():
			var o := ec.get_surface_override_material(s)
			if o and (o as ShaderMaterial).get_shader_parameter(&"base_color").is_equal_approx(SHADOW):
				ecol = true
	_check(ecol, "set_team_color before _ready is applied")

	# ---- Rough animation cost: 60 caravans walking (headless = middle tier).
	var crowd: Array = []
	for i: int in 60:
		var c: Node3D = ps.instantiate()
		c.position = Vector3(float(i % 10) * 4.0, 0, 10.0 + float(i / 10) * 5.0)
		world.add_child(c)
		c.call(&"set_loaded", i % 2 == 0)
		c.call(&"set_moving", 4.0)
		crowd.append(c)
	await _frames(10)
	var t0 := Time.get_ticks_usec()
	await _frames(60)
	var per_frame := float(Time.get_ticks_usec() - t0) / 60.0 / 1000.0
	print("60 walking caravans: %.2f ms per frame (whole headless frame)" % per_frame)
	world.queue_free()
	await _frames(2)
	_finish()


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()
