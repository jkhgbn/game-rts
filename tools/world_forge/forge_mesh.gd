extends RefCounted
## World Forge meshes: the instance baker (many copies of mesh-only kits -> one ArrayMesh surface per material, so
## scatter survives headless runs, where MultiMesh transforms are dropped, and costs one draw per material) and the
## procedural pieces (ground, path ribbons, walls, braziers, stakes, crates). Everything is deterministic.
## No class_name on purpose (preloaded tool script).

## Merge buckets: key -> {material, v, n, t, c, uv, idx}
var buckets := {}
var _order: Array[String] = []


## True when a kit scene is only Node3D / MeshInstance3D without scripts (safe to bake).
static func is_bakeable(node: Node) -> bool:
	if node.get_script() != null:
		return false
	if not (node is MeshInstance3D or node.get_class() == "Node3D"):
		return false
	for c in node.get_children():
		if not is_bakeable(c):
			return false
	return true


## Adds every mesh under `node` (its own transform ignored) placed with `xf`.
func add_node(node: Node, xf: Transform3D, local := Transform3D.IDENTITY) -> void:
	var here := local
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh and mi.visible:
			for s in mi.mesh.get_surface_count():
				var mat: Material = mi.get_surface_override_material(s)
				if mat == null:
					mat = mi.material_override
				if mat == null:
					mat = mi.mesh.surface_get_material(s)
				add_surface(mi.mesh, s, mat, xf * here)
	for c in node.get_children():
		if c is Node3D:
			add_node(c, xf, here * (c as Node3D).transform)


## Adds surface `s` of `mesh` transformed by `xf` to the bucket of its material.
func add_surface(mesh: Mesh, s: int, mat: Material, xf: Transform3D) -> void:
	if mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
		return
	var arr := mesh.surface_get_arrays(s)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	if v.is_empty():
		return
	var key := "%d" % (mat.get_instance_id() if mat else 0)
	if not buckets.has(key):
		buckets[key] = {"material": mat, "v": PackedVector3Array(), "n": PackedVector3Array(), "t": PackedFloat32Array(),
			"c": PackedColorArray(), "uv": PackedVector2Array(), "uv2": PackedVector2Array(), "idx": PackedInt32Array(),
			"has_t": false, "has_uv2": false}
		_order.append(key)
	var b: Dictionary = buckets[key]
	var base: int = (b["v"] as PackedVector3Array).size()
	var nb := xf.basis.inverse().transposed()
	var flip := xf.basis.determinant() < 0.0
	var n: Variant = arr[Mesh.ARRAY_NORMAL]
	var t: Variant = arr[Mesh.ARRAY_TANGENT]
	var c: Variant = arr[Mesh.ARRAY_COLOR]
	var uv: Variant = arr[Mesh.ARRAY_TEX_UV]
	var uv2: Variant = arr[Mesh.ARRAY_TEX_UV2]
	var bv: PackedVector3Array = b["v"]
	var bn: PackedVector3Array = b["n"]
	var bt: PackedFloat32Array = b["t"]
	var bc: PackedColorArray = b["c"]
	var buv: PackedVector2Array = b["uv"]
	var buv2: PackedVector2Array = b["uv2"]
	for i in v.size():
		bv.append(xf * v[i])
		bn.append((nb * (n[i] as Vector3)).normalized() if n is PackedVector3Array and not (n as PackedVector3Array).is_empty() else Vector3.UP)
		if t is PackedFloat32Array and (t as PackedFloat32Array).size() >= (i + 1) * 4:
			var tv := (xf.basis * Vector3(t[i * 4], t[i * 4 + 1], t[i * 4 + 2])).normalized()
			bt.append_array([tv.x, tv.y, tv.z, t[i * 4 + 3] * (-1.0 if flip else 1.0)])
			b["has_t"] = true
		else:
			bt.append_array([1.0, 0.0, 0.0, 1.0])
		bc.append(c[i] if c is PackedColorArray and not (c as PackedColorArray).is_empty() else Color.WHITE)
		buv.append(uv[i] if uv is PackedVector2Array and not (uv as PackedVector2Array).is_empty() else Vector2.ZERO)
		if uv2 is PackedVector2Array and not (uv2 as PackedVector2Array).is_empty():
			buv2.append(uv2[i])
			b["has_uv2"] = true
		else:
			buv2.append(Vector2.ZERO)
	var idx: Variant = arr[Mesh.ARRAY_INDEX]
	var bi: PackedInt32Array = b["idx"]
	if idx is PackedInt32Array and not (idx as PackedInt32Array).is_empty():
		var ii: PackedInt32Array = idx
		for k in range(0, ii.size(), 3):
			if flip:
				bi.append_array([base + ii[k], base + ii[k + 2], base + ii[k + 1]])
			else:
				bi.append_array([base + ii[k], base + ii[k + 1], base + ii[k + 2]])
	else:
		for k in range(0, v.size(), 3):
			if flip:
				bi.append_array([base + k, base + k + 2, base + k + 1])
			else:
				bi.append_array([base + k, base + k + 1, base + k + 2])
	b["v"] = bv
	b["n"] = bn
	b["t"] = bt
	b["c"] = bc
	b["uv"] = buv
	b["uv2"] = buv2
	b["idx"] = bi


## One ArrayMesh with a surface per material bucket (null when empty).
func commit() -> ArrayMesh:
	if _order.is_empty():
		return null
	var m := ArrayMesh.new()
	for key in _order:
		var b: Dictionary = buckets[key]
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = b["v"]
		arr[Mesh.ARRAY_NORMAL] = b["n"]
		if b["has_t"]:
			arr[Mesh.ARRAY_TANGENT] = b["t"]
		arr[Mesh.ARRAY_COLOR] = b["c"]
		arr[Mesh.ARRAY_TEX_UV] = b["uv"]
		if b["has_uv2"]:
			arr[Mesh.ARRAY_TEX_UV2] = b["uv2"]
		arr[Mesh.ARRAY_INDEX] = b["idx"]
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		if b["material"]:
			m.surface_set_material(m.get_surface_count() - 1, b["material"])
	return m


# ---------------------------------------------------------------- procedural pieces

static func vc_material(emissive := false, rough := 0.92, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = rough
	m.metallic = metal
	if emissive:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


## Deterministic hash noise in 0..1.
static func hash01(x: float, z: float, seed: int) -> float:
	var h := int(floor(x * 73.0)) * 73856093 ^ int(floor(z * 71.0)) * 19349663 ^ seed * 83492791
	h = (h ^ (h >> 13)) * 1274126177
	return float((h ^ (h >> 16)) & 0xffff) / 65535.0


static func value_noise(x: float, z: float, cell: float, seed: int) -> float:
	var gx := floorf(x / cell)
	var gz := floorf(z / cell)
	var fx := x / cell - gx
	var fz := z / cell - gz
	fx = fx * fx * (3.0 - 2.0 * fx)
	fz = fz * fz * (3.0 - 2.0 * fz)
	var a := hash01(gx, gz, seed)
	var b := hash01(gx + 1.0, gz, seed)
	var c := hash01(gx, gz + 1.0, seed)
	var d := hash01(gx + 1.0, gz + 1.0, seed)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fz)


## A flat ground grid (size x, z), vertex colours from `base` with low-frequency mottling.
static func ground(size: Vector2, base: Color, seed: int, step := 2.0) -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := int(ceil(size.x / step))
	var nz := int(ceil(size.y / step))
	var x0 := -size.x * 0.5
	var z0 := -size.y * 0.5
	for i in nx:
		for j in nz:
			var quad := [Vector3(x0 + i * step, 0, z0 + j * step), Vector3(x0 + (i + 1) * step, 0, z0 + j * step),
				Vector3(x0 + (i + 1) * step, 0, z0 + (j + 1) * step), Vector3(x0 + i * step, 0, z0 + (j + 1) * step)]
			for k in [0, 1, 2, 0, 2, 3]:
				var p: Vector3 = quad[k]
				var nval := value_noise(p.x, p.z, 7.0, seed) * 0.6 + value_noise(p.x, p.z, 2.5, seed + 1) * 0.4
				st.set_color(base.darkened(0.18).lerp(base.lightened(0.12), nval))
				st.set_normal(Vector3.UP)
				st.add_vertex(p)
	return st


## A ribbon along a polyline at height y (width w).
## `ground` (optional, Callable(x, z) -> height) drapes the ribbon over terrain.
static func ribbon(st: SurfaceTool, poly: PackedVector3Array, w: float, col: Color, y: float, seed: int, ground := Callable()) -> void:
	for k in range(poly.size() - 1):
		var a := poly[k]
		var b := poly[k + 1]
		var d := Vector3(b.x - a.x, 0, b.z - a.z).normalized()
		var side := Vector3(-d.z, 0, d.x) * w * 0.5
		var n := maxi(1, int((b - a).length() / (2.0 if not ground.is_valid() else 1.0)))
		for s in n:
			var p0 := a.lerp(b, float(s) / n)
			var p1 := a.lerp(b, float(s + 1) / n)
			var j0 := side * (1.0 + 0.12 * (hash01(p0.x, p0.z, seed) - 0.5))
			var j1 := side * (1.0 + 0.12 * (hash01(p1.x, p1.z, seed) - 0.5))
			var q := [p0 - j0, p1 - j1, p1 + j1, p0 + j0]
			for i in [0, 1, 2, 0, 2, 3]:
				var p: Vector3 = q[i]
				st.set_color(col.lerp(col.darkened(0.25), hash01(p.x * 0.5, p.z * 0.5, seed + 3)))
				st.set_normal(Vector3.UP)
				st.add_vertex(Vector3(p.x, y + (float(ground.call(p.x, p.z)) if ground.is_valid() else 0.0), p.z))


## Adds an axis-aligned box (local to xf) with a colour.
static func box(st: SurfaceTool, xf: Transform3D, center: Vector3, half: Vector3, col: Color) -> void:
	var faces := [[Vector3.RIGHT, Vector3.UP, Vector3.BACK], [Vector3.LEFT, Vector3.UP, Vector3.FORWARD],
		[Vector3.UP, Vector3.BACK, Vector3.RIGHT], [Vector3.DOWN, Vector3.FORWARD, Vector3.RIGHT],
		[Vector3.BACK, Vector3.UP, Vector3.LEFT], [Vector3.FORWARD, Vector3.UP, Vector3.RIGHT]]
	for f: Array in faces:
		var n: Vector3 = f[0]
		var u: Vector3 = f[1]
		var r: Vector3 = f[2]
		var c := center + n * half
		var du := u * half
		var dr := r * half
		var q := [c - du - dr, c - du + dr, c + du + dr, c + du - dr]
		var shade := 0.82 + 0.18 * maxf(0.0, n.y) - 0.1 * maxf(0.0, -n.y)
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_color(Color(col.r * shade, col.g * shade, col.b * shade))
			st.set_normal((xf.basis * n).normalized())
			st.add_vertex(xf * (q[i] as Vector3))


## A crenellated wall along a polyline, skipping gates [{at: Vector3, width}]. Returns the collider boxes
## [{xf, half}] so the checks can test cameras against it.
static func wall(st: SurfaceTool, poly: PackedVector3Array, height: float, thick: float, col: Color, gates: Array, seed: int, ground := Callable()) -> Array:
	var boxes: Array = []
	var gv := ground.is_valid()
	for k in range(poly.size() - 1):
		var a := Vector3(poly[k].x, 0, poly[k].z)
		var b := Vector3(poly[k + 1].x, 0, poly[k + 1].z)
		var length := Vector2(b.x - a.x, b.z - a.z).length()
		var dir := Vector3(b.x - a.x, 0, b.z - a.z).normalized()
		var xf := Transform3D(Basis(Vector3.UP, atan2(-dir.z, dir.x)), a)
		var n := maxi(1, int(round(length / 2.0)))
		var seg := length / n
		for s in n:
			var mid_local := Vector3(seg * (s + 0.5), 0, 0)
			var mid_world := xf * mid_local
			var gated := false
			for g: Dictionary in gates:
				if Vector2(mid_world.x - g["at"].x, mid_world.z - g["at"].z).length() < float(g["width"]) * 0.5 + seg * 0.25:
					gated = true
			if gated:
				continue
			var tone := col.lerp(col.darkened(0.2), hash01(mid_world.x, mid_world.z, seed))
			# on terrain: the segment stands on the ground at its middle and sinks below its lowest end
			var gy := 0.0
			var sink := 0.0
			if gv:
				var w0 := xf * Vector3(seg * s, 0, 0)
				var w1 := xf * Vector3(seg * (s + 1), 0, 0)
				gy = float(ground.call(mid_world.x, mid_world.z))
				sink = gy - minf(gy, minf(float(ground.call(w0.x, w0.z)), float(ground.call(w1.x, w1.z)))) + 0.4
			var body_c := mid_local + Vector3(0, gy + height * 0.5 - sink * 0.5, 0)
			var body_h := Vector3(seg * 0.5, height * 0.5 + sink * 0.5, thick * 0.5)
			box(st, xf, body_c, body_h + Vector3(0.02, 0, 0), tone)
			boxes.append({"xf": xf, "center": body_c, "half": body_h})
			# merlon on every segment, a crenel gap between (the merlon covers the middle 55 %)
			box(st, xf, mid_local + Vector3(0, gy + height + 0.35, 0), Vector3(seg * 0.275, 0.35, thick * 0.5 + 0.05), tone.lightened(0.06))
			# a darker plinth course
			box(st, xf, mid_local + Vector3(0, gy + 0.3 - sink * 0.5, 0), Vector3(seg * 0.5 + 0.03, 0.3 + sink * 0.5, thick * 0.5 + 0.12), tone.darkened(0.25))
		# a tower stub on each corner
		_tower(st, boxes, a, height, thick, col, ground)
	var lp := poly[poly.size() - 1]
	_tower(st, boxes, Vector3(lp.x, 0, lp.z), height, thick, col, ground)
	return boxes


static func _tower(st: SurfaceTool, boxes: Array, a: Vector3, height: float, thick: float, col: Color, ground: Callable) -> void:
	var gy := float(ground.call(a.x, a.z)) if ground.is_valid() else 0.0
	var sink := 0.6 if ground.is_valid() else 0.0
	var c := Vector3(0, gy + height * 0.6 - sink * 0.5, 0)
	var hf := Vector3(thick, height * 0.6 + sink * 0.5, thick)
	box(st, Transform3D(Basis(), a), c, hf, col.darkened(0.1))
	boxes.append({"xf": Transform3D(Basis(), a), "center": c, "half": hf})


## Procedural props: brazier (stone bowl + glowing coals), stake (charred post), crate. `glow` gets the emissive parts.
static func prop(kind: String, st: SurfaceTool, glow: SurfaceTool, xf: Transform3D, seed: int) -> void:
	match kind:
		"brazier":
			box(st, xf, Vector3(0, 0.5, 0), Vector3(0.14, 0.5, 0.14), Color(0.18, 0.16, 0.15))
			box(st, xf, Vector3(0, 1.05, 0), Vector3(0.42, 0.1, 0.42), Color(0.30, 0.26, 0.24))
			box(st, xf, Vector3(0, 0.05, 0), Vector3(0.35, 0.05, 0.35), Color(0.22, 0.2, 0.19))
			box(glow, xf, Vector3(0, 1.2, 0), Vector3(0.3, 0.07, 0.3), Color(1.0, 0.55, 0.15))
			box(glow, xf, Vector3(0.05, 1.32, -0.04), Vector3(0.14, 0.08, 0.14), Color(1.0, 0.8, 0.35))
		"stake":
			var h := 1.4 + 0.6 * hash01(xf.origin.x, xf.origin.z, seed)
			box(st, xf, Vector3(0, h * 0.5, 0), Vector3(0.09, h * 0.5, 0.09), Color(0.12, 0.09, 0.07))
			box(glow, xf, Vector3(0, h + 0.05, 0), Vector3(0.07, 0.05, 0.07), Color(1.0, 0.45, 0.1))
		"crate":
			box(st, xf, Vector3(0, 0.4, 0), Vector3(0.45, 0.4, 0.45), Color(0.40, 0.28, 0.17))
			box(st, xf, Vector3(0, 0.81, 0), Vector3(0.47, 0.02, 0.47), Color(0.30, 0.2, 0.12))
