class_name GreywaterLodgeModel
extends Node3D
## The Greywater Lodge, house of the Hunters' Guild (task 10.V9, docs/design/market-trade.md sections 2.3, 6, 9, 12).
## Built in code at _ready; meshes are baked once and shared by both Lodges (BuildingMerge), materials are per
## instance (selection rim, glow boost, open / closed state).
## Read from the RTS camera: a long, low hunters' hall of grey weathered logs (crossed log ends at the corners) on a
## dark fieldstone footing, under a steep grey-green shingle roof (ridge along X). A tall fieldstone chimney with a
## slab cap on the -X gable end, smoking (the dominant vertical). On the +X+Z corner (the asymmetric secondary) a raised
## watch platform on log stilts: a brazier fire, a brown pelt over the railing, a grey wolf pelt on the side rail and a
## tall pole with the grey-green guild pennant (arrow emblem) and the amber horn flag that play_contract() hoists.
## Trophies: a big antler rack on the gabled porch over the door, a horned monster skull crowning the +X ridge end,
## a smaller one on the back wall. A log kennel with a sleeping grey hound (-X+Z corner), a hide-stretching frame
## against the front wall, a woodpile under the platform, a drying rack with pelts and hides and a chopping block at
## the back. Only emissive light: the amber lantern under the porch, the brazier fire, warm windows (no Light3D).
## Palette: neutral grey timber and stone, grey-green shingles / pennant (the minimap's green Lodge mark), bone, amber.
## Clearly not the Magpie Den (tall, crooked, black / white, blue-green lantern, weather-vane, crane).
## Footprint 6 x 6 m (nothing below 2.5 m sticks out more than 0.2 m), ridge ~4.1 m, chimney cap ~6.25 m, pennant
## pole ~6 m. Root origin = footprint centre on the ground. No collision (the GuildHouse node owns it).
##
## Door / rotation: the FRONT is local +Z (the door looks along +Z). Market-trade.md 2.3 puts the door 4 m from the
## centre toward the road: north-west Lodge (-45, -55) -> door (-45, -51) = +Z, yaw 0; south-east Lodge (45, 55) ->
## door (45, 51) = -Z, yaw PI. `yaw_for_spot(spot)` / `yaw_for_door(centre, door)` give that yaw; the hall stays square
## on the grid (yaw is a multiple of 90 degrees). Door anchor (tracker spawn) = local (0, 0, DOOR_DISTANCE).
## Hooks (all safe before _ready): set_open(bool) (default open; closed = door shut, dim windows, brazier cold, no
## smoke), is_open(), set_selected(bool) (grey-green rim + glow boost), play_contract() (the amber horn flag runs up
## the pole, flies ~5 s, comes down; lantern and brazier flare), set_team_color(c) (ignored: neutral),
## get_door_point(), get_door_direction(). The pennants always fly toward world +X, like the chimney smoke drifts.

const PAINTED: Shader = preload("res://art/buildings/guilds/greywater_lodge/greywater_lodge_painted.gdshader")
const FLAG_SHADER: Shader = preload("res://art/buildings/guilds/greywater_lodge/greywater_lodge_pennant.gdshader")
const GLOW: Shader = preload("res://art/shaders/rune_glow.gdshader")
const NOISE: Texture2D = preload("res://art/shaders/paint_noise.tres")
const BMG := preload("res://art/buildings/fire_hall_merge.gd")
const KEY := "res://art/buildings/guilds/greywater_lodge/greywater_lodge"
const SITE_GROUND := "res://art/environment/neutral/site_ground.gd"

const DOOR_DISTANCE := 4.0     # door anchor, metres in front of the centre (root +Z)
const AO_HEIGHT := 4.2
const Y_PLINTH := 0.4
const LOG_R := 0.2
const LOG_PITCH := 0.38
const LOG_OVER := 0.34         # crossed log ends past the corners
const WALL_X0 := -2.2          # wall centre lines
const WALL_X1 := 2.2
const WALL_Z0 := -2.2
const WALL_Z1 := 0.55
const WALL_TOP := 2.32         # top of the long-wall plate logs
const ROOF_DEG := 40.0
const EAVE_OUT := 0.55
const VERGE_OUT := 0.4
const ROOF_THICK := 0.22
const DOOR_X := -0.1
const DOOR_TOP := 1.95
const PORCH_Z := 1.85
const CH_X := -2.72            # chimney centre (x); its z is the ridge line
const PX0 := 1.62              # watch platform posts
const PX1 := 2.72
const PZ0 := 1.52
const PZ1 := 2.72
const DECK_Y := 2.9
const POLE_TOP := 5.85         # antler crown on top, up to ~6.5
const PENNANT_TOP := 5.76
const PENNANT_SIZE := Vector2(1.6, 0.66)
const HORN_FLAG_SIZE := Vector2(0.9, 0.64)
const FLAG_LOW := 4.3          # top edge of the furled contract flag
const FLAG_HIGH := 5.02
const CHIMNEY_TOP := 6.6
const FIRE_POS := Vector3(1.92, 3.55, 2.4)
const HOUND_POS := Vector3(-1.5, 0.0, 2.05)
const CONTRACT_RAISE := 0.9
const CONTRACT_HOLD := 5.0
const CONTRACT_LOWER := 1.4
const WIND_YAW := 0.0          # world yaw the flags fly toward (+X), the chimney smoke drifts the same way

# Palette: neutral grey timber and stone, grey-green shingles, bone, amber glow.
const C_STONE := Color(0.47, 0.47, 0.45)
const C_DARK := Color(0.25, 0.25, 0.24)
const C_LOG := Color(0.57, 0.54, 0.49)
const C_LOG_END := Color(0.74, 0.63, 0.46)
const C_TIMBER := Color(0.29, 0.26, 0.22)
const C_PLANK := Color(0.55, 0.51, 0.45)
const C_SHINGLE := Color(0.49, 0.58, 0.52)   # light silver-sage: reads apart from the grass by value and hue
const C_MOSS := Color(0.30, 0.42, 0.20)
const C_BONE := Color(0.88, 0.83, 0.70)
const C_FUR_BROWN := Color(0.52, 0.35, 0.2)
const C_FUR_GREY := Color(0.56, 0.55, 0.52)
const C_HOUND := Color(0.40, 0.38, 0.36)
const C_HIDE := Color(0.76, 0.61, 0.42)
const C_IRON := Color(0.21, 0.21, 0.23)
const C_PENNANT := Color(0.33, 0.56, 0.38)
const C_PENNANT_DARK := Color(0.16, 0.27, 0.19)
const C_HORN_FLAG := Color(0.92, 0.60, 0.20)
const C_HORN_FLAG_DARK := Color(0.30, 0.17, 0.07)
const GLOW_AMBER := Color(1.0, 0.74, 0.34)
const GLOW_FIRE := Color(1.0, 0.52, 0.16)
const RIM_IDLE := Color(0.55, 0.65, 0.85)
const RIM_SELECTED := Color(0.72, 1.0, 0.7)

static var _mesh_cache: Dictionary = {}
static var _tex_cache: Dictionary = {}

var _painted: Array[ShaderMaterial] = []
var _glows: Array[ShaderMaterial] = []
var _flag_mats: Array[ShaderMaterial] = []
var _m: Dictionary = {}   # name -> ShaderMaterial
var _g_window: ShaderMaterial
var _g_door: ShaderMaterial
var _g_lantern: ShaderMaterial
var _g_fire: ShaderMaterial
var _pennant_mat: ShaderMaterial
var _horn_mat: ShaderMaterial
var _door: Node3D
var _door_glow: MeshInstance3D
var _lantern: Node3D
var _lantern_halo: MeshInstance3D
var _wind: Node3D
var _horn_flag: Node3D
var _hound: Node3D
var _fire: GPUParticles3D
var _fire_halo: MeshInstance3D
var _smoke: GPUParticles3D
var _pools: Array[MeshInstance3D] = []
var _deck_pool: MeshInstance3D

var _t: float = 0.0
var _ready_done: bool = false
var _open: bool = true
var _open_k: float = 1.0
var _selected: bool = false
var _sel_k: float = 0.0
var _contract_left: float = 0.0   # seconds the horn flag still flies at the top
var _flag_k: float = 0.0          # 0 furled at the railing, 1 hoisted
var _blast: float = 0.0           # lantern / fire flare after play_contract


func _ready() -> void:
	_ready_done = true
	_t = randf() * 10.0
	_make_materials()
	_build_structure()
	_build_door()
	_build_lantern()
	_build_flags()
	_build_hound()
	_build_ground()
	_build_fire()
	_build_smoke()
	_open_k = 1.0 if _open else 0.0
	_sel_k = 1.0 if _selected else 0.0
	_apply_open()
	_apply_flag()
	_apply_rim_and_glow()


func _process(delta: float) -> void:
	_t += delta
	_lantern.rotation = Vector3(sin(_t * 1.6 + 0.4) * 0.08, 0.0, sin(_t * 1.05) * 0.05)
	_hound.scale = Vector3(1.0, 1.0 + sin(_t * 1.7) * 0.03, 1.0 + sin(_t * 1.7) * 0.012)
	if is_inside_tree():
		_wind.global_basis = Basis(Vector3.UP, WIND_YAW + sin(_t * 0.37) * 0.1 + sin(_t * 0.11) * 0.06)
	var open_target: float = 1.0 if _open else 0.0
	if _open_k != open_target:
		_open_k = move_toward(_open_k, open_target, delta / 0.8)
		_apply_open()
	var dirty: bool = false
	var sel_target: float = 1.0 if _selected else 0.0
	if _sel_k != sel_target:
		_sel_k = move_toward(_sel_k, sel_target, delta / (0.15 if _selected else 0.25))
		dirty = true
	if _blast > 0.0:
		_blast = maxf(_blast - delta / 0.9, 0.0)
		dirty = true
	if _contract_left > 0.0:
		if _flag_k < 1.0:
			_flag_k = move_toward(_flag_k, 1.0, delta / CONTRACT_RAISE)
		else:
			_contract_left = maxf(_contract_left - delta, 0.0)
		_apply_flag()
	elif _flag_k > 0.0:
		_flag_k = move_toward(_flag_k, 0.0, delta / CONTRACT_LOWER)
		_apply_flag()
	if dirty:
		_apply_rim_and_glow()


# --- Hooks ---

## Root yaw for a Lodge centred at `spot` on Crown Hollow (market-trade.md 2.3): the north-west Lodge's door looks
## +Z (yaw 0), the south-east one's -Z (yaw PI), toward the road.
static func yaw_for_spot(spot: Vector3) -> float:
	return 0.0 if spot.z < 0.0 else PI


## Root yaw that turns the door (local +Z) from `centre` toward `door` (any map). Snap it to 90 degrees to keep the
## hall square on the grid.
static func yaw_for_door(centre: Vector3, door: Vector3) -> float:
	return snappedf(atan2(door.x - centre.x, door.z - centre.z), PI * 0.5)


## World position of the door anchor (tracker spawn point): local (0, 0, DOOR_DISTANCE).
func get_door_point() -> Vector3:
	var p := Vector3(0.0, 0.0, DOOR_DISTANCE)
	return to_global(p) if is_inside_tree() else transform * p


## World direction the door faces (the root's +Z).
func get_door_direction() -> Vector3:
	return ((global_transform.basis if is_inside_tree() else basis) * Vector3.BACK).normalized()


## Closed (before 5:00): door shut, windows dim, brazier cold, no smoke. Open: door swung out, fire lit. Default open.
func set_open(open: bool) -> void:
	_open = open


func is_open() -> bool:
	return _open


func set_selected(on: bool) -> void:
	_selected = on


## A contract was hired: the amber horn flag runs up the pole, flies CONTRACT_HOLD s, then comes down; the lantern
## and the brazier flare. Safe to retrigger (keeps the flag up).
func play_contract() -> void:
	_contract_left = CONTRACT_HOLD
	_blast = 1.0


## True while the horn flag is up or moving.
func is_contract_flag_up() -> bool:
	return _contract_left > 0.0 or _flag_k > 0.0


## The Lodge is neutral: team colours are ignored (kept so generic building code can call it).
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


func _glow(color: Color, energy: float, pulse_speed: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = GLOW
	m.set_shader_parameter(&"glow_color", color)
	m.set_shader_parameter(&"energy", energy)
	m.set_shader_parameter(&"pulse_speed", pulse_speed)
	m.set_shader_parameter(&"rune_bands", 0)
	m.set_shader_parameter(&"phase", randf() * TAU)
	_glows.append(m)
	return m


func _flag_mat(shape: int, size: Vector2, cloth: Color, stripe: Color, emblem: Color, energy: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = FLAG_SHADER
	m.set_shader_parameter(&"shape", shape)
	m.set_shader_parameter(&"size", size)
	m.set_shader_parameter(&"cloth_color", cloth)
	m.set_shader_parameter(&"stripe_color", stripe)
	m.set_shader_parameter(&"emblem_color", emblem)
	m.set_shader_parameter(&"emblem_energy", energy)
	_flag_mats.append(m)
	return m


func _make_materials() -> void:
	var stone: ShaderMaterial = _paint("stone", C_STONE, 1, 0.9, 0.5)
	stone.set_shader_parameter(&"course_height", 0.3)
	stone.set_shader_parameter(&"block_length", 0.46)
	var dark: ShaderMaterial = _paint("dark", C_DARK, 1, 0.2, 0.35)
	dark.set_shader_parameter(&"course_height", 0.4)
	dark.set_shader_parameter(&"block_length", 0.85)
	var logm: ShaderMaterial = _paint("log", C_LOG, 3, 0.35, 0.45)
	logm.set_shader_parameter(&"moss_cut", 0.62)
	_paint("log_end", C_LOG_END)
	_paint("timber", C_TIMBER, 3)
	var plank: ShaderMaterial = _paint("plank", C_PLANK, 5, 0.2)
	plank.set_shader_parameter(&"block_length", 0.24)
	var shingle: ShaderMaterial = _paint("shingle", C_SHINGLE, 2, 0.6)
	shingle.set_shader_parameter(&"course_height", 0.2)
	shingle.set_shader_parameter(&"block_length", 0.3)
	shingle.set_shader_parameter(&"moss_cut", 0.6)
	shingle.set_shader_parameter(&"moss_color", C_MOSS.darkened(0.1))
	_paint("bone", C_BONE, 0, 0.0, 0.0, 0.15)
	_paint("fur_brown", C_FUR_BROWN, 4)
	_paint("fur_grey", C_FUR_GREY, 4)
	_paint("hound", C_HOUND, 4)
	_paint("hide", C_HIDE)
	_paint("iron", C_IRON, 0, 0.0, 0.0, 0.4)
	_g_window = _glow(GLOW_AMBER, 1.7, 1.2)
	_g_door = _glow(GLOW_AMBER, 1.4, 2.0)
	_g_lantern = _glow(GLOW_AMBER, 3.6, 3.0)
	_g_fire = _glow(GLOW_FIRE, 3.2, 9.0)
	_pennant_mat = _flag_mat(0, PENNANT_SIZE, C_PENNANT, C_PENNANT_DARK, C_BONE, 0.25)
	_horn_mat = _flag_mat(1, HORN_FLAG_SIZE, C_HORN_FLAG, C_HORN_FLAG_DARK, Color(0.97, 0.92, 0.8), 0.3)


# --- Mesh helpers (cached, shared by both Lodges) ---

static func _box(size: Vector3) -> Mesh:
	var key: String = "b%s" % size
	if not _mesh_cache.has(key):
		var m := BoxMesh.new()
		m.size = size
		_mesh_cache[key] = m
	return _mesh_cache[key]


static func _cyl(top_r: float, bot_r: float, h: float, segs: int, caps: bool = true) -> Mesh:
	var key: String = "c%.3f_%.3f_%.3f_%d_%s" % [top_r, bot_r, h, segs, caps]
	if not _mesh_cache.has(key):
		var m := CylinderMesh.new()
		m.top_radius = top_r
		m.bottom_radius = bot_r
		m.height = h
		m.radial_segments = segs
		m.rings = 1
		m.cap_top = caps and top_r > 0.0
		m.cap_bottom = caps and bot_r > 0.0
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
		m.rings = 14
		m.ring_segments = 6
		_mesh_cache[key] = m
	return _mesh_cache[key]


## A rectangular frustum (half extents `b` at y 0, `t` at y `h`, x / z), flat-shaded sides + top cap, indexed.
static func _frustum(b: Vector2, t: Vector2, h: float) -> Mesh:
	var key: String = "f%s_%s_%.3f" % [b, t, h]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bot: Array[Vector3] = [Vector3(-b.x, 0, -b.y), Vector3(b.x, 0, -b.y), Vector3(b.x, 0, b.y), Vector3(-b.x, 0, b.y)]
	var top: Array[Vector3] = [Vector3(-t.x, h, -t.y), Vector3(t.x, h, -t.y), Vector3(t.x, h, t.y), Vector3(-t.x, h, t.y)]
	for i: int in 4:
		var j: int = (i + 1) % 4
		var n: Vector3 = (bot[j] - bot[i]).cross(top[i] - bot[i]).normalized()
		var mid: Vector3 = (bot[i] + bot[j] + top[i] + top[j]) * 0.25
		if n.dot(Vector3(mid.x, 0.0, mid.z)) < 0.0:
			n = -n
		_tri(st, bot[i], bot[j], top[j], n)
		_tri(st, bot[i], top[j], top[i], n)
	_tri(st, top[0], top[1], top[2], Vector3.UP)
	_tri(st, top[0], top[2], top[3], Vector3.UP)
	# Indexed like the primitive meshes: BuildingMerge's SurfaceTool.append_from drops non-indexed vertices when
	# they are merged with indexed ones.
	st.index()
	var m: ArrayMesh = st.commit()
	_mesh_cache[key] = m
	return m


## Adds a triangle facing `n` (Godot front faces wind clockwise seen from the front).
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
		"fire":
			return _g_fire
	return _m[nm]


## Basis whose +Y runs along `e` (cylinders / beams are symmetric, so a downward `e` is flipped: the arc
## quaternion from UP to -UP is degenerate).
static func _along(e: Vector3) -> Basis:
	var d: Vector3 = e.normalized()
	if d.y < 0.0:
		d = -d
	if d.is_equal_approx(Vector3.UP):
		return Basis.IDENTITY
	return Basis(Quaternion(Vector3.UP, d))


## A square beam (section `w`) from `a` to `b`.
func _beam(a: Vector3, b: Vector3, w: float, mat: String) -> Array:
	var e: Vector3 = b - a
	return _itx(_box(Vector3(w, snappedf(e.length(), 0.01), w)), Transform3D(_along(e), (a + b) * 0.5), mat)


## A round rod (radius `r`) from `a` to `b`.
func _rod(a: Vector3, b: Vector3, r: float, mat: String, segs: int = 8) -> Array:
	var e: Vector3 = b - a
	return _itx(_cyl(r, r, snappedf(e.length(), 0.01), segs), Transform3D(_along(e), (a + b) * 0.5), mat)


## A log from `a` to `b`: grey bark side and, at each end, a dark bark ring around pale end grain.
func _log(it: Array, a: Vector3, b: Vector3, r: float, caps: bool = true) -> void:
	var e: Vector3 = b - a
	var bs: Basis = _along(e)
	it.append(_itx(_cyl(r, r, snappedf(e.length(), 0.01), 10, false), Transform3D(bs, (a + b) * 0.5), "log"))
	if not caps:
		return
	var d: Vector3 = e.normalized()
	for end: Array in [[a, -d], [b, d]]:
		var p: Vector3 = end[0]
		var o: Vector3 = end[1]
		it.append(_itx(_cyl(r, r, 0.02, 10), Transform3D(bs, p), "timber"))
		it.append(_itx(_cyl(r * 0.8, r * 0.8, 0.02, 10), Transform3D(bs, p + o * 0.012), "log_end"))


## Rods through `pts` (in frame `fr`, which may carry a uniform scale), radii per segment, round joints and tip.
func _chain(it: Array, fr: Transform3D, pts: Array, radii: Array, mat: String) -> void:
	var k: float = fr.basis.x.length()
	for i: int in pts.size() - 1:
		var r: float = float(radii[mini(i, radii.size() - 1)]) * k
		var a: Vector3 = fr * (pts[i] as Vector3)
		var b: Vector3 = fr * (pts[i + 1] as Vector3)
		it.append(_rod(a, b, snappedf(r, 0.005), mat, 6))
		if i > 0:
			it.append(_itx(_sphere(snappedf(r, 0.005), 6, 3), Transform3D(Basis.IDENTITY, a), mat))
	var last_r: float = float(radii[mini(pts.size() - 2, radii.size() - 1)]) * k
	it.append(_itx(_sphere(snappedf(last_r, 0.005), 6, 3), Transform3D(Basis.IDENTITY, fr * (pts[pts.size() - 1] as Vector3)),
		mat))


func _merge(nm: String, key: String, items: Array, parent: Node3D, painted: bool = true) -> MeshInstance3D:
	var mi: MeshInstance3D = BMG.instance(nm, "%s/%s" % [KEY, key], items)
	parent.add_child(mi)
	if painted:
		mi.set_instance_shader_parameter(&"ao_bottom", 0.0)
		mi.set_instance_shader_parameter(&"ao_height", AO_HEIGHT)
	return mi


static func _ridge_z() -> float:
	return (WALL_Z0 + WALL_Z1) * 0.5


# --- Structure ---
# Local space: door +Z, ridge along X. Levels: footing 0-0.4, log walls 0.4-2.32 (long walls, 5 logs) / 2.51 (gable
# walls, 6 logs offset half a log), roof 40 degrees, ridge log top ~4.14, chimney cap ~6.25, pennant pole ~6.0.

func _build_structure() -> void:
	var it: Array = []
	_add_plinth(it)
	_add_walls(it)
	_add_roof(it)
	_add_porch(it)
	_add_chimney(it)
	_add_windows(it)
	_add_platform(it)
	_add_kennel(it)
	_add_hide_frame(it)
	_add_back_yard(it)
	_add_trophies(it)
	_merge("Structure", "structure", it, self)


func _add_plinth(it: Array) -> void:
	# Dark fieldstone footing under the hall, the porch floor and a step toward the road.
	var x0: float = WALL_X0 - LOG_R - 0.12
	var x1: float = WALL_X1 + LOG_R + 0.12
	var z0: float = WALL_Z0 - LOG_R - 0.12
	var z1: float = WALL_Z1 + LOG_R + 0.08
	it.append(_it(_box(Vector3(x1 - x0, Y_PLINTH, z1 - z0)), Vector3((x0 + x1) * 0.5, Y_PLINTH * 0.5, (z0 + z1) * 0.5),
		"dark"))
	it.append(_it(_box(Vector3(2.1, Y_PLINTH, PORCH_Z - z1 + 0.06)), Vector3(DOOR_X, Y_PLINTH * 0.5,
		(z1 + PORCH_Z) * 0.5 - 0.02), "dark"))
	it.append(_it(_box(Vector3(1.3, 0.2, 0.38)), Vector3(DOOR_X, 0.1, PORCH_Z + 0.18), "dark"))


func _add_walls(it: Array) -> void:
	# Long walls (front / back): 5 logs; gable walls (sides): 6 logs, half a log lower, so the corners interlock
	# with crossed ends sticking out LOG_OVER. The front logs under the lintel stop at the door jambs.
	var xa: float = WALL_X0 - LOG_OVER
	var xb: float = WALL_X1 + LOG_OVER
	var za: float = WALL_Z0 - LOG_OVER
	var zb: float = WALL_Z1 + LOG_OVER
	for i: int in 5:
		var y: float = Y_PLINTH + LOG_R + LOG_PITCH * i
		_log(it, Vector3(xa, y, WALL_Z0), Vector3(xb, y, WALL_Z0), LOG_R)
		if y - LOG_R < DOOR_TOP - 0.05:
			_log(it, Vector3(xa, y, WALL_Z1), Vector3(DOOR_X - 0.62, y, WALL_Z1), LOG_R)
			_log(it, Vector3(DOOR_X + 0.62, y, WALL_Z1), Vector3(xb, y, WALL_Z1), LOG_R)
		else:
			_log(it, Vector3(xa, y, WALL_Z1), Vector3(xb, y, WALL_Z1), LOG_R)
	for j: int in 6:
		var y: float = Y_PLINTH + LOG_R + LOG_PITCH * (float(j) - 0.5)
		for x: float in [WALL_X0, WALL_X1]:
			_log(it, Vector3(x, y, za), Vector3(x, y, zb), LOG_R)
	# Dark core inside the logs (no see-through gaps; shows in the doorway behind the glow).
	it.append(_it(_box(Vector3(WALL_X1 - WALL_X0 - 0.04, WALL_TOP - Y_PLINTH + 0.1, WALL_Z1 - WALL_Z0 - 0.04)),
		Vector3((WALL_X0 + WALL_X1) * 0.5, (Y_PLINTH + WALL_TOP + 0.1) * 0.5, _ridge_z()), "dark"))
	# Door frame: two jamb posts, a threshold and a lintel board.
	for sx: float in [-1.0, 1.0]:
		it.append(_it(_box(Vector3(0.16, DOOR_TOP - Y_PLINTH + 0.06, 0.5)),
			Vector3(DOOR_X + sx * 0.56, (Y_PLINTH + DOOR_TOP) * 0.5, WALL_Z1), "timber"))
	it.append(_it(_box(Vector3(1.2, 0.08, 0.5)), Vector3(DOOR_X, Y_PLINTH + 0.04, WALL_Z1 + 0.02), "timber"))
	it.append(_it(_box(Vector3(1.42, 0.16, 0.48)), Vector3(DOOR_X, DOOR_TOP + 0.04, WALL_Z1 + 0.03), "timber"))


func _add_roof(it: Array) -> void:
	# Two thick shingle slabs (ridge along X), dark barge boards along the gables, an eave log, a ridge log, plank
	# gable triangles on both gable walls.
	var a: float = deg_to_rad(ROOF_DEG)
	var t: float = tan(a)
	var zr: float = _ridge_z()
	var half: float = (WALL_Z1 - WALL_Z0) * 0.5 + LOG_R
	var run: float = half + EAVE_OUT
	var y_e: float = WALL_TOP - EAVE_OUT * t
	var length: float = run / cos(a) + 0.14
	var xm: float = (WALL_X0 + WALL_X1) * 0.5
	var vx: float = (WALL_X1 - WALL_X0) + 2.0 * VERGE_OUT
	for sz: float in [1.0, -1.0]:
		var down := Vector3(0.0, -sin(a), cos(a) * sz)
		var nrm := Vector3(0.0, cos(a), sin(a) * sz)
		var b := Basis(Vector3.RIGHT, a * sz)
		var eave := Vector3(xm, y_e, zr + sz * run)
		var centre: Vector3 = eave - down * (length * 0.5) + nrm * (ROOF_THICK * 0.5)
		it.append(_itx(_box(Vector3(vx, ROOF_THICK, length)), Transform3D(b, centre), "shingle"))
		for sx: float in [-1.0, 1.0]:
			it.append(_itx(_box(Vector3(0.12, ROOF_THICK + 0.16, length + 0.04)),
				Transform3D(b, centre + Vector3(sx * (vx * 0.5 + 0.06), 0.0, 0.0) - nrm * 0.06), "timber"))
		var e0: Vector3 = eave + nrm * (ROOF_THICK * 0.4) + down * 0.02
		_log(it, e0 - Vector3(vx * 0.5 + 0.1, 0, 0), e0 + Vector3(vx * 0.5 + 0.1, 0, 0), 0.11)
	var ridge_top: float = WALL_TOP + half * t + ROOF_THICK / cos(a)
	_log(it, Vector3(xm - vx * 0.5 - 0.14, ridge_top, zr), Vector3(xm + vx * 0.5 + 0.14, ridge_top, zr), 0.17)
	var gh: float = half * t
	for x: float in [WALL_X0, WALL_X1]:
		it.append(_it(_prism(Vector3(2.0 * half, gh, 0.16)), Vector3(x, WALL_TOP + gh * 0.5, zr), "plank",
			Vector3(0, 90, 0)))


func _add_porch(it: Array) -> void:
	# A small gabled porch over the door (ridge along Z) on two log posts: it breaks the long roof line and carries
	# the antler trophy; the lantern hangs from its tie beam.
	var a: float = deg_to_rad(ROOF_DEG)
	var t: float = tan(a)
	var plate_y: float = 2.22
	var post_z: float = PORCH_Z - 0.15
	for sx: float in [-1.0, 1.0]:
		var px: float = DOOR_X + sx * 0.85
		it.append(_it(_box(Vector3(0.34, 0.1, 0.34)), Vector3(px, Y_PLINTH + 0.05, post_z), "dark"))
		_log(it, Vector3(px, Y_PLINTH + 0.1, post_z), Vector3(px, plate_y, post_z), 0.12)
		it.append(_beam(Vector3(px, plate_y + 0.08, WALL_Z1 + 0.1), Vector3(px, plate_y + 0.08, PORCH_Z + 0.05), 0.16,
			"timber"))
		it.append(_beam(Vector3(px, plate_y - 0.55, post_z), Vector3(px, plate_y, post_z - 0.55), 0.1, "timber"))
	it.append(_beam(Vector3(DOOR_X - 1.0, plate_y + 0.08, post_z), Vector3(DOOR_X + 1.0, plate_y + 0.08, post_z), 0.16,
		"timber"))
	var rest_y: float = plate_y + 0.16          # roof underside where it rests on the plates (x = +-0.85)
	var half: float = 1.12                      # eave half-width
	var y_e: float = rest_y - (half - 0.85) * t
	var ridge_under: float = rest_y + 0.85 * t
	var z0: float = -0.25
	var z1: float = PORCH_Z + 0.12
	var depth: float = z1 - z0
	var zc: float = (z0 + z1) * 0.5
	var run: float = half / cos(a) + 0.12
	for sx: float in [1.0, -1.0]:
		var down := Vector3(cos(a) * sx, -sin(a), 0.0)
		var nrm := Vector3(sin(a) * sx, cos(a), 0.0)
		var b := Basis(Vector3.BACK, -a * sx)
		var eave := Vector3(DOOR_X + half * sx, y_e, zc)
		var centre: Vector3 = eave - down * (run * 0.5) + nrm * (ROOF_THICK * 0.5)
		it.append(_itx(_box(Vector3(run, ROOF_THICK, depth)), Transform3D(b, centre), "shingle"))
		it.append(_itx(_box(Vector3(run + 0.04, ROOF_THICK + 0.16, 0.12)),
			Transform3D(b, centre + Vector3(0, 0, depth * 0.5 + 0.06) - nrm * 0.06), "timber"))
	var ridge_top: float = ridge_under + ROOF_THICK / cos(a)
	_log(it, Vector3(DOOR_X, ridge_top - 0.03, z0 + 0.1), Vector3(DOOR_X, ridge_top - 0.03, z1 + 0.1), 0.13)
	# Front gable (planks) under the porch roof.
	var gh: float = 0.9 * t
	it.append(_it(_prism(Vector3(1.8, gh, 0.12)), Vector3(DOOR_X, rest_y + gh * 0.5, PORCH_Z - 0.08), "plank"))


func _add_chimney(it: Array) -> void:
	# Tall fieldstone chimney on the -X gable end (the dominant vertical): a broad base, a sloped weathering
	# shoulder, a tapering stack, a dark crown band and a slab cap on four stubs (the smoke comes out under it).
	var zr: float = _ridge_z()
	var base := Vector3(CH_X, 0.0, zr)
	var stack_top: float = CHIMNEY_TOP - 0.5
	it.append(_itx(_frustum(Vector2(0.45, 0.78), Vector2(0.42, 0.74), 2.6), Transform3D(Basis.IDENTITY, base), "stone"))
	it.append(_itx(_frustum(Vector2(0.42, 0.74), Vector2(0.34, 0.51), 0.5), Transform3D(Basis.IDENTITY,
		base + Vector3(0, 2.6, 0)), "stone"))
	it.append(_itx(_frustum(Vector2(0.34, 0.51), Vector2(0.31, 0.46), stack_top - 3.1), Transform3D(Basis.IDENTITY,
		base + Vector3(0, 3.1, 0)), "stone"))
	it.append(_it(_box(Vector3(0.78, 0.18, 1.06)), base + Vector3(0, stack_top + 0.09, 0), "dark"))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(_it(_box(Vector3(0.15, 0.18, 0.15)), base + Vector3(c.x * 0.27, stack_top + 0.27, c.y * 0.38), "dark"))
	it.append(_it(_box(Vector3(0.94, 0.14, 1.2)), base + Vector3(0, CHIMNEY_TOP - 0.07, 0), "dark"))
	# A few big stones standing out of the base (rough fieldstone read).
	var bumps: Array[Vector3] = [Vector3(-0.44, 0.5, 0.3), Vector3(-0.43, 1.35, -0.4), Vector3(-0.42, 2.1, 0.15),
		Vector3(0.0, 0.75, 0.76), Vector3(-0.2, 1.8, 0.72), Vector3(0.1, 1.2, -0.76)]
	for i: int in bumps.size():
		var sz: Vector3 = Vector3(0.14, 0.2, 0.32) if i < 3 else Vector3(0.32, 0.2, 0.14)
		it.append(_it(_box(sz), base + bumps[i], "stone", Vector3(0, 8.0 * (i % 2 * 2 - 1), 6.0 * (i % 3))))
	# Hearth glow slit at the foot of the outer face.
	it.append(_it(_box(Vector3(0.06, 0.26, 0.46)), base + Vector3(-0.44, 0.55, 0), "door_glow"))


func _window(it: Array, b: Basis, centre: Vector3, w: float, h: float, shutters: bool) -> void:
	# `centre` on the wall face, `b` local +Z = outward.
	var o: Vector3 = centre
	it.append(_itx(_box(Vector3(w, h, 0.06)), Transform3D(b, o + b * Vector3(0, 0, 0.02)), "window"))
	it.append(_itx(_box(Vector3(0.07, h, 0.07)), Transform3D(b, o + b * Vector3(0, 0, 0.06)), "timber"))
	it.append(_itx(_box(Vector3(w + 0.34, 0.14, 0.22)), Transform3D(b, o + b * Vector3(0, -h * 0.5 - 0.07, 0.08)), "timber"))
	it.append(_itx(_box(Vector3(w + 0.3, 0.16, 0.16)), Transform3D(b, o + b * Vector3(0, h * 0.5 + 0.08, 0.06)), "timber"))
	for sx: float in [-1.0, 1.0]:
		it.append(_itx(_box(Vector3(0.12, h, 0.12)), Transform3D(b, o + b * Vector3(sx * (w * 0.5 + 0.06), 0, 0.06)),
			"timber"))
		if shutters:
			it.append(_itx(_box(Vector3(w * 0.5, h + 0.06, 0.06)),
				Transform3D(b, o + b * Vector3(sx * (w * 0.75 + 0.14), 0, 0.07)), "plank"))


func _add_windows(it: Array) -> void:
	var zr: float = _ridge_z()
	_window(it, Basis.IDENTITY, Vector3(-1.45, 1.45, WALL_Z1 + LOG_R), 0.56, 0.46, true)
	_window(it, Basis(Vector3.UP, PI), Vector3(-1.3, 1.45, WALL_Z0 - LOG_R), 0.56, 0.46, true)
	_window(it, Basis(Vector3.UP, PI * 0.5), Vector3(WALL_X1 + 0.08, WALL_TOP + 0.58, zr), 0.42, 0.36, false)


func _add_platform(it: Array) -> void:
	# Raised watch platform on four log stilts (the secondary element): stone pads, joists, a plank deck, cross
	# braces, a railing, the ladder on the -X side, the pennant pole on the back-right post, the brazier.
	var posts: Array[Vector2] = [Vector2(PX0, PZ0), Vector2(PX1, PZ0), Vector2(PX0, PZ1), Vector2(PX1, PZ1)]
	for p: Vector2 in posts:
		it.append(_it(_box(Vector3(0.4, 0.16, 0.4)), Vector3(p.x, 0.08, p.y), "dark", Vector3(0, 20, 0)))
		_log(it, Vector3(p.x, 0.16, p.y), Vector3(p.x, DECK_Y + 0.8, p.y), 0.13)
	var cx: float = (PX0 + PX1) * 0.5
	var cz: float = (PZ0 + PZ1) * 0.5
	for z: float in [PZ0, PZ1]:
		it.append(_beam(Vector3(PX0 - 0.22, DECK_Y - 0.21, z), Vector3(PX1 + 0.22, DECK_Y - 0.21, z), 0.18, "timber"))
	for x: float in [PX0, PX1]:
		it.append(_beam(Vector3(x, DECK_Y - 0.36, PZ0 - 0.2), Vector3(x, DECK_Y - 0.36, PZ1 + 0.2), 0.14, "timber"))
	it.append(_it(_box(Vector3(PX1 - PX0 + 0.44, 0.12, PZ1 - PZ0 + 0.44)), Vector3(cx, DECK_Y - 0.06, cz), "plank"))
	# Braces: an X on the outer (+X) and back faces, one diagonal + a mid rail on the front.
	var yb0: float = 0.45
	var yb1: float = DECK_Y - 0.4
	it.append(_beam(Vector3(PX1, yb0, PZ0), Vector3(PX1, yb1, PZ1), 0.1, "timber"))
	it.append(_beam(Vector3(PX1, yb0, PZ1), Vector3(PX1, yb1, PZ0), 0.1, "timber"))
	it.append(_beam(Vector3(PX0, yb0, PZ0), Vector3(PX1, yb1, PZ0), 0.1, "timber"))
	it.append(_beam(Vector3(PX1, yb0, PZ0), Vector3(PX0, yb1, PZ0), 0.1, "timber"))
	it.append(_beam(Vector3(PX0, yb0, PZ1), Vector3(PX1, yb1, PZ1), 0.1, "timber"))
	# Railing (top and middle rails) on three sides; the -X side is open for the ladder.
	for y: float in [DECK_Y + 0.72, DECK_Y + 0.38]:
		it.append(_rod(Vector3(PX0, y, PZ1), Vector3(PX1, y, PZ1), 0.055, "timber"))
		it.append(_rod(Vector3(PX1, y, PZ0), Vector3(PX1, y, PZ1), 0.055, "timber"))
		it.append(_rod(Vector3(PX0, y, PZ0), Vector3(PX1, y, PZ0), 0.055, "timber"))
	it.append(_rod(Vector3(PX0, DECK_Y + 0.72, PZ0), Vector3(PX0, DECK_Y + 0.72, PZ0 + 0.35), 0.055, "timber"))
	# Ladder up the -X side.
	for zl: float in [1.95, 2.35]:
		it.append(_rod(Vector3(PX0 - 0.52, 0.0, zl), Vector3(PX0 - 0.1, DECK_Y + 0.6, zl), 0.045, "timber"))
	for k: int in range(1, 9):
		var f: float = float(k) / 9.0
		var p0: Vector3 = Vector3(PX0 - 0.52, 0.0, 1.95).lerp(Vector3(PX0 - 0.1, DECK_Y + 0.6, 1.95), f)
		it.append(_rod(p0, p0 + Vector3(0, 0, 0.4), 0.035, "plank", 6))
	# Pennant pole on the back-right post: iron bands, crowned with a stag skull and antlers (facing the road).
	it.append(_rod(Vector3(PX1, DECK_Y + 0.7, PZ0), Vector3(PX1, POLE_TOP, PZ0), 0.075, "timber"))
	for y: float in [DECK_Y + 0.82, POLE_TOP - 0.02]:
		it.append(_it(_cyl(0.1, 0.1, 0.07, 8), Vector3(PX1, y, PZ0), "iron"))
	_antlers(it, Transform3D(Basis(Vector3.UP, 0.35).scaled(Vector3.ONE * 0.52), Vector3(PX1, POLE_TOP, PZ0 + 0.06)),
		false)
	# Brazier on a tripod at the front-left corner of the deck; the coals glow (the fire flickers above them).
	var bp := Vector3(FIRE_POS.x, DECK_Y, FIRE_POS.z)
	for i: int in 3:
		var ang: float = TAU * float(i) / 3.0 + 0.4
		var foot: Vector3 = bp + Vector3(cos(ang) * 0.26, 0.0, sin(ang) * 0.26)
		it.append(_rod(foot, bp + Vector3(cos(ang) * 0.14, 0.42, sin(ang) * 0.14), 0.03, "iron", 6))
	it.append(_it(_cyl(0.27, 0.15, 0.2, 10), bp + Vector3(0, 0.5, 0), "iron"))
	it.append(_it(_torus(0.23, 0.3), bp + Vector3(0, 0.6, 0), "iron"))
	for c: Vector3 in [Vector3(0.07, 0.6, 0.02), Vector3(-0.08, 0.61, 0.06), Vector3(0.0, 0.62, -0.09)]:
		it.append(_it(_sphere(0.12, 8, 4), bp + c, "fire"))
	# Pelts: a brown bear pelt over the front rail, a grey wolf pelt over the outer rail.
	_pelt(it, Transform3D(Basis.IDENTITY, Vector3(cx + 0.08, DECK_Y + 0.72, PZ1)), 0.7, 0.8, "fur_brown")
	_pelt(it, Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(PX1, DECK_Y + 0.72, cz - 0.05)), 0.66, 0.62, "fur_grey")
	# A hunting horn hanging on the front-right post.
	var hf := Transform3D(Basis(Vector3.UP, -PI * 0.3), Vector3(PX1 + 0.12, DECK_Y + 0.35, PZ1 + 0.1))
	_chain(it, hf, [Vector3(0, 0, 0), Vector3(0.14, -0.13, 0), Vector3(0.32, -0.15, 0), Vector3(0.46, -0.02, 0)],
		[0.035, 0.05, 0.065], "bone")
	it.append(_itx(_cyl(0.13, 0.07, 0.14, 10), hf * Transform3D(Basis(Vector3.BACK, -0.6), Vector3(0.5, 0.04, 0)),
		"bone"))
	it.append(_itx(_cyl(0.07, 0.07, 0.05, 8), hf * Transform3D(Basis(Vector3.BACK, 0.9), Vector3(0.14, -0.13, 0)), "iron"))
	# Woodpile under the platform: short logs along Z, end grain toward the camera.
	var rows: Array[Vector3] = [Vector3(1.86, 0.14, 0), Vector3(2.14, 0.14, 0), Vector3(2.42, 0.14, 0),
		Vector3(2.0, 0.39, 0), Vector3(2.28, 0.39, 0), Vector3(2.14, 0.63, 0)]
	for p: Vector3 in rows:
		_log(it, Vector3(p.x, p.y, 1.72), Vector3(p.x, p.y, 2.5), 0.13)


## A pelt draped over a rail: `fr` origin on the rail, rail along local X, the long side hangs on local +Z. Rounded
## hide (flattened spheres) with four splayed legs and a tail, so it never reads as a board.
func _pelt(it: Array, fr: Transform3D, w: float, drop: float, mat: String) -> void:
	it.append(_itx(_sphere(0.5, 12, 6), fr * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-8.0)) \
		* Basis.from_scale(Vector3(w, drop, 0.08)), Vector3(0, -drop * 0.46 + 0.02, 0.09)), mat))
	it.append(_itx(_sphere(0.5, 10, 5), fr * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(8.0)) \
		* Basis.from_scale(Vector3(w * 0.86, drop * 0.5, 0.08)), Vector3(0, -drop * 0.18, -0.08)), mat))
	it.append(_itx(_cyl(0.075, 0.075, w * 0.86, 8), fr * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, 0.02, 0)),
		mat))
	for sx: float in [-1.0, 1.0]:
		# Fore legs splay sideways near the rail, hind legs at the bottom.
		it.append(_itx(_box(Vector3(0.3, 0.12, 0.05)), fr * Transform3D(Basis(Vector3.BACK, sx * 0.35),
			Vector3(sx * (w * 0.5 + 0.08), -drop * 0.2, 0.13)), mat))
		it.append(_itx(_box(Vector3(0.12, 0.3, 0.05)), fr * Transform3D(Basis(Vector3.BACK, sx * 0.45),
			Vector3(sx * (w * 0.36), -drop * 0.92, 0.17)), mat))
	it.append(_itx(_box(Vector3(0.07, 0.2, 0.04)), fr * Transform3D(Basis.IDENTITY, Vector3(0, -drop - 0.02, 0.17)), mat))


func _add_kennel(it: Array) -> void:
	# A small plank kennel with a steep shingle roof (-X+Z corner): its gable and arched opening face the road (+Z),
	# crossed bones over the arch, a food bowl with a gnawed bone. The hound sleeps beside it (+X side).
	var kx: float = -2.4
	var kz: float = 1.9
	var hw: float = 0.47          # half width (x)
	var hd: float = 0.5           # half depth (z)
	var a: float = deg_to_rad(42.0)
	var t: float = tan(a)
	var wall_top: float = 0.66
	it.append(_it(_box(Vector3(hw * 2.0 + 0.12, 0.1, hd * 2.0 + 0.12)), Vector3(kx, 0.05, kz), "timber"))
	it.append(_it(_box(Vector3(hw * 2.0, wall_top - 0.1, hd * 2.0)), Vector3(kx, (wall_top + 0.1) * 0.5, kz), "plank"))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(_it(_box(Vector3(0.11, wall_top - 0.04, 0.11)), Vector3(kx + c.x * hw, wall_top * 0.5 + 0.03,
			kz + c.y * hd), "timber"))
	# Roof: ridge along Z, slopes down to +-X eaves (like the porch).
	var run: float = hw + 0.14
	var y_e: float = wall_top - 0.14 * t
	var length: float = run / cos(a) + 0.06
	for sx: float in [1.0, -1.0]:
		var down := Vector3(cos(a) * sx, -sin(a), 0.0)
		var nrm := Vector3(sin(a) * sx, cos(a), 0.0)
		var b := Basis(Vector3.BACK, -a * sx)
		var eave := Vector3(kx + sx * run, y_e, kz)
		it.append(_itx(_box(Vector3(length, 0.1, hd * 2.0 + 0.3)), Transform3D(b, eave - down * (length * 0.5) + nrm * 0.05),
			"shingle"))
	var gh: float = hw * t
	for sz: float in [-1.0, 1.0]:
		it.append(_it(_prism(Vector3(hw * 2.0, gh, 0.06)), Vector3(kx, wall_top + gh * 0.5, kz + sz * hd), "plank"))
	var ridge_top: float = wall_top + gh + 0.1 / cos(a)
	it.append(_rod(Vector3(kx, ridge_top, kz - hd - 0.17), Vector3(kx, ridge_top, kz + hd + 0.17), 0.06, "timber"))
	# Arched opening on the +Z gable face.
	var fz: float = kz + hd + 0.01
	it.append(_it(_box(Vector3(0.42, 0.32, 0.03)), Vector3(kx, 0.28, fz), "dark"))
	it.append(_it(_cyl(0.21, 0.21, 0.03, 12), Vector3(kx, 0.44, fz), "dark", Vector3(90, 0, 0)))
	# Crossed bones on the gable above the arch.
	for s: float in [-1.0, 1.0]:
		var p0 := Vector3(kx - 0.17 * s, wall_top + 0.02, fz + 0.02)
		var p1 := Vector3(kx + 0.17 * s, wall_top + 0.28, fz + 0.02)
		it.append(_rod(p0, p1, 0.035, "bone", 6))
		it.append(_it(_sphere(0.055, 6, 3), p0, "bone"))
		it.append(_it(_sphere(0.055, 6, 3), p1, "bone"))
	# Bowl and a gnawed bone in front of the kennel.
	it.append(_it(_cyl(0.17, 0.12, 0.09, 10), Vector3(kx - 0.3, 0.045, 2.72), "plank"))
	it.append(_rod(Vector3(kx + 0.12, 0.05, 2.62), Vector3(kx + 0.32, 0.05, 2.8), 0.03, "bone", 6))
	it.append(_it(_sphere(0.05, 6, 3), Vector3(kx + 0.12, 0.05, 2.62), "bone"))
	it.append(_it(_sphere(0.05, 6, 3), Vector3(kx + 0.32, 0.05, 2.8), "bone"))


func _add_hide_frame(it: Array) -> void:
	# Hide-stretching frame leaning on the back wall by the chimney corner: a pole frame, a tan hide inside.
	var tilt: float = atan2(0.42, 1.6)
	var fr := Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, -tilt),
		Vector3(-0.05, 0.0, WALL_Z0 - LOG_R - 0.45))
	for sx: float in [-1.0, 1.0]:
		it.append(_itx(_cyl(0.05, 0.05, 1.7, 6), fr * Transform3D(Basis.IDENTITY, Vector3(sx * 0.45, 0.85, 0)), "timber"))
	for y: float in [0.28, 1.5]:
		it.append(_itx(_cyl(0.045, 0.045, 1.08, 6), fr * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, y, 0)),
			"timber"))
	it.append(_itx(_sphere(0.5, 10, 5), fr * Transform3D(Basis.from_scale(Vector3(0.76, 1.1, 0.05)),
		Vector3(0, 0.89, 0.02)), "hide"))


func _add_back_yard(it: Array) -> void:
	# Drying rack (two A-frames and a bar) with pelts and hide strips; a chopping block with an axe.
	var z: float = -2.95
	for x: float in [0.78, 2.0]:
		for sx: float in [-1.0, 1.0]:
			it.append(_rod(Vector3(x + sx * 0.3, 0.0, z), Vector3(x, 1.74, z), 0.05, "timber", 6))
	it.append(_rod(Vector3(0.58, 1.7, z), Vector3(2.2, 1.7, z), 0.055, "timber", 6))
	_pelt(it, Transform3D(Basis(Vector3.UP, PI), Vector3(1.08, 1.7, z)), 0.46, 0.8, "fur_brown")
	for i: int in 2:
		it.append(_it(_box(Vector3(0.12, 0.62, 0.03)), Vector3(1.45 + 0.13 * i, 1.35, z - 0.03 * i), "hide",
			Vector3(0, 0, 4.0 - 8.0 * i)))
	var cb := Vector3(-2.85, 0.0, -2.3)
	it.append(_it(_cyl(0.23, 0.26, 0.44, 10, false), cb + Vector3(0, 0.22, 0), "log"))
	it.append(_it(_cyl(0.23, 0.23, 0.02, 10), cb + Vector3(0, 0.44, 0), "log_end"))
	it.append(_rod(cb + Vector3(0.05, 0.46, 0.02), cb + Vector3(0.3, 0.98, -0.12), 0.035, "timber", 6))
	it.append(_it(_box(Vector3(0.06, 0.14, 0.24)), cb + Vector3(0.04, 0.48, 0.02), "iron", Vector3(0, 0, -25)))


func _add_trophies(it: Array) -> void:
	var zr: float = _ridge_z()
	# The great antler rack on the porch gable (faces the road, spikes above the porch ridge).
	_antlers(it, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.85), Vector3(DOOR_X, 2.62, PORCH_Z + 0.02)))
	# A horned monster skull crowning the +X ridge end, snout outward.
	var ridge_top: float = WALL_TOP + ((WALL_Z1 - WALL_Z0) * 0.5 + LOG_R) * tan(deg_to_rad(ROOF_DEG)) \
		+ ROOF_THICK / cos(deg_to_rad(ROOF_DEG))
	_monster_skull(it, Transform3D(Basis(Vector3.UP, PI * 0.5).scaled(Vector3.ONE * 1.0),
		Vector3(WALL_X1 + VERGE_OUT - 0.05, ridge_top + 0.22, zr)))
	# A smaller one hung on the drying rack at the back (seen on the south-east Lodge, which turns its back to the
	# camera).
	_monster_skull(it, Transform3D(Basis(Vector3.UP, PI).scaled(Vector3.ONE * 0.4), Vector3(2.0, 1.4, -2.96)))


## Antler rack on a round plaque (frame: +Z forward, +Y up, uniform scale allowed). ~1.9 m wide, 1.35 m tall at 1.0.
func _antlers(it: Array, fr: Transform3D, plaque: bool = true) -> void:
	if plaque:
		it.append(_itx(_cyl(0.3, 0.3, 0.08, 12), fr * Transform3D(Basis(Vector3.RIGHT, PI * 0.5),
			Vector3(0, 0.06, -0.04)), "timber"))
	it.append(_itx(_sphere(0.5, 10, 6), fr * Transform3D(Basis.from_scale(Vector3(0.28, 0.26, 0.28)),
		Vector3(0, 0.08, 0.1)), "bone"))
	it.append(_itx(_box(Vector3(0.15, 0.13, 0.3)), fr * Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(0, -0.03, 0.28)),
		"bone"))
	for sx: float in [-1.0, 1.0]:
		it.append(_itx(_sphere(0.045, 6, 3), fr * Transform3D(Basis.IDENTITY, Vector3(sx * 0.075, 0.1, 0.21)), "dark"))
		var beam: Array = [Vector3(0.08 * sx, 0.14, 0.08), Vector3(0.3 * sx, 0.26, 0.06), Vector3(0.54 * sx, 0.48, 0.0),
			Vector3(0.72 * sx, 0.8, -0.04), Vector3(0.75 * sx, 1.1, 0.0), Vector3(0.64 * sx, 1.32, 0.06)]
		_chain(it, fr, beam, [0.08, 0.072, 0.064, 0.055, 0.045], "bone")
		var tines: Array = [[beam[1], Vector3(0.36 * sx, 0.4, 0.38)], [beam[2], Vector3(0.48 * sx, 0.86, 0.2)],
			[beam[3], Vector3(0.99 * sx, 1.02, 0.02)], [beam[4], Vector3(0.96 * sx, 1.36, 0.08)]]
		for tn: Array in tines:
			_chain(it, fr, tn, [0.048], "bone")


## Horned monster skull (frame: +Z = snout, +Y up, uniform scale allowed): ~1.4 m horn span, 0.9 m long at 1.0.
func _monster_skull(it: Array, fr: Transform3D) -> void:
	it.append(_itx(_sphere(0.5, 12, 6), fr * Transform3D(Basis.from_scale(Vector3(0.62, 0.5, 0.62)), Vector3.ZERO), "bone"))
	it.append(_itx(_box(Vector3(0.58, 0.1, 0.16)), fr * Transform3D(Basis.IDENTITY, Vector3(0, 0.13, 0.2)), "bone"))
	it.append(_itx(_frustum(Vector2(0.17, 0.12), Vector2(0.1, 0.075), 0.52), fr * Transform3D(Basis(Vector3.RIGHT,
		PI * 0.5), Vector3(0, -0.05, 0.12)), "bone"))
	it.append(_itx(_box(Vector3(0.26, 0.08, 0.42)), fr * Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(0, -0.2, 0.3)),
		"bone"))
	for sx: float in [-1.0, 1.0]:
		it.append(_itx(_sphere(0.08, 8, 4), fr * Transform3D(Basis.from_scale(Vector3(1.0, 0.8, 0.6)),
			Vector3(sx * 0.15, 0.05, 0.26)), "dark"))
		it.append(_itx(_sphere(0.035, 6, 3), fr * Transform3D(Basis.IDENTITY, Vector3(sx * 0.05, -0.02, 0.63)), "dark"))
		it.append(_itx(_cyl(0.045, 0.0, 0.22, 6), fr * Transform3D(Basis.IDENTITY, Vector3(sx * 0.11, -0.25, 0.52)), "bone"))
		_chain(it, fr, [Vector3(0.2 * sx, 0.14, -0.04), Vector3(0.44 * sx, 0.33, -0.16), Vector3(0.64 * sx, 0.33, -0.02),
			Vector3(0.69 * sx, 0.14, 0.14), Vector3(0.58 * sx, 0.0, 0.23)], [0.1, 0.085, 0.068, 0.05], "timber")


# --- Moving parts ---

func _build_door() -> void:
	# Doorway glow (the warm inside) and the plank door hinged on the -X jamb, swinging out when open.
	var glow_it: Array = [_it(_box(Vector3(0.98, DOOR_TOP - Y_PLINTH, 0.04)),
		Vector3(DOOR_X, (Y_PLINTH + DOOR_TOP) * 0.5, WALL_Z1 + 0.02), "door_glow")]
	_door_glow = _merge("DoorGlow", "door_glow", glow_it, self, false)
	_door_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_door = Node3D.new()
	_door.name = "DoorPivot"
	_door.position = Vector3(DOOR_X - 0.47, Y_PLINTH, WALL_Z1 + 0.12)
	add_child(_door)
	var h: float = DOOR_TOP - Y_PLINTH - 0.04
	var it: Array = []
	it.append(_it(_box(Vector3(0.94, h, 0.08)), Vector3(0.47, h * 0.5, 0.0), "plank"))
	for y: float in [0.3, h - 0.3]:
		it.append(_it(_box(Vector3(0.86, 0.09, 0.11)), Vector3(0.47, y, 0.0), "iron"))
	it.append(_beam(Vector3(0.12, 0.38, 0.05), Vector3(0.82, h - 0.38, 0.05), 0.08, "timber"))
	it.append(_itx(_torus(0.05, 0.09), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.82, h * 0.5, 0.08)), "iron"))
	_merge("DoorLeaf", "door_leaf", it, _door)


func _build_lantern() -> void:
	# Amber lantern hanging from the porch tie beam (the landmark light, with a soft halo; no Light3D).
	_lantern = Node3D.new()
	_lantern.name = "LanternPivot"
	_lantern.position = Vector3(DOOR_X, 2.22, PORCH_Z - 0.15)
	add_child(_lantern)
	var it: Array = []
	it.append(_it(_box(Vector3(0.04, 0.12, 0.04)), Vector3(0, -0.06, 0), "iron"))
	it.append(_it(_torus(0.03, 0.07), Vector3(0, -0.14, 0), "iron", Vector3(90, 0, 0)))
	it.append(_it(_cyl(0.02, 0.24, 0.16, 4), Vector3(0, -0.25, 0), "iron", Vector3(0, 45, 0)))
	it.append(_it(_box(Vector3(0.27, 0.34, 0.27)), Vector3(0, -0.5, 0), "lantern"))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(_it(_box(Vector3(0.05, 0.38, 0.05)), Vector3(c.x * 0.145, -0.5, c.y * 0.145), "iron"))
	it.append(_it(_box(Vector3(0.34, 0.06, 0.34)), Vector3(0, -0.33, 0), "iron"))
	it.append(_it(_box(Vector3(0.32, 0.07, 0.32)), Vector3(0, -0.69, 0), "iron"))
	var mi: MeshInstance3D = _merge("Lantern", "lantern", it, _lantern)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lantern_halo = _halo("LanternHalo", 1.9,Color(1.0, 0.76, 0.4, 0.55), "halo_amber")
	_lantern_halo.position = Vector3(0, -0.5, 0)
	_lantern.add_child(_lantern_halo)


func _halo(nm: String, size: float, c: Color, key: String) -> MeshInstance3D:
	var halo := MeshInstance3D.new()
	halo.name = nm
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	halo.mesh = q
	halo.material_override = _soft_mat(key, c, true, true)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return halo


func _build_flags() -> void:
	# The pivot sits on the pole axis; _process turns it so the flags fly toward world +X (wind).
	_wind = Node3D.new()
	_wind.name = "FlagPivot"
	_wind.position = Vector3(PX1, 0.0, PZ0)
	add_child(_wind)
	var pen := MeshInstance3D.new()
	pen.name = "Pennant"
	var pm := PlaneMesh.new()
	pm.size = PENNANT_SIZE
	pm.orientation = PlaneMesh.FACE_Z
	pm.subdivide_width = 8
	pen.mesh = pm
	pen.material_override = _pennant_mat
	pen.position = Vector3(0.07 + PENNANT_SIZE.x * 0.5, PENNANT_TOP - PENNANT_SIZE.y * 0.5, 0.0)
	pen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pen.set_instance_shader_parameter(&"phase", randf() * TAU)
	_wind.add_child(pen)
	_horn_flag = Node3D.new()
	_horn_flag.name = "HornFlagPivot"
	_horn_flag.position = Vector3(0.07, FLAG_LOW, 0.0)
	_wind.add_child(_horn_flag)
	var hf := MeshInstance3D.new()
	hf.name = "HornFlag"
	var hm := PlaneMesh.new()
	hm.size = HORN_FLAG_SIZE
	hm.orientation = PlaneMesh.FACE_Z
	hm.subdivide_width = 5
	hf.mesh = hm
	hf.material_override = _horn_mat
	hf.position = Vector3(HORN_FLAG_SIZE.x * 0.5, -HORN_FLAG_SIZE.y * 0.5, 0.0)
	hf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hf.set_instance_shader_parameter(&"phase", randf() * TAU)
	_horn_flag.add_child(hf)


func _build_hound() -> void:
	# A big grey wolfhound asleep in front of the kennel (breathes in _process).
	_hound = Node3D.new()
	_hound.name = "Hound"
	_hound.position = HOUND_POS
	_hound.rotation.y = 0.12
	add_child(_hound)
	# Lying sphinx-like: long lean body, deep chest, head up on the fore paws, long muzzle, pricked ears, a long
	# tail curled along the flank. Dark slate fur, a darker muzzle and ears, an iron collar.
	var it: Array = []
	it.append(_it(_sphere(0.5, 12, 6), Vector3(0, 0.19, -0.05), "hound", Vector3.ZERO, Vector3(0.38, 0.32, 1.0)))
	it.append(_it(_sphere(0.5, 10, 5), Vector3(0, 0.25, 0.28), "hound", Vector3.ZERO, Vector3(0.36, 0.36, 0.4)))
	it.append(_it(_sphere(0.5, 10, 5), Vector3(0, 0.2, -0.38), "hound", Vector3.ZERO, Vector3(0.36, 0.3, 0.36)))
	it.append(_it(_sphere(0.5, 10, 5), Vector3(0, 0.4, 0.5), "hound", Vector3.ZERO, Vector3(0.24, 0.24, 0.3)))
	it.append(_itx(_frustum(Vector2(0.075, 0.065), Vector2(0.045, 0.04), 0.3), Transform3D(Basis(Vector3.RIGHT,
		PI * 0.5 + 0.12), Vector3(0, 0.38, 0.58)), "dark"))
	it.append(_it(_sphere(0.045, 6, 3), Vector3(0, 0.35, 0.88), "dark"))
	for sx: float in [-1.0, 1.0]:
		it.append(_it(_cyl(0.0, 0.06, 0.17, 4), Vector3(sx * 0.08, 0.56, 0.46), "dark", Vector3(-15, 45, sx * 18)))
		it.append(_it(_sphere(0.5, 8, 4), Vector3(sx * 0.1, 0.05, 0.56), "hound", Vector3.ZERO, Vector3(0.09, 0.08, 0.34)))
	it.append(_it(_torus(0.11, 0.15), Vector3(0, 0.36, 0.4), "iron", Vector3(70, 0, 0)))
	var tail: Array = [Vector3(0.05, 0.14, -0.52), Vector3(0.24, 0.07, -0.44), Vector3(0.26, 0.05, -0.12),
		Vector3(0.22, 0.05, 0.12)]
	_chain(it, Transform3D.IDENTITY, tail, [0.06, 0.05, 0.04], "hound")
	var mi: MeshInstance3D = _merge("HoundMesh", "hound", it, _hound)
	mi.set_instance_shader_parameter(&"ao_height", 0.8)


# --- Ground contact, fake light pools, fire, smoke ---

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
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = _soft_tex(key, c, Color(c, c.a * 0.45), Color(c, 0.0))
	_tex_cache[cache_key] = m
	return m


func _flat(nm: String, size: Vector2, pos: Vector3, mat: Material) -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = size
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = plane
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _build_ground() -> void:
	# Contact decal (art-keep.md 0.5), a trodden path from the porch to the door anchor, warm light pools.
	# MAP.P2: the ContactDecal is a trodden-earth apron with a baked contact shadow along the footing, its tongue
	# out of the porch to the road (shared mesh + material, art/environment/neutral/site_ground.gd). The old
	# unshaded soft blob stays as the fallback.
	if ResourceLoader.exists(SITE_GROUND):
		(load(SITE_GROUND) as Script).call(&"add", self, "ContactDecal", Vector2(2.35, 2.35), 0.35, 2.0, Vector3(0, 0, 1), 2.0, 4)
	else:
		_flat("ContactDecal", Vector2(8.4, 8.4), Vector3(-0.1, 0.03, 0.0),
			_soft_mat("contact", Color(0.05, 0.035, 0.02, 0.62), false, false))
	_flat("PathDecal", Vector2(1.9, 2.8), Vector3(DOOR_X * 0.5, 0.035, 3.2),
		_soft_mat("path", Color(0.30, 0.23, 0.14, 0.7), false, false))
	var pool: StandardMaterial3D = _soft_mat("pool", Color(1.0, 0.7, 0.32, 0.3), true, false)
	_pools.append(_flat("LightPoolPorch", Vector2(2.2, 2.2), Vector3(DOOR_X, Y_PLINTH + 0.015, 1.3), pool))
	_pools.append(_flat("LightPoolGround", Vector2(3.4, 3.4), Vector3(DOOR_X, 0.045, 2.6), pool))
	_deck_pool = _flat("LightPoolDeck", Vector2(1.7, 1.7), Vector3(FIRE_POS.x + 0.1, DECK_Y + 0.012, FIRE_POS.z - 0.1),
		_soft_mat("pool_fire", Color(1.0, 0.55, 0.2, 0.16), true, false))
	# Fieldstones around the footing (one draw call), none on the door path or under the platform.
	var rng := RandomNumberGenerator.new()
	rng.seed = 10909
	var spots: Array[Vector2] = [Vector2(-2.75, -2.9), Vector2(-1.6, -2.95), Vector2(-0.5, -2.8), Vector2(2.3, -2.9),
		Vector2(2.55, -1.8), Vector2(2.5, -0.6), Vector2(-2.85, 0.35), Vector2(-3.0, -2.0), Vector2(-2.9, 1.0),
		Vector2(1.05, 2.75)]
	var xf: Array[Transform3D] = []
	for p: Vector2 in spots:
		var s: float = rng.randf_range(0.28, 0.46)
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, deg_to_rad(rng.randf_range(8.0, 22.0)))
		xf.append(Transform3D(b.scaled(Vector3(s, s * 0.55, s * 0.8)), Vector3(p.x, s * 0.08, p.y)))
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
	add_child(mmi)


func _particle_quad(key: String) -> QuadMesh:
	var q := QuadMesh.new()
	var qm: StandardMaterial3D = _soft_mat(key, Color(1, 1, 1, 1), key == "fire_part", false).duplicate() as StandardMaterial3D
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.vertex_color_use_as_albedo = true
	q.material = qm
	return q


func _build_fire() -> void:
	# Brazier flames: a few additive licks over the coals, plus a soft halo so the fire reads from 60 m.
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.85, 0.45, 0.95))
	g.set_color(1, Color(0.7, 0.15, 0.04, 0.0))
	g.add_point(0.45, Color(1.0, 0.5, 0.14, 0.7))
	var ramp := GradientTexture1D.new()
	ramp.gradient = g
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.0
	pm.gravity = Vector3(0, 0.6, 0)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.1
	pm.scale_min = 0.8
	pm.scale_max = 1.1
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.25))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	pm.color_ramp = ramp
	var q: QuadMesh = _particle_quad("fire_part")
	q.size = Vector2(0.42, 0.42)
	_fire = GPUParticles3D.new()
	_fire.name = "BrazierFire"
	_fire.amount = 12
	_fire.lifetime = 0.6
	_fire.fixed_fps = 30
	_fire.interpolate = true
	_fire.local_coords = true
	_fire.process_material = pm
	_fire.draw_pass_1 = q
	_fire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fire.visibility_aabb = AABB(Vector3(-1, -0.5, -1), Vector3(2, 2.5, 2))
	_fire.position = FIRE_POS
	add_child(_fire)
	_fire_halo = _halo("FireHalo", 2.2,Color(1.0, 0.58, 0.22, 0.6), "halo_fire")
	_fire_halo.position = FIRE_POS + Vector3(0, 0.1, 0)
	add_child(_fire_halo)


func _build_smoke() -> void:
	var g := Gradient.new()
	g.set_color(0, Color(0.55, 0.56, 0.55, 0.0))
	g.set_color(1, Color(0.55, 0.56, 0.55, 0.0))
	g.add_point(0.15, Color(0.6, 0.6, 0.58, 0.45))
	g.add_point(0.6, Color(0.52, 0.53, 0.52, 0.24))
	var ramp := GradientTexture1D.new()
	ramp.gradient = g
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.1, 1.0, 0.0)
	pm.spread = 10.0
	pm.initial_velocity_min = 0.55
	pm.initial_velocity_max = 0.85
	pm.gravity = Vector3(0.2, 0.08, 0.04)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.18
	pm.scale_min = 1.8
	pm.scale_max = 1.8
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(1.0, 1.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	pm.color_ramp = ramp
	_smoke = GPUParticles3D.new()
	_smoke.name = "ChimneySmoke"
	_smoke.amount = 10
	_smoke.lifetime = 3.8
	_smoke.fixed_fps = 30
	_smoke.interpolate = true
	_smoke.local_coords = false
	_smoke.process_material = pm
	_smoke.draw_pass_1 = _particle_quad("smoke")
	_smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_smoke.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 7, 6))
	_smoke.position = Vector3(CH_X, CHIMNEY_TOP - 0.2, _ridge_z())
	add_child(_smoke)


# --- State ---

func _apply_open() -> void:
	var k: float = _open_k
	_door.rotation.y = -deg_to_rad(100.0) * ease(k, -2.0)
	_door_glow.visible = k > 0.01
	_g_door.set_shader_parameter(&"energy", 1.4 * k)
	_g_window.set_shader_parameter(&"energy", lerpf(0.6, 1.7, k))
	_g_fire.set_shader_parameter(&"energy", lerpf(0.45, 3.2, k))
	_g_lantern.set_shader_parameter(&"energy", lerpf(2.6, 3.6, k))
	for p: MeshInstance3D in _pools:
		p.visible = k > 0.05
		p.transparency = 1.0 - k
	_deck_pool.visible = k > 0.05
	_deck_pool.transparency = 1.0 - k
	_fire.emitting = k > 0.5
	_fire_halo.visible = k > 0.05
	_fire_halo.transparency = 1.0 - k
	_smoke.emitting = k > 0.5


func _apply_flag() -> void:
	if not _ready_done:
		return
	var e: float = ease(_flag_k, -1.8)
	_horn_flag.position.y = lerpf(FLAG_LOW, FLAG_HIGH, e)
	_horn_flag.scale = Vector3(lerpf(0.16, 1.0, clampf(_flag_k * 1.4, 0.0, 1.0)), 1.0, 1.0)
	_horn_mat.set_shader_parameter(&"amplitude", lerpf(0.02, 0.12, _flag_k))


func _apply_rim_and_glow() -> void:
	if not _ready_done:
		return
	var rim_col: Color = RIM_IDLE.lerp(RIM_SELECTED, _sel_k)
	var rim_str: float = lerpf(0.22, 0.85, _sel_k)
	for m: ShaderMaterial in _painted:
		m.set_shader_parameter(&"rim_color", rim_col)
		m.set_shader_parameter(&"rim_strength", rim_str)
	for m: ShaderMaterial in _flag_mats:
		m.set_shader_parameter(&"rim_color", rim_col)
		m.set_shader_parameter(&"rim_strength", 0.6 * _sel_k)
	var boost: float = lerpf(1.0, 1.35, _sel_k)
	var flare: float = sin(_blast * PI) * _blast
	for m: ShaderMaterial in _glows:
		m.set_shader_parameter(&"boost", boost)
	_g_lantern.set_shader_parameter(&"boost", boost + 1.2 * flare)
	_g_fire.set_shader_parameter(&"boost", boost + 1.0 * flare)
