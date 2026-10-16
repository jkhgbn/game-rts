extends SceneTree
## Builds 4 Fire army scenes (art-units.md section 4; polish pass A.4; the Blaze Rider moved to 13.V10) as .tscn files, on the shared kit's
## materials (art/units/kit/materials/, closed palette 2.2) and the Fire model script.
## Positions below are relative to the unit's feet, face = +Z, weapon hand (ArmR) at +X (art-units.md 1.6).
## Shapes are custom meshes (lathe / tube / extrude) so the silhouettes are chunky and the toon ramp of
## unit_painted shades them in clean painted bands. Static parts are pre-merged here per (pivot, material), so a
## scene has few nodes (fast instancing) and the kit's runtime merge (one mesh per pivot) is unchanged.
## Run (headless is fine):
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . -s art/units/fire/build_fire_units.gd --quit-after 60
## Re-run after changing anything here; the .tscn files are generated, do not hand-edit them.

const DIR: String = "res://art/units/fire/"
const KIT_MAT_DIR: String = "res://art/units/kit/materials/"
const MODEL_SCRIPT: String = "res://art/units/fire/fire_model.gd"
const DEG: float = PI / 180.0
## Godot front faces are clockwise; flip if a test render shows inside-out meshes.
const FLIP: bool = false
## unit_glow materials: pre-merged per pivot like the others and left to the kit's runtime merge (see _flush).
## Fire infantry is drawn 12 % larger than authored (in-game grade 2026-09-30: small at the RTS zoom 30); body_height
## (scene + UnitType) is the scaled head top. Workers stay 1.0.
const INFANTRY_SCALE := Vector3(1.12, 1.12, 1.12)
const GLOW_MATS: Array[String] = ["fire_glow", "fire_glow_hero", "fire_flame", "crystal"]

var M: Dictionary = {}          # material name -> Material
var _root: Node3D
var _acc: Dictionary = {}       # "pivot id|material" -> [pivot, material, verts, normals, uvs, indices]
var _acc_order: Array[String] = []
var _dir: String = DIR
var _authored: int = 0          # MeshInstance3D count before this pre-merge (for the budget line)


func _init() -> void:
	_make_materials()
	# Optional filter (after `--`): only=cinder_hand,ember_archer rebuilds just those scenes.
	var only: PackedStringArray = []
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5).split(",")
		elif a.begins_with("out="):
			_dir = a.substr(4)   # dry run elsewhere (e.g. out=user://fire_try/): budgets without touching the scenes
	if only.is_empty() or only.has("cinder_hand"):
		_save(_cinder_hand(), "cinder_hand")
	if only.is_empty() or only.has("flame_guard"):
		# The Guard's plates use a brighter polished bronze (Art Lab R3t fire_bronze #9e6629 -> #c57535, 45 % of its
		# body; in-game grade 2026-09-30): its own material, the rest of the army keeps the kit bronze. G-C: shifted to a
		# polished brass #cc994d so the plates separate from the red-orange team cloth (and stay metal on a blue team).
		var kit_bronze: Material = M["fire_bronze"]
		M["fire_bronze"] = load("res://art/units/fire/materials/fire_bronze_guard.tres")
		_save(_flame_guard(), "flame_guard")
		M["fire_bronze"] = kit_bronze
	if only.is_empty() or only.has("ember_archer"):
		_save(_ember_archer(), "ember_archer")
	if only.is_empty() or only.has("ash_hurler"):
		_save(_ash_hurler(), "ash_hurler")
	print("FIRE BUILD OK")
	quit()


# ---------------------------------------------------------------- materials (the kit's closed palette, 2.2)

func _make_materials() -> void:
	for id: String in ["fire_cloth", "fire_cloth_dark", "fire_skin", "fire_bronze", "fire_leather", "fire_wood",
			"fire_fur", "fire_hair", "fire_ash_ball", "fire_sec_worker", "fire_sec_archer", "fire_sec_rider",
			"fire_sec_hurler", "fire_glow", "fire_glow_hero", "fire_flame", "fire_cape", "fire_pennon"]:
		M[id] = load(KIT_MAT_DIR + id + ".tres")
	M["eye_dark"] = load(KIT_MAT_DIR + "unit_eye_dark.tres")
	M["gold_trim"] = load(KIT_MAT_DIR + "unit_gold_trim.tres")
	M["crystal"] = load(KIT_MAT_DIR + "crystal_glow.tres")
	M["blob"] = load(KIT_MAT_DIR + "unit_shadow_blob.tres")
	# G-C (2026-10-15): blackened forge iron (rivets, blade cores, bands): a cool dark accent that breaks the orange
	# bronze / team mass into readable plates. Fire-only material next to fire_bronze_guard (same shader, surface metal).
	M["fire_iron"] = load("res://art/units/fire/materials/fire_iron.tres")

# ---------------------------------------------------------------- primitive meshes

func cyl(top: float, bottom: float, h: float, seg: int = 8) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	m.cap_top = top > 0.0
	m.cap_bottom = bottom > 0.0
	return m


func cone(r: float, h: float, seg: int = 6) -> CylinderMesh:
	return cyl(0.0, r, h, seg)


func sph(r: float, radial: int = 10, rings: int = 5) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = radial
	m.rings = rings
	return m


func octa(r: float, half_h: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = half_h * 2.0
	m.radial_segments = 4
	m.rings = 1
	return m


func cap(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(h, r * 2.0)
	m.radial_segments = 8
	m.rings = 4
	return m


func box(x: float, y: float, z: float) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(x, y, z)
	return m


func torus(inner: float, outer: float, rings: int = 12) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = rings
	m.ring_segments = 6
	return m


func prism(x: float, y: float, z: float) -> PrismMesh:
	var m := PrismMesh.new()
	m.size = Vector3(x, y, z)
	return m

# ---------------------------------------------------------------- custom meshes (SurfaceTool, normals set by hand)

## Orthonormal frame: local +Y along y_dir, local +Z as close to z_hint as possible, origin at `o`.
func frame(o: Vector3, y_dir: Vector3, z_hint: Vector3) -> Transform3D:
	var y: Vector3 = y_dir.normalized()
	var z: Vector3 = (z_hint - y * z_hint.dot(y)).normalized()
	var x: Vector3 = y.cross(z)
	return Transform3D(Basis(x, y, z), o)


func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


func _done(st: SurfaceTool) -> ArrayMesh:
	st.index()
	return st.commit()


## One triangle, turned so its front face (clockwise) points along the given normals.
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3,
		facet: bool = false) -> void:
	var fn: Vector3 = (b - a).cross(c - a)
	if fn.length_squared() < 1e-12:
		return
	var want: Vector3 = na + nb + nc
	if (fn.dot(want) > 0.0) != FLIP:
		var t: Vector3 = b
		b = c
		c = t
		var tn: Vector3 = nb
		nb = nc
		nc = tn
		fn = -fn
	if facet:
		var f: Vector3 = -fn.normalized() if not FLIP else fn.normalized()
		na = f
		nb = f
		nc = f
	st.set_normal(na)
	st.add_vertex(a)
	st.set_normal(nb)
	st.add_vertex(b)
	st.set_normal(nc)
	st.add_vertex(c)


func _xtri(st: SurfaceTool, xf: Transform3D, nb: Basis, a: Vector3, b: Vector3, c: Vector3, na: Vector3,
		nbv: Vector3, nc: Vector3, facet: bool) -> void:
	_tri(st, xf * a, xf * b, xf * c, (nb * na).normalized(), (nb * nbv).normalized(), (nb * nc).normalized(), facet)


## Surface of revolution around local Y. prof: Array of Vector2(radius, y), bottom to top. sx / sz scale the
## cross-section (ellipse). smooth = normals averaged across profile points (else painted bands); facet = flat
## triangles (gems, rocks). Closed with flat caps where the profile ends away from the axis.
func lathe(prof: Array, seg: int = 10, xf: Transform3D = Transform3D.IDENTITY, smooth: bool = true,
		sx: float = 1.0, sz: float = 1.0, facet: bool = false, caps: bool = true) -> ArrayMesh:
	var st := _st()
	var nb: Basis = xf.basis.inverse().transposed()
	var n: int = prof.size()
	var sn: Array[Vector2] = []
	for i: int in n - 1:
		var t: Vector2 = (prof[i + 1] as Vector2) - (prof[i] as Vector2)
		sn.append(Vector2(t.y, -t.x).normalized())
	for i: int in n - 1:
		var p0: Vector2 = prof[i]
		var p1: Vector2 = prof[i + 1]
		var n0: Vector2 = sn[i]
		var n1: Vector2 = sn[i]
		if smooth:
			if i > 0:
				n0 = (sn[i - 1] + sn[i]).normalized()
			if i < n - 2:
				n1 = (sn[i] + sn[i + 1]).normalized()
		for j: int in seg:
			var a0: float = TAU * j / seg
			var a1: float = TAU * ((j + 1) % seg) / seg   # G-C: the seam welds (same angle bits as j = 0)
			var va := _lv(p0, a0, sx, sz)
			var vb := _lv(p0, a1, sx, sz)
			var vc := _lv(p1, a1, sx, sz)
			var vd := _lv(p1, a0, sx, sz)
			var na := _ln(n0, a0, sx, sz)
			var nbb := _ln(n0, a1, sx, sz)
			var nc := _ln(n1, a1, sx, sz)
			var nd := _ln(n1, a0, sx, sz)
			_xtri(st, xf, nb, va, vb, vc, na, nbb, nc, facet)
			_xtri(st, xf, nb, va, vc, vd, na, nc, nd, facet)
	for end: int in [0, n - 1]:
		var pe: Vector2 = prof[end]
		if pe.x <= 0.001 or not caps:
			continue
		var up: Vector3 = Vector3.UP if end == n - 1 else Vector3.DOWN
		var c := Vector3(0, pe.y, 0)
		for j: int in seg:
			var a0: float = TAU * j / seg
			var a1: float = TAU * ((j + 1) % seg) / seg
			_xtri(st, xf, nb, c, _lv(pe, a0, sx, sz), _lv(pe, a1, sx, sz), up, up, up, false)
	return _done(st)


## Open bevelled band (belts, rims, trims): 3 profile rings, no caps; ~1/3 of a TorusMesh's vertices.
## Radius r, half height h, centred at local 0, then placed by xf (scale sx / sz for ovals).
func band(r: float, h: float, seg: int = 10, xf: Transform3D = Transform3D.IDENTITY, sx: float = 1.0,
		sz: float = 1.0) -> ArrayMesh:
	return lathe([Vector2(r - h * 0.35, -h), Vector2(r + h * 0.45, 0.0), Vector2(r - h * 0.35, h)], seg, xf, true,
		sx, sz, false, false)


func _lv(p: Vector2, a: float, sx: float, sz: float) -> Vector3:
	return Vector3(p.x * sin(a) * sx, p.y, p.x * cos(a) * sz)


func _ln(nn: Vector2, a: float, sx: float, sz: float) -> Vector3:
	return Vector3(nn.x * sin(a) / sx, nn.y, nn.x * cos(a) / sz).normalized()


## Tube through feet-space points with a radius per point (0 = pointed end). Smooth around, capped.
func tube(pts: Array, radii: Array, seg: int = 6) -> ArrayMesh:
	var st := _st()
	var n: int = pts.size()
	var rings: Array = []
	var nrm: Array = []
	var ref_n := Vector3.ZERO
	for i: int in n:
		var p: Vector3 = pts[i]
		var t: Vector3 = ((pts[mini(i + 1, n - 1)] as Vector3) - (pts[maxi(i - 1, 0)] as Vector3)).normalized()
		if i == 0:
			var r := Vector3.UP if absf(t.y) < 0.9 else Vector3.RIGHT
			ref_n = (r - t * r.dot(t)).normalized()
		else:
			ref_n = (ref_n - t * ref_n.dot(t)).normalized()
		var bn: Vector3 = t.cross(ref_n)
		var ring: Array[Vector3] = []
		var rn: Array[Vector3] = []
		for j: int in seg:
			var a: float = TAU * j / seg
			var d: Vector3 = ref_n * cos(a) + bn * sin(a)
			ring.append(p + d * float(radii[i]))
			rn.append(d)
		rings.append(ring)
		nrm.append(rn)
	for i: int in n - 1:
		for j: int in seg:
			var k: int = (j + 1) % seg
			var r0: Array[Vector3] = rings[i]
			var r1: Array[Vector3] = rings[i + 1]
			var m0: Array[Vector3] = nrm[i]
			var m1: Array[Vector3] = nrm[i + 1]
			_tri(st, r0[j], r0[k], r1[k], m0[j], m0[k], m1[k])
			_tri(st, r0[j], r1[k], r1[j], m0[j], m1[k], m1[j])
	for end: int in [0, n - 1]:
		if float(radii[end]) <= 0.001:
			continue
		var t2: Vector3 = ((pts[mini(end + 1, n - 1)] as Vector3) - (pts[maxi(end - 1, 0)] as Vector3)).normalized()
		var out: Vector3 = t2 if end == n - 1 else -t2
		var ring2: Array[Vector3] = rings[end]
		for j: int in seg:
			_tri(st, pts[end], ring2[j], ring2[(j + 1) % seg], out, out, out)
	return _done(st)


## 2D outline (local XY) extruded along local Z (depth centred), flat shaded, then placed by xf.
func extrude(poly: PackedVector2Array, depth: float, xf: Transform3D = Transform3D.IDENTITY) -> ArrayMesh:
	var st := _st()
	var nb: Basis = xf.basis.inverse().transposed()
	var idx: PackedInt32Array = Geometry2D.triangulate_polygon(poly)
	if idx.is_empty():
		push_error("extrude: triangulation failed")
	var h: float = depth * 0.5
	for k: int in range(0, idx.size(), 3):
		var a: Vector2 = poly[idx[k]]
		var b: Vector2 = poly[idx[k + 1]]
		var c: Vector2 = poly[idx[k + 2]]
		_xtri(st, xf, nb, Vector3(a.x, a.y, h), Vector3(b.x, b.y, h), Vector3(c.x, c.y, h),
			Vector3.BACK, Vector3.BACK, Vector3.BACK, false)
		_xtri(st, xf, nb, Vector3(a.x, a.y, -h), Vector3(b.x, b.y, -h), Vector3(c.x, c.y, -h),
			Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD, false)
	var area: float = 0.0
	for i: int in poly.size():
		var p: Vector2 = poly[i]
		var q: Vector2 = poly[(i + 1) % poly.size()]
		area += p.x * q.y - q.x * p.y
	var sgn: float = 1.0 if area > 0.0 else -1.0
	for i: int in poly.size():
		var p: Vector2 = poly[i]
		var q: Vector2 = poly[(i + 1) % poly.size()]
		var e: Vector2 = q - p
		var o := Vector3(e.y, -e.x, 0.0).normalized() * sgn
		_xtri(st, xf, nb, Vector3(p.x, p.y, h), Vector3(q.x, q.y, h), Vector3(q.x, q.y, -h), o, o, o, false)
		_xtri(st, xf, nb, Vector3(p.x, p.y, h), Vector3(q.x, q.y, -h), Vector3(p.x, p.y, -h), o, o, o, false)
	return _done(st)


func _poly(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in pts:
		out.append(p)
	return out


## Profile points scaled by s (lathe profiles authored at scale 1).
func _sc(prof: Array, s: float) -> Array:
	var out: Array = []
	for q: Vector2 in prof:
		out.append(q * s)
	return out


## Polygon moved inward by d along each corner's bisector (sharp corners clamped to 3 d).
func _inset(poly: PackedVector2Array, d: float) -> PackedVector2Array:
	var n: int = poly.size()
	var area: float = 0.0
	for i: int in n:
		area += poly[i].x * poly[(i + 1) % n].y - poly[(i + 1) % n].x * poly[i].y
	var sgn: float = 1.0 if area > 0.0 else -1.0
	var out := PackedVector2Array()
	for i: int in n:
		var a: Vector2 = poly[(i + n - 1) % n]
		var p: Vector2 = poly[i]
		var c: Vector2 = poly[(i + 1) % n]
		var e0: Vector2 = (p - a).normalized()
		var e1: Vector2 = (c - p).normalized()
		var n0 := Vector2(e0.y, -e0.x) * sgn
		var n1 := Vector2(e1.y, -e1.x) * sgn
		var bis: Vector2 = n0 + n1
		if bis.length_squared() < 1e-6:
			bis = n0
		bis = bis.normalized()
		out.append(p - bis * d / maxf(bis.dot(n0), 0.33))
	return out


## Bevelled plate (G-C): like extrude() but the front face is inset by `bevel` and joined to the sides by a chamfer
## ring, so every plate edge catches a thin light line (flat shaded). back = chamfer the back edge too (free-standing
## blades, shields). Falls back to a plain extrude when the inset outline cannot be triangulated.
func plate(poly: PackedVector2Array, depth: float, bevel: float, xf: Transform3D = Transform3D.IDENTITY,
		back: bool = false) -> ArrayMesh:
	var ins: PackedVector2Array = _inset(poly, bevel)
	var idx: PackedInt32Array = Geometry2D.triangulate_polygon(ins)
	if idx.is_empty():
		return extrude(poly, depth, xf)
	var st := _st()
	var nb: Basis = xf.basis.inverse().transposed()
	var h: float = depth * 0.5
	var bz: float = minf(bevel, depth * (0.45 if back else 0.7))
	var zf: float = h
	var zc: float = h - bz
	var zbc: float = -h + bz if back else -h
	var n: int = poly.size()
	for k: int in range(0, idx.size(), 3):
		var a: Vector2 = ins[idx[k]]
		var b: Vector2 = ins[idx[k + 1]]
		var c: Vector2 = ins[idx[k + 2]]
		_xtri(st, xf, nb, Vector3(a.x, a.y, zf), Vector3(b.x, b.y, zf), Vector3(c.x, c.y, zf),
			Vector3.BACK, Vector3.BACK, Vector3.BACK, false)
	# back face: the inset outline when the back is chamfered too, else the full outline
	var bpoly: PackedVector2Array = ins if back else poly
	var bidx: PackedInt32Array = idx if back else Geometry2D.triangulate_polygon(poly)
	for k: int in range(0, bidx.size(), 3):
		var a: Vector2 = bpoly[bidx[k]]
		var b: Vector2 = bpoly[bidx[k + 1]]
		var c: Vector2 = bpoly[bidx[k + 2]]
		_xtri(st, xf, nb, Vector3(a.x, a.y, -h), Vector3(b.x, b.y, -h), Vector3(c.x, c.y, -h),
			Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD, false)
	var area: float = 0.0
	for i: int in n:
		area += poly[i].x * poly[(i + 1) % n].y - poly[(i + 1) % n].x * poly[i].y
	var sgn: float = 1.0 if area > 0.0 else -1.0
	for i: int in n:
		var j: int = (i + 1) % n
		var p: Vector2 = poly[i]
		var q: Vector2 = poly[j]
		var pi: Vector2 = ins[i]
		var qi: Vector2 = ins[j]
		var e: Vector2 = q - p
		var o := Vector3(e.y, -e.x, 0.0).normalized() * sgn
		_xtri(st, xf, nb, Vector3(p.x, p.y, zc), Vector3(q.x, q.y, zc), Vector3(q.x, q.y, zbc), o, o, o, true)
		_xtri(st, xf, nb, Vector3(p.x, p.y, zc), Vector3(q.x, q.y, zbc), Vector3(p.x, p.y, zbc), o, o, o, true)
		var of: Vector3 = (o + Vector3.BACK).normalized()
		_xtri(st, xf, nb, Vector3(p.x, p.y, zc), Vector3(q.x, q.y, zc), Vector3(qi.x, qi.y, zf), of, of, of, true)
		_xtri(st, xf, nb, Vector3(p.x, p.y, zc), Vector3(qi.x, qi.y, zf), Vector3(pi.x, pi.y, zf), of, of, of, true)
		var ob: Vector3 = (o + Vector3.FORWARD).normalized() if back else Vector3.FORWARD
		if back:
			_xtri(st, xf, nb, Vector3(p.x, p.y, zbc), Vector3(q.x, q.y, zbc), Vector3(qi.x, qi.y, -zf), ob, ob, ob, true)
			_xtri(st, xf, nb, Vector3(p.x, p.y, zbc), Vector3(qi.x, qi.y, -zf), Vector3(pi.x, pi.y, -zf), ob, ob, ob, true)
	return _done(st)

# ---------------------------------------------------------------- scene helpers

func _origin(n: Node3D) -> Vector3:
	var p: Vector3 = Vector3.ZERO
	var c: Node = n
	while c != null and c != _root:
		p += (c as Node3D).position
		c = c.get_parent()
	return p


func _node(parent: Node, name: String, pos: Vector3 = Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = name
	parent.add_child(n)
	n.owner = _root
	n.position = pos - (_origin(parent as Node3D) if parent != _root else Vector3.ZERO)
	return n


## Adds a mesh part. `pos` is in feet space; rot in degrees (Godot YXZ euler). Static parts are accumulated and
## written as one MeshInstance3D per (pivot, material) by _flush(); keep = a separate node (toggled / animated).
func part(parent: Node3D, name: String, mesh: Mesh, pos: Vector3, mat: String, rot: Vector3 = Vector3.ZERO,
		keep: bool = false, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	_authored += 1
	var local := Transform3D(Basis.from_euler(rot * DEG) * Basis.from_scale(scl), pos - _origin(parent))
	if not keep:
		_add_geo(parent, mat, mesh, local)
		return null
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = M[mat]
	parent.add_child(mi)
	mi.owner = _root
	mi.transform = local
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta(&"keep_separate", true)
	return mi


## A mesh already built in feet space (lathe with a frame, tube, extrude).
func geo(parent: Node3D, mesh: Mesh, mat: String) -> void:
	part(parent, "", mesh, Vector3.ZERO, mat)


func _add_geo(pivot: Node3D, mat: String, mesh: Mesh, xf: Transform3D) -> void:
	var key: String = str(pivot.get_instance_id()) + "|" + mat
	if not _acc.has(key):
		_acc[key] = [pivot, mat, PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]
		_acc_order.append(key)
	var e: Array = _acc[key]
	var nb: Basis = xf.basis.inverse().transposed()
	for s: int in mesh.get_surface_count():
		var arr: Array = mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var base: int = (e[2] as PackedVector3Array).size()
		for j: int in v.size():
			e[2].append(xf * v[j])
			e[3].append((nb * nr[j]).normalized() if j < nr.size() else Vector3.UP)
			e[4].append(uv[j] if j < uv.size() else Vector2.ZERO)
		if ix.is_empty():
			for j: int in v.size():
				e[5].append(base + j)
		else:
			for j: int in ix.size():
				e[5].append(base + ix[j])


func _flush() -> void:
	for key: String in _acc_order:
		var e: Array = _acc[key]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = e[2]
		arrays[Mesh.ARRAY_NORMAL] = e[3]
		arrays[Mesh.ARRAY_TEX_UV] = e[4]
		arrays[Mesh.ARRAY_INDEX] = e[5]
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mi := MeshInstance3D.new()
		mi.name = String(e[1]).capitalize().replace(" ", "")
		mi.mesh = am
		mi.material_override = M[e[1]]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Glow parts (GLOW_MATS) are merged with the painted parts of their pivot by the kit at runtime. Before the
		# A.16 slot map they had to stay on their own keep_separate node (unit_glow's `glow_boost` and unit_painted's
		# `ao_bottom` shared instance uniform #0); now `glow_boost` is slot 5, so one merged node per pivot renders both
		# and the kit boosts it. Perf 2026-10-15: each separate glow node was one more moving draw instance per unit
		# (the G-C blade fuller on ArmR alone cost ~3 % of perf_test at 200 Flame Guards).
		(e[0] as Node3D).add_child(mi)
		mi.owner = _root
	_acc.clear()
	_acc_order.clear()


## Several copies of one mesh baked into ONE separate node (xforms in feet space). Replaces MultiMesh: a headless
## build runs on the dummy RenderingServer, which drops MultiMesh transforms (the old crystals / mane were empty).
func multi(parent: Node3D, name: String, mesh: Mesh, xforms: Array[Transform3D], mat: String) -> MeshInstance3D:
	_authored += 1
	var st := SurfaceTool.new()
	var o: Vector3 = _origin(parent)
	for t: Transform3D in xforms:
		var tt: Transform3D = t
		tt.origin -= o
		st.append_from(mesh, 0, tt)
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = st.commit()
	mi.material_override = M[mat]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.owner = _root
	mi.set_meta(&"keep_separate", true)
	return mi


func xf(pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot_deg * DEG) * Basis.from_scale(scl), pos)


## Root + Root/Hips (+ LegL/LegR) + Root/Chest/Head/ArmL/ArmR + Fx + Shadow. Returns the pivots by name.
func rig(unit_name: String, radius: float, waist_y: float, neck_y: float, shoulder: Vector3,
		leg_top: Vector3, legs: bool = true) -> Dictionary:
	_root = Node3D.new()
	_root.name = unit_name
	_authored = 0
	var p: Dictionary = {}
	p.Root = _node(_root, "Root")
	p.Hips = _node(p.Root, "Hips")
	if legs:
		p.LegL = _node(p.Hips, "LegL", Vector3(-leg_top.x, leg_top.y, leg_top.z))
		p.LegR = _node(p.Hips, "LegR", Vector3(leg_top.x, leg_top.y, leg_top.z))
	p.Chest = _node(p.Root, "Chest", Vector3(0, waist_y, shoulder.z))
	p.Head = _node(p.Chest, "Head", Vector3(0, neck_y, shoulder.z))
	p.ArmL = _node(p.Chest, "ArmL", Vector3(-shoulder.x, shoulder.y, shoulder.z))
	p.ArmR = _node(p.Chest, "ArmR", Vector3(shoulder.x, shoulder.y, shoulder.z))
	p.Fx = _node(_root, "Fx")
	_blob(radius)
	return p


func _blob(radius: float) -> void:
	var s: float = radius * 2.6
	var mi := MeshInstance3D.new()
	mi.name = "Shadow"
	var pm := PlaneMesh.new()
	pm.size = Vector2(1, 1)
	mi.mesh = pm
	mi.material_override = M["blob"]
	mi.position = Vector3(0, 0.02, 0)
	mi.scale = Vector3(s, 1, s)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta(&"keep_separate", true)
	_root.add_child(mi)
	mi.owner = _root
	_authored += 1


## Rounded boot (G-C; was a flat extruded side profile = a "brick" foot): a toe-forward half-ellipsoid foot with a
## flat sole, a tapered shaft and an optional cuff band (another material) at the top, centred at (x, 0, z).
func boot(pv: Node3D, x: float, z: float, s: float, mat: String, cuff: String = "", sole: String = "") -> void:
	geo(pv, lathe(_sc([Vector2(0.0, 0.0), Vector2(0.105, 0.0), Vector2(0.118, 0.028), Vector2(0.112, 0.07),
		Vector2(0.075, 0.115), Vector2(0.0, 0.13)], s), 8,
		Transform3D(Basis.IDENTITY, Vector3(x, 0, z + 0.042 * s)), true, 0.95, 1.55), mat)
	geo(pv, lathe(_sc([Vector2(0.088, 0.05), Vector2(0.094, 0.15), Vector2(0.104, 0.235), Vector2(0.116, 0.268),
		Vector2(0.0, 0.272)], s), 8, Transform3D(Basis.IDENTITY, Vector3(x, 0, z - 0.03 * s)),
		true, 1.0, 1.08), mat)
	if cuff != "":
		part(pv, "Cuff", band(0.112 * s, 0.024 * s, 8), Vector3(x, 0.255 * s, z - 0.03 * s), cuff, Vector3.ZERO, false,
			Vector3(1, 1, 1.08))
	if sole != "":
		part(pv, "Sole", band(0.108 * s, 0.018 * s, 8), Vector3(x, 0.014 * s, z + 0.042 * s), sole, Vector3.ZERO, false,
			Vector3(0.95, 1, 1.55))


## Legs (G-C): a shaped thigh -> knee -> calf -> ankle tube from each leg pivot (thigh full, knee narrow, calf
## swelling, slim ankle; was a straight cylinder) + a rounded boot. armour = a domed knee cop in that material.
func legs(p: Dictionary, x: float, top: float, r: float, leg_mat: String, boot_mat: String, bs: float = 1.0,
		armour: String = "", cuff: String = "", sole: String = "") -> void:
	var k: float = 0.15 + (top - 0.15) * 0.5
	for side: int in [-1, 1]:
		var pv: Node3D = p.LegL if side < 0 else p.LegR
		var sx: float = x * side
		geo(pv, tube([Vector3(sx, top + 0.03, 0.0), Vector3(sx * 1.03, top - (top - k) * 0.45, 0.004),
			Vector3(sx, k + 0.01, 0.018), Vector3(sx, k - (k - 0.2) * 0.45, -0.014), Vector3(sx, 0.2, 0.0)],
			[r, r * 1.02, r * 0.80, r * 0.90, r * 0.70], 7), leg_mat)
		boot(pv, sx, 0.02, bs, boot_mat, cuff, sole)
		if armour != "":
			part(pv, "KneeCop", sph(r * 0.62, 6, 3), Vector3(sx, k + 0.01, 0.018 + r * 0.55), armour, Vector3(-10, 0, 0),
				false, Vector3(1.0, 0.95, 0.7))


## Arm (G-C): shoulder -> bicep swell -> elbow (upper material) -> forearm swell -> wrist (lower material) + a mitten
## fist (was two straight tubes and a ball). pts in +X (right) space.
func arm(p: Dictionary, sh: Vector3, el: Vector3, wr: Vector3, r: Array, up_mat: String, lo_mat: String,
		fist_r: float, fist_mat: String) -> void:
	for side: int in [-1, 1]:
		var pv: Node3D = p.ArmL if side < 0 else p.ArmR
		var m := Vector3(side, 1, 1)
		var mu: Vector3 = sh.lerp(el, 0.42) + Vector3(0.012, 0, 0.006)
		var ml: Vector3 = el.lerp(wr, 0.38) + Vector3(0.006, 0, 0.004)
		geo(pv, tube([sh * m, mu * m, el * m], [r[0], float(r[0]) * 1.05, float(r[1]) * 0.9], 8), up_mat)
		geo(pv, tube([el * m, ml * m, wr * m], [float(r[1]) * 0.92, float(r[1]) * 1.04, float(r[2]) * 0.86], 8), lo_mat)
		var fc: Vector3 = wr + Vector3(0.0, -fist_r * 0.55, 0.02)
		part(pv, "Fist", sph(fist_r, 8, 4), fc * m, fist_mat, Vector3.ZERO, false, Vector3(0.9, 1.0, 1.1))


## Small domed studs (rivets / bolts) at feet-space points: they catch a sun glint at zoom 10 and merge into the plate.
func rivets(pv: Node3D, pts: Array, r: float, mat: String) -> void:
	for q: Vector3 in pts:
		part(pv, "Rivet", sph(r, 5, 2), q, mat)


## Level-4 gold trim (7.1), hidden, toggled by set_veterancy.
func vet_trim(parent: Node3D, pos: Vector3, rot: Vector3 = Vector3.ZERO, s: float = 1.0) -> void:
	var t: MeshInstance3D = part(parent, "VetTrim", band(0.23, 0.028), pos, "gold_trim", rot, true, Vector3(s, s, s))
	t.set_meta(&"vet_trim", true)
	t.visible = false


func _finish(cfg: Dictionary) -> Node3D:
	_flush()
	var scr: Script = load(MODEL_SCRIPT)
	_root.set_script(scr)
	for k: String in cfg:
		_root.set(k, cfg[k])
	return _root


func _save(root: Node3D, id: String) -> void:
	var ps := PackedScene.new()
	var err: int = ps.pack(root)
	if err != OK:
		push_error("pack failed " + id)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
	var path: String = _dir + id + ".tscn"
	err = ResourceSaver.save(ps, path)
	var c: Array[int] = [0, 0]
	_count(root, c)
	print("saved %s  authored parts %d  scene meshes %d  vertices %d  err %d" % [path, _authored, c[0], c[1], err])
	root.free()


func _count(n: Node, c: Array[int]) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		c[0] += 1
		for s: int in (n as MeshInstance3D).mesh.get_surface_count():
			c[1] += ((n as MeshInstance3D).mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	elif n is MultiMeshInstance3D:
		c[0] += 1
		var mm := (n as MultiMeshInstance3D).multimesh
		c[1] += (mm.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() * mm.instance_count
	for ch: Node in n.get_children():
		_count(ch, c)

# ---------------------------------------------------------------- particles

func _particle_mat(additive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.disable_fog = additive  # G-E 5: an additive quad must not fog
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true   # G-F billboard pass: the particle scale applies (docs/art/gf_billboard.md)
	m.vertex_color_use_as_albedo = true
	m.no_depth_test = false
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.55))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 32
	t.height = 32
	m.albedo_texture = t
	return m


## Pre-built GPUParticles3D. cols: 2 or 3 colours along the life. grav: world gravity (embers rise: +y).
func particles(parent: Node3D, name: String, amount: int, lifetime: float, pos: Vector3, box_ext: Vector3,
		vel: float, size_a: float, size_b: float, cols: Array, additive: bool, one_shot: bool = false,
		spread: float = 20.0, grav: Vector3 = Vector3.ZERO) -> GPUParticles3D:
	var pp := ParticleProcessMaterial.new()
	pp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pp.emission_box_extents = box_ext
	pp.direction = Vector3(0, 1, 0)
	pp.spread = spread
	pp.initial_velocity_min = vel * 0.6
	pp.initial_velocity_max = vel
	pp.gravity = grav
	pp.damping_min = 0.5
	pp.damping_max = 1.5
	pp.scale_min = 0.8
	pp.scale_max = 1.2
	var sc := Curve.new()
	sc.max_value = 4.0
	sc.add_point(Vector2(0, 1.0))
	sc.add_point(Vector2(1, size_b / size_a))
	var sct := CurveTexture.new()
	sct.curve = sc
	pp.scale_curve = sct
	var g := Gradient.new()
	g.set_color(0, cols[0])
	g.set_color(1, cols[cols.size() - 1])
	if cols.size() > 2:
		g.add_point(0.45, cols[1])
	var gt := GradientTexture1D.new()
	gt.gradient = g
	gt.use_hdr = true   # colours > 1 cross the bloom threshold with a MIX blend (no washed-out ADD on grass)
	pp.color_ramp = gt
	var q := QuadMesh.new()
	q.size = Vector2(size_a, size_a)
	q.material = _particle_mat(additive)
	var gp := GPUParticles3D.new()
	gp.name = name
	gp.amount = amount
	gp.lifetime = lifetime
	gp.one_shot = one_shot
	gp.emitting = not one_shot
	gp.explosiveness = 0.85 if one_shot else 0.0
	gp.fixed_fps = 30
	gp.interpolate = true
	gp.process_material = pp
	gp.draw_pass_1 = q
	gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gp.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 4, 4))
	parent.add_child(gp)
	gp.owner = _root
	gp.position = pos - _origin(parent)
	gp.set_meta(&"keep_separate", true)
	return gp


## The death "burn": 16 rising embers + an ash puff, restarted by FireModel when the body starts to glow (0.42 s).
func burn_fx(p: Dictionary, y: float, spread_xz: float, puff: bool = true) -> void:
	var e: GPUParticles3D = particles(p.Fx, "BurnEmbers", 16, 0.9, Vector3(0, y, 0),
		Vector3(spread_xz, y * 0.5, spread_xz), 1.8, 0.16, 0.04,
		[Color(2.6, 0.95, 0.25, 1.0), Color(1.7, 0.36, 0.06, 0.9), Color(0.5, 0.08, 0.02, 0.0)], false, true, 45.0,
		Vector3(0, 1.2, 0))
	e.set_meta(&"burn_fx", true)
	if not puff:
		return
	var a: GPUParticles3D = particles(p.Fx, "AshPuff", 8, 1.0, Vector3(0, y * 0.6, 0),
		Vector3(spread_xz, 0.15, spread_xz), 0.7, 0.35, 0.9,
		[Color(0.20, 0.16, 0.14, 0.55), Color(0.25, 0.21, 0.19, 0.30), Color(0.3, 0.26, 0.24, 0.0)], false, true, 60.0,
		Vector3(0, 0.4, 0))
	a.set_meta(&"burn_fx", true)


# ================================================================ 4.1 Cinder Hand (worker, 1.4 m)
# Stout bearded ash-miner: round team hard-hat with the glowing head-lamp, dusty apron, huge curved pick over the
# right shoulder, wicker basket on the back (crystals poke out while carrying). Silhouette: small + round + pick.

func _cinder_hand() -> Node3D:
	var sh := Vector3(0.40, 0.90, 0.0)
	var p: Dictionary = rig("CinderHand", 0.42, 0.44, 0.94, sh, Vector3(0.15, 0.40, 0.0))
	# G-C: shaped legs, rounded work boots on iron-shod soles.
	legs(p, 0.15, 0.40, 0.115, "fire_leather", "fire_leather", 1.05, "", "", "fire_iron")
	# Body: a round bell, the dusty apron colour.
	geo(p.Chest, lathe([Vector2(0.30, 0.34), Vector2(0.37, 0.41), Vector2(0.39, 0.52), Vector2(0.37, 0.66),
		Vector2(0.31, 0.80), Vector2(0.22, 0.90), Vector2(0.10, 0.96), Vector2(0.0, 0.97)], 12,
		Transform3D.IDENTITY, true, 1.0, 0.92), "fire_sec_worker")
	# Leather bib apron on the belly (G-C: bevelled, a cloth pocket, iron rivets) + two bevelled basket straps.
	var af: Transform3D = frame(Vector3(0, 0.60, 0.352), Vector3(0, 1, -0.18), Vector3.BACK)
	geo(p.Chest, plate(_poly([Vector2(-0.19, -0.22), Vector2(0.19, -0.22), Vector2(0.17, 0.10), Vector2(0.12, 0.21),
		Vector2(-0.12, 0.21), Vector2(-0.17, 0.10)]), 0.05, 0.016, af), "fire_leather")
	geo(p.Chest, plate(_poly([Vector2(-0.10, -0.06), Vector2(0.10, -0.06), Vector2(0.105, 0.05), Vector2(-0.105, 0.05)]),
		0.03, 0.01, af * Transform3D(Basis.IDENTITY, Vector3(0, -0.11, 0.03))), "fire_sec_worker")
	rivets(p.Chest, [af * Vector3(-0.10, 0.17, 0.028), af * Vector3(0.10, 0.17, 0.028)], 0.02, "fire_iron")
	for s: int in [-1, 1]:
		geo(p.Chest, plate(_poly([Vector2(-0.037, -0.17), Vector2(0.037, -0.17), Vector2(0.037, 0.17), Vector2(-0.037, 0.17)]),
			0.04, 0.012, xf(Vector3(0.20 * s, 0.80, 0.25), Vector3(-28, 0, 0))), "fire_leather")
	# Belt (team) + bronze buckle.
	part(p.Hips, "Belt", band(0.388, 0.043, 12), Vector3(0, 0.43, 0), "fire_cloth", Vector3.ZERO, false, Vector3(1, 1.3, 0.93))
	geo(p.Hips, plate(_poly([Vector2(-0.075, -0.065), Vector2(0.075, -0.065), Vector2(0.075, 0.065), Vector2(-0.075, 0.065)]),
		0.05, 0.016, frame(Vector3(0, 0.43, 0.375), Vector3.UP, Vector3.BACK)), "fire_bronze")
	# G-C: a hammer hangs from the belt on the left hip (iron head, wood haft).
	geo(p.Hips, tube([Vector3(-0.42, 0.47, 0.08), Vector3(-0.45, 0.21, 0.11)], [0.022, 0.02], 5), "fire_wood")
	part(p.Hips, "HammerHead", box(0.07, 0.07, 0.17), Vector3(-0.42, 0.48, 0.08), "fire_iron", Vector3(0, 0, 8))
	# Head: big round face, nose, a bushy beard. Eyes, brows, mouth, ears, hair: the FaceKit face FireModel attaches
	# at runtime (faces pass 2026-09-28; the old dark eye bar is gone).
	part(p.Head, "Head", sph(0.26), Vector3(0, 1.13, 0.03), "fire_skin")
	part(p.Head, "Nose", sph(0.075, 8, 4), Vector3(0, 1.10, 0.30), "fire_skin")
	part(p.Head, "Beard", sph(0.21), Vector3(0, 0.95, 0.17), "fire_hair", Vector3(-10, 0, 0), false, Vector3(1.22, 0.85, 0.72))
	# Miner's hard-hat (team) with a brim; bronze lamp housing and the glowing lamp (the unit's one glow), mounted
	# high on the hat front and tipped up so it reads over the head from the game camera.
	geo(p.Head, lathe([Vector2(0.335, 1.20), Vector2(0.335, 1.232), Vector2(0.28, 1.25), Vector2(0.272, 1.32),
		Vector2(0.24, 1.40), Vector2(0.17, 1.47), Vector2(0.07, 1.505), Vector2(0.0, 1.51)], 14,
		Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.02))), "fire_cloth")
	part(p.Head, "HatBand", band(0.276, 0.022, 14), Vector3(0, 1.275, 0.02), "fire_leather")
	part(p.Head, "LampHousing", cyl(0.105, 0.105, 0.10, 8), Vector3(0, 1.41, 0.24), "fire_bronze", Vector3(62, 0, 0))
	part(p.Head, "Lamp", sph(0.095), Vector3(0, 1.435, 0.285), "fire_glow")
	# Arms: rolled sleeves (apron colour), bare forearms, leather gloves.
	arm(p, sh, Vector3(0.45, 0.72, 0.01), Vector3(0.47, 0.60, 0.03), [0.12, 0.10, 0.09], "fire_sec_worker", "fire_skin",
		0.135, "fire_leather")
	# Pick: shaft from the fist up and back over the shoulder (30 deg), a big curved bronze head.
	var fist := Vector3(0.47, 0.53, 0.05)
	var d := Vector3(0, cos(30.0 * DEG), -sin(30.0 * DEG))
	# Head turned 25 deg around the shaft so it spreads sideways: a "T" that reads from the high camera (40 deg
	# pushed the outer prong 0.77 m out, past the 0.4 m selection radius).
	var e := Vector3(0, sin(30.0 * DEG), cos(30.0 * DEG)).rotated(d, 25.0 * DEG)
	geo(p.ArmR, tube([fist - d * 0.20, fist + d * 0.98], [0.048, 0.045], 6), "fire_wood")
	var top: Vector3 = fist + d * 0.95
	var hp: Array = []
	var hr: Array = [0.012, 0.05, 0.075, 0.085, 0.075, 0.05, 0.012]
	# Back prong a little shorter than the front pick (it poked out behind the footprint, R10).
	for s2: float in [-0.34, -0.24, -0.11, 0.0, 0.15, 0.30, 0.46]:
		hp.append(top + e * s2 - d * 0.11 * pow(s2 / 0.43, 2.0))
	geo(p.ArmR, tube(hp, hr, 6), "fire_bronze")
	geo(p.ArmR, lathe([Vector2(0.072, -0.08), Vector2(0.075, 0.07), Vector2(0.0, 0.08)], 8, frame(top, d, e)), "fire_bronze")
	# Wicker basket on the back with a wood band (crystals poke out when carrying).
	var bo := Vector3(0, 0, -0.41)   # snug on the back: the rim stays inside the 0.4 m radius footprint (R10)
	geo(p.Chest, lathe([Vector2(0.0, 0.58), Vector2(0.17, 0.58), Vector2(0.23, 0.78), Vector2(0.26, 0.98),
		Vector2(0.275, 1.02), Vector2(0.24, 1.03), Vector2(0.0, 1.0)], 9, Transform3D(Basis.IDENTITY, bo)), "fire_leather")
	for by: float in [0.70, 0.80, 0.90]:
		part(p.Chest, "BasketBand", band(0.236 + (by - 0.70) * 0.17, 0.02, 9), bo + Vector3(0, by, 0), "fire_wood",
			Vector3.ZERO, false, Vector3(1, 1.4, 1))
	var cx: Array[Transform3D] = [xf(bo + Vector3(0.0, 1.10, 0.02), Vector3(0, 20, 6)),
		xf(bo + Vector3(-0.12, 1.05, 0.05), Vector3(0, 0, 24)), xf(bo + Vector3(0.11, 1.04, -0.06), Vector3(15, 0, -22))]
	var cr: MeshInstance3D = multi(p.Chest, "Crystals", octa(0.12, 0.22), cx, "crystal")
	cr.visible = false
	cr.set_meta(&"carry", true)
	particles(p.ArmR, "MineSparks", 6, 0.35, top + e * 0.46, Vector3(0.05, 0.05, 0.05), 2.4, 0.12, 0.03,
		[Color(0.8, 0.95, 1.0, 1.0), Color(0.55, 0.85, 1.0, 0.0)], true, true, 70.0, Vector3(0, -4, 0))
	burn_fx(p, 0.6, 0.25)
	return _finish({"body_height": 1.4, "attack_style": &"worker_pick", "attack_windup": 0.0, "fire_kind": &"worker",
		"death_style": &"fall", "stride_time": 0.5, "is_quadruped": false, "stride_speed": 4.6,
		"idle_period": 2.6, "walk_bounce": 0.06, "leg_swing_deg": 32.0})


# ================================================================ 4.2 Flame Guard (melee line, 1.6 m)
# Squat legionary: bronze bucket helm with a glowing slit and a flame crest, huge pauldrons, a flame-topped tower
# shield (glowing glyph) and a broad leaf blade. Silhouette: wide + square + the shield's three flame tongues.

func _flame_guard() -> Node3D:
	var sh := Vector3(0.48, 1.16, 0.0)
	var p: Dictionary = rig("FlameGuard", 0.45, 0.70, 1.24, sh, Vector3(0.18, 0.52, 0.0))
	# G-C: shaped legs, dark leather boots with bronze cuffs (bottoms darker, tops lighter).
	legs(p, 0.18, 0.52, 0.125, "fire_leather", "fire_leather", 1.12, "", "fire_bronze")
	# Skirt (smooth, dark cloth) + a team tabard hanging front and back (the team colour now reaches the lower body)
	# + leather belt with an iron buckle.
	geo(p.Hips, lathe([Vector2(0.35, 0.46), Vector2(0.33, 0.58), Vector2(0.30, 0.70), Vector2(0.27, 0.77),
		Vector2(0.0, 0.77)], 8, Transform3D.IDENTITY, true, 1.0, 0.85), "fire_cloth_dark")
	for fb: int in [1, -1]:
		geo(p.Hips, extrude(_poly([Vector2(-0.15, 0.0), Vector2(0.15, 0.0), Vector2(0.135, -0.30), Vector2(0.0, -0.40),
			Vector2(-0.135, -0.30)]), 0.03, frame(Vector3(0, 0.76, 0.27 * fb), Vector3(0, 1, -0.20 * fb),
			Vector3.BACK * fb)), "fire_cloth")
	part(p.Hips, "Belt", band(0.33, 0.04, 12), Vector3(0, 0.76, 0), "fire_leather", Vector3.ZERO, false, Vector3(1, 1.2, 0.86))
	geo(p.Hips, plate(_poly([Vector2(-0.075, -0.05), Vector2(0.075, -0.05), Vector2(0.075, 0.05), Vector2(-0.075, 0.05)]),
		0.04, 0.014, frame(Vector3(0, 0.76, 0.285), Vector3.UP, Vector3.BACK)), "fire_iron")
	# Torso keg (team) + shaped bronze breastplate with a centre ridge and an iron gorget.
	geo(p.Chest, lathe([Vector2(0.26, 0.70), Vector2(0.30, 0.80), Vector2(0.37, 1.00), Vector2(0.38, 1.14),
		Vector2(0.33, 1.24), Vector2(0.20, 1.31), Vector2(0.0, 1.33)], 8, Transform3D.IDENTITY, true, 1.0, 0.85), "fire_cloth")
	var bp_f: Transform3D = frame(Vector3(0, 1.03, 0.262), Vector3(0, 1, -0.12), Vector3.BACK)
	geo(p.Chest, plate(_poly([Vector2(-0.29, 0.20), Vector2(0.29, 0.20), Vector2(0.31, 0.04), Vector2(0.25, -0.15),
		Vector2(0.10, -0.24), Vector2(-0.10, -0.24), Vector2(-0.25, -0.15), Vector2(-0.31, 0.04)]), 0.10, 0.035, bp_f),
		"fire_bronze")
	geo(p.Chest, extrude(_poly([Vector2(-0.035, 0.17), Vector2(0.035, 0.17), Vector2(0.03, -0.18), Vector2(0.0, -0.22),
		Vector2(-0.03, -0.18)]), 0.03, bp_f * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.055))), "fire_bronze")
	part(p.Chest, "Gorget", band(0.20, 0.035, 10), Vector3(0, 1.27, 0.0), "fire_iron", Vector3(-8, 0, 0), false,
		Vector3(1, 1.2, 0.9))
	rivets(p.Chest, [bp_f * Vector3(-0.22, 0.13, 0.05), bp_f * Vector3(0.22, 0.13, 0.05)], 0.028, "fire_iron")
	# Big layered pauldrons: two stepped team plates (painted bands) with a bronze rim.
	for s: int in [-1, 1]:
		var po := Vector3(0.49 * s, 1.16, 0.0)
		var tilt := Vector3(0.50 * s, 1, 0)
		var pf: Transform3D = frame(po, tilt, Vector3.BACK)
		# G-C: smooth stepped lames (the painted step kept in the profile), an iron stud on top.
		geo(p.Chest, lathe([Vector2(0.30, -0.10), Vector2(0.31, -0.04), Vector2(0.27, 0.02),
			Vector2(0.255, 0.06), Vector2(0.20, 0.13), Vector2(0.11, 0.18), Vector2(0.0, 0.195)], 8, pf, true, 1.0, 1.08),
			"fire_cloth")
		part(p.Chest, "PauldronRim", band(0.313, 0.032, 12), pf * Vector3(0, -0.07, 0), "fire_bronze",
			Vector3(0, 0, -rad_to_deg(atan2(0.50, 1.0)) * s), false, Vector3(1, 1.2, 1.08))
		part(p.Chest, "PauldronStud", sph(0.065, 5, 2), pf * Vector3(0, 0.19, 0), "fire_iron")
	# Helm: a rounded bronze dome with a rolled rim, open at the front (the FaceKit face + its face sphere look out of
	# it, faces pass 2026-09-28: FireModel attaches it), a glowing band above the brows, bevelled cheek guards, an
	# iron brow band with rivets, the flame crest (team).
	geo(p.Head, lathe([Vector2(0.318, 1.20), Vector2(0.33, 1.225), Vector2(0.29, 1.262), Vector2(0.292, 1.40),
		Vector2(0.28, 1.51), Vector2(0.24, 1.60), Vector2(0.165, 1.672), Vector2(0.08, 1.703), Vector2(0.0, 1.71)], 12),
		"fire_bronze")
	part(p.Head, "BrowBand", band(0.296, 0.03, 12), Vector3(0, 1.44, 0), "fire_iron")
	part(p.Head, "Visor", box(0.30, 0.05, 0.06), Vector3(0, 1.565, 0.262), "fire_glow", Vector3(-12, 0, 0))
	for s: int in [-1, 1]:
		part(p.Head, "Brow", box(0.17, 0.06, 0.08), Vector3(0.095 * s, 1.505, 0.262), "fire_bronze", Vector3(-8, 0, 16 * s))
		geo(p.Head, extrude(_poly([Vector2(-0.07, 0.10), Vector2(0.07, 0.10), Vector2(0.06, -0.10), Vector2(-0.01, -0.16),
			Vector2(-0.07, -0.08)]), 0.035, frame(Vector3(0.255 * s, 1.30, 0.13), Vector3(0, 1, 0),
			Vector3(0.75 * s, 0, 0.66))), "fire_bronze")
	geo(p.Head, extrude(_poly([Vector2(0.21, 1.60), Vector2(0.10, 1.685), Vector2(0.0, 1.705), Vector2(-0.12, 1.675),
		Vector2(-0.24, 1.58), Vector2(-0.30, 1.47), Vector2(-0.42, 1.60), Vector2(-0.28, 1.70), Vector2(-0.33, 1.90),
		Vector2(-0.16, 1.80), Vector2(-0.11, 2.00), Vector2(0.02, 1.84), Vector2(0.12, 1.94), Vector2(0.13, 1.78),
		Vector2(0.24, 1.70)]), 0.11, frame(Vector3.ZERO, Vector3.UP, Vector3.LEFT)), "fire_cloth")
	vet_trim(p.Head, Vector3(0, 1.53, 0), Vector3.ZERO, 1.2)
	# Arms: dark cloth, bronze bracers and gauntlets.
	arm(p, sh, Vector3(0.52, 0.94, 0.01), Vector3(0.53, 0.80, 0.03), [0.115, 0.10, 0.095], "fire_cloth_dark",
		"fire_cloth_dark", 0.14, "fire_bronze")
	for s: int in [-1, 1]:
		var pv: Node3D = p.ArmL if s < 0 else p.ArmR
		# flared bronze bracer (lathe) with an iron edge
		geo(pv, lathe([Vector2(0.104, -0.085), Vector2(0.112, -0.06), Vector2(0.118, 0.04), Vector2(0.13, 0.085),
			Vector2(0.118, 0.092)], 8, Transform3D(Basis.IDENTITY, Vector3(0.53 * s, 0.84, 0.03)), true, 1.0, 1.0, false,
			false), "fire_bronze")
	# Flame tower shield (team face, bronze rim, glowing flame glyph), front-left, slightly turned out. G-C: bevelled
	# face and rim (light lines on every tongue) and iron rivets.
	var shield_pts: Array = [Vector2(0.0, -0.60), Vector2(0.30, -0.48), Vector2(0.40, -0.28), Vector2(0.40, 0.36),
		Vector2(0.36, 0.68), Vector2(0.20, 0.46), Vector2(0.02, 0.82), Vector2(-0.18, 0.46), Vector2(-0.38, 0.64),
		Vector2(-0.40, 0.36), Vector2(-0.40, -0.28), Vector2(-0.30, -0.48)]
	var fwd := Vector3(sin(-12.0 * DEG), 0, cos(-12.0 * DEG))
	var sc := Vector3(-0.44, 0.86, 0.34)
	geo(p.ArmL, plate(_poly(shield_pts), 0.08, 0.03, frame(sc, Vector3.UP, fwd)), "fire_cloth")
	var rim := PackedVector2Array()
	for q: Vector2 in shield_pts:
		rim.append(q * 1.075 + Vector2(0, -0.01))
	geo(p.ArmL, extrude(rim, 0.05, frame(sc - fwd * 0.05, Vector3.UP, fwd)), "fire_bronze")
	var sf: Transform3D = frame(sc, Vector3.UP, fwd)
	var srv: Array = []
	for q: Vector2 in [Vector2(-0.34, 0.30), Vector2(0.34, 0.30)]:
		srv.append(sf * Vector3(q.x, q.y, 0.045))
	rivets(p.ArmL, srv, 0.026, "fire_iron")
	# Dark team foot on the shield face: a value step inside the team colour (Art Lab R6cb, colour-blind fire / nature;
	# in-game grade 2026-09-30) that also grounds the tall shield shape from the RTS camera.
	geo(p.ArmL, extrude(_poly([Vector2(-0.37, -0.12), Vector2(-0.37, -0.27), Vector2(-0.28, -0.45), Vector2(0.0, -0.56),
		Vector2(0.28, -0.45), Vector2(0.37, -0.27), Vector2(0.37, -0.12)]), 0.02, frame(sc + fwd * 0.045, Vector3.UP, fwd)),
		"fire_cloth_dark")
	geo(p.ArmL, extrude(_poly([Vector2(0.0, -0.24), Vector2(0.13, -0.13), Vector2(0.15, 0.04), Vector2(0.07, 0.22),
		Vector2(0.05, 0.10), Vector2(-0.02, 0.32), Vector2(-0.11, 0.13), Vector2(-0.15, -0.04), Vector2(-0.12, -0.15)]),
		0.03, frame(sc + fwd * 0.05 + Vector3(0, 0.02, 0), Vector3.UP, fwd)), "fire_glow")
	# Broad leaf blade, forward-down 45 deg, edge vertical.
	var fist := Vector3(0.53, 0.72, 0.06)
	var d := Vector3(0, -0.707, 0.707)
	var e := Vector3(0, 0.707, 0.707)
	# G-C: leather grip between iron rings, an iron pommel, a swept iron crossguard, a bevelled leaf blade (both edges
	# catch light) with an ember-hot fuller on each face (its own glow node: +1 draw instance).
	geo(p.ArmR, tube([fist - d * 0.14, fist + d * 0.10], [0.045, 0.045], 6), "fire_leather")
	part(p.ArmR, "Pommel", sph(0.07, 6, 3), fist - d * 0.17, "fire_iron", Vector3.ZERO, false, Vector3(1, 1.2, 1))
	part(p.ArmR, "GripRing", band(0.05, 0.014, 8), fist - d * 0.11, "fire_iron", Vector3(45, 0, 0))
	geo(p.ArmR, tube([fist + d * 0.13 - Vector3.RIGHT * 0.22 + d * 0.05, fist + d * 0.12 - Vector3.RIGHT * 0.10,
		fist + d * 0.12 + Vector3.RIGHT * 0.10, fist + d * 0.13 + Vector3.RIGHT * 0.22 + d * 0.05],
		[0.025, 0.04, 0.04, 0.025], 6), "fire_iron")
	var bx := Transform3D(Basis(Vector3.RIGHT, d, -e), fist + d * 0.15)
	geo(p.ArmR, plate(_poly([Vector2(0.0, 0.0), Vector2(0.09, 0.04), Vector2(0.125, 0.38), Vector2(0.11, 0.62),
		Vector2(0.0, 0.92), Vector2(-0.11, 0.62), Vector2(-0.125, 0.38), Vector2(-0.09, 0.04)]), 0.05, 0.022, bx),
		"fire_bronze")
	for fz: float in [0.027, -0.027]:
		geo(p.ArmR, extrude(_poly([Vector2(-0.02, 0.06), Vector2(0.02, 0.06), Vector2(0.024, 0.50), Vector2(0.0, 0.66),
			Vector2(-0.024, 0.50)]), 0.006, bx * Transform3D(Basis.IDENTITY, Vector3(0, 0, fz))), "fire_glow")
	burn_fx(p, 0.8, 0.3)
	return _finish({"scale": INFANTRY_SCALE, "body_height": 2.0, "attack_style": &"melee_swing", "attack_windup": 0.0, "fire_kind": &"guard",
		"death_style": &"fall", "stride_time": 0.58, "is_quadruped": false, "stride_speed": 5.0,
		"idle_period": 3.4, "walk_bounce": 0.035, "leg_swing_deg": 24.0})


# ================================================================ 4.3 Ember Archer (ranged, 1.6 m)
# Lean hooded scout: pointed team hood and capelet, gold coat, a 1.7 m recurve bow carried level at the side
# (it swings up vertical to shoot), smouldering arrows in the back quiver. Silhouette: narrow + long bow line.

func _ember_archer() -> Node3D:
	var sh := Vector3(0.34, 1.14, 0.0)
	var p: Dictionary = rig("EmberArcher", 0.45, 0.64, 1.20, sh, Vector3(0.14, 0.52, 0.0))
	# G-C: shaped legs, soft leather boots with gold turned-down cuffs.
	legs(p, 0.14, 0.52, 0.10, "fire_leather", "fire_leather", 0.98, "", "fire_sec_archer")
	# Gold doublet (secondary) over a dark-crimson coat skirt (tops light, bottoms dark: the gold reads on top from
	# the game camera, the skirt sinks toward the ground), bronze hem, belt over the seam, team sash.
	geo(p.Chest, lathe([Vector2(0.265, 0.70), Vector2(0.295, 0.92),
		Vector2(0.305, 1.06), Vector2(0.26, 1.18), Vector2(0.14, 1.25), Vector2(0.0, 1.26)], 12,
		Transform3D.IDENTITY, true, 1.0, 0.85), "fire_sec_archer")
	geo(p.Chest, lathe([Vector2(0.35, 0.40), Vector2(0.325, 0.47), Vector2(0.30, 0.55), Vector2(0.262, 0.71)], 12,
		Transform3D.IDENTITY, true, 1.0, 0.85), "fire_cloth_dark")
	part(p.Chest, "Hem", band(0.362, 0.034), Vector3(0, 0.42, 0), "fire_bronze", Vector3.ZERO, false, Vector3(1, 1.3, 0.86))
	part(p.Chest, "Belt", band(0.289, 0.029), Vector3(0, 0.70, 0), "fire_leather", Vector3.ZERO, false, Vector3(1, 1.3, 0.86))
	part(p.Chest, "Sash", band(0.323, 0.032), Vector3(0, 0.96, 0), "fire_cloth", Vector3(0, 0, 24), false, Vector3(1, 1.2, 0.86))
	# Team capelet over the shoulders.
	geo(p.Chest, lathe([Vector2(0.41, 1.00), Vector2(0.405, 1.05), Vector2(0.33, 1.15), Vector2(0.20, 1.23),
		Vector2(0.0, 1.27)], 14, Transform3D.IDENTITY, true, 1.0, 0.9), "fire_cloth")
	# G-C: a bronze hem on the capelet, a leather baldric from the left shoulder to the right hip (it carries the
	# quiver) with a bronze buckle, and a belt pouch: mid-size value blocks that read at zoom 10 and merge at 30.
	part(p.Chest, "CapeHem", band(0.405, 0.022, 14), Vector3(0, 1.005, 0), "fire_bronze", Vector3.ZERO, false,
		Vector3(1, 1, 0.9))
	geo(p.Chest, tube([Vector3(-0.22, 1.10, 0.24), Vector3(-0.05, 0.98, 0.29), Vector3(0.14, 0.84, 0.275),
		Vector3(0.27, 0.72, 0.18)], [0.032, 0.032, 0.032, 0.03], 5), "fire_leather")
	part(p.Chest, "BaldricBuckle", box(0.08, 0.07, 0.03), Vector3(0.045, 0.915, 0.295), "fire_bronze", Vector3(0, 0, 38))
	geo(p.Chest, plate(_poly([Vector2(-0.07, -0.06), Vector2(0.07, -0.06), Vector2(0.075, 0.05), Vector2(0.0, 0.07),
		Vector2(-0.075, 0.05)]), 0.07, 0.018, frame(Vector3(-0.20, 0.64, 0.225), Vector3.UP, Vector3(-0.6, 0, 0.8))),
		"fire_leather")
	# Pointed team hood swept back (lab pass: the dark-crimson moved down to the coat skirt, so the archer is light on
	# top and dark at the ground; the role still reads by value through the dark skirt and the gold doublet). The hood
	# IS the head (a closed shell); a small skin oval shows in its opening with the eye bar.
	geo(p.Head, lathe([Vector2(0.0, -0.12), Vector2(0.27, -0.11), Vector2(0.31, 0.0), Vector2(0.295, 0.13),
		Vector2(0.22, 0.28), Vector2(0.12, 0.40), Vector2(0.04, 0.50), Vector2(0.0, 0.53)], 14,
		frame(Vector3(0, 1.40, -0.04), Vector3(0, cos(12.0 * DEG), -sin(12.0 * DEG)), Vector3.BACK)), "fire_cloth")
	# Liripipe: the hood point flops back into a long tail that swings out over the right shoulder (silhouette hook).
	geo(p.Head, tube([Vector3(0, 1.87, -0.13), Vector3(0.03, 1.86, -0.30), Vector3(0.10, 1.74, -0.42),
		Vector3(0.17, 1.56, -0.45)], [0.07, 0.06, 0.045, 0.0], 7), "fire_cloth")
	part(p.Head, "Face", sph(0.18), Vector3(0, 1.395, 0.20), "fire_skin", Vector3.ZERO, false, Vector3(1.0, 0.92, 0.55))
	vet_trim(p.Head, Vector3(0, 1.36, -0.07), Vector3(-15, 0, 0), 1.35)
	# Arms: coat sleeves, leather bracers, bare hands.
	arm(p, sh, Vector3(0.37, 0.94, 0.0), Vector3(0.38, 0.80, 0.02), [0.10, 0.09, 0.085], "fire_sec_archer",
		"fire_sec_archer", 0.12, "fire_skin")
	for s: int in [-1, 1]:
		var pv: Node3D = p.ArmL if s < 0 else p.ArmR
		geo(pv, lathe([Vector2(0.092, -0.075), Vector2(0.10, -0.05), Vector2(0.103, 0.05), Vector2(0.112, 0.078),
			Vector2(0.10, 0.082)], 10, Transform3D(Basis.IDENTITY, Vector3(0.38 * s, 0.83, 0.02)), true, 1.0, 1.0, false,
			false), "fire_leather")
		part(pv, "BracerLace", band(0.103, 0.012, 10), Vector3(0.38 * s, 0.83, 0.02), "fire_bronze")
	# Bow in the left fist, carried level along +Z (front tip up 22 deg), string on top. When the arm rises to
	# -85 deg for the shot the bow turns vertical with the string toward the archer (fire_model.gd).
	var g := Vector3(-0.38, 0.73, 0.05)
	# Canted ~32 deg outward so the bow line also reads from the front (a bow along +Z is edge-on to the camera).
	var ax := Vector3(-0.62, sin(22.0 * DEG), cos(22.0 * DEG)).normalized()
	var up := Vector3(0, cos(22.0 * DEG), -sin(22.0 * DEG))
	up = (up - ax * up.dot(ax)).normalized()
	var us: Array[float] = [-1.0, -0.85, -0.6, -0.3, 0.0, 0.3, 0.6, 0.85, 1.0]
	var off: Array[float] = [0.12, 0.17, 0.10, 0.025, 0.0, 0.025, 0.10, 0.17, 0.12]
	var rr: Array = [0.03, 0.037, 0.043, 0.047, 0.055, 0.047, 0.043, 0.037, 0.03]
	var bp: Array = []
	for i: int in us.size():
		bp.append(g + ax * (0.85 * us[i]) + up * off[i])
	geo(p.ArmL, tube(bp, rr, 6), "fire_bronze")
	geo(p.ArmL, tube([g - ax * 0.10, g + ax * 0.10], [0.066, 0.066], 8), "fire_leather")
	var tip_u: Vector3 = bp[bp.size() - 1]
	var tip_d: Vector3 = bp[0]
	part(p.ArmL, "TipU", sph(0.07, 8, 4), tip_u, "fire_glow")
	part(p.ArmL, "TipD", sph(0.07, 8, 4), tip_d, "fire_glow")
	part(p.ArmL, "String", tube([tip_d, tip_u], [0.014, 0.014], 4), Vector3.ZERO, "fire_skin", Vector3.ZERO, true)
	# Drawn string "V" + the nocked glowing arrow (two nodes: painted and glow never share one), hidden until the draw.
	var apex: Vector3 = g + up * 0.62
	var ds: MeshInstance3D = part(p.ArmL, "DrawnString", tube([tip_d, apex, tip_u], [0.016, 0.016, 0.016], 4),
		Vector3.ZERO, "fire_skin", Vector3.ZERO, true)
	ds.visible = false
	var da: MeshInstance3D = part(p.ArmL, "DrawnArrow", tube([apex + up * 0.04, g - up * 0.16, g - up * 0.32],
		[0.028, 0.028, 0.0], 5), Vector3.ZERO, "fire_glow", Vector3.ZERO, true)
	da.visible = false
	# Quiver on the back, tilted toward the right shoulder, 4 long arrows with smouldering (flame) fletching that
	# fan out high over the right shoulder (the 40 m silhouette hook next to the hood point).
	var qa := Vector3(sin(24.0 * DEG), cos(24.0 * DEG), 0)
	var qc := Vector3(0.08, 0.98, -0.33)
	geo(p.Chest, lathe([Vector2(0.0, -0.27), Vector2(0.105, -0.27), Vector2(0.115, 0.22), Vector2(0.13, 0.24),
		Vector2(0.13, 0.28), Vector2(0.0, 0.26)], 8, frame(qc, qa, Vector3.BACK)), "fire_leather")
	part(p.Chest, "QuiverBand", band(0.127, 0.02), qc + qa * 0.24, "fire_bronze", Vector3(0, 0, -24), false,
		Vector3(1, 1.2, 1))
	var qtop: Vector3 = qc + qa * 0.25
	var fan: Array[float] = [10.0, -8.0, 22.0, 2.0]
	var alen: Array[float] = [0.44, 0.36, 0.40, 0.48]
	var ofs: Array[Vector3] = [Vector3(0.045, 0, 0.04), Vector3(-0.045, 0, 0.035), Vector3(0.03, 0, -0.045), Vector3(-0.035, 0, -0.04)]
	for i: int in ofs.size():
		var a0: Vector3 = qtop + ofs[i]
		var ad: Vector3 = Vector3(sin((24.0 + fan[i]) * DEG), cos((24.0 + fan[i]) * DEG), -0.12).normalized()
		geo(p.Chest, tube([a0, a0 + ad * alen[i]], [0.022, 0.022], 4), "fire_wood")
		part(p.Chest, "Fletch", cone(0.06, 0.19, 4), a0 + ad * (alen[i] + 0.06), "fire_flame", Vector3(-7, 0, -(24.0 + fan[i])))
	burn_fx(p, 0.8, 0.25)
	return _finish({"scale": INFANTRY_SCALE, "body_height": 1.9, "attack_style": &"bow_draw", "attack_windup": 0.15, "fire_kind": &"archer",
		"death_style": &"fall", "stride_time": 0.52, "is_quadruped": false, "stride_speed": 5.2,
		"idle_period": 3.0, "walk_bounce": 0.05, "leg_swing_deg": 30.0})


# ================================================================ 4.4 Blaze Rider
# Replaced by task 13.V10: art/units/fire/blaze_rider.tscn is now hand-authored (the shared Ember Boar + a seated
# BlazeRiderRider, art/units/fire/blaze_rider/). This builder no longer writes it.



# ================================================================ 4.5 Ash Hurler (artillery, 1.6 m)
# Hunched soot-stained engineer: leather cap, glowing goggles, bronze respirator, team scarf, big gloves, a smoking
# bronze ash pot on the back and a 2.3 m staff-sling whose bronze claw holds a cracked, ember-lit ash ball.
# Silhouette: the tallest Fire line unit (pole + ball), hunched body, round pot behind.

func _ash_hurler() -> Node3D:
	var sh := Vector3(0.38, 1.02, 0.06)
	var p: Dictionary = rig("AshHurler", 0.45, 0.54, 1.10, sh, Vector3(0.16, 0.50, 0.0))
	# G-C: shaped legs, heavy boots with dark turned-down cuffs.
	legs(p, 0.16, 0.50, 0.115, "fire_leather", "fire_leather", 1.05, "", "fire_cloth_dark")
	# Hunched body (12 deg forward), leather apron and crossed harness.
	var lean := Vector3(0, cos(12.0 * DEG), sin(12.0 * DEG))
	geo(p.Chest, lathe([Vector2(0.32, 0.0), Vector2(0.365, 0.12), Vector2(0.365, 0.32), Vector2(0.31, 0.50),
		Vector2(0.22, 0.62), Vector2(0.10, 0.68), Vector2(0.0, 0.69)], 12, frame(Vector3(0, 0.46, 0), lean, Vector3.BACK),
		true, 1.0, 0.9), "fire_sec_hurler")
	# G-C: bevelled apron with a coat-cloth pocket and iron rivets, bevelled harness straps crossing on an iron ring.
	var af: Transform3D = frame(Vector3(0, 0.66, 0.345), Vector3(0, 1, -0.02), Vector3.BACK)
	geo(p.Chest, plate(_poly([Vector2(-0.20, -0.24), Vector2(0.20, -0.24), Vector2(0.22, 0.12), Vector2(0.14, 0.22),
		Vector2(-0.14, 0.22), Vector2(-0.22, 0.12)]), 0.05, 0.016, af), "fire_leather")
	geo(p.Chest, plate(_poly([Vector2(-0.09, -0.07), Vector2(0.09, -0.07), Vector2(0.095, 0.05), Vector2(-0.095, 0.05)]),
		0.03, 0.01, af * Transform3D(Basis.IDENTITY, Vector3(0.06, -0.09, 0.03))), "fire_sec_hurler")
	rivets(p.Chest, [af * Vector3(-0.17, 0.15, 0.028), af * Vector3(0.17, 0.15, 0.028)], 0.022, "fire_iron")
	var strap := _poly([Vector2(-0.04, -0.30), Vector2(0.04, -0.30), Vector2(0.04, 0.30), Vector2(-0.04, 0.30)])
	geo(p.Chest, plate(strap, 0.05, 0.014, xf(Vector3(0, 0.90, 0.30), Vector3(-4, 0, 30))), "fire_leather")
	geo(p.Chest, plate(strap, 0.05, 0.014, xf(Vector3(0, 0.90, 0.30), Vector3(-4, 0, -30))), "fire_leather")
	part(p.Chest, "HarnessRing", band(0.05, 0.016, 8), Vector3(0, 0.90, 0.33), "fire_iron", Vector3(90, 0, 0))
	part(p.Chest, "Scarf", torus(0.15, 0.30), Vector3(0, 1.10, 0.08), "fire_cloth", Vector3(-12, 0, 0), false, Vector3(1, 1.5, 1))
	geo(p.Chest, plate(_poly([Vector2(-0.075, 0.18), Vector2(0.075, 0.18), Vector2(0.06, -0.12), Vector2(0.0, -0.19),
		Vector2(-0.06, -0.12)]), 0.04, 0.012, xf(Vector3(0.12, 0.93, -0.25), Vector3(-20, 0, -10))), "fire_cloth")
	# Head (forward), leather cap with flaps, glowing goggles pushed UP onto the cap, the bronze respirator pulled
	# down under the chin: the face shows (FaceKit face attached by FireModel, faces pass 2026-09-28).
	part(p.Head, "Head", sph(0.25), Vector3(0, 1.28, 0.14), "fire_skin")
	geo(p.Head, lathe([Vector2(0.27, 1.37), Vector2(0.267, 1.43), Vector2(0.235, 1.49), Vector2(0.15, 1.54),
		Vector2(0.0, 1.56)], 12, Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.12))), "fire_leather")
	for s: int in [-1, 1]:
		geo(p.Head, extrude(_poly([Vector2(-0.065, 0.10), Vector2(0.065, 0.10), Vector2(0.06, -0.05), Vector2(0.0, -0.10),
			Vector2(-0.06, -0.05)]), 0.06, frame(Vector3(0.25 * s, 1.285, 0.12), Vector3.UP, Vector3(s, 0, 0))), "fire_leather")
		part(p.Head, "Lens", cyl(0.078, 0.078, 0.06, 10), Vector3(0.095 * s, 1.47, 0.345), "fire_glow", Vector3(52, 0, 0))
		part(p.Head, "LensRim", band(0.097, 0.02), Vector3(0.095 * s, 1.465, 0.335), "fire_bronze", Vector3(52, 0, 0))
	part(p.Head, "Strap", band(0.272, 0.02), Vector3(0, 1.44, 0.13), "fire_leather", Vector3(-4, 0, 0), false, Vector3(1, 1.4, 1))
	var rf: Transform3D = xf(Vector3(0, 1.06, 0.30), Vector3(118, 0, 0))
	geo(p.Head, lathe([Vector2(0.10, -0.065), Vector2(0.104, -0.03), Vector2(0.096, 0.03), Vector2(0.088, 0.06),
		Vector2(0.06, 0.07), Vector2(0.0, 0.072)], 10, rf), "fire_bronze")
	vet_trim(p.Head, Vector3(0, 1.26, 0.12), Vector3.ZERO, 1.25)
	# Arms: sleeves + big bronze gloves.
	arm(p, sh, Vector3(0.43, 0.82, 0.10), Vector3(0.44, 0.68, 0.12), [0.11, 0.10, 0.09], "fire_sec_hurler",
		"fire_sec_hurler", 0.15, "fire_bronze")
	for s: int in [-1, 1]:
		var pv: Node3D = p.ArmL if s < 0 else p.ArmR
		geo(pv, lathe([Vector2(0.108, -0.05), Vector2(0.114, -0.02), Vector2(0.125, 0.04), Vector2(0.135, 0.06),
			Vector2(0.12, 0.065)], 10, Transform3D(Basis.IDENTITY, Vector3(0.44 * s, 0.70, 0.12)), true, 1.0, 1.0, false,
			false), "fire_leather")
	# Ash pot on the back: bronze body, glowing rim, dark lid, smoke.
	var po := Vector3(0, 0, -0.42)
	geo(p.Chest, lathe([Vector2(0.0, 0.70), Vector2(0.15, 0.70), Vector2(0.24, 0.78), Vector2(0.285, 0.93),
		Vector2(0.29, 1.07), Vector2(0.245, 1.19), Vector2(0.20, 1.24), Vector2(0.235, 1.265), Vector2(0.235, 1.30),
		Vector2(0.0, 1.30)], 10, Transform3D(Basis.IDENTITY, po)), "fire_bronze")
	part(p.Chest, "PotGlow", band(0.233, 0.032), po + Vector3(0, 1.31, 0), "fire_glow")
	geo(p.Chest, lathe([Vector2(0.20, 1.30), Vector2(0.19, 1.34), Vector2(0.10, 1.39), Vector2(0.0, 1.40)], 8,
		Transform3D(Basis.IDENTITY, po)), "fire_cloth_dark")
	part(p.Chest, "PotBand", band(0.301, 0.023, 12), po + Vector3(0, 0.93, 0), "fire_iron", Vector3.ZERO, false, Vector3(1, 1.4, 1))
	var prv: Array = []
	for i: int in 3:
		var a: float = -1.2 + 1.2 * i
		prv.append(po + Vector3(sin(a) * 0.305, 0.93, cos(a) * 0.305 * -1.0))
	rivets(p.Chest, prv, 0.022, "fire_bronze")
	for s: int in [-1, 1]:
		part(p.Chest, "PotHandle", band(0.065, 0.014, 8), po + Vector3(0.29 * s, 1.12, 0), "fire_iron", Vector3(0, 0, 90))
	particles(p.Fx, "PotSmoke", 6, 2.0, po + Vector3(0, 1.44, 0), Vector3(0.08, 0.02, 0.08), 0.5, 0.25, 0.65,
		[Color(0.30, 0.24, 0.22, 0.35), Color(0.28, 0.22, 0.20, 0.2), Color(0.28, 0.22, 0.20, 0.0)], false)
	# Staff-sling: pole up from the right glove, bronze bands, a 3-prong claw holding the ash ball.
	var fist := Vector3(0.44, 0.60, 0.14)
	var pa := Vector3(0.03, 1, 0.05).normalized()
	var top: Vector3 = fist + pa * 1.70
	geo(p.ArmR, tube([fist - pa * 0.26, top], [0.05, 0.045], 6), "fire_wood")
	for k: float in [0.55, 1.62]:
		part(p.ArmR, "Band", cyl(0.062, 0.062, 0.07, 8), fist + pa * k, "fire_bronze")
	for i: int in 3:
		var a: float = TAU * i / 3.0 + 0.5
		var o := Vector3(cos(a), 0, sin(a))
		geo(p.ArmR, tube([top + o * 0.03, top + o * 0.16 + pa * 0.14, top + o * 0.19 + pa * 0.30,
			top + o * 0.12 + pa * 0.43], [0.035, 0.03, 0.026, 0.0], 5), "fire_bronze")
	part(p.ArmR, "AshBall", sph(0.19), top + pa * 0.25, "fire_ash_ball", Vector3.ZERO, true)
	burn_fx(p, 0.8, 0.3)
	return _finish({"scale": INFANTRY_SCALE, "body_height": 1.8, "attack_style": &"sling_throw", "attack_windup": 0.15, "fire_kind": &"hurler",
		"death_style": &"fall", "stride_time": 0.6, "is_quadruped": false, "stride_speed": 4.0,
		"idle_period": 3.2, "walk_bounce": 0.045, "leg_swing_deg": 26.0})
