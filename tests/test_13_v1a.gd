extends SceneTree
## Tasks 13.V1a + 13.V4: the MountModel kit base (art/units/kit/mount_model.gd) on its first mount, the Rimehorn
## (art/units/mounts/rimehorn/rimehorn.tscn), plus a code-built horse-like mount with a Neck pivot (the generic path).
## Run: $GODOT --headless --path . -s tests/test_13_v1a.gd --fixed-fps 60 --quit-after 3000
## Checks: headless instantiation (2 instances: build + cache), class, pivots + Seat, hooks, section 10 mount budget
## (<= 12 authored meshes incl. the blob, <= 8 draw instances plain AND barded, 0 lights, 0 particles), vertices,
## materials (own <= 3 in the folder, the rest Ice / kit palette), size, seat_transform (rest + rider bob in the
## gallop), walk vs gallop (legs, blend, bounce), hit flash + flinch, play_charge (head levels the horn, lunge, glow
## flare, ends), set_barded (mesh swap, same draw instances, back to the plain mesh, before _ready too), team colour
## (cloth only, survives the barding swap, restores), death (rolls onto its side, lies ON the ground, frosts over,
## death_finished), revive, the kit slot audit on every geometry (KITFIX rules), transparency fade.
## Prints "PASS 13.v1a" or "FAIL 13.v1a: <reasons>".

const TASK_ID := "13.v1a"
const SCENE := "res://art/units/mounts/rimehorn/rimehorn.tscn"
const OWN_DIR := "res://art/units/mounts/rimehorn/"
const KITFIX := "res://art/units/kit/tools/kitfix_glow_check.gd"
const MOUNT_SCRIPT := "res://art/units/kit/mount_model.gd"

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
	_check(plain_verts <= 5000, "vertices <= 5000 (got %d)" % plain_verts)
	_check(b.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
	_check(b.find_children("*", "GPUParticles3D", true, false).is_empty(), "0 particle systems")
	for g: Node in b.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh:
			print("  %s: %d surfaces, %d vertices, shadow %s" % [b.get_path_to(mi), mi.mesh.get_surface_count(),
				_mesh_verts(mi.mesh), mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF])
	# ---- materials: own <= 3, the rest from the Ice / kit palettes, no built-in material
	var own: Array = []
	var shared: Array = []
	for mat: Material in _materials(b):
		var path := mat.resource_path
		if path.begins_with(OWN_DIR):
			own.append(path.get_file())
		else:
			shared.append(path.get_file() if path != "" else "<built-in>")
			_check(path.begins_with("res://art/units/ice/materials/") or path.begins_with("res://art/units/kit/materials/"),
				"material %s is an Ice / kit palette entry" % path)
	print("own materials (%d): %s" % [own.size(), ", ".join(PackedStringArray(own))])
	print("palette materials (%d): %s" % [shared.size(), ", ".join(PackedStringArray(shared))])
	_check(own.size() <= 3, "<= 3 own materials")
	# ---- size (rest)
	var box := _aabb(b, b.get_node("Root"))
	print("rest AABB y %.2f..%.2f, x %.2f..%.2f, z %.2f..%.2f" % [box.position.y, box.end.y, box.position.x, box.end.x,
		box.position.z, box.end.z])
	_check(box.position.y >= -0.01, "nothing below the ground at rest (%.3f)" % box.position.y)
	_check(box.end.y >= 1.8 and box.end.y <= 2.3, "the horn / crest top 1.8-2.3 m (%.2f)" % box.end.y)
	_check(box.size.z >= 2.8 and box.size.z <= 3.8, "length 2.8-3.8 m (%.2f)" % box.size.z)
	_check(box.size.x <= 1.6, "width <= 1.6 m (%.2f)" % box.size.x)
	# ---- seat
	var seat: Transform3D = b.call(&"seat_transform")
	var seat_node: Node3D = b.call(&"seat_node")
	var rel := b.global_transform.affine_inverse() * seat_node.global_transform
	print("seat (model space) ", seat.origin)
	_check(seat.origin.is_equal_approx(rel.origin), "seat_transform = the Seat marker in model space")
	_check(absf(seat.origin.x) < 0.01 and seat.origin.y > 1.3 and seat.origin.y < 1.7 and absf(seat.origin.z) < 0.5,
		"seat on the back (%s)" % seat.origin)
	_check(seat.basis.z.dot(Vector3.BACK) > 0.95, "seat faces +Z")
	# ---- walk vs gallop
	var leg: Node3D = a.get_node("Root/Mount/LegFL")
	var root_n: Node3D = a.get_node("Root")
	var head: Node3D = a.get_node("Root/Mount/Head")
	var tail: Node3D = a.get_node("Root/Mount/Tail")
	a.call(&"set_moving", 1.7)
	var max_leg := 0.0
	var max_g := 0.0
	for i: int in 60:
		await process_frame
		max_leg = maxf(max_leg, absf(leg.rotation.x))
		max_g = maxf(max_g, float(a.call(&"gallop_blend")))
	print("walk: leg swing %.1f deg, gallop blend %.2f" % [rad_to_deg(max_leg), max_g])
	_check(max_leg > deg_to_rad(10.0), "the legs swing in the walk")
	_check(max_g < 0.3, "no gallop at walking speed")
	a.call(&"set_moving", 6.0)
	await _wait(0.8)
	var ymin := 99.0
	var ymax := -99.0
	var seat_min := 99.0
	var seat_max := -99.0
	max_leg = 0.0
	var tail_x := 0.0
	var p0 := float(a.call(&"gait_phase"))
	var wraps := 0
	var last_p := p0
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
	_check(tail_x > deg_to_rad(8.0), "tail lifted in the gallop")
	a.call(&"set_moving", 0.0)
	await _wait(0.8)
	_check(absf(leg.rotation.x) < deg_to_rad(3.0), "legs back at rest after stopping")
	_check(float(a.call(&"gallop_blend")) < 0.2, "gallop blend falls when stopped")
	# ---- hit
	var body_mi := a.get_node("Root/Mount/Merged") as MeshInstance3D
	var head_mi := a.get_node("Root/Mount/Head/Merged") as MeshInstance3D
	a.call(&"play_hit")
	await _wait(0.05)
	var flash := float(body_mi.get_instance_shader_parameter(&"hit_flash"))
	var leg_flash := float((a.get_node("Root/Mount/LegFL/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	print("hit: body flash %.2f, leg flash %.2f, root z %.3f" % [flash, leg_flash, root_n.position.z])
	_check(flash > 0.3 and leg_flash > 0.3, "the whole beast flashes on a hit")
	_check(root_n.position.z < -0.03, "hit flinch pushes back")
	await _wait(0.5)
	# ---- charge
	var glow0 := float(head_mi.get_instance_shader_parameter(&"glow_boost"))
	a.call(&"play_charge")
	await _wait(0.10)
	var hx := head.rotation.x
	var glow1 := float(head_mi.get_instance_shader_parameter(&"glow_boost"))
	await _wait(0.05)
	var rz := root_n.position.z
	await _wait(0.15)
	var hx_toss := head.rotation.x
	print("charge: head %.1f deg (levelled), lunge z %.2f, toss %.1f deg, glow %.2f -> %.2f" % [rad_to_deg(hx), rz,
		rad_to_deg(hx_toss), glow0, glow1])
	_check(a.get(&"_action") == &"charge", "charge action running")
	_check(hx > deg_to_rad(12.0), "the head drops to level the horn")
	_check(rz > 0.2, "the charge lunges forward")
	_check(hx_toss < deg_to_rad(-10.0), "gore toss after the strike")
	_check(glow1 > glow0 + 0.3, "eyes / horn tip flare on the charge")
	await _wait(0.8)
	_check(a.get(&"_action") == &"", "charge finished")
	# attack (the mount's toss) and a cast just run
	a.call(&"play_attack")
	await _wait(0.6)
	_check(a.get(&"_action") == &"", "mount_toss attack finished")
	a.call(&"play_cast", &"fireball")
	await _wait(0.7)
	a.call(&"play_fidget")
	await _wait(0.4)
	_check(a.get(&"_action") == &"fidget", "fidget runs")
	a.call(&"set_moving", 2.0)
	await _wait(0.1)
	_check(a.get(&"_action") == &"", "moving cancels the fidget")
	a.call(&"set_moving", 0.0)
	await _wait(0.4)
	# ---- barding
	var plain_mesh: Mesh = body_mi.mesh
	var plain_surf := plain_mesh.get_surface_count()
	b.call(&"set_barded", true)
	await process_frame
	var b_body := b.get_node("Root/Mount/Merged") as MeshInstance3D
	var barded_inst := _draw_instances(b)
	var barded_verts := _vertices(b)
	print("barded: draw instances %d, vertices %d, body surfaces %d -> %d" % [barded_inst, barded_verts, plain_surf,
		b_body.mesh.get_surface_count()])
	_check(bool(b.call(&"is_barded")), "is_barded")
	_check(b_body.mesh != plain_mesh and _mesh_verts(b_body.mesh) > _mesh_verts(plain_mesh), "barded body mesh swapped")
	_check((b.get_node("Root/Mount/Head/Merged") as MeshInstance3D).mesh != head_mi.mesh, "barded head (chanfron)")
	_check((b.get_node("Root/Mount/LegFL/Merged") as MeshInstance3D).mesh != (a.get_node("Root/Mount/LegFL/Merged") as MeshInstance3D).mesh,
		"barded front legs (knee cops)")
	_check(barded_inst == plain_inst, "barding adds no draw instance")
	_check(barded_verts <= 7000, "barded vertices <= 7000 (got %d)" % barded_verts)
	var has_metal := false
	for s: int in b_body.mesh.get_surface_count():
		var mt := b_body.mesh.surface_get_material(s)
		if mt and mt.resource_path.ends_with("ice_metal.tres"):
			has_metal = true
	_check(has_metal, "barding = silver-blue ice_metal plates")
	var c := _spawn(Vector3(8, 0, 0), true)
	await _wait(0.1)
	_check((c.get_node("Root/Mount/Merged") as MeshInstance3D).mesh == b_body.mesh, "set_barded before _ready applies (cached variant)")
	# ---- team colour: cloth only, survives the barding swap, restores
	var red := Color(0.85, 0.30, 0.12)
	b.call(&"set_team_color", red)
	await process_frame
	var cloth_red := _cloth_colors(b_body)
	print("team colour on the barded body: ", cloth_red)
	_check(cloth_red.size() == 2, "cloth + cloth_dark recoloured")
	_check(red in cloth_red, "saddle-cloth takes the team colour")
	b.call(&"set_barded", false)
	await process_frame
	_check(b_body.mesh == plain_mesh, "unbarded: back to the plain mesh")
	_check(red in _cloth_colors(b_body), "team colour survives the barding swap")
	var others_ok := true
	for s: int in b_body.mesh.get_surface_count():
		var ov := b_body.get_surface_override_material(s)
		var base := b_body.mesh.surface_get_material(s)
		if ov and not (base.resource_path.ends_with("_cloth.tres") or base.resource_path.ends_with("_cloth_dark.tres")):
			others_ok = false
	_check(others_ok, "only cloth surfaces are recoloured")
	b.call(&"set_team_color", Color(0.45, 0.75, 0.95))
	await process_frame
	var any_override := false
	for s: int in b_body.mesh.get_surface_count():
		if b_body.get_surface_override_material(s) != null:
			any_override = true
	_check(not any_override, "the kingdom colour restores the scene's own cloth")
	# ---- kit slot audit (KITFIX rules) on every geometry of a plain and a barded Rimehorn
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
			if names.has("glow_boost"):
				_check((mm.get(&"_glow_nodes") as Array).has(gi), "%s glow driven by the kit" % mm.get_path_to(gi))
	print("slot collisions: ", collisions)
	_check(collisions == 0, "no instance-uniform slot collision")
	# ---- death: rolls onto its side, lies on the ground, frosts, death_finished; revive
	var got: Array = [false]
	a.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	a.call(&"set_moving", 6.0)
	await _wait(0.3)
	a.call(&"play_death")
	await _wait(0.4)
	var roll_mid := root_n.rotation.z
	await _wait(0.65)
	var roll_end := root_n.rotation.z
	var lying := _vert_bounds(a, a.get_parent() as Node3D)
	var frost := float(body_mi.get_instance_shader_parameter(&"hit_flash"))
	print("death: roll %.1f -> %.1f deg, lying AABB y %.2f..%.2f, frost %.2f, finished %s" % [rad_to_deg(roll_mid),
		rad_to_deg(roll_end), lying.position.y, lying.end.y, frost, got[0]])
	_check(absf(roll_end) > deg_to_rad(75.0), "falls onto its side")
	_check(lying.position.y > -0.2, "lies on the ground, not sunk (%.2f)" % lying.position.y)
	_check(lying.end.y < 1.6, "lying low (%.2f)" % lying.end.y)
	_check(frost > 0.2, "the body frosts over")
	_check(got[0], "death_finished within 1.05 s")
	a.call(&"revive")
	await _wait(0.3)
	_check(absf(root_n.rotation.z) < 0.03 and absf(root_n.position.y) < 0.04, "revive resets the pose")
	_check(float(body_mi.get_instance_shader_parameter(&"hit_flash")) < 0.05, "revive clears the frost")
	# ---- statuses / misc kit hooks just run
	a.call(&"play_level_up")
	a.call(&"set_veterancy", 3)
	_check(bool(a.call(&"set_status", &"haste", true)), "set_status haste handled")
	await _wait(0.3)
	a.call(&"set_status", &"haste", false)
	# ---- generic path: a code-built mount with a Neck pivot (horse artists) carries its head
	await _neck_mount_check()
	# ---- transparency (Unit fade) tolerated
	for g: Node in b.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).transparency = 0.5
	await _wait(0.1)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


## A minimal editor-style mount (MeshInstance3D parts under the pivots) with Root/Mount/Neck and a Tail: merged
## per pivot, the neck swings and the head follows it (position), the Seat defaults, the hooks run.
func _neck_mount_check() -> void:
	var mm := Node3D.new()
	mm.set_script(load(MOUNT_SCRIPT))
	var r := _n(mm, "Root", Vector3.ZERO)
	var body := _n(r, "Mount", Vector3(0, 1.0, 0))
	var neck := _n(body, "Neck", Vector3(0, 0.2, 0.6))
	var head := _n(body, "Head", Vector3(0, 0.8, 1.0))
	for nm: String in ["LegFL", "LegFR", "LegBL", "LegBR"]:
		var lg := _n(body, nm, Vector3(-0.25 if nm.ends_with("L") else 0.25, -0.1, 0.5 if nm.begins_with("LegF") else -0.5))
		_mesh(lg, Vector3(0, -0.45, 0), Vector3(0.12, 0.9, 0.12))
	var tl := _n(body, "Tail", Vector3(0, 0.1, -0.8))
	_mesh(body, Vector3.ZERO, Vector3(0.6, 0.6, 1.6))
	_mesh(neck, Vector3(0, 0.35, 0.2), Vector3(0.25, 0.8, 0.3))
	_mesh(head, Vector3(0, 0, 0.2), Vector3(0.25, 0.3, 0.55))
	_mesh(tl, Vector3(0, -0.3, -0.1), Vector3(0.08, 0.6, 0.08))
	mm.set(&"gallop_speed", 4.0)
	mm.set(&"is_quadruped", true)
	_world.add_child(mm)
	mm.position = Vector3(-5, 0, 0)
	await _wait(0.1)
	_check(mm.get_node_or_null("Root/Mount/Neck/Merged") != null and mm.get_node_or_null("Root/Mount/Tail/Merged") != null,
		"neck mount: Neck and Tail merged into their own node")
	_check(_draw_instances(mm) == 8, "neck mount: body, neck, head, 4 legs, tail = 8 (got %d)" % _draw_instances(mm))
	var hp0 := head.position
	mm.call(&"set_moving", 7.0)
	var moved := 0.0
	var neck_rot := 0.0
	for i: int in 60:
		await process_frame
		moved = maxf(moved, head.position.distance_to(hp0))
		neck_rot = maxf(neck_rot, absf(neck.rotation.x))
	print("neck mount: neck swing %.1f deg, head carried %.3f m, gallop %.2f" % [rad_to_deg(neck_rot), moved,
		float(mm.call(&"gallop_blend"))])
	_check(neck_rot > deg_to_rad(1.0) and moved > 0.005, "neck mount: the head rides on the swinging neck")
	var st: Transform3D = mm.call(&"seat_transform")
	_check(st.origin.y > 0.5, "neck mount without a Seat: a seat estimate")
	mm.call(&"set_barded", true)
	mm.call(&"set_team_color", Color(1, 0, 0))
	mm.call(&"play_charge")
	await _wait(0.3)
	mm.call(&"play_death")
	await _wait(1.1)
	_check(absf((r as Node3D).rotation.z) > deg_to_rad(70.0), "neck mount: death roll")
	mm.queue_free()


func _n(parent: Node, nm: String, local: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = nm
	n.position = local
	parent.add_child(n)
	return n


func _mesh(parent: Node3D, local: Vector3, size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = CharacterModel.palette(&"shadow_iron")
	mi.position = local
	parent.add_child(mi)


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
