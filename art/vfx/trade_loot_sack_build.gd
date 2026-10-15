extends SceneTree
## Task 10.V11: builds the loot sack look -> res://art/vfx/trade_loot_sack.tscn (root script trade_loot_sack.gd).
## Vertex-coloured, flat-shaded meshes (same recipe as art/environment/neutral/build_neutral.gd), embedded in the
## scene. Re-run after changing a shape or a colour:
##   $GODOT --headless --path . -s res://art/vfx/trade_loot_sack_build.gd --quit-after 600
## Parts (one draw each): ContactShadow, Glow (gold pool), Spill (coins on the ground), Sack/Body (burlap, rope,
## ruffle), Sack/MouthCoins (coins in the mouth + the stitched coin patch), Glints / Dust / Burst particles.

const OUT := "res://art/vfx/trade_loot_sack.tscn"
const SCRIPT := "res://art/vfx/trade_loot_sack.gd"

const BURLAP := Color(0.54, 0.43, 0.28)
const BURLAP_D := Color(0.43, 0.33, 0.21)
const BURLAP_L := Color(0.62, 0.50, 0.33)
const PATCH := Color(0.44, 0.33, 0.22)
const INSIDE := Color(0.18, 0.13, 0.08)
const ROPE := Color(0.46, 0.32, 0.18)
const GOLD_A := Color(0.98, 0.78, 0.30)
const GOLD_B := Color(0.86, 0.63, 0.22)
const GOLD_C := Color(1.00, 0.86, 0.45)
const LEAN_DEG := -14.0          # the sack leans toward +x, where the coins spilled

var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _conv := 1.0


func _init() -> void:
	_detect_winding()
	var root := Node3D.new()
	root.name = "TradeLootSack"
	root.set_script(load(SCRIPT))
	_decal(root)
	_glow(root)
	var gold_mat := ShaderMaterial.new()
	gold_mat.shader = load("res://art/vfx/trade_loot_sack_gold.gdshader") as Shader
	var body_mat := ShaderMaterial.new()
	body_mat.shader = load("res://art/environment/env_painted.gdshader") as Shader
	body_mat.set_shader_parameter(&"noise_tex", load("res://art/shaders/paint_noise.tres"))
	body_mat.set_shader_parameter(&"noise_scale_a", 3.0)
	body_mat.set_shader_parameter(&"noise_scale_b", 0.9)
	body_mat.set_shader_parameter(&"top_light", 0.15)
	body_mat.set_shader_parameter(&"rim_color", Color(1.0, 0.74, 0.28))   # the gold rim light
	body_mat.set_shader_parameter(&"rim_strength", 0.4)
	body_mat.set_shader_parameter(&"sway_strength", 0.0)
	# Coins spilled on the ground (stay put while the sack bobs).
	_begin()
	_spill()
	_mi(root, _commit(gold_mat, 0.0), "Spill", Vector3.ZERO)
	var sack := Node3D.new()
	sack.name = "Sack"
	root.add_child(sack)
	_begin()
	_body()
	_mi(sack, _commit(body_mat, 0.25), "Body", Vector3.ZERO)
	_begin()
	_mouth_coins()
	_mi(sack, _commit(gold_mat, 0.0), "MouthCoins", Vector3.ZERO)
	_particles(root)
	_own(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	var err := ResourceSaver.save(ps, OUT)
	print("saved %s: %d" % [OUT, err])
	root.free()
	print("LOOT SACK BUILD OK" if err == OK else "LOOT SACK BUILD FAILED")
	quit()


# ---------------------------------------------------------------- shapes

## Lean + position of the sack body (applied to the body and the mouth coins alike).
func _lean() -> Transform3D:
	return Transform3D(Basis.from_euler(Vector3(0.0, 0.0, deg_to_rad(LEAN_DEG))), Vector3(-0.04, 0.0, 0.0))


func _body() -> void:
	var lean := _lean()
	var segs := 14
	# Profile (y, r): round bottom, fat belly, pinched neck, flared ruffle.
	var prof: Array[Vector2] = [Vector2(0.0, 0.13), Vector2(0.03, 0.195), Vector2(0.09, 0.228), Vector2(0.17, 0.234),
			Vector2(0.24, 0.207), Vector2(0.30, 0.158), Vector2(0.34, 0.104), Vector2(0.368, 0.068)]
	var rings: Array = []
	for i in prof.size():
		var ring := PackedVector3Array()
		for s in segs:
			var a := TAU * float(s) / float(segs)
			var y := prof[i].x
			var belly := sin(PI * clampf(y / 0.34, 0.0, 1.0))
			var r := prof[i].y * (1.0 + 0.07 * sin(3.0 * a + 1.3) * belly + 0.035 * sin(5.0 * a + y * 20.0) * belly)
			ring.append(lean * Vector3(cos(a) * r, y, sin(a) * r))
		rings.append(ring)
	# Bottom cap.
	var bc := lean * Vector3(0.0, 0.0, 0.0)
	for s in segs:
		var r0: PackedVector3Array = rings[0]
		_tri(bc, r0[s], r0[(s + 1) % segs], BURLAP_D, Vector3.DOWN)
	# Sides: burlap blocks, darker patch faces, a lighter band on the belly.
	for i in prof.size() - 1:
		var ra: PackedVector3Array = rings[i]
		var rb: PackedVector3Array = rings[i + 1]
		for s in segs:
			var s2 := (s + 1) % segs
			var mid := (ra[s] + rb[s2]) * 0.5
			var out := mid - lean * Vector3(0.0, prof[i].x, 0.0)
			var col := BURLAP
			if i >= 5:
				col = BURLAP_D
			elif (s == 10 or s == 11) and (i == 2 or i == 3):
				col = PATCH                     # a darned patch on the back
			elif i == 2 and s % 3 == 0:
				col = BURLAP_L
			_quad(ra[s], ra[s2], rb[s2], rb[s], col, out)
	# Ruffle: the gathered cloth above the tie, flaring out with a ragged edge; both faces (it is thin).
	var top: PackedVector3Array = rings[prof.size() - 1]
	var r1 := PackedVector3Array()
	var r2 := PackedVector3Array()
	for s in segs:
		var a := TAU * float(s) / float(segs)
		var jag := 0.022 * sin(a * 7.0 + 0.4) + 0.012 * sin(a * 3.0)
		r1.append(lean * Vector3(cos(a) * 0.092, 0.405, sin(a) * 0.092))
		r2.append(lean * Vector3(cos(a) * (0.135 + jag * 0.8), 0.455 + jag, sin(a) * (0.135 + jag * 0.8)))
	var axis_hi := lean * Vector3(0.0, 0.41, 0.0)
	for s in segs:
		var s2 := (s + 1) % segs
		for pair: Array in [[top, r1], [r1, r2]]:
			var pa: PackedVector3Array = pair[0]
			var pb: PackedVector3Array = pair[1]
			var mid := (pa[s] + pb[s2]) * 0.5
			var out := mid - axis_hi
			var col := BURLAP_L if s % 2 == 0 else BURLAP
			_quad(pa[s], pa[s2], pb[s2], pb[s], col, out)
			_quad(pa[s], pa[s2], pb[s2], pb[s], INSIDE.lerp(BURLAP_D, 0.35), -out)
	# The dark inside of the mouth.
	var mc := lean * Vector3(0.0, 0.40, 0.0)
	for s in segs:
		_tri(mc, r1[s], r1[(s + 1) % segs], INSIDE, lean.basis * Vector3.UP)
	# Rope tie around the neck + two tails hanging on the front.
	_prim(_torus(0.058, 0.09, 12, 6), lean * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.378, 0.0)), ROPE)
	for k in 2:
		var side := -1.0 if k == 0 else 1.0
		var xf := lean * Transform3D(Basis.from_euler(Vector3(deg_to_rad(18.0), 0.0, deg_to_rad(12.0 * side))),
				Vector3(0.035 * side, 0.305, 0.095))
		_prim(_cyl(0.014, 0.012, 0.13, 5), xf, ROPE)
		_prim(_sph(0.022, 6, 3), xf * Transform3D(Basis.IDENTITY, Vector3(0.0, -0.07, 0.0)), ROPE.darkened(0.15))


func _mouth_coins() -> void:
	var lean := _lean()
	# Coins spilling over the lip of the mouth, tilted every way.
	var spots := [[Vector3(0.03, 0.43, 0.02), Vector3(35, 10, 20)], [Vector3(-0.05, 0.425, -0.02), Vector3(-25, 40, -30)],
			[Vector3(0.07, 0.415, -0.05), Vector3(60, -20, 10)], [Vector3(-0.01, 0.44, 0.06), Vector3(-50, 70, 15)],
			[Vector3(0.10, 0.40, 0.04), Vector3(20, 0, -70)]]
	var cols := [GOLD_A, GOLD_B, GOLD_C, GOLD_A, GOLD_B]
	for i in spots.size():
		var sp: Array = spots[i]
		var rot: Vector3 = sp[1]
		_prim(_coin(), lean * Transform3D(Basis.from_euler(rot * PI / 180.0), sp[0]), cols[i])
	# Stitched coin patch on the belly (faces the RTS camera, +z), with a raised rim.
	var patch := lean * Transform3D(Basis.from_euler(Vector3(deg_to_rad(90.0), 0.0, 0.0)), Vector3(0.02, 0.17, 0.252))
	_prim(_cyl(0.075, 0.075, 0.016, 12), patch, GOLD_B)
	_prim(_cyl(0.05, 0.05, 0.022, 10), patch, GOLD_C)


func _spill() -> void:
	# Loose coins on the ground toward +x (the lean side) and a little stack.
	var loose := [[Vector3(0.24, 0.012, 0.08), Vector3(4, 20, 3)], [Vector3(0.33, 0.012, -0.06), Vector3(-5, 70, 0)],
			[Vector3(0.40, 0.012, 0.13), Vector3(0, 10, 6)], [Vector3(0.30, 0.03, 0.2), Vector3(18, 45, 0)],
			[Vector3(0.48, 0.012, 0.0), Vector3(3, 0, -4)], [Vector3(0.18, 0.012, 0.24), Vector3(0, 30, 0)],
			[Vector3(0.52, 0.012, 0.22), Vector3(-6, 80, 0)], [Vector3(0.14, 0.02, -0.2), Vector3(10, 15, 12)]]
	var cols := [GOLD_A, GOLD_B, GOLD_C, GOLD_A, GOLD_B, GOLD_A, GOLD_C, GOLD_B]
	for i in loose.size():
		var sp: Array = loose[i]
		var rot: Vector3 = sp[1]
		_prim(_coin(), Transform3D(Basis.from_euler(rot * PI / 180.0), sp[0]), cols[i])
	for k in 3:
		var p := Vector3(0.38 + 0.006 * float(k), 0.01 + 0.019 * float(k), -0.17 + 0.004 * float(k))
		_prim(_coin(), Transform3D(Basis.from_euler(Vector3(0.0, float(k) * 0.7, 0.0)), p),
				GOLD_B if k % 2 == 0 else GOLD_A)
	# One coin rolled up on its edge against the sack.
	_prim(_coin(), Transform3D(Basis.from_euler(Vector3(0.0, deg_to_rad(-30.0), deg_to_rad(75.0))),
			Vector3(0.2, 0.055, -0.05)), GOLD_C)


func _coin() -> CylinderMesh:
	return _cyl(0.058, 0.058, 0.018, 10)


# ---------------------------------------------------------------- scene parts

func _decal(root: Node3D) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(1.2, 1.1)
	var g := Gradient.new()
	g.set_color(0, Color(0.05, 0.035, 0.02, 0.55))
	g.set_color(1, Color(0.05, 0.035, 0.02, 0.0))
	g.add_point(0.5, Color(0.05, 0.035, 0.02, 0.3))
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
	_mi(root, pm, "ContactShadow", Vector3(0.1, 0.015, 0.0))


func _glow(root: Node3D) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(2.0, 2.0)
	var m := ShaderMaterial.new()
	m.shader = load("res://art/vfx/trade_loot_sack_glow.gdshader") as Shader
	pm.material = m
	var mi := _mi(root, pm, "Glow", Vector3(0.1, 0.025, 0.0))
	mi.scale = Vector3(0.95, 1.0, 0.95)


func _particles(root: Node3D) -> void:
	var star := _star_tex()
	var dot := _dot_tex()
	# Glints: a few gold sparkles twinkling over the mouth and the spill (continuous, local).
	var gm := ParticleProcessMaterial.new()
	gm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	gm.emission_box_extents = Vector3(0.3, 0.2, 0.25)
	gm.direction = Vector3.UP
	gm.spread = 20.0
	gm.initial_velocity_min = 0.1
	gm.initial_velocity_max = 0.35
	gm.gravity = Vector3.ZERO
	gm.scale_min = 0.16
	gm.scale_max = 0.3
	gm.scale_curve = _curve([Vector2(0.0, 0.0), Vector2(0.35, 1.0), Vector2(1.0, 0.0)])
	gm.color_ramp = _ramp([Color(2.6, 2.2, 1.2, 1.0), Color(2.2, 1.7, 0.6, 1.0)])
	var glints := _emitter(root, "Glints", Vector3(0.12, 0.3, 0.0), 5, 1.3, false, gm, _pquad(star, true))
	glints.emitting = true
	# Dust puff when it lands.
	var dm := ParticleProcessMaterial.new()
	dm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	dm.emission_ring_axis = Vector3.UP
	dm.emission_ring_radius = 0.25
	dm.emission_ring_inner_radius = 0.18
	dm.emission_ring_height = 0.02
	dm.direction = Vector3.UP
	dm.spread = 70.0
	dm.initial_velocity_min = 0.4
	dm.initial_velocity_max = 0.9
	dm.radial_velocity_min = 0.8
	dm.radial_velocity_max = 1.6
	dm.damping_min = 2.0
	dm.damping_max = 3.0
	dm.angle_min = -180.0
	dm.angle_max = 180.0
	dm.scale_min = 0.25
	dm.scale_max = 0.45
	dm.scale_curve = _curve([Vector2(0.0, 0.4), Vector2(0.3, 1.0), Vector2(1.0, 1.1)])
	var dust := Color(0.58, 0.49, 0.35)
	dm.color_ramp = _ramp([Color(dust, 0.0), Color(dust, 0.55), Color(dust, 0.0)])
	_emitter(root, "Dust", Vector3(0.0, 0.05, 0.0), 10, 0.6, true, dm, _pquad(dot, false))
	# Gold sparkle when it lands.
	var bm := ParticleProcessMaterial.new()
	bm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	bm.emission_sphere_radius = 0.25
	bm.direction = Vector3.UP
	bm.spread = 50.0
	bm.initial_velocity_min = 0.8
	bm.initial_velocity_max = 1.8
	bm.damping_min = 1.5
	bm.damping_max = 2.5
	bm.scale_min = 0.16
	bm.scale_max = 0.3
	bm.scale_curve = _curve([Vector2(0.0, 0.3), Vector2(0.3, 1.0), Vector2(1.0, 0.2)])
	bm.color_ramp = _ramp([Color(2.8, 2.5, 1.6, 1.0), Color(2.2, 1.7, 0.6, 1.0), Color(1.2, 0.8, 0.3, 0.0)])
	_emitter(root, "Burst", Vector3(0.0, 0.3, 0.0), 12, 0.7, true, bm, _pquad(star, true))


func _emitter(root: Node3D, name: String, pos: Vector3, amount: int, life: float, one_shot: bool,
		ppm: ParticleProcessMaterial, draw: Mesh) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = name
	p.position = pos
	p.amount = amount
	p.lifetime = life
	p.one_shot = one_shot
	p.emitting = false
	p.explosiveness = 0.9 if one_shot else 0.0
	p.randomness = 0.5
	p.local_coords = true
	p.process_material = ppm
	p.draw_pass_1 = draw
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-1.5, -0.5, -1.5), Vector3(3.0, 3.0, 3.0))
	root.add_child(p)
	return p


## Billboard particle quad: ADD (glints) or MIX (dust), shape mask, keep_scale, colour from the particle colour.
func _pquad(tex: Texture2D, add: bool) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if add else BaseMaterial3D.BLEND_MODE_MIX
	sm.disable_fog = add  # G-E 5: an additive quad must not fog
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sm.billboard_keep_scale = true
	sm.vertex_color_use_as_albedo = true
	sm.albedo_texture = tex
	sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	sm.disable_receive_shadows = true
	q.material = sm
	return q


func _star_tex() -> ImageTexture:
	var n := 32
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (float(x) + 0.5) / float(n) * 2.0 - 1.0
			var v := (float(y) + 0.5) / float(n) * 2.0 - 1.0
			var r := sqrt(u * u + v * v)
			var core := clampf(1.0 - r / 0.32, 0.0, 1.0)
			var ray := maxf(clampf(1.0 - absf(u) / 0.1, 0.0, 1.0) * clampf(1.0 - absf(v), 0.0, 1.0),
					clampf(1.0 - absf(v) / 0.1, 0.0, 1.0) * clampf(1.0 - absf(u), 0.0, 1.0))
			var a := clampf(core * core * 1.2 + ray * ray, 0.0, 1.0) * clampf((1.0 - r) / 0.2, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _dot_tex() -> ImageTexture:
	var n := 32
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (float(x) + 0.5) / float(n) * 2.0 - 1.0
			var v := (float(y) + 0.5) / float(n) * 2.0 - 1.0
			var a := clampf(1.0 - sqrt(u * u + v * v), 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a * (3.0 - 2.0 * a)))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _curve(points: Array) -> CurveTexture:
	var cv := Curve.new()
	for p: Vector2 in points:
		cv.add_point(p)
	var ct := CurveTexture.new()
	ct.curve = cv
	return ct


func _ramp(colors: Array) -> GradientTexture1D:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	for i in colors.size():
		offs.append(float(i) / float(colors.size() - 1))
	g.offsets = offs
	g.colors = PackedColorArray(colors)
	var gt := GradientTexture1D.new()
	gt.gradient = g
	gt.use_hdr = true
	return gt


# ---------------------------------------------------------------- mesh building

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


func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


## One flat-shaded triangle facing `out`, with a slight value jitter.
func _tri(a: Vector3, b: Vector3, c: Vector3, col: Color, out: Vector3) -> void:
	var fn := (b - a).cross(c - a)
	if fn.length_squared() < 1e-14:
		return
	var s := 1.0 if fn.dot(out) >= 0.0 else -1.0
	if s != _conv:
		var tmp := b
		b = c
		c = tmp
	var nn := fn.normalized() * s
	var k := 1.0 + (_h(((a + b + c) / 3.0).snappedf(0.001)) - 0.5) * 0.10
	var fc := Color(col.r * k, col.g * k, col.b * k)
	for p: Vector3 in [a, b, c]:
		_v.append(p)
		_n.append(nn)
		_c.append(fc)


func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, out: Vector3) -> void:
	_tri(a, b, c, col, out)
	_tri(a, c, d, col, out)


## Adds a primitive, transformed, flat-shaded, in one colour.
func _prim(m: PrimitiveMesh, xf: Transform3D, col: Color) -> void:
	var arr: Array = m.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var nb: Basis = xf.basis.inverse().transposed()
	for t in range(0, idx.size(), 3):
		var a: int = idx[t]
		var b: int = idx[t + 1]
		var c: int = idx[t + 2]
		_tri(xf * v[a], xf * v[b], xf * v[c], col, nb * (n[a] + n[b] + n[c]))


## Commits the buffers: COLOR.a = height gradient over the mesh, UV.y = height + `y_lift` (env_painted's dark
## contact band only touches the very bottom of this small prop).
func _commit(mat: Material, y_lift: float) -> ArrayMesh:
	var miny := INF
	var maxy := -INF
	for p in _v:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var span := maxf(maxy - miny, 0.01)
	var uv := PackedVector2Array()
	uv.resize(_v.size())
	for i in _v.size():
		var cc := _c[i]
		cc.a = clampf((_v[i].y - miny) / span, 0.0, 1.0)
		_c[i] = cc
		uv[i] = Vector2(0.0, _v[i].y + y_lift)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _v
	arrays[Mesh.ARRAY_NORMAL] = _n
	arrays[Mesh.ARRAY_COLOR] = _c
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, mat)
	print("mesh: %d tris, y %.2f..%.2f" % [_v.size() / 3, miny, maxy])
	return mesh


func _mi(parent: Node3D, mesh: Mesh, name: String, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.position = pos
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # tiny, bobbing: no shadow (budget)
	parent.add_child(mi)
	return mi


func _own(n: Node, root: Node) -> void:
	for ch in n.get_children():
		ch.owner = root
		_own(ch, root)


func _cyl(top: float, bottom: float, h: float, segs: int = 8) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = segs
	m.rings = 0
	return m


func _sph(r: float, segs: int = 8, rings: int = 4) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segs
	m.rings = rings
	return m


func _torus(inner: float, outer: float, rings: int = 12, segs: int = 6) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = rings
	m.ring_segments = segs
	return m
