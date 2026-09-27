class_name BountyFlagModel
extends Node3D
## Bounty flag model (task 9.V6, docs/design/champions.md sections 6 and 9). The Bounty node (scripts/world/bounty.gd)
## instances it; many can exist, so it is cheap: 4 draw calls (stand, cairn, pennant, coin; 3 with the cairn hidden),
## meshes and materials shared by every flag (static), per-flag looks through instance uniforms, and the idle motion
## (coin spin + bob, pennant wave) runs in the shaders: no _process except during play_raise(). No light, no collision.
## Look: a 1.6 m wooden pole planted in a small cairn, brass bands, a crossbar carrying a swallow-tail pennant in the
## owner's team colour with the kind icon in gold, and a gold coin disc (r 0.35) floating and spinning slowly above the
## pole tip, the kind icon engraved on both faces, its edge in the team colour.
## Kinds (same order as Bounty.kind): 0 Hunt = crossed blades, 1 Explore = eye, 2 Guard = shield, 3 Escort = linked rings.
## API (all safe before _ready): set_team_color(c), set_kind(kind), set_selected(on), play_raise(),
## set_grounded(on) (hide the cairn, e.g. when the flag rides above a unit). Root origin = the ground point.

const STAND_MAT: Material = preload("res://art/environment/env_painted_mat.tres")
const COIN_SHADER: Shader = preload("res://art/buildings/tavern/bounty_coin.gdshader")
const PENNANT_SHADER: Shader = preload("res://art/buildings/tavern/bounty_pennant.gdshader")

enum Kind { HUNT, EXPLORE, GUARD, ESCORT }

const POLE_HEIGHT := 1.6
const COIN_RADIUS := 0.35
const COIN_Y := 2.07          # coin centre (bottom 1.72, just above the brass finial)
const PENNANT_SIZE := Vector2(0.56, 0.74)
const PENNANT_TOP := 1.47

const C_WOOD := Color(0.45, 0.30, 0.17)
const C_WOOD_D := Color(0.30, 0.20, 0.12)
const C_BRASS := Color(0.80, 0.62, 0.28)
const C_STONE := Color(0.50, 0.48, 0.44)
const C_SOIL := Color(0.30, 0.23, 0.16)

static var _stand_mesh: ArrayMesh
static var _cairn_mesh: ArrayMesh
static var _coin_mesh: ArrayMesh
static var _pennant_mesh: PlaneMesh
static var _coin_mat: ShaderMaterial
static var _pennant_mat: ShaderMaterial

var _team_color: Color = Color(0.85, 0.30, 0.12)
var _kind: int = Kind.HUNT
var _selected: bool = false
var _grounded: bool = true
var _phase: float = 0.0
var _ready_done: bool = false
var _raise_t: float = -1.0

var _stand: MeshInstance3D
var _cairn: MeshInstance3D
var _pennant: MeshInstance3D
var _coin: MeshInstance3D


func _ready() -> void:
	_ready_done = true
	_phase = randf() * TAU
	_ensure_shared()
	_stand = _mesh_node("Stand", _stand_mesh, STAND_MAT)
	_cairn = _mesh_node("Cairn", _cairn_mesh, STAND_MAT)
	_cairn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pennant = _mesh_node("Pennant", _pennant_mesh, _pennant_mat)
	_pennant.position = Vector3(0.0, PENNANT_TOP - PENNANT_SIZE.y * 0.5, 0.08)
	_pennant.extra_cull_margin = 0.2
	_coin = _mesh_node("Coin", _coin_mesh, _coin_mat)
	_coin.position = Vector3(0.0, COIN_Y, 0.0)
	_coin.extra_cull_margin = COIN_RADIUS + 0.1
	_coin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for g: GeometryInstance3D in [_pennant, _coin]:
		g.set_instance_shader_parameter(&"phase", _phase)
	set_process(false)
	_apply()


func _process(delta: float) -> void:
	if _raise_t < 0.0:
		set_process(false)
		return
	_raise_t += delta
	var k: float = clampf(_raise_t / 0.55, 0.0, 1.0)
	# Hop up, a squash-and-stretch pop, settle.
	_coin.position.y = COIN_Y + sin(k * PI) * 0.35
	_coin.scale = Vector3.ONE * (1.0 + sin(k * PI) * 0.3)
	if k >= 1.0:
		_raise_t = -1.0
		_coin.position.y = COIN_Y
		_coin.scale = Vector3.ONE
		set_process(false)


# --- API ---

## Team colour of the pennant and of the coin's edge.
func set_team_color(c: Color) -> void:
	_team_color = c
	_apply()


## 0 Hunt (crossed blades), 1 Explore (eye), 2 Guard (shield), 3 Escort (linked rings).
func set_kind(kind: int) -> void:
	_kind = clampi(kind, 0, 3)
	_apply()


func get_kind() -> int:
	return _kind


func set_selected(on: bool) -> void:
	_selected = on
	_apply()


## Stake raised: the coin hops and pops (0.55 s). Safe to retrigger.
func play_raise() -> void:
	_raise_t = 0.0
	if _ready_done:
		set_process(true)


## Show / hide the little cairn at the foot of the pole (hide it when the flag rides a unit).
func set_grounded(on: bool) -> void:
	_grounded = on
	_apply()


# --- Internals ---

func _apply() -> void:
	if not _ready_done:
		return
	for g: GeometryInstance3D in [_pennant, _coin]:
		g.set_instance_shader_parameter(&"team_color", _team_color)
		g.set_instance_shader_parameter(&"kind", float(_kind))
		g.set_instance_shader_parameter(&"highlight", 1.0 if _selected else 0.0)
	_cairn.visible = _grounded
	if _raise_t >= 0.0:
		set_process(true)


func _mesh_node(nm: String, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.material_override = mat
	add_child(mi)
	return mi


static func _ensure_shared() -> void:
	if _coin_mat != null:
		return
	_coin_mat = ShaderMaterial.new()
	_coin_mat.shader = COIN_SHADER
	_coin_mat.set_shader_parameter(&"radius", COIN_RADIUS)
	_pennant_mat = ShaderMaterial.new()
	_pennant_mat.shader = PENNANT_SHADER
	_pennant_mat.set_shader_parameter(&"size", PENNANT_SIZE)
	_pennant_mesh = PlaneMesh.new()
	_pennant_mesh.size = PENNANT_SIZE
	_pennant_mesh.orientation = PlaneMesh.FACE_Z
	_pennant_mesh.subdivide_width = 3
	_pennant_mesh.subdivide_depth = 8
	# Coin: a 32-sided disc turned so its faces look along +-Z.
	var disc := CylinderMesh.new()
	disc.top_radius = COIN_RADIUS
	disc.bottom_radius = COIN_RADIUS
	disc.height = 0.08
	disc.radial_segments = 32
	disc.rings = 1
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(disc, 0, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	_coin_mesh = st.commit()
	_stand_mesh = _bake(_stand_items(), 1.75)
	_cairn_mesh = _bake(_cairn_items(), 0.4)


static func _cyl(top_r: float, bot_r: float, h: float, segs: int) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top_r
	m.bottom_radius = bot_r
	m.height = h
	m.radial_segments = segs
	m.rings = 1
	m.cap_top = top_r > 0.0
	m.cap_bottom = bot_r > 0.0
	return m


static func _stand_items() -> Array:
	var it: Array = []
	var up := Basis.IDENTITY
	# Pole (tapers), iron-shod foot, two brass bands, crossbar with brass knobs, brass finial cup under the coin.
	it.append([_cyl(0.042, 0.056, POLE_HEIGHT, 7), Transform3D(up, Vector3(0, POLE_HEIGHT * 0.5, 0)), C_WOOD])
	it.append([_cyl(0.062, 0.05, 0.14, 7), Transform3D(up, Vector3(0, 0.07, 0)), C_WOOD_D])
	for y: float in [0.42, 1.2]:
		it.append([_cyl(0.066, 0.066, 0.07, 7), Transform3D(up, Vector3(0, y, 0)), C_BRASS])
	var side := Basis(Vector3.BACK, PI * 0.5)
	it.append([_cyl(0.03, 0.03, PENNANT_SIZE.x + 0.12, 6), Transform3D(side, Vector3(0, PENNANT_TOP + 0.02, 0.075)),
		C_WOOD_D])
	var knob := SphereMesh.new()
	knob.radius = 0.05
	knob.height = 0.1
	knob.radial_segments = 8
	knob.rings = 4
	for sx: float in [-1.0, 1.0]:
		it.append([knob, Transform3D(up, Vector3(sx * (PENNANT_SIZE.x * 0.5 + 0.08), PENNANT_TOP + 0.02, 0.075)), C_BRASS])
	it.append([_cyl(0.11, 0.045, 0.12, 8), Transform3D(up, Vector3(0, POLE_HEIGHT + 0.06, 0)), C_BRASS])
	it.append([_cyl(0.0, 0.03, 0.1, 6), Transform3D(up, Vector3(0, POLE_HEIGHT + 0.16, 0)), C_BRASS])
	return it


static func _cairn_items() -> Array:
	# A low mound of soil and four stones around the pole foot.
	var it: Array = []
	it.append([_cyl(0.14, 0.34, 0.1, 9), Transform3D(Basis.IDENTITY, Vector3(0, 0.05, 0)), C_SOIL])
	var stone := SphereMesh.new()
	stone.radius = 0.5
	stone.height = 1.0
	stone.radial_segments = 6
	stone.rings = 3
	var rocks: Array[Vector4] = [Vector4(0.2, 0.0, 0.12, 0.26), Vector4(-0.17, 0.0, 0.16, 0.22),
		Vector4(0.02, 0.0, -0.22, 0.24), Vector4(-0.2, 0.0, -0.1, 0.16)]
	for i: int in rocks.size():
		var r: Vector4 = rocks[i]
		var b := Basis(Vector3.UP, 1.3 * i).scaled(Vector3(r.w, r.w * 0.62, r.w * 0.85))
		it.append([stone, Transform3D(b, Vector3(r.x, r.w * 0.2, r.z)), C_STONE.darkened(0.12 * (i % 2))])
	return it


## Bakes [mesh, xf, colour] parts into one mesh for env_painted.gdshader: COLOR.rgb = colour (sRGB),
## COLOR.a = height gradient 0..1 over `height`, UV = (0 no sway, local height).
static func _bake(items: Array, height: float) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for item: Array in items:
		var mesh: Mesh = item[0]
		var xf: Transform3D = item[1]
		var col: Color = item[2]
		var arr: Array = mesh.surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var nb: Basis = xf.basis.inverse().transposed()
		var base: int = verts.size()
		for i: int in v.size():
			var p: Vector3 = xf * v[i]
			verts.append(p)
			normals.append((nb * n[i]).normalized())
			colors.append(Color(col.r, col.g, col.b, clampf(p.y / height, 0.0, 1.0)))
			uvs.append(Vector2(0.0, p.y))
		for i: int in idx:
			indices.append(base + i)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am
