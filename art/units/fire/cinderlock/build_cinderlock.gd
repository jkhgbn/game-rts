extends SceneTree
## 13b.V1 Cinderlock Musketeer: builds art/units/fire/cinderlock/cinderlock.tscn (tier3-extras.md 4 / 12).
## Built on the Fire kit (art/units/fire/build_fire_units.gd: the same mesh helpers - lathe / band / tube / extrude,
## pre-merge per (pivot, material), burn fx - copied below because that builder regenerates the five Fire scenes from
## its constructor): the Ember Archer body (lean coat, legs, arms, 1.14 m shoulders) with the Flame Guard's bronze
## (gorget, buckle, fittings), plus the new parts: the cavalier hat with the tall team plume, the bandolier with the
## glowing powder flasks, the long bell-mouthed musket (its own node under the Chest: CinderlockModel poses it) with
## the muzzle ember and the ramrod.
## Rig constants (shoulders, grip, musket frame) live in cinderlock_model.gd so the poses and the geometry agree.
## Materials: the kit's closed Fire palette + 2 files of this folder (materials/fire_sec_cinderlock = the Fire
## secondary leather (0.70, 0.45, 0.20) of tier3-extras 4.1, fire_gunmetal = the blackened barrel), written here.
## Run (headless is fine):
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . -s art/units/fire/cinderlock/build_cinderlock.gd --quit-after 120
## Re-run after changing anything here; the .tscn is generated, do not hand-edit it.

const DIR: String = "res://art/units/fire/cinderlock/"
const KIT_MAT_DIR: String = "res://art/units/kit/materials/"
const MODEL_SCRIPT: String = "res://art/units/fire/cinderlock/cinderlock_model.gd"
const CL = preload("res://art/units/fire/cinderlock/cinderlock_model.gd")
const DEG: float = PI / 180.0
const FLIP: bool = false
const GLOW_MATS: Array[String] = ["fire_glow", "fire_glow_hero", "fire_flame", "crystal"]

var M: Dictionary = {}
var _root: Node3D
var _acc: Dictionary = {}
var _acc_order: Array[String] = []
var _authored: int = 0


func _init() -> void:
	_make_materials()
	_save(_cinderlock(), "cinderlock")
	print("CINDERLOCK BUILD OK")
	quit()


# ---------------------------------------------------------------- materials

func _make_materials() -> void:
	for id: String in ["fire_cloth", "fire_cloth_dark", "fire_skin", "fire_bronze", "fire_leather", "fire_wood",
			"fire_hair", "fire_glow", "fire_flame"]:
		M[id] = load(KIT_MAT_DIR + id + ".tres")
	M["eye_dark"] = load(KIT_MAT_DIR + "unit_eye_dark.tres")
	M["gold_trim"] = load(KIT_MAT_DIR + "unit_gold_trim.tres")
	M["blob"] = load(KIT_MAT_DIR + "unit_shadow_blob.tres")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR + "materials"))
	# Same recipe as the kit's make_materials.gd (painted shader, paint noise, rim 0.25).
	M["fire_sec_cinderlock"] = _painted("fire_sec_cinderlock", Color(0.70, 0.45, 0.20), 0.0)
	M["fire_gunmetal"] = _painted("fire_gunmetal", Color(0.17, 0.14, 0.13), 0.35)


func _painted(id: String, col: Color, spec: float) -> Material:
	var m := ShaderMaterial.new()
	m.shader = load("res://art/units/kit/unit_painted.gdshader")
	m.resource_name = id
	m.set_shader_parameter(&"base_color", col)
	m.set_shader_parameter(&"noise_tex", load("res://art/shaders/paint_noise.tres"))
	m.set_shader_parameter(&"spec_strength", spec)
	m.set_shader_parameter(&"rim_strength", 0.25)
	var path: String = DIR + "materials/" + id + ".tres"
	var err: int = ResourceSaver.save(m, path)
	if err != OK:
		push_error("material save failed " + path)
	return load(path)

# ---------------------------------------------------------------- primitive meshes (as build_fire_units.gd)

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


func box(x: float, y: float, z: float) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(x, y, z)
	return m

# ---------------------------------------------------------------- custom meshes (SurfaceTool, normals by hand)

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
			var a1: float = TAU * (j + 1) / seg
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
			var a1: float = TAU * (j + 1) / seg
			_xtri(st, xf, nb, c, _lv(pe, a0, sx, sz), _lv(pe, a1, sx, sz), up, up, up, false)
	return _done(st)


func band(r: float, h: float, seg: int = 10, xf: Transform3D = Transform3D.IDENTITY, sx: float = 1.0,
		sz: float = 1.0) -> ArrayMesh:
	return lathe([Vector2(r - h * 0.35, -h), Vector2(r + h * 0.45, 0.0), Vector2(r - h * 0.35, h)], seg, xf, true,
		sx, sz, false, false)


func _lv(p: Vector2, a: float, sx: float, sz: float) -> Vector3:
	return Vector3(p.x * sin(a) * sx, p.y, p.x * cos(a) * sz)


func _ln(nn: Vector2, a: float, sx: float, sz: float) -> Vector3:
	return Vector3(nn.x * sin(a) / sx, nn.y, nn.x * cos(a) / sz).normalized()


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


## Cavalier brim: a thick ring (r_in..r_out) at height y, the right side (+X) cocked up (rise at the edge), a slight
## droop front and back. Top, bottom and outer rim surfaces; smooth radial normals on the flat faces.
func brim(r_in: float, r_out: float, y: float, thick: float, rise: float, droop: float, seg: int = 20) -> ArrayMesh:
	var st := _st()
	var rings: int = 3
	var top: Array = []
	var bot: Array = []
	for j: int in seg + 1:
		var a: float = TAU * j / seg
		var sa: float = sin(a)
		var k: float = smoothstep(0.15, 0.95, sa)
		var tr: Array[Vector3] = []
		var br: Array[Vector3] = []
		for i: int in rings + 1:
			var u: float = float(i) / rings
			var r: float = lerpf(r_in, r_out, u)
			var h: float = y + rise * k * pow(u, 1.6) - droop * (1.0 - k) * u * u * (0.6 + 0.4 * absf(cos(a)))
			var p := Vector3(r * sa, h, r * cos(a))
			tr.append(p + Vector3(0, thick * 0.5, 0))
			br.append(p - Vector3(0, thick * 0.5, 0))
		top.append(tr)
		bot.append(br)
	for j: int in seg:
		for i: int in rings:
			var t0: Array[Vector3] = top[j]
			var t1: Array[Vector3] = top[j + 1]
			var b0: Array[Vector3] = bot[j]
			var b1: Array[Vector3] = bot[j + 1]
			var nt: Vector3 = (t1[i + 1] - t0[i]).cross(t0[i + 1] - t1[i]).normalized()
			if nt.y < 0.0:
				nt = -nt
			_tri(st, t0[i], t0[i + 1], t1[i + 1], nt, nt, nt)
			_tri(st, t0[i], t1[i + 1], t1[i], nt, nt, nt)
			_tri(st, b0[i], b0[i + 1], b1[i + 1], -nt, -nt, -nt)
			_tri(st, b0[i], b1[i + 1], b1[i], -nt, -nt, -nt)
		# outer rim
		var ta: Vector3 = (top[j] as Array[Vector3])[rings]
		var tb: Vector3 = (top[j + 1] as Array[Vector3])[rings]
		var ba: Vector3 = (bot[j] as Array[Vector3])[rings]
		var bb: Vector3 = (bot[j + 1] as Array[Vector3])[rings]
		var na := Vector3(ta.x, 0, ta.z).normalized()
		var nbv := Vector3(tb.x, 0, tb.z).normalized()
		_tri(st, ta, tb, bb, na, nbv, nbv)
		_tri(st, ta, bb, ba, na, nbv, na)
	return _done(st)

# ---------------------------------------------------------------- scene helpers (as build_fire_units.gd)

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
		if GLOW_MATS.has(e[1]):
			mi.set_meta(&"keep_separate", true)
			mi.name = "Glow" + mi.name
		(e[0] as Node3D).add_child(mi)
		mi.owner = _root
	_acc.clear()
	_acc_order.clear()


func xf(pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot_deg * DEG) * Basis.from_scale(scl), pos)


func rig(unit_name: String, radius: float, waist_y: float, neck_y: float, shoulder: Vector3,
		leg_top: Vector3) -> Dictionary:
	_root = Node3D.new()
	_root.name = unit_name
	_authored = 0
	var p: Dictionary = {}
	p.Root = _node(_root, "Root")
	p.Hips = _node(p.Root, "Hips")
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


func boot(pv: Node3D, x: float, z: float, s: float, mat: String) -> void:
	var pts: Array = [Vector2(-0.13, 0.0), Vector2(0.16, 0.0), Vector2(0.215, 0.035), Vector2(0.215, 0.09),
		Vector2(0.15, 0.14), Vector2(0.07, 0.16), Vector2(0.07, 0.25), Vector2(-0.12, 0.25), Vector2(-0.145, 0.12)]
	var poly := PackedVector2Array()
	for q: Vector2 in pts:
		poly.append(q * s)
	geo(pv, extrude(poly, 0.25 * s, frame(Vector3(x, 0, z), Vector3.UP, Vector3.LEFT)), mat)


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
	var path: String = DIR + id + ".tscn"
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
	for ch: Node in n.get_children():
		_count(ch, c)

# ---------------------------------------------------------------- particles (the Fire death burn)

func _particle_mat(additive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
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
	gt.use_hdr = true
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


## The Fire death burn (rising embers only: the ash puff is left out to keep the draw budget).
func burn_fx(p: Dictionary, y: float, spread_xz: float) -> void:
	var e: GPUParticles3D = particles(p.Fx, "BurnEmbers", 16, 0.9, Vector3(0, y, 0),
		Vector3(spread_xz, y * 0.5, spread_xz), 1.8, 0.16, 0.04,
		[Color(2.6, 0.95, 0.25, 1.0), Color(1.7, 0.36, 0.06, 0.9), Color(0.5, 0.08, 0.02, 0.0)], false, true, 45.0,
		Vector3(0, 1.2, 0))
	e.set_meta(&"burn_fx", true)

# ================================================================ the musket (its own node, 3 surfaces)

## Appends mesh (transformed) to the per-material SurfaceTools of a multi-surface prop.
func _macc(acc: Dictionary, order: Array, mat: String, mesh: Mesh, t: Transform3D = Transform3D.IDENTITY) -> void:
	if not acc.has(mat):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		acc[mat] = st
		order.append(mat)
	for s: int in mesh.get_surface_count():
		(acc[mat] as SurfaceTool).append_from(mesh, s, t)


func _mcommit(acc: Dictionary, order: Array) -> ArrayMesh:
	var am := ArrayMesh.new()
	for mat: String in order:
		var st: SurfaceTool = acc[mat]
		st.index()
		st.commit(am)
		am.surface_set_material(am.get_surface_count() - 1, M[mat])
	return am


## Musket space: origin = the right fist, +Z = toward the muzzle, +Y = the top of the gun, X = its right side.
## Bell rim at z = MUZZLE_S (1.03), butt plate at BUTT_S (-0.32): 1.35 m.
func _musket_mesh() -> ArrayMesh:
	var acc: Dictionary = {}
	var order: Array = []
	var by: float = CL.BORE_Y
	# Stock + forestock: one side profile (z, y) extruded 7.5 cm wide.
	var side := Transform3D(Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0)), Vector3.ZERO)
	_macc(acc, order, "fire_wood", extrude(_poly([Vector2(-0.325, 0.050), Vector2(-0.20, 0.046), Vector2(-0.07, 0.022),
		Vector2(0.05, 0.018), Vector2(0.70, 0.014), Vector2(0.745, -0.004), Vector2(0.70, -0.030), Vector2(0.10, -0.034),
		Vector2(0.03, -0.046), Vector2(-0.08, -0.052), Vector2(-0.20, -0.088), Vector2(-0.325, -0.130)]), 0.075, side))
	# Cheek-piece swell on the butt (chunkier read).
	_macc(acc, order, "fire_wood", sph(0.075, 6, 3), xf(Vector3(0, -0.035, -0.22), Vector3.ZERO, Vector3(0.62, 0.95, 1.5)))
	# Blackened barrel on the stock, long.
	_macc(acc, order, "fire_gunmetal", tube([Vector3(0, by, -0.10), Vector3(0, by, 0.45), Vector3(0, by, 0.86)],
		[0.037, 0.035, 0.032], 5))
	# Hammer (the cinder lock) on the right side.
	_macc(acc, order, "fire_gunmetal", tube([Vector3(0.05, 0.02, -0.08), Vector3(0.055, 0.08, -0.09),
		Vector3(0.05, 0.105, -0.05)], [0.018, 0.016, 0.012], 5))
	# Dark throat of the bell (inner lathe, faces inward).
	var bell_f: Transform3D = frame(Vector3(0, by, 0), Vector3(0, 0, 1), Vector3(0, 1, 0))
	_macc(acc, order, "fire_gunmetal", lathe([Vector2(0.146, 1.042), Vector2(0.105, 1.003), Vector2(0.066, 0.960),
		Vector2(0.034, 0.925), Vector2(0.0, 0.915)], 7, bell_f, true, 1.0, 1.0, false, false))
	# Bronze: the bell mouth (the read), its collar, 2 barrel bands, lock plate, butt plate, trigger guard.
	_macc(acc, order, "fire_bronze", lathe([Vector2(0.038, 0.80), Vector2(0.045, 0.86), Vector2(0.062, 0.925),
		Vector2(0.095, 0.975), Vector2(0.138, 1.010), Vector2(0.166, 1.030), Vector2(0.170, 1.044),
		Vector2(0.146, 1.047)], 7, bell_f, true, 1.0, 1.0, false, false))
	_macc(acc, order, "fire_bronze", band(0.047, 0.026, 8), frame(Vector3(0, by, 0.83), Vector3(0, 0, 1), Vector3.UP))
	for z: float in [0.30, 0.60]:
		_macc(acc, order, "fire_bronze", band(0.052, 0.022, 8), frame(Vector3(0, 0.012, z), Vector3(0, 0, 1), Vector3.UP))
	_macc(acc, order, "fire_bronze", box(0.022, 0.056, 0.17), xf(Vector3(0.041, 0.018, -0.03)))
	_macc(acc, order, "fire_bronze", box(0.084, 0.19, 0.026), xf(Vector3(0, -0.04, -0.33)))
	_macc(acc, order, "fire_bronze", tube([Vector3(0, -0.035, -0.08), Vector3(0, -0.078, -0.05), Vector3(0, -0.082, 0.0),
		Vector3(0, -0.042, 0.035)], [0.012, 0.012, 0.012, 0.012], 5))
	return _mcommit(acc, order)


func _ramrod_mesh() -> ArrayMesh:
	var acc: Dictionary = {}
	var order: Array = []
	_macc(acc, order, "fire_wood", tube([Vector3(0, 0, 0.0), Vector3(0, 0, CL.ROD_LEN - 0.02)], [0.019, 0.019], 6))
	_macc(acc, order, "fire_bronze", sph(0.036, 8, 4), xf(Vector3(0, 0, CL.ROD_LEN)))
	return _mcommit(acc, order)

# ================================================================ 13b.V1 Cinderlock Musketeer (1.7 m, plume to 2.1 m)
# A swaggering Fire musketeer: broad dark cavalier hat cocked up on the right with a tall team plume, a long tan
# leather coat (Fire secondary), a leather bandolier with a row of glowing powder flasks (right shoulder to left hip),
# tall flared boots, a moustache, a bronze gorget; a long bell-mouthed musket carried across the chest at port arms
# (butt at the right hip, the flared bronze bell with its ember up past the left shoulder).
# Silhouette: the wide flat hat disc + plume, and the long diagonal gun line ending in a flare (the X of gun and
# glowing bandolier across the chest).

func _cinderlock() -> Node3D:
	var sh := Vector3(CL.SHOULDER_R.x, CL.SHOULDER_R.y, 0.0)
	var p: Dictionary = rig("Cinderlock", 0.45, CL.CHEST_POS.y, CL.NECK_POS.y, sh, Vector3(0.14, 0.52, 0.0))
	# ---- legs: dark breeches, tall leather boots with wide flared tops.
	for s: int in [-1, 1]:
		var pv: Node3D = p.LegL if s < 0 else p.LegR
		var x: float = 0.14 * s
		geo(pv, tube([Vector3(x, 0.54, 0.0), Vector3(x, 0.45, 0.01), Vector3(x, 0.36, 0.015)], [0.105, 0.10, 0.092], 5),
			"fire_cloth_dark")
		geo(pv, tube([Vector3(x, 0.40, 0.015), Vector3(x, 0.27, 0.012), Vector3(x, 0.14, 0.0)], [0.098, 0.093, 0.085], 5),
			"fire_leather")
		geo(pv, lathe([Vector2(0.092, 0.33), Vector2(0.135, 0.41), Vector2(0.158, 0.455), Vector2(0.148, 0.465)], 6,
			xf(Vector3(x, 0.0, 0.02), Vector3(-6, 0, 0)), true, 1.0, 1.0, false, false), "fire_leather")
		boot(pv, x, 0.02, 1.0, "fire_leather")
	# ---- coat: long flared tan leather (Fire secondary), dark hem, front seam, belt + buckle, team sash + knot.
	geo(p.Chest, lathe([Vector2(0.375, 0.33), Vector2(0.335, 0.45), Vector2(0.29, 0.61), Vector2(0.272, 0.72),
		Vector2(0.295, 0.92), Vector2(0.305, 1.06), Vector2(0.265, 1.17), Vector2(0.15, 1.25), Vector2(0.0, 1.26)], 9,
		Transform3D.IDENTITY, true, 1.0, 0.85), "fire_sec_cinderlock")
	part(p.Chest, "Hem", band(0.382, 0.032, 9), Vector3(0, 0.345, 0), "fire_cloth_dark", Vector3.ZERO, false,
		Vector3(1, 1.3, 0.86))
	part(p.Chest, "Seam", box(0.045, 0.36, 0.03), Vector3(0, 0.52, 0.272), "fire_cloth_dark", Vector3(-15, 0, 0))
	part(p.Chest, "Belt", band(0.283, 0.034, 9), Vector3(0, 0.71, 0), "fire_leather", Vector3.ZERO, false,
		Vector3(1, 1.3, 0.87))
	part(p.Chest, "Buckle", box(0.13, 0.11, 0.05), Vector3(0.0, 0.71, 0.245), "fire_bronze")
	part(p.Chest, "Sash", band(0.296, 0.036, 9), Vector3(0, 0.79, 0), "fire_cloth", Vector3(0, 0, -7), false,
		Vector3(1, 1.2, 0.87))
	part(p.Chest, "SashKnot", sph(0.075, 6, 3), Vector3(-0.27, 0.76, 0.10), "fire_cloth")
	part(p.Chest, "SashTail", box(0.10, 0.30, 0.04), Vector3(-0.30, 0.60, 0.10), "fire_cloth", Vector3(4, -60, 8))
	# Team falling collar and puffed team shoulder rolls (the team read under the hat).
	geo(p.Chest, lathe([Vector2(0.30, 1.13), Vector2(0.29, 1.165), Vector2(0.22, 1.22), Vector2(0.13, 1.26),
		Vector2(0.10, 1.27)], 9, Transform3D.IDENTITY, true, 1.0, 0.9, false, false), "fire_cloth")
	for s: int in [-1, 1]:
		part(p.Chest, "ShoulderRoll", sph(0.125, 7, 3), Vector3(0.345 * s, 1.14, 0.0), "fire_cloth", Vector3.ZERO, false,
			Vector3(1.05, 0.85, 1.1))
	# ---- bandolier: right shoulder -> left hip over the chest, round the back; 6 glowing powder flasks (the glow row).
	var bf: Array = [Vector3(0.26, 1.21, 0.07), Vector3(0.22, 1.15, 0.19), Vector3(0.10, 1.02, 0.262),
		Vector3(-0.05, 0.87, 0.268), Vector3(-0.19, 0.72, 0.245), Vector3(-0.29, 0.62, 0.17)]
	geo(p.Chest, tube(bf, [0.036, 0.038, 0.038, 0.038, 0.038, 0.036], 4), "fire_leather")
	geo(p.Chest, tube([Vector3(0.26, 1.21, 0.07), Vector3(0.24, 1.22, -0.08), Vector3(0.15, 1.08, -0.245),
		Vector3(-0.12, 0.80, -0.255), Vector3(-0.29, 0.62, -0.13), Vector3(-0.31, 0.61, 0.03)],
		[0.036, 0.036, 0.036, 0.036, 0.036, 0.036], 4), "fire_leather")
	var flasks: Array = [Vector3(0.235, 1.165, 0.225), Vector3(0.18, 1.105, 0.268), Vector3(-0.125, 0.785, 0.30),
		Vector3(-0.19, 0.715, 0.285), Vector3(-0.25, 0.648, 0.245)]
	for fp: Vector3 in flasks:
		part(p.Chest, "Flask", sph(0.062, 5, 3), fp, "fire_glow", Vector3.ZERO, false, Vector3(1.0, 1.25, 0.85))
		# (the 5 cm bronze flask caps were cut: below the 0.12 m detail rule, and B4 < 2 500, in-game pass 2026-09-30)
	# Cartridge satchel on the right hip, behind.
	part(p.Chest, "Satchel", box(0.19, 0.17, 0.09), Vector3(0.25, 0.60, -0.20), "fire_leather", Vector3(0, 32, 0))
	part(p.Chest, "SatchelFlap", box(0.20, 0.07, 0.10), Vector3(0.25, 0.675, -0.20), "fire_bronze", Vector3(0, 32, 0))
	# ---- head: face (eyes / brows / mouth: the FaceKit face FireModel attaches, faces pass 2026-09-28), nose, curled moustache + goatee, hair mane, bronze gorget.
	part(p.Head, "Face", sph(0.175, 8, 4), Vector3(0, 1.37, 0.06), "fire_skin", Vector3.ZERO, false, Vector3(1.0, 1.05, 0.95))
	part(p.Head, "Nose", sph(0.05, 6, 3), Vector3(0, 1.355, 0.225), "fire_skin")
	geo(p.Head, tube([Vector3(-0.17, 1.36, 0.14), Vector3(-0.08, 1.31, 0.215), Vector3(0.0, 1.322, 0.228),
		Vector3(0.08, 1.31, 0.215), Vector3(0.17, 1.36, 0.14)], [0.0, 0.034, 0.03, 0.034, 0.0], 5), "fire_hair")
	part(p.Head, "Goatee", cone(0.045, 0.12, 5), Vector3(0, 1.225, 0.185), "fire_hair", Vector3(160, 0, 0))
	part(p.Head, "Mane", sph(0.20, 7, 3), Vector3(0, 1.33, -0.08), "fire_hair", Vector3.ZERO, false, Vector3(1.12, 1.05, 0.9))
	part(p.Head, "Gorget", band(0.165, 0.04, 8), Vector3(0, 1.215, 0.02), "fire_bronze", Vector3(-8, 0, 0), false,
		Vector3(1, 1.25, 1))
	# ---- the hat: dark leather crown, team band, broad brim cocked up on the right, bronze brooch, tall team plume.
	geo(p.Head, lathe([Vector2(0.205, 1.50), Vector2(0.222, 1.58), Vector2(0.212, 1.67), Vector2(0.172, 1.745),
		Vector2(0.09, 1.782), Vector2(0.0, 1.79)], 9, xf(Vector3(0, 0, -0.01)), true, 1.0, 1.06), "fire_leather")
	part(p.Head, "HatBand", band(0.224, 0.032, 9), Vector3(0, 1.545, -0.01), "fire_cloth", Vector3.ZERO, false,
		Vector3(1, 1.2, 1.06))
	geo(p.Head, brim(0.19, 0.44, 1.515, 0.034, 0.25, 0.05, 12), "fire_leather")
	part(p.Head, "Brooch", sph(0.05, 6, 3), Vector3(0.315, 1.62, 0.04), "fire_bronze")
	geo(p.Head, tube([Vector3(0.29, 1.60, 0.06), Vector3(0.34, 1.78, 0.02), Vector3(0.32, 1.96, -0.10),
		Vector3(0.22, 2.07, -0.28), Vector3(0.09, 2.05, -0.45), Vector3(-0.01, 1.95, -0.55)],
		[0.035, 0.085, 0.105, 0.095, 0.07, 0.0], 5), "fire_cloth")
	geo(p.Head, tube([Vector3(0.28, 1.60, 0.10), Vector3(0.40, 1.74, 0.06), Vector3(0.45, 1.86, -0.08),
		Vector3(0.43, 1.85, -0.24)], [0.03, 0.062, 0.058, 0.0], 5), "fire_cloth")
	vet_trim(p.Head, Vector3(0, 1.60, -0.01), Vector3.ZERO, 0.97)
	# ---- arms, bent for port arms (rigid; CinderlockModel re-aims them per pose): coat sleeves, flared leather
	# gauntlets, gloved fists on the stock (right) and under the forestock (left).
	var fr: Vector3 = CL.GRIP
	var fl: Vector3 = CL.fist_l_rest()
	var arms: Array = [[p.ArmR, CL.SHOULDER_R, Vector3(0.44, 0.93, 0.03), fr + Vector3(0.065, 0.02, -0.05), fr],
		[p.ArmL, CL.SHOULDER_L, Vector3(-0.40, 0.90, 0.17), fl + Vector3(-0.075, 0.01, -0.03), fl]]
	for a: Array in arms:
		var pv: Node3D = a[0]
		var s0: Vector3 = a[1]
		var el: Vector3 = a[2]
		var wr: Vector3 = a[3]
		var fist: Vector3 = a[4]
		geo(pv, tube([s0, el], [0.10, 0.088], 5), "fire_sec_cinderlock")
		geo(pv, tube([el, wr], [0.088, 0.08], 5), "fire_sec_cinderlock")
		var fd: Vector3 = (wr - el).normalized()
		geo(pv, lathe([Vector2(0.078, -0.02), Vector2(0.118, 0.10), Vector2(0.126, 0.125)], 6,
			frame(wr - fd * 0.13, fd, Vector3.UP), true, 1.0, 1.0, false, false), "fire_leather")
		part(pv, "Fist", sph(0.10, 6, 4), fist, "fire_leather")
	# ---- the musket: own node under the Chest (posed by the model), ember + ramrod children.
	var mrest: Transform3D = CL.musket_rest()
	var mk := MeshInstance3D.new()
	mk.name = "Musket"
	mk.mesh = _musket_mesh()
	mk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mk.set_meta(&"keep_separate", true)
	(p.Chest as Node3D).add_child(mk)
	mk.owner = _root
	mk.transform = Transform3D(mrest.basis, mrest.origin - CL.CHEST_POS)
	_authored += 1
	var em := MeshInstance3D.new()
	em.name = "MuzzleEmber"
	var ems := SphereMesh.new()
	ems.radius = 0.11
	ems.height = 0.22
	ems.radial_segments = 10
	ems.rings = 5
	em.mesh = ems
	em.material_override = M["fire_flame"]
	em.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	em.set_meta(&"keep_separate", true)
	em.set_meta(&"own_glow", true)
	mk.add_child(em)
	em.owner = _root
	em.transform = xf(Vector3(0, CL.BORE_Y, CL.MOUTH_S), Vector3.ZERO, Vector3(1.0, 1.0, 0.95))
	_authored += 1
	var rod := MeshInstance3D.new()
	rod.name = "Ramrod"
	rod.mesh = _ramrod_mesh()
	rod.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rod.set_meta(&"keep_separate", true)
	rod.visible = false
	mk.add_child(rod)
	rod.owner = _root
	rod.position = Vector3(0, CL.BORE_Y, CL.MUZZLE_S + CL.ROD_LOW + CL.ROD_KNOB - CL.ROD_LEN)
	_authored += 1
	burn_fx(p, 0.8, 0.25)
	return _finish({"body_height": 1.7, "attack_style": &"musket_volley", "attack_windup": 0.15,
		"fire_kind": &"musketeer", "death_style": &"fall", "stride_time": 0.55, "is_quadruped": false,
		"stride_speed": 4.6, "idle_period": 3.1, "walk_bounce": 0.045, "leg_swing_deg": 26.0})
