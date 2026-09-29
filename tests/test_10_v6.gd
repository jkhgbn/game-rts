extends SceneTree
## Task 10.V6: the Magpie thief model (art/units/neutral/magpie/magpie.tscn), market-trade.md 5 / 9 / 12.
## Run:  $GODOT --headless --path . -s tests/test_10_v6.gd --fixed-fps 60 --quit-after 3000
## Checks: headless instantiation without errors; soldier budget (authored meshes <= 18 with the blob, draw
## instances <= 10 after the merge, 0 lights, vertices <= 2 500, own materials <= 6 from the magpie folder + the kit's
## blob / gold trim); exactly 1 glow surface (the eye shine); size (hood top at body_height 1.6 +- 25 %, footprint
## within radius 0.4 x 1.4 at rest); neutral (set_team_color never recolours); hooks: set_carrying (sack, also before
## _ready), set_moving (walk), play_attack (scissor, both knives), play_snatch (1.5 s, sack yanked over the shoulder,
## eyes flare), cancel_snatch / set_moving cancel it, set_status shroud -> smoke flee (puff, flee sprint), play_hit,
## lurk idle head snaps (camera close), play_death + death_finished (sack hidden), revive.
## Prints PASS 10.v6 / FAIL 10.v6: <reason>.

const TASK_ID := "10.v6"
const SCENE := "res://art/units/neutral/magpie/magpie.tscn"
const OWN_DIR := "res://art/units/neutral/magpie/"
## The FaceKit's shared face material (faces pass 2026-09-28): the Face node carries the eye shine (glowing irises).
const FACE_MAT := "res://art/units/kit/face/unit_face.tres"
const FaceProbe := preload("res://tests/face_probe.gd")
const KIT_OK: Array[String] = ["res://art/units/kit/materials/unit_shadow_blob.tres",
	"res://art/units/kit/materials/unit_gold_trim.tres", FACE_MAT]
const RADIUS := 0.4

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


## A glowing surface: a kit glow shader, except the shared face material, which glows only where a vertex alpha is
## <= 0.5 (FaceKit.glow: the irises, FaceProbe); a face surface without such vertices is painted only.
func _is_glow_surface(mat: Material, mesh: Mesh, s: int) -> bool:
	if FaceProbe.is_face_mat(mat):
		var cols: Variant = mesh.surface_get_arrays(s)[Mesh.ARRAY_COLOR]
		if cols is PackedColorArray:
			for c: Color in cols:
				if c.a <= FaceProbe.GLOW_ALPHA:
					return true
		return false
	return _is_glow(mat)


func _is_glow(mat: Material) -> bool:
	return mat is ShaderMaterial and (mat as ShaderMaterial).shader != null \
		and (mat as ShaderMaterial).shader.code.contains("glow_boost")


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
	_check(authored > 0 and authored <= 18, "authored meshes %d <= 18" % authored)

	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()          # close camera: tier 0 (full-rate idle with the head snaps)
	world.add_child(cam)
	cam.position = Vector3(0, 4, 6)
	cam.look_at(Vector3(0, 1, 0))
	cam.make_current()
	var models: Array = []
	for i: int in 2:
		var h := Node3D.new()
		h.position = Vector3(3.0 * i, 0, 0)
		world.add_child(h)
		var mm: Node3D = ps.instantiate()
		if i == 1:
			mm.call(&"set_carrying", true)   # before _ready: cached and applied
		h.add_child(mm)
		models.append(mm)
	await _frames(3)
	var m: Node3D = models[0]
	var mb: Node3D = models[1]

	# ---- Draw instances, lights, materials, vertices, glow surfaces.
	for k: int in 2:
		var mm: Node3D = models[k]
		var inst := mm.find_children("*", "GeometryInstance3D", true, false).size()
		print("instance %d: draw instances %d" % [k, inst])
		_check(inst <= 11, "draw instances %d <= 11 (10 + the Face node)" % inst)
		_check(mm.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
	var mats := {}
	var verts := 0
	var glow_surfaces := 0
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
					if _is_glow_surface(mat, mesh, s):
						glow_surfaces += 1
				nv += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			verts += nv
			print("  %s: %d vertices" % [mb.get_path_to(gi), nv])
	var own := 0
	for p: String in mats:
		if p.begins_with(OWN_DIR):
			own += 1
		else:
			_check(p in KIT_OK, "material outside the magpie folder: '%s'" % p)
	print("materials: ", own, " own + ", mats.size() - own, " shared (", ", ".join(PackedStringArray(mats.keys())),
		"); vertices ", verts, "; glow surfaces ", glow_surfaces)
	_check(own <= 6, "materials %d <= 6" % own)
	# Soldier + the face (faces pass 2026-09-28: measured 2769 with the Face node, 408 of them; small margin).
	_check(verts <= 2850, "vertices %d <= 2850 (soldier 2500 + face)" % verts)
	_check(glow_surfaces == 1, "exactly 1 glow point (eye shine = the face's glowing irises), got %d surfaces" % glow_surfaces)

	# ---- Exports and size.
	_check(is_equal_approx(float(m.get(&"body_height")), 1.6), "body_height 1.6")
	_check(StringName(m.get(&"attack_style")) == &"scissor", "attack_style scissor")
	_check(float(m.get(&"attack_windup")) == 0.0, "melee: attack_windup 0")
	var head_merged := m.get_node_or_null("Root/Chest/Head/Merged") as MeshInstance3D
	_check(head_merged != null, "Head merged")
	if head_merged:
		# The hood top (the crest feathers are thin and may rise above it): top of the widest part.
		var top := 0.0
		var xf := head_merged.global_transform
		for s: int in head_merged.mesh.get_surface_count():
			var mat := head_merged.mesh.surface_get_material(s)
			if mat and mat.resource_path.ends_with("magpie_black.tres"):
				for v: Vector3 in (head_merged.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
					top = maxf(top, (xf * v).y)
		print("hood top y: %.2f" % top)
		_check(top >= 1.6 * 0.75 and top <= 1.6 * 1.25, "hood top %.2f within 1.6 +- 25 %%" % top)
	var reach := 0.0
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not mi.is_visible_in_tree() or mi.name == "Shadow" or mi.mesh == null:
			continue
		var lx: Transform3D = m.global_transform.affine_inverse() * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var w := lx * v
				reach = maxf(reach, Vector2(w.x, w.z).length())
	print("footprint reach at rest: %.2f" % reach)
	_check(reach <= RADIUS * 1.4 + 0.005, "footprint %.2f within radius x 1.4 = 0.56" % reach)

	# ---- Neutral: set_team_color never recolours anything.
	m.call(&"set_team_color", Color(0.42, 0.22, 0.60))
	var overrides := 0
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh:
			for s: int in mi.mesh.get_surface_count():
				if mi.get_surface_override_material(s) != null:
					overrides += 1
	_check(overrides == 0, "set_team_color is a no-op on a neutral Magpie (%d overrides)" % overrides)

	# ---- Carrying: the sack.
	var sack := m.get_node_or_null("Root/Chest/Sack") as Node3D
	var sack_b := mb.get_node_or_null("Root/Chest/Sack") as Node3D
	_check(sack != null and not sack.visible, "no sack while not carrying")
	_check(sack_b != null and sack_b.visible, "set_carrying(true) before _ready shows the sack")
	m.call(&"set_carrying", true)
	_check(sack != null and sack.visible, "set_carrying(true) shows the sack")
	m.call(&"set_carrying", false)
	_check(sack != null and not sack.visible, "set_carrying(false) hides the sack")

	# ---- Lurk idle: the head snaps around (close camera).
	var head := m.get_node("Root/Chest/Head") as Node3D
	var yaws: Array[float] = []
	for i: int in 180:
		await process_frame
		if i % 10 == 0:
			yaws.append(head.rotation.y)
	var spread := 0.0
	for y: float in yaws:
		spread = maxf(spread, absf(y - yaws[0]))
	print("lurk head yaw spread over 3 s: %.2f rad" % spread)
	_check(spread > 0.25, "lurk idle: head snaps around (%.2f rad)" % spread)
	m.set(&"_idle_left", 1.0e9)
	mb.set(&"_idle_left", 1.0e9)
	await _frames(110)   # let an idle fidget finish if one started

	# ---- Walk.
	var chest := m.get_node("Root/Chest") as Node3D
	m.call(&"set_moving", 5.2)
	var leg := m.get_node("Root/Hips/LegL") as Node3D
	var swing := 0.0
	var lean_walk := 0.0
	for i: int in 40:
		await process_frame
		swing = maxf(swing, absf(leg.rotation.x))
		lean_walk = maxf(lean_walk, chest.rotation.x)
	_check(swing > 0.3, "walk swings the legs (%.2f rad)" % swing)

	# ---- Shroud -> smoke flee (while walking).
	var puff := m.get_node_or_null("Fx/Puff") as GPUParticles3D
	_check(puff != null, "Puff emitter")
	_check(bool(m.call(&"set_status", &"shroud", true)), "set_status shroud -> true")
	_check(bool(m.call(&"is_fleeing")), "shroud on -> fleeing")
	_check(StringName(m.get(&"_action")) == &"cast" and StringName(m.get(&"_cast_id")) == &"smoke_flee",
		"shroud on plays the smoke flee")
	_check(puff != null and puff.emitting, "the smoke puff fires")
	await _frames(45)
	var lean_flee := 0.0
	var arm_back := 0.0
	var arm_r := m.get_node("Root/Chest/ArmR") as Node3D
	var arm_l := m.get_node("Root/Chest/ArmL") as Node3D
	for i: int in 30:
		await process_frame
		lean_flee = maxf(lean_flee, chest.rotation.x)
		arm_back = maxf(arm_back, arm_r.rotation.x)
	print("walk lean %.2f, flee lean %.2f, flee arms back %.2f" % [lean_walk, lean_flee, arm_back])
	_check(lean_flee > lean_walk + 0.15, "the flee sprint leans in deeper than the sneak")
	_check(arm_back > 0.5, "the flee sprint sweeps the arms back")
	m.call(&"set_status", &"shroud", false)
	_check(not bool(m.call(&"is_fleeing")), "shroud off -> not fleeing")
	m.call(&"set_moving", 0.0)
	await _frames(20)

	# ---- Attack scissor.
	m.call(&"play_attack")
	var max_r := 0.0
	var max_l := 0.0
	var lunge := 0.0
	var done := -1
	var rt := m.get_node("Root") as Node3D
	for i: int in 60:
		await process_frame
		max_r = maxf(max_r, absf(arm_r.rotation.z))
		max_l = maxf(max_l, absf(arm_l.rotation.z))
		lunge = maxf(lunge, rt.position.z)
		if StringName(m.get(&"_action")) == &"":
			done = i
			break
	_check(done >= 0 and done <= 30, "scissor ends within 0.5 s (%d frames)" % done)
	_check(max_r > 0.3 and max_l > 0.3, "scissor cuts with both knives (%.2f / %.2f rad)" % [max_r, max_l])
	_check(lunge > 0.12, "scissor lunges (%.2f m)" % lunge)
	await _frames(10)

	# ---- Snatch: 1.5 s, eyes flare, a sack flies onto the back, hidden again (gameplay decides the loot).
	# The eye shine is the Face node's glowing irises (faces pass 2026-09-28; was the eye bar on Head/Merged).
	var eye := m.get_node_or_null("Root/Chest/Head/Face") as GeometryInstance3D
	_check(eye != null, "the Face node (eye shine) exists")
	m.call(&"play_snatch")
	_check(bool(m.call(&"is_snatching")), "play_snatch -> is_snatching")
	var saw_sack := false
	var eye_max := 0.0
	var reach_z := 0.0
	var frames := -1
	for i: int in 140:
		await process_frame
		if sack.visible:
			saw_sack = true
		if eye:
			eye_max = maxf(eye_max, FaceProbe.boost(eye))
		reach_z = maxf(reach_z, rt.position.z)
		if not bool(m.call(&"is_snatching")):
			frames = i + 1
			break
	print("snatch: %d frames, sack shown %s, eye boost max %.2f, lunge %.2f" % [frames, saw_sack, eye_max, reach_z])
	_check(frames >= 84 and frames <= 96, "snatch lasts ~1.5 s (%d frames)" % frames)
	_check(saw_sack, "the snatch yanks a sack over the shoulder")
	_check(not sack.visible, "sack hidden after the snatch when gameplay did not set carrying")
	_check(eye_max > 1.5, "the eyes flare while snatching (%.2f)" % eye_max)
	_check(reach_z > 0.2, "the snatch lunges in (%.2f)" % reach_z)
	# Snatch then gameplay takes the loot: the sack stays.
	m.call(&"play_snatch")
	await _frames(92)
	m.call(&"set_carrying", true)
	await _frames(3)
	_check(sack.visible, "snatch + set_carrying(true): the sack stays on the back")
	m.call(&"set_carrying", false)
	# Broken channel.
	m.call(&"play_snatch")
	await _frames(30)
	m.call(&"cancel_snatch")
	_check(not bool(m.call(&"is_snatching")), "cancel_snatch ends the channel")
	m.call(&"play_snatch")
	await _frames(10)
	m.call(&"set_moving", 3.0)
	_check(not bool(m.call(&"is_snatching")), "set_moving(>= 0.3) cancels the snatch")
	m.call(&"set_moving", 0.0)
	await _frames(20)

	# ---- Hit, statuses.
	m.call(&"play_hit")
	await _frames(20)
	_check(bool(m.call(&"set_status", &"haste", true)), "set_status haste -> true")
	_check(not bool(m.call(&"set_status", &"burn", true)), "set_status burn -> false")
	m.call(&"set_status", &"haste", false)

	# ---- Death (carrying: the sack goes, the LootSack of gameplay takes over) + revive.
	m.call(&"set_carrying", true)
	var got := [false]
	m.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	m.call(&"play_death")
	for i: int in 150:
		await process_frame
		if got[0]:
			break
	_check(got[0], "death_finished emitted")
	_check(not sack.visible, "the sack is gone after the death")
	m.call(&"revive")
	await _frames(4)
	_check(rt.position.length() < 0.05 and absf(rt.rotation.x) < 0.05, "revive resets the pose")
	_check(m.is_processing(), "revived model processes")
	_check(sack.visible, "revive shows the sack again while carrying")

	# ---- Hooks before _ready and the cached merge on a third instance.
	var early: Node3D = ps.instantiate()
	early.call(&"set_team_color", Color(0.85, 0.30, 0.12))
	early.call(&"set_moving", 3.0)
	early.call(&"play_hit")
	world.add_child(early)
	await _frames(10)
	_check(early.get_node_or_null("Root/Chest/Merged") != null, "third instance merged from the cache")
	mb.call(&"play_snatch")
	await _frames(100)
	_check(mb.get_node("Root/Chest/Sack").visible, "carrying Magpie keeps its sack through a snatch")
	world.queue_free()
	await _frames(2)
	_finish()


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()
