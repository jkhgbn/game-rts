class_name TradePostModel
extends Node3D
## Neutral trading post (task 10.V10, docs/design/market-trade.md sections 2.2 and 9): an open-sided timber
## waystation where caravans stop. Built in code at _ready, meshes baked once and shared by the four posts
## (BuildingMerge), materials per instance (selection rim, glow boost). No collision, no gameplay (TradePost owns it).
## Read from the RTS camera: a low mossy stone platform carrying a timber hall with a hipped clay-tile roof (open at the
## sides, a plank back wall, a trading counter with a hinged shutter, goods stacked inside), a striped cream / saffron
## awning over the front, and on the front-right corner the dominant vertical: a 6 m signpost mast with a crossarm
## holding a big hanging sign (gilded emblem on a dark teal board: heron, millstone, lantern or gate, `sign_index`), a
## fingerpost pair, a lantern on a bracket over the trading spot and, when a team holds the post, its pennant at the
## mast top. Secondary: the awning, an iron brazier at the front-left, a hitching rail with a water trough on the +X side.
## Footprint 6 x 6 m (nothing below 2.5 m sticks out more than 0.3 m, the lantern bracket and the sign head above that),
## roof ridge ~4.4 m, mast top ~6.1 m. Root origin = footprint centre on the ground. Palette: stone, timber, clay tiles,
## cream / saffron canvas, iron + gold; glow points: the lantern (1.0, 0.8, 0.4) and the brazier coals. 0 lights.
##
## Front / rotation: the FRONT of the scene is local +Z (the counter and the door point face +Z). Turn the root so +Z
## faces the post's door: rotation.y = yaw_for_door(centre, door) (all four posts then stand square on the grid). The
## door anchor is local (0, 0, DOOR_DISTANCE) = 4 m, matching market-trade.md 2.2 (get_door_point()).
## The sign head always turns its board toward the default camera (world +Z) whatever the post's yaw, so the emblem is
## never seen edge-on; its arm points away from the building.
## Hooks (all safe before _ready): set_sign(i) / sign_index (0 heron, 1 millstone, 2 lantern, 3 gate;
## sign_for_post(post_id)), set_open(bool) (closed before 4:00: shutter down, awning rolled, brazier cold, lantern dim;
## default open), set_held(color_or_null) (the holder's pennant rises on the mast; null lowers it), set_selected(bool),
## play_trade() (a caravan traded: the sign swings, the lantern flares), set_team_color(c) (ignored: neutral).

const PAINTED: Shader = preload("res://art/buildings/trade_post/trade_post_painted.gdshader")
const PENNANT: Shader = preload("res://art/buildings/trade_post/trade_post_pennant.gdshader")
const GLOW: Shader = preload("res://art/shaders/rune_glow.gdshader")
const NOISE: Texture2D = preload("res://art/shaders/paint_noise.tres")
const BMG := preload("res://art/buildings/fire_hall_merge.gd")

const SIGN_NAMES: Array[StringName] = [&"heron", &"millstone", &"lantern", &"gate"]
const POST_SIGNS := {&"heron_ford": 0, &"millstone_cross": 1, &"lantern_wharf": 2, &"saltgate": 3}
const SIGN_COUNT := 4
const DOOR_DISTANCE := 4.0
const HEIGHT := 4.4            # roof ridge cap
const MAST_TOP := 6.1
const KEY := "res://art/buildings/trade_post/trade_post_model"
const SITE_GROUND := "res://art/environment/neutral/site_ground.gd"

const Y_PLINTH := 0.24
const Y_PLATE := 2.78          # top of the posts
const Y_PLATE_TOP := 3.02      # top of the wall plates = where the roof planes pass
const HALL_X := 2.05
const HALL_Z0 := -2.25         # back posts
const HALL_Z1 := 0.85          # front posts
const EAVE := 0.7
const ROOF_DEG := 35.0
const ROOF_THICK := 0.2
const MAST := Vector3(2.5, 0.0, 2.45)
const ARM_Y := 5.25            # crossarm height (sign head origin)
const ARM_LEN := 1.95
const SIGN_W := 1.8
const SIGN_H := 1.36
const SIGN_X := 1.08           # board centre along the arm
const EMBLEM_SCALE := 1.12     # the emblems are drawn for a 1.4 x 1.0 field, scaled up to the board
const SIGN_TILT := 0.22        # rad: the board's bottom swings out toward the camera, the face turns up
const LANTERN_Y := 3.3
const BRAZIER := Vector3(-2.35, 0.0, 2.4)
const AWNING_X0 := -1.6
const AWNING_X1 := 1.3
const AWNING_Z := 1.15
const AWNING_Y := 2.5
const AWNING_LEN := 1.72
const AWNING_SLOPE := 0.27     # rad

const GLOW_COLOR := Color(1.0, 0.8, 0.4)
const COAL_COLOR := Color(1.0, 0.5, 0.16)
const RIM_IDLE := Color(0.55, 0.65, 0.85)
const RIM_SELECTED := Color(1.0, 0.8, 0.4)

# Palette (neutral: no kingdom colour). Canvas saffron = the gold / ochre of trade (minimap post mark).
const C_STONE := Color(0.46, 0.44, 0.40)
const C_DARK := Color(0.26, 0.25, 0.23)
const C_TIMBER := Color(0.31, 0.21, 0.13)
const C_WOOD := Color(0.52, 0.37, 0.22)
const C_ROOF := Color(0.62, 0.35, 0.22)
const C_CANVAS := Color(0.88, 0.81, 0.66)
const C_SAFFRON := Color(0.82, 0.52, 0.15)
const C_IRON := Color(0.21, 0.21, 0.23)
const C_GOLD := Color(0.93, 0.71, 0.27)
const C_CREAM := Color(0.92, 0.87, 0.74)
const C_FIELD := Color(0.13, 0.24, 0.27)
const C_BURLAP := Color(0.60, 0.50, 0.34)
const C_CLAY := Color(0.66, 0.38, 0.23)
const C_MOSS := Color(0.31, 0.41, 0.17)

static var _mesh_cache: Dictionary = {}
static var _tex_cache: Dictionary = {}

## Which emblem hangs on the sign: 0 heron (Heron Ford), 1 millstone (Millstone Cross), 2 lantern (Lantern Wharf),
## 3 gate (Saltgate). Clamped to 0..3. Same as set_sign().
@export_range(0, 3) var sign_index: int = 0:
	set(value):
		sign_index = clampi(value, 0, SIGN_COUNT - 1)
		_apply_sign()

var _body: Node3D
var _painted: Array[ShaderMaterial] = []
var _glows: Array[ShaderMaterial] = []
var _m: Dictionary = {}   # name -> ShaderMaterial
var _g_lantern: ShaderMaterial
var _g_coals: ShaderMaterial
var _sign_head: Node3D
var _sign: Node3D
var _signs: Array[MeshInstance3D] = []
var _pennant: MeshInstance3D
var _lantern: Node3D
var _halo: MeshInstance3D
var _shutter: Node3D
var _awning: Node3D
var _flames: GPUParticles3D
var _pools: Array[MeshInstance3D] = []
var _lantern_basis: Basis
var _head_basis_src: Basis = Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)
var _head_flip: float = 1.0
## G-B neutral (Ultra only): the brazier's and the lantern's warm lights (null at Low).
var _fire_light: NeutralFlickerLight
var _lamp_light: NeutralFlickerLight

var _t: float = 0.0
var _ready_done: bool = false
var _open: bool = true
var _open_k: float = 1.0
var _selected: bool = false
var _sel_k: float = 0.0
var _pulse: float = 0.0
var _held: bool = false
var _held_color: Color = Color(0.85, 0.30, 0.12)
var _held_k: float = 0.0


func _ready() -> void:
	_ready_done = true
	_t = randf() * 10.0
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	_make_materials()
	_build_structure()
	_build_shutter()
	_build_awning()
	_build_sign_head()
	_build_lantern()
	_build_brazier_fire()
	_build_ground()
	NeutralBuildingLook.set_detail_all(_painted)
	_fire_light = NeutralBuildingLook.add_light(_body, "BrazierLight", BRAZIER + Vector3(0, Y_PLINTH + 1.45, 0),
		Color(1.0, 0.58, 0.24), 1.6, 5.5, 0.32, 1.4)
	_lamp_light = NeutralBuildingLook.add_light(_lantern, "LanternLight", Vector3(0, -0.45, 0), Color(1.0, 0.74, 0.40),
		0.9, 4.0, 0.15, 1.0)
	_open_k = 1.0 if _open else 0.0
	_sel_k = 1.0 if _selected else 0.0
	_held_k = 1.0 if _held else 0.0
	_apply_sign()
	_apply_open()
	_apply_held()
	_apply_rim_and_glow()
	_align_head()


func _process(delta: float) -> void:
	_t += delta
	_align_head()
	# Sign sways on its rings, the lantern on its bracket (different rhythms); play_trade swings them harder.
	var kick: float = sin(_pulse * PI * 3.0) * _pulse
	# Negative x rotation swings the bottom toward local +Z (the camera side when the head is not flipped).
	_sign.rotation.x = -(SIGN_TILT + sin(_t * 1.2) * 0.05 + sin(_t * 0.43) * 0.025 + kick * 0.22) * _head_flip
	_lantern.basis = _lantern_basis * Basis(Vector3.RIGHT, sin(_t * 1.6 + 1.1) * 0.08 + kick * 0.15) \
		* Basis(Vector3.FORWARD, sin(_t * 1.05) * 0.05)
	var open_target: float = 1.0 if _open else 0.0
	if _open_k != open_target:
		_open_k = move_toward(_open_k, open_target, delta / 0.9)
		_apply_open()
	var held_target: float = 1.0 if _held else 0.0
	if _held_k != held_target:
		_held_k = move_toward(_held_k, held_target, delta / 0.5)
		_apply_held()
	var sel_target: float = 1.0 if _selected else 0.0
	var dirty: bool = false
	if _sel_k != sel_target:
		_sel_k = move_toward(_sel_k, sel_target, delta / (0.15 if _selected else 0.25))
		dirty = true
	if _pulse > 0.0:
		_pulse = maxf(_pulse - delta / 0.9, 0.0)
		dirty = true
	if dirty:
		_apply_rim_and_glow()


# --- Hooks ---

## The root yaw that turns the front (local +Z) from `center` toward `door` (both world positions).
## Heron Ford (-53, 1) -> (-49, 1): +90 degrees; Millstone Cross (-1, 53) -> (-1, 49): 180 degrees.
static func yaw_for_door(center: Vector3, door: Vector3) -> float:
	return atan2(door.x - center.x, door.z - center.z)


## The sign emblem of a post id (market-trade.md 2.2): heron_ford 0, millstone_cross 1, lantern_wharf 2, saltgate 3
## (unknown ids: 0).
static func sign_for_post(post_id: StringName) -> int:
	return int(POST_SIGNS.get(post_id, 0))


## Same as setting sign_index (0-3, clamped).
func set_sign(i: int) -> void:
	sign_index = i


func get_sign() -> int:
	return sign_index


## World position of the door anchor (where caravans trade): local (0, 0, DOOR_DISTANCE).
func get_door_point() -> Vector3:
	var p := Vector3(0.0, 0.0, DOOR_DISTANCE)
	return to_global(p) if is_inside_tree() else transform * p


## World direction the front faces (the root's +Z).
func get_door_direction() -> Vector3:
	return ((global_transform.basis if is_inside_tree() else basis) * Vector3.BACK).normalized()


## Closed (before 4:00): shutter down, awning rolled, brazier cold, lantern dim. Open: trading. Default open.
func set_open(open: bool) -> void:
	_open = open


func is_open() -> bool:
	return _open


## `holder` = the holding team's colour (the pennant rises on the mast), or null (the pennant is lowered).
func set_held(holder: Variant) -> void:
	if holder is Color:
		_held = true
		_held_color = holder
		if _pennant:
			_pennant.set_instance_shader_parameter(&"team_color", _held_color)
	else:
		_held = false


func is_held() -> bool:
	return _held


func set_selected(on: bool) -> void:
	_selected = on


## A caravan traded here: the sign swings, the lantern flares (0.9 s). Safe to retrigger.
func play_trade() -> void:
	_pulse = 1.0


## The trading post is neutral: team colours are ignored (kept so generic building code can call it).
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


func _make_materials() -> void:
	var stone: ShaderMaterial = _paint("stone", C_STONE, 1, 0.8, 0.5)
	stone.set_shader_parameter(&"course_height", 0.3)
	stone.set_shader_parameter(&"block_length", 0.7)
	var dark: ShaderMaterial = _paint("dark", C_DARK, 1, 0.45, 0.25)
	dark.set_shader_parameter(&"course_height", 0.24)
	dark.set_shader_parameter(&"block_length", 0.9)
	_paint("timber", C_TIMBER)
	_paint("wood", C_WOOD, 5)
	var roof: ShaderMaterial = _paint("roof", C_ROOF, 3, 0.35)
	roof.set_shader_parameter(&"course_height", 0.17)
	roof.set_shader_parameter(&"moss_cut", 0.72)
	var canvas: ShaderMaterial = _paint("canvas", C_CANVAS, 4)
	canvas.set_shader_parameter(&"stripe_color", C_SAFFRON)
	canvas.set_shader_parameter(&"stripe_width", 0.36)
	_paint("iron", C_IRON, 0, 0.0, 0.0, 0.4)
	_paint("gold", C_GOLD, 0, 0.0, 0.0, 0.55)
	_paint("cream", C_CREAM)
	_paint("egold", C_GOLD, 0, 0.0, 0.0, 0.5).set_shader_parameter(&"self_lit", 0.22)
	_paint("ecream", C_CREAM).set_shader_parameter(&"self_lit", 0.2)
	_paint("field", C_FIELD)
	_paint("burlap", C_BURLAP)
	_paint("clay", C_CLAY, 0, 0.0, 0.0, 0.15)
	_g_lantern = _glow(GLOW_COLOR, 3.4, 2.6)
	_g_coals = _glow(COAL_COLOR, 2.2, 4.0)


# --- Mesh helpers (cached, shared by every post) ---

static func _box(size: Vector3) -> Mesh:
	var key: String = "b%s" % size
	if not _mesh_cache.has(key):
		var m := BoxMesh.new()
		m.size = size
		_mesh_cache[key] = m
	return _mesh_cache[key]


## B4 (in-game grade 2026-10-12): rings 0 (no mid ring), `caps` 0 none / 1 top only / 2 both (bottom caps of
## upright parts face the ground and are never seen from the RTS camera).
static func _cyl(top_r: float, bot_r: float, h: float, segs: int, caps: int = 2) -> Mesh:
	var key: String = "c%.3f_%.3f_%.3f_%d_%d" % [top_r, bot_r, h, segs, caps]
	if not _mesh_cache.has(key):
		var m := CylinderMesh.new()
		m.top_radius = top_r
		m.bottom_radius = bot_r
		m.height = h
		m.radial_segments = segs
		m.rings = 0
		m.cap_top = top_r > 0.0 and caps >= 1
		m.cap_bottom = bot_r > 0.0 and caps >= 2
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


static func _torus(inner: float, outer: float, rings: int = 8, ring_segs: int = 4) -> Mesh:
	var key: String = "t%.3f_%.3f_%d_%d" % [inner, outer, rings, ring_segs]
	if not _mesh_cache.has(key):
		var m := TorusMesh.new()
		m.inner_radius = inner
		m.outer_radius = outer
		m.rings = rings
		m.ring_segments = ring_segs
		_mesh_cache[key] = m
	return _mesh_cache[key]


## B4 (in-game grade 2026-10-12): a box without its bottom face (20 verts instead of 24); _it / _itx swap every
## upright box (local Y up) to it, the RTS camera never sees a downward face.
static func _box_open(size: Vector3) -> Mesh:
	var key: String = "bo%s" % size
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var h: Vector3 = size * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces: Array[Vector3] = [Vector3.UP, Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]
	for n: Vector3 in faces:
		var u: Vector3 = Vector3.FORWARD if absf(n.y) > 0.5 else Vector3.UP
		var v: Vector3 = n.cross(u)
		var c: Vector3 = n * h
		var du: Vector3 = u * h
		var dv: Vector3 = v * h
		var p := [c - du - dv, c + du - dv, c + du + dv, c - du + dv]
		_tri(st, p[0], p[1], p[2], n)
		_tri(st, p[0], p[2], p[3], n)
	st.index()
	var m: ArrayMesh = st.commit()
	_mesh_cache[key] = m
	return m


## Flat cards facing local +Z (emblem relief, scallops): a w x h quad, a unit disc / annulus fan, a triangle with its
## apex up (the PrismMesh outline). 4 / segs+1 / 2*segs / 3 verts.
static func _flat_mesh(kind: String, a: float, b: float, segs: int = 8) -> Mesh:
	var key: String = "f%s_%.3f_%.3f_%d" % [kind, a, b, segs]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := Vector3.BACK
	match kind:
		"card":
			var p := [Vector3(-a, -b, 0) * 0.5, Vector3(a, -b, 0) * 0.5, Vector3(a, b, 0) * 0.5, Vector3(-a, b, 0) * 0.5]
			_tri(st, p[0], p[1], p[2], n)
			_tri(st, p[0], p[2], p[3], n)
		"tri":
			_tri(st, Vector3(-a * 0.5, -b * 0.5, 0), Vector3(a * 0.5, -b * 0.5, 0), Vector3(0, b * 0.5, 0), n)
		"disc", "ring":
			for i: int in segs:
				var t0: float = TAU * i / segs
				var t1: float = TAU * (i + 1) / segs
				var o0 := Vector3(cos(t0), sin(t0), 0) * b
				var o1 := Vector3(cos(t1), sin(t1), 0) * b
				if kind == "disc":
					_tri(st, Vector3.ZERO, o0, o1, n)
				else:
					var i0: Vector3 = o0 * (a / b)
					var i1: Vector3 = o1 * (a / b)
					_tri(st, i0, o0, o1, n)
					_tri(st, i0, o1, i1, n)
	st.index()
	var m: ArrayMesh = st.commit()
	_mesh_cache[key] = m
	return m


## A convex polygon (points (x, z)) extruded from y0 to y1: flat-shaded sides + top cap, indexed.
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
	st.index()
	var m: ArrayMesh = st.commit()
	_mesh_cache[key] = m
	return m


## Hipped roof slab: eave rectangle x in [-ex, ex], z in [ez0, ez1] at height ye, ridge from (-rx, yr, zr) to
## (rx, yr, zr), `thick` metres thick (underside parallel), with closed eave edges. Indexed.
static func _hip_roof(ex: float, ez0: float, ez1: float, ye: float, rx: float, yr: float, zr: float,
		thick: float) -> Mesh:
	var key: String = "hip%.3f_%.3f_%.3f_%.3f_%.3f_%.3f_%.3f_%.3f" % [ex, ez0, ez1, ye, rx, yr, zr, thick]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var d := Vector3(0.0, -thick, 0.0)
	var c0 := Vector3(-ex, ye, ez1)
	var c1 := Vector3(ex, ye, ez1)
	var c2 := Vector3(ex, ye, ez0)
	var c3 := Vector3(-ex, ye, ez0)
	var r0 := Vector3(-rx, yr, zr)
	var r1 := Vector3(rx, yr, zr)
	for s: int in 2:   # 0 = top (normals out / up), 1 = underside (normals down / in)
		var o: Vector3 = d if s == 1 else Vector3.ZERO
		var sg: float = -1.0 if s == 1 else 1.0
		_tri(st, c0 + o, c1 + o, r1 + o, Vector3(0, 1, 1) * sg)
		_tri(st, c0 + o, r1 + o, r0 + o, Vector3(0, 1, 1) * sg)
		_tri(st, c2 + o, c3 + o, r0 + o, Vector3(0, 1, -1) * sg)
		_tri(st, c2 + o, r0 + o, r1 + o, Vector3(0, 1, -1) * sg)
		_tri(st, c1 + o, c2 + o, r1 + o, Vector3(1, 1, 0) * sg)
		_tri(st, c3 + o, c0 + o, r0 + o, Vector3(-1, 1, 0) * sg)
	# Eave edges.
	var corners: Array[Vector3] = [c0, c1, c2, c3]
	for i: int in 4:
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % 4]
		var out := Vector3((a.x + b.x) * 0.5, 0.0, (a.z + b.z) * 0.5 - (ez0 + ez1) * 0.5)
		_tri(st, a, b, b + d, out)
		_tri(st, a, b + d, a + d, out)
	st.index()
	var m: ArrayMesh = st.commit()
	_mesh_cache[key] = m
	return m


## Adds a triangle facing `n` (Godot front faces wind clockwise seen from the front).
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	var fn: Vector3 = (b - a).cross(c - a)
	if fn.dot(n) > 0.0:
		var tmp: Vector3 = b
		b = c
		c = tmp
	var nn: Vector3 = -(b - a).cross(c - a).normalized()
	for v: Vector3 in [a, b, c]:
		st.set_normal(nn)
		st.set_uv(Vector2(v.x + v.z, v.y))
		st.add_vertex(v)


# --- Item helpers (BuildingMerge items: [mesh, xf, material]) ---

func _it(mesh: Mesh, pos: Vector3, mat: String, rot_deg: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> Array:
	if mesh is BoxMesh and absf(rot_deg.x) < 8.0 and absf(rot_deg.z) < 8.0:
		mesh = _box_open((mesh as BoxMesh).size)
	return BMG.item(mesh, pos, _mat(mat), rot_deg, scale)


func _itx(mesh: Mesh, xf: Transform3D, mat: String) -> Array:
	if mesh is BoxMesh and xf.basis.y.normalized().y > 0.99:
		mesh = _box_open((mesh as BoxMesh).size)
	return BMG.item_xf(mesh, xf, _mat(mat))


func _mat(nm: String) -> Material:
	match nm:
		"lantern":
			return _g_lantern
		"coals":
			return _g_coals
	return _m[nm]


## A beam (box of section `w` x `w`) from `a` to `b`.
func _beam(a: Vector3, b: Vector3, w: float, mat: String, extra: float = 0.0) -> Array:
	var e: Vector3 = b - a
	var bs := Basis(Quaternion(Vector3.UP, e.normalized()))
	return _itx(_box(Vector3(w, e.length() + extra, w)), Transform3D(bs, (a + b) * 0.5), mat)


## A flat bar (section `w` wide x `d` deep, depth along local z) from `a` to `b` in a plane facing +Z.
func _bar(a: Vector3, b: Vector3, w: float, d: float, mat: String) -> Array:
	var e: Vector3 = b - a
	var ang: float = atan2(e.y, e.x)
	return _itx(_box(Vector3(e.length() + w * 0.5, w, d)), Transform3D(Basis(Vector3.BACK, ang), (a + b) * 0.5), mat)


## A round rod (radius `r`) from `a` to `b`.
func _rod(a: Vector3, b: Vector3, r: float, mat: String, extra: float = 0.0, segs: int = 8, caps: int = 2) -> Array:
	var e: Vector3 = b - a
	var bs := Basis(Quaternion(Vector3.UP, e.normalized()))
	return _itx(_cyl(r, r, snappedf(e.length() + extra, 0.01), segs, caps), Transform3D(bs, (a + b) * 0.5), mat)


func _merge(nm: String, key: String, items: Array, parent: Node3D, ao_height: float = HEIGHT) -> MeshInstance3D:
	var mi: MeshInstance3D = BMG.instance(nm, "%s/%s" % [KEY, key], items)
	parent.add_child(mi)
	mi.set_instance_shader_parameter(&"ao_bottom", 0.0)
	mi.set_instance_shader_parameter(&"ao_height", ao_height)
	return mi


# --- Structure ---
# Body space: front +Z. Levels: plinth 0-0.24, deck 0.24-0.3, posts to 2.78, plates to 3.02, roof 35 degrees (eave
# ~2.5 m, ridge ~4.1 m, ridge cap ~4.4 m), mast to 6.1 m.

func _build_structure() -> void:
	var it: Array = []
	_add_plinth(it)
	_add_frame(it)
	_add_roof(it)
	_add_counter(it)
	_add_goods(it)
	_add_mast(it)
	_add_side_props(it)
	_add_brazier(it)
	_merge("Structure", "structure", it, _body)


func _add_plinth(it: Array) -> void:
	# Low dark stone platform with chamfered corners, a plank deck under the hall, flagstones in the forecourt.
	var c: float = 2.92
	var k: float = 0.35
	var plinth := PackedVector2Array([Vector2(-c + k, -c), Vector2(c - k, -c), Vector2(c, -c + k), Vector2(c, c - k),
		Vector2(c - k, c), Vector2(-c + k, c), Vector2(-c, c - k), Vector2(-c, -c + k)])
	it.append(_itx(_poly_prism(plinth, 0.0, Y_PLINTH), Transform3D.IDENTITY, "dark"))
	it.append(_it(_box(Vector3(HALL_X * 2.0 + 0.35, 0.07, HALL_Z1 - HALL_Z0 + 0.35)),
		Vector3(0, Y_PLINTH + 0.035, (HALL_Z0 + HALL_Z1) * 0.5), "wood"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7311
	for row: int in 2:
		var z: float = 1.52 + row * 0.66
		var x: float = -2.62
		while x < 2.2:
			var w: float = rng.randf_range(0.62, 0.95)
			if x + w > 2.75:
				w = 2.75 - x
			if w > 0.3:
				# B4: flagstones are top cards (their 7 cm sides do not read from the RTS camera).
				var fp := Vector3(x + w * 0.5, Y_PLINTH + 0.055 + rng.randf() * 0.02, z)
				var fb := Basis(Vector3.UP, deg_to_rad(rng.randf_range(-3.0, 3.0))) * Basis(Vector3.RIGHT, -PI * 0.5)
				it.append(_itx(_flat_mesh("card", w - 0.07, 0.58), Transform3D(fb, fp), "stone"))
			x += w
	# Front edge: a worn step along the forecourt.
	it.append(_it(_box(Vector3(3.2, 0.12, 0.42)), Vector3(-0.1, 0.06, 3.02), "dark"))


func _add_frame(it: Array) -> void:
	var h: float = Y_PLATE - Y_PLINTH - 0.07
	var yc: float = Y_PLINTH + 0.07 + h * 0.5
	var posts: Array[Vector2] = [Vector2(-HALL_X, HALL_Z0), Vector2(HALL_X, HALL_Z0), Vector2(-HALL_X, HALL_Z1),
		Vector2(HALL_X, HALL_Z1), Vector2(0.0, HALL_Z0)]
	for p: Vector2 in posts:
		it.append(_it(_box(Vector3(0.5, 0.14, 0.5)), Vector3(p.x, Y_PLINTH + 0.07, p.y), "dark"))
		it.append(_it(_box(Vector3(0.3, h, 0.3)), Vector3(p.x, yc, p.y), "timber"))
	# Wall plates (the roof sits on them) with end-grain overhangs.
	var yp: float = (Y_PLATE + Y_PLATE_TOP) * 0.5
	var ph: float = Y_PLATE_TOP - Y_PLATE
	for z: float in [HALL_Z0, HALL_Z1]:
		it.append(_it(_box(Vector3(HALL_X * 2.0 + 0.7, ph, 0.3)), Vector3(0, yp, z), "timber"))
	for x: float in [-HALL_X, HALL_X]:
		it.append(_it(_box(Vector3(0.28, ph - 0.02, HALL_Z1 - HALL_Z0 + 0.6)), Vector3(x, yp - 0.01, (HALL_Z0 + HALL_Z1) * 0.5),
			"timber"))
	# Tie beam across the middle.
	it.append(_it(_box(Vector3(HALL_X * 2.0, 0.2, 0.22)), Vector3(0, Y_PLATE - 0.1, (HALL_Z0 + HALL_Z1) * 0.5), "timber"))
	# Knee braces at every corner post, both directions.
	for p: Vector2 in posts.slice(0, 4):
		var sx: float = -signf(p.x)
		var sz: float = 1.0 if p.y < 0.0 else -1.0
		it.append(_beam(Vector3(p.x, Y_PLATE - 0.72, p.y), Vector3(p.x + sx * 0.65, Y_PLATE - 0.04, p.y), 0.13, "timber"))
		it.append(_beam(Vector3(p.x, Y_PLATE - 0.72, p.y), Vector3(p.x, Y_PLATE - 0.04, p.y + sz * 0.65), 0.13, "timber"))
	# Back wall: vertical planks between the back posts, a sill and a head rail.
	var wall_h: float = Y_PLATE - Y_PLINTH - 0.07
	it.append(_it(_box(Vector3(HALL_X * 2.0, wall_h, 0.1)), Vector3(0, Y_PLINTH + 0.07 + wall_h * 0.5, HALL_Z0 - 0.08),
		"wood"))
	it.append(_it(_box(Vector3(HALL_X * 2.0, 0.14, 0.18)), Vector3(0, 1.45, HALL_Z0 - 0.08), "timber"))
	# Open sides: a rail and a kick board between the corner posts.
	for x: float in [-HALL_X, HALL_X]:
		it.append(_it(_box(Vector3(0.14, 0.12, HALL_Z1 - HALL_Z0)), Vector3(x, 1.0, (HALL_Z0 + HALL_Z1) * 0.5), "timber"))
		it.append(_it(_box(Vector3(0.08, 0.34, HALL_Z1 - HALL_Z0)), Vector3(x, Y_PLINTH + 0.24, (HALL_Z0 + HALL_Z1) * 0.5),
			"wood"))
		for z: float in [-1.45, -0.3]:
			it.append(_it(_box(Vector3(0.1, 0.62, 0.1)), Vector3(x, 0.7, z), "timber"))


func _add_roof(it: Array) -> void:
	var slope: float = tan(deg_to_rad(ROOF_DEG))
	var half_d: float = (HALL_Z1 - HALL_Z0) * 0.5
	var zr: float = (HALL_Z0 + HALL_Z1) * 0.5
	var yr: float = Y_PLATE_TOP + half_d * slope
	var ye: float = Y_PLATE_TOP - EAVE * slope
	var ex: float = HALL_X + EAVE
	var rx: float = HALL_X - half_d
	var ez0: float = HALL_Z0 - EAVE
	var ez1: float = HALL_Z1 + EAVE
	it.append(_itx(_hip_roof(ex, ez0, ez1, ye + ROOF_THICK, rx, yr + ROOF_THICK, zr, ROOF_THICK), Transform3D.IDENTITY,
		"roof"))
	# Ridge roll and hip rolls (clay), ridge end knobs.
	var top: float = yr + ROOF_THICK + 0.05
	it.append(_it(_cyl(0.13, 0.13, rx * 2.0 + 0.3, 8), Vector3(0, top, zr), "roof", Vector3(0, 0, 90)))
	for sx: float in [-1.0, 1.0]:
		it.append(_it(_sphere(0.17, 6, 3), Vector3(sx * (rx + 0.15), top + 0.03, zr), "roof"))
		for ez: float in [ez0, ez1]:
			it.append(_rod(Vector3(sx * rx, top - 0.02, zr), Vector3(sx * ex, ye + ROOF_THICK + 0.04, ez), 0.08, "roof", 0.05, 6, 1))
	# Fascia boards along the eaves (dark line under the tiles) and rafter tails front and back.
	var fy: float = ye + ROOF_THICK * 0.5 - 0.06
	it.append(_it(_box(Vector3(ex * 2.0 + 0.1, 0.2, 0.08)), Vector3(0, fy, ez1 + 0.03), "timber"))
	it.append(_it(_box(Vector3(ex * 2.0 + 0.1, 0.2, 0.08)), Vector3(0, fy, ez0 - 0.03), "timber"))
	for sx2: float in [-1.0, 1.0]:
		it.append(_it(_box(Vector3(0.08, 0.2, ez1 - ez0 + 0.1)), Vector3(sx2 * (ex + 0.03), fy, zr), "timber"))
	# B4 (in-game grade 2026-10-12): the rafter tails sat under the roof slab, never seen from the RTS camera: removed.


func _add_counter(it: Array) -> void:
	# Trading counter in the front opening: plank top, plank front, two brackets.
	var z: float = HALL_Z1 + 0.02
	var w: float = HALL_X * 2.0 - 0.32
	it.append(_it(_box(Vector3(w, 0.1, 0.62)), Vector3(0, 1.02, z + 0.02), "wood"))
	it.append(_it(_box(Vector3(w, 0.72, 0.08)), Vector3(0, Y_PLINTH + 0.07 + 0.36, z + 0.28), "wood"))
	it.append(_it(_box(Vector3(w + 0.1, 0.1, 0.12)), Vector3(0, 0.96, z + 0.32), "timber"))
	for x: float in [-1.2, 0.0, 1.2]:
		it.append(_beam(Vector3(x, 0.62, z + 0.32), Vector3(x, 0.96, z + 0.12), 0.08, "timber"))
	# Goods on the counter: bolts of striped cloth, a small strongbox, a jar, a coin tray.
	for i: int in 3:
		it.append(_it(_cyl(0.12, 0.12, 0.58, 6), Vector3(-1.2 + i * 0.05, 1.19 + i * 0.2, z - 0.05 + (i % 2) * 0.1),
			"canvas", Vector3(0, 0, 90)))
	it.append(_it(_box(Vector3(0.5, 0.3, 0.36)), Vector3(0.35, 1.22, z - 0.02), "wood", Vector3(0, -12, 0)))
	it.append(_it(_box(Vector3(0.54, 0.07, 0.4)), Vector3(0.35, 1.38, z - 0.02), "iron", Vector3(0, -12, 0)))
	it.append(_it(_box(Vector3(0.12, 0.14, 0.05)), Vector3(0.37, 1.24, z + 0.17), "gold", Vector3(0, -12, 0)))
	it.append(_it(_sphere(0.17, 6, 4), Vector3(1.15, 1.22, z), "clay", Vector3.ZERO, Vector3(1, 1.25, 1)))
	it.append(_it(_cyl(0.07, 0.1, 0.12, 6, 1), Vector3(1.15, 1.46, z), "clay"))
	it.append(_it(_cyl(0.2, 0.2, 0.05, 8, 1), Vector3(-0.45, 1.1, z + 0.05), "gold"))


func _barrel(it: Array, xf: Transform3D) -> void:
	# B4: 7 sides, the two halves share their hidden waist (no caps there), open hoops, no separate lid.
	it.append(_itx(_cyl(0.34, 0.28, 0.42, 7, 2), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0.21, 0)), "wood"))
	it.append(_itx(_cyl(0.28, 0.34, 0.42, 7, 1), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0.63, 0)), "wood"))
	for y: float in [0.13, 0.71]:
		it.append(_itx(_cyl(0.315, 0.315, 0.07, 7, 0), xf * Transform3D(Basis.IDENTITY, Vector3(0, y, 0)), "iron"))


func _crate(it: Array, pos: Vector3, s: float, yaw: float) -> void:
	it.append(_it(_box(Vector3(s, s, s)), pos + Vector3(0, s * 0.5, 0), "wood", Vector3(0, yaw, 0)))
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	# B4: one dark band near the lid (the foot band hid in the crate's own contact shade).
	it.append(_itx(_box(Vector3(s + 0.04, 0.07, s + 0.04)), Transform3D(b, pos + Vector3(0, s - 0.08, 0)), "timber"))


func _sack(it: Array, pos: Vector3, s: float, yaw: float) -> void:
	it.append(_it(_sphere(0.3 * s, 6, 4), pos + Vector3(0, 0.2 * s, 0), "burlap", Vector3(0, yaw, 8), Vector3(1.0, 0.85, 0.8)))
	it.append(_it(_cyl(0.05 * s, 0.1 * s, 0.14 * s, 5, 1), pos + Vector3(0, 0.46 * s, 0), "burlap", Vector3(0, yaw, 0)))


func _add_goods(it: Array) -> void:
	var y: float = Y_PLINTH + 0.07
	# Back-left: crates stacked two high; back-right: barrels; sacks and clay jars along the left side.
	_crate(it, Vector3(-1.45, y, -1.75), 0.62, 6.0)
	_crate(it, Vector3(-0.8, y, -1.8), 0.56, -9.0)
	_crate(it, Vector3(-1.2, y + 0.62, -1.78), 0.5, 20.0)
	_barrel(it, Transform3D(Basis(Vector3.UP, 0.4), Vector3(1.45, y, -1.75)))
	_barrel(it, Transform3D(Basis(Vector3.UP, 1.9), Vector3(0.8, y, -1.85)))
	_barrel(it, Transform3D(Basis(Vector3.RIGHT, PI * 0.5).scaled(Vector3.ONE * 0.75), Vector3(1.5, y + 0.25, -0.9)))
	_sack(it, Vector3(-1.6, y, -0.75), 1.1, 10.0)
	_sack(it, Vector3(-1.55, y, -0.2), 1.0, -30.0)
	_sack(it, Vector3(-1.55, y + 0.36, -0.5), 0.9, 60.0)
	for p: Vector3 in [Vector3(0.9, y, -0.2), Vector3(1.3, y, 0.1)]:
		it.append(_it(_sphere(0.22, 6, 4), p + Vector3(0, 0.3, 0), "clay", Vector3.ZERO, Vector3(1, 1.3, 1)))
		it.append(_it(_cyl(0.08, 0.13, 0.16, 6, 1), p + Vector3(0, 0.62, 0), "clay"))
	# Bolts of cloth on a rack along the back wall.
	it.append(_it(_box(Vector3(1.1, 0.08, 0.36)), Vector3(0.1, 1.72, HALL_Z0 + 0.14), "timber"))
	for i: int in 3:
		it.append(_it(_cyl(0.1, 0.1, 0.9, 6), Vector3(0.1, 1.86 + (i % 2) * 0.18, HALL_Z0 + 0.1 + i * 0.07), "canvas",
			Vector3(0, 0, 90)))


func _add_mast(it: Array) -> void:
	# Stone foot, tall pole (tapered), iron bands, gilded finial; a fingerpost pair; the lantern bracket (toward +Z).
	var m: Vector3 = MAST
	it.append(_it(_box(Vector3(0.66, 0.42, 0.66)), m + Vector3(0, 0.21, 0), "stone", Vector3(0, 8, 0)))
	it.append(_it(_box(Vector3(0.5, 0.12, 0.5)), m + Vector3(0, 0.47, 0), "dark", Vector3(0, 8, 0)))
	var h: float = MAST_TOP - 0.53 - 0.2
	it.append(_it(_cyl(0.12, 0.17, h, 8, 0), m + Vector3(0, 0.53 + h * 0.5, 0), "timber"))
	for y: float in [1.25, 2.9, 4.75]:
		it.append(_it(_cyl(0.185, 0.185, 0.09, 8, 1), m + Vector3(0, y, 0), "iron"))
	it.append(_it(_cyl(0.05, 0.13, 0.14, 8, 0), m + Vector3(0, MAST_TOP - 0.13, 0), "iron"))
	it.append(_it(_sphere(0.15, 8, 4), m + Vector3(0, MAST_TOP + 0.02, 0), "gold"))
	it.append(_it(_cyl(0.0, 0.05, 0.28, 6, 0), m + Vector3(0, MAST_TOP + 0.28, 0), "gold"))
	# Fingerposts: two arrow boards above head height (one toward the road, one along it); they stick out of the
	# footprint only above 2.5 m.
	for f: Array in [[2.64, -90.0, 0.95], [2.98, 0.0, 0.85]]:
		var b := Basis(Vector3.UP, deg_to_rad(float(f[1])))
		var len: float = float(f[2])
		it.append(_itx(_box(Vector3(len, 0.26, 0.06)), Transform3D(b, m + Vector3(0, float(f[0]), 0) + b * Vector3(len * 0.5 + 0.1, 0, 0)),
			"wood"))
		it.append(_itx(_prism(Vector3(0.3, 0.26, 0.06)),
			Transform3D(b * Basis(Vector3.BACK, -PI * 0.5), m + Vector3(0, float(f[0]), 0) + b * Vector3(len + 0.24, 0, 0)), "cream"))
	# Lantern bracket: arm toward +Z, a diagonal strut and a curl.
	var ly: float = LANTERN_Y + 0.42
	it.append(_beam(m + Vector3(0, ly, 0.1), m + Vector3(0, ly, 0.85), 0.08, "iron"))
	it.append(_beam(m + Vector3(0, ly - 0.5, 0.12), m + Vector3(0, ly, 0.55), 0.06, "iron"))
	it.append(_itx(_torus(0.07, 0.12), Transform3D(Basis(Vector3.BACK, PI * 0.5), m + Vector3(0, ly + 0.13, 0.4)), "iron"))


func _add_side_props(it: Array) -> void:
	var y: float = Y_PLINTH
	# Hitching rail + water trough on the +X side (under the eave).
	var x: float = 2.62
	for z: float in [-1.95, 0.55]:
		it.append(_it(_box(Vector3(0.16, 1.05, 0.16)), Vector3(x, y + 0.52, z), "timber"))
		it.append(_it(_box(Vector3(0.22, 0.06, 0.22)), Vector3(x, y + 1.07, z), "timber"))
	it.append(_it(_cyl(0.06, 0.06, 2.75, 6), Vector3(x, y + 0.95, -0.7), "wood", Vector3(90, 0, 0)))
	for z2: float in [-1.2, -0.2]:
		it.append(_itx(_torus(0.04, 0.08, 6, 3), Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(x, y + 0.86, z2)), "iron"))
	it.append(_it(_box(Vector3(0.52, 0.42, 1.5)), Vector3(x - 0.02, y + 0.21, -0.72), "wood"))
	it.append(_it(_box(Vector3(0.4, 0.04, 1.38)), Vector3(x - 0.02, y + 0.37, -0.72), "iron"))
	# Crates and a sack by the mast, a cart wheel leaning on the back wall.
	_crate(it, Vector3(1.55, y + 0.02, 2.0), 0.55, 14.0)
	_crate(it, Vector3(1.6, y + 0.57, 2.02), 0.42, -8.0)
	_sack(it, Vector3(2.25, y, 1.55), 1.0, 40.0)
	var wb := Basis(Vector3.UP, 0.12) * Basis(Vector3.RIGHT, 0.28)
	var wc := Vector3(-1.05, y + 0.6, HALL_Z0 - 0.42)
	it.append(_itx(_torus(0.47, 0.58, 12), Transform3D(wb * Basis(Vector3.RIGHT, PI * 0.5), wc), "timber"))
	it.append(_itx(_cyl(0.1, 0.1, 0.22, 6), Transform3D(wb * Basis(Vector3.RIGHT, PI * 0.5), wc), "iron"))
	for k: int in 4:   # B4: 8 spokes (was 12)
		var a: float = k * PI / 4.0
		it.append(_itx(_box(Vector3(0.05, 0.94, 0.05)), Transform3D(wb * Basis(Vector3.BACK, a), wc), "wood"))


func _add_brazier(it: Array) -> void:
	# Iron bowl on three legs at the front-left corner (coals + flames are separate nodes).
	var b: Vector3 = BRAZIER + Vector3(0, Y_PLINTH, 0)
	for k: int in 3:
		var a: float = k * TAU / 3.0 + 0.3
		var foot := b + Vector3(cos(a) * 0.36, 0.0, sin(a) * 0.36)
		var top := b + Vector3(cos(a) * 0.2, 0.7, sin(a) * 0.2)
		it.append(_rod(foot, top, 0.035, "iron", 0.02, 5, 0))
	it.append(_it(_cyl(0.36, 0.2, 0.24, 8, 1), b + Vector3(0, 0.8, 0), "iron"))
	it.append(_it(_torus(0.33, 0.41, 10), b + Vector3(0, 0.92, 0), "iron"))
	it.append(_it(_cyl(0.3, 0.3, 0.06, 8, 1), b + Vector3(0, 0.02, 0), "dark"))


# --- Moving parts ---

func _build_shutter() -> void:
	# Hinged plank shutter over the counter: hangs down when closed, folds up and in under the roof when open.
	_shutter = Node3D.new()
	_shutter.name = "ShutterPivot"
	_shutter.position = Vector3(0, Y_PLATE - 0.02, HALL_Z1 + 0.2)
	_body.add_child(_shutter)
	var it: Array = []
	var w: float = HALL_X * 2.0 - 0.34
	var h: float = Y_PLATE - 1.1
	it.append(_it(_box(Vector3(w, h, 0.07)), Vector3(0, -h * 0.5, 0), "wood"))
	for y: float in [-0.25, -h + 0.25]:
		it.append(_it(_box(Vector3(w, 0.12, 0.1)), Vector3(0, y, 0.03), "timber"))
	it.append(_it(_box(Vector3(0.1, h - 0.4, 0.1)), Vector3(0, -h * 0.5, 0.03), "timber", Vector3(0, 0, 58)))
	for x: float in [-1.3, 1.3]:
		it.append(_it(_box(Vector3(0.3, 0.06, 0.12)), Vector3(x, -0.1, 0.04), "iron"))
	_merge("Shutter", "shutter", it, _shutter)


func _build_awning() -> void:
	# Striped canvas awning over the forecourt, from under the front eave down toward the road. Its pivot scales along
	# the slope to roll it up (closed). Poles and the roll stay.
	var cx: float = (AWNING_X0 + AWNING_X1) * 0.5
	var w: float = AWNING_X1 - AWNING_X0
	var fixed: Array = []
	fixed.append(_it(_cyl(0.11, 0.11, w + 0.1, 7), Vector3(cx, AWNING_Y + 0.06, AWNING_Z), "canvas", Vector3(0, 0, 90)))
	fixed.append(_it(_box(Vector3(w + 0.2, 0.14, 0.12)), Vector3(cx, AWNING_Y + 0.14, AWNING_Z - 0.12), "timber"))
	var front_z: float = AWNING_Z + AWNING_LEN * cos(AWNING_SLOPE)
	var front_y: float = AWNING_Y - AWNING_LEN * sin(AWNING_SLOPE)
	for x: float in [AWNING_X0 + 0.12, AWNING_X1 - 0.12]:
		fixed.append(_it(_cyl(0.05, 0.06, front_y - Y_PLINTH + 0.1, 6, 0), Vector3(x, (front_y + Y_PLINTH + 0.1) * 0.5, front_z - 0.04),
			"timber"))
		fixed.append(_it(_sphere(0.07, 6, 3), Vector3(x, front_y + 0.13, front_z - 0.04), "gold"))
		fixed.append(_it(_cyl(0.1, 0.12, 0.1, 6, 1), Vector3(x, Y_PLINTH + 0.05, front_z - 0.04), "dark"))
	_merge("AwningFrame", "awning_frame", fixed, _body)
	_awning = Node3D.new()
	_awning.name = "AwningPivot"
	_awning.position = Vector3(cx, AWNING_Y, AWNING_Z)
	_awning.rotation.x = AWNING_SLOPE
	_body.add_child(_awning)
	var it: Array = []
	it.append(_it(_box(Vector3(w, 0.04, AWNING_LEN)), Vector3(0, 0, AWNING_LEN * 0.5), "canvas"))
	# Valance: a hanging striped flap with a scalloped edge (small half-discs).
	var vz: float = AWNING_LEN
	it.append(_itx(_box(Vector3(w, 0.24, 0.04)), Transform3D(Basis(Vector3.RIGHT, -AWNING_SLOPE), Vector3(0, -0.11, vz)),
		"canvas"))
	var n: int = int(w / 0.36)
	for i: int in n:
		var x2: float = -w * 0.5 + (i + 0.5) * w / float(n)
		# B4: flat disc cards (the camera only sees their front).
		it.append(_itx(_flat_mesh("disc", 0.0, 0.14, 8), Transform3D(Basis(Vector3.RIGHT, -AWNING_SLOPE),
			Vector3(x2, -0.24, vz + 0.04)), "canvas"))
	# Front bar the canvas is laced to.
	it.append(_it(_cyl(0.045, 0.045, w + 0.12, 6), Vector3(0, 0.0, vz), "timber", Vector3(0, 0, 90)))
	var mi: MeshInstance3D = _merge("Awning", "awning", it, _awning)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _build_sign_head() -> void:
	# World-aligned head at the crossarm: the arm, an iron tie rod from the mast top, the hanging sign (4 emblems, one
	# visible) and the holder's pennant flying on the other side.
	_sign_head = Node3D.new()
	_sign_head.name = "SignHead"
	_sign_head.position = MAST + Vector3(0, ARM_Y, 0)
	_body.add_child(_sign_head)
	var it: Array = []
	it.append(_beam(Vector3(0.05, 0, 0), Vector3(ARM_LEN, 0, 0), 0.15, "timber"))
	it.append(_it(_box(Vector3(0.1, 0.19, 0.19)), Vector3(ARM_LEN, 0, 0), "iron"))
	it.append(_beam(Vector3(0.1, MAST_TOP - ARM_Y - 0.35, 0), Vector3(ARM_LEN - 0.2, 0.05, 0), 0.05, "iron"))
	it.append(_it(_box(Vector3(0.36, 0.12, 0.2)), Vector3(0.12, -0.1, 0), "iron"))
	for x: float in [SIGN_X - 0.7, SIGN_X + 0.7]:
		it.append(_itx(_torus(0.04, 0.08), Transform3D(Basis(Vector3.UP, PI * 0.5) * Basis(Vector3.RIGHT, PI * 0.5),
			Vector3(x, -0.1, 0)), "iron"))
	_merge("Arm", "arm", it, _sign_head)
	_sign = Node3D.new()
	_sign.name = "SignPivot"
	_sign.position = Vector3(SIGN_X, -0.12, 0)
	_sign_head.add_child(_sign)
	for i: int in SIGN_COUNT:
		var items: Array = _sign_board_items()
		_emblem_items(i, items)
		var mi: MeshInstance3D = _merge("Sign%d" % i, "sign_%d" % i, items, _sign, 1.5)
		mi.set_instance_shader_parameter(&"ao_bottom", -2.5)
		mi.set_instance_shader_parameter(&"ao_height", 2.5)
		_signs.append(mi)
	# Pennant (hidden until a team holds the post): flies toward -X from the mast top.
	_pennant = MeshInstance3D.new()
	_pennant.name = "Pennant"
	var q := PlaneMesh.new()
	q.size = Vector2(1.05, 0.58)
	q.orientation = PlaneMesh.FACE_Z
	q.subdivide_width = 8
	q.subdivide_depth = 2
	_pennant.mesh = q
	var pm := ShaderMaterial.new()
	pm.shader = PENNANT
	_pennant.material_override = pm
	_pennant.rotation.y = PI
	_pennant.position = Vector3(-0.525 - 0.13, MAST_TOP - ARM_Y - 0.5, 0)
	_pennant.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pennant.set_instance_shader_parameter(&"team_color", _held_color)
	_sign_head.add_child(_pennant)


## The board (both faces): dark teal field in a timber frame, iron top band and hanging straps.
func _sign_board_items() -> Array:
	var it: Array = []
	var cy: float = -0.14 - SIGN_H * 0.5
	it.append(_it(_box(Vector3(SIGN_W - 0.1, SIGN_H - 0.1, 0.08)), Vector3(0, cy, 0), "field"))
	for s: float in [-1.0, 1.0]:
		it.append(_it(_box(Vector3(SIGN_W, 0.1, 0.13)), Vector3(0, cy + s * (SIGN_H * 0.5 - 0.05), 0), "timber"))
		it.append(_it(_box(Vector3(0.1, SIGN_H, 0.13)), Vector3(s * (SIGN_W * 0.5 - 0.05), cy, 0), "timber"))
		it.append(_it(_box(Vector3(0.05, 0.2, 0.05)), Vector3(s * 0.7, -0.06, 0), "iron"))
		# B4: the 5 cm gilded corner studs (invisible at RTS range) are gone.
	it.append(_it(_box(Vector3(SIGN_W + 0.06, 0.07, 0.16)), Vector3(0, cy + SIGN_H * 0.5 + 0.02, 0), "iron"))
	return it


## Emblem `i` in relief on both faces of the board (the back one is the front turned 180 degrees). Emblem space:
## x -0.7..0.7, y -0.5..0.5 around the board centre, relief standing 0.05 m proud.
func _emblem_items(i: int, it: Array) -> void:
	var parts: Array = []   # [mesh, Transform3D in emblem space (z = 0 on the field face), mat]
	match i:
		0:
			_emblem_heron(parts)
		1:
			_emblem_millstone(parts)
		2:
			_emblem_lantern(parts)
		_:
			_emblem_gate(parts)
	var cy: float = -0.14 - SIGN_H * 0.5
	var grow := Transform3D(Basis.from_scale(Vector3(EMBLEM_SCALE, EMBLEM_SCALE, 1.0)), Vector3.ZERO)
	for face: int in 2:
		var fb := Basis(Vector3.UP, PI * face)
		var base := Transform3D(fb, Vector3(0, cy, 0)) * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.04)) * grow
		for p: Array in parts:
			# The emblem's gold and cream are slightly self-lit versions (readable in shade and from afar).
			var mn: String = p[2]
			if mn == "gold":
				mn = "egold"
			elif mn == "cream":
				mn = "ecream"
			var flat: Array = _flatten(p[0], p[1])
			it.append(_itx(flat[0], base * (flat[1] as Transform3D), mn))


## B4 (in-game grade 2026-10-12): the emblem relief stands 5-7 cm proud, invisible at RTS range; each part becomes a
## flat card on its front plane (box -> quad, sphere -> disc, prism -> triangle, upright cylinder -> quad), same outline
## and colour, ~1/6 of the vertices. Other meshes (already flat) pass through.
func _flatten(mesh: Mesh, xf: Transform3D) -> Array:
	if mesh is BoxMesh:
		var s: Vector3 = (mesh as BoxMesh).size
		return [_flat_mesh("card", s.x, s.y), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, s.z * 0.5))]
	if mesh is SphereMesh:
		var r: float = (mesh as SphereMesh).radius
		return [_flat_mesh("disc", 0.0, r, 10 if r > 0.5 else 6), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, r))]
	if mesh is PrismMesh:
		var ps: Vector3 = (mesh as PrismMesh).size
		return [_flat_mesh("tri", ps.x, ps.y), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, ps.z * 0.5))]
	if mesh is CylinderMesh:
		var c := mesh as CylinderMesh
		return [_flat_mesh("card", c.bottom_radius * 2.0, c.height), xf * Transform3D(Basis.IDENTITY,
			Vector3(0, 0, c.bottom_radius))]
	return [mesh, xf]


func _ep(parts: Array, mesh: Mesh, pos: Vector2, mat: String, rot_z_deg: float = 0.0, scale: Vector3 = Vector3.ONE,
		depth: float = 0.05) -> void:
	var b := Basis(Vector3.BACK, deg_to_rad(rot_z_deg)).scaled_local(scale)
	parts.append([mesh, Transform3D(b, Vector3(pos.x, pos.y, depth * 0.5)), mat])


## A flat bar from `a` to `b` (emblem space), `w` wide.
func _eb(parts: Array, a: Vector2, b: Vector2, w: float, mat: String, depth: float = 0.05) -> void:
	var e: Vector2 = b - a
	var ang: float = atan2(e.y, e.x)
	parts.append([_box(Vector3(e.length() + w * 0.6, w, depth)),
		Transform3D(Basis(Vector3.BACK, ang), Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, depth * 0.5)), mat])


func _emblem_heron(p: Array) -> void:
	# A standing heron facing left among reeds, over a line of water.
	_ep(p, _sphere(1.0, 12, 6), Vector2(0.1, -0.02), "cream", -16.0, Vector3(0.3, 0.16, 0.05))
	_ep(p, _sphere(1.0, 12, 6), Vector2(0.18, 0.0), "gold", -20.0, Vector3(0.21, 0.09, 0.07))
	_eb(p, Vector2(0.3, -0.07), Vector2(0.44, -0.15), 0.1, "cream")
	_eb(p, Vector2(-0.1, 0.06), Vector2(-0.17, 0.22), 0.09, "cream")
	_eb(p, Vector2(-0.17, 0.22), Vector2(-0.08, 0.34), 0.08, "cream")
	_eb(p, Vector2(-0.08, 0.34), Vector2(-0.14, 0.43), 0.08, "cream")
	_ep(p, _sphere(0.075, 10, 5), Vector2(-0.15, 0.45), "cream", 0.0, Vector3(1.2, 1.0, 0.7))
	_eb(p, Vector2(-0.2, 0.44), Vector2(-0.47, 0.39), 0.045, "gold")
	_eb(p, Vector2(-0.1, 0.49), Vector2(0.06, 0.53), 0.03, "gold")
	_eb(p, Vector2(0.08, -0.14), Vector2(0.06, -0.44), 0.035, "gold")
	_eb(p, Vector2(0.15, -0.14), Vector2(0.22, -0.3), 0.035, "gold")
	_eb(p, Vector2(0.22, -0.3), Vector2(0.14, -0.44), 0.035, "gold")
	_eb(p, Vector2(-0.6, -0.45), Vector2(0.62, -0.45), 0.04, "gold")
	for r: Array in [[0.46, 0.12], [0.55, 0.22], [0.63, 0.05]]:
		_eb(p, Vector2(float(r[0]), -0.44), Vector2(float(r[0]) - 0.02, float(r[1])), 0.025, "gold")
		_ep(p, _cyl(0.03, 0.03, 0.12, 6), Vector2(float(r[0]) - 0.02, float(r[1]) + 0.02), "cream", 0.0, Vector3.ONE,
			0.06)


func _emblem_millstone(p: Array) -> void:
	# A millstone seen face-on: pale stone disc, gilded rim, square eye with a rynd, six harp furrows; grain corners.
	p.append([_flat_mesh("disc", 0.0, 0.4, 16), Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.05)), "cream"])
	p.append([_flat_mesh("ring", 0.36, 0.44, 16), Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.08)), "gold"])
	_ep(p, _box(Vector3(0.14, 0.14, 0.06)), Vector2.ZERO, "field", 45.0, Vector3.ONE, 0.07)
	_eb(p, Vector2(-0.15, 0.0), Vector2(0.15, 0.0), 0.05, "gold", 0.075)
	for k: int in 6:
		var a: float = k * TAU / 6.0
		var c := Vector2(cos(a), sin(a)) * 0.24
		var t := Vector2(-sin(a), cos(a))
		_eb(p, c - t * 0.1 - Vector2(cos(a), sin(a)) * 0.04, c + t * 0.1 + Vector2(cos(a), sin(a)) * 0.04, 0.035, "field",
			0.065)
	for s: Vector2 in [Vector2(-0.58, 0.4), Vector2(0.58, 0.4), Vector2(-0.58, -0.4), Vector2(0.58, -0.4)]:
		_ep(p, _sphere(0.06, 8, 4), s, "gold", 45.0 * signf(s.x * s.y), Vector3(1.6, 0.8, 0.8))


func _emblem_lantern(p: Array) -> void:
	# A wharf lantern: ring, pointed cap, glass body in a gilded frame, flame, base, light rays, two wave lines.
	p.append([_flat_mesh("ring", 0.05, 0.09, 8), Transform3D(Basis.IDENTITY, Vector3(0, 0.44, 0.06)), "gold"])
	_ep(p, _prism(Vector3(0.44, 0.17, 0.05)), Vector2(0, 0.3), "gold")
	_ep(p, _box(Vector3(0.32, 0.4, 0.04)), Vector2(0, 0.02), "cream")
	for x: float in [-0.18, 0.18]:
		_ep(p, _box(Vector3(0.05, 0.46, 0.06)), Vector2(x, 0.02), "gold")
	_ep(p, _box(Vector3(0.46, 0.05, 0.06)), Vector2(0, 0.23), "gold")
	_ep(p, _box(Vector3(0.46, 0.05, 0.06)), Vector2(0, -0.19), "gold")
	_ep(p, _sphere(1.0, 10, 5), Vector2(0, 0.0), "gold", 0.0, Vector3(0.06, 0.11, 0.06))
	_ep(p, _box(Vector3(0.3, 0.07, 0.05)), Vector2(0, -0.25), "gold")
	_ep(p, _prism(Vector3(0.12, 0.1, 0.05)), Vector2(0, -0.33), "gold", 180.0)
	for a_deg: float in [10.0, 35.0, -15.0, 170.0, 145.0, 195.0]:
		var a: float = deg_to_rad(a_deg)
		var d := Vector2(cos(a), sin(a))
		_eb(p, d * 0.32 + Vector2(0, 0.02), d * 0.5 + Vector2(0, 0.02), 0.04, "gold")
	for row: int in 2:
		var y: float = -0.4 - row * 0.08
		for k: int in 4:
			var x0: float = -0.55 + k * 0.3 + row * 0.1
			_eb(p, Vector2(x0, y), Vector2(x0 + 0.13, y + 0.035), 0.03, "cream")
			_eb(p, Vector2(x0 + 0.13, y + 0.035), Vector2(x0 + 0.26, y), 0.03, "cream")


func _emblem_gate(p: Array) -> void:
	# A town gate: two crenellated towers, an arched opening with a gilded portcullis, a road line, tower flags.
	for s: float in [-1.0, 1.0]:
		_ep(p, _box(Vector3(0.24, 0.68, 0.05)), Vector2(s * 0.36, -0.08), "cream")
		for c: float in [-0.07, 0.07]:
			_ep(p, _box(Vector3(0.08, 0.09, 0.05)), Vector2(s * 0.36 + c, 0.3), "cream")
		_eb(p, Vector2(s * 0.36, 0.34), Vector2(s * 0.36, 0.5), 0.025, "gold")
		_ep(p, _prism(Vector3(0.12, 0.1, 0.04)), Vector2(s * 0.36 + 0.07, 0.46), "gold", -90.0)
		_ep(p, _box(Vector3(0.07, 0.12, 0.06)), Vector2(s * 0.36, 0.05), "field", 0.0, Vector3.ONE, 0.06)
	_ep(p, _box(Vector3(0.5, 0.14, 0.05)), Vector2(0, 0.17), "cream")
	for k: int in 5:
		var a: float = PI * float(k) / 4.0
		_ep(p, _box(Vector3(0.09, 0.08, 0.05)), Vector2(cos(a) * 0.19, 0.02 + sin(a) * 0.19 * 0.7), "cream", rad_to_deg(a) + 90.0)
	for x: float in [-0.1, 0.0, 0.1]:
		_eb(p, Vector2(x, -0.4), Vector2(x, 0.02), 0.035, "gold")
	for y: float in [-0.12, -0.28]:
		_eb(p, Vector2(-0.14, y), Vector2(0.14, y), 0.03, "gold")
	_eb(p, Vector2(-0.6, -0.44), Vector2(0.6, -0.44), 0.04, "gold")


func _build_lantern() -> void:
	# The lantern hangs at the bracket tip over the trading spot: iron cap, glowing glass, corner bars, base, halo.
	_lantern = Node3D.new()
	_lantern.name = "LanternPivot"
	_lantern_basis = Basis.IDENTITY
	_lantern.position = MAST + Vector3(0, LANTERN_Y + 0.38, 0.78)
	_body.add_child(_lantern)
	var it: Array = []
	it.append(_it(_torus(0.03, 0.07), Vector3(0, -0.05, 0), "iron", Vector3(90, 0, 0)))
	it.append(_it(_cyl(0.02, 0.24, 0.16, 4), Vector3(0, -0.16, 0), "iron", Vector3(0, 45, 0)))
	it.append(_it(_box(Vector3(0.27, 0.36, 0.27)), Vector3(0, -0.44, 0), "lantern"))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(_it(_box(Vector3(0.05, 0.4, 0.05)), Vector3(c.x * 0.145, -0.44, c.y * 0.145), "iron"))
	it.append(_it(_box(Vector3(0.34, 0.06, 0.34)), Vector3(0, -0.25, 0), "iron"))
	it.append(_it(_box(Vector3(0.32, 0.07, 0.32)), Vector3(0, -0.65, 0), "iron"))
	it.append(_it(_cyl(0.11, 0.0, 0.12, 4), Vector3(0, -0.74, 0), "iron", Vector3(0, 45, 0)))
	var mi: MeshInstance3D = _merge("Lantern", "lantern", it, _lantern)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo = MeshInstance3D.new()
	_halo.name = "Halo"
	var q := QuadMesh.new()
	q.size = Vector2(1.6, 1.6)
	_halo.mesh = q
	_halo.material_override = _soft_mat("halo", Color(1.0, 0.78, 0.4, 0.55), true, true)
	_halo.position = Vector3(0, -0.44, 0)
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lantern.add_child(_halo)


func _build_brazier_fire() -> void:
	var b: Vector3 = BRAZIER + Vector3(0, Y_PLINTH, 0)
	var coals := MeshInstance3D.new()
	coals.name = "Coals"
	coals.mesh = _sphere(0.28, 8, 4)
	coals.scale = Vector3(1.0, 0.32, 1.0)
	coals.position = b + Vector3(0, 0.9, 0)
	coals.material_override = _g_coals
	coals.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(coals)
	# Small flames: a few additive billboards rising and shrinking (30 fps, 10 particles).
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.85, 0.45, 0.0))
	g.set_color(1, Color(0.9, 0.25, 0.05, 0.0))
	g.add_point(0.15, Color(1.0, 0.75, 0.3, 0.75))
	g.add_point(0.6, Color(1.0, 0.42, 0.1, 0.4))
	var ramp := GradientTexture1D.new()
	ramp.gradient = g
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 0.7
	pm.initial_velocity_max = 1.1
	pm.gravity = Vector3(0, 0.4, 0)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.16
	pm.scale_min = 0.8
	pm.scale_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.2))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	pm.color_ramp = ramp
	var q := QuadMesh.new()
	q.size = Vector2(0.3, 0.42)
	var qm: StandardMaterial3D = _soft_mat("flame", Color(1, 1, 1, 1), true, false).duplicate() as StandardMaterial3D
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.vertex_color_use_as_albedo = true
	q.material = qm
	_flames = GPUParticles3D.new()
	_flames.name = "Flames"
	_flames.amount = 8
	_flames.lifetime = 0.6
	_flames.fixed_fps = 30
	_flames.interpolate = true
	_flames.local_coords = false
	_flames.process_material = pm
	_flames.draw_pass_1 = q
	_flames.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flames.visibility_aabb = AABB(Vector3(-1, -0.5, -1), Vector3(2, 2.5, 2))
	_flames.position = b + Vector3(0, 0.98, 0)
	_body.add_child(_flames)


# --- Ground contact, fake light pools ---

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
	_body.add_child(mi)
	return mi


func _build_ground() -> void:
	# Contact decal (art-keep.md 0.5), a trodden yard between the forecourt and the door point (the road ends there),
	# warm light pools under the lantern and around the brazier, mossy rubble around the platform.
	# MAP.P2: the ContactDecal is a trodden-earth apron with a baked contact shadow along the platform, its tongue
	# running to the road (shared mesh + material, art/environment/neutral/site_ground.gd; symmetric in X so the
	# mast mirror does not change it). The old unshaded soft blob stays as the fallback.
	if ResourceLoader.exists(SITE_GROUND):
		(load(SITE_GROUND) as Script).call(&"add", _body, "ContactDecal", Vector2(2.62, 2.62), 0.3, 2.1, Vector3(0, 0, 1), 2.4, 2)
	else:
		_flat("ContactDecal", Vector2(8.4, 8.4), Vector3(0, 0.03, 0), _soft_mat("contact", Color(0.05, 0.035, 0.02, 0.6), false, false))
	_flat("YardDecal", Vector2(5.2, 4.2), Vector3(0.1, 0.035, 3.7), _soft_mat("yard", Color(0.34, 0.25, 0.15, 0.62), false, false))
	var pool: StandardMaterial3D = _soft_mat("pool", Color(1.0, 0.7, 0.32, 0.3), true, false)
	_pools.append(_flat("LightPoolLantern", Vector2(4.0, 4.0), MAST + Vector3(0, 0.3, 0.9), pool))
	_pools.append(_flat("LightPoolBrazier", Vector2(2.8, 2.8), BRAZIER + Vector3(0, 0.3, 0), pool))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5171
	var xf: Array[Transform3D] = []
	for i: int in 10:
		var a: float = PI * 0.35 + (TAU - PI * 0.7) * (float(i) + rng.randf_range(0.0, 0.6)) / 10.0
		var r: float = rng.randf_range(3.1, 3.4)
		var s: float = rng.randf_range(0.28, 0.46)
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, deg_to_rad(rng.randf_range(8.0, 22.0)))
		# a runs around the back and the sides (the front arc, toward +Z, stays clear for the road).
		xf.append(Transform3D(b.scaled(Vector3(s, s * 0.55, s * 0.8)), Vector3(sin(a) * r, s * 0.08, cos(a) * r)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _sphere(0.5, 6, 2)
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


# --- State ---

## Re-run whenever the post's world rotation changes:
## - mirrors the Body along local X when that puts the mast corner further from the default camera (world -Z), so the
##   mast and its sign rise above the roof outline instead of hiding in it (door, footprint and hooks unchanged);
## - keeps the sign head's board facing world +Z (the default camera) with the arm pointing away from the building.
func _align_head() -> void:
	if not _ready_done or not is_inside_tree():
		return
	var gb: Basis = global_transform.basis
	if gb.is_equal_approx(_head_basis_src):
		return
	_head_basis_src = gb
	var right_z: float = (gb * MAST).z
	var left_z: float = (gb * Vector3(-MAST.x, MAST.y, MAST.z)).z
	var mirror: float = -1.0 if left_z < right_z - 0.1 else 1.0
	_body.scale = Vector3(mirror, 1.0, 1.0)
	var off: Vector3 = gb * Vector3(MAST.x * mirror, MAST.y, MAST.z)
	var yaw: float = 0.0 if off.x >= 0.0 else PI
	_head_flip = 1.0 if yaw == 0.0 else -1.0
	var sc: Vector3 = gb.get_scale()
	_sign_head.global_basis = Basis(Vector3.UP, yaw).scaled(sc)


func _apply_sign() -> void:
	if not _ready_done:
		return
	for i: int in _signs.size():
		_signs[i].visible = i == sign_index


func _apply_open() -> void:
	var k: float = _open_k
	var e: float = ease(k, -2.0)
	_shutter.rotation.x = deg_to_rad(84.0) * e
	_awning.scale = Vector3(1.0, 1.0, lerpf(0.05, 1.0, e))
	_awning.visible = k > 0.02
	_g_coals.set_shader_parameter(&"energy", lerpf(0.12, 2.2, k))
	_g_coals.set_shader_parameter(&"glow_color", COAL_COLOR.lerp(Color(0.35, 0.12, 0.06), 1.0 - k))
	_flames.emitting = k > 0.5
	_halo.visible = k > 0.05
	if _fire_light:
		_fire_light.set_level(k)
	if _lamp_light:
		_lamp_light.set_level(lerpf(0.15, 1.0, k))
	for p: MeshInstance3D in _pools:
		p.visible = k > 0.05
		p.transparency = 1.0 - k
	_apply_rim_and_glow()


func _apply_held() -> void:
	if not _ready_done:
		return
	var k: float = ease(_held_k, -2.0)
	_pennant.visible = _held_k > 0.01
	_pennant.scale = Vector3(maxf(k, 0.01), maxf(k, 0.01), 1.0)


func _apply_rim_and_glow() -> void:
	if not _ready_done:
		return
	var rim_col: Color = RIM_IDLE.lerp(RIM_SELECTED, _sel_k)
	var rim_str: float = lerpf(0.22, 0.85, _sel_k)
	for m: ShaderMaterial in _painted:
		m.set_shader_parameter(&"rim_color", rim_col)
		m.set_shader_parameter(&"rim_strength", rim_str)
	var boost: float = lerpf(1.0, 1.35, _sel_k)
	_g_coals.set_shader_parameter(&"boost", boost)
	var flare: float = sin(_pulse * PI) * _pulse * 1.6
	if _lamp_light and _pulse > 0.0:
		_lamp_light.flash(flare)
	_g_lantern.set_shader_parameter(&"boost", boost + flare)
	_g_lantern.set_shader_parameter(&"energy", lerpf(0.35, 3.4, _open_k))
