extends SceneTree
## Task 11.V2: the Wayfinder's class weapons (art/units/champions/wayfinder/, skills-rework.md 5).
## Run: $GODOT --headless --path . -s tests/test_11_v2.gd --fixed-fps 60 --quit-after 4000
## Checks: the bow is the tagged archetype weapon (hidden with each class, back with &""); the lantern pole, hat and
## pennant stay; budgets with each class (<= 26 authored, <= 16 draw instances and the same count for every class,
## 0 lights, <= 5 own materials); her own grips (fists at the glove centres, no weapon vertex inside the lantern pole /
## crook / crossbar, the staff crystal and the long weapons clear of the hat brim, the quiver right of the pole, the
## greatsword resting behind the right shoulder); Signal Flare with a class weapon (the left hand reaches the lantern,
## the flare shows in the hand, sparks off the lantern, then the overhand throw, prop gone after the release), Snare
## Line (the rope coil in the left hand, flung forward), Trailblaze (the class weapon stood upright over her head, the
## lantern blazes); get_beam_origin (bow / left hand / staff crystal); the release sparks follow bow <-> lantern;
## death / revive hide the prop. Prints "PASS 11.v2" or "FAIL 11.v2: <reasons>".

const TASK_ID := "11.v2"
const SCENE := "res://art/units/champions/wayfinder/wayfinder.tscn"
const OWN_DIR := "res://art/units/champions/wayfinder/"
const KIT := "res://art/units/champions/weapons/champion_weapon_kit.gd"
const CLASSES: Array[StringName] = [&"spear", &"sword_shield", &"two_hand", &"wizard"]
const MAIN: Dictionary = {&"spear": &"spear", &"sword_shield": &"sword", &"two_hand": &"greatsword", &"wizard": &"staff"}
const GRIP_R := Vector3(0.43, 0.93, 0.07)
const HAND_L := Vector3(-0.43, 0.93, 0.07)
const SHOULDER_L := Vector3(-0.34, 1.42, 0.0)
# lantern pole segments (model space, wayfinder.gd): shaft, crook, pennant crossbar
const POLE: Array = [[Vector3(-0.12, 0.90, -0.47), Vector3(-0.15, 2.50, -0.50), 0.052],
	[Vector3(-0.15, 2.50, -0.50), Vector3(-0.25, 2.566, -0.497), 0.04],
	[Vector3(-0.25, 2.566, -0.497), Vector3(-0.35, 2.50, -0.49), 0.035],
	[Vector3(-0.14, 2.285, -0.495), Vector3(0.16, 2.285, -0.495), 0.022]]

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D
var _kit: GDScript


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _wait(sec: float) -> void:
	for i: int in int(ceil(sec * 60.0)):
		await process_frame


func _spawn(at: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	_world.add_child(holder)
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	holder.add_child(m)
	return m


func _run() -> void:
	_kit = load(KIT)
	var m := _spawn(Vector3.ZERO)
	var m2 := _spawn(Vector3(4, 0, 0))
	m2.call(&"set_variant", 1)
	await _wait(0.2)
	await _check_tags_budgets(m)
	_check_grips(m)
	for cls: StringName in CLASSES:
		await _check_poses(m, cls)
	await _check_origins(m)
	await _check_death(m2)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


# ---------------------------------------------------------------- tags + budgets

func _check_tags_budgets(m: Node3D) -> void:
	var bow: Node3D = m.get_node("Root/Chest/ArmR/Bow")
	var prop: MeshInstance3D = m.get_node_or_null("Root/Chest/ArmL/HandProp")
	_check(bow.has_meta(&"weapon_classes") and PackedStringArray(bow.get_meta(&"weapon_classes")) == PackedStringArray([""]),
		"the bow is tagged as the archetype weapon")
	_check(prop != null and not prop.visible, "HandProp exists, hidden at rest")
	var authored: int = int(m.call(&"authored_mesh_count"))
	print("authored meshes: ", authored)
	_check(authored <= 26, "authored meshes <= 26 (got %d)" % authored)
	var base := _draw_instances(m)
	for cls: StringName in [&"spear", &"sword_shield", &"two_hand", &"wizard", &""]:
		m.call(&"set_weapon_class", cls, false)
		await _wait(0.1)
		var inst := _draw_instances(m)
		var own := 0
		for mat: Material in _materials(m):
			if mat.resource_path.begins_with(OWN_DIR):
				own += 1
		print("%-12s draw instances %d, own materials %d, bow visible %s" % [cls if cls != &"" else &"(archetype)", inst, own, bow.visible])
		_check(inst == base and inst <= 16, "%s: draw instances %d (archetype %d, <= 16)" % [cls, inst, base])
		_check(own <= 5, "%s: <= 5 own materials (got %d)" % [cls, own])
		_check(m.find_children("*", "Light3D", true, false).is_empty(), "%s: 0 lights" % cls)
		_check(bow.visible == (cls == &""), "%s: bow %s" % [cls, "shown" if cls == &"" else "hidden"])
		_check((m.get_node("Root/Chest/Lantern") as Node3D).visible, "%s: the lantern stays" % cls)
		_check(_pivot_has(m, "Root/Chest", "wayfinder_hat") and _pivot_has(m, "Root/Chest/Head", "wayfinder_hat"),
			"%s: pole, pack and hat stay" % cls)
		var spark: Node = m.get_node_or_null("Root/Chest/ArmR/Bow/ReleaseSparks") if cls == &"" \
			else m.get_node_or_null("Root/Chest/Lantern/ReleaseSparks")
		_check(spark != null, "%s: release sparks on the %s" % [cls, "bow" if cls == &"" else "lantern"])


# ---------------------------------------------------------------- grips

func _check_grips(m: Node3D) -> void:
	var gr: Transform3D = m.call(&"weapon_slot_xf", &"hand_r")
	var gl: Transform3D = m.call(&"weapon_slot_xf", &"hand_l")
	_check(gr.origin.is_equal_approx(GRIP_R) and gl.origin.is_equal_approx(HAND_L), "fists at the glove centres")
	for cls: StringName in CLASSES:
		var min_pole := INF
		var min_brim := INF
		for p: StringName in _kit.call(&"pieces_for", cls):
			if bool(_kit.call(&"is_hidden_by_default", p)):
				continue
			var g: Transform3D = m.call(&"weapon_grip_xf", p)
			var pts := _verts(_kit.call(&"piece_mesh", p))
			var aabb: AABB = (_kit.call(&"piece_mesh", p) as Mesh).get_aabb()
			var y := aabb.position.y
			while y < aabb.end.y:   # the long axis too: blades have few vertices along their length
				pts.append(Vector3(0, y, 0))
				y += 0.02
			for v: Vector3 in pts:
				var w := g * v
				for s: Array in POLE:
					min_pole = minf(min_pole, _seg_dist(w, s[0], s[1]) - float(s[2]))
				if w.y > 1.72 and w.y < 1.92:
					min_brim = minf(min_brim, Vector2(w.x, w.z - 0.02).length())
		print("%-12s clearance: lantern pole %.3f m, hat axis at brim height %.3f m" % [cls, min_pole, min_brim])
		_check(min_pole > 0.04, "%s: no weapon vertex in the lantern pole (%.3f)" % [cls, min_pole])
		_check(min_brim > 0.47, "%s: weapon clear of the hat brim (%.3f)" % [cls, min_brim])
	# per weapon: the read of skills-rework.md 5
	var tip_of := func(p: StringName) -> Vector3:
		return (m.call(&"weapon_grip_xf", p) as Transform3D) * (_kit.call(&"piece_tip", p) as Vector3)
	var spear: Vector3 = tip_of.call(&"spear")
	_check(spear.z > 1.0 and spear.y > 1.5, "spear tip forward and up (%s)" % spear)
	var sword: Vector3 = tip_of.call(&"sword")
	_check(sword.z > 0.6 and sword.y > 0.45 and sword.y < 0.9, "sword point forward, a little down (%s)" % sword)
	var gs: Vector3 = tip_of.call(&"greatsword")
	_check(gs.y > 2.2 and gs.z < -0.2 and gs.x > 0.8, "greatsword up, back and out past the right shoulder (%s)" % gs)
	var st: Vector3 = tip_of.call(&"staff")
	_check(st.y > 1.9 and st.x > 0.55, "staff crystal beside the hat (%s)" % st)
	var q: Transform3D = m.call(&"weapon_grip_xf", &"quiver")
	var qt: Vector3 = q * (_kit.call(&"piece_tip", &"quiver") as Vector3)
	_check(q.origin.x > 0.05 and qt.x > q.origin.x and q.origin.z < -0.5, "quiver behind the pack, leaning right (%s -> %s)" % [q.origin, qt])


# ---------------------------------------------------------------- the three archetype casts with a class weapon

func _check_poses(m: Node3D, cls: StringName) -> void:
	m.call(&"set_weapon_class", cls, false)
	await _wait(0.2)
	var prop: MeshInstance3D = m.get_node("Root/Chest/ArmL/HandProp")
	var lantern: MeshInstance3D = m.get_node("Root/Chest/Lantern")
	var spark: GPUParticles3D = m.get_node("Root/Chest/Lantern/ReleaseSparks")
	var arm_l: Node3D = m.get_node("Root/Chest/ArmL")
	var arm_r: Node3D = m.get_node("Root/Chest/ArmR")
	# ---- Signal Flare: reach the lantern, pull the flare, hurl it
	m.call(&"play_cast", &"flare_arrow")
	await _until(m, 0.30)
	var hand := m.to_local(arm_l.global_transform * (HAND_L - SHOULDER_L))
	var lamp := m.to_local(lantern.global_transform * Vector3(0, -0.30, 0))
	print("%-12s flare grab: hand %s, lantern glass %s (%.2f m)" % [cls, hand, lamp, hand.distance_to(lamp)])
	_check(hand.distance_to(lamp) < 0.35, "%s flare: the left hand reaches the lantern (%.2f m)" % [cls, hand.distance_to(lamp)])
	_check(prop.visible and _mesh_has(prop.mesh, "wayfinder_glow"),
		"%s flare: the burning flare is in the hand" % cls)
	_check(spark.emitting, "%s flare: sparks off the lantern at the grab" % cls)
	await _until(m, 0.53)
	hand = m.to_local(arm_l.global_transform * (HAND_L - SHOULDER_L))
	_check(hand.z > 0.2 and hand.y > 1.5, "%s flare: hurled overhand, forward and high (%s)" % [cls, hand])
	await _wait(0.1)
	_check(not prop.visible, "%s flare: gone from the hand after the release" % cls)
	await _wait(0.5)
	_check(m.get(&"_action") == &"", "%s flare: finished" % cls)
	# ---- Snare Line: rope coil in the left hand, flung underarm
	m.call(&"play_cast", &"snare_line")
	await _until(m, 0.12)
	_check(prop.visible and _mesh_has(prop.mesh, "wayfinder_leather") and not _mesh_has(prop.mesh, "wayfinder_glow"),
		"%s snare: the rope coil in the hand" % cls)
	await _until(m, 0.31)
	_check(arm_l.rotation.x < -1.2, "%s snare: flung forward (ArmL %.2f)" % [cls, arm_l.rotation.x])
	await _wait(0.1)
	_check(not prop.visible, "%s snare: the coil has left the hand" % cls)
	await _wait(0.5)
	_check(m.get(&"_action") == &"", "%s snare: finished" % cls)
	# ---- Trailblaze: the class weapon raised to the sky, the lantern blazes
	m.call(&"play_cast", &"trailblaze")
	await _until(m, 0.6)
	var piece: StringName = MAIN[cls]
	var g: Transform3D = m.call(&"weapon_grip_xf", piece)
	var up := (m.global_transform.basis.inverse() * arm_r.global_transform.basis * g.basis.y).normalized()
	var tip: Variant = m.call(&"get_weapon_tip")
	var glow: float = float(lantern.get_instance_shader_parameter(&"glow_boost"))
	print("%-12s trailblaze: weapon axis %s, tip %s, lantern glow %.2f" % [cls, up, m.to_local(tip), glow])
	_check(up.y > 0.9, "%s trailblaze: the weapon stands upright (%s)" % [cls, up])
	_check(tip is Vector3 and m.to_local(tip).y > 2.3, "%s trailblaze: the weapon raised high" % cls)
	_check(glow > 3.5, "%s trailblaze: the lantern blazes (%.2f)" % [cls, glow])
	await _wait(0.7)
	_check(m.get(&"_action") == &"", "%s trailblaze: finished" % cls)
	# ---- the class attack still plays (kit style); no hand prop
	m.call(&"play_attack")
	await _wait(0.12)
	_check(not prop.visible and m.get(&"_action") == &"attack", "%s: class attack plays, no hand prop" % cls)
	await _wait(0.9)


# ---------------------------------------------------------------- shot / throw origin

func _check_origins(m: Node3D) -> void:
	m.call(&"set_weapon_class", &"", false)
	await _wait(0.1)
	var bow: Node3D = m.get_node("Root/Chest/ArmR/Bow")
	var o: Vector3 = m.call(&"get_beam_origin")
	_check(o.distance_to(bow.global_position) < 0.3, "archetype: shots leave from the bow (%s)" % o)
	m.call(&"set_weapon_class", &"wizard", false)
	await _wait(0.1)
	o = m.call(&"get_beam_origin")
	_check(o.distance_to(m.call(&"get_weapon_tip")) < 0.001, "wizard: bolts leave from the staff crystal")
	m.call(&"set_weapon_class", &"spear", false)
	await _wait(0.1)
	o = m.call(&"get_beam_origin")
	_check(m.to_local(o).distance_to(HAND_L) < 0.12, "spear: javelin / flare leave the left hand (%s)" % m.to_local(o))
	m.call(&"set_weapon_class", &"", false)
	await _wait(0.1)
	_check(m.get_node_or_null("Root/Chest/ArmR/Bow/ReleaseSparks") != null, "sparks back on the bow with &\"\"")
	m.call(&"play_cast", &"flare_arrow")
	await _wait(0.3)
	_check((m.get_node("Root/Chest/ArmR") as Node3D).rotation.x < -1.2 and not (m.get_node("Root/Chest/ArmL/HandProp") as Node3D).visible,
		"archetype Signal Flare is still the bow shot")
	await _wait(0.9)


func _check_death(m: Node3D) -> void:
	m.call(&"set_weapon_class", &"two_hand", false)
	await _wait(0.1)
	var prop: Node3D = m.get_node("Root/Chest/ArmL/HandProp")
	m.call(&"play_cast", &"flare_arrow")
	await _until(m, 0.35)
	_check(prop.visible, "variant B: flare in the hand")
	var got: Array = [false]
	m.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	m.call(&"play_death")
	await _wait(0.1)
	_check(not prop.visible, "death hides the hand prop")
	await _wait(1.2)
	_check(got[0], "death_finished with a class weapon")
	m.call(&"revive")
	await _wait(0.2)
	_check(not prop.visible and m.call(&"weapon_class") == &"two_hand", "revive: class kept, prop hidden")


# ---------------------------------------------------------------- helpers

func _until(m: Node3D, t: float) -> void:
	var guard := 0
	while float(m.get(&"_action_t")) < t and m.get(&"_action") != &"" and guard < 240:
		await process_frame
		guard += 1


func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _verts(mesh: Mesh) -> PackedVector3Array:
	var out := PackedVector3Array()
	for s: int in mesh.get_surface_count():
		out.append_array(mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX])
	return out


func _mesh_has(mesh: Mesh, mat_part: String) -> bool:
	if mesh == null:
		return false
	# palette-aware (ChampionPalette B8 merge, 2026-09-30): folded parts are found per vertex by their source material
	return ChampionPalette.mesh_has(mesh, mat_part)


func _pivot_has(m: Node3D, pivot: String, mat_part: String) -> bool:
	var node := m.get_node_or_null(pivot + "/Merged") as MeshInstance3D
	return node != null and _mesh_has(node.mesh, mat_part)


func _draw_instances(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		if g is MeshInstance3D and (g as MeshInstance3D).mesh == null:
			continue
		c += 1
	return c


func _materials(n: Node) -> Array:
	var out: Array = []
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		if mi.material_override:
			if not (mi.material_override in out):
				out.append(mi.material_override)
			continue
		for s: int in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s)
			if mat == null:
				mat = mi.mesh.surface_get_material(s)
			if mat and not (mat in out):
				out.append(mat)
	return out
