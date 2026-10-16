extends SceneTree
## Generates the crystal node model art/environment/crystal_node.tscn (task A2.3). Run it WINDOWED (headless
## drops mesh data when saving):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/crystal/build_crystal.gd --quit-after 120
## Footprint: CrystalNode's collider is a cylinder r 1.2, h 2 (workers stand ~1.9 m from the centre), so the
## rock mound stays within r ~1.25 and the crystals lean out no further than ~1.4 m.
## Meshes: crystal_rock.res (env_painted), crystal_cluster.res (crystal_cluster.gdshader, CUSTOM0 = crystal base
## + depletion threshold, see the shader), materials and the glint texture next to them.

const Kit := preload("res://art/environment/crown/mesh_kit.gd")
const DIR := "res://art/environment/crystal/"
const SCENE_PATH := "res://art/environment/crystal_node.tscn"
const ART_SCRIPT := "res://art/environment/crystal/crystal_cluster_art.gd"

const ROCK := Color(0.29, 0.30, 0.37)        # blue-grey rock (reflects the crystals, stays low-saturation)
const ROCK_L := Color(0.40, 0.41, 0.48)
const ROCK_D := Color(0.20, 0.20, 0.26)
const MOSS := Color(0.27, 0.40, 0.18, 0.45)

## Crystals: [base x, base z, lean direction (deg), lean (deg), height, radius, sides, threshold].
## Threshold = the fill ratio at which the crystal is gone (0 = the big one, shrinks to 35 % at the end).
const CRYSTALS: Array = [
	[0.0, -0.05, 200.0, 5.0, 2.2, 0.3, 6, 0.0],
	[0.42, 0.22, 30.0, 20.0, 1.55, 0.23, 6, 0.14],
	[-0.42, 0.18, 150.0, 24.0, 1.4, 0.22, 6, 0.26],
	[-0.12, -0.5, 250.0, 22.0, 1.25, 0.2, 6, 0.36],
	[0.5, -0.36, 320.0, 28.0, 1.05, 0.18, 5, 0.46],
	[0.08, 0.55, 95.0, 32.0, 0.92, 0.16, 5, 0.55],
	[-0.68, -0.2, 190.0, 38.0, 0.8, 0.15, 5, 0.63],
	[0.78, 0.08, 5.0, 42.0, 0.64, 0.13, 5, 0.7],
	[-0.35, 0.68, 120.0, 46.0, 0.5, 0.11, 5, 0.78],
	[0.2, -0.86, 280.0, 48.0, 0.46, 0.1, 5, 0.82],
	[0.48, 0.74, 60.0, 50.0, 0.42, 0.09, 5, 0.87],
	[-0.84, 0.4, 160.0, 52.0, 0.4, 0.09, 5, 0.92],
]
## Old stumps (never shrink): [x, z, height, radius].
const STUMPS: Array = [[0.68, -0.72, 0.2, 0.13], [-0.66, 0.74, 0.16, 0.11], [-0.92, -0.52, 0.18, 0.12]]

var mats: Dictionary = {}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	_make_materials()
	var rock: ArrayMesh = _build_rock()
	var cluster: ArrayMesh = _build_cluster()
	_pack_scene(rock, cluster)
	print("CRYSTAL BUILD OK")
	quit()


func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])
	if not res is PackedScene:
		res.take_over_path(path)   # packed scenes then reference the file instead of embedding a copy


func _make_materials() -> void:
	mats["rock"] = load("res://art/environment/env_painted_mat.tres") as Material
	var cm := ShaderMaterial.new()
	cm.shader = load(DIR + "crystal_cluster.gdshader") as Shader
	_save(cm, DIR + "crystal_cluster_mat.tres")
	mats["crystal"] = cm
	var pool := ShaderMaterial.new()
	pool.shader = load("res://art/environment/crown/glow_pool.gdshader") as Shader
	pool.set_shader_parameter("color", Color(0.3, 0.72, 1.0))
	pool.set_shader_parameter("strength", 0.5)
	pool.set_shader_parameter("inner", 0.0)
	pool.set_shader_parameter("falloff", 1.8)
	_save(pool, DIR + "crystal_pool_mat.tres")
	mats["pool"] = pool


## Height of the rock mound top at a flat distance d from the centre (crystal bases sit on it).
static func _mound_y(x: float, z: float) -> float:
	var d: float = Vector2(x, z).length()
	return maxf(0.06, 0.4 - 0.3 * d * d)


func _build_rock() -> ArrayMesh:
	var k := Kit.new()
	k.surf("rock")
	# Central squashed boulder, then a ring of chunks around it and a few pebbles.
	k.prim("rock", _sph(0.92, 9, 5), _xf(Vector3(0, 0.0, 0), Vector3(0, 0.3, 0), Vector3(1.0, 0.44, 0.95)), ROCK, 0.07,
			MOSS, 1.0)
	for i: int in 7:
		var a: float = i * TAU / 7.0 + 0.35
		var hh: float = Kit.h(Vector3(i, 3, 3))
		var rr: float = 0.95 + hh * 0.2
		var s: float = 0.24 + Kit.h(Vector3(i, 5, 1)) * 0.16
		k.prim("rock", _sph(s, 6, 4), _xf(Vector3(cos(a) * rr, s * 0.2, sin(a) * rr), Vector3(0.2, a, 0.1),
				Vector3(1.2, 0.72, 1.0)), ROCK_D.lerp(ROCK_L, hh), 0.05, MOSS, 10.0 + i)
	for i: int in 6:
		var a2: float = i * 1.9 + 0.8
		var rr2: float = 1.18 + Kit.h(Vector3(i, 8, 2)) * 0.15
		var s2: float = 0.07 + Kit.h(Vector3(i, 2, 8)) * 0.06
		k.prim("rock", _box(Vector3(s2 * 1.5, s2, s2 * 1.2)), _xf(Vector3(cos(a2) * rr2, s2 * 0.3, sin(a2) * rr2),
				Vector3(0.3, a2, 0.2)), ROCK_L, 0.02, Kit.NO_TOP, 20.0 + i)
	return k.commit(DIR + "crystal_rock.res", {"rock": mats["rock"]})


func _build_cluster() -> ArrayMesh:
	var k := Kit.new()
	k.face_var = 0.0
	k.surf("crystal", true, true)
	for i: int in CRYSTALS.size():
		var c: Array = CRYSTALS[i]
		var x: float = c[0]
		var z: float = c[1]
		var dir: float = deg_to_rad(c[2])
		var lean: float = deg_to_rad(c[3])
		var axis := Vector3(cos(dir) * sin(lean), cos(lean), sin(dir) * sin(lean))
		var base := Vector3(x, _mound_y(x, z), z)
		_crystal(k, base, axis, c[4], c[5], c[6], c[7], 1.0, Kit.h(Vector3(i, 1, 9)), false, 50.0 + i)
	for j: int in STUMPS.size():
		var s: Array = STUMPS[j]
		var base2 := Vector3(s[0], _mound_y(s[0], s[1]), s[1])
		var ax := (Vector3(s[0], 2.5, s[1])).normalized()
		_crystal(k, base2, ax, s[2], s[3], 6, -1.0, 0.55, 0.5, true, 80.0 + j)
	return k.commit(DIR + "crystal_cluster.res", {"crystal": mats["crystal"]})


## One crystal: a (jittered) hexagonal / pentagonal prism sunk 0.15 m into the rock, a shoulder at 70 % of its
## height and a chiselled point (or a flat broken top for stumps).
func _crystal(k: Kit, base: Vector3, axis: Vector3, h: float, r: float, sides: int, thr: float, tone: float,
		hue: float, flat: bool, seed: float) -> void:
	axis = axis.normalized()
	var fr: Array = Kit.frame(axis, Vector3(1, 0, 0.3))
	var ph: float = Kit.h(Vector3(seed, 2, 2)) * TAU
	var r0: PackedVector3Array = Kit.ring(base - axis * 0.15, fr[0], fr[1], r * 0.9, r * 0.9, sides, ph, r * 0.06, seed)
	var sh: float = 0.7 if not flat else 1.0
	var r1: PackedVector3Array = Kit.ring(base + axis * h * sh, fr[0], fr[1], r, r, sides, ph, r * 0.1, seed + 1.0)
	var tip: Vector3 = base + axis * h + (fr[0] as Vector3) * r * 0.12
	k.custom = Vector4(base.x, base.y, base.z, thr)
	var centre: Vector3 = base + axis * h * 0.4
	for j: int in sides:
		var jn: int = (j + 1) % sides
		var fa: float = Kit.h(Vector3(seed, j, 1))
		var fb: float = Kit.h(Vector3(seed, j, 2))
		var ca0 := Color(tone, fa, hue, 0.0)
		var ca1 := Color(tone, fa, hue, 0.7 if not flat else 0.55)
		var hint: Vector3 = ((r0[j] + r0[jn] + r1[j] + r1[jn]) * 0.25) - centre
		k.tri_c("crystal", r0[j], r0[jn], r1[jn], ca0, ca0, ca1, hint)
		k.tri_c("crystal", r0[j], r1[jn], r1[j], ca0, ca1, ca1, hint)
		if not flat:
			var cb1 := Color(tone, fb, hue, 0.7)
			var cbt := Color(tone, fb, hue, 1.0)
			k.tri_c("crystal", r1[j], r1[jn], tip, cb1, cb1, cbt, ((r1[j] + r1[jn] + tip) / 3.0) - centre)
	if flat:
		var top_c := Vector3.ZERO
		for p: Vector3 in r1:
			top_c += p
		top_c /= float(sides)
		var ct := Color(tone * 0.8, 0.9, hue, 0.6)
		for j: int in sides:
			k.tri_c("crystal", top_c, r1[j], r1[(j + 1) % sides], ct, ct, ct, axis)


func _sph(r: float, segs: int = 7, rings: int = 4) -> SphereMesh:
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


func _xf(pos: Vector3, rot: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot) * Basis.from_scale(s), pos)


func _sparkle_texture() -> Texture2D:
	var size: int = 64
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	for y: int in size:
		for x: int in size:
			var u: float = (x + 0.5) / size * 2.0 - 1.0
			var w: float = (y + 0.5) / size * 2.0 - 1.0
			var star: float = maxf(exp(-absf(u) * 26.0) * exp(-absf(w) * 3.2), exp(-absf(w) * 26.0) * exp(-absf(u) * 3.2))
			var diag: float = maxf(exp(-absf(u - w) * 30.0), exp(-absf(u + w) * 30.0)) * exp(-(u * u + w * w) * 9.0) * 0.45
			var core: float = exp(-(u * u + w * w) * 22.0)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(star + diag + core, 0.0, 1.0)))
	var tex := ImageTexture.create_from_image(img)
	_save(tex, DIR + "crystal_glint_tex.res")
	return tex


func _mi(parent: Node3D, mesh: Mesh, name: String, shadow: bool, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.position = pos
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _pack_scene(rock: ArrayMesh, cluster: ArrayMesh) -> void:
	var root := Node3D.new()
	root.name = "CrystalNodeArt"
	root.set_script(load(ART_SCRIPT))
	_mi(root, rock, "Rock", true)
	_mi(root, cluster, "Crystals", true)
	var plane := PlaneMesh.new()
	plane.size = Vector2(4.8, 4.8)
	plane.material = mats["pool"]
	_mi(root, plane, "GroundGlow", false, Vector3(0, 0.04, 0))
	# Glints: star sparkles popping around the crystals (10 particles, one draw call).
	var star_mat := StandardMaterial3D.new()
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	star_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	star_mat.disable_fog = true  # G-E 5: an additive quad must not fog
	star_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	star_mat.billboard_keep_scale = true   # G-F billboard pass: the particle scale applies (docs/art/gf_billboard.md)
	star_mat.vertex_color_use_as_albedo = true
	star_mat.albedo_texture = _sparkle_texture()
	star_mat.albedo_color = Color(1.6, 2.3, 2.6)
	star_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var quad := QuadMesh.new()
	quad.size = Vector2(0.44, 0.44)
	quad.material = star_mat
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.18, 1.0))
	curve.add_point(Vector2(0.45, 0.25))
	curve.add_point(Vector2(1.0, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	var ppm := ParticleProcessMaterial.new()
	ppm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	ppm.emission_box_extents = Vector3(0.6, 0.8, 0.6)
	ppm.direction = Vector3(0, 1, 0)
	ppm.spread = 25.0
	ppm.initial_velocity_min = 0.05
	ppm.initial_velocity_max = 0.25
	ppm.gravity = Vector3.ZERO
	ppm.scale_min = 0.55
	ppm.scale_max = 1.25
	ppm.scale_curve = ct
	ppm.angle_min = -40.0
	ppm.angle_max = 40.0
	var sp := GPUParticles3D.new()
	sp.name = "Sparkles"
	sp.amount = 10
	sp.lifetime = 1.3
	sp.randomness = 0.5
	sp.fixed_fps = 30
	sp.interpolate = true
	sp.local_coords = true
	sp.process_material = ppm
	sp.draw_pass_1 = quad
	sp.position = Vector3(0, 1.05, 0)
	sp.visibility_aabb = AABB(Vector3(-1.5, -1.5, -1.5), Vector3(3, 3.5, 3))
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(sp)
	for c: Node in root.get_children():
		c.owner = root
	var ps := PackedScene.new()
	var err: int = ps.pack(root)
	if err != OK:
		push_error("pack failed %d" % err)
	_save(ps, SCENE_PATH)
	root.free()
