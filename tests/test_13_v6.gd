extends SceneTree
## Task 13.V6: the Roan Courser, the neutral champion mount (art/units/mounts/roan_courser/roan_courser.tscn), a
## MountModel with saddlebags, a bedroll and a team saddle-cloth only (no barding, no glow).
## Run: $GODOT --headless --path . -s tests/test_13_v6.gd --fixed-fps 60 --quit-after 3000
## Checks: headless instantiation (2 instances: build + cache), class, pivots + Seat, hooks, section 10 mount budget
## (<= 12 authored meshes incl. the blob, <= 8 draw instances, 0 lights, 0 particles), vertices, materials (own <= 3
## in the folder, the rest from the kit / champion weapon palettes), the read (team cloth only on the body, bedroll
## wool, chestnut head, white blaze, no glow, nothing of the Dusk Steed), size (stocky: lower and wider than a
## riding horse), seat, walk vs gallop, hit flash + flinch, play_charge (head drops, lunge, toss), graze fidget,
## set_barded (accepted, no-op: same meshes and draw instances, also before _ready), team colour (cloth only,
## restores), the kit slot audit (KITFIX rules), death (rolls onto its side, lies on the ground, death_finished),
## revive, transparency fade.
## Prints "PASS 13.v6" or "FAIL 13.v6: <reasons>".

const TASK_ID := "13.v6"
const SCENE := "res://art/units/mounts/roan_courser/roan_courser.tscn"
const OWN_DIR := "res://art/units/mounts/roan_courser/"
## Faces pass 2026-09-28: the shared FaceKit face material (eyes / brows / lips, 1 draw call) + glow probe.
const FaceProbe := preload("res://tests/face_probe.gd")
const KITFIX := "res://art/units/kit/tools/kitfix_glow_check.gd"

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var cam := Camera3D.new()   # tier 0 (close) so the full animation runs
	cam.position = Vector3(0, 6, 10)
	_world.add_child(cam)
	cam.look_at_from_position(cam.position, Vector3.ZERO)
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _wait(sec: float) -> void:
	for i: int in int(ceil(sec * 60.0)):
		await process_frame


func _spawn(at: Vector3, barded_before_ready: bool = false) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	_world.add_child(holder)
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	if barded_before_ready:
		m.call(&"set_barded", true)
	holder.add_child(m)
	return m


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene exists")
	var a := _spawn(Vector3(0, 0, 0))
	var b := _spawn(Vector3(4, 0, 0))
	await _wait(0.2)
	_check(a is MountModel and a is CharacterModel, "extends MountModel (a CharacterModel)")
	# ---- pivots + hooks
	for p: String in ["Root", "Root/Mount", "Root/Mount/Head", "Root/Mount/LegFL", "Root/Mount/LegFR", "Root/Mount/LegBL",
			"Root/Mount/LegBR", "Root/Mount/Tail", "Root/Mount/Seat", "Fx", "Shadow"]:
		_check(a.get_node_or_null(p) != null, "node %s" % p)
	for h: String in ["set_moving", "play_hit", "play_death", "set_team_color", "set_barded", "is_barded", "play_charge",
			"seat_transform", "seat_node", "gait_phase", "gallop_blend", "is_galloping", "play_fidget", "authored_mesh_count",
			"play_attack", "play_cast", "play_level_up", "set_veterancy", "set_status", "revive"]:
		_check(a.has_method(h), "hook %s" % h)
	_check(a.has_signal(&"death_finished"), "signal death_finished")
	# ---- budgets
	var authored_a: int = int(a.call(&"authored_mesh_count"))
	var authored_b: int = int(b.call(&"authored_mesh_count"))
	print("authored meshes: %d / %d" % [authored_a, authored_b])
	_check(authored_a == authored_b, "authored count is the same for the cached instance")
	_check(authored_a >= 6 and authored_a <= 12, "authored meshes <= 12 (got %d)" % authored_a)
	var plain_inst := _draw_instances(b)
	var plain_verts := _vertices(b)
	print("plain: draw instances %d, vertices %d, lights %d, particles %d" % [plain_inst, plain_verts,
		b.find_children("*", "Light3D", true, false).size(), b.find_children("*", "GPUParticles3D", true, false).size()])
	_check(plain_inst <= 8, "draw instances <= 8 (got %d)" % plain_inst)
	# 5000 + the face (faces pass 2026-09-28: measured 5232 with the face in the head; small margin).
	_check(plain_verts <= 5400, "vertices <= 5400 = 5000 + face (got %d)" % plain_verts)
	_check(b.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
	_check(b.find_children("*", "GPUParticles3D", true, false).is_empty(), "0 particle systems")
	for g: Node in b.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh:
			print("  %s: %d surfaces, %d vertices, shadow %s" % [b.get_path_to(mi), mi.mesh.get_surface_count(),
				_mesh_verts(mi.mesh), mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF])
	# ---- materials: own <= 3, the rest from the kit / champion weapon palettes, no built-in material
	var own: Array = []
	var shared: Array = []
	for mat: Material in _materials(b):
		var path := mat.resource_path
		if path.begins_with(OWN_DIR):
			own.append(path.get_file())
		else:
			shared.append(path.get_file() if path != "" else "<built-in>")
			_check(path.begins_with("res://art/units/kit/materials/") or path.begins_with("res://art/units/champions/weapons/materials/")
				or FaceProbe.is_face_mat(mat), "material %s is a kit / champion palette entry (or the face)" % path)
	print("own materials (%d): %s" % [own.size(), ", ".join(PackedStringArray(own))])
	print("palette materials (%d): %s" % [shared.size(), ", ".join(PackedStringArray(shared))])
	_check(own.size() <= 3, "<= 3 own materials")
	# ---- the read
	var body_b := b.get_node("Root/Mount/Merged") as MeshInstance3D
	var head_b := b.get_node("Root/Mount/Head/Merged") as MeshInstance3D
	_check(_has_mat(body_b.mesh, "fire_cloth.tres") and _has_mat(body_b.mesh, "fire_cloth_dark.tres"), "team saddle-cloth + dark hem")
	_check(_mat_verts(body_b.mesh, "roan_courser_wool.tres") > 40, "cream bedroll on the body")
	_check(_has_mat(body_b.mesh, "weapon_leather.tres") and _has_mat(body_b.mesh, "weapon_brass.tres"), "leather saddlebags, brass buckles")
	_check(_has_mat(head_b.mesh, "roan_courser_chestnut.tres") and _has_mat(head_b.mesh, "shadow_bone.tres"), "chestnut head with a white blaze")
	_check(_has_mat(head_b.mesh, "fire_fur.tres"), "dark chestnut mane")
	var team_elsewhere := false
	for path: String in ["Root/Mount/Head/Merged", "Root/Mount/LegFL/Merged", "Root/Mount/LegBR/Merged", "Root/Mount/Tail/Merged"]:
		var mi := b.get_node(path) as MeshInstance3D
		for s: int in mi.mesh.get_surface_count():
			var nm := mi.mesh.surface_get_material(s).resource_path.get_file().get_basename()
			if nm.ends_with("_cloth") or nm.ends_with("_cloth_dark") or nm.ends_with("_cape") or nm.ends_with("_pennon"):
				team_elsewhere = true
	_check(not team_elsewhere, "team colour on the saddle-cloth only")
	for mat: Material in _materials(b):
		_check(not ("dusk" in mat.resource_path or "shadow_glow" in mat.resource_path), "nothing of the Dusk Steed")
		if mat is ShaderMaterial:
			_check(not ((mat as ShaderMaterial).shader.resource_path.ends_with("unit_glow.gdshader")), "no glow material (%s)" % mat.resource_path)
	# The kit drives glow_boost on the face's node too (the shared face shader declares it, faces pass 2026-09-28):
	# only the face rig / face carriers may be glow nodes, and the courser's painted eyes have no glowing vertex.
	var glow_ok := not FaceProbe.glows(b)
	for gn: GeometryInstance3D in (b.get(&"_glow_nodes") as Array):
		glow_ok = glow_ok and (gn is FaceRig or not FaceProbe.face_surfaces(gn).is_empty())
		print("glow node %s (FaceRig %s)" % [b.get_path_to(gn), gn is FaceRig])
	_check(glow_ok, "no glow points (the face's eyes painted, not glowing)")
	# ---- size (rest): a stocky cob
	var box := _aabb(b, b.get_node("Root"))
	print("rest AABB y %.2f..%.2f, x %.2f..%.2f, z %.2f..%.2f" % [box.position.y, box.end.y, box.position.x, box.end.x,
		box.position.z, box.end.z])
	# 1.5 cm: the hooves sit ~1 cm into the ground and the sampled breath (idle phase from the instance id) moved the
	# lowest point between -0.0099 and -0.0101 with unrelated code changes (2026-10-02).
	_check(box.position.y >= -0.015, "nothing below the ground at rest (%.4f)" % box.position.y)
	_check(box.end.y >= 1.9 and box.end.y <= 2.3, "ear tips 1.9-2.3 m (%.2f)" % box.end.y)
	_check(box.size.z >= 2.3 and box.size.z <= 2.9, "length 2.3-2.9 m (%.2f)" % box.size.z)
	_check(box.size.x >= 0.85 and box.size.x <= 1.2, "width 0.85-1.2 m with the bags (%.2f)" % box.size.x)
	var body_box := (body_b.transform * body_b.mesh.get_aabb())
	print("body merge AABB (Mount space) ", body_box)
	# ---- seat
	var seat: Transform3D = b.call(&"seat_transform")
	var seat_node: Node3D = b.call(&"seat_node")
	var rel := b.global_transform.affine_inverse() * seat_node.global_transform
	print("seat (model space) ", seat.origin)
	_check(seat.origin.is_equal_approx(rel.origin), "seat_transform = the Seat marker in model space")
	_check(absf(seat.origin.x) < 0.01 and seat.origin.y > 1.4 and seat.origin.y < 1.6 and absf(seat.origin.z) < 0.3,
		"seat on the saddle, lower than a riding horse (%s)" % seat.origin)
	_check(seat.basis.z.dot(Vector3.BACK) > 0.95, "seat faces +Z")
	# ---- walk vs gallop
	var leg: Node3D = a.get_node("Root/Mount/LegFL")
	var root_n: Node3D = a.get_node("Root")
	var head: Node3D = a.get_node("Root/Mount/Head")
	var tail: Node3D = a.get_node("Root/Mount/Tail")
	a.call(&"set_moving", 1.8)
	var max_leg := 0.0
	var max_g := 0.0
	for i: int in 60:
		await process_frame
		max_leg = maxf(max_leg, absf(leg.rotation.x))
		max_g = maxf(max_g, float(a.call(&"gallop_blend")))
	print("walk: leg swing %.1f deg, gallop blend %.2f" % [rad_to_deg(max_leg), max_g])
	_check(max_leg > deg_to_rad(12.0), "the legs swing in the walk")
	_check(max_g < 0.3, "no gallop at walking speed")
	a.call(&"set_moving", 6.0)
	await _wait(0.8)
	var ymin := 99.0
	var ymax := -99.0
	var seat_min := 99.0
	var seat_max := -99.0
	max_leg = 0.0
	var tail_x := 0.0
	var wraps := 0
	var last_p := float(a.call(&"gait_phase"))
	for i: int in 60:
		await process_frame
		ymin = minf(ymin, root_n.position.y)
		ymax = maxf(ymax, root_n.position.y)
		var st: Transform3D = a.call(&"seat_transform")
		seat_min = minf(seat_min, st.origin.y)
		seat_max = maxf(seat_max, st.origin.y)
		max_leg = maxf(max_leg, absf(leg.rotation.x))
		tail_x += tail.rotation.x / 60.0
		var p := float(a.call(&"gait_phase"))
		if p < last_p:
			wraps += 1
		last_p = p
	print("gallop: blend %.2f, bounce %.3f, seat bob %.3f, leg swing %.1f deg, strides/s %d, tail lift %.1f deg" % [
		float(a.call(&"gallop_blend")), ymax - ymin, seat_max - seat_min, rad_to_deg(max_leg), wraps, rad_to_deg(tail_x)])
	_check(bool(a.call(&"is_galloping")), "gallops at 6 m/s")
	_check(ymax - ymin > 0.03, "gallop bounce")
	_check(seat_max - seat_min > 0.03, "the seat bobs with the gallop (rider sync)")
	_check(max_leg > deg_to_rad(22.0), "gallop leg swing > 22 deg")
	_check(wraps >= 1 and wraps <= 3, "1-3 strides per second (%d)" % wraps)
	_check(tail_x > deg_to_rad(10.0), "tail lifted in the gallop")
	a.call(&"set_moving", 0.0)
	await _wait(0.8)
	_check(absf(leg.rotation.x) < deg_to_rad(3.0), "legs back at rest after stopping")
	_check(float(a.call(&"gallop_blend")) < 0.2, "gallop blend falls when stopped")
	# ---- hit
	var body_mi := a.get_node("Root/Mount/Merged") as MeshInstance3D
	a.call(&"play_hit")
	await _wait(0.05)
	var flash := float(body_mi.get_instance_shader_parameter(&"hit_flash"))
	var leg_flash := float((a.get_node("Root/Mount/LegFL/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	print("hit: body flash %.2f, leg flash %.2f, root z %.3f" % [flash, leg_flash, root_n.position.z])
	_check(flash > 0.3 and leg_flash > 0.3, "the whole horse flashes on a hit")
	_check(root_n.position.z < -0.03, "hit flinch pushes back")
	await _wait(0.5)
	# ---- charge
	a.call(&"play_charge")
	await _wait(0.10)
	var hx := head.rotation.x
	await _wait(0.05)
	var rz := root_n.position.z
	await _wait(0.15)
	var hx_toss := head.rotation.x
	print("charge: head %.1f deg, lunge z %.2f, toss %.1f deg" % [rad_to_deg(hx), rz, rad_to_deg(hx_toss)])
	_check(a.get(&"_action") == &"charge", "charge action running")
	_check(hx > deg_to_rad(10.0), "the head drops on the charge")
	_check(rz > 0.2, "the charge lunges forward")
	_check(hx_toss < deg_to_rad(-8.0), "head toss after the strike")
	await _wait(0.8)
	_check(a.get(&"_action") == &"", "charge finished")
	a.call(&"play_attack")
	await _wait(0.6)
	_check(a.get(&"_action") == &"", "mount_toss attack finished")
	a.call(&"play_cast", &"fireball")
	await _wait(0.7)
	# graze fidget: head down to the grass, snort on the shake, moving cancels it
	a.call(&"play_fidget")
	await _wait(1.2)
	var graze := head.rotation.x
	_check(a.get(&"_action") == &"fidget", "fidget runs")
	await _wait(1.5)
	var after := head.rotation.x
	print("graze: head %.1f deg, lifted %.1f deg" % [rad_to_deg(graze), rad_to_deg(after)])
	_check(graze > deg_to_rad(40.0), "graze: the neck drops to the grass")
	_check(after < graze - deg_to_rad(30.0), "graze: the head comes back up")
	await _wait(0.8)
	_check(a.get(&"_action") == &"", "graze finished")
	a.call(&"play_fidget")
	await _wait(0.3)
	a.call(&"set_moving", 2.0)
	await _wait(0.1)
	_check(a.get(&"_action") == &"", "moving cancels the fidget")
	a.call(&"set_moving", 0.0)
	await _wait(0.4)
	# ---- barding: none (accepted, no-op)
	var plain_mesh: Mesh = body_mi.mesh
	var meshes_before := _mesh_list(b)
	b.call(&"set_barded", true)
	await process_frame
	_check(bool(b.call(&"is_barded")), "set_barded accepted (is_barded)")
	_check(_mesh_list(b) == meshes_before, "no barding: the meshes are unchanged")
	_check(_draw_instances(b) == plain_inst, "no barding: same draw instances")
	b.call(&"set_barded", false)
	var c := _spawn(Vector3(8, 0, 0), true)
	await _wait(0.1)
	_check((c.get_node("Root/Mount/Merged") as MeshInstance3D).mesh == plain_mesh, "set_barded before _ready: still the plain mesh")
	# ---- team colour: cloth only, restores
	var body_b2 := b.get_node("Root/Mount/Merged") as MeshInstance3D
	var blue := Color(0.45, 0.75, 0.95)
	b.call(&"set_team_color", blue)
	await process_frame
	var cloth_col := _cloth_colors(body_b2)
	print("team colour on the body: ", cloth_col)
	_check(cloth_col.size() == 2, "cloth + cloth_dark recoloured")
	_check(blue in cloth_col, "saddle-cloth takes the team colour")
	var others_ok := true
	for s: int in body_b2.mesh.get_surface_count():
		var ov := body_b2.get_surface_override_material(s)
		var base := body_b2.mesh.surface_get_material(s)
		if ov and not (base.resource_path.ends_with("_cloth.tres") or base.resource_path.ends_with("_cloth_dark.tres")):
			others_ok = false
	_check(others_ok, "only cloth surfaces are recoloured")
	b.call(&"set_team_color", Color(0.85, 0.30, 0.12))
	await process_frame
	var any_override := false
	for s: int in body_b2.mesh.get_surface_count():
		if body_b2.get_surface_override_material(s) != null:
			any_override = true
	_check(not any_override, "the default colour restores the scene's own cloth")
	# ---- kit slot audit (KITFIX rules)
	var K: GDScript = load(KITFIX)
	var slots: Dictionary = CharacterModel.INSTANCE_SLOTS
	var collisions := 0
	for mm: Node3D in [a, c]:
		for g: Node in mm.find_children("*", "GeometryInstance3D", true, false):
			var gi := g as GeometryInstance3D
			if gi == mm.get(&"_shadow"):
				continue
			var by_slot: Dictionary = {}
			var names: Array[String] = []
			for mat: Material in mm.call(&"_materials_of", gi):
				if not mat is ShaderMaterial:
					continue
				for u: Array in K.call(&"_instance_uniforms", (mat as ShaderMaterial).shader):
					var nm: String = u[0]
					if names.has(nm):
						continue
					names.append(nm)
					if slots.has(nm) and int(u[1]) != int(slots[nm]):
						_check(false, "%s on slot %d (map %d)" % [nm, u[1], slots[nm]])
					if by_slot.has(u[1]):
						collisions += 1
					by_slot[u[1]] = nm
			if names.has("hit_flash"):
				_check((mm.get(&"_flash_all_targets") as Array).has(gi), "%s flashed by the kit" % mm.get_path_to(gi))
	print("slot collisions: ", collisions)
	_check(collisions == 0, "no instance-uniform slot collision")
	# ---- death: rolls onto its side, lies on the ground, death_finished; revive
	var got: Array = [false]
	a.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	a.call(&"set_moving", 6.0)
	await _wait(0.3)
	a.call(&"play_death")
	await _wait(1.05)
	var roll_end := root_n.rotation.z
	var lying := _vert_bounds(a, a.get_parent() as Node3D)
	print("death: roll %.1f deg, lying AABB y %.2f..%.2f, finished %s" % [rad_to_deg(roll_end), lying.position.y,
		lying.end.y, got[0]])
	_check(absf(roll_end) > deg_to_rad(75.0), "falls onto its side")
	_check(lying.position.y > -0.2, "lies on the ground, not sunk (%.2f)" % lying.position.y)
	_check(lying.end.y < 1.4, "lying low (%.2f)" % lying.end.y)
	_check(got[0], "death_finished within 1.05 s")
	a.call(&"revive")
	await _wait(0.3)
	_check(absf(root_n.rotation.z) < 0.03 and absf(root_n.position.y) < 0.04, "revive resets the pose")
	# ---- statuses / misc kit hooks just run
	a.call(&"play_level_up")
	a.call(&"set_veterancy", 3)
	_check(bool(a.call(&"set_status", &"haste", true)), "set_status haste handled")
	await _wait(0.3)
	a.call(&"set_status", &"haste", false)
	# ---- transparency (Unit fade) tolerated
	for g: Node in b.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).transparency = 0.5
	await _wait(0.1)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


func _mesh_list(n: Node) -> Array:
	var out: Array = []
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		out.append((g as MeshInstance3D).mesh)
	return out


func _has_mat(mesh: Mesh, file: String) -> bool:
	for s: int in mesh.get_surface_count():
		var mt := mesh.surface_get_material(s)
		if mt and mt.resource_path.ends_with(file):
			return true
	return false


func _mat_verts(mesh: Mesh, file: String) -> int:
	var c := 0
	for s: int in mesh.get_surface_count():
		var mt := mesh.surface_get_material(s)
		if mt and mt.resource_path.ends_with(file):
			c += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return c


func _draw_instances(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		if g is MeshInstance3D and (g as MeshInstance3D).mesh == null:
			continue
		c += 1
	return c


func _mesh_verts(mesh: Mesh) -> int:
	var c := 0
	for s: int in mesh.get_surface_count():
		c += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return c


func _vertices(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		if (g as MeshInstance3D).mesh:
			c += _mesh_verts((g as MeshInstance3D).mesh)
	return c


## base_color of the recoloured cloth surfaces (surface overrides) of a merged mesh.
func _cloth_colors(mi: MeshInstance3D) -> Array:
	var out: Array = []
	for s: int in mi.mesh.get_surface_count():
		var ov := mi.get_surface_override_material(s) as ShaderMaterial
		if ov:
			var col: Color = ov.get_shader_parameter(&"base_color")
			if not (col in out):
				out.append(col)
	return out


func _materials(n: Node) -> Array:
	var out: Array = []
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		for s: int in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s)
			if mat == null:
				mat = mi.mesh.surface_get_material(s)
			if mat and not (mat in out):
				out.append(mat)
	return out


## Exact bounds of every vertex (the blob skipped) in `frame` space.
func _vert_bounds(n: Node, frame: Node3D) -> AABB:
	var inv := frame.global_transform.affine_inverse()
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		var xf := inv * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var w := xf * v
				lo = lo.min(w)
				hi = hi.max(w)
	return AABB(lo, hi - lo)


func _aabb(n: Node, frame: Node3D) -> AABB:
	var inv := frame.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		var bx := (inv * mi.global_transform) * mi.mesh.get_aabb()
		box = bx if first else box.merge(bx)
		first = false
	return box
