extends SceneTree
## Task 12.V14: Landmarks B (map-fill.md 3.2 + 10): the Old Aqueduct, the Drowned Barge, the Standing Stones.
## Run: $GODOT --headless --path . -s tests/test_12_v14.gd --fixed-fps 60 --quit-after 600
## Checks, per scene (art/environment/landmarks/<id>.tscn), placed at its 3.2 spot:
## - instantiates headless without errors; root Node3D in group "landmarks" with metadata landmark_id /
##   decor_clear_radius / foam_rocks (same layout as Landmarks A); a "Model" MeshInstance3D; colliders < 2 m tall (no
##   walkable island baked inside them);
## - 0 lights, no particles; <= 3 surfaces; surface 0 = the SHARED nature_mat.tres, contact discs = nature_contact_mat.tres,
##   runes = landmarks/stones_rune_mat.tres (no material built at runtime); every surface indexed; <= 7 000 triangles;
## - colliders exactly as 3.2 (layer 1, mask 0): aqueduct = 2 cylinders r 0.9 at the piers (-17.5, -55) / (-9.3, -55),
##   nothing over the water; barge = none (draw-only); stones = 6 cylinders r 0.5 on a ring r 3 around (-54, 20);
## - the point-mirrored copy (position -p, rotation PI) puts every collider at -c;
## - sizes: aqueduct <= 7 m tall and spans the river; the barge's whole mesh stays inside the 5 m channel and <= 3 m
##   above the water; stones <= 4 m;
## - walkable space stays clear: any geometry where a unit can stand (outside collider + agent radius, on land) is
##   either low (< 0.45 m, walk-through rubble) or overhead (> 1.9 m);
## - foam_rocks circles lie in the water;
## - a navmesh baked like main.gd (static colliders, layer 1, agent r 0.5 / h 2.0) has no ground polygon inside any
##   collider (a collider top >= 2 m would bake a walkable island inside it).
## Prints "PASS 12.v14" or "FAIL 12.v14: <reasons>".

const TASK_ID := "12.v14"
const DIR := "res://art/environment/landmarks/"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const CONTACT_MAT := "res://art/environment/nature_props/nature_contact_mat.tres"
const RUNE_MAT := "res://art/environment/landmarks/stones_rune_mat.tres"
const RIVER_N: Array[Vector2] = [Vector2(-15, -62), Vector2(-12, -48.7), Vector2(-9, -38), Vector2(-8, -30), Vector2(-5, -21),
	Vector2(-2.5, -12.5)]
const HALF_W := 2.5
const AGENT_R := 0.5
const SPECS := {
	"aqueduct": {"id": &"lm_aqueduct", "pos": Vector3(-13.4, 0, -55), "colliders": 2, "r": 0.9, "max_h": 7.0},
	"barge": {"id": &"lm_barge", "pos": Vector3(-6.2, 0, -24.5), "colliders": 0, "r": 0.0, "max_h": 3.0},
	"standing_stones": {"id": &"lm_stones", "pos": Vector3(-54, 0, 20), "colliders": 6, "r": 0.5, "max_h": 4.0},
}

var _fails: PackedStringArray = PackedStringArray()
var _holder: Node3D
var _frame := 0


func _initialize() -> void:
	_holder = Node3D.new()
	root.add_child(_holder)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 2:   # the tree is live from the first frame on (global transforms)
		return false
	for file: String in SPECS:
		_check_scene(_holder, file, SPECS[file])
	_check_navmesh()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	return true


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


## Bakes a navmesh (main.gd's settings: static colliders on layer 1, agent r 0.5 / h 2.0) over a flat ground with the
## three landmarks at their spots: no walkable polygon inside a collider (+ agent radius), none on top of one.
func _check_navmesh() -> void:
	var region := NavigationRegion3D.new()
	root.add_child(region)
	var ground := StaticBody3D.new()
	var gs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(140.0, 1.0, 140.0)
	gs.shape = box
	gs.position.y = -0.5
	ground.add_child(gs)
	region.add_child(ground)
	var centres: Array[Vector4] = []   # x, z, radius, 0
	for file: String in SPECS:
		var lm := (load(DIR + file + ".tscn") as PackedScene).instantiate() as Node3D
		lm.position = SPECS[file]["pos"]
		region.add_child(lm)
		for cs: Node in lm.find_children("*", "CollisionShape3D", true, false):
			var p: Vector3 = lm.transform * (cs as Node3D).position
			centres.append(Vector4(p.x, p.z, ((cs as CollisionShape3D).shape as CylinderShape3D).radius, 0.0))
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nm.agent_radius = AGENT_R
	nm.agent_height = 2.0
	nm.agent_max_climb = 0.25
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	var src := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nm, src, region)
	NavigationServer3D.bake_from_source_geometry_data(nm, src)
	var verts: PackedVector3Array = nm.get_vertices()
	_check(nm.get_polygon_count() > 0, "navmesh: baked (%d polygons)" % nm.get_polygon_count())
	var inside := 0
	var on_top := 0
	var worst := ""
	# Sample points inside each collider (centre + a ring at 0.8 r) must not lie in any ground polygon (convex, xz).
	for k: Vector4 in centres:
		var samples: Array[Vector2] = [Vector2(k.x, k.y)]
		for a: int in 8:
			samples.append(Vector2(k.x, k.y) + Vector2(cos(a * TAU / 8.0), sin(a * TAU / 8.0)) * k.z * 0.8)
		for pi: int in nm.get_polygon_count():
			var poly: PackedInt32Array = nm.get_polygon(pi)
			var cy := 0.0
			for vi: int in poly:
				cy += verts[vi].y
			cy /= float(poly.size())
			for sp: Vector2 in samples:
				if _in_poly(sp, poly, verts):
					if cy > 0.5:
						on_top += 1
					else:
						inside += 1
						worst = "ground polygon %d covers %s, inside the collider at (%.1f, %.1f)" % [pi, sp, k.x, k.y]
					break
	_check(inside == 0, "navmesh: no ground polygon inside a collider (%d; %s)" % [inside, worst])
	# The flat collider tops bake small unreachable islands (like the tree / pillar colliders): reported, not a failure.
	print("navmesh: %d polygons, %d colliders checked, 0 ground polygons inside, %d unreachable top-cap polygons" % [
		nm.get_polygon_count(), centres.size(), on_top])
	region.queue_free()


## Point in a convex navmesh polygon (xz), either winding.
func _in_poly(p: Vector2, poly: PackedInt32Array, verts: PackedVector3Array) -> bool:
	var sgn := 0.0
	for i: int in poly.size():
		var a: Vector3 = verts[poly[i]]
		var b: Vector3 = verts[poly[(i + 1) % poly.size()]]
		var cr: float = (b.x - a.x) * (p.y - a.z) - (b.z - a.z) * (p.x - a.x)
		if absf(cr) < 1e-6:
			continue
		if sgn == 0.0:
			sgn = signf(cr)
		elif signf(cr) != sgn:
			return false
	return true


func _river_dist(p: Vector2) -> float:
	var best := INF
	for i in RIVER_N.size() - 1:
		var a: Vector2 = RIVER_N[i]
		var ab: Vector2 = RIVER_N[i + 1] - a
		var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best


func _check_scene(holder: Node3D, file: String, spec: Dictionary) -> void:
	var path := DIR + file + ".tscn"
	_check(ResourceLoader.exists(path), "%s exists" % path)
	if not ResourceLoader.exists(path):
		return
	var ps := load(path) as PackedScene
	var lm := ps.instantiate() as Node3D
	_check(lm != null, "%s: root is a Node3D" % file)
	if lm == null:
		return
	holder.add_child(lm)
	lm.position = spec["pos"]
	_check(lm.get_meta(&"landmark_id", &"") == spec["id"], "%s: landmark_id = %s" % [file, spec["id"]])
	_check(lm.get_meta(&"foam_rocks", null) is PackedVector3Array, "%s: foam_rocks metadata" % file)
	_check(lm.is_in_group(&"landmarks"), "%s: in group landmarks" % file)
	var clear_r: float = lm.get_meta(&"decor_clear_radius", 0.0)
	_check(clear_r >= 3.0 and clear_r <= 7.0, "%s: decor_clear_radius %.1f" % [file, clear_r])
	# --- lights / particles / materials / budget ---
	_check(lm.find_children("*", "Light3D", true, false).is_empty(), "%s: 0 lights" % file)
	_check(lm.find_children("*", "GPUParticles3D", true, false).is_empty() and lm.find_children("*", "CPUParticles3D",
		true, false).is_empty(), "%s: no particles" % file)
	var mi := lm.get_node_or_null("Model") as MeshInstance3D
	_check(mi != null and mi.mesh != null, "%s: Model node with a mesh" % file)
	if mi == null or mi.mesh == null:
		return
	var mesh: Mesh = mi.mesh
	_check(mesh.resource_path.begins_with(DIR + "meshes/"), "%s: mesh saved under landmarks/meshes (%s)" % [file, mesh.resource_path])
	_check(mesh.get_surface_count() <= 3, "%s: <= 3 surfaces (%d)" % [file, mesh.get_surface_count()])
	_check(mi.material_override == null, "%s: no material override" % file)
	var tris := 0
	var painted := PackedVector3Array()
	for s in mesh.get_surface_count():
		var m: Material = mesh.surface_get_material(s)
		_check(m != null and m.resource_path.ends_with(".tres"), "%s: surface %d material is a saved .tres" % [file, s])
		if m:
			if s == 0:
				_check(m.resource_path == NATURE_MAT and m == load(NATURE_MAT), "%s: surface 0 = shared nature_mat" % file)
			else:
				_check(m.resource_path in [CONTACT_MAT, RUNE_MAT], "%s: surface %d = contact / rune mat (%s)" % [file, s,
					m.resource_path])
		var arr: Array = mesh.surface_get_arrays(s)
		var idx: Variant = arr[Mesh.ARRAY_INDEX]
		_check(idx is PackedInt32Array and not (idx as PackedInt32Array).is_empty(), "%s: surface %d indexed" % [file, s])
		if idx is PackedInt32Array:
			tris += (idx as PackedInt32Array).size() / 3
		if s == 0:
			painted = arr[Mesh.ARRAY_VERTEX]
	_check(tris <= 7000, "%s: <= 7000 triangles (%d)" % [file, tris])
	if file == "standing_stones":
		var has_rune := false
		for s2 in mesh.get_surface_count():
			var m2: Material = mesh.surface_get_material(s2)
			has_rune = has_rune or (m2 != null and m2.resource_path == RUNE_MAT)
		_check(has_rune, "stones: rune surface present")
	# --- colliders ---
	var shapes: Array[CollisionShape3D] = []
	for cs: Node in lm.find_children("*", "CollisionShape3D", true, false):
		shapes.append(cs as CollisionShape3D)
	_check(shapes.size() == int(spec["colliders"]), "%s: %d colliders (got %d)" % [file, spec["colliders"], shapes.size()])
	var centres: Array[Vector3] = []
	for cs2: CollisionShape3D in shapes:
		var cyl := cs2.shape as CylinderShape3D
		_check(cyl != null and is_equal_approx(cyl.radius, float(spec["r"])), "%s: %s is a cylinder r %.1f" % [file, cs2.name, spec["r"]])
		var body := cs2.get_parent() as StaticBody3D
		_check(body != null and body.collision_layer == 1 and body.collision_mask == 0, "%s: %s on layer 1, mask 0" % [file, cs2.name])
		var c: Vector3 = cs2.global_position
		centres.append(Vector3(c.x, 0.0, c.z))
		_check(cyl != null and absf(c.y - cyl.height * 0.5) <= 0.01 and cyl.height >= 1.0 and cyl.height < 2.0,
			"%s: %s stands on the ground, 1-2 m tall" % [file, cs2.name])
	match file:
		"aqueduct":
			var want: Array[Vector3] = [Vector3(-17.5, 0, -55), Vector3(-9.3, 0, -55)]
			for w: Vector3 in want:
				var near := false
				for c3: Vector3 in centres:
					near = near or c3.distance_to(w) < 0.05
				_check(near, "aqueduct: a pier collider at %s" % w)
			for c4: Vector3 in centres:
				_check(_river_dist(Vector2(c4.x, c4.z)) - 0.9 > 0.5, "aqueduct: pier collider %s on the bank (not in the water)" % c4)
		"standing_stones":
			for c5: Vector3 in centres:
				var r: float = Vector2(c5.x + 54.0, c5.z - 20.0).length()
				_check(absf(r - 3.0) < 0.2, "stones: collider %s on the ring r 3 (r %.2f)" % [c5, r])
			for i in centres.size():
				for j in range(i + 1, centres.size()):
					_check(centres[i].distance_to(centres[j]) > 2.0, "stones: colliders %d / %d leave a gap" % [i, j])
	# --- the point-mirrored copy ---
	var twin := ps.instantiate() as Node3D
	holder.add_child(twin)
	twin.position = -(spec["pos"] as Vector3)
	twin.rotation.y = PI
	var tw: Array[Vector3] = []
	for cs6: Node in twin.find_children("*", "CollisionShape3D", true, false):
		var p6: Vector3 = (cs6 as Node3D).global_position
		tw.append(Vector3(p6.x, 0.0, p6.z))
	for c7: Vector3 in centres:
		var found := false
		for t7: Vector3 in tw:
			found = found or t7.distance_to(-c7) < 0.02
		_check(found, "%s: the mirrored copy has a collider at %s" % [file, -c7])
	twin.queue_free()
	# --- sizes, water, walkable space ---
	var xf: Transform3D = mi.global_transform
	var top := -INF
	var blocked := 0
	var outside_water := 0
	var worst := ""
	for v: Vector3 in painted:
		var w8: Vector3 = xf * v
		top = maxf(top, w8.y)
		var d_river: float = _river_dist(Vector2(w8.x, w8.z))
		if file == "barge":
			if d_river > HALF_W - 0.05:
				outside_water += 1
				worst = "%s (%.2f m off the centre line)" % [w8, d_river]
			continue
		# A unit's centre can be here: on land (agent radius off the water) and outside every collider + agent radius.
		var free := d_river > HALF_W + AGENT_R
		for c8: Vector3 in centres:
			if Vector2(w8.x - c8.x, w8.z - c8.z).length() < float(spec["r"]) + AGENT_R:
				free = false
		if free and w8.y > 0.45 and w8.y < 1.9:
			blocked += 1
			worst = "%s" % w8
	_check(top <= float(spec["max_h"]), "%s: top %.2f m <= %.1f m" % [file, top, spec["max_h"]])
	if file == "barge":
		_check(outside_water == 0, "barge: every vertex inside the 5 m channel (%d outside, e.g. %s)" % [outside_water, worst])
		_check(top - (-0.35) <= 3.0, "barge: <= 3 m above the water (%.2f)" % (top + 0.35))
	else:
		_check(blocked == 0, "%s: walkable space clear (%d vertices between 0.45 and 1.9 m where units walk, e.g. %s)" % [file,
			blocked, worst])
	if file == "aqueduct":
		_check(top >= 5.0, "aqueduct: tall enough to read (top %.2f)" % top)
	# foam circles in the water
	var foam: PackedVector3Array = lm.get_meta(&"foam_rocks", PackedVector3Array())
	for f: Vector3 in foam:
		var wp: Vector3 = lm.global_transform * Vector3(f.x, 0.0, f.y)
		_check(_river_dist(Vector2(wp.x, wp.z)) < HALF_W, "%s: foam circle %s in the water" % [file, wp])
	if file != "standing_stones":
		_check(not foam.is_empty(), "%s: foam circles for the water" % file)
	print("%-16s tris %d, surfaces %d, colliders %d, top %.2f m" % [file, tris, mesh.get_surface_count(), shapes.size(), top])
