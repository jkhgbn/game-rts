class_name TavernModel
extends Node3D
## Neutral tavern (task 9.V6, docs/design/champions.md sections 2 and 9). Built in code at _ready, meshes baked once
## and shared by both taverns (BuildingMerge), materials per instance (selection rim, glow boost).
## Read from the RTS camera: a two-storey inn on a mossy stone plinth: a mossy stone ground floor, a jettied
## half-timbered upper floor in cream plaster, a steep golden thatch roof (gables facing the camera, thick rounded
## rolls), a tall stone chimney on the -X side (the dominant vertical, smoking) and, on
## the +X+Z corner (the asymmetric secondary), a recessed porch with the door, an iron bracket holding the hanging
## sign (a foaming tankard over a gold coin) and a lantern glowing (1.0, 0.8, 0.4). Barrels, a keg, a bench, crates
## and a woodpile around it. No real light: the warm light is emissive windows / door / lantern + a fake additive
## light pool and halo.
## Footprint 6 x 6 m (nothing below 2.5 m sticks out more than 0.3 m; eaves / sign up to 0.6 m above that), ridge
## ~6.4 m, chimney pots ~7.9 m. Root origin = footprint centre on the ground. No collision (tavern.gd owns it).
##
## Door / rotation: the FRONT of the scene is local +Z (the door looks along +Z, like tavern.gd expects). Inside, the
## building ("Body") is turned -45 degrees: the door sits on the chamfered corner of a square house. So when the parent
## turns the root to face the map centre from a diagonal spot, the house lands square on the build grid:
##   rotation.y = atan2(-spot.x, -spot.z)  ->  (-15, -15): +45 deg, (15, 15): -135 deg   (yaw_for_spot(spot))
## gives world yaw 0 / 180 for the house, door toward (0, 0). The door anchor (spawn / rest point) is local
## (0, 0, DOOR_DISTANCE) = spot x 0.8 on both spots (get_door_point()). The 6 x 6 collider must then be turned -45 deg
## too (square in world, see docs/handoff/for-systems-coder.md).
## Hooks (all safe before _ready): set_open(bool) (door swings, windows brighten; default open),
## set_selected(bool) (amber rim + glow boost), play_door_pulse() (0.6 s door flash, e.g. when a champion is hired),
## set_team_color(c) (ignored: the tavern is neutral; present so generic code can call it).

const PAINTED: Shader = preload("res://art/buildings/tavern/tavern_painted.gdshader")
const GLOW: Shader = preload("res://art/shaders/rune_glow.gdshader")
const NOISE: Texture2D = preload("res://art/shaders/paint_noise.tres")
const BMG := preload("res://art/buildings/fire_hall_merge.gd")

const GLOW_COLOR := Color(1.0, 0.8, 0.4)
const RIM_IDLE := Color(0.55, 0.65, 0.85)
const RIM_SELECTED := Color(1.0, 0.75, 0.35)
const DOOR_DISTANCE := 4.2426        # door anchor, metres in front of the centre (root +Z)
const DOOR_LOCAL := Vector3(3.0, 0.0, 3.0)                     # same point in Body space
const DOOR_DIR_LOCAL := Vector3(0.70710678, 0.0, 0.70710678)   # door direction in Body space
const BODY_YAW := -PI * 0.25
const HEIGHT := 6.4
const ROOF_SLOPE_DEG := 38.0
const ARM_Y := 3.42   # the sign / lantern bracket; everything hanging from it stays above 2.5 m
const Y_PLINTH := 0.35
const Y_STONE := 2.2
const Y_JETTY := 2.45
const Y_PLATE := 3.5
const Y_PLATE_TOP := 3.71
const CHIMNEY_Z := -0.9
const KEY := "res://art/buildings/tavern/tavern_model"
const SITE_GROUND := "res://art/environment/neutral/site_ground.gd"

# Palette: neutral (no kingdom colour). Straw roof = the minimap's amber tavern mark.
const C_STONE := Color(0.43, 0.42, 0.38)
const C_DARK := Color(0.25, 0.24, 0.22)
const C_TIMBER := Color(0.31, 0.21, 0.13)
const C_WOOD := Color(0.52, 0.37, 0.22)
const C_PLASTER := Color(0.78, 0.70, 0.56)
## G-E 12 (docs/art/ge_fixes_c.md): a greyer straw (value -15 %, saturation -25 %, was 0.63 / 0.47 / 0.25) so the
## crown altar stays the centre's focus.
const C_THATCH := Color(0.54, 0.44, 0.30)
const C_IRON := Color(0.21, 0.21, 0.23)
const C_GOLD := Color(0.92, 0.70, 0.27)
const C_MOSS := Color(0.31, 0.41, 0.17)

static var _mesh_cache: Dictionary = {}
static var _tex_cache: Dictionary = {}

var _body: Node3D
var _painted: Array[ShaderMaterial] = []
var _glows: Array[ShaderMaterial] = []
var _m: Dictionary = {}   # name -> ShaderMaterial
## B8 material merge (in-game grade 2026-09-30): ONE palette material (BuildingPalette, tavern_painted's palette mode)
## draws every painted part and every warm glow; the per-instance materials above stay the source of truth (selection
## rim, lamps) and are re-read into it (BuildingPalette.refresh) after every change.
var _pal: ShaderMaterial
var _g_window: ShaderMaterial
var _g_door: ShaderMaterial
var _g_lantern: ShaderMaterial
var _sign: Node3D
var _lantern: Node3D
var _door: Node3D
var _door_glow: MeshInstance3D
var _pools: Array[MeshInstance3D] = []
var _smoke: GPUParticles3D
var _sign_basis: Basis
## G-B neutral (Ultra only): the lantern's and the doorway's warm lights (null at Low).
var _lamp_light: NeutralFlickerLight
var _door_light: NeutralFlickerLight
var _sparks: GPUParticles3D   # High+ only
var _lantern_basis: Basis

var _t: float = 0.0
var _ready_done: bool = false
var _open: bool = true
var _open_k: float = 1.0
var _selected: bool = false
var _sel_k: float = 0.0
var _pulse: float = 0.0


func _ready() -> void:
	_ready_done = true
	_t = randf() * 10.0
	_body = Node3D.new()
	_body.name = "Body"
	_body.rotation.y = BODY_YAW
	add_child(_body)
	_make_materials()
	_build_structure()
	_build_door()
	_build_sign()
	_build_lantern()
	_build_ground()
	_build_smoke()
	_pal = BuildingPalette.create(PAINTED, _painted[0])
	BuildingPalette.fold_tree(_pal, _body)
	NeutralBuildingLook.set_detail(_pal)
	NeutralBuildingLook.set_detail_all(_painted)
	_build_lights()
	_open_k = 1.0 if _open else 0.0
	_sel_k = 1.0 if _selected else 0.0
	_apply_open()
	_apply_rim_and_glow()


func _process(delta: float) -> void:
	_t += delta
	# Sign and lantern sway on the bracket (different rhythms).
	_sign.basis = _sign_basis * Basis(Vector3.RIGHT, sin(_t * 1.3) * 0.07 + sin(_t * 0.47) * 0.03)
	_lantern.basis = _lantern_basis * Basis(Vector3.RIGHT, sin(_t * 1.7 + 1.1) * 0.09) \
		* Basis(Vector3.FORWARD, sin(_t * 1.1) * 0.05)
	var open_target: float = 1.0 if _open else 0.0
	if _open_k != open_target:
		_open_k = move_toward(_open_k, open_target, delta / 0.8)
		_apply_open()
	var sel_target: float = 1.0 if _selected else 0.0
	var dirty: bool = false
	if _sel_k != sel_target:
		_sel_k = move_toward(_sel_k, sel_target, delta / (0.15 if _selected else 0.25))
		dirty = true
	if _pulse > 0.0:
		_pulse = maxf(_pulse - delta / 0.6, 0.0)
		dirty = true
	if dirty:
		_apply_rim_and_glow()


# --- Hooks ---

## The root yaw that turns the door (local +Z) toward the map centre from `spot`; on the diagonal spots the house
## then stands square on the grid. (-15, -15) -> +PI/4, (15, 15) -> -3 PI/4.
static func yaw_for_spot(spot: Vector3) -> float:
	return atan2(-spot.x, -spot.z)


## World position of the door anchor (champion spawn / rest point): local (0, 0, DOOR_DISTANCE).
func get_door_point() -> Vector3:
	var p := Vector3(0.0, 0.0, DOOR_DISTANCE)
	return to_global(p) if is_inside_tree() else transform * p


## World direction the door faces (the root's +Z).
func get_door_direction() -> Vector3:
	return ((global_transform.basis if is_inside_tree() else basis) * Vector3.BACK).normalized()


## Closed (before 2:00): door shut, windows dim, no light pool. Open: door swings out, warm light. Default open.
func set_open(open: bool) -> void:
	_open = open


func is_open() -> bool:
	return _open


func set_selected(on: bool) -> void:
	_selected = on


## A short warm flash from the doorway (hire, revive...). Safe to retrigger.
func play_door_pulse() -> void:
	_pulse = 1.0


## The tavern is neutral: team colours are ignored (kept so generic building code can call it).
func set_team_color(_c: Color) -> void:
	pass


# --- Materials ---

func _paint(nm: String, color: Color, pattern: int = 0, moss_top: float = 0.0, moss_foot: float = 0.0,
		spec: float = 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = PAINTED
	m.set_shader_parameter(&"base_color", color)
	m.set_shader_parameter(&"noise_tex", NOISE)
	m.set_shader_parameter(&"pattern", pattern)
	m.set_shader_parameter(&"moss_color", C_MOSS)
	m.set_shader_parameter(&"moss_top", moss_top)
	m.set_shader_parameter(&"moss_foot", moss_foot)
	m.set_shader_parameter(&"spec_strength", spec)
	_painted.append(m)
	_m[nm] = m
	return m


func _glow(energy: float, pulse_speed: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = GLOW
	m.set_shader_parameter(&"glow_color", GLOW_COLOR)
	m.set_shader_parameter(&"energy", energy)
	m.set_shader_parameter(&"pulse_speed", pulse_speed)
	m.set_shader_parameter(&"rune_bands", 0)
	m.set_shader_parameter(&"phase", randf() * TAU)
	_glows.append(m)
	return m


func _make_materials() -> void:
	_paint("stone", C_STONE, 1, 1.0, 0.7)
	var dark: ShaderMaterial = _paint("dark", C_DARK, 1, 1.0, 0.45)
	dark.set_shader_parameter(&"course_height", 0.35)
	dark.set_shader_parameter(&"block_length", 1.1)
	_paint("timber", C_TIMBER)
	_paint("wood", C_WOOD)
	_paint("plaster", C_PLASTER)
	var thatch: ShaderMaterial = _paint("thatch", C_THATCH, 2, 0.7)
	thatch.set_shader_parameter(&"moss_cut", 0.7)
	thatch.set_shader_parameter(&"moss_color", C_MOSS.darkened(0.15))
	_paint("iron", C_IRON, 0, 0.0, 0.0, 0.4)
	_paint("bloom_red", Color(0.78, 0.16, 0.14))
	_paint("bloom_gold", Color(0.95, 0.74, 0.22))
	_paint("leaf", Color(0.26, 0.42, 0.16))
	_paint("gold", C_GOLD, 0, 0.0, 0.0, 0.5)
	_g_window = _glow(1.9, 1.3)
	_g_door = _glow(1.5, 2.2)
	_g_lantern = _glow(3.6, 3.0)


# --- Mesh helpers (cached, shared by both taverns) ---

static func _box(size: Vector3) -> Mesh:
	var key: String = "b%s" % size
	if not _mesh_cache.has(key):
		var m := BoxMesh.new()
		m.size = size
		_mesh_cache[key] = m
	return _mesh_cache[key]


static func _cyl(top_r: float, bot_r: float, h: float, segs: int) -> Mesh:
	var key: String = "c%.3f_%.3f_%.3f_%d" % [top_r, bot_r, h, segs]
	if not _mesh_cache.has(key):
		var m := CylinderMesh.new()
		m.top_radius = top_r
		m.bottom_radius = bot_r
		m.height = h
		m.radial_segments = segs
		m.rings = 1
		m.cap_top = top_r > 0.0
		m.cap_bottom = bot_r > 0.0
		_mesh_cache[key] = m
	return _mesh_cache[key]


static func _sphere(r: float, segs: int = 10, rings: int = 5) -> Mesh:
	var key: String = "s%.3f_%d_%d" % [r, segs, rings]
	if not _mesh_cache.has(key):
		var m := SphereMesh.new()
		m.radius = r
		m.height = r * 2.0
		m.radial_segments = segs
		m.rings = rings
		_mesh_cache[key] = m
	return _mesh_cache[key]


static func _prism(size: Vector3) -> Mesh:
	var key: String = "p%s" % size
	if not _mesh_cache.has(key):
		var m := PrismMesh.new()
		m.size = size
		_mesh_cache[key] = m
	return _mesh_cache[key]


static func _torus(inner: float, outer: float) -> Mesh:
	var key: String = "t%.3f_%.3f" % [inner, outer]
	if not _mesh_cache.has(key):
		var m := TorusMesh.new()
		m.inner_radius = inner
		m.outer_radius = outer
		m.rings = 16
		m.ring_segments = 6
		_mesh_cache[key] = m
	return _mesh_cache[key]


## A convex polygon (points (x, z), any winding) extruded from y0 to y1: flat-shaded sides + top cap.
static func _poly_prism(poly: PackedVector2Array, y0: float, y1: float) -> Mesh:
	var key: String = "poly%s_%.3f_%.3f" % [poly, y0, y1]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var c := Vector2.ZERO
	for p: Vector2 in poly:
		c += p
	c /= float(poly.size())
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cc := Vector3(c.x, 0.0, c.y)
	for i: int in poly.size():
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		var a0 := Vector3(a.x, y0, a.y)
		var b0 := Vector3(b.x, y0, b.y)
		var a1 := Vector3(a.x, y1, a.y)
		var b1 := Vector3(b.x, y1, b.y)
		var mid: Vector3 = (a0 + b0) * 0.5
		var n := Vector3(b.y - a.y, 0.0, a.x - b.x).normalized()
		if n.dot(Vector3(mid.x, 0.0, mid.z) - cc) < 0.0:
			n = -n
		_tri(st, a0, b0, b1, n)
		_tri(st, a0, b1, a1, n)
		_tri(st, Vector3(c.x, y1, c.y), a1, b1, Vector3.UP)
	# Indexed like the primitive meshes: BuildingMerge's SurfaceTool.append_from drops non-indexed vertices when
	# they are merged with indexed ones.
	st.index()
	var m: ArrayMesh = st.commit()
	_mesh_cache[key] = m
	return m


## Adds a triangle facing `n` (Godot front faces wind clockwise seen from the front: (b - a) x (c - a) points
## away from the viewer).
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	if (b - a).cross(c - a).dot(n) > 0.0:
		var tmp: Vector3 = b
		b = c
		c = tmp
	for v: Vector3 in [a, b, c]:
		st.set_normal(n)
		st.set_uv(Vector2(v.x + v.z, v.y))
		st.add_vertex(v)


# --- Item helpers (BuildingMerge items: [mesh, xf, material]) ---

func _it(mesh: Mesh, pos: Vector3, mat: String, rot_deg: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> Array:
	return BMG.item(mesh, pos, _mat(mat), rot_deg, scale)


func _itx(mesh: Mesh, xf: Transform3D, mat: String) -> Array:
	return BMG.item_xf(mesh, xf, _mat(mat))


func _mat(nm: String) -> Material:
	match nm:
		"window":
			return _g_window
		"door_glow":
			return _g_door
		"lantern":
			return _g_lantern
	return _m[nm]


## A beam (box of section `w` x `w`) from `a` to `b`.
func _beam(a: Vector3, b: Vector3, w: float, mat: String, extra: float = 0.0) -> Array:
	var e: Vector3 = b - a
	var bs := Basis(Quaternion(Vector3.UP, e.normalized()))
	return _itx(_box(Vector3(w, e.length() + extra, w)), Transform3D(bs, (a + b) * 0.5), mat)


## A round rod (radius `r`) from `a` to `b`.
func _rod(a: Vector3, b: Vector3, r: float, mat: String, extra: float = 0.0) -> Array:
	var e: Vector3 = b - a
	var bs := Basis(Quaternion(Vector3.UP, e.normalized()))
	return _itx(_cyl(r, r, snappedf(e.length() + extra, 0.01), 10), Transform3D(bs, (a + b) * 0.5), mat)


func _merge(nm: String, key: String, items: Array, parent: Node3D, painted: bool = true) -> MeshInstance3D:
	var mi: MeshInstance3D = BMG.instance(nm, "%s/%s" % [KEY, key], items)
	parent.add_child(mi)
	if painted:
		mi.set_instance_shader_parameter(&"ao_bottom", 0.0)
		mi.set_instance_shader_parameter(&"ao_height", HEIGHT)
	return mi


# --- Structure ---
# Body space: door corner +X+Z, ridge along Z (the gables face +-Z: from the RTS camera the front gable is the
# face of the house and the two slopes catch light / shade). Levels: plinth 0-0.35, stone 0.35-2.2, jetty 2.2-2.45,
# plaster 2.45-3.5, top plate to 3.71, roof 38 degrees, ridge roll top ~6.4, chimney pots ~7.9.

func _build_structure() -> void:
	var it: Array = []
	_add_plinth_and_walls(it)
	_add_upper_floor(it)
	_add_roof(it)
	_add_chimney(it)
	_add_windows(it)
	_add_porch(it)
	_add_props(it)
	_merge("Structure", "structure", it, _body)


func _add_plinth_and_walls(it: Array) -> void:
	# Plinth (dark stone, 0.35 m, a small chamfer at the door corner) and a stone step out of the porch.
	var plinth := PackedVector2Array([Vector2(-2.9, -2.9), Vector2(2.9, -2.9), Vector2(2.9, 2.45),
		Vector2(2.45, 2.9), Vector2(-2.9, 2.9)])
	it.append(_itx(_poly_prism(plinth, 0.0, Y_PLINTH), Transform3D.IDENTITY, "dark"))
	it.append(_it(_box(Vector3(1.1, 0.18, 0.42)), Vector3(2.74, 0.09, 2.74), "dark", Vector3(0, 45, 0)))
	# Ground floor: mossy stone, the +X+Z corner cut at 45 degrees for the door.
	var ground := PackedVector2Array([Vector2(-2.45, -2.45), Vector2(2.45, -2.45), Vector2(2.45, 0.55),
		Vector2(0.55, 2.45), Vector2(-2.45, 2.45)])
	it.append(_itx(_poly_prism(ground, Y_PLINTH, Y_STONE), Transform3D.IDENTITY, "stone"))
	# Dark quoins on the three square corners (alternating long / short blocks) frame the mass from afar.
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1)]:
		for i: int in 4:
			var y: float = Y_PLINTH + 0.22 + 0.44 * i
			var along_x: bool = i % 2 == 0
			var sx: float = 0.72 if along_x else 0.46
			var sz: float = 0.46 if along_x else 0.72
			it.append(_it(_box(Vector3(sx, 0.4, sz)),
				Vector3(c.x * (2.45 - sx * 0.5 + 0.06), y, c.y * (2.45 - sz * 0.5 + 0.06)), "dark"))
	# Jetty: timber floor slab over the stone (upper floor overhangs 0.17 m), joist ends under it.
	it.append(_it(_box(Vector3(5.3, 0.25, 5.3)), Vector3(0, (Y_STONE + Y_JETTY) * 0.5, 0), "timber"))
	for k: int in 8:
		var s: float = -2.1 + 0.6 * k
		# Only where a stone wall is under the jetty (not over the porch, not behind the chimney).
		if s < 0.35:
			it.append(_it(_box(Vector3(0.24, 0.2, 0.3)), Vector3(s, Y_STONE - 0.1, 2.55), "timber"))
			it.append(_it(_box(Vector3(0.3, 0.2, 0.24)), Vector3(2.55, Y_STONE - 0.1, s), "timber"))
		it.append(_it(_box(Vector3(0.24, 0.2, 0.3)), Vector3(s, Y_STONE - 0.1, -2.55), "timber"))
		if s > -0.2 or s < -1.6:
			it.append(_it(_box(Vector3(0.3, 0.2, 0.24)), Vector3(-2.55, Y_STONE - 0.1, s), "timber"))


func _add_upper_floor(it: Array) -> void:
	# Plaster box, top plate, corner posts, studs and "/ \" braces on every face (half-timbered).
	var h: float = Y_PLATE - Y_JETTY
	var yc: float = (Y_JETTY + Y_PLATE) * 0.5
	it.append(_it(_box(Vector3(5.1, h, 5.1)), Vector3(0, yc, 0), "plaster"))
	it.append(_it(_box(Vector3(5.36, 0.22, 5.36)), Vector3(0, Y_PLATE_TOP - 0.11, 0), "timber"))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(_it(_box(Vector3(0.32, h + 0.08, 0.32)), Vector3(c.x * 2.56, yc, c.y * 2.56), "timber"))
	for f: int in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)   # local +Z = outward, local X along the face
		var off: float = 2.58
		for x: float in [-1.25, 1.25]:
			it.append(_itx(_box(Vector3(0.24, h, 0.1)), Transform3D(b, b * Vector3(x, yc, off)), "timber"))
		for sx: float in [-1.0, 1.0]:
			it.append(_beam(b * Vector3(sx * 2.4, Y_JETTY + 0.08, off), b * Vector3(sx * 1.37, Y_PLATE - 0.06, off),
				0.2, "timber"))
	# Gables (plaster triangles) on +-Z: collar beam, a small window, a king post up to the apex.
	var gh: float = 2.67 * tan(deg_to_rad(ROOF_SLOPE_DEG))
	for sz: float in [-1.0, 1.0]:
		it.append(_it(_prism(Vector3(5.34, gh, 0.26)), Vector3(0, Y_PLATE_TOP + gh * 0.5, sz * 2.49), "plaster"))
		it.append(_it(_box(Vector3(4.0, 0.16, 0.1)), Vector3(0, Y_PLATE_TOP + 0.42, sz * 2.63), "timber"))
		it.append(_it(_box(Vector3(0.14, 0.95, 0.1)), Vector3(0, Y_PLATE_TOP + gh - 0.5, sz * 2.63), "timber"))
		for sx: float in [-1.0, 1.0]:
			it.append(_beam(Vector3(sx * 1.9, Y_PLATE_TOP + 0.5, sz * 2.63), Vector3(sx * 0.42, Y_PLATE_TOP + 1.05,
				sz * 2.63), 0.12, "timber"))


func _add_roof(it: Array) -> void:
	# Two thick thatch slabs (ridge along Z), rounded eave / verge / ridge rolls (straw layers are in the shader).
	var ang: float = deg_to_rad(ROOF_SLOPE_DEG)
	var slope: float = tan(ang)
	var eave_x: float = 3.4
	var eave_y: float = Y_PLATE_TOP - (eave_x - 2.67) * slope
	var thick: float = 0.34
	var run: float = eave_x / cos(ang)
	var length: float = run + 0.2
	var depth: float = 6.1
	for sx: float in [1.0, -1.0]:
		var down := Vector3(cos(ang) * sx, -sin(ang), 0.0)     # along the slope toward the eave
		var nrm := Vector3(sin(ang) * sx, cos(ang), 0.0)       # out of the roof
		var eave := Vector3(eave_x * sx, eave_y, 0.0)
		var b := Basis(Vector3.BACK, -ang * sx)
		var centre: Vector3 = eave - down * (length * 0.5) + nrm * (thick * 0.5)
		# Lumpy, gently sagging thatch (LumpySlab; in-game grade 2026-09-30: the flat slab was the biggest plain plane).
		it.append(_itx(LumpySlab.mesh(Vector3(length, thick, depth), Vector2i(6, 12), 0.08, 0.12, int(sx + 2.0)),
			Transform3D(b, centre), "thatch"))
		# Eave roll along the lower edge.
		it.append(_it(_cyl(0.22, 0.22, depth + 0.1, 10), eave + nrm * (thick * 0.5) + down * 0.02, "thatch",
			Vector3(90, 0, 0)))
		# Verge rolls along the gable edges (the thick outline of the gable).
		for sz: float in [-1.0, 1.0]:
			var p0: Vector3 = eave + nrm * (thick * 0.5) + Vector3(0, 0, sz * depth * 0.5)
			it.append(_rod(p0, p0 - down * run, 0.2, "thatch", 0.1))

	# Ridge roll with rounded ends.
	var ridge_y: float = eave_y + eave_x * slope + thick / cos(ang)
	it.append(_it(_cyl(0.26, 0.26, depth + 0.2, 10), Vector3(0, ridge_y - 0.1, 0), "thatch", Vector3(90, 0, 0)))
	for sz: float in [-1.0, 1.0]:
		it.append(_it(_sphere(0.3, 10, 5), Vector3(0, ridge_y - 0.1, sz * (depth * 0.5 + 0.1)), "thatch"))


func _add_chimney(it: Array) -> void:
	# Tall stone stack on the -X side (the dominant vertical): wide base, a mossy weathering ledge, a narrower stack
	# through the eave, a crown band and two pots (the smoke comes out of them).
	var x: float = -2.73
	var z: float = CHIMNEY_Z
	it.append(_it(_box(Vector3(0.6, 3.3, 1.3)), Vector3(x, 1.65, z), "stone"))
	it.append(_it(_box(Vector3(0.74, 0.16, 1.44)), Vector3(x, 3.36, z), "dark"))
	it.append(_it(_box(Vector3(0.58, 3.9, 0.88)), Vector3(x + 0.02, 5.37, z), "stone"))
	it.append(_it(_box(Vector3(0.76, 0.24, 1.06)), Vector3(x + 0.02, 7.38, z), "dark"))
	for pz: float in [-0.23, 0.21]:
		it.append(_it(_cyl(0.13, 0.17, 0.42, 7), Vector3(x + 0.02, 7.71, z + pz), "dark"))
	# Fireplace glow slit at the foot (a hint of the hearth inside).
	it.append(_it(_box(Vector3(0.06, 0.28, 0.5)), Vector3(x - 0.3, 0.62, z), "door_glow"))


func _window(it: Array, b: Basis, centre: Vector3, w: float, h: float, shutters: bool) -> void:
	# `centre` on the wall face, `b` local +Z = outward.
	var o: Vector3 = centre
	it.append(_itx(_box(Vector3(w, h, 0.06)), Transform3D(b, o + b * Vector3(0, 0, 0.01)), "window"))
	it.append(_itx(_box(Vector3(0.07, h, 0.07)), Transform3D(b, o + b * Vector3(0, 0, 0.05)), "timber"))
	it.append(_itx(_box(Vector3(w, 0.07, 0.07)), Transform3D(b, o + b * Vector3(0, 0, 0.05)), "timber"))
	it.append(_itx(_box(Vector3(w + 0.3, 0.14, 0.2)), Transform3D(b, o + b * Vector3(0, -h * 0.5 - 0.07, 0.07)), "timber"))
	it.append(_itx(_box(Vector3(w + 0.26, 0.16, 0.14)), Transform3D(b, o + b * Vector3(0, h * 0.5 + 0.08, 0.05)), "timber"))
	for sx: float in [-1.0, 1.0]:
		it.append(_itx(_box(Vector3(0.12, h, 0.12)), Transform3D(b, o + b * Vector3(sx * (w * 0.5 + 0.06), 0, 0.05)),
			"timber"))
		if shutters:
			it.append(_itx(_box(Vector3(w * 0.5, h + 0.06, 0.06)),
				Transform3D(b, o + b * Vector3(sx * (w * 0.75 + 0.14), 0, 0.05)), "wood"))


func _add_windows(it: Array) -> void:
	var bz := Basis.IDENTITY                          # +Z face
	var bx := Basis(Vector3.UP, PI * 0.5)             # +X face
	var bnz := Basis(Vector3.UP, PI)                  # -Z face
	var bnx := Basis(Vector3.UP, -PI * 0.5)           # -X face
	# Ground floor (stone).
	_window(it, bz, Vector3(-1.25, 1.35, 2.45), 0.72, 0.7, false)
	_window(it, bx, Vector3(2.45, 1.35, -1.45), 0.72, 0.7, false)
	_window(it, bnz, Vector3(0.7, 1.35, -2.45), 0.72, 0.7, false)
	_window(it, bnx, Vector3(-2.45, 1.35, 1.45), 0.62, 0.62, false)
	# Upper floor (plaster) with open shutters, and the two gable windows.
	var yu: float = (Y_JETTY + Y_PLATE) * 0.5 + 0.02
	_window(it, bz, Vector3(0, yu, 2.55), 0.62, 0.5, true)
	_window(it, bnz, Vector3(0, yu, -2.55), 0.62, 0.5, true)
	_window(it, bx, Vector3(2.55, yu, -1.0), 0.56, 0.46, false)
	for s: float in [-1.0, 1.0]:
		_window(it, bz if s > 0.0 else bnz, Vector3(0, Y_PLATE_TOP + 0.78, s * 2.62), 0.46, 0.4, false)
	# G-B neutral: flower boxes under the shuttered upper windows and two ground-floor ones (lived-in, colour at RTS
	# zoom; the ground-floor boxes stick out 0.26 m, inside the 0.3 m footprint rule).
	_flower_box(it, bz, Vector3(0, yu - 0.25 - 0.14, 2.55), 0.82, 1)
	_flower_box(it, bnz, Vector3(0, yu - 0.25 - 0.14, -2.55), 0.82, 2)
	_flower_box(it, bz, Vector3(-1.25, 1.35 - 0.35 - 0.14, 2.45), 0.9, 3)
	_flower_box(it, bx, Vector3(2.45, 1.35 - 0.35 - 0.14, -1.45), 0.9, 4)


## A window box (planks + earth) packed with red / gold blooms over leaves, under a sill. `b` local +Z = outward.
func _flower_box(it: Array, b: Basis, sill: Vector3, w: float, seed_i: int) -> void:
	var o: Vector3 = sill + b * Vector3(0, -0.12, 0.17)
	it.append(_itx(_box(Vector3(w, 0.2, 0.22)), Transform3D(b, o), "wood"))
	it.append(_itx(_box(Vector3(w + 0.04, 0.04, 0.24)), Transform3D(b, o + b * Vector3(0, -0.1, 0)), "timber"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * seed_i
	var n: int = int(w / 0.11)
	for i: int in n:
		var x: float = -w * 0.5 + 0.06 + (w - 0.12) * (float(i) + rng.randf_range(-0.3, 0.3)) / maxf(n - 1, 1)
		var z: float = rng.randf_range(-0.06, 0.06)
		it.append(_itx(_sphere(0.075, 6, 3), Transform3D(b.scaled(Vector3(1.0, 0.8, 1.0)),
			o + b * Vector3(x, 0.1 + rng.randf_range(0.0, 0.03), z)), "leaf"))
		if rng.randf() < 0.75:
			it.append(_itx(_sphere(0.05, 6, 3), Transform3D(b, o + b * Vector3(x + rng.randf_range(-0.03, 0.03),
				0.17 + rng.randf_range(0.0, 0.05), z + 0.03)), "bloom_red" if rng.randf() < 0.55 else "bloom_gold"))


func _add_porch(it: Array) -> void:
	# Door frame on the chamfer (the leaf and the doorway glow are separate nodes), corner post, braces, bracket.
	var bd := Basis(Vector3.UP, PI * 0.25)
	var dc := Vector3(1.5, Y_PLINTH, 1.5)
	for sx: float in [-1.0, 1.0]:
		it.append(_itx(_box(Vector3(0.2, 1.86, 0.24)), Transform3D(bd, dc + bd * Vector3(sx * 0.68, 0.93, 0.06)),
			"timber"))
	it.append(_itx(_box(Vector3(1.7, 0.28, 0.3)), Transform3D(bd, dc + bd * Vector3(0, 1.84, 0.08)), "timber"))
	it.append(_itx(_box(Vector3(1.3, 0.1, 0.3)), Transform3D(bd, dc + bd * Vector3(0, 0.02, 0.12)), "dark"))
	# Corner post under the jetty, on a stone pad, with two braces.
	var pc := Vector3(2.56, 0.0, 2.56)
	var ph: float = Y_STONE - Y_PLINTH
	it.append(_it(_box(Vector3(0.5, 0.12, 0.5)), pc + Vector3(0, Y_PLINTH + 0.06, 0), "dark", Vector3(0, 45, 0)))
	it.append(_it(_box(Vector3(0.34, ph, 0.34)), pc + Vector3(0, Y_PLINTH + ph * 0.5, 0), "timber", Vector3(0, 45, 0)))
	it.append(_beam(pc + Vector3(0, Y_STONE - 0.55, 0), Vector3(1.75, Y_STONE - 0.02, 2.56), 0.16, "timber"))
	it.append(_beam(pc + Vector3(0, Y_STONE - 0.55, 0), Vector3(2.56, Y_STONE - 0.02, 1.75), 0.16, "timber"))
	# Iron bracket for the sign and the lantern: arm along the diagonal, a strut under it, a curl, a finial.
	var d: Vector3 = DOOR_DIR_LOCAL
	it.append(_beam(d * 3.55 + Vector3(0, ARM_Y, 0), d * 5.08 + Vector3(0, ARM_Y, 0), 0.1, "iron"))
	it.append(_beam(d * 3.62 + Vector3(0, ARM_Y - 0.6, 0), d * 4.5 + Vector3(0, ARM_Y, 0), 0.08, "iron"))
	it.append(_itx(_torus(0.1, 0.17), Transform3D(Basis(Vector3.UP, -PI * 0.25) * Basis(Vector3.RIGHT, PI * 0.5),
		d * 4.05 + Vector3(0, ARM_Y + 0.17, 0)), "iron"))
	it.append(_it(_sphere(0.08, 8, 4), d * 5.1 + Vector3(0, ARM_Y, 0), "iron"))


func _barrel(it: Array, xf: Transform3D) -> void:
	it.append(_itx(_cyl(0.34, 0.28, 0.42, 10), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0.21, 0)), "wood"))
	it.append(_itx(_cyl(0.28, 0.34, 0.42, 10), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0.63, 0)), "wood"))
	it.append(_itx(_cyl(0.285, 0.285, 0.04, 10), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0.84, 0)), "timber"))
	for y: float in [0.13, 0.71]:
		it.append(_itx(_cyl(0.315, 0.315, 0.07, 10), xf * Transform3D(Basis.IDENTITY, Vector3(0, y, 0)), "iron"))
	it.append(_itx(_cyl(0.35, 0.35, 0.07, 10), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0.42, 0)), "iron"))


func _add_props(it: Array) -> void:
	# Barrels by the door (on the plinth), a keg on its side, a bench under the front window, crates, a woodpile.
	_barrel(it, Transform3D(Basis(Vector3.UP, 0.4), Vector3(2.58, Y_PLINTH, 1.0)))
	_barrel(it, Transform3D(Basis(Vector3.UP, 1.3), Vector3(2.6, Y_PLINTH, 0.3)))
	_barrel(it, Transform3D(Basis(Vector3.RIGHT, PI * 0.5).scaled(Vector3.ONE * 0.72), Vector3(2.62, 0.6, -0.78)))
	it.append(_it(_box(Vector3(1.55, 0.1, 0.44)), Vector3(-1.25, 0.8, 2.7), "wood"))
	it.append(_it(_box(Vector3(1.62, 0.07, 0.1)), Vector3(-1.25, 0.72, 2.9), "timber"))
	for x: float in [-1.85, -0.65]:
		it.append(_it(_box(Vector3(0.12, 0.42, 0.38)), Vector3(x, 0.56, 2.7), "timber"))
	it.append(_it(_box(Vector3(0.55, 0.52, 0.55)), Vector3(-2.5, 0.61, 2.5), "wood", Vector3(0, 12, 0)))
	it.append(_it(_box(Vector3(0.59, 0.08, 0.59)), Vector3(-2.5, 0.87, 2.5), "timber", Vector3(0, 12, 0)))
	it.append(_it(_box(Vector3(0.36, 0.34, 0.36)), Vector3(-2.52, 1.06, 2.46), "wood", Vector3(0, -20, 0)))
	var logs: Array[Vector2] = [Vector2(-2.86, 0.48), Vector2(-2.6, 0.48), Vector2(-2.73, 0.71)]
	for i: int in logs.size():
		var p: Vector2 = logs[i]
		it.append(_it(_cyl(0.13, 0.13, 0.95 - 0.1 * i, 7), Vector3(p.x, p.y, 0.64), "wood", Vector3(90, 0, 0)))
	# Back corner (-X-Z): two stacked crates and a sack-like keg, so the far side seen from the camera is dressed too.
	it.append(_it(_box(Vector3(0.6, 0.55, 0.6)), Vector3(-2.3, Y_PLINTH + 0.275, -2.62), "wood", Vector3(0, -8, 0)))
	it.append(_it(_box(Vector3(0.64, 0.07, 0.64)), Vector3(-2.3, Y_PLINTH + 0.56, -2.62), "timber", Vector3(0, -8, 0)))
	it.append(_it(_box(Vector3(0.42, 0.4, 0.42)), Vector3(-2.25, Y_PLINTH + 0.8, -2.6), "wood", Vector3(0, 25, 0)))
	_barrel(it, Transform3D(Basis(Vector3.UP, 2.1).scaled(Vector3.ONE * 0.85), Vector3(-1.5, Y_PLINTH, -2.66)))


# --- Moving parts ---

func _build_door() -> void:
	# Doorway glow (the warm inside) and the door leaf hinged on the left jamb, swinging out when open.
	var bd := Basis(Vector3.UP, PI * 0.25)
	var dc := Vector3(1.5, Y_PLINTH, 1.5)
	var glow_it: Array = [_itx(_box(Vector3(1.16, 1.76, 0.04)), Transform3D(bd, dc + bd * Vector3(0, 0.88, 0.01)),
		"door_glow")]
	_door_glow = _merge("DoorGlow", "door_glow", glow_it, _body, false)
	_door_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_door = Node3D.new()
	_door.name = "DoorPivot"
	_door.transform = Transform3D(bd, dc + bd * Vector3(-0.56, 0.0, 0.05))
	_body.add_child(_door)
	var it: Array = []
	it.append(_it(_box(Vector3(1.08, 1.74, 0.09)), Vector3(0.56, 0.88, 0.0), "wood"))
	for y: float in [0.3, 1.4]:
		it.append(_it(_box(Vector3(0.96, 0.1, 0.12)), Vector3(0.53, y, 0.0), "iron"))
	for k: int in 3:
		it.append(_it(_box(Vector3(0.05, 1.72, 0.11)), Vector3(0.29 + 0.27 * k, 0.88, 0.0), "timber"))
	it.append(_itx(_torus(0.05, 0.09), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.94, 0.88, 0.07)), "iron"))
	_merge("DoorLeaf", "door_leaf", it, _door)


func _build_sign() -> void:
	# Hanging sign board (both faces): dark board in a wood frame, emblem = a foaming tankard over a gold coin.
	var d: Vector3 = DOOR_DIR_LOCAL
	_sign = Node3D.new()
	_sign.name = "SignPivot"
	_sign_basis = Basis(Vector3.UP, -PI * 0.25)   # local +X along the arm, local +Z = board face
	_sign.transform = Transform3D(_sign_basis, d * 4.18 + Vector3(0, ARM_Y - 0.04, 0))
	_body.add_child(_sign)
	var it: Array = []
	for sx: float in [-1.0, 1.0]:
		it.append(_it(_box(Vector3(0.04, 0.22, 0.04)), Vector3(sx * 0.38, -0.11, 0), "iron"))
	it.append(_it(_box(Vector3(1.04, 0.62, 0.1)), Vector3(0, -0.54, 0), "wood"))
	it.append(_it(_box(Vector3(0.88, 0.47, 0.13)), Vector3(0, -0.54, 0), "timber"))
	it.append(_it(_box(Vector3(1.1, 0.09, 0.14)), Vector3(0, -0.22, 0), "iron"))
	for sz: float in [-1.0, 1.0]:
		var z: float = sz * 0.075
		it.append(_it(_cyl(0.19, 0.19, 0.03, 16), Vector3(0.14, -0.5, z), "gold", Vector3(90, 0, 0)))
		it.append(_it(_box(Vector3(0.23, 0.27, 0.05)), Vector3(-0.07, -0.6, z * 1.3), "wood"))
		it.append(_it(_box(Vector3(0.27, 0.045, 0.06)), Vector3(-0.07, -0.5, z * 1.4), "iron"))
		it.append(_it(_box(Vector3(0.27, 0.045, 0.06)), Vector3(-0.07, -0.7, z * 1.4), "iron"))
		it.append(_itx(_torus(0.05, 0.095), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.21, -0.6, z * 1.3)),
			"wood"))
		for f: Vector3 in [Vector3(-0.15, -0.45, 0.08), Vector3(-0.05, -0.43, 0.09), Vector3(0.03, -0.46, 0.07)]:
			it.append(_it(_sphere(f.z, 8, 4), Vector3(f.x, f.y, z * 1.4), "plaster", Vector3.ZERO, Vector3(1, 0.85, 0.5)))
	_merge("SignBoard", "sign", it, _sign)


func _build_lantern() -> void:
	# The lantern hangs at the arm tip: iron cap, glowing glass (the landmark light), corner bars, base.
	var d: Vector3 = DOOR_DIR_LOCAL
	_lantern = Node3D.new()
	_lantern.name = "LanternPivot"
	_lantern_basis = Basis(Vector3.UP, -PI * 0.25)
	_lantern.transform = Transform3D(_lantern_basis, d * 4.98 + Vector3(0, ARM_Y - 0.04, 0))
	_body.add_child(_lantern)
	var it: Array = []
	it.append(_it(_box(Vector3(0.04, 0.1, 0.04)), Vector3(0, -0.05, 0), "iron"))
	it.append(_it(_torus(0.03, 0.07), Vector3(0, -0.12, 0), "iron", Vector3(90, 0, 0)))
	it.append(_it(_cyl(0.02, 0.24, 0.16, 4), Vector3(0, -0.22, 0), "iron", Vector3(0, 45, 0)))
	it.append(_it(_box(Vector3(0.27, 0.36, 0.27)), Vector3(0, -0.5, 0), "lantern"))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(_it(_box(Vector3(0.05, 0.4, 0.05)), Vector3(c.x * 0.145, -0.5, c.y * 0.145), "iron"))
	it.append(_it(_box(Vector3(0.34, 0.06, 0.34)), Vector3(0, -0.31, 0), "iron"))
	it.append(_it(_box(Vector3(0.32, 0.07, 0.32)), Vector3(0, -0.71, 0), "iron"))
	it.append(_it(_cyl(0.11, 0.0, 0.12, 4), Vector3(0, -0.8, 0), "iron", Vector3(0, 45, 0)))
	var mi: MeshInstance3D = _merge("Lantern", "lantern", it, _lantern)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Soft halo sprite around the glass so the lantern reads from 60 m (fake light, no Light3D).
	var halo := MeshInstance3D.new()
	halo.name = "Halo"
	var q := QuadMesh.new()
	q.size = Vector2(1.5, 1.5)
	halo.mesh = q
	halo.material_override = _soft_mat("halo", Color(1.0, 0.78, 0.4, 0.55), true, true)
	halo.position = Vector3(0, -0.5, 0)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lantern.add_child(halo)


## G-B neutral (Ultra only, NeutralBuildingLook): a real warm light in the swinging lantern (it sways with it, so the
## light pool on the porch and the sign moves) and a softer one in the doorway (follows the door, flashes on a hire).
func _build_lights() -> void:
	_lamp_light = NeutralBuildingLook.add_light(_lantern, "LanternLight", Vector3(0, -0.5, 0), Color(1.0, 0.70, 0.36),
		1.7, 6.5, 0.22, 1.1)
	_door_light = NeutralBuildingLook.add_light(_body, "DoorLight", Vector3(1.5, Y_PLINTH, 1.5) + DOOR_DIR_LOCAL * 0.55
		+ Vector3(0, 1.1, 0), Color(1.0, 0.64, 0.30), 1.2, 4.2, 0.12, 0.7)
	_sparks = NeutralBuildingLook.add_sparks(_body, "ChimneySparks", Vector3(-2.71, 7.9, CHIMNEY_Z), 6)


# --- Ground contact, fake light pools, smoke ---

func _soft_tex(key: String, inner: Color, mid: Color, outer: Color) -> GradientTexture2D:
	if _tex_cache.has(key):
		return _tex_cache[key]
	var g := Gradient.new()
	g.set_color(0, inner)
	g.set_color(1, outer)
	g.add_point(0.5, mid)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	_tex_cache[key] = tex
	return tex


func _soft_mat(key: String, c: Color, add: bool, billboard: bool) -> StandardMaterial3D:
	var cache_key: String = "mat_" + key
	if _tex_cache.has(cache_key):
		return _tex_cache[cache_key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if add else BaseMaterial3D.BLEND_MODE_MIX
	m.disable_fog = add  # G-E 5: an additive quad must not fog
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = _soft_tex(key, c, Color(c, c.a * 0.45), Color(c, 0.0))
	_tex_cache[cache_key] = m
	return m


func _flat(nm: String, size: Vector2, pos: Vector3, yaw: float, mat: Material) -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = size
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = plane
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = yaw
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(mi)
	return mi


func _build_ground() -> void:
	# MAP.P2: a trodden-earth apron with a baked contact shadow along the plinth seats it on the map ground,
	# with a tongue of worn earth out of the door (shared mesh + material, art/environment/neutral/site_ground.gd).
	# It is the ContactDecal node (the old unshaded soft blob stays as the fallback).
	if ResourceLoader.exists(SITE_GROUND):
		(load(SITE_GROUND) as Script).call(&"add", _body, "ContactDecal", Vector2(2.7, 2.7), 0.2, 1.8, DOOR_DIR_LOCAL, 2.8, 1)
	else:
		_flat("ContactDecal", Vector2(8.0, 8.0), Vector3(0, 0.03, 0), 0.0,
			_soft_mat("contact", Color(0.05, 0.035, 0.02, 0.62), false, false))
	# A worn dirt path out of the door, warm light pools under the lantern.
	_flat("PathDecal", Vector2(2.2, 4.4), DOOR_DIR_LOCAL * 5.0 + Vector3(0, 0.035, 0), PI * 0.25,
		_soft_mat("path", Color(0.30, 0.22, 0.13, 0.7), false, false))
	var pool: StandardMaterial3D = _soft_mat("pool", Color(1.0, 0.7, 0.32, 0.2), true, false)   # 0.3 -> 0.2: under the bloom level (R5, 2026-09-30)
	_pools.append(_flat("LightPoolPorch", Vector2(2.6, 2.6), Vector3(2.35, 0.37, 2.35), 0.0, pool))
	_pools.append(_flat("LightPoolGround", Vector2(4.2, 4.2), DOOR_DIR_LOCAL * 4.7 + Vector3(0, 0.045, 0), 0.0, pool))
	# Mossy rubble stones around the plinth (one draw call), none in front of the door.
	var rng := RandomNumberGenerator.new()
	rng.seed = 9061
	var xf: Array[Transform3D] = []
	for i: int in 9:
		var a: float = PI * 0.25 + PI * 0.35 + (TAU - PI * 0.7) * (float(i) + rng.randf_range(0.0, 0.6)) / 9.0
		var r: float = rng.randf_range(3.05, 3.35)
		var s: float = rng.randf_range(0.28, 0.48)
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, deg_to_rad(rng.randf_range(8.0, 22.0)))
		xf.append(Transform3D(b.scaled(Vector3(s, s * 0.55, s * 0.8)), Vector3(sin(a) * r, s * 0.08, cos(a) * r)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _sphere(0.5, 7, 4)
	mm.instance_count = xf.size()
	for i: int in xf.size():
		mm.set_instance_transform(i, xf[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Rubble"
	mmi.multimesh = mm
	mmi.material_override = _m["dark"]
	mmi.set_instance_shader_parameter(&"ao_bottom", -0.2)
	mmi.set_instance_shader_parameter(&"ao_height", 1.0)
	_body.add_child(mmi)


func _build_smoke() -> void:
	var g := Gradient.new()
	g.set_color(0, Color(0.55, 0.52, 0.48, 0.0))
	g.set_color(1, Color(0.55, 0.52, 0.48, 0.0))
	g.add_point(0.15, Color(0.58, 0.55, 0.5, 0.42))
	g.add_point(0.6, Color(0.5, 0.48, 0.45, 0.22))
	var ramp := GradientTexture1D.new()
	ramp.gradient = g
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.15, 1.0, 0.0)
	pm.spread = 10.0
	pm.initial_velocity_min = 0.55
	pm.initial_velocity_max = 0.85
	pm.gravity = Vector3(0.18, 0.08, 0.05)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.15
	pm.scale_min = 1.7
	pm.scale_max = 1.7
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(1.0, 1.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	pm.color_ramp = ramp
	var q := QuadMesh.new()
	var qm: StandardMaterial3D = _soft_mat("smoke", Color(1, 1, 1, 1), false, false).duplicate() as StandardMaterial3D
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.vertex_color_use_as_albedo = true
	q.material = qm
	_smoke = GPUParticles3D.new()
	_smoke.name = "ChimneySmoke"
	_smoke.amount = 10
	_smoke.lifetime = 3.6
	_smoke.fixed_fps = 30
	_smoke.interpolate = true
	_smoke.local_coords = false
	_smoke.process_material = pm
	_smoke.draw_pass_1 = q
	_smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_smoke.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 7, 6))
	_smoke.position = Vector3(-2.71, 8.0, CHIMNEY_Z)
	_body.add_child(_smoke)


# --- State ---

func _apply_open() -> void:
	var k: float = _open_k
	_door.rotation.y = -deg_to_rad(105.0) * ease(k, -2.0) + PI * 0.25
	_door_glow.visible = k > 0.01
	_g_door.set_shader_parameter(&"energy", 1.5 * k)
	# 1.9 -> 1.05 (in-game grade 2026-09-30, R5: 3 windows + door + lantern = 5 glow points): the windows stay a
	# warm soft glow just under the bloom level; the door and the lantern are the two points.
	_g_window.set_shader_parameter(&"energy", lerpf(0.5, 1.05, k))
	for p: MeshInstance3D in _pools:
		p.visible = k > 0.05
		p.transparency = 1.0 - k
	_smoke.emitting = k > 0.5
	if _sparks:
		_sparks.emitting = k > 0.5
	if _lamp_light:
		_lamp_light.set_level(lerpf(0.35, 1.0, k))
	if _door_light:
		_door_light.set_level(k)
	if _pal:
		BuildingPalette.refresh(_pal)


func _apply_rim_and_glow() -> void:
	if not _ready_done:
		return
	var rim_col: Color = RIM_IDLE.lerp(RIM_SELECTED, _sel_k)
	var rim_str: float = lerpf(0.22, 0.85, _sel_k)
	for m: ShaderMaterial in _painted:
		m.set_shader_parameter(&"rim_color", rim_col)
		m.set_shader_parameter(&"rim_strength", rim_str)
	var boost: float = lerpf(1.0, 1.35, _sel_k)
	for m: ShaderMaterial in _glows:
		m.set_shader_parameter(&"boost", boost)
	_g_door.set_shader_parameter(&"boost", boost + 2.5 * sin(_pulse * PI) * _pulse)
	if _door_light and _pulse > 0.0:
		_door_light.flash(1.5 * sin(_pulse * PI))
	if _pal:
		BuildingPalette.refresh(_pal)
