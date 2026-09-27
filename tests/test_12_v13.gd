extends SceneTree
## Task 12.V13 (Landmarks A): the Fallen Colossus and the Giant's Stump.
## Run:  godot --headless --path . -s tests/test_12_v13.gd --fixed-fps 60 --quit-after 1200
## Checks (map-fill.md 3.2 / 9 / 10, step12-agent-rules.md 5):
## - both scenes load and instantiate without errors; root Node3D in group "landmarks" with `landmark_id` /
##   `decor_clear_radius` metadata; 0 lights, 0 particles; one MeshInstance3D "Model" whose surfaces use the SHARED
##   painted nature material + the shared contact material (+ the colossus rune glow), no runtime materials;
##   indexed meshes, triangle budgets, heights (low enough not to hide units);
## - colliders: StaticBody3D "Collision" on layer 1 (world), mask 0; colossus = head cylinder r 2.2 + hand box
##   3 x 1.5, everything within 3.5 m of the centre; stump = one cylinder r 2.0 at the centre;
## - the model does not hang over its colliders above knee height (units would clip into it): every painted vertex
##   higher than 0.5 m is within 0.5 m of the collider footprints;
## - placed at the map spots (player side + the PI-turned mirror), the colliders are point-mirrored, a ray down hits
##   them on layer 1, and a navmesh baked from static colliders (like main.gd) leaves them out (+ agent radius).

const TASK_ID := "12.v13"
const COLOSSUS := "res://art/environment/landmarks/colossus.tscn"
const STUMP := "res://art/environment/landmarks/giant_stump.tscn"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const CONTACT_MAT := "res://art/environment/nature_props/nature_contact_mat.tres"
const RUNE_MAT := "res://art/environment/landmarks/colossus_rune_mat.tres"
const SPOTS := {&"lm_colossus": Vector3(-57, 0, -16), &"lm_stump": Vector3(-30, 0, 20)}
const TRI_BUDGET := {&"lm_colossus": 12000, &"lm_stump": 10000}
const MAX_HEIGHT := {&"lm_colossus": 2.9, &"lm_stump": 3.9}

var _fails: Array[String] = []
var _frame := 0
var _placed: Array[Node3D] = []
var _nav: NavigationRegion3D
var _stage: Node3D


func _fail(msg: String) -> void:
	_fails.append(msg)
	print("  FAIL: " + msg)


func _initialize() -> void:
	for path: String in [COLOSSUS, STUMP]:
		if not ResourceLoader.exists(path):
			_fail("missing " + path)
			continue
		var ps := load(path) as PackedScene
		var n: Node = ps.instantiate() if ps else null
		if not (n is Node3D):
			_fail("%s does not instantiate a Node3D" % path)
			continue
		_check_static(n as Node3D, path)
		n.free()
	_stage = Node3D.new()
	_stage.name = "Stage"
	root.add_child(_stage)
	# Map placement: player side + mirror (turned by PI), under a nav region with a ground slab.
	_nav = NavigationRegion3D.new()
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nm.agent_radius = 0.5
	nm.agent_height = 2.0
	nm.agent_max_climb = 0.25
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	_nav.navigation_mesh = nm
	_stage.add_child(_nav)
	var ground := StaticBody3D.new()
	var gs := CollisionShape3D.new()
	var gb := BoxShape3D.new()
	gb.size = Vector3(160, 1, 80)
	gs.shape = gb
	gs.position = Vector3(0, -0.5, 0)
	ground.add_child(gs)
	_nav.add_child(ground)
	for id: StringName in SPOTS:
		var path2: String = COLOSSUS if id == &"lm_colossus" else STUMP
		if not ResourceLoader.exists(path2):
			continue
		for side: int in 2:
			var inst := (load(path2) as PackedScene).instantiate() as Node3D
			inst.position = SPOTS[id] * (1.0 if side == 0 else -1.0)
			inst.rotation.y = 0.0 if side == 0 else PI
			_nav.add_child(inst)
			_placed.append(inst)


func _check_static(n: Node3D, path: String) -> void:
	var id: StringName = n.get_meta(&"landmark_id", &"")
	print("%s: id %s" % [path.get_file(), id])
	if not SPOTS.has(id):
		_fail("%s: landmark_id meta %s" % [path, id])
		return
	if not n.is_in_group(&"landmarks"):
		_fail("%s: not in group landmarks" % path)
	var lights: int = n.find_children("*", "Light3D", true, false).size()
	var parts: int = n.find_children("*", "GPUParticles3D", true, false).size() + \
		n.find_children("*", "CPUParticles3D", true, false).size()
	if lights != 0 or parts != 0:
		_fail("%s: %d lights, %d particle systems (want 0)" % [path, lights, parts])
	if n.get_script() != null:
		_fail("%s: root has a script (want a plain scene)" % path)
	# Model.
	var mi := n.get_node_or_null(^"Model") as MeshInstance3D
	if mi == null or mi.mesh == null:
		_fail("%s: no Model mesh" % path)
		return
	var meshes: int = n.find_children("*", "MeshInstance3D", true, false).size()
	if meshes != 1:
		_fail("%s: %d MeshInstance3D (want 1 merged model)" % [path, meshes])
	var mesh: Mesh = mi.mesh
	var want: Array[String] = [NATURE_MAT, CONTACT_MAT]
	if id == &"lm_colossus":
		want.append(RUNE_MAT)
	if mesh.get_surface_count() != want.size():
		_fail("%s: %d surfaces (want %d)" % [path, mesh.get_surface_count(), want.size()])
	var tris := 0
	var max_y := -INF
	var painted := PackedVector3Array()
	for s: int in mesh.get_surface_count():
		var m: Material = mesh.surface_get_material(s)
		var mp: String = m.resource_path if m else "<none>"
		if s < want.size() and mp != want[s]:
			_fail("%s: surface %d material %s (want the shared %s)" % [path, s, mp, want[s]])
		var arr: Array = mesh.surface_get_arrays(s)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if idx.is_empty():
			_fail("%s: surface %d not indexed" % [path, s])
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		tris += idx.size() / 3
		if s == 0:
			painted = verts
			for v: Vector3 in verts:
				max_y = maxf(max_y, v.y)
	var overridden: bool = mi.material_override != null
	for s2: int in mi.get_surface_override_material_count():
		overridden = overridden or mi.get_surface_override_material(s2) != null
	if overridden:
		_fail("%s: Model has override materials" % path)
	print("  %d triangles, top at %.2f m" % [tris, max_y])
	if tris > int(TRI_BUDGET[id]):
		_fail("%s: %d triangles > budget %d" % [path, tris, TRI_BUDGET[id]])
	if max_y > float(MAX_HEIGHT[id]):
		_fail("%s: top at %.2f m > %.2f (would hide units)" % [path, max_y, MAX_HEIGHT[id]])
	# Colliders.
	var body := n.get_node_or_null(^"Collision") as StaticBody3D
	if body == null:
		_fail("%s: no StaticBody3D Collision" % path)
		return
	if body.collision_layer != 1 or body.collision_mask != 0:
		_fail("%s: collision layer %d mask %d (want 1 / 0)" % [path, body.collision_layer, body.collision_mask])
	var cyls: Array[CollisionShape3D] = []
	var boxes: Array[CollisionShape3D] = []
	for c: Node in body.get_children():
		var cs := c as CollisionShape3D
		if cs == null:
			continue
		if cs.shape is CylinderShape3D:
			cyls.append(cs)
		elif cs.shape is BoxShape3D:
			boxes.append(cs)
		else:
			_fail("%s: unexpected shape %s" % [path, cs.shape])
	if id == &"lm_colossus":
		if cyls.size() != 1 or boxes.size() != 1:
			_fail("colossus: %d cylinders, %d boxes (want 1 + 1)" % [cyls.size(), boxes.size()])
			return
		var cy := cyls[0].shape as CylinderShape3D
		if not is_equal_approx(cy.radius, 2.2):
			_fail("colossus: head radius %.2f (want 2.2)" % cy.radius)
		var bx := boxes[0].shape as BoxShape3D
		var xz: Array[float] = [bx.size.x, bx.size.z]
		xz.sort()
		if not (is_equal_approx(xz[0], 1.5) and is_equal_approx(xz[1], 3.0)):
			_fail("colossus: hand box %s (want 3 x 1.5)" % bx.size)
		var reach: float = Vector2(cyls[0].position.x, cyls[0].position.z).length() + cy.radius
		for sx: float in [-0.5, 0.5]:
			for sz: float in [-0.5, 0.5]:
				var corner: Vector3 = boxes[0].transform * Vector3(bx.size.x * sx, 0.0, bx.size.z * sz)
				reach = maxf(reach, Vector2(corner.x, corner.z).length())
		print("  colliders reach %.3f m from the centre" % reach)
		if reach > 3.5 + 0.001:
			_fail("colossus: colliders reach %.2f m (> 3.5)" % reach)
	else:
		if cyls.size() != 1 or boxes.size() != 0:
			_fail("stump: %d cylinders, %d boxes (want 1)" % [cyls.size(), boxes.size()])
			return
		var cy2 := cyls[0].shape as CylinderShape3D
		if not is_equal_approx(cy2.radius, 2.0) or Vector2(cyls[0].position.x, cyls[0].position.z).length() > 0.01:
			_fail("stump: cylinder r %.2f at %s (want r 2.0 at the centre)" % [cy2.radius, cyls[0].position])
	for cs2: CollisionShape3D in cyls + boxes:
		var lo: float = cs2.position.y - _half_h(cs2.shape)
		var hi: float = cs2.position.y + _half_h(cs2.shape)
		# From the ground to >= 1.5 m, but the top under the nav agent height (2.0): a taller hollow collider bakes a
		# walkable island inside itself.
		if lo > 0.05 or hi < 1.5 or hi >= 1.95:
			_fail("%s: shape %s spans y %.2f..%.2f (want <= 0 .. 1.5-1.95 m)" % [path, cs2.name, lo, hi])
	# Overhang: tall parts must stay over the collider footprints.
	var worst := 0.0
	var worst_p := Vector3.ZERO
	for v2: Vector3 in painted:
		if v2.y <= 0.5:
			continue
		var d: float = INF
		for c1: CollisionShape3D in cyls:
			d = minf(d, maxf(Vector2(v2.x - c1.position.x, v2.z - c1.position.z).length() - (c1.shape as CylinderShape3D).radius, 0.0))
		for b1: CollisionShape3D in boxes:
			var lp: Vector3 = b1.transform.affine_inverse() * v2
			var hs: Vector3 = (b1.shape as BoxShape3D).size * 0.5
			d = minf(d, Vector2(maxf(absf(lp.x) - hs.x, 0.0), maxf(absf(lp.z) - hs.z, 0.0)).length())
		if d > worst:
			worst = d
			worst_p = v2
	print("  worst overhang above 0.5 m: %.2f m at %s" % [worst, worst_p])
	if worst > 0.5:
		_fail("%s: model hangs %.2f m past its colliders at %s" % [path, worst, worst_p])
	var clear_r: float = n.get_meta(&"decor_clear_radius", 0.0)
	if clear_r < 3.0:
		_fail("%s: decor_clear_radius %.2f" % [path, clear_r])


func _half_h(s: Shape3D) -> float:
	if s is CylinderShape3D:
		return (s as CylinderShape3D).height * 0.5
	if s is BoxShape3D:
		return (s as BoxShape3D).size.y * 0.5
	return 0.0


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 3:
		_check_placed()
		_nav.bake_navigation_mesh(false)
		_check_nav()
		_finish()
		return true
	return false


func _shapes_of(n: Node3D) -> Array[CollisionShape3D]:
	var out: Array[CollisionShape3D] = []
	for c: Node in n.find_children("*", "CollisionShape3D", true, false):
		out.append(c as CollisionShape3D)
	return out


func _check_placed() -> void:
	if _placed.size() != 4:
		_fail("placed %d landmarks (want 4)" % _placed.size())
		return
	var space: PhysicsDirectSpaceState3D = _stage.get_world_3d().direct_space_state
	for i: int in range(0, 4, 2):
		var a: Node3D = _placed[i]
		var b: Node3D = _placed[i + 1]
		var sa := _shapes_of(a)
		var sb := _shapes_of(b)
		for s: CollisionShape3D in sa:
			var mirrored := false
			for t: CollisionShape3D in sb:
				var pa: Vector3 = s.global_position
				var pb: Vector3 = t.global_position
				if Vector2(pa.x + pb.x, pa.z + pb.z).length() < 0.01 and absf(pa.y - pb.y) < 0.01 \
						and s.shape.get_class() == t.shape.get_class():
					mirrored = true
			if not mirrored:
				_fail("%s: shape %s has no point-mirrored twin" % [a.name, s.name])
			# A ray straight down onto the shape hits the landmark on the world layer.
			var q := PhysicsRayQueryParameters3D.create(s.global_position + Vector3(0, 6, 0),
				s.global_position + Vector3(0, -1, 0), 1)
			var hit: Dictionary = space.intersect_ray(q)
			if hit.is_empty() or not a.is_ancestor_of(hit.collider as Node):
				_fail("%s: ray down on %s does not hit it (layer 1)" % [a.name, s.name])
		# 5 m past the collider edge in open ground: no hit on the landmark.
		var far: Vector3 = a.global_position + Vector3(0, 0, 7.5)
		var q2 := PhysicsRayQueryParameters3D.create(far + Vector3(0, 6, 0), far + Vector3(0, 0.05, 0), 1)
		var hit2: Dictionary = space.intersect_ray(q2)
		if not hit2.is_empty():
			_fail("%s: something blocks 7.5 m from the centre" % a.name)


func _check_nav() -> void:
	var nm: NavigationMesh = _nav.navigation_mesh
	var verts: PackedVector3Array = nm.get_vertices()
	if verts.size() < 8:
		_fail("navmesh bake produced %d vertices" % verts.size())
		return
	var worst := INF
	for l: Node3D in _placed:
		for s: CollisionShape3D in _shapes_of(l):
			for v: Vector3 in verts:
				if v.y > 0.5:
					continue   # the flat collider tops bake unreachable islands (like tree colliders): ignored
				var d := 0.0
				if s.shape is CylinderShape3D:
					d = Vector2(v.x - s.global_position.x, v.z - s.global_position.z).length() - (s.shape as CylinderShape3D).radius
				else:
					var lp: Vector3 = s.global_transform.affine_inverse() * v
					var hs: Vector3 = (s.shape as BoxShape3D).size * 0.5
					var ox: float = absf(lp.x) - hs.x
					var oz: float = absf(lp.z) - hs.z
					d = Vector2(maxf(ox, 0.0), maxf(oz, 0.0)).length() if (ox > 0.0 or oz > 0.0) else maxf(ox, oz)
				worst = minf(worst, d)
	# Polygon vertices sit >= agent radius (0.5) from every collider, minus a cell of rasterisation slack.
	print("navmesh: %d vertices, %d polygons; closest vertex to a landmark collider %.2f m" % [verts.size(),
		nm.get_polygon_count(), worst])
	if worst < 0.25:
		_fail("navmesh gets within %.2f m of a landmark collider (not blocked like terrain)" % worst)
	# Every ground polygon centre is outside the colliders (no walkable ground inside a landmark).
	for p: int in nm.get_polygon_count():
		var poly: PackedInt32Array = nm.get_polygon(p)
		var c := Vector3.ZERO
		for k: int in poly:
			c += verts[k]
		c /= float(poly.size())
		if c.y > 0.5:
			continue
		for l2: Node3D in _placed:
			for s2: CollisionShape3D in _shapes_of(l2):
				var inside := false
				if s2.shape is CylinderShape3D:
					inside = Vector2(c.x - s2.global_position.x, c.z - s2.global_position.z).length() < (s2.shape as CylinderShape3D).radius
				else:
					var lp2: Vector3 = s2.global_transform.affine_inverse() * c
					var hs2: Vector3 = (s2.shape as BoxShape3D).size * 0.5
					inside = absf(lp2.x) < hs2.x and absf(lp2.z) < hs2.z
				if inside:
					_fail("%s: a ground navmesh polygon lies inside %s (%s)" % [l2.name, s2.name, c])


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
