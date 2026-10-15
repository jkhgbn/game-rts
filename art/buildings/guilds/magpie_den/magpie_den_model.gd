class_name MagpieDenModel
extends Node3D
## Magpie Den, the Thieves' Guild house (task 10.V8, docs/design/market-trade.md sections 2.3, 5, 9, 12).
## Built in code at _ready; meshes baked once and shared by both Dens (BuildingMerge), materials per instance
## (selection rim, glow boost). Read from the RTS camera: a ramshackle hideout squatting in an old ruin. A broken stone
## platform (the ruin's floor) with a stump of a ruined tower and two jagged wall remnants in the back corner; on it a
## narrow, crooked, LEANING tall house (a stone ground floor with a cracked lintel and a boarded-up collapsed corner,
## two black-timbered whitewashed storeys, each leaning a little more over the road), a dark patched shingle roof
## (ridge along X, the magpie gables face +-X), and at the +X gable end a MAST with a barrel crow's-nest lookout, the
## Magpies' black flag (a white feather with a blue-green tip) and on top a big MAGPIE WEATHER-VANE (the dominant
## vertical, it creaks in the wind). Asymmetric secondary: a HOIST DORMER on the front slope whose jib swings a loot sack
## over the road, above stolen crates, a strongbox and spilled gold. Four tattered stolen banners (Fire, Shadow, Ice,
## Nature colours) hang as trophies; black / white shutters. Glow = blue-green only (door lantern, lookout lamp, dim
## window slits and gable roundels): emissive, NO real light.
## The Body is mirrored along X when needed so the mast end is always the gable AWAY from the default RTS camera
## (_update_facing): only there does it break the roof outline in the silhouette test.
##
## Footprint 6 x 6 m (nothing below 2.45 m sticks out more than 0.3 m; eaves / jib up to 1 m); ridge ~6.3 m, crow's
## nest ~7 m, mast top 7.9 m, vane top ~8.7 m. Root origin = footprint centre on the ground. No collision (guild_house.gd owns it).
## Door / rotation: the FRONT (door) is local +Z; the door anchor is local (0, 0, DOOR_DISTANCE) = 1 m outside the
## footprint face, like the spec's door points. The house is square to the root, so the parent only turns it by a
## multiple of 90 degrees: rotation.y = yaw_for_door(centre, door) -> north-west Den (-55, -45) with door (-51, -45):
## +PI/2; south-east Den (55, 45) with door (51, 45): -PI/2.
## Hooks (all safe before _ready): set_open(bool) (closed before 5:00: door shut, lamps dim; default open),
## set_selected(bool) (blue-green rim + glow boost), play_band_out() (a band leaves: door flung open, dust puff,
## lamp flash, the hoist sack jolts), set_team_color(c) (ignored: neutral), get_door_point(), get_door_direction().

const PAINTED: Shader = preload("res://art/buildings/guilds/magpie_den/magpie_den_painted.gdshader")
const CLOTH: Shader = preload("res://art/buildings/guilds/magpie_den/magpie_den_cloth.gdshader")
const GLOW: Shader = preload("res://art/shaders/rune_glow.gdshader")
const NOISE: Texture2D = preload("res://art/shaders/paint_noise.tres")
const BMG := preload("res://art/buildings/fire_hall_merge.gd")

const GLOW_COLOR := Color(0.36, 1.0, 0.84)
const RIM_IDLE := Color(0.55, 0.65, 0.85)
const RIM_SELECTED := Color(0.5, 1.0, 0.88)
const DOOR_DISTANCE := 4.0   # door anchor, metres in front of the centre (root +Z): 1 m outside the 6 x 6 face
const KEY := "res://art/buildings/guilds/magpie_den/magpie_den_model"
const SITE_GROUND := "res://art/environment/neutral/site_ground.gd"
const HEIGHT := 7.0

# Levels (m). Stone ground floor, two timber storeys (each leans / twists a bit more), roof.
const Y_PLINTH := 0.3
const Y_STONE := 1.9
const Y_SILL := 2.06
const Y_F1 := 3.12
const Y_P1 := 3.26
const Y_F2 := 4.12
const Y_P2 := 4.26
const W0 := 2.2      # stone floor half size
const W1 := 2.34     # first storey half size (jettied)
const W2X := 2.44    # second storey half size along the ridge (gables at +-X jettied out)
const W2Z := 2.1     # second storey half size across the ridge
const ROOF_SLOPE_DEG := 36.0
const DOOR_X := 0.1
const DOOR_W := 1.0
const DOOR_H := 1.5
const LANTERN_X := -0.82
const LANTERN_Y := 1.8
const HOIST_X := 0.45    # the hoist dormer on the front roof slope (its jib hangs the loot sack over the road)
const MAST_X := 2.05     # the mast rises at the +X gable end (turned to the far side, see _update_facing)
const DOOR_AJAR_DEG := 42.0
const MAST_TOP := 2.75   # mast length (its frame starts 1 m under the ridge)
const NEST_Y := 1.12     # crow's-nest floor, mast frame
const FLAG_Y := 2.3      # flag centre, mast frame
const FLAG_SIZE := Vector2(1.45, 0.78)
const BIRD_S := 1.35     # vane bird scale
const DORMER_HW := 0.66  # hoist dormer half width
const DORMER_TOP := Y_P2 + 0.78   # top of the dormer front wall
const DOOR_WIDE_DEG := 112.0
const BAND_TIME := 1.7

# Palette: neutral and shady. Magpie black (tarred timber) and white (whitewash), cold ruin stone, a dark slate roof
# with a blue-green cast; the only saturated colours are the stolen banners, the gold loot and the blue-green glow.
const C_STONE := Color(0.45, 0.45, 0.43)
const C_DARK := Color(0.23, 0.23, 0.25)
const C_TAR := Color(0.12, 0.115, 0.125)
const C_WHITE := Color(0.84, 0.83, 0.79)
const C_DAUB := Color(0.6, 0.55, 0.47)
const C_WOOD := Color(0.47, 0.37, 0.26)
const C_ROOF := Color(0.2, 0.24, 0.27)
const C_IRON := Color(0.21, 0.21, 0.23)
const C_GOLD := Color(0.92, 0.70, 0.27)
const C_BURLAP := Color(0.62, 0.52, 0.35)
const C_TEAL := Color(0.1, 0.5, 0.5)
const C_MOSS := Color(0.31, 0.41, 0.17)
# Stolen banners: the four kingdom team colours (art-keep.md 0.2).
const C_FIRE := Color(0.85, 0.30, 0.12)
const C_SHADOW := Color(0.42, 0.22, 0.60)
const C_ICE := Color(0.45, 0.75, 0.95)
const C_NATURE := Color(0.35, 0.70, 0.25)

static var _mesh_cache: Dictionary = {}
static var _tex_cache: Dictionary = {}

var _body: Node3D
var _painted: Array[ShaderMaterial] = []
var _glows: Array[ShaderMaterial] = []
var _m: Dictionary = {}   # name -> Material
var _g_window: ShaderMaterial
var _g_door: ShaderMaterial
var _g_lantern: ShaderMaterial
var _cloth_mat: ShaderMaterial
## B8 material merge (in-game grade 2026-09-30): ONE palette material (BuildingPalette, magpie_den_painted.gdshader's
## palette mode) draws every painted part and every blue-green glow; the per-instance materials above stay the source
## of truth (selection rim, lamps) and are re-read into it (BuildingPalette.refresh) after every change.
var _pal: ShaderMaterial
var _l1: Transform3D      # first storey lean (body space)
var _l12: Transform3D     # second storey + roof lean (body space)
var _mast_xf: Transform3D  # mast frame (local +Y along the mast), body space
var _door: Node3D
var _door_glow: MeshInstance3D
var _lantern: Node3D
var _halo: MeshInstance3D
var _vane: Node3D
var _sack: Node3D
var _pools: Array[MeshInstance3D] = []
var _dust: GPUParticles3D
## G-B neutral (Ultra only): the blue-green door lantern's real light (null at Low).
var _lamp_light: NeutralFlickerLight
var _lantern_basis: Basis
var _vane_basis: Basis

var _t: float = 0.0
var _ready_done: bool = false
var _open: bool = true
var _open_k: float = 1.0
var _selected: bool = false
var _sel_k: float = 0.0
var _band_t: float = -1.0     # < 0 = no band leaving
var _band_pending: bool = false
var _kick: float = 0.0        # hoist sack jolt (decays)


func _ready() -> void:
	_ready_done = true
	_t = randf() * 10.0
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	# The house leans over the road (+Z, sideways on screen from the RTS camera) and twists a little more per storey.
	_l1 = _lean(Vector3(0.0, Y_STONE, 0.0), 1.5, 1.0, 2.6)
	_l12 = _l1 * _lean(Vector3(0.0, Y_P1, 0.0), -4.0, -1.8, 3.4)
	var mast_dir := Vector3(0.1, 1.0, -0.06).normalized()
	_mast_xf = _l12 * Transform3D(Basis(Quaternion(Vector3.UP, mast_dir)), Vector3(MAST_X, _ridge_y() - 1.0, 0.0))
	_make_materials()
	_build_structure()
	_build_cloth()
	_build_door()
	_build_lantern()
	_build_vane()
	_build_sack()
	_build_ground()
	_build_dust()
	_pal = BuildingPalette.create(PAINTED, _m["stone"])
	BuildingPalette.fold_tree(_pal, _body)
	NeutralBuildingLook.set_detail(_pal)
	NeutralBuildingLook.set_detail_all(_painted)
	_lamp_light = NeutralBuildingLook.add_light(_lantern, "LanternLight", Vector3(0, -0.43, 0), GLOW_COLOR, 1.4, 5.5,
		0.25, 0.8)
	_open_k = 1.0 if _open else 0.0
	_sel_k = 1.0 if _selected else 0.0
	set_notify_transform(true)
	_update_facing()
	_apply_open()
	_apply_rim_and_glow()
	if _band_pending:
		_band_pending = false
		play_band_out()


func _process(delta: float) -> void:
	_t += delta
	# Door lantern sways on its bracket; the vane creaks around the mast (slow drift + gusts); the hoist sack swings.
	_lantern.basis = _lantern_basis * Basis(Vector3.RIGHT, sin(_t * 1.6 + 0.7) * 0.08) \
		* Basis(Vector3.FORWARD, sin(_t * 1.05) * 0.05)
	var gust: float = sin(_t * 0.23) * 0.35 + sin(_t * 1.9) * 0.05 * (0.5 + 0.5 * sin(_t * 0.61))
	_vane.basis = _vane_basis * Basis(Vector3.UP, gust)
	_kick = maxf(_kick - delta * 0.7, 0.0)
	var sw: float = 0.05 + _kick * 0.35
	_sack.basis = Basis(Vector3.FORWARD, sin(_t * 1.25) * sw) * Basis(Vector3.RIGHT, sin(_t * 0.9 + 1.3) * sw * 0.6)
	var dirty_door: bool = false
	var open_target: float = 1.0 if _open else 0.0
	if _open_k != open_target:
		_open_k = move_toward(_open_k, open_target, delta / 0.8)
		_apply_open()
		dirty_door = true
	var dirty_glow: bool = false
	if _band_t >= 0.0:
		_band_t += delta
		if _band_t >= BAND_TIME:
			_band_t = -1.0
		dirty_door = true
		dirty_glow = true
	if dirty_door:
		_apply_door()
	var sel_target: float = 1.0 if _selected else 0.0
	if _sel_k != sel_target:
		_sel_k = move_toward(_sel_k, sel_target, delta / (0.15 if _selected else 0.25))
		dirty_glow = true
	if dirty_glow:
		_apply_rim_and_glow()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and _ready_done:
		_update_facing()


## The mast / crow's nest / vane stand at the +X gable end of the Body. From the RTS camera (default yaw, looking
## along world -Z) a tall thing only breaks the roof outline when it stands at the FAR gable, so the Body is mirrored
## along its X axis whenever +X would face the camera. The door (+Z), the footprint and every hook are unchanged;
## both Dens (turned +-90 degrees) look the same from the camera.
func _update_facing() -> void:
	if _body == null or not is_inside_tree():
		return
	var far_local: Vector3 = global_transform.basis.inverse() * Vector3.FORWARD
	var sx: float = 1.0 if far_local.x >= 0.0 else -1.0
	if _body.scale.x != sx:
		_body.scale = Vector3(sx, 1.0, 1.0)


## +1 when the Body is as built, -1 when mirrored (the mast end then points to local -X).
func get_mirror() -> float:
	return _body.scale.x if _body != null else 1.0


# --- Hooks ---

## The root yaw that turns the door (local +Z) from `center` toward `door` (the spec's door point):
## (-55, -45) -> (-51, -45): +PI/2, (55, 45) -> (51, 45): -PI/2. The house then stands square on the grid.
static func yaw_for_door(center: Vector3, door: Vector3) -> float:
	return atan2(door.x - center.x, door.z - center.z)


## World position of the door anchor (band spawn / return point): local (0, 0, DOOR_DISTANCE).
func get_door_point() -> Vector3:
	var p := Vector3(0.0, 0.0, DOOR_DISTANCE)
	return to_global(p) if is_inside_tree() else transform * p


## World direction the door faces (the root's +Z).
func get_door_direction() -> Vector3:
	return ((global_transform.basis if is_inside_tree() else basis) * Vector3.BACK).normalized()


## Closed (before 5:00): door shut, lamps and windows dim, no light pool. Open: door ajar, blue-green glow. Default open.
func set_open(open: bool) -> void:
	_open = open


func is_open() -> bool:
	return _open


func set_selected(on: bool) -> void:
	_selected = on


func is_selected() -> bool:
	return _selected


## A band of Magpies leaves (or comes home): the door is flung wide and swings back, a dust puff rolls out of the
## doorway, the lamps flash and the hoist sack jolts. ~1.7 s, safe to retrigger.
func play_band_out() -> void:
	if not _ready_done:
		_band_pending = true
		return
	_band_t = 0.0
	_kick = 1.0
	_dust.restart()


## The Den is neutral: team colours are ignored (kept so generic building code can call it).
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


func _glow(nm: String, energy: float, pulse_speed: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = GLOW
	m.set_shader_parameter(&"glow_color", GLOW_COLOR)
	m.set_shader_parameter(&"energy", energy)
	m.set_shader_parameter(&"pulse_speed", pulse_speed)
	m.set_shader_parameter(&"rune_bands", 0)
	m.set_shader_parameter(&"phase", randf() * TAU)
	_glows.append(m)
	_m[nm] = m
	return m


func _make_materials() -> void:
	var stone: ShaderMaterial = _paint("stone", C_STONE, 1, 0.9, 0.8)
	stone.set_shader_parameter(&"moss_cut", 0.45)
	var dark: ShaderMaterial = _paint("dark", C_DARK, 1, 0.8, 0.5)
	dark.set_shader_parameter(&"course_height", 0.34)
	dark.set_shader_parameter(&"block_length", 1.05)
	_paint("tar", C_TAR, 0, 0.0, 0.0, 0.12)
	var white: ShaderMaterial = _paint("white", C_WHITE, 4)
	white.set_shader_parameter(&"patch_color", C_DAUB)
	var wood: ShaderMaterial = _paint("wood", C_WOOD, 3, 0.35)
	wood.set_shader_parameter(&"moss_cut", 0.72)
	var roof: ShaderMaterial = _paint("roof", C_ROOF, 2, 0.55)
	roof.set_shader_parameter(&"moss_cut", 0.62)
	roof.set_shader_parameter(&"moss_color", C_MOSS.darkened(0.2))
	roof.set_shader_parameter(&"patch_color", C_WOOD)
	_paint("iron", C_IRON, 0, 0.0, 0.0, 0.4)
	_paint("gold", C_GOLD, 0, 0.0, 0.0, 0.6)
	_paint("burlap", C_BURLAP)
	_paint("teal", C_TEAL, 0, 0.0, 0.0, 0.7)
	_g_window = _glow("window", 1.2, 1.1)
	_g_door = _glow("door_glow", 0.9, 1.7)
	_g_lantern = _glow("lantern", 3.4, 2.6)
	_cloth_mat = ShaderMaterial.new()
	_cloth_mat.shader = CLOTH
	_cloth_mat.set_shader_parameter(&"noise_tex", NOISE)
	_cloth_mat.set_shader_parameter(&"flag_size", FLAG_SIZE)
	_m["cloth"] = _cloth_mat


# --- Mesh helpers (cached, shared by both Dens) ---

static func _box(size: Vector3) -> Mesh:
	var key: String = "b%s" % size
	if not _mesh_cache.has(key):
		var m := BoxMesh.new()
		m.size = size
		_mesh_cache[key] = m
	return _mesh_cache[key]


## B4 pass (in-game grade 2026-09-30, 13.5k -> <= 12k vertices): cylinders at most 8 sides (6 under r 0.2), spheres
## 7 x 4 (6 x 3 under r 0.3), tori 8 x 4 (at 25-40 m the extra facets never show under the paint patterns).
static func _cyl(top_r: float, bot_r: float, h: float, segs: int) -> Mesh:
	segs = mini(segs, 8 if maxf(top_r, bot_r) >= 0.2 else 6)   # rods and posts: 6 sides
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
	segs = mini(segs, 7 if r >= 0.3 else 6)
	rings = mini(rings, 4 if r >= 0.3 else 3)
	var key: String = "s%.3f_%d_%d" % [r, segs, rings]
	if not _mesh_cache.has(key):
		var m := SphereMesh.new()
		m.radius = r
		m.height = r * 2.0
		m.radial_segments = segs
		m.rings = rings
		_mesh_cache[key] = m
	return _mesh_cache[key]


static func _prism(size: Vector3, left: float = 0.5) -> Mesh:
	var key: String = "p%s_%.2f" % [size, left]
	if not _mesh_cache.has(key):
		var m := PrismMesh.new()
		m.size = size
		m.left_to_right = left
		_mesh_cache[key] = m
	return _mesh_cache[key]


static func _torus(inner: float, outer: float, rings: int = 16) -> Mesh:
	rings = mini(rings, 8)
	var key: String = "t%.3f_%.3f_%d" % [inner, outer, rings]
	if not _mesh_cache.has(key):
		var m := TorusMesh.new()
		m.inner_radius = inner
		m.outer_radius = outer
		m.rings = rings
		m.ring_segments = 4
		_mesh_cache[key] = m
	return _mesh_cache[key]


## A cloth strip in its local XY plane, normal +Z, pinned along its top edge (y = 0) and hanging to y = -length.
## UV.x across (0-1), UV.y from the pinned edge (0) to the free edge (1); COLOR = linear cloth colour + kind in alpha
## (see magpie_den_cloth.gdshader). Indexed (BuildingMerge-safe).
static func _cloth_mesh(width: float, length: float, color: Color, kind: float) -> Mesh:
	var key: String = "cloth%.3f_%.3f_%s_%.1f" % [width, length, color, kind]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var sx: int = 4
	var sy: int = maxi(4, int(ceil(length / 0.12)))
	var lin: Color = color.srgb_to_linear()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j: int in sy + 1:
		for i: int in sx + 1:
			var u: float = float(i) / float(sx)
			var v: float = float(j) / float(sy)
			st.set_color(Color(lin.r, lin.g, lin.b, kind))
			st.set_normal(Vector3.BACK)
			st.set_uv(Vector2(u, v))
			st.add_vertex(Vector3((u - 0.5) * width, -v * length, 0.0))
	for j: int in sy:
		for i: int in sx:
			var a: int = j * (sx + 1) + i
			var b: int = a + 1
			var c: int = a + sx + 1
			var d: int = c + 1
			st.add_index(a)
			st.add_index(c)
			st.add_index(b)
			st.add_index(b)
			st.add_index(c)
			st.add_index(d)
	var m: ArrayMesh = st.commit()
	_mesh_cache[key] = m
	return m


# --- Item helpers (BuildingMerge items: [mesh, xf, material]) ---

func _it(mesh: Mesh, pos: Vector3, mat: String, rot_deg: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> Array:
	return BMG.item(mesh, pos, _m[mat], rot_deg, scale)


func _itx(mesh: Mesh, xf: Transform3D, mat: String) -> Array:
	return BMG.item_xf(mesh, xf, _m[mat])


## A beam (box of section `w` x `w`) from `a` to `b`.
func _beam(a: Vector3, b: Vector3, w: float, mat: String, extra: float = 0.0) -> Array:
	var e: Vector3 = b - a
	var bs := Basis(Quaternion(Vector3.UP, e.normalized()))
	return _itx(_box(Vector3(w, snappedf(e.length() + extra, 0.01), w)), Transform3D(bs, (a + b) * 0.5), mat)


## A round rod (radius `r`) from `a` to `b`.
func _rod(a: Vector3, b: Vector3, r: float, mat: String, extra: float = 0.0, segs: int = 8) -> Array:
	var e: Vector3 = b - a
	var bs := Basis(Quaternion(Vector3.UP, e.normalized()))
	return _itx(_cyl(r, r, snappedf(e.length() + extra, 0.01), segs), Transform3D(bs, (a + b) * 0.5), mat)


## Moves the items from index `from` on by `xf` (a lean, a frame...).
static func _xf_items(items: Array, from: int, xf: Transform3D) -> void:
	for i: int in range(from, items.size()):
		var item: Array = items[i]
		item[1] = xf * (item[1] as Transform3D)


## A lean around `pivot`: yaw (deg, around Y), roll (deg, + leans toward -X), pitch (deg, - leans toward -Z).
static func _lean(pivot: Vector3, yaw: float, roll: float, pitch: float) -> Transform3D:
	var b := Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.BACK, deg_to_rad(roll)) \
		* Basis(Vector3.RIGHT, deg_to_rad(pitch))
	return Transform3D(Basis.IDENTITY, pivot) * Transform3D(b, Vector3.ZERO) * Transform3D(Basis.IDENTITY, -pivot)


func _merge(nm: String, key: String, items: Array, parent: Node3D, painted: bool = true) -> MeshInstance3D:
	var mi: MeshInstance3D = BMG.instance(nm, "%s/%s" % [KEY, key], items)
	parent.add_child(mi)
	if painted:
		mi.set_instance_shader_parameter(&"ao_bottom", 0.0)
		mi.set_instance_shader_parameter(&"ao_height", HEIGHT)
	return mi


## Main roof: ridge along local X (the gables face +-X, i.e. the RTS camera once the Den is turned to its road),
## slopes down to the eaves at +-Z.
static func _roof_geo() -> Dictionary:
	var ang: float = deg_to_rad(ROOF_SLOPE_DEG)
	var slope: float = tan(ang)
	var plate_z: float = W2Z + 0.08
	var eave_z: float = W2Z + 0.52
	var eave_y: float = Y_P2 - (eave_z - plate_z) * slope
	var thick: float = 0.3
	var ridge_y: float = eave_y + eave_z * slope + thick / cos(ang)
	return {"ang": ang, "slope": slope, "eave_z": eave_z, "eave_y": eave_y, "thick": thick, "ridge_y": ridge_y,
		"depth": W2X * 2.0 + 0.5}


static func _ridge_y() -> float:
	return float(_roof_geo()["ridge_y"])


# --- Structure (one merged mesh: base, storeys, roof, mast, crane, props) ---

func _build_structure() -> void:
	var it: Array = []
	_add_ruin(it)
	_add_stone_floor(it)
	var f1: int = it.size()
	_add_storey1(it)
	_xf_items(it, f1, _l1)
	var f2: int = it.size()
	_add_storey2(it)
	_add_roof(it)
	_add_hoist(it)
	_xf_items(it, f2, _l12)
	var fm: int = it.size()
	_add_mast(it)
	_xf_items(it, fm, _mast_xf)
	_add_props(it)
	_merge("Structure", "structure", it, _body)


func _add_ruin(it: Array) -> void:
	# The ruin's floor: a broken dark stone platform (chipped corners), a stump of an old tower in the back-left
	# corner (-X-Z) and two jagged wall remnants stepping down from it along the back and left edges.
	it.append(_it(_box(Vector3(5.7, Y_PLINTH, 5.7)), Vector3(0.0, Y_PLINTH * 0.5, 0.0), "dark"))
	for c: Vector3 in [Vector3(2.62, 0.12, 2.1), Vector3(-2.3, 0.1, 2.66), Vector3(2.64, 0.14, -1.2),
			Vector3(0.9, 0.1, 2.65), Vector3(-2.66, 0.12, 0.4)]:
		it.append(_it(_box(Vector3(0.62, 0.3, 0.5)), c, "dark", Vector3(0, c.x * 7.0, 4.0)))
	# Tower stump: square pier with a jagged, mossy broken top.
	var px: float = -2.47
	var pz: float = -2.47
	it.append(_it(_box(Vector3(0.9, 2.6, 0.9)), Vector3(px, Y_PLINTH + 1.3, pz), "stone"))
	it.append(_it(_box(Vector3(1.04, 0.3, 1.04)), Vector3(px, Y_PLINTH + 0.15, pz), "dark"))
	it.append(_it(_box(Vector3(0.5, 0.5, 0.55)), Vector3(px - 0.18, Y_PLINTH + 2.82, pz - 0.1), "stone", Vector3(6, 12, -8)))
	it.append(_it(_box(Vector3(0.42, 0.36, 0.4)), Vector3(px + 0.2, Y_PLINTH + 2.68, pz + 0.2), "stone", Vector3(-10, 30, 6)))
	it.append(_it(_box(Vector3(0.36, 0.72, 0.34)), Vector3(px - 0.24, Y_PLINTH + 3.05, pz + 0.24), "stone", Vector3(4, -8, 9)))
	# Wall remnants: along the back edge (+X from the stump) and the left edge (+Z from the stump), stepping down.
	var backs: Array[float] = [1.45, 1.05, 0.75, 0.45]
	for i: int in backs.size():
		var x: float = px + 0.72 + 0.5 * i
		var h: float = backs[i]
		it.append(_it(_box(Vector3(0.52, h, 0.46)), Vector3(x, Y_PLINTH + h * 0.5, -2.62), "stone", Vector3(0, 0, (i % 2) * 3.0)))
	var lefts: Array[float] = [1.25, 0.85, 0.5]
	for i: int in lefts.size():
		var z: float = pz + 0.72 + 0.5 * i
		var h: float = lefts[i]
		it.append(_it(_box(Vector3(0.46, h, 0.52)), Vector3(-2.62, Y_PLINTH + h * 0.5, z), "stone", Vector3((i % 2) * 3.0, 0, 0)))
	# A fallen column drum by the back wall and a broken capital block.
	it.append(_it(_cyl(0.33, 0.33, 0.9, 10), Vector3(0.55, 0.33, -2.92), "stone", Vector3(0, 0, 90)))
	it.append(_it(_box(Vector3(0.55, 0.4, 0.55)), Vector3(-0.35, Y_PLINTH + 0.2, -2.78), "dark", Vector3(0, 20, 8)))


func _add_stone_floor(it: Array) -> void:
	# Ground floor of the house: ruin stone (walls 0.3-2.0), dark quoins, a cracked sagging lintel over the door,
	# iron-barred glowing slits, and the collapsed front-left corner boarded up with planks.
	var h: float = Y_STONE - Y_PLINTH
	it.append(_it(_box(Vector3(W0 * 2.0, h, W0 * 2.0)), Vector3(0.0, Y_PLINTH + h * 0.5, 0.0), "stone"))
	for c: Vector2 in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		for i: int in 4:
			var y: float = Y_PLINTH + 0.21 + 0.42 * i
			var along_x: bool = i % 2 == 0
			var sx: float = 0.62 if along_x else 0.4
			var sz: float = 0.4 if along_x else 0.62
			if c == Vector2(1, -1) and i == 3:
				continue   # a missing quoin
			it.append(_it(_box(Vector3(sx, 0.38, sz)),
				Vector3(c.x * (W0 - sx * 0.5 + 0.05), y, c.y * (W0 - sz * 0.5 + 0.05)), "dark"))
	# Door: dark stone jambs and a lintel cracked in two (the halves sag into a shallow V).
	var dx0: float = DOOR_X - DOOR_W * 0.5
	var dx1: float = DOOR_X + DOOR_W * 0.5
	for x: float in [dx0 - 0.16, dx1 + 0.16]:
		for k: int in 3:
			var hh: float = 0.52
			it.append(_it(_box(Vector3(0.32 + 0.06 * (k % 2), hh - 0.02, 0.16)),
				Vector3(x, Y_PLINTH + hh * 0.5 + hh * k, W0 + 0.05), "dark"))
	var ly: float = Y_PLINTH + DOOR_H + 0.14
	it.append(_it(_box(Vector3(0.78, 0.28, 0.3)), Vector3(DOOR_X - 0.36, ly + 0.02, W0 + 0.14), "dark", Vector3(0, 0, -4)))
	it.append(_it(_box(Vector3(0.78, 0.28, 0.3)), Vector3(DOOR_X + 0.38, ly + 0.01, W0 + 0.14), "dark", Vector3(0, 0, 5)))
	it.append(_it(_box(Vector3(DOOR_W + 0.1, 0.08, 0.3)), Vector3(DOOR_X, Y_PLINTH + 0.03, W0 + 0.1), "dark"))
	# Barred slits (glow) on the other three faces.
	var slits: Array = [[Basis(Vector3.UP, PI * 0.5), Vector3(W0, 1.2, -0.7)],
		[Basis(Vector3.UP, -PI * 0.5), Vector3(-W0, 1.15, 0.2)],
		[Basis(Vector3.UP, PI), Vector3(1.0, 1.2, -W0)]]
	for s: Array in slits:
		var b: Basis = s[0]
		var p: Vector3 = s[1]
		it.append(_itx(_box(Vector3(0.2, 0.62, 0.06)), Transform3D(b, p + b * Vector3(0, 0, 0.01)), "window"))
		it.append(_itx(_box(Vector3(0.46, 0.14, 0.16)), Transform3D(b, p + b * Vector3(0, -0.38, 0.05)), "dark"))
		it.append(_itx(_box(Vector3(0.44, 0.16, 0.14)), Transform3D(b, p + b * Vector3(0, 0.39, 0.04)), "dark"))
		for bx: float in [-0.05, 0.05]:
			it.append(_itx(_box(Vector3(0.035, 0.66, 0.035)), Transform3D(b, p + b * Vector3(bx, 0, 0.06)), "iron"))
	# Collapsed front-left corner (-X+Z), boarded with planks on both faces; broken stones at the edge.
	it.append(_it(_box(Vector3(1.25, 1.05, 0.08)), Vector3(-W0 + 0.6, 1.47, W0 + 0.04), "wood", Vector3(0, 0, 2)))
	it.append(_it(_box(Vector3(0.08, 1.05, 1.1)), Vector3(-W0 - 0.04, 1.44, W0 - 0.52), "wood", Vector3(-2, 0, 0)))
	it.append(_beam(Vector3(-W0 + 0.05, 1.05, W0 + 0.1), Vector3(-W0 + 1.15, 1.88, W0 + 0.1), 0.1, "tar"))
	it.append(_beam(Vector3(-W0 - 0.1, 1.0, W0 - 0.05), Vector3(-W0 - 0.1, 1.85, W0 - 0.95), 0.1, "tar"))
	for p: Vector3 in [Vector3(-W0 + 1.3, 1.02, W0 + 0.05), Vector3(-W0 + 1.36, 1.3, W0 + 0.04),
			Vector3(-W0 - 0.03, 0.98, W0 - 1.12)]:
		it.append(_it(_box(Vector3(0.36, 0.26, 0.3)), p, "stone", Vector3(8, p.x * 20.0, 10)))
	# Lantern bracket (iron) left of the door.
	it.append(_beam(Vector3(LANTERN_X, LANTERN_Y, W0), Vector3(LANTERN_X, LANTERN_Y, W0 + 0.72), 0.08, "iron"))
	it.append(_beam(Vector3(LANTERN_X, LANTERN_Y - 0.47, W0), Vector3(LANTERN_X, LANTERN_Y, W0 + 0.46), 0.06, "iron"))
	it.append(_it(_sphere(0.06, 8, 4), Vector3(LANTERN_X, LANTERN_Y, W0 + 0.74), "iron"))


func _shutter(it: Array, b: Basis, p: Vector3, w: float, h: float, askew: float) -> void:
	# A magpie shutter: black frame, white panel, black Z-brace. `askew` (rad) = hanging from one hinge.
	var xf := Transform3D(b, p)
	if absf(askew) > 0.001:
		var top := Vector3(0.0, h * 0.5, 0.0)
		xf = xf * Transform3D(Basis.IDENTITY, top) * Transform3D(Basis(Vector3.BACK, askew), -top)
	it.append(_itx(_box(Vector3(w, h, 0.05)), xf, "tar"))
	it.append(_itx(_box(Vector3(w - 0.1, h - 0.1, 0.05)), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.02)), "white"))
	var d := Vector3(w - 0.14, h - 0.14, 0.0)
	var bs := Basis(Quaternion(Vector3.UP, d.normalized()))
	it.append(_itx(_box(Vector3(0.07, d.length(), 0.04)), xf * Transform3D(bs, Vector3(0, 0, 0.05)), "tar"))


## A window on a wall face: `b` local +Z = outward, `centre` on the face. style 0 plain, 1 magpie shutters open,
## 2 one shutter hanging askew, 3 boarded up (two crossed planks, the glow peeks through).
func _window(it: Array, b: Basis, centre: Vector3, w: float, h: float, style: int) -> void:
	var o: Vector3 = centre
	it.append(_itx(_box(Vector3(w, h, 0.06)), Transform3D(b, o + b * Vector3(0, 0, 0.01)), "window"))
	it.append(_itx(_box(Vector3(w + 0.26, 0.12, 0.18)), Transform3D(b, o + b * Vector3(0, -h * 0.5 - 0.06, 0.06)), "tar"))
	it.append(_itx(_box(Vector3(w + 0.2, 0.12, 0.12)), Transform3D(b, o + b * Vector3(0, h * 0.5 + 0.06, 0.04)), "tar"))
	for sx: float in [-1.0, 1.0]:
		it.append(_itx(_box(Vector3(0.1, h, 0.1)), Transform3D(b, o + b * Vector3(sx * (w * 0.5 + 0.05), 0, 0.04)), "tar"))
	if style == 0:
		it.append(_itx(_box(Vector3(0.05, h, 0.05)), Transform3D(b, o + b * Vector3(0, 0, 0.05)), "tar"))
	elif style == 1 or style == 2:
		for sx: float in [-1.0, 1.0]:
			var askew: float = 0.0
			if style == 2 and sx > 0.0:
				askew = -0.42
			_shutter(it, b, o + b * Vector3(sx * (w * 0.75 + 0.12), 0.0, 0.05), w * 0.5 + 0.02, h + 0.04, askew)
	else:
		it.append(_itx(_box(Vector3(w + 0.3, 0.12, 0.05)), Transform3D(b * Basis(Vector3.BACK, 0.55),
			o + b * Vector3(0, 0, 0.07)), "wood"))
		it.append(_itx(_box(Vector3(w + 0.3, 0.12, 0.05)), Transform3D(b * Basis(Vector3.BACK, -0.5),
			o + b * Vector3(0, 0, 0.09)), "wood"))


func _half_timber(it: Array, b: Basis, half_w: float, off: float, y0: float, y1: float, gap: Vector2) -> void:
	# Black studs and "/ \" braces on a whitewashed face. `gap` = (x from, x to) kept free for a window.
	var yc: float = (y0 + y1) * 0.5
	var h: float = y1 - y0
	for x: float in [-half_w * 0.5, half_w * 0.5]:
		if x > gap.x - 0.1 and x < gap.y + 0.1:
			continue
		it.append(_itx(_box(Vector3(0.18, h, 0.08)), Transform3D(b, b * Vector3(x, yc, off)), "tar"))
	for sx: float in [-1.0, 1.0]:
		var a := Vector3(sx * (half_w - 0.12), y0 + 0.06, off)
		var c := Vector3(sx * (half_w * 0.55), y1 - 0.06, off)
		if (minf(a.x, c.x) < gap.y and maxf(a.x, c.x) > gap.x):
			continue
		it.append(_beam(b * a, b * c, 0.15, "tar"))


func _add_storey1(it: Array) -> void:
	# First timber storey (whitewash + tar), jettied over the stone. Built straight, then leaned by _l1.
	var bz := Basis.IDENTITY
	var bx := Basis(Vector3.UP, PI * 0.5)
	var bnz := Basis(Vector3.UP, PI)
	var bnx := Basis(Vector3.UP, -PI * 0.5)
	it.append(_it(_box(Vector3(W1 * 2.0 + 0.12, Y_SILL - Y_STONE, W1 * 2.0 + 0.12)),
		Vector3(0, (Y_STONE + Y_SILL) * 0.5, 0), "tar"))
	for k: int in 7:
		var s: float = -1.8 + 0.6 * k
		for f: Basis in [bz, bx, bnz, bnx]:
			it.append(_itx(_box(Vector3(0.2, 0.16, 0.26)), Transform3D(f, f * Vector3(s, Y_STONE - 0.08, W0 + 0.1)), "tar"))
	var h: float = Y_F1 - Y_SILL
	var yc: float = (Y_SILL + Y_F1) * 0.5
	it.append(_it(_box(Vector3(W1 * 2.0, h, W1 * 2.0)), Vector3(0, yc, 0), "white"))
	it.append(_it(_box(Vector3(W1 * 2.0 + 0.2, Y_P1 - Y_F1, W1 * 2.0 + 0.2)), Vector3(0, (Y_F1 + Y_P1) * 0.5, 0), "tar"))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(_it(_box(Vector3(0.26, h + 0.04, 0.26)), Vector3(c.x * (W1 - 0.06), yc, c.y * (W1 - 0.06)), "tar"))
	var off: float = W1 + 0.02
	var wy: float = yc + 0.02
	# Front (+Z, the road side): a window with magpie shutters left of centre; the Fire banner hangs right of it.
	_half_timber(it, bz, W1, off, Y_SILL, Y_F1, Vector2(-1.6, -0.1))
	_window(it, bz, Vector3(-0.85, wy, off), 0.56, 0.5, 1)
	# +X (camera side of the south-east Den): a shutter hanging askew; the Nature banner beside it.
	_half_timber(it, bx, W1, off, Y_SILL, Y_F1, Vector2(-0.2, 1.3))
	_window(it, bx, Vector3(0.55, wy, off), 0.56, 0.5, 2)
	# -Z: boarded window.
	_half_timber(it, bnz, W1, off, Y_SILL, Y_F1, Vector2(-1.2, 0.2))
	_window(it, bnz, Vector3(-0.5, wy, off), 0.52, 0.46, 3)
	# -X (camera side of the north-west Den): shuttered window; the Ice banner beside it.
	_half_timber(it, bnx, W1, off, Y_SILL, Y_F1, Vector2(-0.9, 0.5))
	_window(it, bnx, Vector3(-0.2, wy, off), 0.5, 0.46, 1)


func _add_storey2(it: Array) -> void:
	# Second storey: long along the ridge (X) with the gable ends jettied out, narrower across. A ramshackle plank
	# patch covers the -X gable wall; the loading door of the hoist dormer opens in the front (+Z) wall. Leaned by _l12.
	var bz := Basis.IDENTITY
	var bx := Basis(Vector3.UP, PI * 0.5)
	var bnz := Basis(Vector3.UP, PI)
	var bnx := Basis(Vector3.UP, -PI * 0.5)
	var h: float = Y_F2 - Y_P1
	var yc: float = (Y_P1 + Y_F2) * 0.5
	it.append(_it(_box(Vector3(W2X * 2.0, h, W2Z * 2.0)), Vector3(0, yc, 0), "white"))
	it.append(_it(_box(Vector3(W2X * 2.0 + 0.18, Y_P2 - Y_F2, W2Z * 2.0 + 0.18)), Vector3(0, (Y_F2 + Y_P2) * 0.5, 0), "tar"))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(_it(_box(Vector3(0.24, h + 0.04, 0.24)), Vector3(c.x * (W2X - 0.05), yc, c.y * (W2Z - 0.05)), "tar"))
	# Joist ends under the jettied gable ends.
	for k: int in 7:
		var s: float = -1.8 + 0.6 * k
		for sx: float in [-1.0, 1.0]:
			it.append(_it(_box(Vector3(0.3, 0.14, 0.18)), Vector3(sx * (W2X - 0.08), Y_P1 - 0.02, s), "tar"))
	var wy: float = yc + 0.02
	# Front (+Z): a shuttered window on the left (the hoist dormer rises from this wall on the right).
	_half_timber(it, bz, W2X, W2Z + 0.02, Y_P1, Y_F2, Vector2(-1.7, -0.4))
	_window(it, bz, Vector3(-1.05, wy, W2Z + 0.02), 0.46, 0.42, 1)
	# Back (-Z): a plain window.
	_half_timber(it, bnz, W2X, W2Z + 0.02, Y_P1, Y_F2, Vector2(-0.9, -0.1))
	_window(it, bnz, Vector3(-0.5, wy, W2Z + 0.02), 0.44, 0.4, 0)
	# +X gable wall: shuttered window.
	_half_timber(it, bx, W2Z, W2X + 0.02, Y_P1, Y_F2, Vector2(-0.8, 0.8))
	_window(it, bx, Vector3(0.0, wy, W2X + 0.02), 0.48, 0.42, 1)
	# -X gable wall: planks nailed over the whitewash (ramshackle patch) with a small boarded window.
	it.append(_itx(_box(Vector3(W2Z * 2.0 - 0.3, h - 0.08, 0.07)), Transform3D(bnx, bnx * Vector3(0.1, yc, W2X + 0.04)), "wood"))
	for s: float in [-1.0, 1.0]:
		it.append(_itx(_box(Vector3(W2Z * 2.0 - 0.4, 0.09, 0.05)), Transform3D(bnx, bnx * Vector3(0.1, yc + s * 0.25, W2X + 0.09)), "tar"))
	_window(it, bnx, Vector3(-0.55, wy, W2X + 0.1), 0.38, 0.36, 3)


func _add_roof(it: Array) -> void:
	# Steep patched slate-shingle roof, ridge along X; black verge and fascia boards, a sagging ridge beam, loose
	# patch boards; whitewashed gables (+-X, the camera sides) with black timbers and a round blue-green lookout window.
	var g: Dictionary = _roof_geo()
	var ang: float = g["ang"]
	var slope: float = g["slope"]
	var eave_z: float = g["eave_z"]
	var eave_y: float = g["eave_y"]
	var thick: float = g["thick"]
	var ridge_y: float = g["ridge_y"]
	var depth: float = g["depth"]
	var run: float = eave_z / cos(ang)
	var length: float = run + 0.12
	for sz: float in [1.0, -1.0]:
		var down := Vector3(0.0, -sin(ang), cos(ang) * sz)
		var nrm := Vector3(0.0, cos(ang), sin(ang) * sz)
		var eave := Vector3(0.0, eave_y, eave_z * sz)
		var b := Basis(Vector3.RIGHT, ang * sz)
		var centre: Vector3 = eave - down * (length * 0.5) + nrm * (thick * 0.5)
		# The front slope is cut where the hoist dormer rises through it.
		var spans: Array[Vector2] = [Vector2(-depth * 0.5, depth * 0.5)]
		if sz > 0.0:
			spans = [Vector2(-depth * 0.5, HOIST_X - DORMER_HW - 0.02), Vector2(HOIST_X + DORMER_HW + 0.02, depth * 0.5)]
		for sp: Vector2 in spans:
			var w: float = sp.y - sp.x
			var cx := Vector3((sp.x + sp.y) * 0.5, 0, 0)
			it.append(_itx(_box(Vector3(w, thick, length)), Transform3D(b, centre + cx), "roof"))
			it.append(_itx(_box(Vector3(w + 0.05, 0.22, 0.12)), Transform3D(b, eave + nrm * 0.05 + down * 0.03 + cx), "tar"))
		for sx: float in [-1.0, 1.0]:
			var p0: Vector3 = eave + nrm * (thick * 0.5) + Vector3(sx * (depth * 0.5 + 0.04), 0, 0)
			it.append(_beam(p0, p0 - down * run, 0.14, "tar", 0.05))
		# One loose patch board per slope (the front one left of the dormer).
		var top: Vector3 = eave + nrm * (thick + 0.02)
		var c: Vector3 = top - down * (1.0 if sz > 0.0 else 1.5) + Vector3(-1.5 * sz, 0, 0)
		it.append(_itx(_box(Vector3(0.28, 0.05, 1.0)), Transform3D(b * Basis(Vector3.UP, 0.3 * sz), c), "wood"))
	# Ridge beam, sagging: two halves meeting a little low in the middle.
	for sx: float in [-1.0, 1.0]:
		it.append(_beam(Vector3(0, ridge_y - 0.04, 0.0), Vector3(sx * (depth * 0.5 + 0.08), ridge_y + 0.07, 0), 0.2, "tar"))
	# Gables on +-X.
	var gw: float = W2Z + 0.08
	var gh: float = gw * slope
	for sx: float in [-1.0, 1.0]:
		var bg := Basis(Vector3.UP, PI * 0.5 * sx)   # local +Z = outward, local X along the gable
		var x: float = sx * (W2X - 0.01)
		it.append(_itx(_prism(Vector3(gw * 2.0, gh, 0.24)), Transform3D(bg, Vector3(x, Y_P2 + gh * 0.5, 0)), "white"))
		var o := Vector3(0, 0, W2X + 0.12)
		it.append(_itx(_box(Vector3(gw * 1.5, 0.14, 0.1)), Transform3D(bg, bg * (o + Vector3(0, Y_P2 + 0.4, 0))), "tar"))
		it.append(_itx(_box(Vector3(0.14, gh - 0.3, 0.1)), Transform3D(bg, bg * (o + Vector3(0, Y_P2 + 0.3 + (gh - 0.3) * 0.5, 0))), "tar"))
		for s: float in [-1.0, 1.0]:
			it.append(_beam(bg * (o + Vector3(s * gw * 0.74, Y_P2 + 0.46, 0.01)), bg * (o + Vector3(s * 0.16, Y_P2 + gh * 0.74, 0.01)),
				0.1, "tar"))
		# Round lookout window (blue-green), off-centre.
		var ow := Transform3D(bg * Basis(Vector3.RIGHT, PI * 0.5), bg * (o + Vector3(0.62 * sx, Y_P2 + 0.9, 0.03)))
		it.append(_itx(_cyl(0.2, 0.2, 0.05, 12), ow, "window"))
		it.append(_itx(_torus(0.18, 0.3, 12), ow * Transform3D(Basis.IDENTITY, Vector3(0, 0.03, 0)), "tar"))
		it.append(_itx(_box(Vector3(0.05, 0.4, 0.05)), ow * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.06, 0)), "tar"))


## The hoist dormer on the front slope: a small whitewashed gable with a hoist opening, a jib out over the road, a
## pulley and the rope back inside (the loot sack itself swings on its own pivot, see _build_sack).
func _add_hoist(it: Array) -> void:
	var x: float = HOIST_X
	var y_dt: float = DORMER_TOP
	var fz: float = W2Z + 0.02
	var back: float = -0.15
	var hw: float = DORMER_HW
	var dz: float = fz - back
	it.append(_it(_box(Vector3(hw * 2.0, y_dt - Y_F2 + 0.05, dz)), Vector3(x, (Y_F2 - 0.05 + y_dt) * 0.5, (fz + back) * 0.5), "white"))
	for s: float in [-1.0, 1.0]:
		it.append(_it(_box(Vector3(0.18, y_dt - Y_F2 + 0.1, 0.18)), Vector3(x + s * (hw - 0.02), (Y_F2 + y_dt) * 0.5, fz + 0.02), "tar"))
	it.append(_it(_box(Vector3(hw * 2.0 + 0.16, 0.14, 0.2)), Vector3(x, y_dt, fz + 0.02), "tar"))
	# Hoist opening (dark) in the dormer front.
	it.append(_it(_box(Vector3(0.7, 0.62, 0.05)), Vector3(x, Y_P2 + 0.26, fz + 0.01), "iron"))
	# Dormer gable + small roof (ridge along Z, 45 degrees).
	var da: float = deg_to_rad(45.0)
	var gh: float = hw + 0.06
	it.append(_it(_prism(Vector3((hw + 0.06) * 2.0, gh, 0.2)), Vector3(x, y_dt + 0.07 + gh * 0.5, fz), "white"))
	var dthick: float = 0.2
	var dlen: float = (hw + 0.28) / cos(da)
	var ddepth: float = dz + 0.36
	var dridge: float = y_dt + 0.07 + gh + dthick / cos(da)
	for s: float in [1.0, -1.0]:
		var down := Vector3(cos(da) * s, -sin(da), 0.0)
		var nrm := Vector3(sin(da) * s, cos(da), 0.0)
		var b := Basis(Vector3.BACK, -da * s)
		var top := Vector3(x, dridge, 0.0) - nrm * dthick * 0.5
		var centre: Vector3 = top + down * (dlen * 0.5 - 0.06)
		centre.z = back + ddepth * 0.5 - 0.1
		it.append(_itx(_box(Vector3(dlen, dthick, ddepth)), Transform3D(b, centre), "roof"))
		var p0 := Vector3(x, dridge - 0.02, fz + 0.26)
		it.append(_beam(p0, p0 + down * (dlen - 0.08), 0.12, "tar"))
	it.append(_it(_box(Vector3(0.16, 0.16, ddepth)), Vector3(x, dridge, back + ddepth * 0.5 - 0.1), "tar"))
	# Jib out of the dormer over the road, a strut under it, the pulley and the rope back into the opening.
	var jy: float = y_dt + 0.3
	var tip := Vector3(x, jy + 0.06, fz + 1.5)
	it.append(_beam(Vector3(x, jy, fz - 0.5), tip, 0.2, "tar", 0.1))
	it.append(_beam(Vector3(x, y_dt - 0.5, fz + 0.04), Vector3(x, jy - 0.06, fz + 0.95), 0.14, "tar"))
	var pulley := tip + Vector3(0, -0.16, -0.08)
	it.append(_it(_cyl(0.17, 0.17, 0.1, 12), pulley, "iron", Vector3(0, 0, 90)))
	for s: float in [-1.0, 1.0]:
		it.append(_it(_box(Vector3(0.04, 0.3, 0.24)), pulley + Vector3(s * 0.08, 0.05, 0), "iron"))
	it.append(_rod(pulley + Vector3(0, 0.15, -0.1), Vector3(x + 0.05, Y_P2 + 0.35, fz), 0.025, "burlap"))
	it.append(_it(_box(Vector3(0.06, 0.16, 0.06)), Vector3(x, jy - 0.05, fz + 0.8), "iron"))


func _add_mast(it: Array) -> void:
	# In the mast frame (local +Y along the mast, y 0 = 1 m under the ridge): pole, a rope lashing at the ridge,
	# struts, the barrel crow's nest with iron hoops and a small lookout lamp. Top at MAST_TOP.
	it.append(_it(_cyl(0.11, 0.14, MAST_TOP, 8), Vector3(0, MAST_TOP * 0.5, 0), "tar"))
	it.append(_it(_torus(0.11, 0.19, 10), Vector3(0, 0.95, 0), "burlap"))
	var nb: float = NEST_Y
	var nh: float = 0.6
	for k: int in 4:
		var a: float = PI * 0.25 + PI * 0.5 * k
		it.append(_beam(Vector3(0, nb - 0.36, 0), Vector3(cos(a) * 0.46, nb + 0.02, sin(a) * 0.46), 0.08, "tar"))
	it.append(_it(_cyl(0.7, 0.58, nh, 14), Vector3(0, nb + nh * 0.5, 0), "wood"))
	it.append(_it(_cyl(0.6, 0.6, 0.04, 14), Vector3(0, nb + nh - 0.1, 0), "dark"))
	it.append(_it(_torus(0.6, 0.76, 18), Vector3(0, nb + nh - 0.01, 0), "tar"))
	for y: float in [0.1, 0.4]:
		var r: float = lerpf(0.58, 0.7, y / nh) + 0.02
		it.append(_it(_cyl(r, r, 0.07, 14), Vector3(0, nb + y, 0), "iron"))
	# Lookout lamp hanging off the rim (+Z side, over the road).
	var lp := Vector3(0.1, nb + nh - 0.08, 0.78)
	it.append(_it(_box(Vector3(0.06, 0.06, 0.2)), lp + Vector3(0, 0.02, -0.08), "iron"))
	it.append(_it(_cyl(0.02, 0.18, 0.1, 4), lp + Vector3(0, -0.07, 0.04), "iron", Vector3(0, 45, 0)))
	it.append(_it(_box(Vector3(0.22, 0.28, 0.22)), lp + Vector3(0, -0.26, 0.04), "lantern"))
	it.append(_it(_box(Vector3(0.26, 0.05, 0.26)), lp + Vector3(0, -0.42, 0.04), "iron"))


func _crate(it: Array, pos: Vector3, s: float, yaw_deg: float) -> void:
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), pos + Vector3(0, s * 0.5, 0))
	it.append(_itx(_box(Vector3(s, s, s)), xf, "wood"))
	for y: float in [-0.5, 0.5]:
		it.append(_itx(_box(Vector3(s + 0.04, 0.08, s + 0.04)), xf * Transform3D(Basis.IDENTITY, Vector3(0, y * (s - 0.08), 0)), "tar"))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(_itx(_box(Vector3(0.08, s, 0.08)), xf * Transform3D(Basis.IDENTITY,
			Vector3(c.x * (s * 0.5 - 0.02), 0, c.y * (s * 0.5 - 0.02))), "tar"))


func _sack_item(it: Array, pos: Vector3, r: float, tilt: float) -> void:
	var xf := Transform3D(Basis(Vector3.BACK, tilt).scaled(Vector3(1.0, 1.15, 0.95)), pos + Vector3(0, r * 0.95, 0))
	it.append(_itx(_sphere(r, 10, 6), xf, "burlap"))
	it.append(_itx(_cyl(r * 0.28, r * 0.4, r * 0.5, 8), Transform3D(Basis(Vector3.BACK, tilt), pos + Vector3(-sin(tilt) * r * 1.1, r * 2.0, 0)), "burlap"))


func _barrel(it: Array, xf: Transform3D) -> void:
	it.append(_itx(_cyl(0.33, 0.27, 0.42, 10), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0.21, 0)), "wood"))
	it.append(_itx(_cyl(0.27, 0.33, 0.42, 10), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0.63, 0)), "wood"))
	it.append(_itx(_cyl(0.28, 0.28, 0.04, 10), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0.83, 0)), "tar"))
	for y: float in [0.13, 0.71]:
		it.append(_itx(_cyl(0.305, 0.305, 0.07, 10), xf * Transform3D(Basis.IDENTITY, Vector3(0, y, 0)), "iron"))
	it.append(_itx(_cyl(0.34, 0.34, 0.07, 10), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0.42, 0)), "iron"))


func _add_props(it: Array) -> void:
	var y0: float = Y_PLINTH
	# +X side: stolen crates, a strongbox with its lid up and gold inside, sacks, spilled coins.
	_crate(it, Vector3(2.62, y0, 0.35), 0.62, 8.0)
	_crate(it, Vector3(2.64, y0, 1.12), 0.54, -12.0)
	_crate(it, Vector3(2.58, y0 + 0.62, 0.42), 0.46, 27.0)
	var sb := Transform3D(Basis(Vector3.UP, deg_to_rad(-80.0)), Vector3(2.6, y0, -0.5))
	it.append(_itx(_box(Vector3(0.6, 0.34, 0.4)), sb * Transform3D(Basis.IDENTITY, Vector3(0, 0.17, 0)), "wood"))
	for x: float in [-0.2, 0.2]:
		it.append(_itx(_box(Vector3(0.07, 0.36, 0.43)), sb * Transform3D(Basis.IDENTITY, Vector3(x, 0.18, 0)), "iron"))
	it.append(_itx(_box(Vector3(0.12, 0.13, 0.05)), sb * Transform3D(Basis.IDENTITY, Vector3(0, 0.23, 0.22)), "gold"))
	it.append(_itx(_sphere(0.24, 10, 5), sb * Transform3D(Basis.IDENTITY.scaled(Vector3(1.1, 0.3, 0.7)), Vector3(0, 0.35, 0)), "gold"))
	it.append(_itx(_box(Vector3(0.6, 0.06, 0.4)), sb * Transform3D(Basis(Vector3.RIGHT, -1.1), Vector3(0, 0.5, -0.33)), "wood"))
	_sack_item(it, Vector3(2.62, y0, -1.25), 0.3, 0.15)
	_sack_item(it, Vector3(2.35, y0, -1.72), 0.26, -0.3)
	it.append(_it(_sphere(0.3, 10, 5), Vector3(2.55, y0, 1.75), "gold", Vector3.ZERO, Vector3(1.0, 0.28, 0.8)))
	for c: Vector3 in [Vector3(2.2, 0.02, 1.95), Vector3(2.9, 0.02, 1.95), Vector3(2.35, 0.02, 2.25)]:
		it.append(_it(_cyl(0.09, 0.09, 0.03, 10), Vector3(c.x, y0 + c.y, c.z), "gold", Vector3(8, 0, 12)))
	# Back (+X-Z corner): a barrel and a crate stacked against the ruin wall.
	_barrel(it, Transform3D(Basis(Vector3.UP, 0.7), Vector3(1.75, y0, -2.55)))
	_crate(it, Vector3(2.55, y0, -2.5), 0.56, 18.0)
	# Front-left: a broken cart wheel leaning on the boarded corner and a sack.
	var wh := Transform3D(Basis(Vector3.UP, 0.08) * Basis(Vector3.RIGHT, -0.2), Vector3(-1.45, y0 + 0.5, W0 + 0.27))
	it.append(_itx(_torus(0.4, 0.5, 14), wh * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), "wood"))
	it.append(_itx(_cyl(0.1, 0.1, 0.18, 8), wh * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), "tar"))
	for k: int in 5:
		var a: float = TAU * float(k) / 6.0 + 0.3
		it.append(_itx(_box(Vector3(0.06, 0.4, 0.05)), wh * Transform3D(Basis(Vector3.BACK, a), Vector3(-sin(a), cos(a), 0) * 0.22), "wood"))
	_sack_item(it, Vector3(-2.0, y0, 2.55), 0.27, 0.2)
	# -X: a ladder up to the first storey (the way up to the lookout).
	var lz: float = 0.95
	var bot := Vector3(-W1 - 0.62, y0, lz)
	var top := _l1 * Vector3(-W1 - 0.04, Y_F1 - 0.1, lz)
	for s: float in [-0.23, 0.23]:
		it.append(_rod(bot + Vector3(0, 0, s), top + Vector3(0, 0.25, s), 0.05, "wood", 0.0, 6))
	for k: int in 8:
		var f: float = (float(k) + 0.6) / 8.6
		var p: Vector3 = bot.lerp(top, f)
		it.append(_it(_cyl(0.035, 0.035, 0.5, 6), p, "wood", Vector3(90, 0, 0)))
	# Front-right of the door, under the hoist: crates waiting to go up and a spilled coin heap.
	_crate(it, Vector3(1.45, y0, 2.66), 0.56, -14.0)
	_crate(it, Vector3(2.12, y0, 2.62), 0.5, 22.0)
	_crate(it, Vector3(1.6, y0 + 0.56, 2.62), 0.42, 8.0)
	it.append(_it(_sphere(0.26, 10, 5), Vector3(0.95, y0, 2.78), "gold", Vector3.ZERO, Vector3(1.0, 0.3, 0.75)))


# --- Cloth (one merged mesh): four stolen banners + the Magpies' flag ---

func _build_cloth() -> void:
	var it: Array = []
	var off1: float = W1 + 0.07
	# Fire: first storey front (+Z), right of the window, hanging a little crooked.
	it.append(_itx(_cloth_mesh(0.62, 0.98, C_FIRE, 1.0),
		_l1 * Transform3D(Basis(Vector3.BACK, 0.07), Vector3(0.85, Y_F1 - 0.02, off1)), "cloth"))
	# Ice: first storey -X face, beside the window.
	it.append(_itx(_cloth_mesh(0.58, 0.92, C_ICE, 1.0),
		_l1 * Transform3D(Basis(Vector3.UP, -PI * 0.5) * Basis(Vector3.BACK, -0.05), Vector3(-off1, Y_F1 - 0.02, -1.3)), "cloth"))
	# Nature: first storey +X face, beside the shutter hanging askew.
	it.append(_itx(_cloth_mesh(0.6, 0.95, C_NATURE, 1.0),
		_l1 * Transform3D(Basis(Vector3.UP, PI * 0.5) * Basis(Vector3.BACK, 0.06), Vector3(off1, Y_F1 - 0.02, 0.85)), "cloth"))
	# Shadow: hanging from the hoist jib like a trophy (faces +-X, the camera sides).
	it.append(_itx(_cloth_mesh(0.52, 1.0, C_SHADOW, 1.0),
		_l12 * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(HOIST_X, DORMER_TOP + 0.22, W2Z + 0.86)), "cloth"))
	# The Magpies' flag on the mast, flying over the road (+Z, sideways on screen). The cloth hangs along local -Y:
	# turned so it flies along +Z, its height along the mast.
	it.append(_itx(_cloth_mesh(FLAG_SIZE.y, FLAG_SIZE.x, Color(0.05, 0.05, 0.06), 0.0),
		_mast_xf * Transform3D(Basis(Vector3.UP, -PI * 0.5) * Basis(Vector3.BACK, PI * 0.5), Vector3(0.0, FLAG_Y, 0.1)),
		"cloth"))
	var mi: MeshInstance3D = _merge("Cloth", "cloth", it, _body, false)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# --- Moving parts ---

func _build_door() -> void:
	# Doorway glow (the dim blue-green inside) and a patched plank door hinged on the left jamb, swinging out.
	var glow_it: Array = [_it(_box(Vector3(DOOR_W, DOOR_H, 0.04)), Vector3(DOOR_X, Y_PLINTH + DOOR_H * 0.5, W0 + 0.012),
		"door_glow")]
	_door_glow = _merge("DoorGlow", "door_glow", glow_it, _body, false)
	_door_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_door = Node3D.new()
	_door.name = "DoorPivot"
	_door.position = Vector3(DOOR_X - DOOR_W * 0.5, Y_PLINTH, W0 + 0.06)
	_body.add_child(_door)
	var it: Array = []
	var w: float = DOOR_W - 0.04
	it.append(_it(_box(Vector3(w, DOOR_H - 0.03, 0.09)), Vector3(w * 0.5, DOOR_H * 0.5, 0.0), "wood"))
	for y: float in [0.28, DOOR_H - 0.3]:
		it.append(_it(_box(Vector3(w - 0.08, 0.12, 0.13)), Vector3(w * 0.5, y, 0.0), "tar"))
	it.append(_beam(Vector3(0.12, 0.34, 0.05), Vector3(w - 0.12, DOOR_H - 0.36, 0.05), 0.1, "tar"))
	for y: float in [0.28, DOOR_H - 0.3]:
		it.append(_it(_box(Vector3(0.42, 0.06, 0.15)), Vector3(0.2, y, 0.0), "iron"))
	# A white feather daubed on the door (the Magpies' mark): two white strokes.
	it.append(_it(_box(Vector3(0.1, 0.5, 0.03)), Vector3(w * 0.62, DOOR_H * 0.55, 0.06), "white", Vector3(0, 0, -24)))
	it.append(_it(_box(Vector3(0.05, 0.3, 0.03)), Vector3(w * 0.52, DOOR_H * 0.38, 0.065), "white", Vector3(0, 0, -24)))
	it.append(_itx(_torus(0.04, 0.08, 10), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(w - 0.14, DOOR_H * 0.48, 0.08)), "iron"))
	_merge("DoorLeaf", "door_leaf", it, _door)


func _build_lantern() -> void:
	# The door lantern (the landmark light, blue-green) hangs at the bracket tip; a soft halo sprite around it.
	_lantern = Node3D.new()
	_lantern.name = "LanternPivot"
	_lantern_basis = Basis.IDENTITY
	_lantern.position = Vector3(LANTERN_X, LANTERN_Y - 0.04, W0 + 0.64)
	_body.add_child(_lantern)
	var it: Array = []
	it.append(_it(_torus(0.03, 0.07, 10), Vector3(0, -0.06, 0), "iron", Vector3(90, 0, 0)))
	it.append(_it(_cyl(0.02, 0.22, 0.15, 4), Vector3(0, -0.17, 0), "iron", Vector3(0, 45, 0)))
	it.append(_it(_box(Vector3(0.25, 0.34, 0.25)), Vector3(0, -0.43, 0), "lantern"))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(_it(_box(Vector3(0.05, 0.38, 0.05)), Vector3(c.x * 0.135, -0.43, c.y * 0.135), "iron"))
	it.append(_it(_box(Vector3(0.32, 0.06, 0.32)), Vector3(0, -0.25, 0), "iron"))
	it.append(_it(_box(Vector3(0.3, 0.07, 0.3)), Vector3(0, -0.63, 0), "iron"))
	it.append(_it(_cyl(0.1, 0.0, 0.11, 4), Vector3(0, -0.72, 0), "iron", Vector3(0, 45, 0)))
	var mi: MeshInstance3D = _merge("Lantern", "lantern", it, _lantern)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo = MeshInstance3D.new()
	_halo.name = "Halo"
	var q := QuadMesh.new()
	q.size = Vector2(1.6, 1.6)
	_halo.mesh = q
	_halo.material_override = _soft_mat("halo", Color(0.35, 1.0, 0.82, 0.5), true, true)
	_halo.position = Vector3(0, -0.43, 0)
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lantern.add_child(_halo)


func _build_vane() -> void:
	# The magpie weather-vane on the mast top: an iron arrow with a fin, a chunky black-and-white magpie standing on
	# it with an iridescent blue-green long tail. Turns (creaks) around the mast. Faces its pivot's +X.
	_vane = Node3D.new()
	_vane.name = "VanePivot"
	var top: Transform3D = _mast_xf * Transform3D(Basis.IDENTITY, Vector3(0, MAST_TOP, 0))
	# Keep the mast's tilt, but let the bird stand upright-ish (half the tilt).
	# Rest heading: beak toward -Z (into the wind; the flag flies downwind toward +Z), sideways on screen.
	_vane_basis = Basis.IDENTITY.slerp(top.basis.orthonormalized(), 0.5) * Basis(Vector3.UP, PI * 0.5)
	_vane.transform = Transform3D(_vane_basis, top.origin)
	_body.add_child(_vane)
	# Unit-size bird (beak +X), scaled by BIRD_S at the end. Black body and head, white belly and shoulder patches,
	# folded black wings, a long iridescent tail tipped up (the magpie read).
	var it: Array = []
	it.append(_it(_sphere(0.08, 8, 4), Vector3(0, 0.02, 0), "iron"))
	it.append(_it(_cyl(0.03, 0.03, 1.2, 6), Vector3(0.02, 0.1, 0), "iron", Vector3(0, 0, 90)))
	it.append(_it(_prism(Vector3(0.24, 0.22, 0.05)), Vector3(0.7, 0.1, 0), "iron", Vector3(0, 0, -90)))
	it.append(_it(_box(Vector3(0.3, 0.24, 0.04)), Vector3(-0.55, 0.15, 0), "iron", Vector3(0, 0, 18)))
	it.append(_it(_cyl(0.03, 0.03, 0.14, 6), Vector3(0.03, 0.17, 0), "iron"))
	it.append(_it(_sphere(0.25, 12, 6), Vector3(0.0, 0.33, 0), "tar", Vector3(0, 0, -8), Vector3(1.45, 0.6, 0.52)))
	it.append(_it(_sphere(0.2, 10, 5), Vector3(0.06, 0.28, 0), "white", Vector3(0, 0, -8), Vector3(1.0, 0.55, 0.76)))
	for sz: float in [-1.0, 1.0]:
		it.append(_it(_sphere(0.15, 10, 5), Vector3(-0.08, 0.38, sz * 0.1), "white", Vector3(0, 0, -6),
			Vector3(1.7, 0.3, 0.26)))
		it.append(_it(_sphere(0.15, 10, 5), Vector3(-0.27, 0.4, sz * 0.075), "tar", Vector3(0, 0, -5),
			Vector3(1.6, 0.34, 0.3)))
		it.append(_it(_cyl(0.018, 0.018, 0.12, 4), Vector3(0.05, 0.21, sz * 0.05), "iron"))
	it.append(_it(_sphere(0.1, 10, 5), Vector3(0.25, 0.4, 0), "tar"))
	it.append(_it(_sphere(0.105, 10, 5), Vector3(0.36, 0.46, 0), "tar"))
	it.append(_it(_cyl(0.0, 0.04, 0.18, 6), Vector3(0.52, 0.45, 0), "iron", Vector3(0, 0, -94)))
	it.append(_it(_box(Vector3(0.85, 0.07, 0.17)), Vector3(-0.72, 0.43, 0), "teal", Vector3(0, 0, -12)))
	it.append(_it(_box(Vector3(0.32, 0.06, 0.25)), Vector3(-1.2, 0.53, 0), "teal", Vector3(0, 0, -12)))
	_xf_items(it, 0, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * BIRD_S), Vector3.ZERO))
	_merge("Vane", "vane", it, _vane)


func _build_sack() -> void:
	# The loot sack swinging from the hoist pulley (rope, iron hook, a bulging sack with gold showing at the neck).
	_sack = Node3D.new()
	_sack.name = "SackPivot"
	var pulley := Vector3(HOIST_X, DORMER_TOP + 0.03, W2Z + 0.02 + 1.42)
	_sack.position = _l12 * pulley
	_body.add_child(_sack)
	var it: Array = []
	it.append(_it(_cyl(0.025, 0.025, 0.36, 6), Vector3(0, -0.18, 0), "burlap"))
	it.append(_it(_torus(0.04, 0.09, 10), Vector3(0, -0.4, 0), "iron", Vector3(90, 0, 0)))
	it.append(_it(_sphere(0.34, 12, 6), Vector3(0, -0.84, 0), "burlap", Vector3.ZERO, Vector3(1.0, 1.15, 0.95)))
	it.append(_it(_cyl(0.1, 0.16, 0.18, 8), Vector3(0, -0.48, 0), "burlap"))
	it.append(_it(_sphere(0.14, 8, 4), Vector3(0.12, -0.56, 0.08), "gold", Vector3.ZERO, Vector3(1.0, 0.6, 1.0)))
	for a: float in [0.0, 1.57]:
		it.append(_it(_torus(0.33, 0.37, 14), Vector3(0, -0.84, 0), "burlap", Vector3(90, rad_to_deg(a), 0), Vector3(1.0, 1.0, 1.1)))
	_merge("Sack", "sack", it, _sack)


# --- Ground contact, fake light pool, dust ---

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
	# Contact decal (art-keep.md 0.5), a trodden dirt path out of the door, a blue-green pool under the lantern,
	# ruin rubble around the platform (one draw call), none in front of the door.
	# MAP.P2: the ContactDecal is a trodden-earth apron with a baked contact shadow along the ruin platform, its
	# tongue out of the door to the road (shared mesh + material, art/environment/neutral/site_ground.gd; symmetric
	# in X so the Body mirror does not change it). The old unshaded soft blob stays as the fallback.
	if ResourceLoader.exists(SITE_GROUND):
		(load(SITE_GROUND) as Script).call(&"add", _body, "ContactDecal", Vector2(2.5, 2.5), 0.35, 2.0, Vector3(0, 0, 1), 2.2, 3)
	else:
		_flat("ContactDecal", Vector2(8.2, 8.2), Vector3(0, 0.03, 0), 0.0,
			_soft_mat("contact", Color(0.04, 0.035, 0.035, 0.66), false, false))
	_flat("PathDecal", Vector2(1.9, 3.4), Vector3(DOOR_X, 0.035, 4.3), 0.0,
		_soft_mat("path", Color(0.28, 0.22, 0.15, 0.7), false, false))
	_pools.append(_flat("LightPool", Vector2(3.0, 3.0), Vector3(LANTERN_X + 0.3, 0.33, W0 + 0.75), 0.0,
		_soft_mat("pool", Color(0.3, 1.0, 0.8, 0.12), true, false)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 10808
	var xf: Array[Transform3D] = []
	for i: int in 12:
		var a: float = PI * 0.2 + (TAU - PI * 0.4) * (float(i) + rng.randf_range(0.0, 0.7)) / 12.0
		var r: float = rng.randf_range(3.0, 3.45)
		var s: float = rng.randf_range(0.32, 0.56)
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, deg_to_rad(rng.randf_range(10.0, 20.0)))
		var d := Vector2(sin(a), cos(a))
		# Square-ish ring (the platform is square).
		var sq: float = r / maxf(absf(d.x), absf(d.y))
		sq = minf(sq, r * 1.25)
		xf.append(Transform3D(b.scaled(Vector3(s, s * 0.7, s * 0.85)), Vector3(d.x * sq, s * 0.12, d.y * sq)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _box(Vector3.ONE)
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


func _build_dust() -> void:
	# One-shot dust puff out of the doorway (play_band_out). MIX, soft billboard, 14 particles.
	var g := Gradient.new()
	g.set_color(0, Color(0.5, 0.44, 0.36, 0.0))
	g.set_color(1, Color(0.5, 0.45, 0.38, 0.0))
	g.add_point(0.06, Color(0.52, 0.46, 0.37, 0.9))
	g.add_point(0.5, Color(0.55, 0.5, 0.42, 0.55))
	var ramp := GradientTexture1D.new()
	ramp.gradient = g
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 0.35, 1.0)
	pm.spread = 38.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 3.4
	pm.gravity = Vector3(0.0, 0.25, 0.0)
	pm.damping_min = 2.4
	pm.damping_max = 3.2
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.45, 0.25, 0.1)
	pm.scale_min = 1.4
	pm.scale_max = 2.2
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.6))
	curve.add_point(Vector2(1.0, 1.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	pm.color_ramp = ramp
	var q := QuadMesh.new()
	var qm: StandardMaterial3D = _soft_mat("dust", Color(1, 1, 1, 1), false, false).duplicate() as StandardMaterial3D
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.vertex_color_use_as_albedo = true
	q.material = qm
	_dust = GPUParticles3D.new()
	_dust.name = "DoorDust"
	_dust.amount = 18
	_dust.lifetime = 1.2
	_dust.one_shot = true
	_dust.explosiveness = 0.85
	_dust.emitting = false
	_dust.fixed_fps = 30
	_dust.interpolate = true
	_dust.local_coords = false
	_dust.process_material = pm
	_dust.draw_pass_1 = q
	_dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dust.visibility_aabb = AABB(Vector3(-3, -1, -1), Vector3(6, 4, 6))
	_dust.position = Vector3(DOOR_X, Y_PLINTH + 0.3, W0 + 0.35)
	_body.add_child(_dust)


# --- State ---

func _band_curve() -> float:
	# 0 -> 1 fast (0.22 s), hold, back to 0 over the last 0.6 s.
	if _band_t < 0.0:
		return 0.0
	if _band_t < 0.22:
		return ease(_band_t / 0.22, 0.4)
	if _band_t < BAND_TIME - 0.6:
		return 1.0
	return 1.0 - ease((_band_t - (BAND_TIME - 0.6)) / 0.6, 1.8)


func _apply_door() -> void:
	var ajar: float = deg_to_rad(DOOR_AJAR_DEG) * ease(_open_k, -2.0)
	var wide: float = deg_to_rad(DOOR_WIDE_DEG) * _band_curve()
	_door.rotation.y = -maxf(ajar, wide)


func _apply_open() -> void:
	var k: float = _open_k
	_apply_door()
	_door_glow.visible = k > 0.01 or _band_t >= 0.0
	_g_door.set_shader_parameter(&"energy", 0.9 * k)
	_g_window.set_shader_parameter(&"energy", lerpf(0.25, 0.7, k))   # 1.2 -> 0.7: soft slits under the bloom (R5, 2026-09-30)
	_g_lantern.set_shader_parameter(&"energy", lerpf(0.9, 3.4, k))
	_halo.transparency = lerpf(0.7, 0.0, k)
	if _lamp_light:
		_lamp_light.set_level(lerpf(0.3, 1.0, k))
	for p: MeshInstance3D in _pools:
		p.visible = k > 0.05
		p.transparency = 1.0 - k
	if _pal:
		BuildingPalette.refresh(_pal)


func _apply_rim_and_glow() -> void:
	if not _ready_done:
		return
	var rim_col: Color = RIM_IDLE.lerp(RIM_SELECTED, _sel_k)
	var rim_str: float = lerpf(0.22, 0.75, _sel_k)
	for m: ShaderMaterial in _painted:
		m.set_shader_parameter(&"rim_color", rim_col)
		m.set_shader_parameter(&"rim_strength", rim_str)
	_cloth_mat.set_shader_parameter(&"rim_color", rim_col)
	_cloth_mat.set_shader_parameter(&"rim_strength", 0.6 * _sel_k)
	var band: float = _band_curve()
	var boost: float = lerpf(1.0, 1.35, _sel_k) + 0.8 * band
	for m: ShaderMaterial in _glows:
		m.set_shader_parameter(&"boost", boost)
	_g_door.set_shader_parameter(&"boost", boost + 2.0 * band)
	_door_glow.visible = _open_k > 0.01 or _band_t >= 0.0
	if not _open and _band_t >= 0.0:
		_g_door.set_shader_parameter(&"energy", 0.9 * band)
	if _pal:
		BuildingPalette.refresh(_pal)
