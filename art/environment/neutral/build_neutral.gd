extends SceneTree
## Task A2.7: generates the neutral props' art (Ruin Peddler stall, Lost Cache) the same way as
## art/environment/build_env.gd (vertex-coloured, flat-shaded meshes on the shared env_painted material, one mesh per
## moving part), and packs the scenes at the paths the gameplay scripts load:
##   res://art/environment/ruin_peddler.tscn   (root script neutral/peddler_stall_art.gd)
##   res://art/environment/lost_cache.tscn     (root script neutral/lost_cache_model.gd)
## Meshes go to art/environment/neutral/meshes/. Re-run after changing a shape or colour:
##   $GODOT --headless --path . -s res://art/environment/neutral/build_neutral.gd --quit-after 600
## NOTE: build_env.gd still has its own (older) _build_cache / _build_peddler: running it would overwrite these two
## scenes with the old look. Drop those two calls from its _init (tech-artist / lead) before re-running it.

const ENV := "res://art/environment/"
const DIR := "res://art/environment/neutral/"
const MESH_DIR := "res://art/environment/neutral/meshes/"

# Palette: the tavern's (art/buildings/tavern/tavern_model.gd) + a few prop colours.
const STONE := Color(0.47, 0.45, 0.40)
const STONE_L := Color(0.56, 0.54, 0.48)
const DARK := Color(0.25, 0.24, 0.22)
const TIMBER := Color(0.31, 0.21, 0.13)
const WOOD := Color(0.52, 0.37, 0.22)
const WOOD_L := Color(0.62, 0.46, 0.28)
const PLASTER := Color(0.80, 0.72, 0.57)
const THATCH := Color(0.66, 0.52, 0.29)
const IRON := Color(0.21, 0.21, 0.23)
const GOLD := Color(0.92, 0.70, 0.27)
const BRONZE := Color(0.60, 0.43, 0.20)
const WOOD_OLD := Color(0.44, 0.30, 0.17)
const MOSS := Color(0.31, 0.41, 0.17)
const MOSS_TOP := Color(0.31, 0.43, 0.17, 0.75)
const SAFFRON := Color(0.82, 0.54, 0.16)
const SAFFRON_D := Color(0.62, 0.36, 0.10)
const CLAY := Color(0.68, 0.38, 0.22)
const CLAY_D := Color(0.46, 0.25, 0.15)
const RUG := Color(0.42, 0.22, 0.13)
const ROBE := Color(0.30, 0.38, 0.22)
const ROBE_D := Color(0.22, 0.28, 0.16)
const APRON := Color(0.82, 0.76, 0.62)
const BEARD := Color(0.90, 0.87, 0.80)
const SKIN := Color(0.86, 0.66, 0.50)
const BURLAP := Color(0.60, 0.50, 0.34)
const SCROLL := Color(0.88, 0.82, 0.66)
const NO_TOP := Color(0, 0, 0, 0)
# Glow colours (neutral_glow: vertex colour = glow colour): item tiers of items.md + treasure.
const G_GREEN := Color(0.40, 0.90, 0.40)
const G_BLUE := Color(0.30, 0.75, 1.00)
const G_ORANGE := Color(1.00, 0.60, 0.20)
const G_GOLD := Color(1.00, 0.80, 0.35)
const G_AMBER := Color(1.00, 0.72, 0.25)
const G_CRYSTAL := Color(0.55, 0.85, 1.00)

var env_mat: ShaderMaterial
var lantern_mat: ShaderMaterial
var glow_mat: ShaderMaterial

var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _conv: float = 1.0


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	_detect_winding()
	env_mat = load(ENV + "env_painted_mat.tres") as ShaderMaterial
	lantern_mat = load(ENV + "lantern_glow_mat.tres") as ShaderMaterial
	glow_mat = ShaderMaterial.new()
	glow_mat.shader = load(DIR + "neutral_glow.gdshader") as Shader
	_save(glow_mat, DIR + "neutral_glow_mat.tres")
	_build_peddler()
	_build_cache()
	print("NEUTRAL BUILD OK")
	quit()


# --- mesh building (same recipe as build_env.gd) ---------------------------------------------------

func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])


func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


func _h3(p: Vector3) -> Vector3:
	return Vector3(_h(p), _h(p + Vector3(5.2, 1.3, 7.1)), _h(p + Vector3(2.7, 9.1, 3.3))) * 2.0 - Vector3.ONE


func _xf(pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot_deg * PI / 180.0) * Basis.from_scale(s), pos)


func _detect_winding() -> void:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var fn: Vector3 = (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]])
	_conv = 1.0 if fn.dot(n[idx[0]]) >= 0.0 else -1.0


func _begin() -> void:
	_v = PackedVector3Array()
	_n = PackedVector3Array()
	_c = PackedColorArray()


func _mk(verts: PackedVector3Array, norms: PackedVector3Array, idx: PackedInt32Array) -> Array:
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = idx
	return arr


## Adds a primitive, transformed, flat-shaded, with a colour block, jitter (m) and an optional tint on faces turned
## to the sky (moss; alpha = strength).
func _prim(m: PrimitiveMesh, xf: Transform3D, col: Color, jitter: float = 0.0, top: Color = NO_TOP,
		seed: float = 0.0) -> void:
	_arr(m.get_mesh_arrays(), xf, col, jitter, top, seed)


func _arr(arr: Array, xf: Transform3D, col: Color, jitter: float = 0.0, top: Color = NO_TOP, seed: float = 0.0) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var nb: Basis = xf.basis.inverse().transposed()
	var tv := PackedVector3Array()
	tv.resize(v.size())
	for i: int in v.size():
		var p: Vector3 = xf * v[i]
		if jitter > 0.0:
			p += _h3(v[i].snappedf(0.001) + Vector3(seed, seed * 0.7, seed * 1.3)) * jitter
		tv[i] = p
	for t: int in range(0, idx.size(), 3):
		var a: int = idx[t]
		var b: int = idx[t + 1]
		var c: int = idx[t + 2]
		var fn: Vector3 = (tv[b] - tv[a]).cross(tv[c] - tv[a])
		if fn.length_squared() < 1e-12:
			continue
		fn = fn.normalized()
		var on: Vector3 = nb * (n[a] + n[b] + n[c])
		var s: float = 1.0 if fn.dot(on) >= 0.0 else -1.0
		if s != _conv:
			var tmp: int = b
			b = c
			c = tmp
		fn *= s
		var centre: Vector3 = (tv[a] + tv[b] + tv[c]) / 3.0
		var fc: Color = col
		if top.a > 0.0 and fn.y > 0.6 and _h(centre.snappedf(0.01) + Vector3(3, 3, 3)) > 0.25:
			fc = col.lerp(Color(top.r, top.g, top.b), top.a * smoothstep(0.6, 0.9, fn.y))
		var k: float = 1.0 + (_h(centre.snappedf(0.01)) - 0.5) * 0.10
		fc = Color(fc.r * k, fc.g * k, fc.b * k)
		for vi: int in [a, b, c]:
			_v.append(tv[vi])
			_n.append(fn)
			_c.append(fc)


## Commits the current buffers. `y_base` = model-space height of the node the mesh hangs on (env_painted darkens
## UV.y near 0 as ground contact, and grades COLOR.a over [grad_lo, grad_hi] model metres; lo >= hi = per mesh).
func _commit(name: String, mat: Material, y_base: float = 0.0, grad_lo: float = 0.0, grad_hi: float = -1.0) -> ArrayMesh:
	var miny: float = INF
	var maxy: float = -INF
	for p: Vector3 in _v:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var lo: float = grad_lo
	var hi: float = grad_hi
	if hi <= lo:
		lo = miny + y_base
		hi = maxy + y_base
	var span: float = maxf(hi - lo, 0.01)
	var uv := PackedVector2Array()
	uv.resize(_v.size())
	for i: int in _v.size():
		var cc: Color = _c[i]
		cc.a = clampf((_v[i].y + y_base - lo) / span, 0.0, 1.0)
		_c[i] = cc
		uv[i] = Vector2(0.0, _v[i].y + y_base)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _v
	arrays[Mesh.ARRAY_NORMAL] = _n
	arrays[Mesh.ARRAY_COLOR] = _c
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, mat)
	_save(mesh, MESH_DIR + name + ".res")
	print("mesh %s: %d tris, y %.2f..%.2f" % [name, _v.size() / 3, miny, maxy])
	return mesh


func _cyl(top: float, bottom: float, h: float, segs: int = 8, rings: int = 0) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = segs
	m.rings = rings
	return m


func _sph(r: float, segs: int = 8, rings: int = 4) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segs
	m.rings = rings
	return m


func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


func _prism(size: Vector3) -> PrismMesh:
	var m := PrismMesh.new()
	m.size = size
	return m


func _torus(inner: float, outer: float, rings: int = 12, segs: int = 6) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = rings
	m.ring_segments = segs
	return m


## Half cylinder (a domed lid / arched strap): axis along X, length `len`, radius r, flattened by `sy`; the flat
## side at y 0 spans z -r..r, the arc goes from the front (+z) over the top to the back.
func _half_cyl(r: float, len: float, segs: int, sy: float, caps: bool = true) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	for i: int in segs + 1:
		var a: float = PI * float(i) / float(segs)
		var d := Vector3(0, sin(a) * sy, cos(a))
		for x: float in [-len * 0.5, len * 0.5]:
			v.append(Vector3(x, d.y * r, d.z * r))
			n.append(Vector3(0, sin(a), cos(a)))
	for i: int in segs:
		var k: int = i * 2
		idx.append_array([k, k + 1, k + 2, k + 1, k + 3, k + 2])
	if caps:
		for side: int in 2:
			var x: float = -len * 0.5 if side == 0 else len * 0.5
			var nx := Vector3(-1 if side == 0 else 1, 0, 0)
			var base: int = v.size()
			v.append(Vector3(x, 0, 0))
			n.append(nx)
			for i: int in segs + 1:
				var a: float = PI * float(i) / float(segs)
				v.append(Vector3(x, sin(a) * sy * r, cos(a) * r))
				n.append(nx)
			for i: int in segs:
				idx.append_array([base, base + 1 + i, base + 2 + i])
	return _mk(v, n, idx)


## A column whose top is broken off: the top ring vertices drop by a seeded amount (0..`bite` m).
func _broken_cyl(r_top: float, r_bot: float, h: float, segs: int, bite: float, seed: float) -> Array:
	var arr: Array = _cyl(r_top, r_bot, h, segs, 1).get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for i: int in v.size():
		if v[i].y > h * 0.5 - 0.001:
			var a: float = atan2(v[i].z, v[i].x)
			var cut: float = bite * (0.5 + 0.5 * sin(a * 2.0 + seed)) * (0.6 + 0.4 * _h(Vector3(snappedf(a, 0.01), seed, 1)))
			if Vector2(v[i].x, v[i].z).length() < 0.001:
				cut = bite * 0.6
			v[i].y -= cut
	arr[Mesh.ARRAY_VERTEX] = v
	return arr


# --- scenes ------------------------------------------------------------------------------------------

func _own(n: Node, root: Node) -> void:
	for ch: Node in n.get_children():
		ch.owner = root
		_own(ch, root)


func _pack(path: String, root: Node3D) -> void:
	_own(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	_save(ps, path)
	root.free()


func _mi(parent: Node3D, mesh: Mesh, name: String, pos: Vector3 = Vector3.ZERO, shadow: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.position = pos
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _node(parent: Node3D, name: String, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = name
	n.position = pos
	n.rotation_degrees = rot_deg
	parent.add_child(n)
	return n


## Soft dark contact decal (art-keep.md 0.5): unshaded radial gradient quad, no depth write, no shadow.
func _decal(parent: Node3D, size: Vector2, pos: Vector3, alpha: float) -> MeshInstance3D:
	var pm := PlaneMesh.new()
	pm.size = size
	var g := Gradient.new()
	g.set_color(0, Color(0.05, 0.035, 0.02, alpha))
	g.set_color(1, Color(0.05, 0.035, 0.02, 0.0))
	g.add_point(0.55, Color(0.05, 0.035, 0.02, alpha * 0.6))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 64
	gt.height = 64
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.albedo_texture = gt
	pm.material = m
	var mi := _mi(parent, pm, "ContactShadow", pos, false)
	return mi


func _mask_tex() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(0, 0, 0, 0))
	g.add_point(0.25, Color(1, 1, 1, 0.9))
	g.add_point(0.6, Color(0.45, 0.45, 0.45, 0.35))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 32
	gt.height = 32
	return gt


## Billboard particle quad: ADD (glints) or MIX (dust), round mask, keep_scale, colour from the particle colour.
func _quad(size: float, add: bool, tint: Color = Color.WHITE) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if add else BaseMaterial3D.BLEND_MODE_MIX
	sm.disable_fog = add  # G-E 5: an additive quad must not fog
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sm.billboard_keep_scale = true
	sm.vertex_color_use_as_albedo = true
	sm.albedo_color = tint
	sm.albedo_texture = _mask_tex()
	sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q.material = sm
	return q


func _curve(points: Array) -> CurveTexture:
	var cv := Curve.new()
	for p: Vector2 in points:
		cv.add_point(p)
	var ct := CurveTexture.new()
	ct.curve = cv
	return ct


func _ramp(c: Color, mid: float = 0.6) -> GradientTexture1D:
	var g := Gradient.new()
	g.set_color(0, c)
	g.set_color(1, Color(c.r, c.g, c.b, 0.0))
	g.add_point(mid, Color(c.r, c.g, c.b, c.a * 0.8))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	return gt


func _particles(parent: Node3D, name: String, pos: Vector3, amount: int, life: float, one_shot: bool,
		ppm: ParticleProcessMaterial, draw: Mesh) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = name
	p.position = pos
	p.amount = amount
	p.lifetime = life
	p.one_shot = one_shot
	p.emitting = not one_shot
	p.explosiveness = 0.9 if one_shot else 0.0
	p.randomness = 0.4
	p.fixed_fps = 30
	p.interpolate = true
	p.local_coords = true
	p.process_material = ppm
	p.draw_pass_1 = draw
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-2.5, -1, -2.5), Vector3(5, 5, 5))
	parent.add_child(p)
	return p


# --- Ruin Peddler stall --------------------------------------------------------------------------------

## Striped awning: 7 stripes from the back beam (y 2.44, z -0.80) to the front (y 2.06, z 0.80), each in two
## panels with a slight sag, + a scalloped valance at the front and short ones on the sides.
func _awning() -> void:
	var x0: float = -0.80
	var w: float = 2.70 / 7.0
	var back := Vector3(0, 2.46, -0.82)
	var mid := Vector3(0, 2.20, 0.0)
	var front := Vector3(0, 2.06, 0.82)
	for i: int in 7:
		var x: float = x0 + w * (i + 0.5)
		var col: Color = SAFFRON if i % 2 == 0 else PLASTER
		for seg: int in 2:
			var a: Vector3 = back if seg == 0 else mid
			var b: Vector3 = mid if seg == 0 else front
			var d: Vector3 = b - a
			var ang: float = rad_to_deg(atan2(-d.y, d.z))
			var c: Vector3 = (a + b) * 0.5 + Vector3(x, 0, 0)
			_prim(_box(Vector3(w + 0.004, 0.045, d.length() + 0.02)), _xf(c, Vector3(ang, 0, 0)), col, 0.004, NO_TOP, i)
		# front scallop (the opposite colour), hanging from the front edge
		_prim(_prism(Vector3(w, 0.24, 0.035)), _xf(front + Vector3(x, -0.12, 0.0), Vector3(0, 0, 180)),
			PLASTER if i % 2 == 0 else SAFFRON)
	# Side valances: 4 short flaps along each side edge (from back to front).
	for side: int in [-1, 1]:
		var xs: float = 0.55 + side * 1.35
		for j: int in 4:
			var u: float = (j + 0.5) / 4.0
			var p: Vector3 = back.lerp(front, u) if u > 0.0 else back
			p.y = lerpf(2.46, 2.06, u) - 0.02 - 0.05 * sin(u * PI)
			_prim(_prism(Vector3(0.40, 0.20, 0.035)), _xf(Vector3(xs, p.y - 0.10, p.z), Vector3(0, 90, 180)),
				SAFFRON_D if j % 2 == 0 else PLASTER)
	# Ridge trim along the back, timber.
	_prim(_box(Vector3(2.80, 0.08, 0.10)), _xf(Vector3(0.55, 2.49, -0.84)), TIMBER)


func _bottle(pos: Vector3, h: float) -> void:
	# neck + cork in the painted mesh; the glowing body is added by _bottle_glow
	_prim(_cyl(0.035, 0.04, 0.10, 6), _xf(pos + Vector3(0, h + 0.05, 0)), Color(0.62, 0.70, 0.66))
	_prim(_cyl(0.045, 0.04, 0.05, 6), _xf(pos + Vector3(0, h + 0.12, 0)), WOOD_L)


func _barrel(pos: Vector3, seed: float) -> void:
	_prim(_cyl(0.22, 0.19, 0.20, 10), _xf(pos + Vector3(0, 0.10, 0)), WOOD, 0.006, NO_TOP, seed)
	_prim(_cyl(0.22, 0.22, 0.18, 10), _xf(pos + Vector3(0, 0.29, 0)), WOOD, 0.006, NO_TOP, seed + 1)
	_prim(_cyl(0.19, 0.22, 0.20, 10), _xf(pos + Vector3(0, 0.48, 0)), WOOD_L, 0.006, NO_TOP, seed + 2)
	for y: float in [0.12, 0.46]:
		_prim(_cyl(0.228, 0.228, 0.05, 10), _xf(pos + Vector3(0, y, 0)), IRON)
	_prim(_cyl(0.18, 0.18, 0.03, 10), _xf(pos + Vector3(0, 0.585, 0)), TIMBER)


func _sack(pos: Vector3, s: float, rot: float, seed: float) -> void:
	_prim(_sph(0.24 * s, 7, 4), _xf(pos + Vector3(0, 0.20 * s, 0), Vector3(0, rot, 0), Vector3(1.0, 0.95, 0.85)),
		BURLAP, 0.03 * s, NO_TOP, seed)
	_prim(_cyl(0.05 * s, 0.10 * s, 0.14 * s, 6), _xf(pos + Vector3(0, 0.46 * s, 0)), BURLAP.darkened(0.1), 0.01, NO_TOP, seed)
	_prim(_cyl(0.07 * s, 0.07 * s, 0.04, 6), _xf(pos + Vector3(0, 0.41 * s, 0)), TIMBER)


func _rock(pos: Vector3, r: float, seed: float) -> void:
	_prim(_sph(r, 6, 3), _xf(pos, Vector3(0, seed * 40.0, 0), Vector3(1.2, 0.7, 1.0)), STONE, r * 0.25, MOSS_TOP, seed)


func _build_peddler() -> void:
	# ---- Static stall mesh (y graded over the whole stall height).
	_begin()
	# Ruin base: two old stone blocks as the counter's legs, moss on top.
	_prim(_box(Vector3(0.42, 0.86, 0.74)), _xf(Vector3(-0.28, 0.43, 0.04), Vector3(0, 4, 1)), STONE, 0.03, MOSS_TOP, 1.0)
	_prim(_box(Vector3(0.42, 0.86, 0.74)), _xf(Vector3(1.38, 0.43, 0.04), Vector3(0, -5, -1)), STONE, 0.03, MOSS_TOP, 2.0)
	_prim(_box(Vector3(0.20, 0.16, 0.20)), _xf(Vector3(-0.44, 0.08, 0.46), Vector3(0, 30, 8)), STONE_L, 0.02, MOSS_TOP, 3.0)
	# Counter: plank top, front boards, a dark rail; saffron valance with scallops on the front.
	_prim(_box(Vector3(2.24, 0.12, 0.92)), _xf(Vector3(0.55, 0.92, 0.05)), WOOD, 0.008, NO_TOP, 4.0)
	_prim(_box(Vector3(2.28, 0.06, 0.96)), _xf(Vector3(0.55, 0.85, 0.05)), TIMBER)
	_prim(_box(Vector3(1.24, 0.70, 0.06)), _xf(Vector3(0.55, 0.48, 0.40)), TIMBER, 0.005, NO_TOP, 5.0)
	for k: int in 4:
		_prim(_box(Vector3(0.04, 0.70, 0.03)), _xf(Vector3(0.05 + k * 0.33, 0.48, 0.44)), DARK)
	_prim(_box(Vector3(2.10, 0.20, 0.03)), _xf(Vector3(0.55, 0.76, 0.51)), SAFFRON)
	for k: int in 6:
		_prim(_prism(Vector3(0.35, 0.16, 0.03)), _xf(Vector3(-0.325 + k * 0.35, 0.58, 0.51), Vector3(0, 0, 180)),
			SAFFRON if k % 2 == 1 else SAFFRON_D)
	# Posts and beams (front 2.02, back 2.40: the awning slopes toward the counter side).
	for p: Vector3 in [Vector3(-0.66, 0, 0.70), Vector3(1.76, 0, 0.70)]:
		_prim(_cyl(0.055, 0.065, 2.04, 6), _xf(p + Vector3(0, 1.02, 0)), TIMBER, 0.01, NO_TOP, p.x)
	for p: Vector3 in [Vector3(-0.66, 0, -0.66), Vector3(1.76, 0, -0.66)]:
		_prim(_cyl(0.055, 0.065, 2.44, 6), _xf(p + Vector3(0, 1.22, 0)), TIMBER, 0.01, NO_TOP, p.x + 7.0)
	_prim(_box(Vector3(2.64, 0.10, 0.10)), _xf(Vector3(0.55, 2.02, 0.70)), TIMBER)
	_prim(_box(Vector3(2.64, 0.10, 0.10)), _xf(Vector3(0.55, 2.40, -0.66)), TIMBER)
	for x: float in [-0.66, 1.76]:
		_prim(_box(Vector3(0.08, 0.08, 1.42)), _xf(Vector3(x, 2.12, 0.02), Vector3(15, 0, 0)), TIMBER)
	_awning()
	# Goods on the counter: potion stand (the glowing bodies are in the glow mesh), jars, a crate of scrolls, a rug roll,
	# a small brass scale.
	_prim(_box(Vector3(0.78, 0.05, 0.26)), _xf(Vector3(0.36, 0.99, 0.28)), TIMBER)
	for b: Array in [[Vector3(0.10, 1.01, 0.28), 0.17], [Vector3(0.36, 1.01, 0.30), 0.20], [Vector3(0.62, 1.01, 0.27), 0.16]]:
		_bottle(b[0], b[1])
	_prim(_cyl(0.13, 0.16, 0.30, 8), _xf(Vector3(1.02, 1.13, 0.18)), CLAY, 0.01, NO_TOP, 6.0)
	_prim(_cyl(0.08, 0.13, 0.08, 8), _xf(Vector3(1.02, 1.31, 0.18)), CLAY_D)
	_prim(_sph(0.13, 8, 4), _xf(Vector3(1.28, 1.10, 0.02), Vector3.ZERO, Vector3(1, 1.1, 1)), CLAY_D, 0.01, NO_TOP, 7.0)
	_prim(_cyl(0.06, 0.09, 0.08, 8), _xf(Vector3(1.28, 1.26, 0.02)), CLAY)
	_prim(_box(Vector3(0.42, 0.24, 0.34)), _xf(Vector3(-0.08, 1.10, -0.12), Vector3(0, 12, 0)), WOOD_L, 0.01, NO_TOP, 8.0)
	for s: int in 5:
		var a: float = s * 1.3
		_prim(_cyl(0.045, 0.045, 0.40, 6), _xf(Vector3(-0.08 + cos(a) * 0.09, 1.30, -0.12 + sin(a) * 0.07),
			Vector3(12.0 * cos(a * 2.0), 0, 14.0 * sin(a * 1.7))), SCROLL)
	_prim(_cyl(0.12, 0.12, 1.10, 8), _xf(Vector3(0.62, 1.10, -0.28), Vector3(0, 8, 90)), SAFFRON_D, 0.005, NO_TOP, 9.0)
	_prim(_cyl(0.125, 0.125, 0.10, 8), _xf(Vector3(0.62, 1.10, -0.28), Vector3(0, 8, 90)), PLASTER)
	# Herb bundles and a hanging pot under the front beam.
	for hx: float in [0.02, 0.86]:
		_prim(_cyl(0.012, 0.012, 0.18, 4), _xf(Vector3(hx, 1.90, 0.70)), IRON)
		_prim(_cyl(0.10, 0.02, 0.34, 6), _xf(Vector3(hx, 1.66, 0.70), Vector3(0, hx * 50.0, 0)), MOSS, 0.02, NO_TOP, hx)
		_prim(_cyl(0.05, 0.05, 0.06, 6), _xf(Vector3(hx, 1.82, 0.70)), SAFFRON_D)
	_prim(_cyl(0.012, 0.012, 0.22, 4), _xf(Vector3(1.30, 1.88, 0.70)), IRON)
	_prim(_sph(0.12, 8, 4), _xf(Vector3(1.30, 1.70, 0.70)), CLAY, 0.01, NO_TOP, 10.0)
	# Rug of wares in front: border + field + saffron diamonds; a bronze Warden Scale, a Vital Root, pots, a chest.
	_prim(_box(Vector3(1.70, 0.02, 0.74)), _xf(Vector3(0.60, 0.012, 1.02), Vector3(0, -3, 0)), RUG)
	_prim(_box(Vector3(1.50, 0.022, 0.56)), _xf(Vector3(0.60, 0.014, 1.02), Vector3(0, -3, 0)), PLASTER.darkened(0.1))
	for d: int in 3:
		_prim(_box(Vector3(0.26, 0.024, 0.26)), _xf(Vector3(0.12 + d * 0.48, 0.016, 1.02 - d * 0.025), Vector3(0, 42, 0)), SAFFRON)
	_prim(_cyl(0.24, 0.24, 0.05, 12), _xf(Vector3(1.22, 0.30, 0.56), Vector3(-72, 0, 0)), BRONZE, 0.004)
	_prim(_cyl(0.10, 0.10, 0.07, 10), _xf(Vector3(1.22, 0.32, 0.585), Vector3(-72, 0, 0)), GOLD)
	for r: int in 4:
		var ra: float = r * 1.7
		_prim(_cyl(0.025, 0.06, 0.46, 5), _xf(Vector3(0.38 + cos(ra) * 0.06, 0.06, 1.14 + sin(ra) * 0.05),
			Vector3(84, ra * 30.0, 0)), Color(0.46, 0.30, 0.18), 0.02, NO_TOP, 11.0 + r)
	_prim(_sph(0.08, 6, 3), _xf(Vector3(0.20, 0.08, 1.12)), MOSS)
	_prim(_cyl(0.10, 0.14, 0.24, 8), _xf(Vector3(0.90, 0.13, 1.18)), CLAY, 0.01, NO_TOP, 12.0)
	_prim(_sph(0.10, 8, 4), _xf(Vector3(0.00, 0.10, 0.86)), CLAY_D, 0.01, NO_TOP, 13.0)
	_prim(_box(Vector3(0.34, 0.20, 0.24)), _xf(Vector3(1.18, 0.11, 1.20), Vector3(0, -14, 0)), TIMBER)
	_prim(_box(Vector3(0.36, 0.06, 0.26)), _xf(Vector3(1.18, 0.23, 1.20), Vector3(0, -14, 0)), WOOD)
	_prim(_box(Vector3(0.06, 0.22, 0.27)), _xf(Vector3(1.18, 0.14, 1.20), Vector3(0, -14, 0)), GOLD.darkened(0.15))
	# Barrel and sacks on the right, a crate by the back post.
	_barrel(Vector3(1.86, 0, 0.16), 20.0)
	_sack(Vector3(1.88, 0, -0.34), 1.0, 20.0, 21.0)
	_sack(Vector3(1.60, 0, 0.62), 0.8, -35.0, 22.0)
	_prim(_box(Vector3(0.46, 0.40, 0.46)), _xf(Vector3(1.40, 0.20, -0.62), Vector3(0, 18, 0)), WOOD, 0.01, NO_TOP, 23.0)
	_prim(_box(Vector3(0.50, 0.05, 0.50)), _xf(Vector3(1.40, 0.41, -0.62), Vector3(0, 18, 0)), TIMBER)
	# Broken mossy column behind the peddler (the tall vertical accent) + its plinth, and a fallen drum.
	_prim(_box(Vector3(0.66, 0.16, 0.66)), _xf(Vector3(-1.06, 0.08, -0.60), Vector3(0, 10, 0)), STONE, 0.02, MOSS_TOP, 24.0)
	_arr(_broken_cyl(0.25, 0.28, 2.05, 10, 0.34, 3.0), _xf(Vector3(-1.06, 1.18, -0.60)), STONE_L, 0.012, MOSS_TOP, 25.0)
	_prim(_cyl(0.285, 0.285, 0.08, 10), _xf(Vector3(-1.06, 0.20, -0.60)), STONE)
	_prim(_sph(0.20, 6, 3), _xf(Vector3(-1.02, 2.06, -0.60), Vector3.ZERO, Vector3(1.2, 0.4, 1.2)), MOSS, 0.02)
	_prim(_cyl(0.24, 0.24, 0.40, 10), _xf(Vector3(-1.66, 0.24, -0.64), Vector3(90, 15, 0)), STONE_L, 0.012, MOSS_TOP, 26.0)
	# The peddler's travelling pack leaning on the column: frame, bags, bedroll, dangling pot and pan.
	var pk := Vector3(-0.98, 0, -0.22)
	_prim(_box(Vector3(0.56, 0.86, 0.32)), _xf(pk + Vector3(0, 0.52, 0), Vector3(-10, 8, 0)), WOOD_L, 0.02, NO_TOP, 27.0)
	for sx: float in [-0.30, 0.30]:
		_prim(_box(Vector3(0.06, 1.10, 0.06)), _xf(pk + Vector3(sx, 0.60, -0.14), Vector3(-10, 8, 0)), TIMBER)
	_prim(_cyl(0.15, 0.15, 0.70, 8), _xf(pk + Vector3(0.02, 1.08, -0.10), Vector3(-10, 8, 90)), SAFFRON, 0.005)
	_prim(_box(Vector3(0.40, 0.30, 0.14)), _xf(pk + Vector3(0, 0.40, 0.20), Vector3(-10, 8, 0)), BURLAP, 0.02, NO_TOP, 28.0)
	_prim(_sph(0.12, 7, 3), _xf(pk + Vector3(0.36, 0.52, 0.10)), IRON)
	_prim(_cyl(0.13, 0.13, 0.04, 10), _xf(pk + Vector3(-0.36, 0.62, 0.06), Vector3(0, 0, 80)), IRON)
	# Signpost with a gold coin and a green potion painted on the board (both faces).
	var sp := Vector3(-1.84, 0, 0.04)
	_prim(_cyl(0.05, 0.06, 1.94, 6), _xf(sp + Vector3(0, 0.97, 0)), TIMBER)
	_prim(_box(Vector3(0.18, 0.12, 0.18)), _xf(sp + Vector3(0, 0.06, 0), Vector3(0, 20, 0)), STONE, 0.02, MOSS_TOP, 29.5)
	_prim(_box(Vector3(0.52, 0.06, 0.06)), _xf(sp + Vector3(0.24, 1.86, 0)), TIMBER)
	_prim(_box(Vector3(0.54, 0.38, 0.06)), _xf(sp + Vector3(0.30, 1.52, 0), Vector3(0, 0, -3)), WOOD, 0.006, NO_TOP, 29.0)
	for zf: float in [0.036, -0.036]:
		_prim(_cyl(0.11, 0.11, 0.02, 12), _xf(sp + Vector3(0.20, 1.53, zf), Vector3(90, 0, 0)), GOLD)
		_prim(_sph(0.07, 6, 3), _xf(sp + Vector3(0.44, 1.49, zf), Vector3.ZERO, Vector3(1, 1, 0.3)), G_GREEN.darkened(0.2))
	for c: int in 2:
		_prim(_cyl(0.008, 0.008, 0.14, 4), _xf(sp + Vector3(0.10 + c * 0.40, 1.77, 0)), IRON)
	# Rubble and stones around (ground contact).
	_rock(Vector3(-1.62, 0.05, -0.30), 0.16, 30.0)
	_rock(Vector3(2.02, 0.05, -0.80), 0.18, 31.0)
	_rock(Vector3(-0.30, 0.04, 1.40), 0.12, 32.0)
	_rock(Vector3(1.98, 0.04, 0.95), 0.13, 33.0)
	var stall: ArrayMesh = _commit("peddler_stall", env_mat, 0.0, 0.0, 2.5)

	# ---- Glowing potions (neutral_glow: tier colours).
	_begin()
	_prim(_sph(0.085, 8, 4), _xf(Vector3(0.10, 1.10, 0.28), Vector3.ZERO, Vector3(1, 1.05, 1)), G_GREEN)
	_prim(_cyl(0.075, 0.09, 0.18, 8), _xf(Vector3(0.36, 1.10, 0.30)), G_BLUE)
	_prim(_sph(0.08, 8, 4), _xf(Vector3(0.62, 1.09, 0.27)), G_ORANGE)
	_prim(_sph(0.06, 6, 3), _xf(Vector3(1.30, 1.36, 0.02)), G_GREEN)       # a potion peeking out of the dark jar
	var potions: ArrayMesh = _commit("peddler_potions", glow_mat)

	# ---- Lanterns (pivot at the hook; cage in the painted mesh, the orb on the lantern glow).
	_begin()
	_prim(_cyl(0.012, 0.012, 0.14, 4), _xf(Vector3(0, -0.07, 0)), IRON)
	_prim(_cyl(0.05, 0.15, 0.10, 6), _xf(Vector3(0, -0.18, 0)), IRON)
	for k: int in 4:
		var a: float = k * PI * 0.5 + PI * 0.25
		_prim(_box(Vector3(0.03, 0.26, 0.03)), _xf(Vector3(cos(a) * 0.10, -0.36, sin(a) * 0.10)), IRON)
	_prim(_cyl(0.13, 0.10, 0.05, 6), _xf(Vector3(0, -0.51, 0)), IRON)
	var cage: ArrayMesh = _commit("peddler_lantern_cage", env_mat, 1.98, 0.0, 2.5)
	_begin()
	_prim(_sph(0.105, 8, 4), _xf(Vector3(0, -0.36, 0), Vector3.ZERO, Vector3(1, 1.15, 1)), Color.WHITE)
	var orb: ArrayMesh = _commit("peddler_lantern_orb", lantern_mat)

	# ---- The peddler (feet origin; faces +Z): body, head (hat, beard), two arms on shoulder pivots.
	_begin()
	for sx: float in [-0.12, 0.12]:
		_prim(_box(Vector3(0.15, 0.14, 0.26)), _xf(Vector3(sx, 0.07, 0.05)), TIMBER)
	_prim(_cyl(0.25, 0.40, 0.92, 9), _xf(Vector3(0, 0.56, 0)), ROBE, 0.01, NO_TOP, 40.0)
	_prim(_cyl(0.40, 0.41, 0.08, 9), _xf(Vector3(0, 0.12, 0)), ROBE_D)
	_prim(_sph(0.33, 9, 5), _xf(Vector3(0, 0.74, 0.05), Vector3.ZERO, Vector3(1.0, 0.92, 0.95)), ROBE)
	_prim(_sph(0.30, 9, 5), _xf(Vector3(0, 0.62, 0.20), Vector3.ZERO, Vector3(0.86, 1.10, 0.62)), APRON)
	_prim(_cyl(0.345, 0.345, 0.07, 10), _xf(Vector3(0, 0.88, 0.05)), TIMBER)
	_prim(_box(Vector3(0.11, 0.09, 0.05)), _xf(Vector3(0, 0.88, 0.39)), GOLD)
	_prim(_cyl(0.21, 0.30, 0.30, 9), _xf(Vector3(0, 1.08, 0.02)), ROBE)
	_prim(_torus(0.12, 0.25, 10, 6), _xf(Vector3(0, 1.24, 0.02)), SAFFRON, 0.01)
	_prim(_box(Vector3(0.12, 0.34, 0.05)), _xf(Vector3(0.12, 1.06, 0.27), Vector3(8, 0, -8)), SAFFRON)
	_prim(_sph(0.09, 6, 3), _xf(Vector3(-0.30, 0.80, 0.16)), WOOD, 0.01)                      # coin purse
	var body: ArrayMesh = _commit("peddler_body", env_mat, 0.0, 0.0, 1.9)
	_begin()   # head, local to the neck pivot at y 1.26
	var hy: float = 1.26
	_prim(_sph(0.19, 9, 5), _xf(Vector3(0, 1.42 - hy, 0.04)), SKIN)
	_prim(_sph(0.065, 6, 3), _xf(Vector3(0, 1.41 - hy, 0.23)), SKIN.darkened(0.08))
	_prim(_sph(0.19, 8, 4), _xf(Vector3(0, 1.29 - hy, 0.12), Vector3(-10, 0, 0), Vector3(1.05, 1.2, 0.72)), BEARD, 0.01)
	_prim(_sph(0.10, 6, 3), _xf(Vector3(0, 1.36 - hy, 0.20), Vector3.ZERO, Vector3(1.7, 0.55, 0.6)), BEARD)
	for ex: float in [-0.07, 0.07]:
		_prim(_box(Vector3(0.05, 0.035, 0.03)), _xf(Vector3(ex, 1.47 - hy, 0.205)), Color(0.12, 0.09, 0.07))
		_prim(_box(Vector3(0.08, 0.03, 0.04)), _xf(Vector3(ex, 1.515 - hy, 0.19), Vector3(0, 0, -ex * 150.0)), BEARD)
	_prim(_cyl(0.46, 0.44, 0.05, 12), _xf(Vector3(0, 1.57 - hy, 0.02), Vector3(-8, 0, 0)), THATCH, 0.015)
	_prim(_cyl(0.15, 0.20, 0.20, 9), _xf(Vector3(0, 1.68 - hy, 0.0), Vector3(-6, 0, 0)), THATCH, 0.01)
	_prim(_cyl(0.205, 0.205, 0.06, 9), _xf(Vector3(0, 1.62 - hy, 0.005), Vector3(-6, 0, 0)), SAFFRON)
	_prim(_box(Vector3(0.05, 0.30, 0.09)), _xf(Vector3(0.19, 1.74 - hy, -0.08), Vector3(-30, 0, -30)), MOSS)
	var head: ArrayMesh = _commit("peddler_head", env_mat, hy, 0.0, 1.9)
	_begin()   # right arm, local to the shoulder pivot (0.30, 1.16)
	_prim(_cyl(0.085, 0.11, 0.40, 7), _xf(Vector3(0.03, -0.19, 0.0), Vector3(0, 0, 8)), ROBE)
	_prim(_cyl(0.115, 0.115, 0.07, 7), _xf(Vector3(0.05, -0.38, 0.0)), ROBE_D)
	_prim(_sph(0.08, 6, 3), _xf(Vector3(0.06, -0.47, 0.02)), SKIN)
	var arm_r: ArrayMesh = _commit("peddler_arm_r", env_mat, 1.16, 0.0, 1.9)
	_begin()   # left arm: bent, the hand resting on the belly
	_prim(_cyl(0.085, 0.11, 0.30, 7), _xf(Vector3(-0.03, -0.14, 0.02), Vector3(0, 0, -10)), ROBE)
	_prim(_cyl(0.08, 0.10, 0.28, 7), _xf(Vector3(0.02, -0.33, 0.14), Vector3(70, 0, 30)), ROBE)
	_prim(_sph(0.08, 6, 3), _xf(Vector3(0.10, -0.38, 0.27)), SKIN)
	var arm_l: ArrayMesh = _commit("peddler_arm_l", env_mat, 1.16, 0.0, 1.9)

	# ---- Scene.
	var root := Node3D.new()
	root.name = "RuinPeddlerArt"
	root.set_script(load(DIR + "peddler_stall_art.gd"))
	_decal(root, Vector2(4.4, 3.2), Vector3(0.35, 0.025, 0.1), 0.55)
	_mi(root, stall, "Stall")
	_mi(root, potions, "Potions", Vector3.ZERO, false)
	for i: int in 2:
		var lp := _node(root, "LanternPivot" if i == 0 else "LanternPivot2",
			Vector3(-0.50, 1.98, 0.72) if i == 0 else Vector3(1.60, 1.98, 0.72))
		_mi(lp, cage, "Cage", Vector3.ZERO, false)
		_mi(lp, orb, "Orb", Vector3.ZERO, false)
	var ped := _node(root, "Peddler", Vector3(-1.10, 0, 0.74), Vector3(0, 12, 0))
	_mi(ped, body, "Body")
	var hp := _node(ped, "Head", Vector3(0, hy, 0.0))
	_mi(hp, head, "HeadMesh")
	var ar := _node(ped, "ArmR", Vector3(0.30, 1.16, 0.02), Vector3(0, 0, 6))
	_mi(ar, arm_r, "ArmRMesh")
	var al := _node(ped, "ArmL", Vector3(-0.30, 1.16, 0.02))
	_mi(al, arm_l, "ArmLMesh")
	_pack(ENV + "ruin_peddler.tscn", root)


# --- Lost Cache ----------------------------------------------------------------------------------------

func _build_cache() -> void:
	# ---- Ruin site (static): cracked mossy plinth, leaning broken tablet, fallen drum, stones, spilled coins, roots.
	_begin()
	_prim(_box(Vector3(1.30, 0.12, 0.94)), _xf(Vector3(0, 0.06, 0.0), Vector3(0, 3, 0)), STONE, 0.02, MOSS_TOP, 1.0)
	_prim(_box(Vector3(0.44, 0.10, 0.36)), _xf(Vector3(0.78, 0.04, 0.40), Vector3(4, 28, -6)), STONE_L, 0.02, MOSS_TOP, 2.0)
	# leaning broken tablet behind (clear of the opening lid): a slab and a jagged top piece
	_prim(_box(Vector3(0.90, 0.78, 0.18)), _xf(Vector3(0.05, 0.40, -0.88), Vector3(-16, 4, 0)), STONE_L, 0.025, MOSS_TOP, 3.0)
	_prim(_box(Vector3(0.50, 0.30, 0.18)), _xf(Vector3(-0.14, 0.86, -1.00), Vector3(-16, 4, 14)), STONE_L, 0.03, MOSS_TOP, 3.5)
	_prim(_box(Vector3(0.30, 0.05, 0.03)), _xf(Vector3(-0.08, 0.62, -0.845), Vector3(-16, 4, 20)), DARK)
	_prim(_box(Vector3(0.24, 0.05, 0.03)), _xf(Vector3(0.18, 0.50, -0.81), Vector3(-16, 4, -35)), DARK)
	_prim(_cyl(0.24, 0.24, 0.46, 10), _xf(Vector3(-0.86, 0.22, -0.12), Vector3(90, 70, 0)), STONE, 0.012, MOSS_TOP, 4.0)
	_rock(Vector3(0.82, 0.06, -0.46), 0.17, 5.0)
	_rock(Vector3(-0.70, 0.05, 0.52), 0.14, 6.0)
	_rock(Vector3(-0.30, 0.04, 0.66), 0.10, 7.0)
	for k: int in 6:
		var a: float = k * 2.1
		var p := Vector3(0.28 + cos(a) * 0.22, 0.02 + k * 0.004, 0.64 + sin(a) * 0.10)
		_prim(_cyl(0.075, 0.075, 0.022, 8), _xf(p, Vector3(k * 7.0 - 18.0, 0, k * 5.0)), GOLD)
	for r: int in 3:
		var ra: float = -0.4 + r * 0.45
		_prim(_cyl(0.03, 0.055, 0.62, 5), _xf(Vector3(-0.58 + r * 0.05, 0.16, -0.20 + r * 0.22),
			Vector3(78, ra * 60.0, 20), Vector3(1, 1, 1)), Color(0.40, 0.28, 0.16), 0.015, NO_TOP, 8.0 + r)
	_prim(_sph(0.14, 6, 3), _xf(Vector3(-0.56, 0.13, 0.34), Vector3.ZERO, Vector3(1.3, 0.5, 1.1)), MOSS, 0.02)
	var site: ArrayMesh = _commit("cache_site", env_mat, 0.0, 0.0, 1.0)

	# ---- Chest body (on the plinth: y 0.12 .. 0.54), bronze bands, corner caps, lock plate.
	_begin()
	var by: float = 0.33
	_prim(_box(Vector3(1.00, 0.42, 0.66)), _xf(Vector3(0, by, 0)), TIMBER, 0.006, NO_TOP, 11.0)
	for k: int in 5:
		_prim(_box(Vector3(1.01, 0.02, 0.67)), _xf(Vector3(0, 0.17 + k * 0.085, 0)), DARK)
	for x: float in [-0.30, 0.30]:
		_prim(_box(Vector3(0.10, 0.44, 0.70)), _xf(Vector3(x, by, 0)), BRONZE)
	_prim(_box(Vector3(1.05, 0.07, 0.71)), _xf(Vector3(0, 0.515, 0)), BRONZE)
	_prim(_box(Vector3(1.05, 0.06, 0.71)), _xf(Vector3(0, 0.15, 0)), BRONZE.darkened(0.15))
	for cx: float in [-0.48, 0.48]:
		for cz: float in [-0.31, 0.31]:
			_prim(_box(Vector3(0.12, 0.44, 0.12)), _xf(Vector3(cx, by, cz)), BRONZE.darkened(0.08))
	_prim(_box(Vector3(0.24, 0.24, 0.05)), _xf(Vector3(0, 0.40, 0.345)), GOLD)
	_prim(_torus(0.07, 0.10, 10, 4), _xf(Vector3(0, 0.40, 0.37), Vector3(90, 0, 0)), BRONZE.darkened(0.2))
	# the treasure well inside (dark), seen when the lid is open
	_prim(_box(Vector3(0.88, 0.02, 0.54)), _xf(Vector3(0, 0.545, 0)), Color(0.10, 0.07, 0.05))
	var body: ArrayMesh = _commit("cache_body", env_mat, 0.0, 0.0, 1.0)

	# ---- Lid (pivot at the back top edge (0, 0.55, -0.33)): domed timber, bronze straps and rim, the hasp in front.
	_begin()
	_arr(_half_cyl(0.33, 1.00, 8, 0.72), _xf(Vector3(0, 0, 0.33)), WOOD_OLD, 0.004, NO_TOP, 12.0)
	for x: float in [-0.30, 0.30]:
		_arr(_half_cyl(0.345, 0.10, 8, 0.74, false), _xf(Vector3(x, 0, 0.33)), BRONZE)
	for x2: float in [-0.49, 0.49]:
		_arr(_half_cyl(0.34, 0.05, 8, 0.73), _xf(Vector3(x2, 0, 0.33)), BRONZE.darkened(0.1))
	_prim(_box(Vector3(1.04, 0.05, 0.70)), _xf(Vector3(0, 0.02, 0.33)), BRONZE.darkened(0.15))
	_prim(_box(Vector3(0.16, 0.18, 0.04)), _xf(Vector3(0, -0.05, 0.69)), GOLD)
	_prim(_sph(0.06, 6, 3), _xf(Vector3(0, 0.25, 0.33), Vector3.ZERO, Vector3(1.4, 0.6, 1.4)), GOLD)   # a knob on top
	var lid: ArrayMesh = _commit("cache_lid", env_mat, 0.55, 0.0, 1.0)

	# ---- Glow meshes: seal gem, treasure heap (coins, gems) inside.
	_begin()
	_prim(_sph(0.07, 6, 3), _xf(Vector3(0, 0.40, 0.38), Vector3.ZERO, Vector3(1, 1.2, 0.7)), G_AMBER)
	var gem: ArrayMesh = _commit("cache_seal_gem", glow_mat)
	_begin()
	_prim(_sph(0.40, 10, 4), _xf(Vector3(0, 0.52, 0), Vector3.ZERO, Vector3(1.05, 0.34, 0.62)), G_GOLD, 0.02, NO_TOP, 13.0)
	for k: int in 7:
		var a: float = k * 0.9
		_prim(_cyl(0.07, 0.07, 0.02, 8), _xf(Vector3(cos(a) * 0.30, 0.62 + 0.02 * float(k % 3), sin(a) * 0.15),
			Vector3(20.0 * sin(a), 0, 25.0 * cos(a))), G_GOLD)
	_prim(_cyl(0.0, 0.07, 0.11, 4), _xf(Vector3(-0.18, 0.67, 0.04), Vector3(0, 0, 18)), G_CRYSTAL)
	_prim(_cyl(0.07, 0.0, 0.07, 4), _xf(Vector3(-0.18, 0.585, 0.04), Vector3(0, 0, 18)), G_CRYSTAL)
	_prim(_sph(0.07, 6, 3), _xf(Vector3(0.22, 0.65, -0.05)), G_ORANGE)
	var treasure: ArrayMesh = _commit("cache_treasure", glow_mat)

	# ---- Light shaft (additive, vertical fade), shown open.
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.62
	shaft_mesh.bottom_radius = 0.36
	shaft_mesh.height = 1.6
	shaft_mesh.radial_segments = 12
	shaft_mesh.rings = 1
	shaft_mesh.cap_top = false
	shaft_mesh.cap_bottom = false
	var sg := Gradient.new()
	sg.set_color(0, Color(1.0, 0.82, 0.40, 0.0))
	sg.set_color(1, Color(1.0, 0.82, 0.40, 0.55))
	var sgt := GradientTexture2D.new()
	sgt.gradient = sg
	sgt.fill_from = Vector2(0.5, 0.0)
	sgt.fill_to = Vector2(0.5, 1.0)
	sgt.width = 8
	sgt.height = 64
	var shaft_mat := StandardMaterial3D.new()
	shaft_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shaft_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shaft_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	shaft_mat.disable_fog = true  # G-E 5: an additive quad must not fog
	shaft_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shaft_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	shaft_mat.albedo_texture = sgt
	shaft_mat.texture_repeat = false
	shaft_mat.albedo_color = Color(1.6, 1.3, 0.8, 1.0)
	shaft_mesh.material = shaft_mat

	# ---- Particles: idle glints (loop), coin burst + glints (one-shot on open), appear dust puff.
	var glint_ppm := ParticleProcessMaterial.new()
	glint_ppm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	glint_ppm.emission_box_extents = Vector3(0.45, 0.04, 0.30)
	glint_ppm.direction = Vector3.UP
	glint_ppm.spread = 15.0
	glint_ppm.initial_velocity_min = 0.25
	glint_ppm.initial_velocity_max = 0.55
	glint_ppm.gravity = Vector3.ZERO
	glint_ppm.scale_curve = _curve([Vector2(0, 0.0), Vector2(0.2, 1.0), Vector2(1, 0.0)])
	glint_ppm.color = Color(1.0, 0.85, 0.45)
	var coin_ppm := ParticleProcessMaterial.new()
	coin_ppm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	coin_ppm.emission_box_extents = Vector3(0.30, 0.05, 0.18)
	coin_ppm.direction = Vector3(0, 1, 0.25)
	coin_ppm.spread = 38.0
	coin_ppm.initial_velocity_min = 2.6
	coin_ppm.initial_velocity_max = 4.2
	coin_ppm.gravity = Vector3(0, -9.8, 0)
	coin_ppm.angular_velocity_min = -720.0
	coin_ppm.angular_velocity_max = 720.0
	coin_ppm.angle_min = -180.0
	coin_ppm.angle_max = 180.0
	coin_ppm.scale_min = 0.8
	coin_ppm.scale_max = 1.2
	var coin_draw := CylinderMesh.new()
	coin_draw.top_radius = 0.065
	coin_draw.bottom_radius = 0.065
	coin_draw.height = 0.02
	coin_draw.radial_segments = 8
	coin_draw.rings = 0
	var coin_mat := StandardMaterial3D.new()
	coin_mat.albedo_color = Color(0.95, 0.72, 0.25)
	coin_mat.metallic = 0.8
	coin_mat.roughness = 0.3
	coin_mat.emission_enabled = true
	coin_mat.emission = Color(1.0, 0.75, 0.3)
	coin_mat.emission_energy_multiplier = 1.2
	coin_draw.material = coin_mat
	var burst_ppm := ParticleProcessMaterial.new()
	burst_ppm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	burst_ppm.emission_sphere_radius = 0.25
	burst_ppm.direction = Vector3.UP
	burst_ppm.spread = 60.0
	burst_ppm.initial_velocity_min = 1.0
	burst_ppm.initial_velocity_max = 2.6
	burst_ppm.damping_min = 1.5
	burst_ppm.damping_max = 2.5
	burst_ppm.gravity = Vector3(0, 0.3, 0)
	burst_ppm.scale_curve = _curve([Vector2(0, 1.0), Vector2(1, 0.0)])
	burst_ppm.color = Color(1.0, 0.82, 0.40)
	var puff_ppm := ParticleProcessMaterial.new()
	puff_ppm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	puff_ppm.emission_ring_axis = Vector3.UP
	puff_ppm.emission_ring_radius = 0.55
	puff_ppm.emission_ring_inner_radius = 0.35
	puff_ppm.emission_ring_height = 0.05
	puff_ppm.direction = Vector3.UP
	puff_ppm.spread = 25.0
	puff_ppm.initial_velocity_min = 0.3
	puff_ppm.initial_velocity_max = 0.8
	puff_ppm.radial_velocity_min = 1.0
	puff_ppm.radial_velocity_max = 1.8
	puff_ppm.damping_min = 2.5
	puff_ppm.damping_max = 3.5
	puff_ppm.gravity = Vector3.ZERO
	puff_ppm.scale_curve = _curve([Vector2(0, 0.6), Vector2(1, 1.3)])
	puff_ppm.color_ramp = _ramp(Color(0.60, 0.56, 0.46, 0.7))

	# ---- Scene.
	var root := Node3D.new()
	root.name = "LostCacheArt"
	root.set_script(load(DIR + "lost_cache_model.gd"))
	_decal(root, Vector2(2.6, 2.2), Vector3(0, 0.022, 0), 0.55)
	_mi(root, site, "Site")
	var chest := _node(root, "Chest", Vector3.ZERO)
	_mi(chest, body, "Body")
	var gem_mi := _mi(chest, gem, "LockGem", Vector3.ZERO, false)
	gem_mi.visible = true
	var lp := _node(chest, "LidPivot", Vector3(0, 0.55, -0.33))
	_mi(lp, lid, "Lid")
	var inner := _mi(chest, treasure, "InnerGlow", Vector3.ZERO, false)
	inner.visible = false
	var shaft := _mi(chest, shaft_mesh, "Shaft", Vector3(0, 1.30, 0), false)
	shaft.visible = false
	_particles(chest, "Sparkles", Vector3(0, 0.62, 0.05), 6, 1.8, false, glint_ppm, _quad(0.16, true))
	_particles(chest, "Coins", Vector3(0, 0.60, 0.0), 14, 1.0, true, coin_ppm, coin_draw)
	_particles(chest, "Glints", Vector3(0, 0.70, 0.0), 14, 0.9, true, burst_ppm, _quad(0.18, true))
	_particles(root, "Puff", Vector3(0, 0.05, 0), 14, 0.9, true, puff_ppm, _quad(0.6, false))
	_pack(ENV + "lost_cache.tscn", root)
