extends SceneTree
## Task 12.V19: builds the Essence well capture-point model: its meshes, its shared materials and essence_well.tscn.
## Re-run after any change to the geometry, the colours or the material setup below (headless is fine):
##   $GODOT --headless --path . -s res://art/buildings/capture/essence_well/build_essence_well.gd --quit-after 300
## Writes (all in this folder):
##   essence_well_painted_mat.tres  essence_well_painted.gdshader (stone, timber, iron, rope, runes)
##   essence_well_essence_mat.tres  essence_well_essence.gdshader (pool, crystals, spill; unshaded)
##   essence_well_fx_mat.tres       essence_well_fx.gdshader (mist cards, ground glow, pulse ring; additive)
##   essence_well_mist_process.tres, essence_well_mist_quad.tres (the near-camera mist particles)
##   essence_well_body.res (surface 0 painted, surface 1 the shared nature contact shadow), essence_well_essence.res,
##   essence_well_fx.res, essence_well.tscn
## Space: root origin = the point's centre on the ground, front = +Z. Angles `t` go clockwise seen from above, starting at
## -Z (P(r, y, t) = (sin t * r, y, -cos t * r)); the rune ring's capture fill follows the same angle.

const DIR := "res://art/buildings/capture/essence_well/"
const NOISE_PATH := "res://art/shaders/paint_noise.tres"
const CONTACT_MAT_PATH := "res://art/environment/nature_props/nature_contact_mat.tres"
const SCRIPT_PATH := DIR + "essence_well.gd"

enum Kind { STONE = 0, WOOD = 1, IRON = 2, ROPE = 3, RUNE = 4, SHINGLE = 5 }

# Shaft and rim (metres).
const R_IN := 0.74          # shaft (inner face of the wall)
const R_WALL := 1.30        # outer face of the wall
const COPE_IN := 0.70
const COPE_OUT := 1.44
const FOOT_OUT := 1.56      # footing
const Y_FOOT := 0.16
const Y_WALL := 0.78
const Y_TOP := 0.96         # coping top
const POOL_Y := 0.64        # the brimming essence surface
const POOL_R := 0.75
const RUNE_R := 1.05        # glyph ring radius on the coping top
# Coping: N_COPE stones from angle 0 (-Z), so no stone crosses the 0 / 1 wrap of the rune angle. The broken front-right:
# the stone whose centre angle is in GAP is missing (it lies on the apron); CRACKED is pushed out and down.
const N_COPE := 10
const GAP_A0 := 1.95
const GAP_A1 := 2.45
const CRACKED := 6
# Winch.
const POST_Z := -0.22
const POST_X := 1.58
const LEFT_TOP := 3.1       # left post top (the right one split and sank to RIGHT_TOP, so the roof tilts)
const RIGHT_TOP := 2.84
const ROOF_PITCH := 36.0    # degrees
const ROOF_DEPTH := 0.64    # half the roof's length along the ridge (front-to-back)
const DRUM_R := Vector3(0.81, 1.12, -0.58)   # P(1.0, 1.12, 0.95): the fallen end resting on the back-right coping
const DRUM_R_RADIUS := 0.16

# Palette (sRGB): neutral stone and old timber, like the map's ruins; the only strong colours are the essence (violet)
# and the rune / ground glow (owner).
const C_STONE := Color(0.50, 0.48, 0.45)
const C_STONE_W := Color(0.54, 0.51, 0.46)
const C_STONE_B := Color(0.46, 0.46, 0.48)
const C_COPE := Color(0.53, 0.51, 0.47)
const C_DARK := Color(0.33, 0.31, 0.30)
const C_MORTAR := Color(0.18, 0.17, 0.17)
const C_FLAG := Color(0.52, 0.50, 0.46)
const C_TIMBER := Color(0.40, 0.31, 0.22)
const C_TIMBER_D := Color(0.30, 0.22, 0.15)
const C_SHINGLE := Color(0.36, 0.29, 0.24)
const C_IRON := Color(0.22, 0.22, 0.25)
const C_ROPE := Color(0.64, 0.54, 0.36)
const C_BUCKET := Color(0.50, 0.36, 0.22)
const C_GROOVE := Color(0.10, 0.08, 0.12)
const C_STAIN := Color(0.40, 0.24, 0.62)

var _conv: float = -1.0
var _rng := RandomNumberGenerator.new()
# Current mesh buffers.
var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _uv := PackedVector2Array()
var _uv2 := PackedVector2Array()
# Current part attributes.
var _col: Color = Color.WHITE
var _kind: int = 0
var _moss: float = 0.0
var _part0: int = 0
var _report: Array[String] = []


func _init() -> void:
	_detect_winding()
	var noise: Texture2D = load(NOISE_PATH) as Texture2D
	var painted: ShaderMaterial = _shader_mat("essence_well_painted", noise)
	var essence: ShaderMaterial = _shader_mat("essence_well_essence", noise)
	var fx: ShaderMaterial = _shader_mat("essence_well_fx", noise)
	var contact: Material = load(CONTACT_MAT_PATH) as Material
	var body: ArrayMesh = _save_ref(_build_body(painted, contact), DIR + "essence_well_body.res") as ArrayMesh
	var ess: ArrayMesh = _save_ref(_build_essence(essence), DIR + "essence_well_essence.res") as ArrayMesh
	var fxm: ArrayMesh = _save_ref(_build_fx(fx), DIR + "essence_well_fx.res") as ArrayMesh
	var process: ParticleProcessMaterial = _save_ref(_mist_process(), DIR + "essence_well_mist_process.tres") \
		as ParticleProcessMaterial
	var quad: QuadMesh = _save_ref(_mist_quad(), DIR + "essence_well_mist_quad.tres") as QuadMesh
	_build_scene(body, ess, fxm, process, quad)
	for line: String in _report:
		print(line)
	print("ESSENCE WELL BUILD OK")
	quit()


# --- Resources ------------------------------------------------------------------------------------

func _save_ref(res: Resource, path: String) -> Resource:
	var flags: int = ResourceSaver.FLAG_COMPRESS if path.ends_with(".res") else 0
	var err: int = ResourceSaver.save(res, path, flags)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)


func _shader_mat(nm: String, noise: Texture2D) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(DIR + nm + ".gdshader") as Shader
	m.set_shader_parameter(&"noise_tex", noise)
	return _save_ref(m, DIR + nm + "_mat.tres") as ShaderMaterial


func _soft_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.55))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t


func _mist_process() -> ParticleProcessMaterial:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = 0.55
	pm.emission_ring_inner_radius = 0.12
	pm.emission_ring_height = 0.04
	pm.direction = Vector3.UP
	pm.spread = 16.0
	pm.initial_velocity_min = 0.28
	pm.initial_velocity_max = 0.5
	pm.gravity = Vector3(0.0, 0.2, 0.12)   # drifts out from under the roof, toward the front
	pm.damping_min = 0.05
	pm.damping_max = 0.12
	pm.angle_min = 0.0
	pm.angle_max = 360.0
	pm.angular_velocity_min = -18.0
	pm.angular_velocity_max = 18.0
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 2.6
	pm.turbulence_noise_speed = Vector3(0.0, 0.25, 0.0)
	pm.turbulence_influence_min = 0.03
	pm.turbulence_influence_max = 0.08
	pm.scale_min = 0.75
	pm.scale_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.35))
	curve.add_point(Vector2(0.4, 1.0))
	curve.add_point(Vector2(1.0, 1.45))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	var g := Gradient.new()
	g.set_color(0, Color(0.85, 0.55, 1.0, 0.0))
	g.set_color(1, Color(0.45, 0.22, 0.85, 0.0))
	g.add_point(0.22, Color(0.82, 0.52, 1.0, 0.55))
	g.add_point(0.65, Color(0.62, 0.34, 0.98, 0.32))
	var ramp := GradientTexture1D.new()
	ramp.gradient = g
	pm.color_ramp = ramp
	return pm


func _mist_quad() -> QuadMesh:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	m.albedo_texture = _soft_texture()
	m.disable_receive_shadows = true
	var q := QuadMesh.new()
	q.size = Vector2(0.8, 0.8)
	q.material = m
	return q


# --- Mesh buffers ---------------------------------------------------------------------------------

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
	_uv = PackedVector2Array()
	_uv2 = PackedVector2Array()


## Starts a part: its colour, kind and moss; its height gradient is set by _end_part.
func _part(col: Color, kind: int, moss: float = 0.0) -> void:
	_col = col
	_kind = kind
	_moss = moss
	_part0 = _v.size()


## Height gradient (COLOR.a) of the vertices since _part: 0 at `lo` -> 1 at `hi` (default: the part's own range).
func _end_part(lo: float = NAN, hi: float = NAN) -> void:
	var mn: float = INF
	var mx: float = -INF
	for i: int in range(_part0, _v.size()):
		mn = minf(mn, _v[i].y)
		mx = maxf(mx, _v[i].y)
	if not is_nan(lo):
		mn = lo
	if not is_nan(hi):
		mx = hi
	var span: float = maxf(mx - mn, 0.35)
	for i: int in range(_part0, _v.size()):
		var cc: Color = _c[i]
		cc.a = clampf((_v[i].y - mn) / span, 0.0, 1.0)
		_c[i] = cc


func _vert(p: Vector3, n: Vector3, aux: float, col: Color) -> void:
	_v.append(p)
	_n.append(n.normalized())
	_c.append(Color(col.r, col.g, col.b, 1.0))
	_uv.append(Vector2(_moss, p.y))
	_uv2.append(Vector2(float(_kind), aux))


## A triangle with per-vertex normals, wound so its front faces the normals.
func _tri(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3,
		ea: float = 0.0, eb: float = 0.0, ec: float = 0.0, col: Color = Color(-1, 0, 0)) -> void:
	var cl: Color = _col if col.r < 0.0 else col
	var fn: Vector3 = (b - a).cross(c - a)
	if fn.dot(na + nb + nc) * _conv < 0.0:
		_vert(a, na, ea, cl)
		_vert(c, nc, ec, cl)
		_vert(b, nb, eb, cl)
	else:
		_vert(a, na, ea, cl)
		_vert(b, nb, eb, cl)
		_vert(c, nc, ec, cl)


func _quad(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, n0: Vector3, n1: Vector3, n2: Vector3, n3: Vector3,
		e: Vector4 = Vector4.ZERO, col: Color = Color(-1, 0, 0)) -> void:
	_tri(p0, p1, p2, n0, n1, n2, e.x, e.y, e.z, col)
	_tri(p0, p2, p3, n0, n2, n3, e.x, e.z, e.w, col)


func _fquad(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, n: Vector3, col: Color = Color(-1, 0, 0)) -> void:
	_quad(p0, p1, p2, p3, n, n, n, n, Vector4.ZERO, col)


## Appends a primitive mesh's triangles transformed by `xf` (positive scale only). `grain`: the wood streaks run along
## the primitive's local Y (posts, beams, planks are all built with their length on local Y).
func _prim(mesh: PrimitiveMesh, xf: Transform3D, grain: bool = false) -> void:
	var arr: Array = mesh.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var nb: Basis = xf.basis.inverse().transposed()
	for i: int in idx.size():
		var j: int = idx[i]
		var lp: Vector3 = verts[j]
		var aux: float = (lp.x + lp.z * 0.73) if grain else 0.0
		_vert(xf * lp, nb * norms[j], aux, _col)


func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


func _cyl(top_r: float, bot_r: float, h: float, segs: int) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top_r
	m.bottom_radius = bot_r
	m.height = h
	m.radial_segments = segs
	m.rings = 1
	m.cap_top = top_r > 0.0
	m.cap_bottom = bot_r > 0.0
	return m


func _sphere(r: float, segs: int, rings: int) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segs
	m.rings = rings
	return m


## Transform whose local +Y runs from `a` to `b` (for a primitive of height |b - a| centred on its origin).
func _span(a: Vector3, b: Vector3, roll: float = 0.0) -> Transform3D:
	var e: Vector3 = b - a
	var bs := Basis(Quaternion(Vector3.UP, e.normalized())) * Basis(Vector3.UP, roll)
	return Transform3D(bs, (a + b) * 0.5)


func _xf(pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	var b := Basis.from_euler(Vector3(deg_to_rad(rot_deg.x), deg_to_rad(rot_deg.y), deg_to_rad(rot_deg.z)))
	return Transform3D(b.scaled_local(s), pos)


func _jit(c: Color, amount: float = 0.06) -> Color:
	var k: float = 1.0 + _rng.randf_range(-amount, amount)
	return Color(c.r * k, c.g * k, c.b * k)


func _commit(material: Material, mesh: ArrayMesh = null) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in _v.size():
		st.set_color(_c[i])
		st.set_normal(_n[i])
		st.set_uv(_uv[i])
		st.set_uv2(_uv2[i])
		st.add_vertex(_v[i])
	st.index()
	st.set_material(material)
	var out: ArrayMesh = st.commit(mesh) if mesh else st.commit()
	return out


static func P(r: float, y: float, t: float) -> Vector3:
	return Vector3(sin(t) * r, y, -cos(t) * r)


static func D(t: float) -> Vector3:
	return Vector3(sin(t), 0.0, -cos(t))


static func T(t: float) -> Vector3:
	return Vector3(cos(t), 0.0, sin(t))


static func frac_of(t: float) -> float:
	return fposmod(t, TAU) / TAU


# --- Body -------------------------------------------------------------------------------------------

func _build_body(painted: Material, contact: Material) -> ArrayMesh:
	_rng.seed = 1219
	_begin()
	_build_rim()
	_build_runes()
	_build_apron()
	_build_winch()
	_build_props()
	var verts: int = _v.size()
	var mesh: ArrayMesh = _commit(painted)
	_begin()
	_contact_disc(2.95)
	_commit(contact, mesh)
	_report.append("body: %d raw verts -> %d indexed, surfaces %d" % [verts,
		(mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), mesh.get_surface_count()])
	return mesh


## A ring-sector stone block: inner / outer radius, angles, heights; `bevel` chamfers the outer top edge. The inner face
## gets `inner` as its colour (the dark, essence-stained shaft).
func _sector(r0: float, r1: float, a0: float, a1: float, y0: float, y1: float, bevel: float, segs: int,
		inner: Color, ends: bool = true) -> void:
	var b: float = bevel
	for i: int in segs:
		var t0: float = lerpf(a0, a1, float(i) / segs)
		var t1: float = lerpf(a0, a1, float(i + 1) / segs)
		var d0: Vector3 = D(t0)
		var d1: Vector3 = D(t1)
		_quad(P(r1, y0, t0), P(r1, y0, t1), P(r1, y1 - b, t1), P(r1, y1 - b, t0), d0, d1, d1, d0)
		if b > 0.0:
			var b0: Vector3 = (d0 + Vector3.UP).normalized()
			var b1: Vector3 = (d1 + Vector3.UP).normalized()
			_quad(P(r1, y1 - b, t0), P(r1, y1 - b, t1), P(r1 - b, y1, t1), P(r1 - b, y1, t0), b0, b1, b1, b0)
		_fquad(P(r1 - b, y1, t0), P(r1 - b, y1, t1), P(r0, y1, t1), P(r0, y1, t0), Vector3.UP)
		_quad(P(r0, y1, t0), P(r0, y1, t1), P(r0, y0, t1), P(r0, y0, t0), -d0, -d1, -d1, -d0, Vector4.ZERO, inner)
	if not ends:
		return
	for side: int in 2:
		var t: float = a0 if side == 0 else a1
		var n: Vector3 = T(t) * (-1.0 if side == 0 else 1.0)
		var pts: Array[Vector3] = [P(r1, y0, t), P(r1, y1 - b, t), P(r1 - b, y1, t), P(r0, y1, t), P(r0, y0, t)]
		for k: int in range(1, pts.size() - 1):
			_tri(pts[0], pts[k], pts[k + 1], n, n, n)


func _build_rim() -> void:
	var inner_base: Color = C_DARK * 0.62
	# Footing: 7 big dark blocks, a mortar core behind the joints.
	_part(C_DARK, Kind.STONE, 0.9)
	_sector(R_IN + 0.04, FOOT_OUT - 0.06, 0.0, TAU, 0.0, Y_FOOT - 0.02, 0.0, 28, C_MORTAR, false)
	var off: float = 0.3
	for i: int in 7:
		var a0: float = off + i * TAU / 7.0 + 0.012
		var a1: float = off + (i + 1) * TAU / 7.0 - 0.012
		_col = _jit(C_DARK, 0.08)
		_sector(R_IN, FOOT_OUT + _rng.randf_range(-0.03, 0.04), a0, a1, 0.0, Y_FOOT + _rng.randf_range(-0.015, 0.015),
			0.05, 4, inner_base)
	_end_part(0.0, Y_TOP)
	# Wall: three courses of staggered blocks.
	var courses: Array = [[Y_FOOT, 0.37, 9, 0.1], [0.37, 0.58, 10, 0.45], [0.58, Y_WALL, 9, 0.8]]
	for ci: int in courses.size():
		var cr: Array = courses[ci]
		var y0: float = cr[0]
		var y1: float = cr[1]
		var cnt: int = cr[2]
		var o: float = cr[3]
		_part(C_MORTAR, Kind.STONE, 0.5)
		_sector(R_IN + 0.04, R_WALL - 0.05, 0.0, TAU, y0, y1 - 0.01, 0.0, 28, C_MORTAR, false)
		for i: int in cnt:
			var w: float = TAU / cnt
			var a0: float = o + i * w + 0.03 / R_WALL + _rng.randf_range(-0.03, 0.03)
			var a1: float = o + (i + 1) * w - 0.03 / R_WALL
			var pick: float = _rng.randf()
			var base: Color = C_STONE if pick < 0.45 else (C_STONE_W if pick < 0.75 else C_STONE_B)
			_col = _jit(base, 0.07)
			# Inner face: darker toward the bottom, stained violet near the essence.
			var stain: float = 0.35 + 0.35 * float(ci) / 2.0
			var inner: Color = (_col * 0.55).lerp(C_STAIN, stain * 0.55)
			_sector(R_IN, R_WALL + _rng.randf_range(-0.02, 0.03), a0, a1, y0, y1 + _rng.randf_range(-0.012, 0.012),
				0.035, 3, inner)
		_end_part(0.0, Y_TOP)
	# Coping: 10 big light stones, overhanging both faces; one missing at the back-right (fallen, see _build_props).
	for i: int in N_COPE:
		var w: float = TAU / N_COPE
		var a0: float = i * w + 0.025 / COPE_OUT
		var a1: float = (i + 1) * w - 0.025 / COPE_OUT
		var mid: float = (a0 + a1) * 0.5
		if mid > GAP_A0 and mid < GAP_A1:
			continue
		_part(_jit(C_COPE, 0.06), Kind.STONE, 0.75)
		var drop: float = 0.0
		var out: float = 0.0
		if i == CRACKED:   # a cracked stone at the front-left, pushed out and down a little (a crystal grows from the crack)
			drop = 0.035
			out = 0.05
		var inner: Color = (_col * 0.6).lerp(C_STAIN, 0.6)
		_sector(COPE_IN + out, COPE_OUT + out + _rng.randf_range(-0.02, 0.02), a0, a1, Y_WALL, Y_TOP - drop, 0.06, 4, inner)
		_end_part(0.0, Y_TOP)


## Carved runes on the coping top: a glyph per stone and two thin inlay arcs, all kind RUNE with their angle fraction.
func _build_runes() -> void:
	var glyphs: Array = [
		[[Vector2(0, -0.15), Vector2(0, 0.15)], [Vector2(0, 0.03), Vector2(0.1, 0.14)], [Vector2(0, 0.03), Vector2(-0.1, 0.14)]],
		[[Vector2(0, -0.15), Vector2(0, 0.15)], [Vector2(0, 0.15), Vector2(0.11, 0.03)], [Vector2(0.11, 0.03), Vector2(0, -0.07)]],
		[[Vector2(0, -0.15), Vector2(0.1, 0)], [Vector2(0.1, 0), Vector2(0, 0.15)], [Vector2(0, 0.15), Vector2(-0.1, 0)],
			[Vector2(-0.1, 0), Vector2(0, -0.15)]],
		[[Vector2(0, -0.15), Vector2(0, 0.15)], [Vector2(-0.11, -0.05), Vector2(0.11, 0.07)]],
		[[Vector2(-0.07, -0.15), Vector2(-0.07, 0.15)], [Vector2(0.07, -0.15), Vector2(0.07, 0.15)],
			[Vector2(-0.07, 0.09), Vector2(0.07, -0.09)]],
		[[Vector2(0, -0.12), Vector2(0, 0.15)], [Vector2(0, 0.15), Vector2(-0.1, 0.04)], [Vector2(0, 0.15), Vector2(0.1, 0.04)],
			[Vector2(-0.09, -0.15), Vector2(0.09, -0.15)]],
	]
	_part(C_GROOVE, Kind.RUNE, 0.0)
	for i: int in N_COPE:
		var w: float = TAU / N_COPE
		var a0: float = i * w + 0.025 / COPE_OUT
		var a1: float = (i + 1) * w - 0.025 / COPE_OUT
		var mid: float = (a0 + a1) * 0.5
		if mid > GAP_A0 and mid < GAP_A1:
			continue
		var drop: float = 0.035 if i == CRACKED else 0.0
		var out: float = 0.05 if i == CRACKED else 0.0
		var y: float = Y_TOP - drop
		var g: Array = glyphs[(i * 5 + 1) % glyphs.size()]
		for s: Array in g:
			_stroke(mid, RUNE_R + out, (s[0] as Vector2) * 1.15, (s[1] as Vector2) * 1.15, y, 0.05)
		# Inlay arcs (inner and outer), leaving 6 cm at the stone ends.
		for r: float in [0.80 + out, 1.31 + out]:
			var m: float = 0.06 / r
			_arc(r, a0 + m, a1 - m, y, 0.035, 5)
	_end_part(0.0, Y_TOP)


## A raised glyph stroke on the coping top from `a` to `b` ((tangential, radial) metres around the glyph centre at angle
## `tc`, radius `rc`), `w` wide, 1.4 cm proud.
func _stroke(tc: float, rc: float, a: Vector2, b: Vector2, y: float, w: float) -> void:
	var d: Vector2 = (b - a).normalized()
	var nr := Vector2(-d.y, d.x) * w * 0.5
	var ext: Vector2 = d * w * 0.35
	var q: Array[Vector2] = [a - ext - nr, b + ext - nr, b + ext + nr, a - ext + nr]
	var top: Array[Vector3] = []
	var bot: Array[Vector3] = []
	var ang: Array[float] = []
	for p: Vector2 in q:
		var r: float = rc + p.y
		var t: float = tc + p.x / r
		top.append(P(r, y + 0.014, t))
		bot.append(P(r, y - 0.004, t))
		ang.append(frac_of(t))
	_quad(top[0], top[1], top[2], top[3], Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector4(ang[0], ang[1], ang[2], ang[3]))
	for k: int in 4:
		var k2: int = (k + 1) % 4
		var mid: Vector3 = (top[k] + top[k2]) * 0.5
		var cen: Vector3 = (top[0] + top[1] + top[2] + top[3]) * 0.25
		var n: Vector3 = (mid - cen)
		n.y = 0.0
		n = n.normalized()
		_quad(bot[k], bot[k2], top[k2], top[k], n, n, n, n, Vector4(ang[k], ang[k2], ang[k2], ang[k]))


## A thin raised inlay arc at radius `r` from angle a0 to a1.
func _arc(r: float, a0: float, a1: float, y: float, w: float, segs: int) -> void:
	for i: int in segs:
		var t0: float = lerpf(a0, a1, float(i) / segs)
		var t1: float = lerpf(a0, a1, float(i + 1) / segs)
		var e := Vector4(frac_of(t0), frac_of(t1), frac_of(t1), frac_of(t0))
		var yt: float = y + 0.012
		_quad(P(r - w * 0.5, yt, t0), P(r - w * 0.5, yt, t1), P(r + w * 0.5, yt, t1), P(r + w * 0.5, yt, t0),
			Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, e)
		_quad(P(r + w * 0.5, y - 0.004, t0), P(r + w * 0.5, y - 0.004, t1), P(r + w * 0.5, yt, t1), P(r + w * 0.5, yt, t0),
			D(t0), D(t1), D(t1), D(t0), e)
		_quad(P(r - w * 0.5, yt, t0), P(r - w * 0.5, yt, t1), P(r - w * 0.5, y - 0.004, t1), P(r - w * 0.5, y - 0.004, t0),
			-D(t0), -D(t1), -D(t1), -D(t0), e)


## A flat stone slab: an irregular convex polygon (centre `c`, radii rx / rz, yaw) extruded from y0 to y1, top edge
## chamfered by `bevel`.
func _slab(c: Vector3, rx: float, rz: float, yaw: float, y0: float, y1: float, sides: int, bevel: float) -> void:
	var ring: Array[Vector3] = []
	for k: int in sides:
		var a: float = TAU * (float(k) + _rng.randf_range(-0.2, 0.2)) / sides
		var j: float = _rng.randf_range(0.82, 1.08)
		var p := Vector2(cos(a) * rx * j, sin(a) * rz * j).rotated(yaw)
		ring.append(Vector3(c.x + p.x, 0.0, c.z + p.y))
	var cen := Vector3(c.x, 0.0, c.z)
	for k: int in sides:
		var a0: Vector3 = ring[k]
		var a1: Vector3 = ring[(k + 1) % sides]
		var o0: Vector3 = (a0 - cen).normalized()
		var o1: Vector3 = (a1 - cen).normalized()
		var i0: Vector3 = a0 - o0 * bevel
		var i1: Vector3 = a1 - o1 * bevel
		var n := Vector3(a1.z - a0.z, 0.0, a0.x - a1.x).normalized()
		if n.dot(a0 - cen) < 0.0:
			n = -n
		_fquad(Vector3(a0.x, y0, a0.z), Vector3(a1.x, y0, a1.z), Vector3(a1.x, y1 - bevel, a1.z), Vector3(a0.x, y1 - bevel, a0.z), n)
		var bn: Vector3 = (n + Vector3.UP).normalized()
		_fquad(Vector3(a0.x, y1 - bevel, a0.z), Vector3(a1.x, y1 - bevel, a1.z), Vector3(i1.x, y1, i1.z), Vector3(i0.x, y1, i0.z), bn)
		_tri(Vector3(cen.x, y1, cen.z), Vector3(i0.x, y1, i0.z), Vector3(i1.x, y1, i1.z), Vector3.UP, Vector3.UP, Vector3.UP)


func _build_apron() -> void:
	# Cracked flagstones round the well: an inner ring (a few missing at the broken back-right, where the stones fell)
	# and a partial outer ring toward the front (the approach), all low and mossy.
	var n1: int = 13
	for k: int in n1:
		var a: float = (float(k) + 0.5) * TAU / n1 + _rng.randf_range(-0.06, 0.06)
		if (a > 1.95 and a < 2.5) or k == 9:
			continue
		var r: float = _rng.randf_range(1.93, 2.08)
		_part(_jit(C_FLAG, 0.08), Kind.STONE, 0.9)
		var c: Vector3 = P(r, 0.0, a)
		_slab(c, _rng.randf_range(0.36, 0.44), _rng.randf_range(0.27, 0.33), -a + PI * 0.5, -0.05,
			_rng.randf_range(0.035, 0.065), 6, 0.025)
		_end_part(-0.05, 0.6)
	var n2: int = 17
	for k: int in n2:
		var a: float = (float(k) + 0.3) * TAU / n2 + _rng.randf_range(-0.05, 0.05)
		# Front half only (z > 0 is t in (PI/2, 3 PI/2)), sparser at the sides.
		if a < PI * 0.62 or a > PI * 1.42 or _rng.randf() < 0.2:
			continue
		var r: float = _rng.randf_range(2.6, 2.78)
		_part(_jit(C_FLAG, 0.1), Kind.STONE, 1.0)
		_slab(P(r, 0.0, a), _rng.randf_range(0.3, 0.4), _rng.randf_range(0.24, 0.3), -a + PI * 0.5, -0.05,
			_rng.randf_range(0.02, 0.045), 5, 0.02)
		_end_part(-0.05, 0.6)
	# Rubble: small rounded stones, half sunk, around the apron (more at the broken side).
	var rock: SphereMesh = _sphere(0.5, 7, 4)
	for k: int in 12:
		var a: float = _rng.randf() * TAU
		if k < 4:
			a = _rng.randf_range(1.7, 2.7)
		var r: float = _rng.randf_range(2.2, 3.05)
		var s: float = _rng.randf_range(0.16, 0.3)
		_part(_jit(C_DARK, 0.1), Kind.STONE, 0.8)
		_prim(rock, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.RIGHT, _rng.randf_range(0.1, 0.35))
			.scaled(Vector3(s * 1.2, s * 0.7, s)), P(r, s * 0.12, a)))
		_end_part(-0.1, 0.5)


func _build_winch() -> void:
	# Two posts on stone pads carry the little gable roof (ridge front-to-back, so the triangle faces the RTS camera:
	# the "well" silhouette). The right post split and sank, so the roof tilts right and lost shingles there; the rope
	# drum broke out of its right bearing and fell into the broken coping; a log props the left post.
	var lb := Vector3(-POST_X, 0.18, POST_Z)
	var lt: Vector3 = Vector3(-POST_X - 0.06, LEFT_TOP, POST_Z)
	var rb := Vector3(POST_X, 0.18, POST_Z)
	var rt: Vector3 = Vector3(POST_X - 0.2, RIGHT_TOP, POST_Z)
	_part(_jit(C_DARK, 0.05), Kind.STONE, 0.8)
	_prim(_box(Vector3(0.46, 0.2, 0.46)), _xf(Vector3(-POST_X, 0.1, POST_Z), Vector3(0, 12, 0)))
	_prim(_box(Vector3(0.46, 0.2, 0.46)), _xf(Vector3(POST_X, 0.1, POST_Z), Vector3(0, -8, 0)))
	_end_part(0.0, 0.6)
	_part(_jit(C_TIMBER, 0.05), Kind.WOOD, 0.6)
	_prim(_box(Vector3(0.28, (lt - lb).length(), 0.28)), _span(lb, lt), true)
	_end_part()
	_part(_jit(C_TIMBER, 0.05), Kind.WOOD, 0.6)
	_prim(_box(Vector3(0.28, (rt - rb).length(), 0.28)), _span(rb, rt), true)
	# The split: a wedge of the right post cracked off at mid-height (sticking out), iron splint bands above and below.
	var mid_r: Vector3 = rb.lerp(rt, 0.45)
	_prim(_box(Vector3(0.1, 0.62, 0.2)), Transform3D(Basis(Vector3.BACK, deg_to_rad(-14.0)), mid_r + Vector3(0.17, 0.0, 0.02)), true)
	_end_part()
	_part(_jit(C_TIMBER_D, 0.05), Kind.WOOD, 0.9)
	# The prop log: from the ground in front, up against the left post.
	var foot := Vector3(-1.5, 0.0, 0.95)
	var head: Vector3 = lb.lerp(lt, 0.5) + Vector3(-0.02, 0, 0.15)
	_prim(_cyl(0.09, 0.11, (head - foot).length(), 7), _span(foot, head), true)
	_end_part()
	# Drum: left end still in its bearing, right end fallen into the broken coping. Rope wound on it, iron bands.
	var dl: Vector3 = lb.lerp(lt, 0.58) + Vector3(0.17, 0.0, 0.0)
	var dr: Vector3 = DRUM_R
	var dd: Vector3 = (dr - dl).normalized()
	_part(_jit(C_TIMBER_D, 0.04), Kind.WOOD, 0.3)
	_prim(_cyl(DRUM_R_RADIUS, DRUM_R_RADIUS, (dr - dl).length(), 8), _span(dl, dr), true)
	_end_part()
	_part(C_ROPE, Kind.ROPE, 0.0)
	var rm: Vector3 = dl.lerp(dr, 0.36)
	_prim(_cyl(DRUM_R_RADIUS + 0.05, DRUM_R_RADIUS + 0.05, 0.5, 8), _span(rm - dd * 0.25, rm + dd * 0.25))
	_end_part()
	_part(C_IRON, Kind.IRON, 0.0)
	for f: float in [0.03, 0.97]:
		var c: Vector3 = dl.lerp(dr, f)
		_prim(_cyl(DRUM_R_RADIUS + 0.025, DRUM_R_RADIUS + 0.025, 0.07, 8), _span(c - dd * 0.035, c + dd * 0.035))
	# Left bearing strap, axle stub through the post, crank arm and handle (outside the left post).
	_prim(_box(Vector3(0.34, 0.1, 0.34)), _xf(lb.lerp(lt, 0.58) + Vector3(0, 0.2, 0)))
	var ax: Vector3 = dl - dd * 0.02
	var stub_end: Vector3 = ax + Vector3(-0.3, 0.0, 0.0)
	_prim(_cyl(0.045, 0.045, 0.33, 6), _span(ax, stub_end))
	var arm_end: Vector3 = stub_end + Vector3(0, -0.38, 0.12)
	_prim(_box(Vector3(0.07, 0.42, 0.05)), _span(stub_end, arm_end))
	_prim(_cyl(0.035, 0.035, 0.26, 6), _span(arm_end, arm_end + Vector3(0, 0, 0.26)))
	# The right bearing: its bracket torn open (bent iron), splint bands round the split post.
	var rbear: Vector3 = rb.lerp(rt, 0.62)
	_prim(_box(Vector3(0.34, 0.1, 0.34)), _xf(rbear, Vector3(0, 0, -20)))
	_prim(_box(Vector3(0.05, 0.3, 0.3)), _xf(rbear + Vector3(-0.2, 0.1, 0), Vector3(0, 0, 35)))
	for f2: float in [0.25, 0.68]:
		_prim(_box(Vector3(0.33, 0.06, 0.33)), _span(rb.lerp(rt, f2) - Vector3(0, 0.03, 0), rb.lerp(rt, f2) + Vector3(0, 0.03, 0)))
	_prim(_box(Vector3(0.33, 0.06, 0.33)), _span(lb.lerp(lt, 0.2) - Vector3(0, 0.03, 0), lb.lerp(lt, 0.2) + Vector3(0, 0.03, 0)))
	_end_part()
	# The frayed rope hanging from the drum over the shaft, a few strands at its end.
	var r0: Vector3 = rm + Vector3(0.05, -DRUM_R_RADIUS - 0.03, 0.14)
	var r1: Vector3 = Vector3(-0.2, 1.05, 0.02)
	_part(C_ROPE, Kind.ROPE, 0.0)
	_prim(_cyl(0.034, 0.034, (r1 - r0).length(), 5), _span(r0, r1))
	for k: int in 4:
		var a: float = k * TAU / 4.0 + 0.4
		_prim(_cyl(0.0, 0.018, 0.17, 3), _span(r1, r1 + Vector3(cos(a) * 0.08, -0.16, sin(a) * 0.08)))
	_end_part()
	_build_roof(lt, rt)


## The tilted gable roof. Roof frame: origin half way between the post tops, x toward the right post top, y up, z along
## the ridge (front = +Z). Slab frame (side s = +1 right, -1 left): x down the slope (times s), y out of the roof.
func _build_roof(lt: Vector3, rt: Vector3) -> void:
	var span_v: Vector3 = rt - lt
	var half: float = span_v.length() * 0.5
	var rf := Transform3D(Basis(Vector3.BACK, atan2(span_v.y, span_v.x)), (lt + rt) * 0.5 + Vector3(0, 0.08, 0))
	var pitch: float = deg_to_rad(ROOF_PITCH)
	var ridge_h: float = 0.1 + half * tan(pitch)
	var slope_len: float = (half + 0.26) / cos(pitch)
	var depth: float = ROOF_DEPTH
	# Caps on the post tops, ridge beam, rafter pairs at both gable ends and in the middle, a tie beam at the front.
	_part(_jit(C_TIMBER_D, 0.04), Kind.WOOD, 0.2)
	for sx: float in [-1.0, 1.0]:
		_prim(_box(Vector3(0.36, 0.14, depth * 2.0 + 0.1)), rf * _xf(Vector3(sx * half, 0.0, 0.0)), true)
	_prim(_box(Vector3(0.15, depth * 2.0 + 0.3, 0.15)), rf * _span(Vector3(0, ridge_h - 0.05, -depth - 0.15),
		Vector3(0, ridge_h - 0.05, depth + 0.15)), true)
	for z: float in [-depth + 0.06, 0.0, depth - 0.06]:
		for s: float in [-1.0, 1.0]:
			var top := Vector3(0.0, ridge_h - 0.08, z)
			var low: Vector3 = top + Vector3(s * cos(pitch), -sin(pitch), 0.0) * (slope_len - 0.12)
			_prim(_box(Vector3(0.1, slope_len - 0.1, 0.1)), rf * _span(top, low), true)
	_prim(_box(Vector3(0.1, half * 2.0 + 0.1, 0.1)), rf * _span(Vector3(-half - 0.05, 0.08, depth - 0.06),
		Vector3(half + 0.05, 0.08, depth - 0.06)), true)
	_end_part()
	# Gable boards (front and back): a triangle of planks under the rafters.
	_part(_jit(C_TIMBER, 0.05), Kind.WOOD, 0.2)
	var gh: float = ridge_h - 0.16
	var gw: float = gh / tan(pitch) * 2.0
	var pm := PrismMesh.new()
	pm.size = Vector3(gw, gh, 0.06)
	for z2: float in [-depth + 0.04, depth - 0.04]:
		_prim(pm, rf * _xf(Vector3(0.0, 0.1 + gh * 0.5, z2)), true)
	_end_part()
	# The rune medallion on the front gable: a stone ring round a carved disc that glows with the well's state (it takes
	# the capturer's colour as soon as a capture starts: its angle fraction is 0).
	var mc: Vector3 = rf * Vector3(0.0, 0.1 + gh * 0.36, depth + 0.02)
	var mb: Basis = rf.basis * Basis(Vector3.RIGHT, PI * 0.5)
	_part(_jit(C_COPE, 0.04), Kind.STONE, 0.3)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.19
	ring.outer_radius = 0.3
	ring.rings = 14
	ring.ring_segments = 6
	_prim(ring, Transform3D(mb, mc))
	_end_part()
	_part(C_GROOVE, Kind.RUNE, 0.0)
	var start: int = _v.size()
	_prim(_cyl(0.2, 0.2, 0.05, 12), Transform3D(mb, mc))
	for i: int in range(start, _v.size()):
		_uv2[i] = Vector2(float(Kind.RUNE), 0.001)
	_end_part()
	# Shingles: rows of boards along the ridge, down each slope. The right slab (the low side) lost boards: two rows cut
	# short (a hole shows the rafters) and one board hangs from the eave.
	for side: int in 2:
		var s: float = -1.0 if side == 0 else 1.0
		var sb := Basis(Vector3.BACK, -pitch * s)
		var rows: int = 5
		var row_w: float = slope_len / rows
		for row: int in rows:
			var z0: float = -depth - 0.12
			var z1: float = depth + 0.12
			if side == 1 and row == 2:
				z0 = 0.05
			elif side == 1 and row == 3:
				z1 = -0.25
			z0 += _rng.randf_range(-0.05, 0.05)
			z1 += _rng.randf_range(-0.05, 0.05)
			_part(_jit(C_SHINGLE, 0.09), Kind.SHINGLE, 0.55)
			var d: float = (row + 0.5) * row_w
			var local := Transform3D(sb, Vector3(0.0, ridge_h, 0.0)) \
				* Transform3D(Basis(Vector3.BACK, deg_to_rad(5.0) * s), Vector3(s * d, 0.06 + row * 0.012, (z0 + z1) * 0.5))
			_prim(_box(Vector3(row_w + 0.07, z1 - z0, 0.055)), rf * local * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), true)
			_end_part()
	# Ridge cap boards.
	_part(_jit(C_TIMBER_D, 0.04), Kind.SHINGLE, 0.3)
	for s2: float in [-1.0, 1.0]:
		var cap_xf := Transform3D(Basis(Vector3.BACK, -pitch * s2 * 0.6), Vector3(s2 * 0.08, ridge_h + 0.13, 0.0))
		_prim(_box(Vector3(0.22, depth * 2.0 + 0.36, 0.05)), rf * cap_xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), true)
	_end_part()
	# The hanging board below the right eave.
	_part(_jit(C_SHINGLE, 0.06), Kind.SHINGLE, 0.2)
	var eave_r: Vector3 = rf * (Transform3D(Basis(Vector3.BACK, -pitch), Vector3(0.0, ridge_h, 0.0)) * Vector3(slope_len - 0.1, 0.06, 0.2))
	var hang_bot: Vector3 = eave_r + Vector3(-0.1, -0.9, 0.18)
	_prim(_box(Vector3(0.36, (hang_bot - eave_r).length(), 0.055)), _span(eave_r, hang_bot, 0.2), true)
	_end_part()


func _build_props() -> void:
	# The fallen coping stones at the front-right, one on the apron, one tipped against the footing.
	_part(_jit(C_COPE, 0.05), Kind.STONE, 0.7)
	_prim(_box(Vector3(0.66, 0.2, 0.44)), _xf(P(2.15, 0.08, 2.3), Vector3(4.0, -rad_to_deg(2.3) + 12.0, 7.0)))
	_end_part(-0.1, 0.9)
	_part(_jit(C_COPE, 0.05), Kind.STONE, 0.7)
	_prim(_box(Vector3(0.6, 0.2, 0.42)), _xf(P(1.84, 0.19, 1.92), Vector3(-8.0, -rad_to_deg(1.92) - 5.0, 26.0)))
	_end_part(-0.1, 0.9)
	# Shingle boards blown off the right slab, lying on the apron at the back-right (one propped on a stone).
	for bd: Array in [[Vector3(2.05, 0.07, -1.35), Vector3(2.3, 0.09, -0.15), 0.1], [Vector3(1.75, 0.06, -1.75), Vector3(2.65, 0.24, -1.2), 0.5]]:
		_part(_jit(C_SHINGLE, 0.08), Kind.SHINGLE, 0.7)
		var a: Vector3 = bd[0]
		var b: Vector3 = bd[1]
		_prim(_box(Vector3(0.4, (b - a).length(), 0.055)), _span(a, b, float(bd[2])), true)
		_end_part(0.0, 1.0)
	# The tipped bucket on the apron (front-left), mouth toward +X where the essence spilled.
	var bc := Vector3(-1.42, 0.2, 1.62)
	var bb := Basis(Vector3.UP, deg_to_rad(-18.0)) * Basis(Vector3.BACK, -PI * 0.5 - 0.12)   # local +Y (mouth) -> +X
	_part(C_BUCKET, Kind.WOOD, 0.2)
	_prim(_cyl(0.21, 0.17, 0.38, 9), Transform3D(bb, bc), true)
	_end_part(0.0, 0.5)
	_part(C_IRON, Kind.IRON, 0.0)
	for f: float in [-0.12, 0.12]:
		_prim(_cyl(0.202 + f * 0.105, 0.202 + f * 0.105, 0.04, 9), Transform3D(bb, bc + bb * Vector3(0, f, 0)))
	_prim(_cyl(0.012, 0.012, 0.44, 4), Transform3D(bb * Basis(Vector3.BACK, PI * 0.5), bc + bb * Vector3(0.0, 0.22, 0.0)))
	_end_part(0.0, 0.5)
	# The dark inside of the bucket's mouth.
	_part(C_TIMBER_D * 0.45, Kind.WOOD, 0.0)
	_prim(_cyl(0.19, 0.19, 0.02, 9), Transform3D(bb, bc + bb * Vector3(0, 0.185, 0)))
	_end_part(0.0, 0.5)
	# A few loose stones from the broken coping lying by the footing.
	_part(_jit(C_STONE, 0.06), Kind.STONE, 0.5)
	_prim(_box(Vector3(0.3, 0.16, 0.24)), _xf(P(1.74, 0.07, 1.75), Vector3(0, 30, 12)))
	_prim(_box(Vector3(0.24, 0.14, 0.2)), _xf(P(2.5, 0.05, 2.62), Vector3(10, -20, 0)))
	_end_part(-0.1, 0.6)


## The contact shadow disc (nature_contact.gdshader: UV.x = 0 at the centre -> 1 at the rim).
func _contact_disc(r: float) -> void:
	_part(Color.WHITE, 0, 0.0)
	var segs: int = 20
	for i: int in segs:
		var t0: float = i * TAU / segs
		var t1: float = (i + 1) * TAU / segs
		var c := Vector3(0, 0.02, 0)
		var p0: Vector3 = P(r, 0.02, t0)
		var p1: Vector3 = P(r, 0.02, t1)
		_v.append(c)
		_v.append(p0 if _conv < 0.0 else p1)
		_v.append(p1 if _conv < 0.0 else p0)
		for k: int in 3:
			_n.append(Vector3.UP)
			_c.append(Color.WHITE)
			_uv2.append(Vector2.ZERO)
		_uv.append(Vector2(0.0, 0.0))
		_uv.append(Vector2(1.0, 0.0))
		_uv.append(Vector2(1.0, 0.0))
	# Wound for +Y: check with the triangle helper's rule (front faces the normal).
	var fn: Vector3 = (_v[1] - _v[0]).cross(_v[2] - _v[0])
	if fn.dot(Vector3.UP) * _conv < 0.0:
		for i: int in range(0, _v.size(), 3):
			var tmp: Vector3 = _v[i + 1]
			_v[i + 1] = _v[i + 2]
			_v[i + 2] = tmp


# --- Essence (pool, crystals, spill) -------------------------------------------------------------

func _build_essence(mat: Material) -> ArrayMesh:
	_rng.seed = 4410
	_begin()
	# Pool: a disc in rings (for the swell), UV = local xz / radius.
	_part(Color.WHITE, 0, 0.0)
	var rings: int = 4
	var segs: int = 28
	for ri: int in rings:
		var ra: float = POOL_R * float(ri) / rings
		var rb: float = POOL_R * float(ri + 1) / rings
		for i: int in segs:
			var t0: float = i * TAU / segs
			var t1: float = (i + 1) * TAU / segs
			var q: Array[Vector3] = [P(ra, POOL_Y, t0), P(ra, POOL_Y, t1), P(rb, POOL_Y, t1), P(rb, POOL_Y, t0)]
			_essence_quad(q, POOL_R, 0.0)
	# Crystals: the big cluster in the broken front-right, a small one from the cracked coping stone (front-left), a few
	# poking out of the pool at the back-left.
	_crystal_cluster(P(1.62, 0.0, 2.2), [[0.95, 0.13, 0.0, 22.0], [0.7, 0.1, 1.9, 30.0], [0.55, 0.09, 3.9, 26.0],
		[0.42, 0.08, 5.1, 38.0], [0.32, 0.07, 2.8, 44.0]], 2.2)
	_crystal_cluster(P(1.36, Y_TOP - 0.08, 4.08), [[0.36, 0.07, 0.3, 26.0], [0.26, 0.055, 2.2, 36.0],
		[0.2, 0.05, 4.4, 40.0]], 4.08)
	_crystal_cluster(P(0.5, POOL_Y - 0.1, 5.75), [[0.5, 0.08, 0.2, 14.0], [0.34, 0.06, 2.4, 26.0],
		[0.26, 0.05, 4.6, 30.0]], 5.75)
	# Spill: a ragged puddle at the bucket's mouth.
	var sc := Vector3(-0.98, 0.075, 1.72)
	var sr: float = 0.46
	var ss: int = 14
	var rad: Array[float] = []
	for i: int in ss:
		rad.append(sr * _rng.randf_range(0.7, 1.08))
	for i: int in ss:
		var t0: float = i * TAU / ss
		var t1: float = (i + 1) * TAU / ss
		var p0: Vector3 = sc + Vector3(cos(t0) * rad[i] * 1.25, 0.0, sin(t0) * rad[i] * 0.8)
		var p1: Vector3 = sc + Vector3(cos(t1) * rad[(i + 1) % ss] * 1.25, 0.0, sin(t1) * rad[(i + 1) % ss] * 0.8)
		_mode_tri(sc, p0, p1, Vector2.ZERO, Vector2(cos(t0), sin(t0)), Vector2(cos(t1), sin(t1)), 2.0)
	var mesh: ArrayMesh = _commit(mat)
	_report.append("essence: %d verts indexed" % (mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
	return mesh


func _essence_quad(q: Array[Vector3], r: float, mode: float) -> void:
	var uv: Array[Vector2] = []
	for p: Vector3 in q:
		uv.append(Vector2(p.x, p.z) / r)
	_mode_tri(q[0], q[1], q[2], uv[0], uv[1], uv[2], mode)
	_mode_tri(q[0], q[2], q[3], uv[0], uv[2], uv[3], mode)


## A flat, upward-facing triangle with explicit UVs and mode (UV2.x).
func _mode_tri(a: Vector3, b: Vector3, c: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, mode: float) -> void:
	var fn: Vector3 = (b - a).cross(c - a)
	var pts: Array = [[a, ua], [b, ub], [c, uc]]
	if fn.dot(Vector3.UP) * _conv < 0.0:
		pts = [[a, ua], [c, uc], [b, ub]]
	for p: Array in pts:
		_v.append(p[0])
		_n.append(Vector3.UP)
		_c.append(Color.WHITE)
		_uv.append(p[1])
		_uv2.append(Vector2(mode, 0.0))


## Crystals at `base`: each [height, radius, azimuth (rad), tilt (deg)], leaning away from the cluster centre and
## outward (azimuth `out` = the direction away from the well).
func _crystal_cluster(base: Vector3, list: Array, out: float) -> void:
	for cr: Array in list:
		var h: float = cr[0]
		var r: float = cr[1]
		var az: float = float(cr[2]) + out
		var tilt: float = deg_to_rad(float(cr[3]))
		var dir: Vector3 = (Vector3.UP * cos(tilt) + D(az) * sin(tilt)).normalized()
		var foot: Vector3 = base + D(az) * r * 0.8 - Vector3(0, 0.05, 0)
		_crystal(foot, dir, h, r)


## A hexagonal crystal: prism body + pointed tip. UV = (facet, height fraction), mode 1.
func _crystal(foot: Vector3, dir: Vector3, h: float, r: float) -> void:
	var b := Basis(Quaternion(Vector3.UP, dir)) * Basis(Vector3.UP, _rng.randf() * TAU)
	var body_h: float = h - r * 1.9
	var sides: int = 6
	for k: int in sides:
		var a0: float = k * TAU / sides
		var a1: float = (k + 1) * TAU / sides
		var o0 := Vector3(cos(a0) * r, 0.0, sin(a0) * r)
		var o1 := Vector3(cos(a1) * r, 0.0, sin(a1) * r)
		var n: Vector3 = b * Vector3(cos((a0 + a1) * 0.5), 0.0, sin((a0 + a1) * 0.5))
		var p0: Vector3 = foot + b * o0
		var p1: Vector3 = foot + b * o1
		var p2: Vector3 = foot + b * (o1 * 0.92 + Vector3(0, body_h, 0))
		var p3: Vector3 = foot + b * (o0 * 0.92 + Vector3(0, body_h, 0))
		var tip: Vector3 = foot + b * Vector3(0, h, 0)
		var f: float = float(k)
		_crystal_tri(p0, p1, p2, n, Vector2(f, 0.0), Vector2(f, 0.0), Vector2(f, body_h / h))
		_crystal_tri(p0, p2, p3, n, Vector2(f, 0.0), Vector2(f, body_h / h), Vector2(f, body_h / h))
		var tn: Vector3 = (n + dir * 0.7).normalized()
		_crystal_tri(p3, p2, tip, tn, Vector2(f, body_h / h), Vector2(f, body_h / h), Vector2(f, 1.0))


func _crystal_tri(a: Vector3, b: Vector3, c: Vector3, n: Vector3, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	var fn: Vector3 = (b - a).cross(c - a)
	var pts: Array = [[a, ua], [b, ub], [c, uc]]
	if fn.dot(n) * _conv < 0.0:
		pts = [[a, ua], [c, uc], [b, ub]]
	for p: Array in pts:
		_v.append(p[0])
		_n.append(n)
		_c.append(Color.WHITE)
		_uv.append(p[1])
		_uv2.append(Vector2(1.0, 0.0))


# --- Fx (mist cards, ground glow, pulse ring) ---------------------------------------------------

func _build_fx(mat: Material) -> ArrayMesh:
	_begin()
	# Mist cards: built in the local XY plane (x across, y up, z = depth offset toward the camera); the shader turns
	# them around Y. [width, height, offset toward the camera (the mist drifts out in front of the gable), seed]
	for card: Array in [[1.45, 2.7, 0.3, 0.13], [1.0, 3.4, 0.45, 0.61], [0.75, 2.2, 0.15, 0.87]]:
		var w: float = card[0]
		var h: float = card[1]
		var z: float = card[2]
		var seed: float = card[3]
		var rows: int = 4
		for j: int in rows:
			var v0: float = float(j) / rows
			var v1: float = float(j + 1) / rows
			var y0: float = POOL_Y - 0.05 + v0 * h
			var y1: float = POOL_Y - 0.05 + v1 * h
			var q: Array[Vector3] = [Vector3(-w * 0.5, y0, z), Vector3(w * 0.5, y0, z), Vector3(w * 0.5, y1, z), Vector3(-w * 0.5, y1, z)]
			var uv: Array[Vector2] = [Vector2(0, v0), Vector2(1, v0), Vector2(1, v1), Vector2(0, v1)]
			_fx_tri(q[0], q[1], q[2], uv[0], uv[1], uv[2], 0.0, seed)
			_fx_tri(q[0], q[2], q[3], uv[0], uv[2], uv[3], 0.0, seed)
	# Ground glow (6.6 m) and pulse ring (10 m) quads, UV = local xz.
	for g: Array in [[3.3, 0.09, 1.0], [5.0, 0.1, 2.0]]:
		var s: float = g[0]
		var y: float = g[1]
		var q2: Array[Vector3] = [Vector3(-s, y, -s), Vector3(s, y, -s), Vector3(s, y, s), Vector3(-s, y, s)]
		var uv2: Array[Vector2] = []
		for p: Vector3 in q2:
			uv2.append(Vector2(p.x, p.z))
		_fx_tri(q2[0], q2[1], q2[2], uv2[0], uv2[1], uv2[2], float(g[2]), 0.0)
		_fx_tri(q2[0], q2[2], q2[3], uv2[0], uv2[2], uv2[3], float(g[2]), 0.0)
	var mesh: ArrayMesh = _commit(mat)
	_report.append("fx: %d verts indexed" % (mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
	return mesh


func _fx_tri(a: Vector3, b: Vector3, c: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, mode: float, seed: float) -> void:
	for p: Array in [[a, ua], [b, ub], [c, uc]]:
		_v.append(p[0])
		_n.append(Vector3.UP)
		_c.append(Color.WHITE)
		_uv.append(p[1])
		_uv2.append(Vector2(mode, seed))


# --- Scene ------------------------------------------------------------------------------------------

func _build_scene(body: ArrayMesh, ess: ArrayMesh, fxm: ArrayMesh, process: ParticleProcessMaterial, quad: QuadMesh) -> void:
	var root := Node3D.new()
	root.name = "EssenceWell"
	root.set_script(load(SCRIPT_PATH))
	var b := MeshInstance3D.new()
	b.name = "Body"
	b.mesh = body
	root.add_child(b)
	b.owner = root
	var e := MeshInstance3D.new()
	e.name = "Essence"
	e.mesh = ess
	e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(e)
	e.owner = root
	var f := MeshInstance3D.new()
	f.name = "Fx"
	f.mesh = fxm
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	f.custom_aabb = AABB(Vector3(-5.0, -0.1, -5.0), Vector3(10.0, 4.6, 10.0))
	root.add_child(f)
	f.owner = root
	var m := GPUParticles3D.new()
	m.name = "Mist"
	m.amount = 12
	m.lifetime = 2.6
	m.preprocess = 2.6
	m.fixed_fps = 30
	m.interpolate = true
	m.local_coords = true
	m.process_material = process
	m.draw_pass_1 = quad
	m.position = Vector3(0.0, POOL_Y, 0.0)
	m.visibility_aabb = AABB(Vector3(-1.6, -0.2, -1.6), Vector3(3.2, 4.4, 3.2))
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.visibility_range_end = 40.0
	m.visibility_range_end_margin = 6.0
	m.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	root.add_child(m)
	m.owner = root
	var ps := PackedScene.new()
	var err: int = ps.pack(root)
	if err != OK:
		push_error("pack failed: %d" % err)
	err = ResourceSaver.save(ps, DIR + "essence_well.tscn")
	if err != OK:
		push_error("scene save failed: %d" % err)
	root.free()
	_report.append("scene: %sessence_well.tscn" % DIR)
