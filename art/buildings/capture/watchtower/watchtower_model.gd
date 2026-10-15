class_name WatchtowerModel
extends Node3D
## Watchtower capture point model (task 12.V17, docs/design/map-fill.md 4.2 and section 10). Draw only: no collision,
## no gameplay (CapturePoint owns the footprint, the clicks and the rules and calls the hooks below).
## Read from the RTS camera (the 40 m silhouette): a tall, broken round stone tower on an octagonal plinth (ragged top,
## torn open on the front-left), carrying a rebuilt timber crown on posts (turned 45 degrees, plank parapet with lookout windows, cloth drapes)
## under a steep shingle pyramid roof with an iron vane (~9.6 m) = the dominant vertical; the asymmetric secondary is the
## banner pole on the front-right corner with a big hanging banner and an iron cresset (the brazier) on top.
##   Neutral: grey torn banner and drapes, cold black cresset.
##   Owned:   the owner's team colour on the banner and drapes, the cresset burns in the owner's glow colour (emissive
##            only: embers, a flame card and a fake light on the nearby wood / cloth; 0 lights).
##   Capturing: the capturer's small banner climbs the pole (bottom -> just under the owner banner) and a ring round the
##            foot fills from the front in the capturer's colour.
## Footprint 4 x 4 m (the crown and banner stick out only above 5 m), height 9.65 m (vane), root origin = footprint centre on
## the ground. Budget (tavern budget): 6 draw instances (structure, banner, capture banner, flames, ring, contact
## decal), 5 shared materials (.tres next to this file, per-tower state = instance uniforms), 0 lights, no particles.
## The body keeps its front (door, pole, banner) toward the default camera (world +Z) whatever the root's yaw
## (`face_camera`), so the enemy-bank mirror towers read the same.
##
## Hooks (all safe before _ready; the state is applied when the model enters the tree):
##   set_owner_color(c: Variant)          Color = owned by that team colour, null = neutral. Animated (0.5 s).
##   set_capture(color: Variant, ratio)   capture progress 0-1 in the capturer's colour (the rising banner + ring);
##                                        null or ratio <= 0 = none. Calls at 1 Hz are smoothed (the display moves
##                                        continuously to the new value in ~1 s).
##   play_captured()                      the cresset flares, the banner pops, a ring pulse in the owner's colour.
##   set_selected(on: bool)               gold rim on the tower.
##   set_team_color(c)                    ignored (the point is neutral; kept for generic building code).
## Reads: is_owned(), get_owner_color() -> Variant, get_capture_color() -> Variant, get_capture_ratio() -> float
## (last set), get_displayed_capture() -> float, get_beacon_point() -> Vector3, get_banner_point() -> Vector3,
## static glow_for(team_color) -> Color.

const MESH := preload("res://art/buildings/capture/watchtower/watchtower_mesh.gd")
const MAT: Material = preload("res://art/buildings/capture/watchtower/watchtower_mat.tres")
const BANNER_MAT: Material = preload("res://art/buildings/capture/watchtower/watchtower_banner_mat.tres")
const FLAME_MAT: Material = preload("res://art/buildings/capture/watchtower/watchtower_flame_mat.tres")
const RING_MAT: Material = preload("res://art/buildings/capture/watchtower/watchtower_ring_mat.tres")
const CONTACT_MAT: Material = preload("res://art/buildings/capture/watchtower/watchtower_contact_mat.tres")

const FOOTPRINT := Vector2(4.0, 4.0)
const HEIGHT := 9.65
const NEUTRAL := Color(0.55, 0.54, 0.50)
const BANNER_SIZE := Vector2(1.25, 2.25)
const CAPTURE_SIZE := Vector2(0.9, 1.55)
const BANNER_X := 0.14          # banner left edge, right of the pole axis
const CAPTURE_LOW := 1.75       # capture banner top (y) at ratio 0
const CAPTURE_HIGH := 5.0       # at ratio 1: just under the owner banner
const UPDATE_INTERVAL := 1.0    # expected time between set_capture calls (CapturePoints runs at 1 Hz)
const GLOW_ENERGY := 2.7
const FLARE_TIME := 1.2
const BURST_TIME := 1.1
const CONTACT_SIZE := 8.6
const RIM_BURST_COLOR := Color(1.0, 0.86, 0.55)
## [team colour, glow colour]: art-keep.md 0.2, Unit.KINGDOM_COLORS and UIStyle.KINGDOM_COLORS. Others: glow_for().
const TEAM_GLOWS: Array = [
	[Color(0.85, 0.30, 0.12), Color(1.00, 0.55, 0.15)],
	[Color(1.00, 0.55, 0.15), Color(1.00, 0.60, 0.20)],
	[Color(0.42, 0.22, 0.60), Color(0.70, 0.30, 1.00)],
	[Color(0.66, 0.36, 1.00), Color(0.72, 0.42, 1.00)],
	[Color(0.45, 0.75, 0.95), Color(0.75, 0.92, 1.00)],
	[Color(0.45, 0.75, 1.00), Color(0.75, 0.92, 1.00)],
	[Color(0.62, 0.86, 1.00), Color(0.78, 0.93, 1.00)],
	[Color(0.35, 0.70, 0.25), Color(0.75, 1.00, 0.40)],
	[Color(0.45, 0.80, 0.35), Color(0.75, 1.00, 0.40)],
	[Color(0.52, 0.85, 0.30), Color(0.78, 1.00, 0.45)],
]

static var _plane_cache: Dictionary = {}

## Keep the body's front toward world +Z (the default camera) whatever the root's yaw.
@export var face_camera: bool = true

var _body: Node3D
var _structure: MeshInstance3D
var _banner: MeshInstance3D
var _cap_banner: MeshInstance3D
var _flames: MeshInstance3D
var _ring: MeshInstance3D
var _contact: MeshInstance3D

var _ready_done: bool = false
var _owned: bool = false
var _owner_color: Color = NEUTRAL
var _glow_target: Color = Color(1.0, 0.55, 0.15)
var _cloth_shown: Color = NEUTRAL
var _glow_shown: Color = Color(1.0, 0.55, 0.15)
var _own_k: float = 0.0
var _glow_k: float = 0.0
var _cap_on: bool = false
var _cap_color: Color = NEUTRAL
var _cap_target: float = 0.0
var _cap_shown: float = 0.0
var _cap_speed: float = 0.5
var _selected: bool = false
var _sel_k: float = 0.0
var _flare: float = 0.0
var _burst: float = 0.0
var _burst_color: Color = RIM_BURST_COLOR
var _phase: float = 0.0
## G-B neutral (Ultra only): the lit cresset's real light in the owner's glow colour (null at Low / neutral art).
var _beacon_light: NeutralFlickerLight


func _ready() -> void:
	if _ready_done:
		return
	_ready_done = true
	_phase = randf() * TAU
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	_structure = _mesh_node("Structure", MESH.structure(), MAT, true)
	_contact = _mesh_node("ContactDecal", _plane(CONTACT_SIZE), CONTACT_MAT, false)
	_contact.position.y = 0.02
	_ring = _mesh_node("CaptureRing", MESH.ring(), RING_MAT, false)
	_ring.position.y = 0.05
	_banner = _mesh_node("Banner", MESH.banner(BANNER_SIZE), BANNER_MAT, true)
	_banner.position = MESH.POLE + Vector3(BANNER_X, MESH.CROSSBAR_Y - 0.04, 0.0)
	_cap_banner = _mesh_node("CaptureBanner", MESH.banner(CAPTURE_SIZE), BANNER_MAT, false)
	_cap_banner.position = MESH.POLE + Vector3(BANNER_X, CAPTURE_LOW, 0.0)
	_flames = _mesh_node("Flames", MESH.flames(), FLAME_MAT, false)
	NeutralBuildingLook.set_detail(MAT)
	_beacon_light = NeutralBuildingLook.add_light(_body, "BeaconLight", MESH.FLAME_BASE + Vector3(0, 0.55, 0),
		_glow_target, 2.4, 9.0, 0.28, 1.3)
	_banner.set_instance_shader_parameter(&"phase", _phase)
	_banner.set_instance_shader_parameter(&"rod", 0.0)
	_cap_banner.set_instance_shader_parameter(&"phase", _phase + 2.1)
	_cap_banner.set_instance_shader_parameter(&"rod", 1.0)
	_cap_banner.set_instance_shader_parameter(&"owner_k", 1.0)
	# State set before _ready shows at once (no transition).
	_own_k = 1.0 if _owned else 0.0
	_glow_k = _own_k
	_cloth_shown = _owner_color if _owned else NEUTRAL
	_glow_shown = _glow_target
	_cap_shown = _cap_target
	_sel_k = 1.0 if _selected else 0.0
	_apply()
	set_notify_transform(true)
	_align_body()
	set_process(_animating())


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED or what == NOTIFICATION_ENTER_TREE:
		_align_body()


func _process(delta: float) -> void:
	# Ownership: cloth blends from grey to the owner's colour (or back), the cresset ignites / dies.
	var own_t: float = 1.0 if _owned else 0.0
	_own_k = move_toward(_own_k, own_t, delta / 0.5)
	if _owned:
		_cloth_shown = _cloth_shown.lerp(_owner_color, 1.0 - exp(-delta * 6.0)) if _own_k > 0.05 else _owner_color
		_glow_shown = _glow_shown.lerp(_glow_target, 1.0 - exp(-delta * 6.0)) if _glow_k > 0.05 else _glow_target
	_glow_k = move_toward(_glow_k, own_t, delta / (0.9 if _owned else 0.7))
	# Capture progress: constant-speed chase of the last value (smooth between 1 Hz updates).
	_cap_shown = move_toward(_cap_shown, _cap_target, _cap_speed * delta)
	_sel_k = move_toward(_sel_k, 1.0 if _selected else 0.0, delta / (0.15 if _selected else 0.25))
	_flare = maxf(_flare - delta / FLARE_TIME, 0.0)
	_burst = maxf(_burst - delta / BURST_TIME, 0.0)
	_apply()
	if not _animating():
		set_process(false)


# ------------------------------------------------------------------------------------------------ hooks

## `c` = the owning team's colour (Color) or null (neutral). Safe before _ready.
func set_owner_color(c: Variant) -> void:
	if c is Color:
		var col: Color = c
		var was: bool = _owned
		_owned = true
		_owner_color = col
		_glow_target = glow_for(col)
		if not was:
			_cloth_shown = col
			_glow_shown = _glow_target
		# The capturer's banner reached the top: it becomes the owner banner (no slide back down).
		if _cap_shown > 0.5 and _cap_color.is_equal_approx(col):
			_cap_on = false
			_cap_target = 0.0
			_cap_shown = 0.0
		if _burst > 0.0:
			_burst_color = col
	else:
		_owned = false
	_kick()


## Capture progress `ratio` (0-1) by the team of `color`; null or ratio <= 0 = no capture (the banner slides down).
## Safe before _ready.
func set_capture(color: Variant, ratio: float) -> void:
	var r: float = clampf(ratio, 0.0, 1.0)
	if color is Color and r > 0.0:
		var col: Color = color
		if _cap_shown > 0.0 and not _cap_color.is_equal_approx(col):
			_cap_shown = 0.0   # another team starts from the bottom
		_cap_color = col
		_cap_on = true
		_cap_target = r
	else:
		_cap_on = false
		_cap_target = 0.0
	_cap_speed = maxf(absf(_cap_target - _cap_shown) / UPDATE_INTERVAL, 0.15)
	if not _ready_done:
		_cap_shown = _cap_target
	_kick()


## The point was just captured: the cresset flares, the banner pops, a ring pulse in the owner's colour.
func play_captured() -> void:
	_flare = 1.0
	_burst = 1.0
	if _cap_on and _cap_shown > 0.5:
		_burst_color = _cap_color
	elif _owned:
		_burst_color = _owner_color
	else:
		_burst_color = RIM_BURST_COLOR
	_kick()


func set_selected(on: bool) -> void:
	_selected = on
	_kick()


## The point is neutral: team colours are ignored (kept so generic building code can call it).
func set_team_color(_c: Color) -> void:
	pass


func is_owned() -> bool:
	return _owned


func get_owner_color() -> Variant:
	return _owner_color if _owned else null


func get_capture_color() -> Variant:
	return _cap_color if _cap_on else null


## The last capture ratio set (0 when none).
func get_capture_ratio() -> float:
	return _cap_target


## The capture ratio the banner / ring show right now (chases get_capture_ratio()).
func get_displayed_capture() -> float:
	return _cap_shown


## World position of the cresset fire (VFX anchor).
func get_beacon_point() -> Vector3:
	return _to_world(MESH.FLAME_BASE + Vector3(0, 0.25, 0))


## World position of the owner banner's centre.
func get_banner_point() -> Vector3:
	return _to_world(MESH.POLE + Vector3(BANNER_X + BANNER_SIZE.x * 0.5, MESH.CROSSBAR_Y - BANNER_SIZE.y * 0.5, 0))


## The cresset's glow colour for a team colour: the kingdom glow of art-keep.md 0.2 when it is a known kingdom colour,
## else the same hue made bright.
static func glow_for(team: Color) -> Color:
	var best: float = 0.06
	var out: Variant = null
	for pair: Array in TEAM_GLOWS:
		var tc: Color = pair[0]
		var d: float = Vector3(tc.r - team.r, tc.g - team.g, tc.b - team.b).length()
		if d < best:
			best = d
			out = pair[1]
	if out is Color:
		return out
	return Color.from_hsv(team.h, clampf(team.s * 0.8, 0.2, 1.0), 1.0)


# ------------------------------------------------------------------------------------------------ internals

func _kick() -> void:
	if _ready_done:
		set_process(true)


func _animating() -> bool:
	var own_t: float = 1.0 if _owned else 0.0
	return _own_k != own_t or _glow_k != own_t or _cap_shown != _cap_target or _flare > 0.0 or _burst > 0.0 \
		or _sel_k != (1.0 if _selected else 0.0) or (_owned and not _cloth_shown.is_equal_approx(_owner_color)) \
		or (_owned and not _glow_shown.is_equal_approx(_glow_target))


func _mesh_node(nm: String, mesh: Mesh, mat: Material, shadow: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(mi)
	return mi


static func _plane(size: float) -> PlaneMesh:
	if not _plane_cache.has(size):
		var p := PlaneMesh.new()
		p.size = Vector2(size, size)
		_plane_cache[size] = p
	return _plane_cache[size]


func _to_world(local: Vector3) -> Vector3:
	var xf: Transform3D = _body.global_transform if _body and _body.is_inside_tree() else (
		global_transform if is_inside_tree() else transform)
	return xf * local


func _align_body() -> void:
	if not _ready_done or not is_inside_tree() or not face_camera:
		return
	var gb: Basis = global_transform.basis
	var want := Basis.IDENTITY.scaled(gb.get_scale())
	if not _body.global_basis.is_equal_approx(want):
		_body.global_basis = want


func _apply() -> void:
	if not _ready_done:
		return
	var ign: float = ease(_glow_k, 0.7)
	var energy: float = GLOW_ENERGY * ign * (1.0 + 1.3 * _flare * _flare)
	var flash: float = _flare * _flare * 0.55
	_structure.set_instance_shader_parameter(&"owner_color", _cloth_shown)
	_structure.set_instance_shader_parameter(&"owner_k", _own_k)
	_structure.set_instance_shader_parameter(&"glow_color", _glow_shown)
	_structure.set_instance_shader_parameter(&"glow_energy", energy)
	_structure.set_instance_shader_parameter(&"select_k", _sel_k)
	_structure.set_instance_shader_parameter(&"flash", flash)
	_banner.set_instance_shader_parameter(&"cloth_color", _cloth_shown)
	_banner.set_instance_shader_parameter(&"owner_k", _own_k)
	_banner.set_instance_shader_parameter(&"glow_color", _glow_shown)
	_banner.set_instance_shader_parameter(&"glow_energy", energy)
	_banner.set_instance_shader_parameter(&"flash", flash)
	# The banner pops (a quick stretch) when captured.
	var pop: float = sin(_flare * PI) * _flare * 0.14
	_banner.scale = Vector3(1.0 + pop * 0.5, 1.0 + pop, 1.0)
	_flames.visible = ign > 0.01
	if _beacon_light:
		_beacon_light.set_tint(_glow_shown)
		_beacon_light.set_level(ign * (1.0 + 1.2 * _flare), true)
	_flames.set_instance_shader_parameter(&"flame_color", _glow_shown)
	_flames.set_instance_shader_parameter(&"energy", energy)
	_flames.set_instance_shader_parameter(&"height_k", lerpf(0.25, 1.0, ign) * (1.0 + 0.6 * _flare))
	# Rising capture banner.
	var shown: bool = _cap_shown > 0.002
	_cap_banner.visible = shown
	if shown:
		var k: float = clampf(_cap_shown * 12.0, 0.05, 1.0)
		_cap_banner.position.y = lerpf(CAPTURE_LOW, CAPTURE_HIGH, _cap_shown)
		_cap_banner.scale = Vector3(k, k, 1.0)
		_cap_banner.set_instance_shader_parameter(&"cloth_color", _cap_color)
	# Ring: progress, or the captured pulse (grows and fades).
	_ring.visible = shown or _burst > 0.0
	if _ring.visible:
		if _burst > 0.0:
			_ring.set_instance_shader_parameter(&"ring_color", _burst_color)
			_ring.set_instance_shader_parameter(&"burst", _burst)
			_ring.set_instance_shader_parameter(&"ratio", 1.0)
			_ring.set_instance_shader_parameter(&"fade", 1.0)
			var s: float = 1.0 + (1.0 - _burst) * 0.9
			_ring.scale = Vector3(s, 1.0, s)
		else:
			_ring.set_instance_shader_parameter(&"ring_color", _cap_color)
			_ring.set_instance_shader_parameter(&"burst", 0.0)
			_ring.set_instance_shader_parameter(&"ratio", _cap_shown)
			_ring.set_instance_shader_parameter(&"fade", clampf(_cap_shown * 25.0, 0.0, 1.0))
			_ring.scale = Vector3.ONE
