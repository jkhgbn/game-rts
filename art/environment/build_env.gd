extends SceneTree
## Generates the environment art: materials (art/environment/*_mat.tres), meshes
## (art/environment/meshes/*.res, one mesh + one shared material each, MultiMesh friendly) and scenes
## (art/environment/*.tscn). Re-run after changing a shape or colour:
##   $GODOT --headless --path . -s res://art/environment/build_env.gd --quit-after 600
## A.10 (terrain + props polish): richer trees / rocks / pillar (same names, same collider footprints), new tree,
## rock and decor meshes, sparkling crystal nodes, crown ruins dressing, and the map edge (cliffs, plateau, border
## forest) packed in map_dressing.tscn (see map_dressing_art.gd for how the level plugs it in).
## 12.V5 (river mouths): the map edge is built twice, the closed ring (river_mouths/map_cliffs_closed.res +
## map_plateau_closed.res, maps without the river) and the open ring with the Hollowmere's two mouths (meshes/
## map_cliffs.res + map_plateau.res: a notch + plunge pool under a waterfall at the north, a gorge with rapids and a
## stone arch at the south), plus the mouth meshes in river_mouths/ (water, falls, foam, mist) and the RiverMouths
## node of map_dressing.tscn (river_mouths/river_mouths_art.gd picks the ring at runtime).
## Partial runs (reuse the saved materials, leave every other file untouched):
##   ... build_env.gd --quit-after 600 -- edge     map edge (both rings) + river mouths + map_dressing.tscn
##   ... build_env.gd --quit-after 600 -- ruins    meshes/crown_ruin_dressing.res only

const DIR := "res://art/environment/"
const MESH_DIR := "res://art/environment/meshes/"
const MAP_HALF := 60.0

# --- river mouths (12.V5, map-fill.md 2.1 / 3.2 `lm_mouths`) ---
const RM_DIR := "res://art/environment/river_mouths/"
const WATER_MAT_PATH := "res://art/environment/water/water_mat.tres"
const MOUTH_WATER_Y := -0.362          ## pool / gorge surface, a hair under the river's -0.35 where they overlap
const SOUTH0 := 164                    ## perimeter index of the first south-side column (x = 60 - 1.6 k)
## North: N0 (-15, -62) -> N1 (-12, -48.7) crosses z = -60 at x -14.55; the fall sits in a notch just upstream.
const N_EDGE_X := -14.549
const NOTCH_X := -15.1
const NOTCH_CORE := 2.6                ## half width of the notch at full depth
const NOTCH_HALF := 6.8                ## half width where the notch fades out
const NOTCH_RECESS := 2.4              ## the cliff face behind the fall is pushed back this far
const NOTCH_VALLEY := 1.3              ## the stream's valley cut into the plateau (and the lip under it)
const STREAM_END := 20.0               ## the stream comes out of the forest this far behind the notch base
## South: S0 (15, 62) <- S1 (12, 48.7) crosses z = 60 at x 14.55; the gorge runs out to GORGE_END.
const S_EDGE_X := 14.549
const GORGE_END := 23.3
const GORGE_HOLE := 23.5               ## the plateau is cut open up to here over the gorge
const GORGE_STEPS: Array[float] = [2.9, 6.6, 10.3, 14.0]
const GORGE_LEVELS: Array[float] = [-0.362, -0.9, -1.55, -2.25, -2.95]
const CHUTE_HALF := 0.3                ## half length of each rapid step (the water drops over 0.6 m)
const ARCH_D := Vector2(17.4, 23.9)    ## the stone arch spans the gorge between these distances

# Palette (sRGB, art-keep.md 0.2 spirit: saturated accents, low-saturation stone).
const TRUNK := Color(0.36, 0.24, 0.14)
const TRUNK_D := Color(0.27, 0.18, 0.11)
const PINE := Color(0.13, 0.30, 0.16)
const PINE_L := Color(0.24, 0.45, 0.21)
const OAK := Color(0.27, 0.44, 0.15)
const OAK_L := Color(0.45, 0.60, 0.21)
const OAK_D := Color(0.17, 0.31, 0.12)
const FIR := Color(0.10, 0.27, 0.24)
const FIR_L := Color(0.18, 0.41, 0.32)
const BIRCH := Color(0.88, 0.86, 0.80)
const BIRCH_MARK := Color(0.20, 0.19, 0.18)
const BIRCH_LEAF := Color(0.50, 0.64, 0.22)
const BIRCH_LEAF_L := Color(0.68, 0.78, 0.30)
const GOLD_LEAF := Color(0.82, 0.50, 0.14)
const GOLD_LEAF_L := Color(0.96, 0.72, 0.25)
const GOLD_LEAF_D := Color(0.60, 0.27, 0.09)
const STONE := Color(0.47, 0.45, 0.42)
const STONE_W := Color(0.56, 0.50, 0.42)
const STONE_B := Color(0.40, 0.40, 0.45)
const STONE_D := Color(0.28, 0.27, 0.27)
const MOSS := Color(0.26, 0.40, 0.17, 0.55)
const MOSS_HEAVY := Color(0.22, 0.35, 0.15, 0.7)
const MOSS_LIGHT := Color(0.30, 0.40, 0.20, 0.3)
const RUIN := Color(0.52, 0.50, 0.55)
const RUIN_L := Color(0.58, 0.56, 0.59)
const RUIN_D := Color(0.35, 0.32, 0.37)
const IVY := Color(0.16, 0.33, 0.13)
const IVY_L := Color(0.26, 0.45, 0.17)
const WOOD := Color(0.45, 0.30, 0.15)
const WOOD_D := Color(0.30, 0.20, 0.11)
const WOOD_CUT := Color(0.74, 0.58, 0.36)
const GOLD := Color(0.86, 0.64, 0.24)
const METAL := Color(0.25, 0.24, 0.26)
const CLOTH_R := Color(0.70, 0.22, 0.14)
const CLOTH_C := Color(0.88, 0.78, 0.56)
const ROBE := Color(0.60, 0.50, 0.30)
const ROBE_D := Color(0.38, 0.29, 0.17)
const SCARF := Color(0.18, 0.52, 0.56)
const BUSH := Color(0.19, 0.35, 0.14)
const BUSH_L := Color(0.33, 0.50, 0.18)
const FERN := Color(0.22, 0.43, 0.16)
const BERRY := Color(0.78, 0.14, 0.18)
const MUSH_CAP := Color(0.74, 0.22, 0.12)
const MUSH_STEM := Color(0.88, 0.84, 0.72)
const FLOWER_W := Color(0.97, 0.95, 0.87)
const FLOWER_Y := Color(1.00, 0.82, 0.22)
const FLOWER_P := Color(0.68, 0.48, 0.90)
const STEM := Color(0.24, 0.42, 0.15)
const BLADE := Color(0.30, 0.47, 0.16)
const CLIFF := Color(0.37, 0.34, 0.32)
const CLIFF_L := Color(0.47, 0.43, 0.38)
const CLIFF_D := Color(0.23, 0.21, 0.21)
const CLIFF_B := Color(0.33, 0.33, 0.36)
const SOIL := Color(0.30, 0.22, 0.14)
const GRASS_TOP := Color(0.27, 0.42, 0.15, 1.0)
const GRASS_CAP := Color(0.25, 0.40, 0.15)
const NO_TOP := Color(0, 0, 0, 0)

## Border forest variants (map_dressing) and their weights.
const BORDER_TREES: Array[String] = ["tree_pine_far", "tree_fir_far", "tree_broadleaf_far", "tree_birch_far",
	"tree_gold_far"]
const BORDER_WEIGHTS: Array[float] = [0.34, 0.32, 0.24, 0.06, 0.04]

var env_mat: ShaderMaterial
var crystal_mat: ShaderMaterial
var ember_mat: ShaderMaterial
var lantern_mat: ShaderMaterial
var plateau_mat: ShaderMaterial

var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _sway := PackedFloat32Array()
var _conv: float = 1.0   # sign of (b - a) x (c - a) . normal for Godot's own primitives (front-face winding)

# Map edge profile per perimeter column (filled by _build_map_edge, used to place the border props).
# [base: Vector3, normal: Vector3, profile_d: PackedFloat32Array, profile_y: PackedFloat32Array, plateau y: float,
#  valley depth: float, notch weight: float]
var _cols: Array = []
var _cols_closed: Array = []
var _cols_open: Array = []

# River mouths (12.V5).
var _open_edge := false                # building the open ring
var _gap: Dictionary = {}              # perimeter index -> true: columns cut out for the south gorge
var _kept_e := -1                      # the columns left standing on either side of the gorge
var _kept_w := -1
var _notch_yp := 8.4                   # plateau height shared by the notch columns
var _notch_lip := 7.05
var _notch_pd := PackedFloat32Array()
var _notch_py := PackedFloat32Array()
var _hofs := PackedFloat32Array()      # per vertex: ground height the contact band (UV.y) is measured from
var _last_range := Vector2.ZERO        # y range of the last committed mesh (for the COLOR.a gradient)
var _mouth_closed_idx: Dictionary = {}   # border set name -> PackedInt32Array: instances of the closed ring only
var _mouth_open_idx: Dictionary = {}     # ... of the open ring only
var foam_mat: ShaderMaterial
var falls_mat: ShaderMaterial
var mist_mat: ShaderMaterial
var fallback_water_mat: ShaderMaterial


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RM_DIR))
	_detect_winding()
	if args.has("edge") or args.has("ruins"):
		# Partial runs reuse the saved materials. `ruins`: only meshes/crown_ruin_dressing.res; `edge`: only the map
		# edge, the river mouths and map_dressing.tscn.
		_load_materials()
		if args.has("ruins"):
			_build_ruin_dressing_only()
		if args.has("edge"):
			_make_mouth_materials()
			_build_map_edge()
			_build_map_dressing()
		print("ENV BUILD OK (%s)" % " ".join(args))
		quit()
		return
	_make_materials()
	# _build_trees() / _build_rocks() / _build_pillar() (and the *_far border trees): replaced by
	# art/environment/nature_props/build_nature.gd (A2.8, variants + wind + contact shadows); don't overwrite.
	_build_ruin_dressing_only()   # A2.3 owns crown_pedestal.tscn / crystal_node.tscn (art/environment/crown|crystal/)
	# _build_cache() / _build_peddler(): replaced by art/environment/neutral/build_neutral.gd (A2.7); don't overwrite.
	_build_decor()
	_make_mouth_materials()
	_build_map_edge()
	_build_map_dressing()
	print("ENV BUILD OK")
	quit()


# --- materials ---------------------------------------------------------------------------------

func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])


func _glow(name: String, glow: Color, core: Color, energy: float, sparkle: float = 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(DIR + "env_glow.gdshader") as Shader
	m.set_shader_parameter("glow_color", glow)
	m.set_shader_parameter("core_color", core)
	m.set_shader_parameter("energy", energy)
	m.set_shader_parameter("sparkle", sparkle)
	_save(m, DIR + name + ".tres")
	return m


func _make_materials() -> void:
	var noise: Texture2D = load("res://art/shaders/paint_noise.tres") as Texture2D
	env_mat = ShaderMaterial.new()
	env_mat.shader = load(DIR + "env_painted.gdshader") as Shader
	env_mat.set_shader_parameter("noise_tex", noise)
	_save(env_mat, DIR + "env_painted_mat.tres")
	var ground := ShaderMaterial.new()
	ground.shader = load(DIR + "ground.gdshader") as Shader
	ground.set_shader_parameter("noise_tex", noise)
	_save(ground, DIR + "ground_material.tres")
	# The map_dressing plateau outside the cliffs: same painted ground, forest floor + far canopy, no lane.
	plateau_mat = ShaderMaterial.new()
	plateau_mat.shader = ground.shader
	plateau_mat.set_shader_parameter("noise_tex", noise)
	plateau_mat.set_shader_parameter("expand_edge", false)
	plateau_mat.set_shader_parameter("forest_floor", 1.0)
	plateau_mat.set_shader_parameter("lane_half_width", 0.0)
	plateau_mat.set_shader_parameter("canopy_start", 19.0)
	for i: int in 4:
		plateau_mat.set_shader_parameter("spot_%d" % i, Vector4.ZERO)
	_save(plateau_mat, DIR + "plateau_mat.tres")
	# MAP.P1: the map-edge cliffs use the same painted shader with the cliff layer on (streaks, strata, dark foot).
	var cliff := ShaderMaterial.new()
	cliff.shader = env_mat.shader
	cliff.set_shader_parameter("noise_tex", noise)
	cliff.set_shader_parameter("cliff_paint", 1.0)
	cliff.set_shader_parameter("rim_strength", 0.05)   # the low south bank is seen edge-on: no pale rim wash
	_save(cliff, DIR + "cliff_mat.tres")
	crystal_mat = _glow("crystal_glow_mat", Color(0.22, 0.64, 1.0), Color(0.70, 0.94, 1.0), 2.1, 1.0)
	ember_mat = _glow("ember_glow_mat", Color(1.0, 0.55, 0.15), Color(1.0, 0.85, 0.5), 3.0)
	lantern_mat = _glow("lantern_glow_mat", Color(1.0, 0.8, 0.4), Color(1.0, 0.95, 0.8), 3.2)


## `-- edge` runs: reuse the saved materials instead of rewriting them (other tasks own their tuning).
func _load_materials() -> void:
	env_mat = load(DIR + "env_painted_mat.tres") as ShaderMaterial
	plateau_mat = load(DIR + "plateau_mat.tres") as ShaderMaterial
	if env_mat == null or plateau_mat == null:
		push_warning("saved env materials missing: rebuilding them")
		_make_materials()


## 12.V5: the river-mouth materials (all saved, one shader each, the shared paint noise as the only sampler).
func _make_mouth_materials() -> void:
	var noise: Texture2D = load("res://art/shaders/paint_noise.tres") as Texture2D
	var list: Array = [["waterfall", "waterfall_mat"], ["mouth_foam", "mouth_foam_mat"], ["mouth_mist", "mouth_mist_mat"],
		["mouth_water_fallback", "mouth_water_fallback_mat"]]
	var mats: Array[ShaderMaterial] = []
	for e: Array in list:
		var m := ShaderMaterial.new()
		m.shader = load(RM_DIR + String(e[0]) + ".gdshader") as Shader
		m.set_shader_parameter("noise_tex", noise)
		_save(m, RM_DIR + String(e[1]) + ".tres")
		mats.append(load(RM_DIR + String(e[1]) + ".tres") as ShaderMaterial)
	falls_mat = mats[0]
	foam_mat = mats[1]
	mist_mat = mats[2]
	fallback_water_mat = mats[3]


# --- mesh building -----------------------------------------------------------------------------

func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


func _h3(p: Vector3) -> Vector3:
	return Vector3(_h(p), _h(p + Vector3(5.2, 1.3, 7.1)), _h(p + Vector3(2.7, 9.1, 3.3))) * 2.0 - Vector3.ONE


func _xf(pos: Vector3, rot: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot) * Basis.from_scale(s), pos)


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
	_sway = PackedFloat32Array()
	_hofs = PackedFloat32Array()


## Mesh arrays from raw data. `norms` only orient the faces (outward hint per vertex); shading is flat.
func _mk(verts: PackedVector3Array, norms: PackedVector3Array, idx: PackedInt32Array) -> Array:
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = idx
	return arr


## Adds a primitive, transformed, flat-shaded, with a colour block, jitter (metres), sway weight and an
## optional tint on faces turned to the sky (moss, grass...; alpha = strength).
func _prim(m: PrimitiveMesh, xf: Transform3D, col: Color, jitter: float = 0.0, sway: float = 0.0,
		top: Color = NO_TOP, seed: float = 0.0, jit_axes: Vector3 = Vector3.ONE) -> void:
	_arr(m.get_mesh_arrays(), xf, col, jitter, sway, top, seed, jit_axes)


## Same as _prim for any mesh arrays (custom shapes from _mk). The triangle winding is fixed from the normal
## hints so custom faces are front-facing like Godot's primitives.
func _arr(arr: Array, xf: Transform3D, col: Color, jitter: float = 0.0, sway: float = 0.0,
		top: Color = NO_TOP, seed: float = 0.0, jit_axes: Vector3 = Vector3.ONE) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var nb: Basis = xf.basis.inverse().transposed()
	var tv := PackedVector3Array()
	tv.resize(v.size())
	for i: int in v.size():
		var p: Vector3 = xf * v[i]
		if jitter > 0.0:
			p += _h3(v[i].snappedf(0.001) + Vector3(seed, seed * 0.7, seed * 1.3)) * jitter * jit_axes
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
		if top.a > 0.0 and fn.y > 0.7 and _h(centre.snappedf(0.01) + Vector3(3, 3, 3)) > 0.35:
			fc = col.lerp(Color(top.r, top.g, top.b), top.a * smoothstep(0.7, 0.95, fn.y))
		var k: float = 1.0 + (_h(centre.snappedf(0.01)) - 0.5) * 0.12
		fc = Color(fc.r * k, fc.g * k, fc.b * k)
		for vi: int in [a, b, c]:
			_v.append(tv[vi])
			_n.append(fn)
			_c.append(fc)
			_sway.append(sway)
			_hofs.append(0.0)


func _cyl(top: float, bottom: float, h: float, segs: int = 7, rings: int = 0) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = segs
	m.rings = rings
	return m


func _sph(r: float, segs: int = 7, rings: int = 4) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segs
	m.rings = rings
	return m


func _box(size: Vector3, sub: int = 0) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	m.subdivide_width = sub
	m.subdivide_height = sub
	m.subdivide_depth = sub
	return m


## A tree tier: cone whose skirt is a star (points alternate r_out / r_in, the outer tips droop), with a
## slightly raised underside. Base at y 0, apex at y h.
func _star_cone(r_out: float, r_in: float, h: float, points: int, droop: float, under_lift: float = 0.18) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var m: int = points * 2
	v.append(Vector3(0, h, 0))
	n.append(Vector3.UP)
	for i: int in m:
		var a: float = i * PI / points
		var r: float = r_out if i % 2 == 0 else r_in
		var y: float = -droop if i % 2 == 0 else 0.0
		v.append(Vector3(cos(a) * r, y, sin(a) * r))
		n.append(Vector3(cos(a), 0.7, sin(a)).normalized())
	for i: int in m:
		idx.append_array([0, 1 + i, 1 + (i + 1) % m])
	var base: int = v.size()
	v.append(Vector3(0, h * under_lift, 0))
	n.append(Vector3.DOWN)
	for i: int in m:
		v.append(v[1 + i])
		n.append(Vector3.DOWN)
	for i: int in m:
		idx.append_array([base, base + 1 + i, base + 1 + (i + 1) % m])
	return _mk(v, n, idx)


## A fluted column drum (radius alternates r_out / r_in around 2 * flutes vertices), capped both ends.
func _fluted(r_out: float, r_in: float, h: float, flutes: int) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var m: int = flutes * 2
	for ring: int in 2:
		for i: int in m:
			var a: float = i * PI / flutes
			var r: float = r_out if i % 2 == 0 else r_in
			v.append(Vector3(cos(a) * r, h * ring, sin(a) * r))
			n.append(Vector3(cos(a), 0, sin(a)))
	for i: int in m:
		var j: int = (i + 1) % m
		idx.append_array([i, j, m + i, j, m + j, m + i])
	for cap: int in 2:
		var cbase: int = v.size()
		var up: Vector3 = Vector3.UP if cap == 1 else Vector3.DOWN
		v.append(Vector3(0, h * cap, 0))
		n.append(up)
		for i: int in m:
			v.append(v[cap * m + i])
			n.append(up)
		for i: int in m:
			idx.append_array([cbase, cbase + 1 + i, cbase + 1 + (i + 1) % m])
	return _mk(v, n, idx)


## A broken column top: ring of radius r at y 0, a jagged rim (heights 0.3..1 x h) and a sunken centre.
func _broken_top(r: float, h: float, segs: int, seed: float) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	for i: int in segs:
		var a: float = i * TAU / segs
		v.append(Vector3(cos(a) * r, 0, sin(a) * r))
		n.append(Vector3(cos(a), 0, sin(a)))
	for i: int in segs:
		var a: float = i * TAU / segs
		var notch: float = 0.45 if i % 4 == 1 else 1.0   # a couple of chipped notches in the rim
		var hh: float = h * (0.55 + 0.45 * _h(Vector3(i, seed, 1.0))) * notch
		v.append(Vector3(cos(a) * r * 0.97, hh, sin(a) * r * 0.97))
		n.append(Vector3(cos(a), 0.2, sin(a)))
	for i: int in segs:
		var j: int = (i + 1) % segs
		idx.append_array([i, j, segs + i, j, segs + j, segs + i])
	var cbase: int = v.size()
	v.append(Vector3(0.1, h * 0.35, -0.05))
	n.append(Vector3.UP)
	for i: int in segs:
		v.append(v[segs + i])
		n.append(Vector3.UP)
	for i: int in segs:
		idx.append_array([cbase, cbase + 1 + i, cbase + 1 + (i + 1) % segs])
	return _mk(v, n, idx)


## A grass blade as a thin 3-sided spike (visible from every side): base centre at `p`, leaning along `lean`.
func _blade(p: Vector3, h: float, w: float, lean: Vector3) -> Array:
	var tip: Vector3 = p + Vector3(0, h, 0) + lean
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	for i: int in 3:
		var a: float = i * TAU / 3.0 + p.x * 3.0
		v.append(p + Vector3(cos(a) * w, 0, sin(a) * w))
		n.append(Vector3(cos(a), 0.3, sin(a)))
	v.append(tip)
	n.append(Vector3.UP)
	for i: int in 3:
		idx.append_array([i, (i + 1) % 3, 3])
	return _mk(v, n, idx)


## Bakes gradient (COLOR.a) and height (UV.y), saves the mesh with `mat` on its surface.
func _commit(name: String, mat: Material) -> ArrayMesh:
	return _commit_to(MESH_DIR + name + ".res", mat)


## Same as _commit to any path. `grad` (x < y) fixes the y range of the COLOR.a gradient (the open cliff ring keeps
## the closed ring's shading although its gorge goes deeper); UV.y is measured from each vertex's _hofs ground.
func _commit_to(path: String, mat: Material, grad: Vector2 = Vector2(INF, -INF)) -> ArrayMesh:
	var name: String = path.get_file().get_basename()
	var miny: float = INF
	var maxy: float = -INF
	for p: Vector3 in _v:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	_last_range = Vector2(miny, maxy)
	if grad.x < grad.y:
		miny = grad.x
		maxy = grad.y
	var span: float = maxf(maxy - miny, 0.01)
	var uv := PackedVector2Array()
	uv.resize(_v.size())
	for i: int in _v.size():
		var cc: Color = _c[i]
		cc.a = clampf((_v[i].y - miny) / span, 0.0, 1.0)
		_c[i] = cc
		uv[i] = Vector2(_sway[i], _v[i].y - _hofs[i])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _v
	arrays[Mesh.ARRAY_NORMAL] = _n
	arrays[Mesh.ARRAY_COLOR] = _c
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, mat)
	_save(mesh, path)
	print("mesh %s: %d tris, y %.2f..%.2f" % [name, _v.size() / 3, miny, maxy])
	return mesh


## Sets the contact-band ground (_hofs) of the vertices added since index `from`: a constant or fn(world pos).
func _set_hofs(from: int, value: float, fn: Callable = Callable()) -> void:
	for i: int in range(from, _v.size()):
		_hofs[i] = float(fn.call(_v[i])) if fn.is_valid() else value


# --- scenes ------------------------------------------------------------------------------------

func _own(n: Node, root: Node) -> void:
	for ch: Node in n.get_children():
		ch.owner = root
		_own(ch, root)


func _pack(name: String, root: Node3D) -> void:
	_own(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	_save(ps, DIR + name + ".tscn")
	root.free()


func _mi(parent: Node3D, mesh: Mesh, name: String, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi


func _single(name: String, mesh: Mesh) -> void:
	var root := Node3D.new()
	root.name = name.to_pascal_case()
	var mi: MeshInstance3D = _mi(root, mesh, "Mesh")
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_pack(name, root)


# --- trees (s = 1: collider radius 0.45, height 2 at y 1; ~4.5-5.5 m tall) ---------------------

func _roots(seed: float, col: Color, r: float) -> void:
	for i: int in 4:
		var a: float = i * TAU / 4.0 + _h(Vector3(seed, i, 2)) * 0.8
		var d := Vector3(cos(a), 0, sin(a))
		_prim(_cyl(0.03, 0.11, 0.55, 4), Transform3D(Basis(d.cross(Vector3.UP).normalized(), 1.15) , d * r + Vector3(0, 0.08, 0)),
			col, 0.02, 0.0, NO_TOP, seed + i)


func _build_trees() -> void:
	# A: pine, 5 drooping star tiers, dark at the bottom, light at the top.
	_begin()
	_prim(_cyl(0.16, 0.28, 1.7, 6), _xf(Vector3(0, 0.8, 0)), TRUNK, 0.03, 0.0, NO_TOP, 1.0)
	_roots(1.0, TRUNK_D, 0.22)
	for i: int in 5:
		var r: float = 1.75 - i * 0.3
		var y: float = 1.25 + i * 0.72
		var col: Color = PINE.lerp(PINE_L, i / 4.0)
		_arr(_star_cone(r, r * 0.66, 1.25 - i * 0.05, 7, 0.28), _xf(Vector3(0, y, 0), Vector3(0, i * 0.45, 0)), col,
			0.07, 1.0, NO_TOP, 2.0 + i)
	_prim(_cyl(0.0, 0.2, 0.6, 5), _xf(Vector3(0, 5.0, 0)), PINE_L.lightened(0.08), 0.02, 1.0)
	_single("tree_pine", _commit("tree_pine", env_mat))

	# B: round broadleaf: trunk + 3 branches + 7 lumpy blobs (dark underside, light top blobs).
	_begin()
	_prim(_cyl(0.2, 0.34, 2.2, 7), _xf(Vector3(0, 1.05, 0)), TRUNK, 0.035, 0.0, NO_TOP, 3.0)
	_roots(3.0, TRUNK_D, 0.26)
	_prim(_cyl(0.07, 0.14, 1.1, 5), _xf(Vector3(0.42, 2.1, 0.12), Vector3(0, 0, -0.85)), TRUNK_D, 0.02)
	_prim(_cyl(0.07, 0.14, 1.0, 5), _xf(Vector3(-0.36, 2.05, -0.18), Vector3(0.25, 0, 0.8)), TRUNK_D, 0.02)
	_prim(_cyl(0.06, 0.12, 0.9, 5), _xf(Vector3(0.05, 2.2, -0.4), Vector3(-0.8, 0, 0.1)), TRUNK_D, 0.02)
	var blobs: Array = [
		[Vector3(0, 2.75, 0), 1.25, Vector3(1.05, 0.72, 1.05), OAK_D],
		[Vector3(0.95, 2.95, 0.35), 0.95, Vector3.ONE, OAK],
		[Vector3(-0.85, 3.0, -0.35), 1.0, Vector3.ONE, OAK],
		[Vector3(0.2, 3.05, -0.95), 0.9, Vector3.ONE, OAK.lerp(OAK_L, 0.2)],
		[Vector3(-0.3, 3.1, 0.85), 0.9, Vector3.ONE, OAK.lerp(OAK_L, 0.3)],
		[Vector3(0.15, 3.75, 0.05), 1.05, Vector3(1.0, 0.85, 1.0), OAK_L.lerp(OAK, 0.25)],
		[Vector3(-0.35, 4.3, -0.2), 0.6, Vector3.ONE, OAK_L],
	]
	var bi: int = 0
	for b: Array in blobs:
		_prim(_sph(b[1] as float, 8, 5), _xf(b[0] as Vector3, Vector3(0, bi * 0.9, 0), b[2] as Vector3),
			b[3] as Color, 0.17, 1.0, NO_TOP, 10.0 + bi)
		bi += 1
	_single("tree_broadleaf", _commit("tree_broadleaf", env_mat))

	# C: tall fir, 6 slim teal star tiers + tip.
	_begin()
	_prim(_cyl(0.14, 0.25, 1.4, 6), _xf(Vector3(0, 0.65, 0)), TRUNK_D, 0.03, 0.0, NO_TOP, 4.0)
	_roots(4.0, TRUNK_D, 0.2)
	for i: int in 6:
		var r2: float = 1.3 - i * 0.2
		_arr(_star_cone(r2, r2 * 0.6, 1.05, 6, 0.2), _xf(Vector3(0, 1.1 + i * 0.68, 0), Vector3(0, i * 0.55, 0)),
			FIR.lerp(FIR_L, i / 5.0), 0.06, 1.0, NO_TOP, 20.0 + i)
	_prim(_cyl(0.0, 0.16, 0.7, 5), _xf(Vector3(0, 5.35, 0)), FIR_L.lightened(0.05), 0.02, 1.0)
	_single("tree_fir", _commit("tree_fir", env_mat))

	# D (new): birch, white trunk with dark marks, airy yellow-green crown.
	_begin()
	for i: int in 5:
		var col2: Color = BIRCH if i % 2 == 0 else BIRCH.darkened(0.12)
		_prim(_cyl(0.16 - i * 0.012, 0.2 - i * 0.012, 0.62, 6), _xf(Vector3(0.02 * i, 0.31 + i * 0.6, 0)), col2, 0.015,
			0.0, NO_TOP, 30.0 + i)
	for i: int in 6:
		var a3: float = i * 2.1
		_prim(_box(Vector3(0.14, 0.07, 0.04)), _xf(Vector3(cos(a3) * 0.17, 0.5 + i * 0.47, sin(a3) * 0.17),
			Vector3(0, -a3, 0)), BIRCH_MARK)
	_prim(_cyl(0.04, 0.08, 1.0, 4), _xf(Vector3(0.35, 2.7, 0.1), Vector3(0, 0, -0.9)), BIRCH.darkened(0.1), 0.02)
	var bb: Array = [
		[Vector3(0.1, 3.1, 0.1), 0.95, BIRCH_LEAF], [Vector3(0.75, 3.5, -0.2), 0.7, BIRCH_LEAF.lerp(BIRCH_LEAF_L, 0.4)],
		[Vector3(-0.6, 3.6, 0.3), 0.72, BIRCH_LEAF.lerp(BIRCH_LEAF_L, 0.3)], [Vector3(0.0, 4.2, -0.1), 0.75, BIRCH_LEAF_L],
		[Vector3(0.3, 4.75, 0.2), 0.45, BIRCH_LEAF_L.lightened(0.06)],
	]
	var bj: int = 0
	for b2: Array in bb:
		_prim(_sph(b2[1] as float, 7, 4), _xf(b2[0] as Vector3, Vector3(0, bj, 0), Vector3(1.0, 1.15, 1.0)),
			b2[2] as Color, 0.14, 1.0, NO_TOP, 35.0 + bj)
		bj += 1
	_single("tree_birch", _commit("tree_birch", env_mat))

	# E (new): golden oak, wide flat crown in autumn gold (a warm accent, use sparingly).
	_begin()
	_prim(_cyl(0.22, 0.38, 1.9, 7), _xf(Vector3(0, 0.9, 0)), TRUNK_D, 0.04, 0.0, NO_TOP, 40.0)
	_roots(40.0, TRUNK_D, 0.28)
	_prim(_cyl(0.08, 0.16, 1.3, 5), _xf(Vector3(0.55, 2.05, 0.1), Vector3(0, 0, -1.0)), TRUNK_D, 0.02)
	_prim(_cyl(0.08, 0.16, 1.2, 5), _xf(Vector3(-0.5, 2.0, -0.1), Vector3(0.1, 0, 1.0)), TRUNK_D, 0.02)
	var gb: Array = [
		[Vector3(0, 2.6, 0), 1.4, Vector3(1.25, 0.55, 1.2), GOLD_LEAF_D],
		[Vector3(1.1, 2.9, 0.2), 0.95, Vector3(1.0, 0.75, 1.0), GOLD_LEAF],
		[Vector3(-1.05, 2.95, -0.25), 1.0, Vector3(1.0, 0.75, 1.0), GOLD_LEAF],
		[Vector3(0.1, 3.2, 0.9), 0.95, Vector3(1.0, 0.75, 1.0), GOLD_LEAF.lerp(GOLD_LEAF_L, 0.3)],
		[Vector3(-0.1, 3.3, -0.9), 0.9, Vector3(1.0, 0.75, 1.0), GOLD_LEAF.lerp(GOLD_LEAF_L, 0.4)],
		[Vector3(0.1, 3.65, 0.0), 1.0, Vector3(1.0, 0.7, 1.0), GOLD_LEAF_L],
	]
	var gj: int = 0
	for b3: Array in gb:
		_prim(_sph(b3[1] as float, 8, 5), _xf(b3[0] as Vector3, Vector3(0, gj * 0.8, 0), b3[2] as Vector3),
			b3[3] as Color, 0.16, 1.0, NO_TOP, 45.0 + gj)
		gj += 1
	_single("tree_gold", _commit("tree_gold", env_mat))
	_build_far_trees()


## Low-poly stand-ins (~60-140 tris) for the border forest, seen from 40 m and more: same silhouettes and
## colours as the map trees, a quarter of the triangles.
func _build_far_trees() -> void:
	_begin()
	_prim(_cyl(0.16, 0.26, 1.7, 5), _xf(Vector3(0, 0.8, 0)), TRUNK)
	for i: int in 3:
		var r: float = 1.8 - i * 0.45
		_arr(_star_cone(r, r * 0.66, 1.6 - i * 0.1, 5, 0.3), _xf(Vector3(0, 1.3 + i * 1.15, 0), Vector3(0, i * 0.6, 0)),
			PINE.lerp(PINE_L, i / 3.0).darkened(0.08), 0.07, 1.0, NO_TOP, 2.0 + i)
	_commit("tree_pine_far", env_mat)
	_begin()
	_prim(_cyl(0.14, 0.24, 1.4, 5), _xf(Vector3(0, 0.65, 0)), TRUNK_D)
	for i: int in 4:
		var r2: float = 1.3 - i * 0.26
		_arr(_star_cone(r2, r2 * 0.6, 1.3, 5, 0.22), _xf(Vector3(0, 1.1 + i * 0.95, 0), Vector3(0, i * 0.7, 0)),
			FIR.lerp(FIR_L, i / 3.0), 0.06, 1.0, NO_TOP, 20.0 + i)
	_commit("tree_fir_far", env_mat)
	# Background trees: a little darker and less saturated than the map's, so the playfield stays the focus.
	var sets: Array = [
		["tree_broadleaf_far", TRUNK, 2.1, [[Vector3(0, 2.8, 0), 1.35, OAK_D], [Vector3(0.7, 3.2, 0.3), 1.0, OAK.darkened(0.18)],
			[Vector3(-0.5, 3.7, -0.2), 0.95, OAK.darkened(0.06)]]],
		["tree_birch_far", BIRCH.darkened(0.2), 2.0, [[Vector3(0.1, 2.9, 0.1), 1.0, BIRCH_LEAF.darkened(0.2)],
			[Vector3(-0.3, 3.7, 0.2), 0.8, BIRCH_LEAF.darkened(0.08)], [Vector3(0.5, 3.4, -0.2), 0.7, BIRCH_LEAF.darkened(0.14)]]],
		["tree_gold_far", TRUNK_D, 1.9, [[Vector3(0, 2.7, 0), 1.45, GOLD_LEAF_D.darkened(0.1)], [Vector3(0.6, 3.2, 0.2), 1.05,
			GOLD_LEAF_D], [Vector3(-0.4, 3.5, -0.2), 1.0, GOLD_LEAF.darkened(0.12)]]],
	]
	for s: Array in sets:
		_begin()
		var th: float = s[2]
		_prim(_cyl(0.16, 0.28, th, 5), _xf(Vector3(0, th * 0.5, 0)), s[1] as Color)
		var k: int = 0
		for b: Array in s[3]:
			_prim(_sph(b[1] as float, 6, 3), _xf(b[0] as Vector3, Vector3(0, k, 0), Vector3(1.0, 0.85, 1.0)), b[2] as Color,
				0.15, 1.0, NO_TOP, 60.0 + k)
			k += 1
		_commit(s[0] as String, env_mat)


# --- rocks (s = 1: collider box 1.6 x 1.2 x 1.3 at y 0.5; mesh fits y -0.2..1.2) ---------------

func _build_rocks() -> void:
	# Boulder: a big faceted rock leaning on a second one, mossy top, pebbles at the foot.
	_begin()
	_prim(_sph(1.0, 8, 5), _xf(Vector3(0.05, 0.42, 0), Vector3(0.12, 0.3, 0.05), Vector3(0.78, 0.66, 0.66)),
		STONE, 0.15, 0.0, MOSS_HEAVY, 30.0)
	_prim(_sph(0.62, 7, 4), _xf(Vector3(-0.55, 0.22, 0.25), Vector3(0.3, 1.1, -0.2), Vector3(1.0, 0.8, 0.85)),
		STONE.darkened(0.08), 0.1, 0.0, MOSS, 31.0)
	_prim(_sph(0.34, 6, 3), _xf(Vector3(0.72, 0.08, 0.48)), STONE.darkened(0.12), 0.06, 0.0, MOSS, 32.0)
	_prim(_sph(0.2, 5, 3), _xf(Vector3(-0.2, 0.02, 0.62)), STONE.lightened(0.05), 0.04, 0.0, NO_TOP, 33.0)
	_prim(_sph(0.16, 5, 3), _xf(Vector3(0.45, 0.02, -0.55)), STONE, 0.04, 0.0, NO_TOP, 34.0)
	_single("rock_boulder", _commit("rock_boulder", env_mat))

	# Slab: stacked stratified plates, each shifted and tilted, moss on the ledges.
	_begin()
	var plates: Array = [
		[Vector3(1.65, 0.4, 1.3), Vector3(0, 0.1, 0), Vector3(0.05, 0.2, 0.06), STONE_W.darkened(0.08)],
		[Vector3(1.35, 0.34, 1.0), Vector3(-0.1, 0.46, 0.06), Vector3(-0.08, 0.55, 0.05), STONE_W],
		[Vector3(1.0, 0.3, 0.8), Vector3(0.1, 0.77, -0.05), Vector3(0.1, 0.95, -0.06), STONE_W.lightened(0.05)],
		[Vector3(0.55, 0.26, 0.45), Vector3(0.22, 1.03, 0.05), Vector3(0.14, 1.4, -0.1), STONE_W.lightened(0.1)],
	]
	var pi2: int = 0
	for pl: Array in plates:
		_prim(_box(pl[0] as Vector3, 1), _xf(pl[1] as Vector3, pl[2] as Vector3), pl[3] as Color, 0.07, 0.0,
			MOSS_HEAVY if pi2 < 3 else MOSS, 33.0 + pi2)
		pi2 += 1
	_prim(_box(Vector3(0.4, 0.25, 0.35)), _xf(Vector3(0.85, 0.05, 0.55), Vector3(0.2, 0.4, 0.1)), STONE_W.darkened(0.1),
		0.04, 0.0, NO_TOP, 39.0)
	_single("rock_slab", _commit("rock_slab", env_mat))

	# Shards: blue-grey crystalline spikes out of a low mound.
	_begin()
	_prim(_sph(0.72, 7, 3), _xf(Vector3(0, 0.02, 0), Vector3.ZERO, Vector3(1.1, 0.42, 0.9)), STONE_B.darkened(0.18),
		0.09, 0.0, MOSS, 36.0)
	var sh: Array = [
		[Vector3(-0.05, 0.62, 0), 1.45, 0.34, Vector3(0.08, 0.3, -0.1)],
		[Vector3(0.45, 0.4, 0.3), 1.0, 0.27, Vector3(0.3, 1.0, -0.4)],
		[Vector3(-0.48, 0.32, -0.28), 0.85, 0.25, Vector3(-0.35, 2.0, 0.3)],
		[Vector3(0.3, 0.28, -0.42), 0.7, 0.2, Vector3(0.35, 0.5, 0.45)],
		[Vector3(-0.35, 0.22, 0.42), 0.55, 0.18, Vector3(-0.3, 1.4, -0.45)],
	]
	var si: int = 0
	for s2: Array in sh:
		_prim(_cyl(0.03, s2[2] as float, s2[1] as float, 5), _xf(s2[0] as Vector3, s2[3] as Vector3),
			STONE_B.lightened(0.04 * si), 0.04, 0.0, NO_TOP, 37.0 + si)
		si += 1
	_single("rock_shards", _commit("rock_shards", env_mat))

	# Spire (new): a tall weathered needle with a leaning chunk (footprint ~1.4 x 1.1, 2.4 m tall).
	_begin()
	_prim(_cyl(0.18, 0.62, 2.3, 7, 2), _xf(Vector3(0, 1.1, 0), Vector3(0.06, 0.2, -0.05)), STONE, 0.13, 0.0, MOSS, 50.0)
	_prim(_cyl(0.05, 0.3, 0.9, 6), _xf(Vector3(0.05, 2.55, 0.04), Vector3(0.1, 0.9, 0.12)), STONE.lightened(0.06),
		0.06, 0.0, NO_TOP, 51.0)
	_prim(_sph(0.45, 6, 3), _xf(Vector3(0.55, 0.18, 0.2), Vector3(0.3, 0.5, 0.2), Vector3(1.0, 0.7, 0.8)),
		STONE.darkened(0.1), 0.08, 0.0, MOSS_HEAVY, 52.0)
	_prim(_sph(0.3, 5, 3), _xf(Vector3(-0.5, 0.1, -0.25)), STONE.darkened(0.05), 0.05, 0.0, MOSS, 53.0)
	_single("rock_spire", _commit("rock_spire", env_mat))


# --- ruin pillar (3.0 m tall; scale y by height / 3.0. Collider: cylinder r 0.7) ----------------

func _build_pillar() -> void:
	_begin()
	# Two-step plinth.
	_prim(_box(Vector3(1.7, 0.3, 1.7), 1), _xf(Vector3(0, 0.12, 0)), RUIN_D, 0.05, 0.0, MOSS_HEAVY, 40.0)
	_prim(_box(Vector3(1.32, 0.24, 1.32), 1), _xf(Vector3(0, 0.39, 0), Vector3(0, 0.05, 0)), RUIN.darkened(0.08), 0.04,
		0.0, MOSS, 41.0)
	_prim(_cyl(0.66, 0.74, 0.2, 12), _xf(Vector3(0, 0.6, 0)), RUIN, 0.02, 0.0, MOSS, 42.0)
	# Fluted shaft in two drums, the upper one knocked slightly off its seat.
	_arr(_fluted(0.56, 0.49, 1.2, 8), _xf(Vector3(0, 0.7, 0)), RUIN, 0.02, 0.0, NO_TOP, 43.0)
	_prim(_cyl(0.6, 0.6, 0.14, 12), _xf(Vector3(0, 1.95, 0)), RUIN_D.lightened(0.05), 0.015, 0.0, NO_TOP, 44.0)
	_arr(_fluted(0.53, 0.47, 0.62, 8), _xf(Vector3(0.05, 2.02, 0.03), Vector3(0.03, 0.14, 0.02)), RUIN_L, 0.02, 0.0,
		NO_TOP, 45.0)
	_arr(_broken_top(0.52, 0.34, 9, 3.0), _xf(Vector3(0.06, 2.6, 0.04), Vector3(0.05, 0.3, 0.03)), RUIN.darkened(0.12),
		0.04, 0.0, NO_TOP, 46.0)
	# Ivy climbing the shaft on one side: leaf clumps flattened against the stone, thinning out upward.
	for i: int in 3:
		var a: float = -0.55 + i * 0.5
		var d := Vector3(cos(a), 0, sin(a))
		var b := Basis(Vector3.UP, -a)
		for j: int in 5 - i:
			var jy: float = 0.75 + j * 0.36 + i * 0.12
			var jr: float = 0.16 - j * 0.015
			_prim(_sph(jr, 5, 3), Transform3D(b * Basis.from_scale(Vector3(0.45, 1.2, 1.0)),
				d * 0.52 + Vector3(0, jy, 0) + Vector3(-d.z, 0, d.x) * (_h(Vector3(i, j, 47)) - 0.5) * 0.16),
				IVY_L if (i + j) % 2 == 0 else IVY, 0.03, 0.0, NO_TOP, 47.0 + i * 5.0 + j)
	# Fallen chunk and rubble at the foot.
	_prim(_cyl(0.42, 0.45, 0.6, 8), _xf(Vector3(1.0, 0.24, 0.55), Vector3(0.3, 0.4, 1.5708)), RUIN_D, 0.06, 0.0,
		MOSS, 48.0)
	for k: int in 4:
		var a2: float = k * 1.7 + 0.4
		_prim(_box(Vector3(0.28, 0.2, 0.24) * (1.0 + _h(Vector3(k, 5, 5)) * 0.6)),
			_xf(Vector3(cos(a2), 0, sin(a2)) * 1.05 + Vector3(0, 0.06, 0), Vector3(0.2, a2, 0.15)), RUIN_D.lightened(0.05),
			0.04, 0.0, MOSS, 60.0 + k)
	_single("ruin_pillar", _commit("ruin_pillar", env_mat))


# --- crown pedestal (0.8 m tall, r 0.9; the crown gem floats at y 1.8, not part of this scene) ---

func _build_pedestal() -> void:
	_begin()
	_prim(_cyl(0.9, 0.98, 0.25, 10), _xf(Vector3(0, 0.12, 0)), RUIN_D, 0.03, 0.0, NO_TOP, 50.0)
	_prim(_cyl(0.7, 0.78, 0.36, 10), _xf(Vector3(0, 0.43, 0), Vector3(0, 0.39, 0)), RUIN, 0.02, 0.0, NO_TOP, 51.0)
	_prim(_cyl(0.86, 0.72, 0.2, 10), _xf(Vector3(0, 0.7, 0)), RUIN.lightened(0.08), 0.02, 0.0, NO_TOP, 52.0)
	for i: int in 4:
		var a: float = i * PI * 0.5 + PI * 0.25
		var d := Vector3(cos(a), 0, sin(a))
		_prim(_box(Vector3(0.35, 0.8, 0.28)), _xf(d * 1.05 + Vector3(0, 0.3, 0), Vector3(0, -a, 0.25)), RUIN_D, 0.05,
			0.0, MOSS, 53.0 + i)
	# Four rune stubs on the carved ground ring (r 2.9), between the warden spots.
	for i: int in 4:
		var a2: float = i * PI * 0.5
		var d2 := Vector3(cos(a2), 0, sin(a2))
		_prim(_box(Vector3(0.42, 0.55, 0.36), 1), _xf(d2 * 2.9 + Vector3(0, 0.22, 0), Vector3(0.06, -a2, 0.08)),
			RUIN_D.lightened(0.04), 0.05, 0.0, MOSS, 57.0 + i)
	var stone: ArrayMesh = _commit("crown_pedestal", env_mat)
	_begin()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.52
	tor.outer_radius = 0.62
	tor.rings = 16
	tor.ring_segments = 4
	_prim(tor, _xf(Vector3(0, 0.81, 0)), Color.WHITE)
	for i: int in 8:
		var a3: float = i * TAU / 8.0 + 0.39 / 2.0
		_prim(_box(Vector3(0.08, 0.22, 0.14)), _xf(Vector3(cos(a3), 0, sin(a3)) * 0.73 + Vector3(0, 0.43, 0),
			Vector3(0, -a3, 0)), Color.WHITE)
	# Rune slits on the 4 stubs (they glow and tint with the pedestal: sealed = red).
	for i: int in 4:
		var a4: float = i * PI * 0.5
		var d4 := Vector3(cos(a4), 0, sin(a4))
		_prim(_box(Vector3(0.07, 0.3, 0.2)), _xf(d4 * 2.68 + Vector3(0, 0.3, 0), Vector3(0, -a4, 0)), Color.WHITE)
	var runes: ArrayMesh = _commit("crown_pedestal_runes", ember_mat)
	var dressing: ArrayMesh = _build_ruin_dressing()
	var root := Node3D.new()
	root.name = "CrownPedestal"
	_mi(root, stone, "Stone")
	var r: MeshInstance3D = _mi(root, runes, "Runes")
	r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Rubble, fallen drums and a broken lintel around the pillar ring (radius 8, no colliders, all low).
	var dm: MeshInstance3D = _mi(root, dressing, "RuinDressing")
	dm.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_pack("crown_pedestal", root)


## Only rebuilds meshes/crown_ruin_dressing.res (used by the A2.3 altar); the old pedestal / crystal scenes are not
## written any more.
func _build_ruin_dressing_only() -> void:
	_build_ruin_dressing()


## Low debris around the 10 pillar spots of the crown ring (radius 8) and outside it. Nothing inside r 7 but
## flat rubble, nothing taller than ~0.85 m, so units walking through it read fine.
func _build_ruin_dressing() -> ArrayMesh:
	_begin()
	for i: int in 10:
		var a: float = i * TAU / 10.0
		for k: int in 3:
			var hh: float = _h(Vector3(i, k, 9))
			var ak: float = a + (hh - 0.5) * 0.35
			var rr: float = 8.0 + (1.2 + hh * 0.9) * (1.0 if k != 1 else -0.75)
			var s: float = 0.22 + _h(Vector3(k, i, 3)) * 0.22
			_prim(_box(Vector3(s * 1.4, s, s * 1.1), 1), _xf(Vector3(cos(ak) * rr, s * 0.3, sin(ak) * rr),
				Vector3(hh * 0.5, hh * 6.0, 0.2)), RUIN_D.lerp(RUIN, hh), 0.04, 0.0, MOSS, 70.0 + i * 3 + k)
	# Fallen drums lying between pillars, outside the ring.
	for i: int in [1, 3, 6, 8]:
		var a2: float = (i + 0.5) * TAU / 10.0
		var d := Vector3(cos(a2), 0, sin(a2))
		var tangent := Vector3(-d.z, 0, d.x)
		var b := Basis(tangent, 0.0)
		b = Basis.looking_at(tangent, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5)
		_arr(_fluted(0.42, 0.37, 0.95, 8), Transform3D(b, d * 10.2 + Vector3(0, 0.36, 0) - tangent * 0.45), RUIN,
			0.02, 0.0, MOSS_LIGHT, 90.0 + i)
	# A broken lintel slab and a toppled capital. 12.V3 handoff: kept >= 0.5 rad off the lane axis (135 / 315 deg),
	# where the Crown Bridges' decks now reach the isle (were at 2.2 / 5.35 rad, in the lane).
	_prim(_box(Vector3(2.4, 0.45, 0.62), 1), _xf(Vector3(cos(1.8) * 10.6, 0.2, sin(1.8) * 10.6), Vector3(0.05, -1.8 + 1.3, 0.12)),
		RUIN.darkened(0.04), 0.05, 0.0, MOSS_LIGHT, 95.0)
	_prim(_box(Vector3(0.9, 0.35, 0.9), 1), _xf(Vector3(cos(4.95) * 10.3, 0.15, sin(4.95) * 10.3), Vector3(0.25, 0.2, 0.1)),
		RUIN, 0.05, 0.0, MOSS_LIGHT, 96.0)
	# Kerb fragments along the plaza rim.
	for i: int in 16:
		var a3: float = i * TAU / 16.0 + _h(Vector3(i, 1, 1)) * 0.2
		if _h(Vector3(i, 2, 2)) < 0.35:
			continue
		_prim(_box(Vector3(0.9, 0.22, 0.38)), _xf(Vector3(cos(a3), 0, sin(a3)) * 9.35 + Vector3(0, 0.06, 0),
			Vector3(0, -a3 + PI * 0.5, 0.05)), RUIN_D.lightened(0.06), 0.03, 0.0, MOSS, 100.0 + i)
	return _commit("crown_ruin_dressing", env_mat)


# --- crystal node (disc r 1.2; collider cylinder r 1.2, h 2) ------------------------------------

func _prism_mesh(name: String, h: float) -> ArrayMesh:
	_begin()
	var body: float = h * 0.74
	_prim(_cyl(0.25, 0.19, body, 6), _xf(Vector3(0, body * 0.5, 0)), Color.WHITE, 0.0)
	_prim(_cyl(0.0, 0.25, h - body, 6), _xf(Vector3(0, body + (h - body) * 0.5, 0)), Color.WHITE, 0.0)
	return _commit(name, crystal_mat)


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
			var a: float = clampf(star + diag + core, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	var tex := ImageTexture.create_from_image(img)
	_save(tex, DIR + "sparkle_tex.res")
	return tex


func _build_crystal_node() -> void:
	_begin()
	_prim(_cyl(1.05, 1.2, 0.32, 10), _xf(Vector3(0, 0.1, 0)), STONE_D.lightened(0.12), 0.07, 0.0, NO_TOP, 60.0)
	for i: int in 7:
		var a: float = i * TAU / 7.0 + 0.3
		var rr: float = 0.2 + _h(Vector3(i, 7, 0)) * 0.16
		_prim(_sph(rr, 5, 3), _xf(Vector3(cos(a), 0, sin(a)) * 1.08 + Vector3(0, 0.12, 0)), STONE_D, 0.05, 0.0,
			MOSS, 61.0 + i)
	var disc: ArrayMesh = _commit("crystal_node_disc", env_mat)
	var root := Node3D.new()
	root.name = "CrystalNodeArt"
	root.set_script(load(DIR + "crystal_node_art.gd"))
	_mi(root, disc, "Disc")
	var heights: Array[float] = [1.7, 1.25, 0.95]
	var offsets: Array[Vector3] = [Vector3(0.0, 0.2, -0.1), Vector3(0.5, 0.2, 0.3), Vector3(-0.42, 0.2, 0.38)]
	var tilts: Array[Vector3] = [Vector3(0.05, 0.0, 0.08), Vector3(0.18, 0.6, -0.32), Vector3(0.28, 1.2, 0.25)]
	for i: int in 3:
		var pm: ArrayMesh = _prism_mesh("crystal_prism_%d" % i, heights[i])
		var p: MeshInstance3D = _mi(root, pm, "Prism%d" % i, offsets[i])
		p.rotation = tilts[i]
	# Small shards around the big prisms (they go when the node runs low).
	_begin()
	for i: int in 5:
		var a4: float = i * TAU / 5.0 + 1.1
		var hh: float = 0.3 + _h(Vector3(i, 3, 8)) * 0.25
		_prim(_cyl(0.0, 0.1, hh, 5), _xf(Vector3(cos(a4) * 0.78, 0.2 + hh * 0.4, sin(a4) * 0.78),
			Vector3(cos(a4) * 0.45, a4, sin(a4) * 0.45)), Color.WHITE)
	var shards: MeshInstance3D = _mi(root, _commit("crystal_shards", crystal_mat), "Shards")
	shards.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_begin()
	for i: int in 3:
		var a2: float = i * TAU / 3.0
		_prim(_sph(0.08, 4, 2), _xf(Vector3(cos(a2) * 0.95, 1.1 + i * 0.3, sin(a2) * 0.95)), Color.WHITE)
	var motes := Node3D.new()
	motes.name = "Motes"
	root.add_child(motes)
	var mm: MeshInstance3D = _mi(motes, _commit("crystal_motes", crystal_mat), "MotesMesh")
	mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Soft cyan light pool on the ground (additive, no light cost).
	var grad := Gradient.new()
	grad.set_color(0, Color(0.35, 0.8, 1.0, 0.5))
	grad.set_color(1, Color(0.2, 0.55, 1.0, 0.0))
	grad.add_point(0.45, Color(0.3, 0.7, 1.0, 0.22))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 64
	gt.height = 64
	var pool_mat := StandardMaterial3D.new()
	pool_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pool_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pool_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pool_mat.disable_fog = true  # G-E 5: an additive quad must not fog
	pool_mat.albedo_texture = gt
	pool_mat.albedo_color = Color(0.8, 1.0, 1.0)
	pool_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var plane := PlaneMesh.new()
	plane.size = Vector2(4.2, 4.2)
	plane.material = pool_mat
	var pool: MeshInstance3D = _mi(root, plane, "GroundGlow", Vector3(0, 0.05, 0))
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Sparkles: star glints popping around the prisms (10 particles, one draw call).
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
	quad.size = Vector2(0.42, 0.42)
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
	ppm.emission_box_extents = Vector3(0.55, 0.75, 0.55)
	ppm.direction = Vector3(0, 1, 0)
	ppm.spread = 25.0
	ppm.initial_velocity_min = 0.05
	ppm.initial_velocity_max = 0.25
	ppm.gravity = Vector3.ZERO
	ppm.scale_min = 0.6
	ppm.scale_max = 1.3
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
	sp.position = Vector3(0, 0.95, 0.05)
	sp.visibility_aabb = AABB(Vector3(-1.5, -1.5, -1.5), Vector3(3, 3.5, 3))
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(sp)
	_pack("crystal_node", root)


# --- Lost Cache chest (1.0 x 0.7 x 0.7, lid hinged on -z) ---------------------------------------

func _build_cache() -> void:
	_begin()
	_prim(_box(Vector3(1.0, 0.5, 0.7)), _xf(Vector3(0, 0.27, 0)), WOOD, 0.015, 0.0, NO_TOP, 70.0)
	_prim(_box(Vector3(1.05, 0.08, 0.75)), _xf(Vector3(0, 0.1, 0)), GOLD)
	_prim(_box(Vector3(1.05, 0.08, 0.75)), _xf(Vector3(0, 0.46, 0)), GOLD)
	for x: float in [-0.3, 0.3]:
		_prim(_box(Vector3(0.09, 0.52, 0.75)), _xf(Vector3(x, 0.27, 0)), GOLD.darkened(0.15))
	for x2: float in [-0.42, 0.42]:
		for z: float in [-0.27, 0.27]:
			_prim(_box(Vector3(0.14, 0.06, 0.14)), _xf(Vector3(x2, 0.02, z)), METAL)
	var body: ArrayMesh = _commit("lost_cache_body", env_mat)
	_begin()
	_prim(_box(Vector3(1.0, 0.16, 0.7)), _xf(Vector3(0, 0.08, 0.35)), WOOD.lightened(0.05), 0.01)
	var half := CylinderMesh.new()
	half.top_radius = 0.35
	half.bottom_radius = 0.35
	half.height = 1.0
	half.radial_segments = 8
	half.rings = 0
	_prim(half, _xf(Vector3(0, 0.16, 0.35), Vector3(0, 0, PI * 0.5), Vector3(0.5, 1.0, 1.0)), WOOD.lightened(0.08), 0.01)
	for x3: float in [-0.3, 0.3]:
		_prim(half, _xf(Vector3(x3, 0.16, 0.35), Vector3(0, 0, PI * 0.5), Vector3(0.53, 0.09, 1.04)), GOLD)
	_prim(_box(Vector3(0.2, 0.22, 0.06)), _xf(Vector3(0, 0.06, 0.72)), GOLD)
	var lid: ArrayMesh = _commit("lost_cache_lid", env_mat)
	_begin()
	_prim(_sph(0.07, 6, 3), _xf(Vector3(0, 0.08, 0.76)), Color.WHITE)
	var gem: ArrayMesh = _commit("lost_cache_gem", lantern_mat)
	_begin()
	_prim(_box(Vector3(0.88, 0.05, 0.58)), _xf(Vector3(0, 0.5, 0)), Color.WHITE)
	var inner: ArrayMesh = _commit("lost_cache_inner", lantern_mat)

	var root := Node3D.new()
	root.name = "LostCacheArt"
	root.set_script(load(DIR + "lost_cache_art.gd"))
	_mi(root, body, "Body")
	var pivot := Node3D.new()
	pivot.name = "LidPivot"
	pivot.position = Vector3(0, 0.52, -0.35)
	root.add_child(pivot)
	_mi(pivot, lid, "Lid")
	var g: MeshInstance3D = _mi(pivot, gem, "LockGem")
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ig: MeshInstance3D = _mi(root, inner, "InnerGlow")
	ig.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ig.visible = false
	_pack("lost_cache", root)


# --- Ruin Peddler stand (collider box 3.2 x 1.8 x 1.8 at (0.4, 0.9, 0)) --------------------------

func _build_peddler() -> void:
	# Cart at x 0.6 (2 x 1 x 1.5) with canopy and goods.
	_begin()
	var cx: float = 0.6
	_prim(_box(Vector3(2.0, 0.5, 1.5)), _xf(Vector3(cx, 0.65, 0)), WOOD, 0.02, 0.0, NO_TOP, 80.0)
	_prim(_box(Vector3(2.08, 0.1, 1.58)), _xf(Vector3(cx, 0.9, 0)), WOOD_D)
	for z: float in [-0.8, 0.8]:
		_prim(_cyl(0.42, 0.42, 0.12, 8), _xf(Vector3(cx, 0.42, z), Vector3(PI * 0.5, 0, 0)), WOOD_D, 0.02)
		_prim(_cyl(0.12, 0.12, 0.16, 6), _xf(Vector3(cx, 0.42, z), Vector3(PI * 0.5, 0, 0)), METAL)
	for z2: float in [-0.45, 0.45]:
		_prim(_box(Vector3(0.9, 0.08, 0.08)), _xf(Vector3(cx + 1.25, 0.6, z2), Vector3(0, 0, 0.25)), WOOD_D)
	for x: float in [-0.88, 0.88]:
		for z3: float in [-0.66, 0.66]:
			_prim(_cyl(0.05, 0.06, 1.45, 5), _xf(Vector3(cx + x, 1.62, z3)), WOOD_D)
	# Striped canopy, tilted toward the front (+z, the camera side).
	for i: int in 5:
		var zz: float = -0.8 + i * 0.4
		_prim(_box(Vector3(2.3, 0.08, 0.41)), _xf(Vector3(cx, 2.42 - zz * 0.12, zz), Vector3(0.12, 0, 0)),
			CLOTH_R if i % 2 == 0 else CLOTH_C, 0.02)
	# Goods: crates, jars, rolled rug.
	_prim(_box(Vector3(0.45, 0.4, 0.45)), _xf(Vector3(cx - 0.6, 1.15, -0.3), Vector3(0, 0.3, 0)), WOOD.lightened(0.1), 0.02)
	_prim(_box(Vector3(0.35, 0.3, 0.35)), _xf(Vector3(cx - 0.55, 1.5, -0.3), Vector3(0, 0.9, 0)), WOOD, 0.02)
	var jars: Array[Color] = [Color(0.25, 0.45, 0.85), Color(0.30, 0.65, 0.30), Color(0.75, 0.25, 0.35)]
	for j: int in 3:
		_prim(_cyl(0.1, 0.14, 0.32, 6), _xf(Vector3(cx + 0.1 + j * 0.28, 1.12, 0.35)), jars[j])
	_prim(_cyl(0.16, 0.16, 1.2, 6), _xf(Vector3(cx + 0.45, 1.12, -0.35), Vector3(0, 0.2, PI * 0.5)), SCARF)
	# Lantern cage (hangs from the pivot, built in pivot space below).
	var cart: ArrayMesh = _commit("peddler_cart", env_mat)

	# The peddler (x -0.8), hooded, with a big backpack and a staff. Faces +z.
	_begin()
	_prim(_cyl(0.22, 0.46, 1.3, 7), _xf(Vector3(0, 0.65, 0)), ROBE, 0.03, 0.0, NO_TOP, 90.0)
	_prim(_sph(0.3, 7, 4), _xf(Vector3(0, 1.35, 0), Vector3.ZERO, Vector3(1.1, 0.8, 1.0)), ROBE, 0.02)
	_prim(_cyl(0.26, 0.3, 0.12, 7), _xf(Vector3(0, 1.45, 0.02)), SCARF, 0.01)
	_prim(_sph(0.27, 7, 4), _xf(Vector3(0, 1.66, -0.02), Vector3(0.2, 0, 0), Vector3(1.0, 1.15, 1.05)), ROBE_D, 0.02)
	_prim(_sph(0.16, 6, 3), _xf(Vector3(0, 1.62, 0.16), Vector3.ZERO, Vector3(1.0, 1.0, 0.5)), Color(0.08, 0.06, 0.05))
	_prim(_box(Vector3(0.55, 0.65, 0.38)), _xf(Vector3(0, 1.25, -0.34), Vector3(0.1, 0, 0)), WOOD, 0.02)
	_prim(_cyl(0.14, 0.14, 0.7, 6), _xf(Vector3(0, 1.66, -0.36), Vector3(0, 0, PI * 0.5)), CLOTH_R)
	_prim(_cyl(0.035, 0.045, 1.95, 5), _xf(Vector3(0.38, 0.97, 0.12), Vector3(0.05, 0, -0.08)), WOOD_D)
	var figure: ArrayMesh = _commit("peddler_figure", env_mat)

	_begin()
	_prim(_cyl(0.015, 0.015, 0.25, 4), _xf(Vector3(0, -0.12, 0)), METAL)
	_prim(_cyl(0.08, 0.16, 0.08, 6), _xf(Vector3(0, -0.25, 0)), METAL)
	_prim(_cyl(0.14, 0.08, 0.06, 6), _xf(Vector3(0, -0.6, 0)), METAL)
	var cage: ArrayMesh = _commit("peddler_lantern_cage", env_mat)
	_begin()
	_prim(_sph(0.18, 8, 4), _xf(Vector3(0, -0.42, 0)), Color.WHITE)
	var orb: ArrayMesh = _commit("peddler_lantern_orb", lantern_mat)

	var root := Node3D.new()
	root.name = "RuinPeddlerArt"
	root.set_script(load(DIR + "ruin_peddler_art.gd"))
	_mi(root, cart, "Cart")
	_mi(root, figure, "Peddler", Vector3(-0.8, 0, 0))
	var pivot := Node3D.new()
	pivot.name = "LanternPivot"
	pivot.position = Vector3(cx, 2.32, 0)
	root.add_child(pivot)
	_mi(pivot, cage, "Cage")
	var o: MeshInstance3D = _mi(pivot, orb, "Orb")
	o.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var light := OmniLight3D.new()
	light.name = "LanternLight"
	light.position = Vector3(0, -0.42, 0)
	light.light_color = Color(1.0, 0.78, 0.45)
	light.light_energy = 1.4
	light.omni_range = 4.5
	light.shadow_enabled = false
	light.light_specular = 0.2
	pivot.add_child(light)
	_pack("ruin_peddler", root)


# --- decor (no colliders; scattered by map_dressing_art.gd) ------------------------------------

func _build_decor() -> void:
	# Grass clump: 7 blades, ~0.4 m.
	_begin()
	for i: int in 7:
		var a: float = i * 2.4
		var r: float = 0.04 + _h(Vector3(i, 1, 1)) * 0.1
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		var hh: float = 0.26 + _h(Vector3(i, 2, 1)) * 0.2
		_arr(_blade(p, hh, 0.035, Vector3(cos(a), 0, sin(a)) * 0.1), Transform3D.IDENTITY,
			BLADE.lerp(BLADE.lightened(0.25), _h(Vector3(i, 3, 1))), 0.0, 0.0)
	_commit("decor_grass", env_mat)

	# Flower clumps: 4 stems with heads (white / yellow / purple variants) and a few leaves.
	var heads: Array[Color] = [FLOWER_W, FLOWER_Y, FLOWER_P]
	var names: Array[String] = ["decor_flowers_w", "decor_flowers_y", "decor_flowers_p"]
	for f: int in 3:
		_begin()
		for i: int in 4:
			var a2: float = i * 1.9 + f
			var p2 := Vector3(cos(a2), 0, sin(a2)) * (0.05 + 0.1 * _h(Vector3(i, f, 4)))
			var hh2: float = 0.22 + _h(Vector3(i, f, 5)) * 0.16
			_arr(_blade(p2, hh2, 0.015, Vector3(cos(a2), 0, sin(a2)) * 0.04), Transform3D.IDENTITY, STEM)
			_prim(_sph(0.06, 4, 2), _xf(p2 + Vector3(cos(a2) * 0.04, hh2, sin(a2) * 0.04), Vector3.ZERO,
				Vector3(1.0, 0.6, 1.0)), heads[f], 0.0)
		for i: int in 3:
			var a3: float = i * 2.1 + 0.5
			_arr(_blade(Vector3.ZERO, 0.14, 0.04, Vector3(cos(a3), 0, sin(a3)) * 0.12), Transform3D.IDENTITY, BLADE)
		_commit(names[f], env_mat)

	# Bush: 5 lumpy blobs, ~0.9 m.
	_begin()
	var bl: Array = [[Vector3(0, 0.38, 0), 0.5], [Vector3(0.38, 0.28, 0.15), 0.36], [Vector3(-0.35, 0.3, -0.12), 0.38],
		[Vector3(0.05, 0.3, 0.38), 0.33], [Vector3(0.1, 0.66, -0.05), 0.3]]
	var k: int = 0
	for b: Array in bl:
		_prim(_sph(b[1] as float, 6, 3), _xf(b[0] as Vector3, Vector3(0, k, 0), Vector3(1.0, 0.85, 1.0)),
			BUSH.lerp(BUSH_L, k / 4.0), 0.07, 0.4, NO_TOP, 110.0 + k)
		k += 1
	_commit("decor_bush", env_mat)

	# Berry bush: smaller, darker, with red berries.
	_begin()
	for i: int in 4:
		var a4: float = i * 1.6
		_prim(_sph(0.3 + 0.06 * (i % 2), 6, 3), _xf(Vector3(cos(a4) * 0.22, 0.28 + (i % 2) * 0.12, sin(a4) * 0.22),
			Vector3.ZERO, Vector3(1.0, 0.85, 1.0)), BUSH.darkened(0.1).lerp(BUSH_L, i * 0.15), 0.06, 0.4, NO_TOP, 120.0 + i)
	for i: int in 9:
		var a5: float = i * 2.3
		var y5: float = 0.3 + _h(Vector3(i, 9, 9)) * 0.3
		_prim(_sph(0.055, 4, 2), _xf(Vector3(cos(a5) * 0.42, y5, sin(a5) * 0.42)), BERRY, 0.0)
	_commit("decor_bush_berry", env_mat)

	# Fern: 7 fronds arching out of the ground.
	_begin()
	for i: int in 7:
		var a6: float = i * TAU / 7.0 + 0.2
		var b6 := Basis(Vector3.UP, -a6) * Basis(Vector3.BACK, 0.55 + 0.2 * _h(Vector3(i, 6, 6)))
		_prim(_sph(0.5, 5, 2), Transform3D(b6 * Basis.from_scale(Vector3(0.62, 0.05, 0.13)),
			Basis(Vector3.UP, -a6) * Vector3(0.36, 0.2, 0)), FERN.lerp(FERN.lightened(0.2), _h(Vector3(i, 7, 7))), 0.0,
			0.3)
	_commit("decor_fern", env_mat)

	# Mushrooms: 3 red caps on pale stems.
	_begin()
	var ms: Array = [[Vector3(0, 0, 0), 0.22], [Vector3(0.16, 0, 0.1), 0.15], [Vector3(-0.1, 0, 0.14), 0.12]]
	for m: Array in ms:
		var hm: float = m[1] as float
		_prim(_cyl(0.03, 0.045, hm, 5), _xf((m[0] as Vector3) + Vector3(0, hm * 0.5, 0)), MUSH_STEM)
		_prim(_sph(hm * 0.55, 6, 3), _xf((m[0] as Vector3) + Vector3(0, hm, 0), Vector3.ZERO, Vector3(1.0, 0.55, 1.0)),
			MUSH_CAP, 0.01)
	_commit("decor_mushrooms", env_mat)

	# Stump with cut top and roots.
	_begin()
	_prim(_cyl(0.3, 0.38, 0.45, 8), _xf(Vector3(0, 0.2, 0)), TRUNK, 0.03, 0.0, MOSS, 130.0)
	_prim(_cyl(0.27, 0.27, 0.04, 8), _xf(Vector3(0, 0.44, 0)), WOOD_CUT, 0.01)
	_roots(130.0, TRUNK_D, 0.3)
	_commit("decor_stump", env_mat)

	# Fallen log with a snapped branch and moss on top (~2.2 m long).
	_begin()
	_prim(_cyl(0.24, 0.28, 2.2, 7), _xf(Vector3(0, 0.22, 0), Vector3(0, 0, PI * 0.5)), TRUNK, 0.04, 0.0, MOSS_HEAVY, 140.0)
	_prim(_cyl(0.23, 0.23, 0.03, 7), _xf(Vector3(1.11, 0.22, 0), Vector3(0, 0, PI * 0.5)), WOOD_CUT)
	_prim(_cyl(0.05, 0.09, 0.6, 5), _xf(Vector3(-0.4, 0.45, 0.12), Vector3(0.4, 0, 0.5)), TRUNK_D, 0.02)
	_commit("decor_log", env_mat)

	# Stones: 4 small mossy stones.
	_begin()
	for i: int in 4:
		var a7: float = i * 1.9
		var r7: float = 0.12 + _h(Vector3(i, 11, 3)) * 0.14
		_prim(_sph(r7, 6, 3), _xf(Vector3(cos(a7), 0, sin(a7)) * 0.28 + Vector3(0, r7 * 0.2, 0), Vector3(0.2, a7, 0.1),
			Vector3(1.0, 0.7, 0.9)), STONE.lerp(STONE_W, _h(Vector3(i, 1, 9))), 0.04, 0.0, MOSS, 150.0 + i)
	_commit("decor_stones", env_mat)


# --- map edge: cliffs + plateau around the 120 x 120 map (map_dressing) -------------------------

## Perimeter samples of the map square, walking N (-z) -> E (+x) -> S (+z) -> W (-x), with quarter-circle
## fans at the corners: [point on the square, outward normal].
func _perimeter(step: float, arc_steps: int) -> Array:
	var out: Array = []
	var h: float = MAP_HALF
	var sides: Array = [
		[Vector3(-h, 0, -h), Vector3(1, 0, 0), Vector3(0, 0, -1)],
		[Vector3(h, 0, -h), Vector3(0, 0, 1), Vector3(1, 0, 0)],
		[Vector3(h, 0, h), Vector3(-1, 0, 0), Vector3(0, 0, 1)],
		[Vector3(-h, 0, h), Vector3(0, 0, -1), Vector3(-1, 0, 0)],
	]
	for k: int in 4:
		var start: Vector3 = sides[k][0]
		var t: Vector3 = sides[k][1]
		var nrm: Vector3 = sides[k][2]
		var cnt: int = int(round(2.0 * h / step))
		for i: int in cnt:
			out.append([start + t * (i * 2.0 * h / cnt), nrm])
		var corner: Vector3 = start + t * 2.0 * h
		var nrm2: Vector3 = sides[(k + 1) % 4][2]
		for j: int in arc_steps:
			var a: float = float(j) / arc_steps * PI * 0.5
			out.append([corner, (nrm * cos(a) + nrm2 * sin(a)).normalized()])
	return out


## Cliff height by facing: tall at the back (north / west, the camera sees their faces), low at the front
## (south: it is between the camera and the map, so it must not hide units at the edge).
func _side_height(nrm: Vector3) -> float:
	var w: float = maxf(-nrm.z, 0.0) * 10.0 + maxf(nrm.z, 0.0) * 3.0 + maxf(-nrm.x, 0.0) * 8.5 + maxf(nrm.x, 0.0) * 7.5
	return w / (absf(nrm.x) + absf(nrm.z))


## Builds the closed ring (maps without the river: river_mouths/map_cliffs_closed.res + map_plateau_closed.res, the
## pre-12.V5 ring with the same seeds) and the open ring with the river mouths (meshes/map_cliffs.res +
## map_plateau.res, the scene default), then the mouth meshes. _cols stays the closed ring (border trees use it).
func _build_map_edge() -> void:
	_open_edge = false
	_gap = {}
	_cols_closed = _make_cols(false)
	_cols = _cols_closed
	_build_cliffs(_cols_closed, RM_DIR + "map_cliffs_closed.res", Vector2(INF, -INF))
	var closed_range: Vector2 = _last_range
	_build_plateau(_cols_closed, RM_DIR + "map_plateau_closed.res")
	_open_edge = true
	_cols_open = _make_cols(true)
	_gap = _gorge_gap(_cols_open)
	_build_cliffs(_cols_open, MESH_DIR + "map_cliffs.res", closed_range)
	_build_plateau(_cols_open, MESH_DIR + "map_plateau.res")
	_build_mouth_meshes()
	_open_edge = false
	_cols = _cols_closed


## One column per perimeter sample: [base, normal, profile_d, profile_y, plateau y, valley depth, notch weight].
## `open` cuts the north notch (recessed face, lowered crest, valley) into the columns around NOTCH_X.
func _make_cols(open: bool) -> Array:
	var samples: Array = _perimeter(1.6, 7)
	var m: int = samples.size()
	var s_len: float = 0.0
	var cols: Array = []
	for i: int in m:
		var base: Vector3 = samples[i][0]
		var nrm: Vector3 = samples[i][1]
		s_len += 1.6
		var u: float = maxf(0.0, 0.9 + 0.8 * sin(s_len * 0.047 + 1.3) + 0.5 * sin(s_len * 0.13 + 0.4)
			+ 0.25 * sin(s_len * 0.37 + 2.0))
		# Buttresses: sharp vertical ridges pushing out of the wall every few metres.
		var bb: float = pow(absf(sin(s_len * 0.19 + 1.7 * sin(s_len * 0.043))), 4.0) * 1.8 - 0.6
		var hh: float = _side_height(nrm) * (0.84 + 0.22 * (0.5 + 0.5 * sin(s_len * 0.071 + 0.7)) + 0.08 * sin(s_len * 0.29)
			+ bb * 0.05)
		var yp: float = maxf(hh * 0.84, 2.2)
		var d1: float = maxf(0.45, 0.9 + u * 0.3 - bb * 0.5)
		var d2: float = maxf(d1 + 0.2, 1.7 + u * 0.6 - bb * 0.8)
		var d3: float = maxf(d2 + 0.2, 2.5 + u * 0.85 - bb * 0.6)
		var d4: float = maxf(d3 + 0.15, 2.8 + u - bb * 0.25)
		var d5: float = maxf(d4 + 0.15, 3.1 + u)
		var pd := PackedFloat32Array([0.3, d1, d2, d3, d4, d5, d5 + 1.6, d5 + 3.9])
		# Wavy strata: the band lines rise and fall along the wall.
		var py := PackedFloat32Array([-0.5, hh * (0.28 + 0.06 * sin(s_len * 0.13)), hh * (0.58 + 0.06 * sin(s_len * 0.09 + 1.0)),
			hh * (0.86 + 0.03 * sin(s_len * 0.17 + 2.0)), hh - 0.35, hh, hh * 0.98, yp])
		cols.append([base, nrm, pd, py, yp, 0.0, 0.0])
	if open:
		_notch_cols(cols)
	return cols


## The north notch: the columns around NOTCH_X blend (weight f) toward one shared profile: the face pushed back
## NOTCH_RECESS and made steep (the fall needs room in front of it), the crest cut down to the lip, the plateau
## behind it lowered into a valley for the stream. All f = 1 columns share the same heights, so the lip is level.
func _notch_cols(cols: Array) -> void:
	var sum: float = 0.0
	var n: int = 0
	for i: int in 75:
		if absf((cols[i][0] as Vector3).x - NOTCH_X) < NOTCH_CORE:
			sum += float(cols[i][4])
			n += 1
	_notch_yp = sum / maxf(float(n), 1.0)
	_notch_lip = _notch_yp - NOTCH_VALLEY - 0.05
	_notch_pd = PackedFloat32Array([1.9, 2.3, 2.75, 3.2, 3.6, 4.0, 5.6, 7.9])
	_notch_py = PackedFloat32Array([-0.5, 2.6, 4.9, _notch_lip - 0.55, _notch_lip, _notch_lip, _notch_lip,
		_notch_lip + 0.05])
	for i: int in 75:
		var col: Array = cols[i]
		var base: Vector3 = col[0]
		var f: float = _notch_f(base.x)
		if f <= 0.0:
			continue
		var pd: PackedFloat32Array = col[2]
		var py: PackedFloat32Array = col[3]
		for k: int in 8:
			pd[k] = lerpf(pd[k], _notch_pd[k], f)
			py[k] = lerpf(py[k], _notch_py[k], f)
		col[2] = pd
		col[3] = py
		col[4] = lerpf(float(col[4]), _notch_yp, f)
		col[5] = NOTCH_VALLEY * f
		col[6] = f
		col[0] = base + (col[1] as Vector3) * NOTCH_RECESS * f
	print("notch: plateau %.2f, lip %.2f" % [_notch_yp, _notch_lip])


## Cliff bands (dark foot -> stone strata -> soil rim -> grass cap), leaning slabs, foot boulders; the open ring adds
## the gorge gap, its end caps, and the rocks / walls of both river mouths. Saved at `path` (env_painted on the
## surface; map_dressing puts cliff_mat.tres on the node).
func _build_cliffs(cols: Array, path: String, grad: Vector2) -> void:
	var m: int = cols.size()
	# Cliff bands: dark foot -> stone strata -> soil rim -> grass cap (flat colours, moss on the ledges).
	_begin()
	var band_cols: Array[Color] = [CLIFF_D, CLIFF, CLIFF_L.lerp(CLIFF_B, 0.3), CLIFF, SOIL, GRASS_CAP, GRASS_CAP]
	var band_tops: Array[Color] = [NO_TOP, MOSS, MOSS, MOSS, NO_TOP, NO_TOP, NO_TOP]
	for band: int in 7:
		var v := PackedVector3Array()
		var n := PackedVector3Array()
		var idx := PackedInt32Array()
		for i: int in m:
			var col: Array = cols[i]
			var base2: Vector3 = col[0]
			var nrm2: Vector3 = col[1]
			var pd2: PackedFloat32Array = col[2]
			var py2: PackedFloat32Array = col[3]
			var hint: Vector3 = (-nrm2 + Vector3.UP * 0.35) if band < 6 else (Vector3.UP + nrm2 * 0.3)
			for r: int in 2:
				v.append(base2 + nrm2 * pd2[band + r] + Vector3.UP * py2[band + r])
				n.append(hint)
		for i: int in m:
			var j: int = (i + 1) % m
			if _gap.has(i) or _gap.has(j):
				continue
			idx.append_array([i * 2, j * 2, i * 2 + 1, j * 2, j * 2 + 1, i * 2 + 1])
		# Same jitter and seed for every band so the shared rows stay welded.
		_arr(_mk(v, n, idx), Transform3D.IDENTITY, band_cols[band], 0.24, 0.0, band_tops[band], 200.0,
			Vector3(1.0, 0.7, 1.0))
	if _open_edge:
		_gap_caps(cols)
		_apron(cols)
	# Rock slabs standing against the wall: they break the long bands into facets and cast shadows on each
	# other; a few rise above the crest so the skyline is not a ruler line. None on the low south bank.
	var slab_cols: Array[Color] = [CLIFF, CLIFF_L, CLIFF_B, CLIFF.darkened(0.12), CLIFF_L.lerp(CLIFF_B, 0.5)]
	for i: int in range(0, m, 2):
		var cs: Array = cols[i]
		var nrm5: Vector3 = cs[1]
		var py5: PackedFloat32Array = cs[3]
		var pd5: PackedFloat32Array = cs[2]
		var big_h: float = py5[5]
		var hs0: float = _h(Vector3(i, 7.0, 3.0))
		if big_h < 4.0 or hs0 < 0.25:
			continue
		if _open_edge and (_gap.has(i) or float(cs[6]) > 0.02):
			continue   # nothing in front of the falls
		var tangent5 := Vector3(-nrm5.z, 0, nrm5.x)
		var hs: float = big_h * (0.5 + 0.62 * _h(Vector3(i, 8.0, 3.0)))
		var ws: float = 1.5 + 1.8 * _h(Vector3(i, 9.0, 3.0))
		var tilt: float = 0.06 + 0.14 * _h(Vector3(i, 10.0, 3.0))
		var yaw: float = (_h(Vector3(i, 11.0, 3.0)) - 0.5) * 0.7
		var d5: float = maxf(pd5[1] + 0.35, 0.85 + tilt * hs * 0.5)   # front bottom edge stays outside the map
		var bs := Basis.looking_at(-nrm5, Vector3.UP) * Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, tilt)
		var ctr: Vector3 = (cs[0] as Vector3) + nrm5 * d5 + tangent5 * (hs0 - 0.5) * 1.2 + Vector3(0, hs * 0.5 - 0.4, 0)
		_prim(_box(Vector3(ws, hs, 1.1), 1), Transform3D(bs, ctr), slab_cols[i % slab_cols.size()], 0.22, 0.0,
			Color(GRASS_TOP.r, GRASS_TOP.g, GRASS_TOP.b, 0.7), 400.0 + i)
	# Boulders and fallen blocks along the cliff foot.
	for i: int in range(0, m, 2):
		var col3: Array = cols[i]
		var base3: Vector3 = col3[0]
		var nrm3: Vector3 = col3[1]
		var hh3: float = _h(Vector3(i, 4.0, 1.0))
		if hh3 < 0.35:
			continue
		if _open_edge and (_gap.has(i) or float(col3[6]) > 0.25):
			continue   # the mouths place their own rocks
		var r3: float = 0.45 + hh3 * 0.9
		var tangent := Vector3(-nrm3.z, 0, nrm3.x)
		var p3: Vector3 = base3 + nrm3 * (0.35 + r3 * 0.55) + tangent * (_h(Vector3(i, 5.0, 2.0)) - 0.5) * 1.2
		_prim(_sph(r3, 6, 4), _xf(p3 + Vector3(0, r3 * 0.2, 0), Vector3(hh3, i * 0.7, 0.2), Vector3(1.0, 0.75, 0.9)),
			CLIFF.lerp(CLIFF_D, hh3 * 0.6), 0.1, 0.0, MOSS, 300.0 + i)
	if _open_edge:
		_north_mouth_rocks()
		_gorge_rocks(cols)
	_commit_to(path, env_mat, grad)


## Plateau: rows following the same columns, rising gently away from the map, under the cliff lip. The open ring
## adds rows (so the notch valley and the gorge hole have clean edges), lowers the valley and leaves the hole open.
func _build_plateau(cols: Array, path: String) -> void:
	var m: int = cols.size()
	var v2 := PackedVector3Array()
	var n2 := PackedVector3Array()
	var idx2 := PackedInt32Array()
	var rows: Array[float] = [3.2, 7.0, 14.0, 26.0, 50.0, 110.0, 220.0]
	var rise: Array[float] = [-0.05, -0.03, 0.4, 1.4, 3.5, 8.0, 14.0]
	if _open_edge:
		rows = [3.2, 7.0, 11.0, 14.0, 17.0, 20.0, GORGE_HOLE, 26.0, 50.0, 110.0, 220.0]
	var nr: int = rows.size()
	for i: int in m:
		var col4: Array = cols[i]
		var base4: Vector3 = col4[0]
		var nrm4: Vector3 = col4[1]
		var pd4: PackedFloat32Array = col4[2]
		var yp4: float = col4[4]
		for r: int in nr:
			var d: float = rows[r] if r != 1 else pd4[7] + 0.1
			var y: float
			if not _open_edge:
				y = yp4 + rise[r]
			else:
				var f: float = col4[6]
				if r == 0 and f > 0.0:
					d = lerpf(3.2, pd4[5], f)   # tucked under the lowered notch crest
				y = yp4 + _plateau_rise(d, pd4[7] + 0.1) - float(col4[5]) * _valley_fade(d)
				if r == 0:
					y = yp4 - 0.05 - float(col4[5]) - 0.1 * f
			v2.append(base4 + nrm4 * d + Vector3.UP * y)
			n2.append(Vector3.UP)
	for i: int in m:
		var j: int = (i + 1) % m
		var cut: bool = _open_edge and (_gap.has(i) or _gap.has(j))
		for r: int in nr - 1:
			if cut and rows[r + 1] <= GORGE_HOLE + 0.01:
				continue   # the gorge
			var a: int = i * nr + r
			var b: int = j * nr + r
			idx2.append_array([a, b, a + 1, b, b + 1, a + 1])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	# Plain smooth mesh (the ground shader paints it); winding fixed like _arr.
	var fixed := PackedInt32Array()
	for t: int in range(0, idx2.size(), 3):
		var a2: int = idx2[t]
		var b2: int = idx2[t + 1]
		var c2: int = idx2[t + 2]
		var fn: Vector3 = (v2[b2] - v2[a2]).cross(v2[c2] - v2[a2])
		var s: float = 1.0 if fn.y >= 0.0 else -1.0
		if s != _conv:
			fixed.append_array([a2, c2, b2])
		else:
			fixed.append_array([a2, b2, c2])
	arrays[Mesh.ARRAY_VERTEX] = v2
	arrays[Mesh.ARRAY_NORMAL] = n2
	arrays[Mesh.ARRAY_INDEX] = fixed
	var pmesh := ArrayMesh.new()
	pmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	pmesh.surface_set_material(0, plateau_mat)
	_save(pmesh, path)
	print("plateau %s: %d tris" % [path.get_file(), fixed.size() / 3])


# --- river mouths (12.V5) -----------------------------------------------------------------------

## Notch weight of a north column at world x: 1 in the core, 0 outside NOTCH_HALF.
func _notch_f(x: float) -> float:
	return 1.0 - smoothstep(NOTCH_CORE, NOTCH_HALF, absf(x - NOTCH_X))


## How much of the notch valley is left at distance d behind the cliff base (full near the lip, gone by 20 m).
func _valley_fade(d: float) -> float:
	return 1.0 - smoothstep(12.0, 20.0, d)


## Plateau rise above a column's plateau height at distance d, the same piecewise-linear rows as the plateau mesh
## (row 1 sits at d1 = profile_d[7] + 0.1).
func _plateau_rise(d: float, d1: float) -> float:
	var ds: Array[float] = [3.2, d1, 14.0, 26.0, 50.0, 110.0, 220.0]
	var rs: Array[float] = [-0.05, -0.03, 0.4, 1.4, 3.5, 8.0, 14.0]
	if d <= ds[0]:
		return rs[0]
	for k: int in ds.size() - 1:
		if d <= ds[k + 1]:
			return lerpf(rs[k], rs[k + 1], (d - ds[k]) / maxf(ds[k + 1] - ds[k], 0.01))
	return rs[rs.size() - 1]


## Surface height of a column at distance d from its base: the cliff profile, then the plateau (with the valley).
func _col_y(col: Array, d: float) -> float:
	var pd: PackedFloat32Array = col[2]
	var py: PackedFloat32Array = col[3]
	if d <= pd[7]:
		if d <= pd[0]:
			return py[0]
		for k: int in 7:
			if d <= pd[k + 1]:
				return lerpf(py[k], py[k + 1], clampf((d - pd[k]) / maxf(pd[k + 1] - pd[k], 0.01), 0.0, 1.0))
	return float(col[4]) + _plateau_rise(d, pd[7] + 0.1) - float(col[5]) * _valley_fade(d)


## Index of the band a column shows at distance d (0 foot .. 6 grass cap), for colours that must match the cliff.
func _band_at(col: Array, d: float) -> int:
	var pd: PackedFloat32Array = col[2]
	for k: int in 7:
		if d < pd[k + 1]:
			return k
	return 6


## World height of the open ring's surface on the north side at (x, z), between the two nearest columns.
func _north_y(x: float, z: float) -> float:
	var fi: float = clampf((x + MAP_HALF) / 1.6, 0.0, 73.999)
	var i0: int = int(floor(fi))
	var t: float = fi - i0
	var ys: Array[float] = []
	for i: int in [i0, i0 + 1]:
		var col: Array = _cols_open[i]
		ys.append(_col_y(col, (col[0] as Vector3).z - z))
	return lerpf(ys[0], ys[1], t)


# Stream on the north plateau, by distance dc behind the notch base (z = -MAP_HALF - NOTCH_RECESS - dc).
func _stream_x(dc: float) -> float:
	return NOTCH_X + 0.5 * sin((dc - 6.0) * 0.42) * smoothstep(7.0, 11.0, dc)


func _stream_hw(dc: float) -> float:
	return lerpf(1.25, 0.9, smoothstep(8.0, STREAM_END, dc))


func _notch_z(dc: float) -> float:
	return -MAP_HALF - NOTCH_RECESS - dc


## Stream surface: the valley floor under the stream (the highest of the three core columns) + 7 cm.
func _stream_pos(dc: float) -> Vector3:
	var y: float = -INF
	for i: int in [27, 28, 29]:
		y = maxf(y, _col_y(_cols_open[i], dc))
	return Vector3(_stream_x(dc), y + 0.08, _notch_z(dc))


## The notch face's distance behind the notch base at height y (the shared notch profile, inverted).
func _notch_wall_d(y: float) -> float:
	if y <= _notch_py[0]:
		return _notch_pd[0]
	for k: int in 4:
		if y <= _notch_py[k + 1]:
			return lerpf(_notch_pd[k], _notch_pd[k + 1], (y - _notch_py[k]) / maxf(_notch_py[k + 1] - _notch_py[k], 0.01))
	return _notch_pd[4]


## x of the river centre line near N0 (N0 (-15, -62) -> N1 (-12, -48.7)) at z.
func _river_n_x(z: float) -> float:
	return -15.0 + 3.0 * (z + 62.0) / 13.3


## Plunge path: from the foot of the falls (d 0) toward the map, easing onto the river line.
func _plunge_pos(d: float) -> Vector3:
	var z0: float = _notch_z(_notch_pd[0]) + 0.15
	var z: float = z0 + d
	var x: float = lerpf(NOTCH_X, _river_n_x(z), smoothstep(z0, -61.0, z))
	return Vector3(x, MOUTH_WATER_Y, z)


# Gorge by distance d past the south edge (z = MAP_HALF + d).
func _gorge_x(d: float) -> float:
	return S_EDGE_X + 1.1 * (1.0 - exp(-d * 0.2256 / 1.1)) + 0.35 * sin(d * 0.33) * smoothstep(3.0, 8.0, d)


func _gorge_hw(d: float) -> float:
	return lerpf(2.3, 2.05, smoothstep(0.0, 8.0, d))


## Water surface in the gorge: flat pools joined by short chutes at GORGE_STEPS.
func _gorge_wy(d: float) -> float:
	var y: float = GORGE_LEVELS[0]
	for k: int in GORGE_STEPS.size():
		y = lerpf(y, GORGE_LEVELS[k + 1], smoothstep(GORGE_STEPS[k] - CHUTE_HALF, GORGE_STEPS[k] + CHUTE_HALF, d))
	return y


## Sample distances along the gorge: 0.25 m around the chutes (the walls follow the water line), ~0.9 m elsewhere.
func _gorge_samples(from: float, to: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var d: float = from
	while d < to - 0.01:
		out.append(d)
		var near: bool = false
		for sd: float in GORGE_STEPS:
			if absf(d - sd) < CHUTE_HALF + 0.5 + 0.01:
				near = true
		var nxt: float = d + (0.25 if near else 0.9)
		for sd2: float in GORGE_STEPS:
			if d < sd2 - CHUTE_HALF - 0.5 and nxt > sd2 - CHUTE_HALF - 0.5:
				nxt = sd2 - CHUTE_HALF - 0.5   # land exactly where the fine sampling starts
		d = nxt
	out.append(to)
	return out


func _gorge_pos(d: float) -> Vector3:
	return Vector3(_gorge_x(d), _gorge_wy(d), MAP_HALF + d)


## Unit vector across the gorge at d, pointing east (+x).
func _gorge_across(d: float) -> Vector3:
	var dx: float = (_gorge_x(d + 0.05) - _gorge_x(d - 0.05)) / 0.1
	return Vector3(1.0, 0.0, -dx).normalized()


## Rim height of one gorge side at d: the standing column's surface (at least a hair over the map floor).
func _gorge_rim(side: float, d: float) -> float:
	return maxf(_col_y(_cols_open[_kept_e if side > 0.0 else _kept_w], d), 0.1)


## The south columns cut out for the gorge (every column between the gorge's widest rims), and the two left standing.
func _gorge_gap(cols: Array) -> Dictionary:
	var lo: float = INF
	var hi: float = -INF
	var d: float = 0.0
	while d <= GORGE_END:
		var top: float = _gorge_hw(d) + 2.05
		lo = minf(lo, _gorge_x(d) - top)
		hi = maxf(hi, _gorge_x(d) + top)
		d += 0.25
	var gap: Dictionary = {}
	for k: int in 75:
		var x: float = (cols[SOUTH0 + k][0] as Vector3).x
		if x > lo and x < hi:
			gap[SOUTH0 + k] = true
	for k: int in 75:
		var i: int = SOUTH0 + k
		if gap.has(i):
			continue
		if gap.has(i + 1):
			_kept_e = i
		if gap.has(i - 1):
			_kept_w = i
	print("gorge gap: %d columns, x %.2f..%.2f, kept %.1f / %.1f" % [gap.size(), lo, hi,
		(cols[_kept_w][0] as Vector3).x, (cols[_kept_e][0] as Vector3).x])
	return gap


## Rock end walls where the cliff bands stop at the gorge: each standing column's profile, closed down to -0.9,
## facing the gap (same jitter as the bands, so they stay welded). The gorge walls stand in front of them.
func _gap_caps(cols: Array) -> void:
	var m: int = cols.size()
	for i: int in m:
		if _gap.has(i):
			continue
		var toward: int = 0
		if _gap.has((i + 1) % m):
			toward = 1
		elif _gap.has((i - 1 + m) % m):
			toward = -1
		else:
			continue
		var col: Array = cols[i]
		var base: Vector3 = col[0]
		var nrm: Vector3 = col[1]
		var pd: PackedFloat32Array = col[2]
		var py: PackedFloat32Array = col[3]
		var hint: Vector3 = ((cols[(i + toward + m) % m][0] as Vector3) - base).normalized()
		var v := PackedVector3Array()
		var n := PackedVector3Array()
		var idx := PackedInt32Array()
		for k: int in 8:
			v.append(base + nrm * pd[k] + Vector3.UP * py[k])
			v.append(base + nrm * pd[k] + Vector3.UP * -0.9)
			n.append(hint)
			n.append(hint)
		for k: int in 7:
			var a: int = k * 2
			idx.append_array([a, a + 2, a + 1, a + 2, a + 3, a + 1])
		_arr(_mk(v, n, idx), Transform3D.IDENTITY, CLIFF_D, 0.24, 0.0, NO_TOP, 200.0, Vector3(1.0, 0.7, 1.0))


## Open ring: a dark scree apron under the cliff foot (y -0.03, from the map edge to under band 0). With the mouths
## open, RiverMouthsArt turns off the ground plane's painted skirt (ground.gdshader `expand_edge`: the 120 m plane
## stretched to +-260 m at y 0), which would cover the plunge pool and the gorge; this strip replaces it at the foot of
## the walls. Not under the notch (the pool is there) nor the gorge.
func _apron(cols: Array) -> void:
	var m: int = cols.size()
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var skip: Dictionary = {}
	for i: int in m:
		var col: Array = cols[i]
		var nrm: Vector3 = col[1]
		var pd: PackedFloat32Array = col[2]
		# The map-edge point of the column (the notch columns are recessed: measured from the unmoved square).
		var edge: Vector3 = (col[0] as Vector3) - nrm * NOTCH_RECESS * float(col[6])
		v.append(edge + Vector3(0, -0.03, 0))
		v.append((col[0] as Vector3) + nrm * (pd[0] + 0.55) + Vector3(0, -0.03, 0))
		n.append(Vector3.UP)
		n.append(Vector3.UP)
		if _gap.has(i) or float(col[6]) > 0.02:
			skip[i] = true
	for i: int in m:
		var j: int = (i + 1) % m
		if skip.has(i) or skip.has(j):
			continue
		idx.append_array([i * 2, j * 2, i * 2 + 1, j * 2, j * 2 + 1, i * 2 + 1])
	var n0: int = _v.size()
	_arr(_mk(v, n, idx), Transform3D.IDENTITY, CLIFF_D.lerp(SOIL, 0.35), 0.0, 0.0, NO_TOP, 210.0)
	_set_hofs(n0, -0.2)


## A boulder (flat-shaded, moss on top) whose contact band starts at `ground`.
func _rock(p: Vector3, r: float, s: Vector3, col: Color, seed: float, ground: float, top: Color = MOSS) -> void:
	var n0: int = _v.size()
	_prim(_sph(r, 7, 4), _xf(p, Vector3((_h(Vector3(seed, 1.0, 2.0)) - 0.5) * 0.6, seed * 1.37, (_h(Vector3(seed, 3.0, 1.0)) - 0.5) * 0.5), s),
		col, r * 0.2, 0.0, top, seed)
	_set_hofs(n0, ground)


## North mouth rocks: boulders flanking the lip, at the foot of the falls, along the pool front and the river banks
## (they also hide where the river's own trench walls end), stones along the stream and a spring at its source.
func _north_mouth_rocks() -> void:
	var lip: float = _notch_lip
	var zl: float = _notch_z(_notch_pd[4])
	var zf: float = _notch_z(_notch_pd[0])
	var wy: float = MOUTH_WATER_Y
	# Lip flanks and a slab jutting over the west side of the lip.
	_rock(Vector3(NOTCH_X - 2.6, lip + 0.1, zl - 0.45), 1.05, Vector3(1.0, 0.8, 1.15), CLIFF.darkened(0.05), 501.0, lip)
	_rock(Vector3(NOTCH_X + 2.7, lip + 0.15, zl - 0.7), 1.25, Vector3(1.1, 0.85, 1.0), CLIFF_B, 502.0, lip)
	_rock(Vector3(NOTCH_X + 2.2, lip + 0.05, zl - 2.2), 0.8, Vector3(1.0, 0.7, 1.2), CLIFF_L, 503.0, lip)
	_rock(Vector3(NOTCH_X - 2.0, lip + 0.02, zl - 2.9), 0.7, Vector3(1.2, 0.7, 1.0), CLIFF, 504.0, lip)
	# Foot of the falls: half-drowned boulders either side of the plunge, one in the pool.
	_rock(Vector3(NOTCH_X - 2.55, wy + 0.1, zf + 0.35), 0.9, Vector3(1.0, 0.8, 1.0), CLIFF_D.lerp(CLIFF, 0.4), 511.0, wy)
	_rock(Vector3(NOTCH_X + 2.65, wy + 0.15, zf + 0.25), 1.05, Vector3(1.05, 0.85, 0.95), CLIFF_D.lerp(CLIFF, 0.5), 512.0, wy)
	_rock(Vector3(NOTCH_X - 4.1, wy, zf + 1.0), 0.6, Vector3(1.0, 0.7, 1.0), CLIFF, 513.0, wy)
	_rock(Vector3(NOTCH_X + 4.3, wy, zf + 0.7), 0.7, Vector3(1.1, 0.75, 1.0), CLIFF.darkened(0.1), 514.0, wy)
	# Pool front: a broken rim of rocks along the map edge, open where the river leaves the pool.
	var x: float = NOTCH_X - 6.2
	var k: int = 0
	while x < NOTCH_X + 6.3:
		var hx: float = _h(Vector3(x, 7.0, 5.0))
		if absf(x - _river_n_x(-60.4)) > 2.5 and _notch_f(x) > 0.02:
			var r: float = 0.45 + 0.35 * hx
			var dw: float = 0.25 + 0.45 * _h(Vector3(x, 8.0, 5.0))
			_rock(Vector3(x, -0.12 + r * 0.12, -MAP_HALF - dw), r, Vector3(1.1, 0.72, 0.9),
				CLIFF.lerp(CLIFF_D, _h(Vector3(x, 9.0, 5.0)) * 0.6), 520.0 + k, wy)
			k += 1
		x += 0.8 + 0.4 * hx
	# River banks between the map edge and the pool (the river's trench walls end under these).
	for zb: float in [-60.35, -61.1, -61.85]:
		for side: float in [-1.0, 1.0]:
			var hb: float = _h(Vector3(zb, side, 6.0))
			var rb: float = 0.5 + 0.25 * hb
			_rock(Vector3(_river_n_x(zb) + side * (2.55 + rb * 0.25), -0.1, zb), rb, Vector3(1.0, 0.75, 1.1),
				CLIFF.lerp(CLIFF_D, hb * 0.5), 540.0 + zb * 3.0 + side, wy)
	# Stones along the stream banks, bigger ones now and then.
	var dc: float = _notch_pd[4] + 0.9
	var j: int = 0
	while dc < STREAM_END - 0.5:
		var c: Vector3 = _stream_pos(dc)
		for side: float in [-1.0, 1.0]:
			var hs: float = _h(Vector3(dc, side, 11.0))
			if hs < 0.2:
				continue
			var big: bool = hs > 0.82
			var rs: float = (0.45 + hs * 0.3) if big else (0.18 + hs * 0.22)
			var off: float = _stream_hw(dc) + rs * 0.55 + (_h(Vector3(dc, side, 12.0)) - 0.3) * 0.25
			_rock(Vector3(c.x + side * off, c.y - 0.1 + rs * 0.1, c.z + (_h(Vector3(dc, side, 13.0)) - 0.5) * 0.6), rs,
				Vector3(1.1, 0.7, 1.0), STONE.lerp(CLIFF, 0.5).darkened(hs * 0.15), 560.0 + j, c.y - 0.08,
				MOSS_HEAVY if big else MOSS)
			j += 1
		dc += 0.95 + _h(Vector3(dc, 3.0, 14.0)) * 0.5
	# The spring: mossy boulders where the stream comes out of the forest.
	var e: Vector3 = _stream_pos(STREAM_END)
	_rock(e + Vector3(-1.3, 0.2, -0.9), 0.95, Vector3(1.1, 0.85, 1.0), CLIFF, 590.0, e.y, MOSS_HEAVY)
	_rock(e + Vector3(0.3, 0.35, -1.6), 1.2, Vector3(1.0, 0.9, 1.1), CLIFF_B, 591.0, e.y, MOSS_HEAVY)
	_rock(e + Vector3(1.5, 0.15, -0.6), 0.8, Vector3(1.0, 0.8, 1.0), CLIFF.darkened(0.08), 592.0, e.y, MOSS_HEAVY)


## South gorge: two rock walls from the water up to the standing columns' surface (a shelf closes the gap to them),
## an end wall, the stone arch the river vanishes under, boulders in the rapids and along the rims.
func _gorge_rocks(cols: Array) -> void:
	var ds: PackedFloat32Array = _gorge_samples(0.0, GORGE_END)
	var ns: int = ds.size()
	var wall_cols: Array[Color] = [CLIFF_D.darkened(0.3), CLIFF_D.darkened(0.1), CLIFF_D.lerp(CLIFF, 0.5), CLIFF,
		CLIFF_L.lerp(CLIFF_B, 0.3)]
	var wall_tops: Array[Color] = [NO_TOP, NO_TOP, MOSS, MOSS, MOSS_HEAVY]
	var band_cols: Array[Color] = [CLIFF_D, CLIFF, CLIFF_L.lerp(CLIFF_B, 0.3), CLIFF, SOIL, GRASS_CAP, GRASS_CAP]
	var ends: Array = []   # last row of each side (for the end wall)
	var n0: int = _v.size()
	for side: float in [-1.0, 1.0]:
		var kept: Array = cols[_kept_e if side > 0.0 else _kept_w]
		var kept_x: float = (kept[0] as Vector3).x
		var rows: Array = []
		for j: int in ns:
			var dd: float = ds[j]
			var c: Vector3 = _gorge_pos(dd)
			var a: Vector3 = _gorge_across(dd) * side
			var hw: float = _gorge_hw(dd)
			var rim: float = _gorge_rim(side, dd)
			var hgt: float = maxf(rim - c.y, 0.2)
			var sc: float = smoothstep(0.5, 2.0, hgt)
			var offs: Array[float] = [lerpf(0.08, 0.12, sc), 0.0, lerpf(0.04, 0.30, sc), lerpf(0.07, 0.55, sc),
				lerpf(0.12, 1.15, sc), lerpf(0.20, 1.90, sc)]
			var fr: Array[float] = [lerpf(0.55, 0.30, sc), lerpf(0.85, 0.58, sc), lerpf(0.97, 0.86, sc), 1.0]
			var jit: float = (_h(Vector3(dd, side, 3.0)) - 0.5) * 0.3 * sc
			var pts: Array[Vector3] = []
			pts.append(c + a * (hw + offs[0]) + Vector3(0, -0.55, 0))
			pts.append(c + a * (hw + offs[1]) + Vector3(0, minf(0.12, hgt * 0.3), 0))
			for k: int in 4:
				pts.append(c + a * (hw + offs[k + 2] + (jit if k < 3 else 0.0)) + Vector3(0, hgt * fr[k], 0))
			# Shelf: from the lip out over the standing column's line, a hair under its surface.
			pts.append(Vector3(kept_x + side * 0.15, rim - 0.06, pts[5].z))
			rows.append(pts)
		ends.append(rows[ns - 1])
		# Wall bands (one colour each).
		for k: int in 5:
			var v := PackedVector3Array()
			var n := PackedVector3Array()
			var idx := PackedInt32Array()
			for j: int in ns:
				var hint: Vector3 = -_gorge_across(ds[j]) * side + Vector3.UP * 0.3
				v.append(rows[j][k])
				v.append(rows[j][k + 1])
				n.append(hint)
				n.append(hint)
			for j: int in ns - 1:
				idx.append_array([j * 2, j * 2 + 2, j * 2 + 1, j * 2 + 2, j * 2 + 3, j * 2 + 1])
			_arr(_mk(v, n, idx), Transform3D.IDENTITY, wall_cols[k], 0.14, 0.0, wall_tops[k], 300.0,
				Vector3(1.0, 0.6, 1.0))
		# Shelf: coloured like the standing column's band at that distance (rock face in the cliff, grass beyond).
		for j: int in ns - 1:
			var b: int = _band_at(kept, (ds[j] + ds[j + 1]) * 0.5)
			var v := PackedVector3Array([rows[j][5], rows[j][6], rows[j + 1][5], rows[j + 1][6]])
			var n := PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
			_arr(_mk(v, n, PackedInt32Array([0, 2, 1, 2, 3, 1])), Transform3D.IDENTITY, band_cols[b], 0.14, 0.0,
				MOSS if b >= 1 and b <= 3 else NO_TOP, 300.0, Vector3(1.0, 0.6, 1.0))
	# End wall under the arch (faces back up the gorge).
	var ev := PackedVector3Array()
	var en := PackedVector3Array()
	var eidx := PackedInt32Array()
	var back: Vector3 = -Vector3(_gorge_x(GORGE_END + 0.05) - _gorge_x(GORGE_END - 0.05), 0.0, 0.1).normalized()
	for k: int in 6:
		ev.append((ends[0] as Array)[k])
		ev.append((ends[1] as Array)[k])
		en.append(back)
		en.append(back)
	for k: int in 5:
		var a2: int = k * 2
		eidx.append_array([a2, a2 + 2, a2 + 1, a2 + 2, a2 + 3, a2 + 1])
	_arr(_mk(ev, en, eidx), Transform3D.IDENTITY, CLIFF_D.darkened(0.2), 0.14, 0.0, NO_TOP, 300.0, Vector3(1.0, 0.6, 1.0))
	_set_hofs(n0, 0.0, func(p: Vector3) -> float: return _gorge_wy(p.z - MAP_HALF))
	# The stone arch over the last stretch: a thick grassy slab, a leaning block on its lip, boulders on top.
	var da: float = (ARCH_D.x + ARCH_D.y) * 0.5
	var ca: Vector3 = _gorge_pos(da)
	var top: float = (_gorge_rim(-1.0, da) + _gorge_rim(1.0, da)) * 0.5 + 0.25
	var yaw: float = atan((_gorge_x(da + 0.05) - _gorge_x(da - 0.05)) / 0.1)
	var width: float = (_gorge_hw(da) + 2.6) * 2.0
	var n1: int = _v.size()
	var alen: float = ARCH_D.y - ARCH_D.x
	_prim(_box(Vector3(width, 1.75, alen), 2), Transform3D(Basis(Vector3.UP, yaw),
		Vector3(ca.x, top - 1.0, MAP_HALF + da)), CLIFF.darkened(0.05), 0.3, 0.0, NO_TOP, 610.0)
	_prim(_box(Vector3(width * 0.7, 1.3, 1.4), 1), Transform3D(Basis(Vector3.UP, yaw + 0.08) * Basis(Vector3.RIGHT, -0.22),
		Vector3(ca.x - 0.4, top - 1.25, MAP_HALF + ARCH_D.x + 0.35)), CLIFF_B.darkened(0.08), 0.22, 0.0, MOSS_HEAVY, 611.0)
	_set_hofs(n1, top - 1.9)
	# Its turf: a thin grass slab over the rock, overhanging a little.
	var n2: int = _v.size()
	_prim(_box(Vector3(width + 0.4, 0.3, alen + 0.3), 2), Transform3D(Basis(Vector3.UP, yaw),
		Vector3(ca.x, top - 0.08, MAP_HALF + da)), GRASS_CAP, 0.16, 0.0, NO_TOP, 615.0)
	_set_hofs(n2, top - 1.0)
	for sh: Vector3 in [Vector3(-2.6, ARCH_D.x + 0.9, 0.55), Vector3(2.9, ARCH_D.x + 3.2, 0.7), Vector3(0.9, ARCH_D.y - 2.4, 0.5)]:
		_shrub(Vector3(ca.x + sh.x, top + 0.05, MAP_HALF + sh.y), sh.z, 630.0 + sh.y)
	_rock(Vector3(ca.x - 3.3, top + 0.1, MAP_HALF + ARCH_D.x + 1.2), 0.85, Vector3(1.1, 0.8, 1.0), CLIFF, 612.0, top)
	_rock(Vector3(ca.x + 3.6, top + 0.15, MAP_HALF + da + 0.8), 1.0, Vector3(1.0, 0.8, 1.1), CLIFF_B, 613.0, top)
	_rock(Vector3(ca.x + 0.6, top + 0.05, MAP_HALF + ARCH_D.y - 0.9), 0.7, Vector3(1.2, 0.75, 1.0), CLIFF.darkened(0.1), 614.0, top)
	# Rapids rocks, half drowned: [d, offset across, radius].
	for rk: Vector3 in _gorge_rapid_rocks():
		var p: Vector3 = _gorge_pos(rk.x) + _gorge_across(rk.x) * rk.y
		_rock(p + Vector3(0, rk.z * 0.15, 0), rk.z, Vector3(1.0, 0.8, 1.15), STONE_W.lerp(STONE, 0.4), 620.0 + rk.x,
			p.y - 0.4, MOSS_HEAVY)
	# Shrubs on the shelves (they break the flat strips between the lip and the standing cliff).
	for side: float in [-1.0, 1.0]:
		var kx2: float = ((cols[_kept_e if side > 0.0 else _kept_w])[0] as Vector3).x
		var sd: float = 1.9
		var q2: int = 0
		while sd < ARCH_D.x - 0.6:
			var hs: float = _h(Vector3(sd, side, 19.0))
			var c: Vector3 = _gorge_pos(sd)
			var rim2: float = _gorge_rim(side, sd)
			var lip_x: float = c.x + side * (_gorge_hw(sd) + 1.9 * smoothstep(0.5, 2.0, rim2 - c.y))
			if hs > 0.35 and absf(kx2 - lip_x) > 1.2:
				var px: float = lerpf(lip_x + side * 0.6, kx2 - side * 0.3, _h(Vector3(sd, side, 20.0)))
				_shrub(Vector3(px, rim2, c.z), 0.45 + 0.3 * hs, 700.0 + q2 + side * 50.0)
			sd += 1.8 + hs * 1.6
			q2 += 1
	# Mouth corners and the rims (they hide the seam between the shelf and the standing cliff / plateau).
	for side: float in [-1.0, 1.0]:
		var kx: float = ((cols[_kept_e if side > 0.0 else _kept_w])[0] as Vector3).x
		var c0: Vector3 = _gorge_pos(0.55)
		var a0: Vector3 = _gorge_across(0.55) * side
		_rock(c0 + a0 * (_gorge_hw(0.55) + 0.75) + Vector3(0, 0.25, 0), 0.95 if side < 0.0 else 1.15,
			Vector3(1.0, 0.85, 1.05), CLIFF, 640.0 + side, 0.0)
		var c1: Vector3 = _gorge_pos(1.7)
		_rock(Vector3(lerpf(c1.x + side * 3.2, kx, 0.4), _gorge_rim(side, 1.7) + 0.1, c1.z), 0.75, Vector3(1.1, 0.8, 1.0),
			CLIFF_B, 642.0 + side, _gorge_rim(side, 1.7))
		var rd: float = 2.6
		var q: int = 0
		while rd < ARCH_D.x:
			var hq: float = _h(Vector3(rd, side, 17.0))
			var rr: float = 0.35 + 0.4 * hq
			var rim: float = _gorge_rim(side, rd)
			_rock(Vector3(kx + side * (0.05 + (hq - 0.5) * 0.5), rim + rr * 0.15, MAP_HALF + rd), rr,
				Vector3(1.1, 0.75, 1.0), CLIFF.lerp(CLIFF_B, hq), 650.0 + q + side * 40.0, rim)
			rd += 1.7 + hq * 1.2
			q += 1


## A low shrub (3 lumpy blobs) standing on `p`.
func _shrub(p: Vector3, r: float, seed: float) -> void:
	var n0: int = _v.size()
	for k: int in 3:
		var a: float = seed * 1.3 + k * 2.1
		var rr: float = r * (1.0 - k * 0.18)
		_prim(_sph(rr, 6, 3), _xf(p + Vector3(cos(a) * r * 0.55, rr * 0.55, sin(a) * r * 0.55), Vector3(0, a, 0),
			Vector3(1.0, 0.8, 1.0)), BUSH.lerp(BUSH_L, _h(Vector3(seed, k, 3.0))), rr * 0.2, 0.0, NO_TOP, seed + k)
	_set_hofs(n0, p.y)


## Rocks standing in the gorge's rapids: Vector3(d, offset across, radius).
func _gorge_rapid_rocks() -> Array[Vector3]:
	return [Vector3(1.2, 1.5, 0.4), Vector3(3.7, 1.15, 0.45), Vector3(4.4, -1.25, 0.35), Vector3(7.5, -0.7, 0.55),
		Vector3(8.7, 1.05, 0.4), Vector3(11.3, 0.35, 0.6), Vector3(14.8, -1.0, 0.5), Vector3(15.7, 1.2, 0.35)]


## The river-mouth meshes (river_mouths/*.res): water (plunge pool, plateau stream, gorge), falls (main curtain +
## the gorge's rapid steps), foam bands, mist cards. Indexed, one surface, one saved material each (the water's material is
## set at runtime by RiverMouthsArt: water_mat.tres when it exists, the fallback on the surface otherwise).
func _build_mouth_meshes() -> void:
	_mesh_save(_mouth_water(), "mouth_water", fallback_water_mat)
	_mesh_save(_mouth_falls(), "mouth_falls", falls_mat)
	_mesh_save(_mouth_foam(), "mouth_foam", foam_mat)
	_mesh_save(_mouth_mist(), "mouth_mist", mist_mat)


func _mesh_save(st: SurfaceTool, name: String, mat: Material) -> void:
	st.index()
	var mesh: ArrayMesh = st.commit()
	mesh.surface_set_material(0, mat)
	_save(mesh, RM_DIR + name + ".res")
	print("mesh %s: %d tris" % [name, mesh.surface_get_array_index_len(0) / 3])


## One quad (two triangles wound to face `want`, Godot front = clockwise) with per-corner uv / uv2 / colour.
func _st_quad(st: SurfaceTool, v: Array, nrm: Vector3, uv: Array, uv2: Array, col: Array, want: Vector3) -> void:
	for tri: Array in [[0, 1, 2], [0, 2, 3]]:
		var ids: Array = tri
		var a: Vector3 = v[ids[0]]
		var b: Vector3 = v[ids[1]]
		var c: Vector3 = v[ids[2]]
		if (b - a).cross(c - a).dot(want) > 0.0:
			ids = [ids[0], ids[2], ids[1]]
		for k: int in ids:
			st.set_normal(nrm)
			st.set_uv(uv[k])
			st.set_uv2(uv2[k])
			st.set_color(col[k])
			st.add_vertex(v[k])


## Water: the plunge pool (a grid hugging the cliff foot), the stream (flowing toward the lip) and the gorge (down
## its steps). UV.x metres along the flow, UV.y 0..1 across, COLOR.r bank foam, COLOR.g width / 5 m (water.gdshader).
func _mouth_water() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Plunge pool: x across NOTCH_X +- 6.6 (to the first columns with a foot apron), from 1.2 m inside the map (under
	# the ground / the river's water) to just under the cliff foot.
	var nx: int = 12
	var nz: int = 7
	var pw: float = 13.2
	var x0: float = NOTCH_X - pw * 0.5
	var grid: Array = []
	for ix: int in nx + 1:
		var x: float = x0 + pw * ix / nx
		var f: float = _notch_f(x)
		var foot: float = NOTCH_RECESS * f + lerpf(0.3, _notch_pd[0], f) + 0.35
		var colp: Array = []
		for iz: int in nz + 1:
			var dw: float = lerpf(-1.2, foot, float(iz) / nz)
			colp.append(Vector3(x, MOUTH_WATER_Y, -MAP_HALF - dw))
		grid.append(colp)
	for ix: int in nx:
		for iz: int in nz:
			var q: Array = [grid[ix][iz], grid[ix + 1][iz], grid[ix + 1][iz + 1], grid[ix][iz + 1]]
			var uv: Array = []
			var cl: Array = []
			for p: Vector3 in q:
				uv.append(Vector2(p.z + 100.0, (p.x - x0) / pw))
				cl.append(Color(1.0, pw / 5.0, 1.0, 1.0))
			_st_quad(st, q, Vector3.UP, uv, [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], cl, Vector3.UP)
	# Stream: from the spring down to the lip.
	var pts: Array = []
	var dc: float = STREAM_END
	while dc > _notch_pd[4] + 0.3:
		pts.append(dc)
		dc -= 0.5
	pts.append(_notch_pd[4] + 0.02)
	_water_strip(st, pts, func(x: float) -> Vector3: return _stream_pos(x), func(x: float) -> float: return _stream_hw(x), 300.0)
	# Gorge: from the map edge (under the river's end) down the steps to the end wall.
	var gp: Array = Array(_gorge_samples(0.0, GORGE_END + 0.1))
	_water_strip(st, gp, func(x: float) -> Vector3: return _gorge_pos(x), func(x: float) -> float: return _gorge_hw(x) + 0.05, 500.0)
	return st


## A water strip along `params` (in flow order): pos_fn(param) = centre on the surface, hw_fn(param) = half width.
func _water_strip(st: SurfaceTool, params: Array, pos_fn: Callable, hw_fn: Callable, s0: float) -> void:
	var rows: Array = []
	var s: float = s0
	for j: int in params.size():
		var c: Vector3 = pos_fn.call(params[j])
		var prev: Vector3 = pos_fn.call(params[maxi(j - 1, 0)])
		var nxt: Vector3 = pos_fn.call(params[mini(j + 1, params.size() - 1)])
		var fl: Vector3 = nxt - prev
		var dir := Vector3(fl.x, 0.0, fl.z).normalized()
		var across := Vector3(-dir.z, 0.0, dir.x)
		var slope: float = fl.y / maxf(Vector2(fl.x, fl.z).length(), 0.01)
		var nrm: Vector3 = (Vector3.UP - dir * slope).normalized()
		if j > 0:
			s += c.distance_to(pos_fn.call(params[j - 1]))
		var hw: float = hw_fn.call(params[j])
		rows.append([c - across * hw, c + across * hw, s, hw * 2.0 / 5.0, nrm])
	for j: int in rows.size() - 1:
		var a: Array = rows[j]
		var b: Array = rows[j + 1]
		var q: Array = [a[0], a[1], b[1], b[0]]
		var uv: Array = [Vector2(a[2], 0.0), Vector2(a[2], 1.0), Vector2(b[2], 1.0), Vector2(b[2], 0.0)]
		var cl: Array = [Color(1, a[3], 1, 1), Color(1, a[3], 1, 1), Color(1, b[3], 1, 1), Color(1, b[3], 1, 1)]
		var nrm: Vector3 = ((a[4] as Vector3) + (b[4] as Vector3)).normalized()
		_st_quad(st, q, nrm, uv, [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], cl, Vector3.UP)


## Falls: the main curtain over the notch lip (a ballistic arc kept clear of the face, bowed toward the map, wider
## at the bottom) and a short curtain on each rapid step of the gorge. UV metres (across, down), UV2.x the length.
func _mouth_falls() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var face := Vector3(0.0, 0.25, 1.0).normalized()
	var y_top: float = _notch_lip + 0.1
	var y_bot: float = MOUTH_WATER_Y - 0.12
	var nr: int = 18
	var nu: int = 8
	var centre: Array = []
	for r: int in nr + 1:
		var t: float = float(r) / nr
		var y: float = lerpf(y_top, y_bot, t)
		var dcol: float = minf(_notch_pd[4] + 0.05 - (0.1 + 1.5 * sqrt(t)), _notch_wall_d(y) - 0.4)
		centre.append([y, dcol, t])
	var lens := PackedFloat32Array([0.0])
	for r: int in nr:
		var a: Array = centre[r]
		var b: Array = centre[r + 1]
		lens.append(lens[r] + Vector2(float(a[1]) - float(b[1]), float(a[0]) - float(b[0])).length())
	var total: float = lens[nr]
	var grid: Array = []
	for r: int in nr + 1:
		var y: float = centre[r][0]
		var t: float = centre[r][2]
		var w: float = lerpf(2.05, 2.75, t)
		var row: Array = []
		for iu: int in nu + 1:
			var u: float = float(iu) / nu * 2.0 - 1.0
			var dcu: float = float(centre[r][1]) - 0.3 * (1.0 - u * u)
			var x: float = NOTCH_X + u * w + 0.12 * sin(t * 3.0 + u * 2.0)
			row.append([Vector3(x, y, _notch_z(dcu)), Vector2(u * w, lens[r]), 1.0 - smoothstep(0.72, 1.0, absf(u))])
		grid.append(row)
	_grid_quads(st, grid, face, total)
	# Rapid steps of the south gorge: a short curtain down each chute, 3 cm over the water (white lip, streaks).
	for sd: float in GORGE_STEPS:
		var g3: Array = []
		var n3: int = 5
		var d_a: float = sd - CHUTE_HALF - 0.1
		var d_b: float = sd + CHUTE_HALF + 0.15
		var len3 := PackedFloat32Array([0.0])
		for r3: int in n3 + 1:
			var dd: float = lerpf(d_a, d_b, float(r3) / n3)
			if r3 > 0:
				len3.append(len3[r3 - 1] + _gorge_pos(dd).distance_to(_gorge_pos(lerpf(d_a, d_b, float(r3 - 1) / n3))))
			var c3: Vector3 = _gorge_pos(dd) + Vector3(0.0, 0.03, 0.0)
			var a3: Vector3 = _gorge_across(dd)
			var hw3: float = _gorge_hw(dd) + 0.02
			var row3: Array = []
			for iu: int in 5:
				var u3: float = float(iu) / 4.0 * 2.0 - 1.0
				row3.append([c3 + a3 * u3 * hw3, Vector2(u3 * hw3 + sd * 3.1, 0.0), 1.0 - smoothstep(0.82, 1.0, absf(u3))])
			g3.append(row3)
		for r3: int in g3.size():
			for e3: Array in g3[r3]:
				e3[1] = Vector2((e3[1] as Vector2).x, len3[r3])
		_grid_quads(st, g3, Vector3(0.0, 0.75, 0.66).normalized(), len3[len3.size() - 1])
	return st


## Quads of a [row][column] grid of [position, uv, edge] (UV2.x = total length, COLOR.a = edge).
func _grid_quads(st: SurfaceTool, grid: Array, nrm: Vector3, total: float) -> void:
	for r: int in grid.size() - 1:
		for iu: int in (grid[r] as Array).size() - 1:
			var cs: Array = [grid[r][iu], grid[r][iu + 1], grid[r + 1][iu + 1], grid[r + 1][iu]]
			var v: Array = []
			var uv: Array = []
			var uv2: Array = []
			var cl: Array = []
			for e: Array in cs:
				v.append(e[0])
				uv.append(e[1])
				uv2.append(Vector2(total, 0.0))
				cl.append(Color(1.0, 1.0, 1.0, float(e[2])))
			_st_quad(st, v, nrm, uv, uv2, cl, nrm)


## Foam bands (mouth_foam.gdshader): the plunge boil, the stream lip and riffles, the gorge steps, run-out and wakes.
func _mouth_foam() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var plunge := func(x: float) -> Vector3: return _plunge_pos(x)
	var across_x := func(x: float) -> Vector3: return Vector3(NOTCH_X - 3.3 + x, MOUTH_WATER_Y, _notch_z(_notch_pd[0]) + 0.9)
	var stream := func(x: float) -> Vector3: return _stream_pos(x)
	var gorge := func(x: float) -> Vector3: return _gorge_pos(x)
	# Plunge pool: a boiling patch under the falls drifting out into the river, and a churn across the impact.
	_foam_band(st, plunge, 0.0, 6.6, 0.0, func(x: float) -> float: return lerpf(3.1, 2.3, x / 6.6),
		func(x: float) -> float: return lerpf(1.0, 0.12, smoothstep(0.3, 6.6, x)), 1.2, 1.0)
	_foam_band(st, across_x, 0.0, 6.6, 0.0, func(_x: float) -> float: return 1.15,
		func(x: float) -> float: return 1.0 - smoothstep(1.6, 3.4, absf(x - 3.3)), 0.35, 1.0)

	# Stream: white water where it tips over the lip, and two riffles.
	_foam_band(st, stream, _notch_pd[4] + 1.9, _notch_pd[4] + 0.02, 0.0, func(x: float) -> float: return _stream_hw(x),
		func(x: float) -> float: return lerpf(1.0, 0.25, smoothstep(_notch_pd[4], _notch_pd[4] + 1.9, x)), 1.6, 0.0)
	for rd: float in [12.4, 16.8]:
		_foam_band(st, stream, rd, rd - 1.8, 0.0, func(x: float) -> float: return _stream_hw(x),
			func(x: float) -> float: return 0.55 * sin(clampf((rd - x) / 1.8, 0.0, 1.0) * PI), 1.4, 0.0)
	# Gorge: white water breaking at the foot of each chute and thinning out below it (the first band also covers
	# where the river's own water ends, 2 m past the edge), light streaks between the steps.
	for k: int in GORGE_STEPS.size():
		var sd: float = GORGE_STEPS[k]
		var d0: float = 1.2 if k == 0 else sd - 0.5
		var r0: float = 1.3 if k == 0 else sd - 0.45
		_foam_band(st, gorge, d0, sd + 2.2, 0.0, func(x: float) -> float: return _gorge_hw(x) - 0.05,
			func(x: float) -> float: return 0.78 * smoothstep(r0, sd + 0.25, x) * (1.0 - smoothstep(sd + 0.45, sd + 2.1, x)),
			1.5, 0.0)
		if k < GORGE_STEPS.size() - 1:
			var nx: float = GORGE_STEPS[k + 1]
			_foam_band(st, gorge, sd + 1.6, nx - 0.5, 0.0, func(x: float) -> float: return _gorge_hw(x) - 0.3,
				func(x: float) -> float: return 0.2 * sin(clampf((x - sd - 1.6) / (nx - sd - 2.1), 0.0, 1.0) * PI), 1.3, 0.0)
	_foam_band(st, gorge, GORGE_STEPS[3] + 1.9, GORGE_END, 0.0, func(x: float) -> float: return _gorge_hw(x) - 0.2,
		func(x: float) -> float: return 0.24 * (1.0 - smoothstep(GORGE_END - 3.0, GORGE_END, x)), 1.2, 0.0)
	# Wakes behind the rapids rocks.
	for rk: Vector3 in _gorge_rapid_rocks():
		_foam_band(st, gorge, rk.x - 0.35, rk.x + 1.9, rk.y, func(_x: float) -> float: return rk.z + 0.3,
			func(x: float) -> float: return 0.9 * (1.0 - smoothstep(rk.x, rk.x + 1.9, x)), 1.3, 0.0)
	return st


## A foam band along pos_fn from p0 to p1 (either direction; UV.x grows from p0), `off` metres across the path,
## half width hw_fn(p), envelope env_fn(p), 2.5 cm over the water.
func _foam_band(st: SurfaceTool, pos_fn: Callable, p0: float, p1: float, off: float, hw_fn: Callable,
		env_fn: Callable, speed: float, boil: float) -> void:
	var n: int = maxi(2, int(ceil(absf(p1 - p0) / 0.3)))
	var rows: Array = []
	var s: float = 0.0
	var last := Vector3.ZERO
	for j: int in n + 1:
		var p: float = lerpf(p0, p1, float(j) / n)
		var e: float = (p1 - p0) / n * 0.5
		var c: Vector3 = pos_fn.call(p)
		var fl: Vector3 = (pos_fn.call(p + e) as Vector3) - (pos_fn.call(p - e) as Vector3)
		var dir := Vector3(fl.x, 0.0, fl.z).normalized()
		var across := Vector3(dir.z, 0.0, -dir.x)   # to the right of the flow (east in the gorge, like _gorge_across)
		var slope: float = fl.y / maxf(Vector2(fl.x, fl.z).length(), 0.01)
		var nrm: Vector3 = (Vector3.UP - dir * slope).normalized()
		c += across * off + nrm * 0.025
		if j > 0:
			s += c.distance_to(last)
		last = c
		var hw: float = hw_fn.call(p)
		rows.append([c - across * hw, c + across * hw, s, hw, clampf(float(env_fn.call(p)), 0.0, 1.0), nrm])
	for j: int in n:
		var a: Array = rows[j]
		var b: Array = rows[j + 1]
		var q: Array = [a[0], a[1], b[1], b[0]]
		var uv: Array = [Vector2(a[2], -a[3]), Vector2(a[2], a[3]), Vector2(b[2], b[3]), Vector2(b[2], -b[3])]
		var sp := Vector2(speed, boil)
		var cl: Array = [Color(0.0, 1, 1, a[4]), Color(1.0, 1, 1, a[4]), Color(1.0, 1, 1, b[4]), Color(0.0, 1, 1, b[4])]
		var nrm: Vector3 = ((a[5] as Vector3) + (b[5] as Vector3)).normalized()
		_st_quad(st, q, nrm, uv, [sp, sp, sp, sp], cl, Vector3.UP)


## Mist cards: spray at the foot of the falls drifting out over the river, a little at each rapid step.
func _mouth_mist() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var zp: float = _notch_z(_notch_pd[0]) + 0.3
	var cards: Array = [   # [centre, size, phase]
		[Vector3(NOTCH_X - 1.6, 0.9, zp + 0.8), 4.2, 0.0], [Vector3(NOTCH_X + 1.4, 1.2, zp + 0.5), 4.6, 0.33],
		[Vector3(NOTCH_X + 0.1, 0.7, zp + 2.0), 5.2, 0.66], [Vector3(NOTCH_X - 0.6, 2.7, zp + 0.3), 3.4, 0.15],
		[Vector3(NOTCH_X + 0.9, 3.6, zp + 0.1), 2.8, 0.5], [Vector3(NOTCH_X - 1.0, 0.6, zp + 3.6), 3.6, 0.85],
		[Vector3(NOTCH_X + 1.2, 0.5, zp + 5.0), 3.0, 0.42]]
	for k: int in GORGE_STEPS.size():
		var sd: float = GORGE_STEPS[k] + 0.6
		cards.append([_gorge_pos(sd) + Vector3(0.0, 0.45, 0.0), 2.3 + k * 0.1, 0.2 + k * 0.23])
	for cd: Array in cards:
		var c: Vector3 = cd[0]
		var size: float = cd[1]
		var sp := Vector2(size, float(cd[2]))
		var v: Array = []
		var uv: Array = []
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			v.append(c + Vector3(corner.x, -corner.y, 0.0) * size * 0.5)
			uv.append((corner + Vector2.ONE) * 0.5)
		_st_quad(st, v, Vector3.BACK, uv, [sp, sp, sp, sp], [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE],
			Vector3.BACK)
	return st


## True where a closed-ring border tree / crest rock must go when the mouths open: every instance on the notch
## columns (they are replanted for the valley) and everything between the gorge's standing columns.
func _mouth_zone(p: Vector3) -> bool:
	if p.z < -MAP_HALF and absf(p.x - NOTCH_X) < NOTCH_HALF + 0.5:
		return true
	if p.z > MAP_HALF and p.z < MAP_HALF + GORGE_HOLE + 1.0:
		var xw: float = ((_cols_open[_kept_w])[0] as Vector3).x
		var xe: float = ((_cols_open[_kept_e])[0] as Vector3).x
		if p.x > xw + 0.3 and p.x < xe - 0.3:
			return true
	return false


## Height of the edge surface (cliff profile, then plateau) at distance d from the map square for column i.
func _edge_y(i: int, d: float) -> float:
	var col: Array = _cols[i]
	var pd: PackedFloat32Array = col[2]
	var py: PackedFloat32Array = col[3]
	var yp: float = col[4]
	if d <= pd[pd.size() - 1]:
		for k: int in pd.size() - 1:
			if d <= pd[k + 1]:
				return lerpf(py[k], py[k + 1], clampf((d - pd[k]) / maxf(pd[k + 1] - pd[k], 0.01), 0.0, 1.0))
	var rows: Array[float] = [7.0, 14.0, 26.0, 50.0]
	var rise: Array[float] = [-0.03, 0.4, 1.4, 3.5]
	for k2: int in rows.size() - 1:
		if d <= rows[k2 + 1]:
			return yp + lerpf(rise[k2], rise[k2 + 1], clampf((d - rows[k2]) / (rows[k2 + 1] - rows[k2]), 0.0, 1.0))
	return yp + 3.5


func _pick_border_tree(h: float) -> int:
	var acc: float = 0.0
	for i: int in BORDER_WEIGHTS.size():
		acc += BORDER_WEIGHTS[i]
		if h <= acc:
			return i
	return 0


## map_dressing.tscn: the cliffs, the plateau and the border forest (MultiMeshes per side and variant, stored in
## the scene), plus the MapDressingArt script that scatters the in-map decor at runtime.
func _build_map_dressing() -> void:
	var root := Node3D.new()
	root.name = "MapDressing"
	root.set_script(load(DIR + "map_dressing_art.gd"))
	var cliffs: MeshInstance3D = _mi(root, load(MESH_DIR + "map_cliffs.res") as Mesh, "Cliffs")
	cliffs.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	cliffs.material_override = load(DIR + "cliff_mat.tres") as Material
	var plateau: MeshInstance3D = _mi(root, load(MESH_DIR + "map_plateau.res") as Mesh, "Plateau")
	plateau.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plateau.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	# Border trees: per side (by the column normal), variant and shadow (only the front rows cast shadows, down
	# the cliff onto the map edge). Stored as data (MultiMesh buffers are not saved from a headless run);
	# MapDressingArt builds the MultiMeshes in _ready.
	var lists: Dictionary = {}   # "side:variant:shadow" -> Array[Transform3D]
	var flags: Dictionary = {}   # same keys -> Array[int]: 0 both rings, 1 closed ring only, 2 open ring only (12.V5)
	var m: int = _cols.size()
	_mouth_closed_idx = {}
	_mouth_open_idx = {}
	for i: int in m:
		for e: Array in _border_trees(_cols[i], i, func(dj: float) -> float: return _edge_y(i, dj)):
			_add_border(lists, flags, e[0], e[1], 1 if _mouth_zone((e[1] as Transform3D).origin) else 0)
	_mouth_trees(lists, flags)
	var sets: Array = []
	var total: int = 0
	for key2: String in lists:
		var parts: PackedStringArray = key2.split(":")
		# Every side uses the light *_far stand-ins (A2.8: they have smooth painted shading now, good enough for the
		# south bank under the camera; the full map trees are 3-variant meshes, too heavy for ~250 border trees).
		var mesh_name: String = BORDER_TREES[int(parts[1])]
		var node_name: String = "%s_%s%s" % [["North", "East", "South", "West"][int(parts[0])], mesh_name.to_pascal_case(),
			"_Shadow" if parts[2] == "1" else ""]
		sets.append([mesh_name, node_name, _pack_xforms(lists[key2]), parts[2] == "1"])
		_mouth_index(node_name, flags[key2])
		total += (lists[key2] as Array).size()
	# Big rocks on the cliff crest, one set per rock_spire variant (A2.8 single-variant meshes: no hidden triangles).
	var rocks: Array = [[], [], []]
	var rock_flags: Array = [[], [], []]
	for i: int in range(0, m, 5):
		var hh2: float = _h(Vector3(i, 31.0, 5.0))
		var col2: Array = _cols[i]
		if hh2 < 0.5 or (col2[1] as Vector3).z > 0.5:
			continue
		var pd2: PackedFloat32Array = col2[2]
		var dd: float = pd2[5] + 0.4 + hh2 * 1.5
		var p2: Vector3 = (col2[0] as Vector3) + (col2[1] as Vector3) * dd
		p2.y = _edge_y(i, dd) - 0.3
		var s2: float = 1.3 + hh2 * 1.4
		(rocks[i % 3] as Array).append(Transform3D(Basis(Vector3.UP, hh2 * 17.0).scaled(Vector3(s2, s2, s2)), p2))
		(rock_flags[i % 3] as Array).append(1 if _mouth_zone(p2) else 0)
	var n_rocks: int = 0
	for v: int in 3:
		var mesh_v: String = "rock_spire_v%d" % v
		if not ResourceLoader.exists(MESH_DIR + mesh_v + ".res"):
			mesh_v = "rock_spire"
		sets.append([mesh_v, "CrestRocks%d" % v, _pack_xforms(rocks[v]), true])
		_mouth_index("CrestRocks%d" % v, rock_flags[v])
		n_rocks += (rocks[v] as Array).size()
	root.set(&"border_sets", sets)
	print("border trees: %d in %d sets, crest rocks %d (closed ring only %d, open ring only %d)" % [total,
		sets.size() - 3, n_rocks, _index_count(_mouth_closed_idx), _index_count(_mouth_open_idx)])
	var forest := Node3D.new()
	forest.name = "BorderForest"
	root.add_child(forest)
	var decor := Node3D.new()
	decor.name = "Decor"
	root.add_child(decor)
	# 12.V5: the river mouths (RiverMouthsArt picks the open / closed ring at runtime).
	var mouths := Node3D.new()
	mouths.name = "RiverMouths"
	mouths.set_script(load(RM_DIR + "river_mouths_art.gd"))
	mouths.set(&"closed_only", _mouth_closed_idx)
	mouths.set(&"open_only", _mouth_open_idx)
	root.add_child(mouths)
	for part: Array in [["Water", "mouth_water"], ["Falls", "mouth_falls"], ["Foam", "mouth_foam"], ["Mist", "mouth_mist"]]:
		var mi: MeshInstance3D = _mi(mouths, load(RM_DIR + String(part[1]) + ".res") as Mesh, String(part[0]))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		if part[0] == "Mist":
			mi.extra_cull_margin = 4.0   # the cards are billboards that rise and swell in the shader
	_pack("map_dressing", root)


## Border trees of column `col` (index i): [set key, transform] each; `ground(dj)` = surface height at distance dj.
## Same hashes for the closed and the open ring, so a replanted column keeps its trees where the ground allows.
func _border_trees(col: Array, i: int, ground: Callable) -> Array:
	var out: Array = []
	var base: Vector3 = col[0]
	var nrm: Vector3 = col[1]
	var pd: PackedFloat32Array = col[2]
	var tangent := Vector3(-nrm.z, 0, nrm.x)
	var south: bool = nrm.z > 0.5
	var d0: float = pd[5] + 0.3 + (4.0 if south else 0.0)
	var row: int = 0
	var d: float = d0
	while d < 24.0:
		var hh: float = _h(Vector3(i, row, 21.0))
		var keep: float = 0.95 if d < 13.0 else (0.72 if d < 18.0 else 0.45)
		if i % 2 == row % 2 and hh < keep:
			var dj: float = d + (_h(Vector3(i, row, 22.0)) - 0.5) * 1.4
			var p: Vector3 = base + nrm * dj + tangent * (_h(Vector3(i, row, 23.0)) - 0.5) * 1.4
			p.y = float(ground.call(dj)) - 0.1
			var s: float = 1.05 + _h(Vector3(i, row, 24.0)) * 0.6 - (0.2 if south else 0.0)
			var variant: int = _pick_border_tree(_h(Vector3(i, row, 25.0)))
			if south and variant >= 3:   # no bright birch / gold right under the camera
				variant -= 3
			var shadow: int = 1 if row < 2 else 0
			var key: String = "%d:%d:%d" % [_side_of(nrm), variant, shadow]
			out.append([key, Transform3D(Basis(Vector3.UP, hh * TAU).scaled(Vector3(s, s, s)), p)])
		d += 2.9
		row += 1
	return out


func _add_border(lists: Dictionary, flags: Dictionary, key: String, xf: Transform3D, flag: int) -> void:
	if not lists.has(key):
		lists[key] = []
		flags[key] = []
	(lists[key] as Array).append(xf)
	(flags[key] as Array).append(flag)


## Records which instances of a border set belong to one ring only (RiverMouthsArt hides them on the other ring).
func _mouth_index(node_name: String, set_flags: Array) -> void:
	var closed_i := PackedInt32Array()
	var open_i := PackedInt32Array()
	for k: int in set_flags.size():
		if int(set_flags[k]) == 1:
			closed_i.append(k)
		elif int(set_flags[k]) == 2:
			open_i.append(k)
	if not closed_i.is_empty():
		_mouth_closed_idx[node_name] = closed_i
	if not open_i.is_empty():
		_mouth_open_idx[node_name] = open_i


func _index_count(idx: Dictionary) -> int:
	var n: int = 0
	for k: Variant in idx:
		n += (idx[k] as PackedInt32Array).size()
	return n


## Open-ring trees (12.V5): the notch columns replanted on the valley (clear of the stream and the lip), a few trees
## hanging over the stream's source, and trees on the gorge's stone arch (flag 2: open ring only).
func _mouth_trees(lists: Dictionary, flags: Dictionary) -> void:
	var lip_clear: float = _notch_pd[7] + 1.2
	for i: int in 75:
		var col: Array = _cols_open[i]
		if absf((_cols_closed[i][0] as Vector3).x - NOTCH_X) >= NOTCH_HALF + 0.5 + 0.8:
			continue
		for e: Array in _border_trees(col, i, func(dj: float) -> float: return _col_y(col, dj)):
			var p: Vector3 = (e[1] as Transform3D).origin
			var dc: float = -MAP_HALF - NOTCH_RECESS - p.z
			if not _mouth_zone(p):
				continue   # outside the replanted strip: the closed-ring tree there stays
			if dc < STREAM_END + 1.3 and absf(p.x - _stream_x(dc)) < _stream_hw(dc) + 1.4:
				continue   # the stream
			if dc < lip_clear and absf(p.x - NOTCH_X) < NOTCH_CORE + 1.0:
				continue   # the lip of the falls
			_add_border(lists, flags, e[0], e[1], 2)
	# Over the stream's source (it comes out from under the trees), then on the stone arch over the gorge.
	var extra: Array = []   # [key, position, scale, yaw]
	for t: Vector3 in [Vector3(-1.7, 0.8, 0.0), Vector3(1.3, 1.3, 1.0), Vector3(0.1, 2.7, 1.0), Vector3(-2.3, 3.4, 0.0)]:
		var dc2: float = STREAM_END + t.y
		var x2: float = _stream_x(STREAM_END) + t.x
		var z2: float = _notch_z(dc2)
		extra.append(["0:%d:1" % int(t.z), Vector3(x2, _north_y(x2, z2) - 0.1, z2), 1.35 + t.y * 0.05, t.x * 2.1])
	var da: float = (ARCH_D.x + ARCH_D.y) * 0.5
	var top: float = (_gorge_rim(-1.0, da) + _gorge_rim(1.0, da)) * 0.5 + 0.25
	var gx: float = _gorge_x(da)
	for t2: Vector3 in [Vector3(-1.6, ARCH_D.x + 2.3, 0.0), Vector3(1.9, ARCH_D.y - 1.6, 1.0), Vector3(-0.2, ARCH_D.y - 0.4, 2.0)]:
		extra.append(["2:%d:1" % int(t2.z), Vector3(gx + t2.x, top - 0.15, MAP_HALF + t2.y), 1.25, t2.x * 1.7])
	for ex: Array in extra:
		var s: float = ex[2]
		var xf := Transform3D(Basis(Vector3.UP, float(ex[3])).scaled(Vector3(s, s, s)), ex[1] as Vector3)
		_add_border(lists, flags, ex[0], xf, 2)


## Transforms as 12 floats each (basis x, y, z columns, origin).
func _pack_xforms(list: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for xf: Transform3D in list:
		var b: Basis = xf.basis
		out.append_array([b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, xf.origin.x, xf.origin.y,
			xf.origin.z])
	return out


func _side_of(nrm: Vector3) -> int:
	if absf(nrm.z) >= absf(nrm.x):
		return 0 if nrm.z < 0.0 else 2
	return 1 if nrm.x > 0.0 else 3
