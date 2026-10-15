extends SceneTree
## G-C mounts + titans (docs/art/gc_mounts_titans.md): the look pass keeps every contract and budget.
## - MountShapes (art/units/mounts/mount_shapes.gd): one continuous leg tube per leg (outward normals, flattened side to
##   side), bands share their joint ring, muscles are closed ellipsoids.
## - The Ember Boar, Dusk Steed, Grove Stag and Roan Courser build their legs with MountShapes (no stacked tube + ball +
##   tube legs left); every mount keeps its pivots / Seat, <= 8 draw instances after _ready, its body vertex budget
##   (the face apart: Art Lab B4 mount 6000; the Grove Stag was over it before the pass, capped at 6700), legs whose
##   lowest point sits on the ground, and the hit flash on the leg meshes.
## - Titans: <= 20 draw instances; the Elder Treant crown carries team leaves (COLOR.a 1, tinted by team_tint) and two
##   treants / two flyers share one ground-blob mesh (Art Lab B9m); the Frost Dragon membrane keeps the kingdom colour's
##   brightness; the War Mammoth crown / hump crest are locks (no cog-like fringe ring).
## Run: $GODOT --headless --path . -s tests/test_gc_mounts_titans.gd --fixed-fps 60 --quit-after 3000
## Prints "PASS gc_mounts_titans" or "FAIL gc_mounts_titans: <reasons>".

const TASK_ID := "gc_mounts_titans"
const MOUNTS := {
	"ember_boar": 6000, "dusk_steed": 6000, "grove_stag": 6700, "rimehorn": 6000, "roan_courser": 6000,
}
const SHAPED: Array[String] = ["ember_boar", "dusk_steed", "grove_stag", "roan_courser"]
const TITANS: Array[String] = ["cinder_dragon", "frost_dragon", "elder_treant", "nightmare_knight", "war_mammoth"]
const LEGS: Array[String] = ["Root/Mount/LegFL", "Root/Mount/LegFR", "Root/Mount/LegBL", "Root/Mount/LegBR"]

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var cam := Camera3D.new()
	_world.add_child(cam)
	cam.look_at_from_position(Vector3(0, 9, 14), Vector3.ZERO)   # close: the models stay on LOD tier 0
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _run() -> void:
	_shape_checks()
	for id: String in MOUNTS:
		await _mount(id)
	for id: String in TITANS:
		await _titan(id)
	await _shared_blobs()
	_source_checks()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0)


# ---------------------------------------------------------------- MountShapes

func _shape_checks() -> void:
	var s := MountModel.sculpt()
	var rows: Array[Vector3] = MountShapes.HORSE_FORE
	MountShapes.leg(s, "gc_test_leg", Vector3(0.3, 0, 0.5), rows,
		MountModel.material_at("res://art/units/kit/materials/fire_hair.tres"), 1.0, 0.7, 8)
	var m := MountModel.sculpt_mesh(s)
	_check(m != null and m.get_surface_count() == 1, "MountShapes.leg makes one surface")
	if m == null:
		return
	var a := m.surface_get_arrays(0)
	var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var bad := 0
	var min_y := INF
	var max_y := -INF
	var cannon_x := 0.0
	var cannon_z := 0.0
	for i: int in v.size():
		var p := v[i]
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
		# axis point at this height: the row centre (x 0.3, z 0.5 + dz); normals must point away from it
		var c := Vector3(0.3, p.y, 0.5 + _dz_at(rows, p.y))
		var out := p - c
		out.y = 0.0
		if out.length() > 0.01 and n[i].dot(out) < 0.0:
			bad += 1
		if absf(p.y - 0.32) < 0.03:
			cannon_x = maxf(cannon_x, absf(p.x - 0.3))
			cannon_z = maxf(cannon_z, absf(p.z - c.z))
	_check(bad <= v.size() / 20, "leg normals face outward (%d of %d inward)" % [bad, v.size()])
	_check(absf(max_y - 1.18) < 0.04 and min_y < 0.09, "leg spans the root to the coronet (%.2f .. %.2f)" % [min_y, max_y])
	_check(cannon_x > 0.0 and cannon_x < cannon_z * 0.85, "cannon flattened side to side (x %.3f vs z %.3f)" % [cannon_x, cannon_z])
	# bands: the cut row is shared (no gap between the coat and the sock)
	var s2 := MountModel.sculpt()
	var mats: Array = [MountModel.material_at("res://art/units/kit/materials/fire_hair.tres"),
		MountModel.material_at("res://art/units/kit/materials/fire_leather.tres")]
	MountShapes.leg_bands(s2, "gc_test_band", Vector3.ZERO, rows, [4], mats, 1.0, 0.8, 8)
	var m2 := MountModel.sculpt_mesh(s2)
	_check(m2 != null and m2.get_surface_count() == 2, "leg_bands: one surface per band")
	if m2 and m2.get_surface_count() == 2:
		var lo0 := INF
		var hi1 := -INF
		for p: Vector3 in m2.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array:
			lo0 = minf(lo0, p.y)
		for p: Vector3 in m2.surface_get_arrays(1)[Mesh.ARRAY_VERTEX] as PackedVector3Array:
			hi1 = maxf(hi1, p.y)
		_check(absf(lo0 - rows[4].x) < 0.01 and absf(hi1 - rows[4].x) < 0.01, "bands meet at the cut row (%.3f / %.3f)" % [lo0, hi1])
	var sc := MountShapes.scaled(rows, 0.2, 0.5)
	_check(is_equal_approx(sc[sc.size() - 1].x, rows[rows.size() - 1].x) and sc[0].x < rows[0].x,
		"scaled keeps the hoof rows, shortens the leg")


func _dz_at(rows: Array[Vector3], y: float) -> float:
	for i: int in range(1, rows.size()):
		if y >= rows[i].x:
			var t := (y - rows[i].x) / maxf(rows[i - 1].x - rows[i].x, 0.0001)
			return lerpf(rows[i].y, rows[i - 1].y, clampf(t, 0.0, 1.0))
	return rows[rows.size() - 1].y


# ---------------------------------------------------------------- mounts

func _mount(id: String) -> void:
	var p := "res://art/units/mounts/%s/%s.tscn" % [id, id]
	var m := (load(p) as PackedScene).instantiate() as Node3D
	_world.add_child(m)
	await process_frame
	await process_frame
	for path: String in ["Root", "Root/Mount", "Root/Mount/Head", "Root/Mount/Seat", "Fx", "Shadow"] + LEGS:
		_check(m.get_node_or_null(path) != null, "%s: node %s kept" % [id, path])
	for hk: String in ["set_team_color", "set_moving", "play_attack", "play_hit", "play_death", "set_barded", "play_charge",
			"seat_transform", "gait_phase", "authored_mesh_count"]:
		_check(m.has_method(hk), "%s: hook %s kept" % [id, hk])
	var draws := _draws(m)
	var body := _body_verts(m)
	print("%s: draw instances %d, body vertices %d (budget %d)" % [id, draws, body, MOUNTS[id]])
	_check(draws <= 8, "%s: draw instances %d <= 8" % [id, draws])
	_check(body <= int(MOUNTS[id]), "%s: body vertices %d <= %d" % [id, body, MOUNTS[id]])
	# legs on the ground (rest pose), each leg merged into one mesh
	var low := INF
	for lp: String in LEGS:
		var mi := m.get_node_or_null(lp + "/Merged") as MeshInstance3D
		_check(mi != null and mi.mesh != null, "%s: %s merged" % [id, lp])
		if mi and mi.mesh:
			var xf := mi.global_transform
			for s: int in mi.mesh.get_surface_count():
				for v: Vector3 in mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array:
					low = minf(low, (xf * v).y)
	_check(low > -0.035 and low < 0.08, "%s: legs stand on the ground (lowest %.3f)" % [id, low])
	# hit flash still reaches the legs
	m.call(&"play_hit")
	await process_frame
	await process_frame
	var leg := m.get_node_or_null("Root/Mount/LegFL/Merged") as MeshInstance3D
	var f: Variant = leg.get_instance_shader_parameter(&"hit_flash") if leg else null
	_check(f != null and float(f) > 0.2, "%s: hit flash on the legs" % id)
	m.queue_free()
	await process_frame


# ---------------------------------------------------------------- titans

func _titan(id: String) -> void:
	var p := "res://art/units/titans/%s/%s.tscn" % [id, id]
	var m := (load(p) as PackedScene).instantiate() as Node3D
	_world.add_child(m)
	await process_frame
	await process_frame
	var draws := _draws(m) + m.find_children("*", "GPUParticles3D", true, false).size()
	print("%s: draw instances + particle systems %d, vertices %d" % [id, draws, _body_verts(m)])
	_check(draws <= 20, "%s: %d draw instances + particle systems <= 20" % [id, draws])
	_check(m.find_children("*", "Light3D", true, false).is_empty(), "%s: 0 lights" % id)
	if id == "elder_treant":
		var head := m.get_node_or_null("Root/Chest/Head/HeadMesh") as MeshInstance3D
		var team := 0
		var still := 0
		if head and head.mesh:
			for s: int in head.mesh.get_surface_count():
				var mat := head.mesh.surface_get_material(s)
				if mat == null or not mat.resource_path.ends_with("treant_leaf.tres"):
					continue
				var cols: PackedColorArray = head.mesh.surface_get_arrays(s)[Mesh.ARRAY_COLOR]
				for c: Color in cols:
					if c.a >= 0.75:
						team += 1
						if c.a > 0.95:
							still += 1
		print("  treant crown team-leaf vertices: %d" % team)
		_check(team >= 300, "elder_treant: the crown carries team leaves (%d vertices)" % team)
		# treant_leaf.gdshader: breeze sway = step(COLOR.a, 0.95), team read = step(0.75, COLOR.a)
		_check(still == 0, "elder_treant: crown team leaves sway with their core (%d still vertices)" % still)
	m.queue_free()
	await process_frame


func _shared_blobs() -> void:
	for p: String in ["res://art/units/titans/elder_treant/elder_treant.tscn", "res://art/units/titans/cinder_dragon/cinder_dragon.tscn",
			"res://art/units/titans/frost_dragon/frost_dragon.tscn"]:
		var a := (load(p) as PackedScene).instantiate() as Node3D
		var b := (load(p) as PackedScene).instantiate() as Node3D
		_world.add_child(a)
		_world.add_child(b)
		await process_frame
		await process_frame
		var sa := a.get_node_or_null("Shadow") as MeshInstance3D
		var sb := b.get_node_or_null("Shadow") as MeshInstance3D
		_check(sa != null and sb != null and sa.mesh == sb.mesh, "%s: one shared ground-blob mesh" % p.get_file())
		a.queue_free()
		b.queue_free()
		await process_frame


# ---------------------------------------------------------------- sources

func _source_checks() -> void:
	for id: String in SHAPED:
		var src := FileAccess.get_file_as_string("res://art/units/mounts/%s/%s.gd" % [id, id])
		_check("MountShapes.leg" in src, "%s: legs built with MountShapes" % id)
	var dusk := FileAccess.get_file_as_string("res://art/units/mounts/dusk_steed/dusk_steed.gd")
	_check(not "dusk_fcannon_v1" in dusk and not "dusk_hcannon_v1" in dusk, "dusk_steed: no stacked cannon tubes left")
	var mem := FileAccess.get_file_as_string("res://art/units/titans/frost_dragon/frost_membrane.gdshader")
	_check("mt_max" in mem, "frost_membrane keeps the kingdom colour's brightness")
	var leaf := FileAccess.get_file_as_string("res://art/units/titans/elder_treant/treant_leaf.gdshader")
	_check("step(COLOR.a, 0.95)" in leaf and "step(0.75, COLOR.a)" in leaf, "treant_leaf: crown team leaves (a 0.9) sway and read team")
	var fd := FileAccess.get_file_as_string("res://art/units/titans/frost_dragon/frost_dragon.gd")
	_check(not "_blob_mesh" in fd, "frost_dragon: no dead blob override (FlyerModel shares the plane)")
	var mam := FileAccess.get_file_as_string("res://art/units/titans/war_mammoth/war_mammoth.gd")
	_check(not "mammoth_crown_v1" in mam and not "mammoth_frostcap_v1" in mam, "war_mammoth: crown / hump crest as locks")
	var fur := load("res://art/units/titans/war_mammoth/materials/mammoth_fur.tres") as ShaderMaterial
	_check(fur != null and float(fur.get_shader_parameter(&"top_lift")) > 0.0, "mammoth fur: frosted top lift")


# ---------------------------------------------------------------- helpers

func _draws(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		if not (g as Node3D).is_visible_in_tree():
			continue
		if g is MeshInstance3D and (g as MeshInstance3D).mesh == null:
			continue
		if g is GPUParticles3D:
			continue
		c += 1
	return c


## Visible vertices, the face kit's material apart (Art Lab B4 gives the face its own allowance).
func _body_verts(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		for s: int in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(s)
			if mat and mat.resource_path.get_file().begins_with("unit_face"):
				continue
			c += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return c
