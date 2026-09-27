extends SceneTree
## Task 13.V3: the Dusk Steed, the Shadow mount (art/units/mounts/dusk_steed/dusk_steed.tscn, a MountModel).
## Run: $GODOT --headless --path . -s tests/test_13_v3.gd --fixed-fps 60 --quit-after 3000
## Checks: headless instantiation (2 instances: build + cache), class, pivots + Seat, hooks, section 10 mount budget
## (<= 12 authored meshes incl. the blob, <= 8 draw instances plain AND barded, 0 lights, 0 particles), vertices,
## materials (own <= 3 in the folder, the rest the Shadow kit palette, no Fire / flame material: not the Nightmare
## Knight's burning horse), violet eye glow, riding-horse size, seat_transform (rest + rider bob in the gallop), walk vs
## gallop (legs, blend, bounce), hit flash + flinch, play_charge (neck stretched low, lunge, toss, eye flare, ends),
## fidget (dusk rear), set_barded (tarnished silver chanfron on the head + peytral, mesh swap, same draw instances,
## back to the plain mesh, before _ready too), team colour (cloth only, survives the barding swap, restores), death
## (rolls onto its side, lies ON the ground, violet dissolve flare, death_finished), revive, the kit slot audit on every
## geometry (KITFIX rules), transparency fade.
## Prints "PASS 13.v3" or "FAIL 13.v3: <reasons>".

const TASK_ID := "13.v3"
const SCENE := "res://art/units/mounts/dusk_steed/dusk_steed.tscn"
const OWN_DIR := "res://art/units/mounts/dusk_steed/"
const KITFIX := "res://art/units/kit/tools/kitfix_glow_check.gd"
const SHADOW := Color(0.42, 0.22, 0.60)

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
	_check(plain_verts <= 6000, "vertices <= 6000 (got %d)" % plain_verts)
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
			var fname := path.get_file()
			_check(path.begins_with("res://art/units/kit/materials/shadow_") or fname == "unit_eye_dark.tres",
				"material %s is a Shadow kit palette entry" % path)
			_check(not fname.begins_with("fire_") and not fname.contains("flame"), "no fire material (%s)" % fname)
	print("own materials (%d): %s" % [own.size(), ", ".join(PackedStringArray(own))])
	print("palette materials (%d): %s" % [shared.size(), ", ".join(PackedStringArray(shared))])
	_check(own.size() <= 3, "<= 3 own materials")
	# ---- violet eye glow on the head
	var glow_ok := false
	var head_plain := b.get_node("Root/Mount/Head/Merged") as MeshInstance3D
	for s: int in head_plain.mesh.get_surface_count():
		var mt := head_plain.mesh.surface_get_material(s)
		if mt and mt.resource_path.ends_with("shadow_glow_hero.tres"):
			glow_ok = true
	_check(glow_ok, "violet eye glow (shadow_glow_hero) on the head")
	_check((b.get("_glow_nodes") as Array).has(head_plain), "the eye glow is driven by the kit")
	# ---- size (rest): a riding-size horse (the Nightmare Knight's is huge)
	var box := _aabb(b, b.get_node("Root"))
	print("rest AABB y %.2f..%.2f, x %.2f..%.2f, z %.2f..%.2f" % [box.position.y, box.end.y, box.position.x, box.end.x,
		box.position.z, box.end.z])
	_check(box.position.y >= -0.01, "nothing below the ground at rest (%.3f)" % box.position.y)
	_check(box.end.y >= 2.2 and box.end.y <= 2.7, "ears / mane top 2.2-2.7 m (%.2f)" % box.end.y)
	_check(box.size.z >= 2.4 and box.size.z <= 3.3, "length 2.4-3.3 m (%.2f)" % box.size.z)
	_check(box.size.x <= 1.0, "width <= 1.0 m (%.2f)" % box.size.x)
	# ---- seat
	var seat: Transform3D = b.call(&"seat_transform")
	var seat_node: Node3D = b.call(&"seat_node")
	var rel := b.global_transform.affine_inverse() * seat_node.global_transform
	print("seat (model space) ", seat.origin)
	_check(seat.origin.is_equal_approx(rel.origin), "seat_transform = the Seat marker in model space")
	_check(absf(seat.origin.x) < 0.01 and seat.origin.y > 1.55 and seat.origin.y < 1.85 and absf(seat.origin.z) < 0.4,
		"seat on the back (%s)" % seat.origin)
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
	_check(hx > deg_to_rad(10.0), "the neck stretches low (charge)")
	_check(rz > 0.2, "the charge lunges forward")
	_check(hx_toss < deg_to_rad(-10.0), "head toss after the strike")
	_check(glow1 > glow0 + 0.3, "the violet eyes flare on the charge")
	await _wait(0.8)
	_check(a.get(&"_action") == &"", "charge finished")
	# attack (the mount's toss) and a cast just run
	a.call(&"play_attack")
	await _wait(0.6)
	_check(a.get(&"_action") == &"", "mount_toss attack finished")
	a.call(&"play_cast", &"fireball")
	await _wait(0.7)
	a.call(&"play_fidget")
	await _wait(0.6)
	var body_n: Node3D = a.get_node("Root/Mount")
	print("fidget (dusk rear): body pitch %.1f deg, fore leg %.1f deg, head %.1f deg" % [rad_to_deg(body_n.rotation.x),
		rad_to_deg(leg.rotation.x), rad_to_deg(head.rotation.x)])
	_check(a.get(&"_action") == &"fidget", "fidget runs")
	_check(body_n.rotation.x < deg_to_rad(-4.0) and leg.rotation.x < deg_to_rad(-15.0), "fidget: a half rear, fore hooves up")
	var hoof_y := _vert_bounds(a, a.get_parent() as Node3D).position.y
	_check(hoof_y > -0.05, "rearing keeps the hind hooves on the ground (%.2f)" % hoof_y)
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

	_check(barded_inst == plain_inst, "barding adds no draw instance")
	_check(barded_verts <= 7600, "barded vertices <= 7600 (got %d)" % barded_verts)
	var has_metal := false
	for s: int in b_body.mesh.get_surface_count():
		var mt := b_body.mesh.surface_get_material(s)
		if mt and mt.resource_path.ends_with("shadow_silver.tres"):
			has_metal = true
	var b_head := b.get_node("Root/Mount/Head/Merged") as MeshInstance3D
	var head_silver := false
	for s: int in b_head.mesh.get_surface_count():
		var mt := b_head.mesh.surface_get_material(s)
		if mt and mt.resource_path.ends_with("shadow_silver.tres"):
			head_silver = (b_head.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() > 0
	_check(has_metal, "barding: tarnished silver peytral (shadow_silver)")
	_check(head_silver and _mesh_verts(b_head.mesh) > _mesh_verts(head_mi.mesh) + 200, "barding: tarnished silver chanfron + crinet")
	_check(b_head in (b.get("_glow_nodes") as Array), "barded head keeps the eye glow (+ brow gem)")
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
	b.call(&"set_team_color", SHADOW)
	await process_frame
	var any_override := false
	for s: int in b_body.mesh.get_surface_count():
		if b_body.get_surface_override_material(s) != null:
			any_override = true
	_check(not any_override, "the kingdom colour restores the scene's own cloth")
	# ---- kit slot audit (KITFIX rules) on every geometry of a plain and a barded Dusk Steed
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
	# ---- death: rolls onto its side, lies on the ground, violet dissolve flare, death_finished; revive
	var got: Array = [false]
	a.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	a.call(&"set_moving", 6.0)
	await _wait(0.3)
	a.call(&"play_death")
	await _wait(0.4)
	var roll_mid := root_n.rotation.z
	var flare_mid := float(body_mi.get_instance_shader_parameter(&"hit_flash"))
	var fcol: Vector3 = body_mi.get_instance_shader_parameter(&"flash_color")
	await _wait(0.65)
	var roll_end := root_n.rotation.z
	var lying := _vert_bounds(a, a.get_parent() as Node3D)
	var frost := float(body_mi.get_instance_shader_parameter(&"hit_flash"))  # the residual violet sheen
	print("death: roll %.1f -> %.1f deg, lying AABB y %.2f..%.2f, flare %.2f -> %.2f, finished %s" % [rad_to_deg(roll_mid),
		rad_to_deg(roll_end), lying.position.y, lying.end.y, flare_mid, frost, got[0]])
	_check(absf(roll_end) > deg_to_rad(75.0), "falls onto its side")
	_check(lying.position.y > -0.2, "lies on the ground, not sunk (%.2f)" % lying.position.y)
	_check(lying.end.y < 1.6, "lying low (%.2f)" % lying.end.y)
	_check(flare_mid > 0.15 and fcol.z > 0.8 and fcol.x > 0.3 and fcol.y < 0.3, "violet dissolve flare (%.2f)" % flare_mid)
	_check(frost > 0.05 and frost < flare_mid, "fades to a faint violet sheen (%.2f)" % frost)
	_check(got[0], "death_finished within 1.05 s")
	a.call(&"revive")
	await _wait(0.3)
	_check(absf(root_n.rotation.z) < 0.03 and absf(root_n.position.y) < 0.04, "revive resets the pose")
	_check(float(body_mi.get_instance_shader_parameter(&"hit_flash")) < 0.05, "revive clears the dissolve")
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
