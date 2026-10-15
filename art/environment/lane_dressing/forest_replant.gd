extends RefCounted
## G-F review 2 item 10 (docs/art/gf_r2_autumn.md): the Wave Strike forest blocks are drawn by the level as trees on an
## even 4.6 m grid (WaveStrikeLevel._add_ws_block -> EnvProps.add_tree), which reads as an orchard. This look replants
## the trees INSIDE the layout's forest blocks after EnvProps.commit(): a jittered treeline along the lane-facing edge
## (the block is a wall: no gap there that looks walkable), clusters of one dominant species inside, one or two glades
## per block, three tree sizes. Same tree meshes and about the same instance count (no new draw, no runtime cost: the
## MultiMeshes are rebuilt once), so every tier gets it (Low = the cost before G1). Draw-only: the block colliders and
## the navmesh are the level's and do not change; trees outside the forest blocks are kept as they are.
## Reach it with load() (no class_name); LevelLooks.apply calls `ensure_for_level(level)` (windowed runs only).
## Deterministic: the plan depends only on the block rectangles.

const LANE_DRESSING := "res://art/environment/lane_dressing/lane_dressing.gd"
## EnvProps.TREES order: the MultiMeshInstance3D children are named after them (to_pascal_case).
const TREE_KINDS: Array[String] = ["tree_pine", "tree_broadleaf", "tree_fir"]
const MESH_DIR := "res://art/environment/meshes/"
const MARK := &"_forest_replanted"
const OLD_STEP := 4.6              ## the level's grid step (the instance count we aim for)
const GRID_JITTER := 1.6           ## the level's jitter (trees of a block can stand this far outside it)
const EDGE_STEP := Vector2(2.3, 4.0)   ## treeline spacing range (m) along the lane-facing edge
const EDGE_DEPTH := Vector2(0.2, 2.4)  ## treeline depth range (m) inside the block
## Planned trees per block vs the level grid: a bit denser, so the clusters still read as a wall (not a walkable meadow).
const DENSITY := 1.1
const MIN_GAP := 1.75              ## minimum distance between trunks (x the bigger size)
## Size classes [weight, min, max]: small, mid, large (the level drew 0.9-1.5 uniform).
const SIZES: Array = [[0.3, 0.72, 0.92], [0.45, 1.05, 1.28], [0.25, 1.45, 1.78]]


## Replants the level's forest blocks once. Returns the EnvProps node (dressed now or before), else null.
static func ensure_for_level(level: Node) -> Node:
	if level == null or not level.is_inside_tree() or not ResourceLoader.exists(LANE_DRESSING):
		return null
	var ld := load(LANE_DRESSING) as Script
	if ld == null or not bool(ld.call(&"wants", level)) or not (&"env_props" in level):
		return null
	var ep := level.get(&"env_props") as Node3D
	if ep == null:
		return null
	if ep.has_meta(MARK):
		return ep
	var rects := forest_rects(level.get(&"layout") as Resource)
	if rects.is_empty():
		return null
	replant(ep, rects, plan(rects, MapInfo.half_x(), MapInfo.half_z()))
	ep.set_meta(MARK, true)
	return ep


## The layout's forest blocks as world rectangles (x, z).
static func forest_rects(layout: Resource) -> Array[Rect2]:
	var out: Array[Rect2] = []
	if layout == null:
		return out
	var blocks: Variant = layout.get(&"blocks")
	if not (blocks is Array):
		return out
	for b: Variant in blocks:
		if not (b is Dictionary) or String((b as Dictionary).get("kind", "")) != "forest":
			continue
		var c: Vector3 = (b as Dictionary).get("center", Vector3.ZERO)
		var hb: Vector3 = (b as Dictionary).get("half", Vector3.ZERO)
		out.append(Rect2(c.x - hb.x, c.z - hb.z, hb.x * 2.0, hb.z * 2.0))
	return out


## The level's own count for a block (EnvProps grid: (int(w / 4.6) + 1) x (int(d / 4.6) + 1)).
static func grid_count(r: Rect2) -> int:
	return (int(r.size.x / OLD_STEP) + 1) * (int(r.size.y / OLD_STEP) + 1)


## The new trees: [{pos: Vector3, s: float, kind: int (TREE_KINDS index)}], about grid_count() per block.
static func plan(rects: Array[Rect2], half_x: float = 1e6, half_z: float = 1e6) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Rect2 in rects:
		out.append_array(_plan_block(r, half_x, half_z))
	return out


static func _plan_block(r: Rect2, half_x: float, half_z: float) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%.1f,%.1f,%.1f,%.1f" % [r.position.x, r.position.y, r.size.x, r.size.y])
	var target := int(grid_count(r) * DENSITY)
	var trees: Array[Dictionary] = []
	# The lane-facing edge (the long side nearest z = 0) and the inward direction.
	var c := r.get_center()
	var edge_z := r.end.y if c.y < 0.0 else r.position.y
	var inward := -1.0 if c.y < 0.0 else 1.0
	var base_kind := rng.randi_range(0, TREE_KINDS.size() - 1)
	# 1. Treeline: irregular spacing and depth, mostly mid / large trees.
	var x := r.position.x + rng.randf_range(0.4, 1.6)
	while x < r.end.x - 0.4:
		var p := Vector3(x, 0.0, edge_z + inward * rng.randf_range(EDGE_DEPTH.x, EDGE_DEPTH.y))
		var s := _size(rng, 0.35)
		_try_add(trees, p, s, _kind(rng, base_kind, 0.5), r, [], half_x, half_z)
		x += rng.randf_range(EDGE_STEP.x, EDGE_STEP.y)
	# 2. Glades: one per ~600 m2 (max 2), deep inside (>= 7 m from the lane edge), radius 3.5-6 m.
	var glades: Array[Vector3] = []
	var n_glades := clampi(int(r.get_area() / 600.0), 1, 2) if r.size.x > 14.0 and r.size.y > 14.0 else 0
	for i: int in n_glades:
		var gr := rng.randf_range(3.5, 6.0)
		var gz := edge_z + inward * rng.randf_range(maxf(7.0, gr + 4.0), maxf(r.size.y - gr * 0.6, gr + 4.5))
		var gx := rng.randf_range(r.position.x + gr * 0.7, r.end.x - gr * 0.7)
		glades.append(Vector3(gx, gz, gr))
	# 3. Clusters (one dominant species each) until the block's count is reached.
	var n_clusters := maxi(2, int(r.get_area() / 170.0))
	var centres: Array[Vector3] = []   # (x, z, sigma)
	for i: int in n_clusters:
		centres.append(Vector3(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y),
				rng.randf_range(2.0, 3.6)))
	var kinds: Array[int] = []
	for i: int in n_clusters:
		kinds.append(rng.randi_range(0, TREE_KINDS.size() - 1))
	var tries := 0
	while trees.size() < target and tries < target * 40:
		tries += 1
		var single := rng.randf() < 0.15
		var p2: Vector3
		var kind: int
		if single:
			p2 = Vector3(rng.randf_range(r.position.x, r.end.x), 0.0, rng.randf_range(r.position.y, r.end.y))
			kind = rng.randi_range(0, TREE_KINDS.size() - 1)
		else:
			var k := rng.randi_range(0, n_clusters - 1)
			var cc := centres[k]
			p2 = Vector3(cc.x + rng.randfn(0.0, cc.z), 0.0, cc.y + rng.randfn(0.0, cc.z))
			kind = _kind(rng, kinds[k], 0.75)
		_try_add(trees, p2, _size(rng, 0.0), kind, r, glades, half_x, half_z)
	return trees


## A size from the three classes; `big_bias` moves weight from small to large.
static func _size(rng: RandomNumberGenerator, big_bias: float) -> float:
	var w0: float = float(SIZES[0][0]) * (1.0 - big_bias)
	var w1: float = float(SIZES[1][0])
	var w2: float = float(SIZES[2][0]) + float(SIZES[0][0]) * big_bias
	var t := rng.randf() * (w0 + w1 + w2)
	var row: Array = SIZES[0] if t < w0 else (SIZES[1] if t < w0 + w1 else SIZES[2])
	return rng.randf_range(float(row[1]), float(row[2]))


static func _kind(rng: RandomNumberGenerator, dominant: int, share: float) -> int:
	return dominant if rng.randf() < share else rng.randi_range(0, TREE_KINDS.size() - 1)


static func _try_add(trees: Array[Dictionary], p: Vector3, s: float, kind: int, r: Rect2, glades: Array[Vector3],
		half_x: float, half_z: float) -> bool:
	if not r.grow(0.3).has_point(Vector2(p.x, p.z)):
		return false
	if absf(p.x) > half_x - 1.0 or absf(p.z) > half_z - 1.0:
		return false
	for g: Vector3 in glades:
		if Vector2(p.x - g.x, p.z - g.y).length() < g.z:
			return false
	for t: Dictionary in trees:
		var q: Vector3 = t["pos"]
		if Vector2(p.x - q.x, p.z - q.z).length() < MIN_GAP * maxf(s, float(t["s"])) * 0.8:
			return false
	trees.append({"pos": p, "s": s, "kind": kind})
	return true


## Rebuilds EnvProps' tree MultiMeshes: the instances inside a forest block (+ the level's jitter) are dropped, the
## planned trees added. Returns the instances placed by the plan.
static func replant(ep: Node3D, rects: Array[Rect2], trees: Array[Dictionary]) -> int:
	var by_kind: Array = []
	for i: int in TREE_KINDS.size():
		by_kind.append([])
	for t: Dictionary in trees:
		var p: Vector3 = t["pos"]
		var s := float(t["s"])
		var yaw := fposmod(sin(p.x * 12.9898 + p.z * 78.233) * 43758.5453, 1.0) * TAU
		(by_kind[int(t["kind"])] as Array).append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), p))
	var placed := 0
	for i: int in TREE_KINDS.size():
		var list: Array = by_kind[i]
		var node_name := TREE_KINDS[i].to_pascal_case()
		var mmi := ep.get_node_or_null(NodePath(node_name)) as MultiMeshInstance3D
		var keep: Array[Transform3D] = []
		if mmi and mmi.multimesh:
			for j: int in mmi.multimesh.instance_count:
				var xf := mmi.multimesh.get_instance_transform(j)
				if not _in_forest(xf.origin, rects):
					keep.append(xf)
		if mmi == null:
			if list.is_empty() or not ResourceLoader.exists(MESH_DIR + TREE_KINDS[i] + ".res"):
				continue
			mmi = MultiMeshInstance3D.new()
			mmi.name = node_name
			mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			ep.add_child(mmi)
		var mesh: Mesh = mmi.multimesh.mesh if mmi.multimesh else load(MESH_DIR + TREE_KINDS[i] + ".res") as Mesh
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = keep.size() + list.size()
		for j: int in keep.size():
			mm.set_instance_transform(j, keep[j])
		for j: int in list.size():
			mm.set_instance_transform(keep.size() + j, list[j])
		mmi.multimesh = mm
		placed += list.size()
	return placed


static func _in_forest(p: Vector3, rects: Array[Rect2]) -> bool:
	for r: Rect2 in rects:
		if r.grow(GRID_JITTER + 0.2).has_point(Vector2(p.x, p.z)):
			return true
	return false
