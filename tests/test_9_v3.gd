extends SceneTree
## Task 9.V3: the Coin-Cutter champion model (art/units/champions/coin_cutter/coin_cutter.tscn).
## Run:  $GODOT --headless --path . -s tests/test_9_v3.gd --fixed-fps 60 --quit-after 3000
## Checks: headless instantiation without errors; budgets (authored meshes <= 26 with the blob, draw instances after
## the merge <= 16, 0 lights, <= 5 materials, all from the champion's own folder, except the kit's shared blob;
## vertices <= 4 000 = the wizards' level, champions.md 4.6 "budget: as a wizard");
## size (hood top at body_height 1.7 +- 25 %, footprint within radius 0.45 x 1.4 at rest); every hook callable:
## set_team_color (sash + pennant only), set_variant (one toggled node), set_moving, play_attack (slash2),
## play_cast (cutpurse, smoke_pouch, marked_for_coin, unknown id), play_hit, play_level_up, set_status,
## play_death + death_finished, revive. Prints PASS 9.v3 / FAIL 9.v3: <reason>.

const TASK_ID := "9.v3"
const SCENE := "res://art/units/champions/coin_cutter/coin_cutter.tscn"
const OWN_DIR := "res://art/units/champions/coin_cutter/"
const BLOB_MAT := "res://art/units/kit/materials/unit_shadow_blob.tres"
## The FaceKit's shared face material (faces pass 2026-09-28: every unit has a Face node, 1 draw call).
const FACE_MAT := "res://art/units/kit/face/unit_face.tres"
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


## Waits until m._action is empty (the action finished); returns the frames waited (-1 = timed out).
func _until_idle(m: Node, limit: int) -> int:
	for i: int in limit:
		await process_frame
		if StringName(m.get(&"_action")) == &"":
			return i
	return -1


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
	_check(authored > 0 and authored <= 26, "authored meshes %d <= 26" % authored)

	# ---- Two instances in the tree (variant A and B): the second uses the cached merge.
	var world := Node3D.new()
	root.add_child(world)
	var holders: Array[Node3D] = []
	var models: Array = []
	for i: int in 2:
		var h := Node3D.new()
		h.position = Vector3(3.0 * i, 0, 0)
		world.add_child(h)
		var m: Node3D = ps.instantiate()
		m.call(&"set_variant", i)          # before _ready: cached and applied
		h.add_child(m)
		holders.append(h)
		models.append(m)
	await _frames(3)
	var m: Node3D = models[0]
	var mb: Node3D = models[1]

	# ---- Draw instances, lights, materials.
	for k: int in 2:
		var mm: Node3D = models[k]
		var inst := 0
		for n: Node in mm.find_children("*", "GeometryInstance3D", true, false):
			inst += 1
		print("instance %d: draw instances %d" % [k, inst])
		_check(inst <= 16, "draw instances %d <= 16" % inst)
		_check(mm.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
	var mats := {}
	var verts := 0
	for n: Node in m.find_children("*", "GeometryInstance3D", true, false):
		if n is GPUParticles3D:
			continue
		var gi := n as GeometryInstance3D
		# B8 merge (2026-09-30): the ChampionPalette material stands for its folded sources (unfold)
		for om: Material in ChampionPalette.unfold([gi.material_override] if gi.material_override else []):
			mats[om.resource_path] = true
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
			var mesh := (gi as MeshInstance3D).mesh
			for s: int in mesh.get_surface_count():
				var mat := mesh.surface_get_material(s)
				if mat:
					for um: Material in ChampionPalette.unfold([mat]):
						mats[um.resource_path] = true
				verts += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var own := 0
	for p: String in mats:
		if p.begins_with(OWN_DIR):
			own += 1
		else:
			_check(p == BLOB_MAT or p == FACE_MAT, "material outside the champion folder: '%s'" % p)
	print("materials: ", own, " own + ", mats.size() - own, " shared (", ", ".join(PackedStringArray(mats.keys())), "); vertices ", verts)
	_check(own <= 5, "materials %d <= 5" % own)
	# Wizard level + the face (faces pass 2026-09-28: measured 4203 with the Face node; small margin).
	_check(verts <= 4350, "vertices %d <= 4350 (wizard level 4000 + face)" % verts)

	# ---- Exports and size.
	_check(is_equal_approx(float(m.get(&"body_height")), 1.7), "body_height 1.7")
	_check(StringName(m.get(&"attack_style")) == &"slash2", "attack_style slash2")
	_check(float(m.get(&"attack_windup")) == 0.0, "melee: attack_windup 0")
	var head_merged := m.get_node_or_null("Root/Chest/Head/Merged") as MeshInstance3D
	_check(head_merged != null, "Head merged")
	if head_merged:
		var top := (head_merged.global_transform * head_merged.mesh.get_aabb()).end.y
		print("hood top y: %.2f" % top)
		_check(top >= 1.7 * 0.75 and top <= 1.7 * 1.25, "hood top %.2f within 1.7 +- 25 %%" % top)
	var reach := 0.0
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not mi.is_visible_in_tree() or mi.name == "Shadow" or mi.mesh == null:
			continue
		var xf: Transform3D = m.global_transform.affine_inverse() * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var w := xf * v
				reach = maxf(reach, Vector2(w.x, w.z).length())
	print("footprint reach at rest: %.2f" % reach)
	_check(reach <= 0.45 * 1.4, "footprint %.2f within radius x 1.4 = 0.63" % reach)

	# ---- Variant toggle: one node.
	var vb := m.get_node_or_null("Root/Chest/Head/VariantB") as Node3D
	var vb2 := mb.get_node_or_null("Root/Chest/Head/VariantB") as Node3D
	_check(vb != null and not vb.visible, "variant A hides VariantB")
	_check(vb2 != null and vb2.visible, "variant B shows VariantB (set before _ready)")
	m.call(&"set_variant", 1)
	_check(vb != null and vb.visible, "set_variant(1) shows VariantB")
	m.call(&"set_variant", 0)
	_check(vb != null and not vb.visible, "set_variant(0) hides VariantB")

	# ---- Team colour: only the pennon surfaces change (sash + pennant on the merged Chest).
	var chest := m.get_node_or_null("Root/Chest/Merged") as MeshInstance3D
	m.call(&"set_team_color", Color(0.85, 0.30, 0.12))   # = kingdom_color: no-op
	var before := 0
	if chest:
		for s: int in chest.mesh.get_surface_count():
			if chest.get_surface_override_material(s) != null:
				before += 1
	_check(before == 0, "set_team_color(kingdom colour) is a no-op")
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
			if src and src.resource_path.ends_with("coin_cutter_pennon.tres") \
					and (o as ShaderMaterial).get_shader_parameter(&"cloth_color").is_equal_approx(SHADOW):
				recoloured += 1
			else:
				wrong += 1
	print("team colour: %d pennon surfaces recoloured, %d other" % [recoloured, wrong])
	_check(recoloured >= 1 and wrong == 0, "set_team_color recolours the sash / pennant only")

	# ---- Walk.
	m.call(&"set_moving", 5.6)
	var leg := m.get_node("Root/Hips/LegL") as Node3D
	var swing := 0.0
	for i: int in 40:
		await process_frame
		swing = maxf(swing, absf(leg.rotation.x))
	_check(swing > 0.2, "walk swings the legs (%.2f rad)" % swing)
	m.call(&"set_moving", 0.0)
	await _frames(20)

	# ---- Attack slash2.
	var arm_r := m.get_node("Root/Chest/ArmR") as Node3D
	var arm_l := m.get_node("Root/Chest/ArmL") as Node3D
	m.call(&"play_attack")
	var max_r := 0.0
	var max_l := 0.0
	var done := -1
	for i: int in 60:
		await process_frame
		max_r = maxf(max_r, absf(arm_r.rotation.z))
		max_l = maxf(max_l, absf(arm_l.rotation.z))
		if StringName(m.get(&"_action")) == &"":
			done = i
			break
	_check(done >= 0, "slash2 ends")
	_check(max_r > 0.3 and max_l > 0.3, "slash2 cuts with both knives (%.2f / %.2f rad)" % [max_r, max_l])

	# ---- Casts.
	var pouch := m.get_node_or_null("Root/Chest/ArmL/Pouch") as Node3D
	var coin := m.get_node_or_null("Fx/FlipCoin") as Node3D
	_check(pouch != null and coin != null, "pouch and coin nodes")
	for id: StringName in [&"cutpurse", &"smoke_pouch", &"marked_for_coin", &"some_unknown_id"]:
		m.call(&"play_cast", id)
		var saw_pouch := false
		var coin_top := -99.0
		var root_z := 0.0
		var ok := false
		for i: int in 120:
			await process_frame
			if pouch and pouch.visible:
				saw_pouch = true
			if coin and coin.visible:
				coin_top = maxf(coin_top, coin.position.y)
			root_z = maxf(root_z, (m.get_node("Root") as Node3D).position.z)
			if StringName(m.get(&"_action")) == &"":
				ok = true
				break
		print("cast %s: ended %s, pouch %s, coin top %.2f, lunge %.2f" % [id, ok, saw_pouch, coin_top, root_z])
		_check(ok, "cast %s ends" % id)
		match id:
			&"cutpurse", &"some_unknown_id":
				_check(root_z > 0.3, "%s lunges forward" % id)
			&"smoke_pouch":
				_check(saw_pouch, "smoke_pouch shows the pouch")
			&"marked_for_coin":
				_check(coin_top > 1.6, "marked_for_coin flips the coin up (top %.2f)" % coin_top)
		_check(pouch == null or not pouch.visible, "pouch hidden after %s" % id)
		_check(coin == null or not coin.visible, "coin hidden after %s" % id)

	# ---- Hit, level-up, statuses, veterancy no-op.
	m.call(&"play_hit")
	await _frames(20)
	m.call(&"play_level_up")
	await _frames(40)
	_check(bool(m.call(&"set_status", &"haste", true)), "set_status haste -> true")
	_check(bool(m.call(&"set_status", &"shroud", true)), "set_status shroud -> true")
	_check(not bool(m.call(&"set_status", &"burn", true)), "set_status burn -> false")
	m.call(&"set_status", &"haste", false)
	m.call(&"set_status", &"shroud", false)

	# ---- Death + revive.
	var got := [false]
	m.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	m.call(&"play_death")
	for i: int in 150:
		await process_frame
		if got[0]:
			break
	_check(got[0], "death_finished emitted")
	m.call(&"revive")
	await _frames(4)
	var r := m.get_node("Root") as Node3D
	_check(r.position.length() < 0.05 and absf(r.rotation.x) < 0.05, "revive resets the pose")
	_check(m.is_processing(), "revived model processes")

	# ---- Hooks before _ready (cached and applied), and the second (cached-merge) instance still animates.
	var early: Node3D = ps.instantiate()
	early.call(&"set_team_color", SHADOW)
	early.call(&"set_moving", 3.0)
	early.call(&"play_hit")
	world.add_child(early)
	await _frames(10)
	_check(early.get_node_or_null("Root/Chest/Merged") != null, "third instance merged from the cache")
	mb.call(&"play_cast", &"marked_for_coin")
	await _until_idle(mb, 150)
	world.queue_free()
	await _frames(2)
	_finish()


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()
