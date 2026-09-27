extends SceneTree
## Task 13c.V9: generates art/environment/lairs/icebound_barge.tscn, the Frost Wyrm's lair (see icebound_barge.gd):
## a draw-only overlay on the Drowned Barge landmark (landmarks/barge.tscn stays untouched), authored in the BARGE's
## space (the barge builder's `_barge_pre()` is copied here so every icicle hangs from the real spar / gunwale / eave).
##   meshes/icebound_crust.res  icicles, mast sheath, snow caps, hull frost glaze, ice plates (ONE surface,
##                              icebound_crust_mat.tres; COLOR / UV / CUSTOM0 as in icebound_crust.gdshader)
##   icebound_sheet_mat.tres    the ice sheet r 5 on the water (a PlaneMesh at the water line + 5 cm)
##   icebound_rime_mat.tres     hoarfrost on the banks (a PlaneMesh just over the bank tops, depth-hugging)
##   Vapour                     one GPUParticles3D (10 soft puffs rising off the ice, local coords, 30 fps, < 80 m)
## 0 lights, no collider, no shadows, every material a saved resource. Re-run after a change:
##   $GODOT --headless --path . -s res://art/environment/lairs/build_icebound_barge.gd --quit-after 300

const LDIR := "res://art/environment/lairs/"
const MESH_DIR := "res://art/environment/lairs/meshes/"
const SCRIPT_PATH := "res://art/environment/lairs/icebound_barge.gd"

# The barge (art/environment/landmarks/build_landmarks_b.gd, DROWNED BARGE): stations, deck, mast, spar, yard.
const BG_STATIONS: Array = [
	[-3.2, 0.72, 0.96, 0.34, 1.16],
	[-2.6, 0.95, 1.12, 0.08, 1.03],
	[-1.4, 1.0, 1.17, 0.0, 0.99],
	[0.0, 1.0, 1.17, 0.0, 0.98],
	[1.4, 0.98, 1.15, 0.02, 1.02],
	[2.4, 0.8, 1.03, 0.2, 1.12],
	[3.2, 0.46, 0.72, 0.55, 1.3],
]
const DECK_Y := 0.72
const WATER_Y := -0.35
const MAST_FOOT := Vector3(-0.2, DECK_Y, 0.55)
const MAST_TOP := Vector3(-0.32, DECK_Y + 2.45, 0.42)
const SPAR_A := Vector3(0.15, DECK_Y + 1.55, 0.7)
const SPAR_B := Vector3(2.05, -0.1, 2.3)
## The river's flow in the barge's space (it runs at 18.4 deg there): the ice drifts are streaked along it.
const FLOW_YAW := 0.3211

# Palette (sRGB).
const ICE := Color(0.70, 0.86, 0.96)
const ICE_DEEP := Color(0.46, 0.68, 0.86)
const ICE_WHITE := Color(0.86, 0.93, 0.99)
const SNOW := Color(0.93, 0.95, 0.99)
const SNOW_SHADE := Color(0.84, 0.89, 0.97)
const FROST := Color(0.80, 0.88, 0.95)

var _conv := 1.0
var _pre := Transform3D.IDENTITY
var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _uv := PackedVector2Array()
var _cu := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()
var _counts := {"icicles": 0, "snow": 0, "plates": 0}


func _initialize() -> void:
	_rng.seed = 13009
	_detect_winding()
	var b := Basis(Vector3.UP, deg_to_rad(28.4)) * Basis(Vector3.RIGHT, deg_to_rad(-15.0)) \
			* Basis(Vector3.BACK, deg_to_rad(-10.0))
	_pre = Transform3D(b, Vector3(0.0, -0.95, 0.0))
	_build_crust()
	var crust := _commit()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	var err := ResourceSaver.save(crust, MESH_DIR + "icebound_crust.res")
	print("crust mesh: %d tris, icicles %d, snow %d, plates %d (save %d)" % [_v.size() / 3, _counts["icicles"],
			_counts["snow"], _counts["plates"], err])
	var crust_mat := ShaderMaterial.new()
	crust_mat.shader = load(LDIR + "icebound_crust.gdshader")
	ResourceSaver.save(crust_mat, LDIR + "icebound_crust_mat.tres")
	var sheet_mat := ShaderMaterial.new()
	sheet_mat.shader = load(LDIR + "icebound_sheet.gdshader")
	ResourceSaver.save(sheet_mat, LDIR + "icebound_sheet_mat.tres")
	var rime_mat := ShaderMaterial.new()
	rime_mat.shader = load(LDIR + "icebound_rime.gdshader")
	ResourceSaver.save(rime_mat, LDIR + "icebound_rime_mat.tres")
	_scene(load(MESH_DIR + "icebound_crust.res") as Mesh, load(LDIR + "icebound_crust_mat.tres") as Material,
			load(LDIR + "icebound_sheet_mat.tres") as Material, load(LDIR + "icebound_rime_mat.tres") as Material)
	quit()


func _detect_winding() -> void:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	_conv = 1.0 if (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]]).dot(n[idx[0]]) >= 0.0 else -1.0


# ---------------------------------------------------------------- the scene

func _scene(crust: Mesh, crust_mat: Material, sheet_mat: Material, rime_mat: Material) -> void:
	var root := Node3D.new()
	root.name = "IceboundBarge"
	root.set_script(load(SCRIPT_PATH))
	root.add_to_group(&"lairs", true)
	root.set_meta(&"lair_kind", &"frost_wyrm")
	root.set_meta(&"beast_rest", Vector3.ZERO)
	root.set_meta(&"decor_clear", PackedVector3Array([Vector3(0.0, 0.0, 5.5)]))
	var active := Node3D.new()
	active.name = "Active"
	active.visible = false
	root.add_child(active)
	active.owner = root
	var sheet := MeshInstance3D.new()
	sheet.name = "Sheet"
	var pm := PlaneMesh.new()
	pm.size = Vector2(12.0, 12.0)
	sheet.mesh = pm
	sheet.material_override = sheet_mat
	sheet.position = Vector3(0.0, WATER_Y + 0.05, 0.0)
	sheet.rotation.y = FLOW_YAW
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sheet.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	active.add_child(sheet)
	sheet.owner = root
	var rime := MeshInstance3D.new()
	rime.name = "Rime"
	var rm := PlaneMesh.new()
	rm.size = Vector2(14.0, 14.0)
	rime.mesh = rm
	rime.material_override = rime_mat
	rime.position = Vector3(0.0, 0.05, 0.0)
	rime.rotation.y = FLOW_YAW
	rime.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rime.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	rime.visibility_range_end = 95.0
	rime.visibility_range_end_margin = 8.0
	rime.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	active.add_child(rime)
	rime.owner = root
	var cm := MeshInstance3D.new()
	cm.name = "Crust"
	cm.mesh = crust
	cm.material_override = crust_mat
	cm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cm.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	cm.visibility_range_end = 95.0
	cm.visibility_range_end_margin = 8.0
	cm.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	cm.extra_cull_margin = 1.0   # icicles collapse into their roots at freeze 0 (shader)
	active.add_child(cm)
	cm.owner = root
	var vap := _vapour()
	active.add_child(vap)
	vap.owner = root
	var ps := PackedScene.new()
	var err := ps.pack(root)
	var err2 := ResourceSaver.save(ps, LDIR + "icebound_barge.tscn")
	print("icebound_barge.tscn: pack %d, save %d" % [err, err2])
	root.free()


func _vapour() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Vapour"
	p.amount = 10
	p.lifetime = 4.5
	p.fixed_fps = 30
	p.interpolate = true
	p.local_coords = true
	p.emitting = false
	p.position = Vector3(0.0, WATER_Y + 0.1, 0.0)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-6.0, -1.0, -6.0), Vector3(12.0, 6.0, 12.0))
	p.visibility_range_end = 80.0
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	m.emission_ring_axis = Vector3.UP
	m.emission_ring_radius = 3.8
	m.emission_ring_inner_radius = 1.2
	m.emission_ring_height = 0.1
	m.direction = Vector3.UP
	m.spread = 20.0
	m.initial_velocity_min = 0.2
	m.initial_velocity_max = 0.45
	m.gravity = Vector3(0.0, 0.03, 0.0)
	m.damping_min = 0.05
	m.damping_max = 0.1
	m.angle_min = -180.0
	m.angle_max = 180.0
	m.angular_velocity_min = -12.0
	m.angular_velocity_max = 12.0
	m.scale_min = 1.3
	m.scale_max = 2.3
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.35))
	c.add_point(Vector2(0.4, 0.9))
	c.add_point(Vector2(1.0, 1.1))
	var ct := CurveTexture.new()
	ct.curve = c
	m.scale_curve = ct
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	g.colors = PackedColorArray([Color(0.9, 0.95, 1.0, 0.0), Color(0.9, 0.95, 1.0, 0.24),
			Color(0.88, 0.93, 1.0, 0.16), Color(0.88, 0.93, 1.0, 0.0)])
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_ramp = gt
	p.process_material = m
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.disable_receive_shadows = true
	mat.proximity_fade_enabled = true
	mat.proximity_fade_distance = 0.5
	var rg := Gradient.new()
	rg.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	rg.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = rg
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	mat.albedo_texture = tex
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	q.material = mat
	p.draw_pass_1 = q
	return p


# ---------------------------------------------------------------- the crust

func _build_crust() -> void:
	# 1. Ice plates jammed against the hull at the water line (pressure ridge), in the root's space (yaw only).
	var yaw := deg_to_rad(28.4)
	for i in 8:
		var a := float(i) / 8.0 * TAU + _rng.randf_range(-0.15, 0.15)
		var local := Vector3(cos(a) * 1.55, 0.0, sin(a) * 3.35)
		var p := Basis(Vector3.UP, yaw) * local
		var out := (Basis(Vector3.UP, yaw) * Vector3(cos(a) / 1.55, 0.0, sin(a) / 3.35)).normalized()
		var size := Vector3(_rng.randf_range(0.4, 0.7), 0.16, _rng.randf_range(0.3, 0.5))
		var tilt := _rng.randf_range(0.25, 0.6)
		var side := out.cross(Vector3.UP).normalized()
		var bb := Basis(side, tilt) * Basis(Vector3.UP, atan2(out.x, out.z))
		var centre := p + out * 0.15 + Vector3.UP * (WATER_Y + 0.12)
		_box(centre, size, bb, ICE.lerp(ICE_DEEP, _rng.randf() * 0.6), 0, centre - Vector3.UP * 0.5, _rng.randf_range(0.0, 0.2))
		_counts["plates"] += 1
	# 2. Frost glaze down the upper hull (both sides), from the gunwale.
	_frost_band()
	# 3. The ice sheath up the mast stub, dripping.
	_sheath(MAST_FOOT + Vector3(0, 0.05, 0), MAST_FOOT.lerp(MAST_TOP, 0.88), 0.215, 0.19, 0.2)
	# 4. Snow on the cabin roof, the crates, the barrels, the deck, the fallen spar, the bow post.
	for rs: float in [-1.0, 1.0]:
		var rb := Basis.from_euler(Vector3(0.0, 0.0, -rs * 0.34))
		var rc := Vector3(rs * 0.46, DECK_Y + 1.02, -2.35)
		_snow(rc + rb * Vector3(0.0, 0.05, 0.0), Vector3(0.5, 0.1, 0.8), rb, 0.35)
	_snow(Vector3(0.0, DECK_Y + 1.24, -2.35), Vector3(0.12, 0.08, 0.85), Basis.IDENTITY, 0.38)   # ridge
	for cr: Array in [[Vector3(0.05, DECK_Y + 0.62, 2.45), 0.62], [Vector3(0.15, DECK_Y + 1.06, 2.4), 0.46],
			[Vector3(-0.6, DECK_Y + 0.5, 0.0), 0.5]]:
		var s: float = cr[1]
		_snow((cr[0] as Vector3) + Vector3(0, 0.02, 0), Vector3(s * 0.52, 0.09, s * 0.52), Basis.IDENTITY, 0.45)
	for br: Vector3 in [Vector3(0.45, DECK_Y + 0.6, 1.9), Vector3(-0.2, DECK_Y + 0.6, 1.6), Vector3(0.52, DECK_Y + 0.6, 1.32)]:
		_snow(br + Vector3(0, 0.02, 0), Vector3(0.25, 0.08, 0.25), Basis.IDENTITY, 0.5)
	for dk: Vector3 in [Vector3(-0.78, DECK_Y + 0.03, -1.0), Vector3(-0.8, DECK_Y + 0.03, 1.9), Vector3(0.82, DECK_Y + 0.03, 2.1),
			Vector3(-0.35, DECK_Y + 0.03, 2.75), Vector3(-0.75, DECK_Y + 0.03, -0.5)]:
		_snow(dk, Vector3(0.22, 0.07, 0.42), Basis(Vector3.UP, _rng.randf_range(-0.3, 0.3)), 0.4)
	for k in 5:
		var t := 0.08 + float(k) * 0.16
		var sp := SPAR_A.lerp(SPAR_B, t)
		if (_pre * sp).y < WATER_Y + 0.25:
			continue
		_snow(sp + Vector3(0, 0.1, 0), Vector3(0.12, 0.06, 0.26), _along_basis(SPAR_A, SPAR_B), 0.5)
	_snow(Vector3(0.0, 2.2, 3.26), Vector3(0.13, 0.08, 0.16), Basis.IDENTITY, 0.5)
	# 5. Icicles (world-down in the root's space).
	# The mast top: a ring hanging round the jagged break, one long drip down the sheath.
	var mt := _pre * MAST_TOP
	for i in 6:
		var a := float(i) / 6.0 * TAU + 0.3
		var root := mt + Vector3(cos(a) * 0.2, -0.15 - _rng.randf() * 0.1, sin(a) * 0.2)
		_icicle(root, _rng.randf_range(0.35, 0.8), _rng.randf_range(0.05, 0.075))
	# The fallen spar and the yard (undersides).
	for k in 9:
		var t := 0.06 + float(k) * 0.1 + _rng.randf_range(-0.03, 0.03)
		var sp := _pre * SPAR_A.lerp(SPAR_B, t) - Vector3.UP * 0.1
		_icicle(sp, _rng.randf_range(0.3, 0.75), _rng.randf_range(0.045, 0.07))
	var yard_c := SPAR_A.lerp(SPAR_B, 0.45)
	var ya := yard_c + Vector3(-0.35, 0.18, 1.3)
	var yb := yard_c + Vector3(0.45, -0.25, -1.25)
	for k in 7:
		var t := 0.05 + float(k) * 0.14
		var yp := _pre * ya.lerp(yb, t) - Vector3.UP * 0.07
		_icicle(yp, _rng.randf_range(0.25, 0.6), _rng.randf_range(0.04, 0.06))
	# The gunwales, outside the rail, where it stands above the water.
	for side: float in [-1.0, 1.0]:
		var z := -3.0
		while z < 3.1:
			var g := _gunwale_at(z)
			var gp := Vector3(side * (float(g.x) + 0.05), float(g.y) + 0.02, z)
			var wp := _pre * gp
			var len := _rng.randf_range(0.25, 0.7)
			if wp.y - len > WATER_Y + 0.08:
				_icicle(wp, len, _rng.randf_range(0.045, 0.07))
			elif wp.y - 0.2 > WATER_Y + 0.05:
				_icicle(wp, wp.y - WATER_Y - 0.08, 0.05)
			z += _rng.randf_range(0.28, 0.42)
	# The cabin eaves.
	for rs: float in [-1.0, 1.0]:
		var rb := Basis.from_euler(Vector3(0.0, 0.0, -rs * 0.34))
		var rc := Vector3(rs * 0.46, DECK_Y + 1.02, -2.35)
		for k in 6:
			var ez := -0.72 + float(k) * 0.29 + _rng.randf_range(-0.05, 0.05)
			var ep := _pre * (rc + rb * Vector3(rs * 0.52, -0.05, ez))
			if ep.y - 0.3 > WATER_Y + 0.05:
				_icicle(ep, _rng.randf_range(0.25, 0.55), _rng.randf_range(0.045, 0.065))
	# The bow post and the stovepipe.
	for bp: Vector3 in [Vector3(0.06, 2.02, 3.36), Vector3(-0.07, 2.0, 3.3), Vector3(0.0, 1.62, 3.25)]:
		_icicle(_pre * bp, _rng.randf_range(0.3, 0.5), 0.05)
	_icicle(_pre * Vector3(0.72, DECK_Y + 1.74, -2.95), 0.3, 0.045)


## Outer gunwale (half-beam, height) at station z.
func _gunwale_at(z: float) -> Vector2:
	for k in BG_STATIONS.size() - 1:
		var a: Array = BG_STATIONS[k]
		var b: Array = BG_STATIONS[k + 1]
		if z >= float(a[0]) and z <= float(b[0]):
			var t := (z - float(a[0])) / (float(b[0]) - float(a[0]))
			return Vector2(lerpf(float(a[2]), float(b[2]), t), lerpf(float(a[4]), float(b[4]), t))
	var e: Array = BG_STATIONS[0] if z < 0.0 else BG_STATIONS[BG_STATIONS.size() - 1]
	return Vector2(float(e[2]), float(e[4]))


## The hull side from the gunwale down (5 outline points per side, as the barge builder's _station, pushed out).
func _hull_side(s: Array, side: float) -> Array[Vector3]:
	var z: float = s[0]
	var b: float = s[1]
	var g: float = s[2]
	var yb: float = s[3]
	var yg: float = s[4]
	var out: Array[Vector3] = []
	for k in 5:
		var t := k / 4.0
		var x := lerpf(g, b, t) + 0.035
		out.append(Vector3(side * x, lerpf(yg, yb + 0.05, t * t * 0.3 + t * 0.7), z))
	return out


func _frost_band() -> void:
	for side: float in [-1.0, 1.0]:
		for k in BG_STATIONS.size() - 1:
			var a := _hull_side(BG_STATIONS[k], side)
			var b := _hull_side(BG_STATIONS[k + 1], side)
			for i in 3:
				var p00 := _pre * a[i]
				var p01 := _pre * a[i + 1]
				var p10 := _pre * b[i]
				var p11 := _pre * b[i + 1]
				var inside := _pre * Vector3(0.0, 0.6, (float(BG_STATIONS[k][0]) + float(BG_STATIONS[k + 1][0])) * 0.5)
				var root := (_pre * a[0] + _pre * b[0]) * 0.5
				var r0 := float(i) / 3.0
				var r1 := float(i + 1) / 3.0
				var d := 0.1 + 0.15 * _rng.randf()
				_tri_flat(p00, p01, p11, inside, FROST, 2, [r0, r1, r1], root, d)
				_tri_flat(p00, p11, p10, inside, FROST, 2, [r0, r1, r0], root, d)


## An icicle hanging straight down from `root`: a faceted cone with a kink, a cap on top (seen from above).
func _icicle(root: Vector3, length: float, r: float) -> void:
	var sides := 5
	var delay := _rng.randf_range(0.45, 1.0)
	var col := ICE.lerp(ICE_WHITE, _rng.randf_range(0.0, 0.6))
	var kink := Vector3(_rng.randf_range(-0.03, 0.03), 0.0, _rng.randf_range(-0.03, 0.03))
	var mid_y := -length * 0.42
	var tip := root + Vector3(kink.x * 1.5, -length, kink.z * 1.5)
	var top: Array[Vector3] = []
	var mid: Array[Vector3] = []
	var a0 := _rng.randf() * TAU
	for k in sides:
		var a := a0 + float(k) / float(sides) * TAU
		var d := Vector3(cos(a), 0.0, sin(a))
		top.append(root + d * r * _rng.randf_range(0.85, 1.15) + Vector3.UP * 0.03)
		mid.append(root + kink + d * r * 0.5 + Vector3.UP * mid_y)
	var axis_in := root + Vector3.UP * (mid_y * 0.5)
	for k in sides:
		var k2 := (k + 1) % sides
		_tri_flat(top[k], top[k2], mid[k2], axis_in, col, 0, [0.0, 0.0, 0.0], root, delay)
		_tri_flat(top[k], mid[k2], mid[k], axis_in, col, 0, [0.0, 0.0, 0.0], root, delay)
		_tri_flat(mid[k], mid[k2], tip, root + kink + Vector3.UP * (mid_y - 0.05), col.darkened(0.05), 0,
				[0.0, 0.0, 0.0], root, delay)
		_tri_flat(top[k], top[k2], root + Vector3.UP * 0.06, root - Vector3.UP * 0.2, ICE_WHITE, 0, [0.0, 0.0, 0.0],
				root, delay)
	_counts["icicles"] += 1


## A bumpy ice tube round the mast from a to b (pre-space points), a cap at the top, drips at the bottom.
func _sheath(a: Vector3, b: Vector3, r0: float, r1: float, delay: float) -> void:
	var pa := _pre * a
	var pb := _pre * b
	var axis := (pb - pa).normalized()
	var x := axis.cross(Vector3.FORWARD).normalized()
	var z := x.cross(axis).normalized()
	var sides := 8
	var rings := 7
	var grid: Array = []
	for j in rings + 1:
		var t := float(j) / float(rings)
		var c := pa.lerp(pb, t)
		var row: Array[Vector3] = []
		for k in sides:
			var ang := float(k) / float(sides) * TAU
			var bump := 1.0 + 0.18 * sin(ang * 3.0 + t * 7.0) + _rng.randf_range(-0.06, 0.08)
			var rr := lerpf(r0, r1, t) * bump
			row.append(c + (x * cos(ang) + z * sin(ang)) * rr)
		grid.append(row)
	var col := ICE_DEEP.lerp(ICE, 0.25)
	for j in rings:
		for k in sides:
			var k2 := (k + 1) % sides
			var c0 := pa.lerp(pb, (float(j) + 0.5) / float(rings))
			_tri_flat(grid[j][k], grid[j][k2], grid[j + 1][k2], c0, col, 0, [0.0, 0.0, 0.0], pa, delay)
			_tri_flat(grid[j][k], grid[j + 1][k2], grid[j + 1][k], c0, col, 0, [0.0, 0.0, 0.0], pa, delay)
	var top_c := pb + axis * 0.08
	for k in sides:
		_tri_flat(grid[rings][k], grid[rings][(k + 1) % sides], top_c, pb - axis * 0.2, ICE_WHITE, 0,
				[0.0, 0.0, 0.0], pa, delay)
	# Drips hanging off the lower rim.
	for k in 4:
		var bot: Vector3 = grid[1][k * 2]
		_icicle(bot + Vector3.UP * 0.02, _rng.randf_range(0.2, 0.4), 0.05)


## A snow cap: a squashed dome (radii in `basis`), smooth normals, grows from its foot.
func _snow(centre_pre: Vector3, radii: Vector3, basis: Basis, delay: float) -> void:
	var segs := 8
	var rings := 3
	var c := _pre * centre_pre
	var bw := _pre.basis * basis
	var up := (bw * Vector3.UP).normalized()
	var pts: Array = []
	var nrm: Array = []
	for j in rings + 1:
		var phi := float(j) / float(rings) * PI * 0.5   # 0 at the rim -> PI/2 at the top
		var row: Array[Vector3] = []
		var nrow: Array[Vector3] = []
		for k in segs:
			var th := float(k) / float(segs) * TAU
			var wob := 1.0 + _rng.randf_range(-0.12, 0.1) * (1.0 if j < rings else 0.0)
			var lp := Vector3(cos(th) * cos(phi) * radii.x * wob, sin(phi) * radii.y, sin(th) * cos(phi) * radii.z * wob)
			row.append(c + bw * lp)
			var ln := Vector3(cos(th) * cos(phi) / radii.x, sin(phi) / radii.y, sin(th) * cos(phi) / radii.z)
			nrow.append((bw.inverse().transposed() * ln).normalized())
		pts.append(row)
		nrm.append(nrow)
	var root := c
	var col := SNOW.lerp(SNOW_SHADE, _rng.randf() * 0.4)
	for j in rings:
		for k in segs:
			var k2 := (k + 1) % segs
			_tri_n(pts[j][k], pts[j][k2], pts[j + 1][k2], nrm[j][k], nrm[j][k2], nrm[j + 1][k2], col, 1, root, delay)
			_tri_n(pts[j][k], pts[j + 1][k2], pts[j + 1][k], nrm[j][k], nrm[j + 1][k2], nrm[j + 1][k], col, 1, root,
					delay)
	# Underside: a flat disc slightly below the rim (never seen through).
	var under := c - up * 0.015
	for k in segs:
		_tri_flat(pts[0][k], pts[0][(k + 1) % segs], under, c + up * 0.5, col.darkened(0.1), 1, [0.0, 0.0, 0.0],
				root, delay)
	_counts["snow"] += 1


## An ice slab (box) at `centre` with `size` in `basis`, flat faces.
func _box(centre: Vector3, size: Vector3, basis: Basis, col: Color, kind: int, root: Vector3, delay: float) -> void:
	var h := size * 0.5
	var corners: Array[Vector3] = []
	for i in 8:
		var sx := -1.0 if (i & 1) == 0 else 1.0
		var sy := -1.0 if (i & 2) == 0 else 1.0
		var sz := -1.0 if (i & 4) == 0 else 1.0
		var jitter := Vector3(_rng.randf_range(-0.04, 0.04), 0.0, _rng.randf_range(-0.04, 0.04))
		corners.append(centre + basis * (Vector3(sx * h.x, sy * h.y, sz * h.z) + jitter))
	var faces := [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]]
	for f: Array in faces:
		var q0: Vector3 = corners[f[0]]
		var q1: Vector3 = corners[f[1]]
		var q2: Vector3 = corners[f[2]]
		var q3: Vector3 = corners[f[3]]
		_tri_flat(q0, q1, q2, centre, col, kind, [0.0, 0.0, 0.0], root, delay)
		_tri_flat(q0, q2, q3, centre, col, kind, [0.0, 0.0, 0.0], root, delay)


func _along_basis(a: Vector3, b: Vector3) -> Basis:
	var z := (b - a).normalized()
	var x := Vector3.UP.cross(z).normalized()
	var y := z.cross(x).normalized()
	return Basis(x, y, z)


## One triangle with a flat normal turned away from `inside`, wound for the engine's front faces.
func _tri_flat(p0: Vector3, p1: Vector3, p2: Vector3, inside: Vector3, col: Color, kind: int, rag: Array,
		root: Vector3, delay: float) -> void:
	var n := (p1 - p0).cross(p2 - p0)
	if n.length_squared() < 1e-12:
		return
	n = n.normalized()
	if n.dot((p0 + p1 + p2) / 3.0 - inside) < 0.0:
		n = -n
	_emit(p0, p1, p2, n, n, n, col, kind, rag, root, delay)


func _tri_n(p0: Vector3, p1: Vector3, p2: Vector3, n0: Vector3, n1: Vector3, n2: Vector3, col: Color, kind: int,
		root: Vector3, delay: float) -> void:
	_emit(p0, p1, p2, n0, n1, n2, col, kind, [0.0, 0.0, 0.0], root, delay)


func _emit(p0: Vector3, p1: Vector3, p2: Vector3, n0: Vector3, n1: Vector3, n2: Vector3, col: Color, kind: int,
		rag: Array, root: Vector3, delay: float) -> void:
	var fn := (p1 - p0).cross(p2 - p0)
	var avg := n0 + n1 + n2
	var q: Array = [[p0, n0, rag[0]], [p1, n1, rag[1]], [p2, n2, rag[2]]]
	if signf(fn.dot(avg)) != _conv:
		q = [[p0, n0, rag[0]], [p2, n2, rag[2]], [p1, n1, rag[1]]]
	for e: Array in q:
		_v.append(e[0])
		_n.append(e[1])
		_c.append(col)
		_uv.append(Vector2(float(kind), float(e[2])))
		_cu.append_array(PackedFloat32Array([root.x, root.y, root.z, delay]))


func _commit() -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _v
	arrays[Mesh.ARRAY_NORMAL] = _n
	arrays[Mesh.ARRAY_COLOR] = _c
	arrays[Mesh.ARRAY_TEX_UV] = _uv
	arrays[Mesh.ARRAY_CUSTOM0] = _cu
	# Index it (welding identical vertices) so the surface is indexed like every other lair mesh.
	var st := SurfaceTool.new()
	var mesh := ArrayMesh.new()
	var flags := Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT
	var idx := PackedInt32Array()
	var map := {}
	var v2 := PackedVector3Array()
	var n2 := PackedVector3Array()
	var c2 := PackedColorArray()
	var uv2 := PackedVector2Array()
	var cu2 := PackedFloat32Array()
	for i in _v.size():
		var key := "%.4f,%.4f,%.4f|%.3f,%.3f,%.3f|%.2f,%.3f|%.3f,%.3f,%.3f,%.3f|%s" % [_v[i].x, _v[i].y, _v[i].z,
				_n[i].x, _n[i].y, _n[i].z, _uv[i].x, _uv[i].y, _cu[i * 4], _cu[i * 4 + 1], _cu[i * 4 + 2], _cu[i * 4 + 3],
				_c[i].to_html()]
		if map.has(key):
			idx.append(int(map[key]))
			continue
		map[key] = v2.size()
		idx.append(v2.size())
		v2.append(_v[i])
		n2.append(_n[i])
		c2.append(_c[i])
		uv2.append(_uv[i])
		cu2.append_array(PackedFloat32Array([_cu[i * 4], _cu[i * 4 + 1], _cu[i * 4 + 2], _cu[i * 4 + 3]]))
	st = null
	arrays[Mesh.ARRAY_VERTEX] = v2
	arrays[Mesh.ARRAY_NORMAL] = n2
	arrays[Mesh.ARRAY_COLOR] = c2
	arrays[Mesh.ARRAY_TEX_UV] = uv2
	arrays[Mesh.ARRAY_CUSTOM0] = cu2
	arrays[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
	return mesh
