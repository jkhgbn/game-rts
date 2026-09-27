class_name CapturePoint
extends Node3D
## A capturable point of the map (docs/design/map-fill.md 4, contract section 13): a Watchtower, an Essence well or a
## Wayshrine. Team NEUTRAL, invulnerable and never a target: in neither "units" nor "buildings", so no unit, spell,
## tower or bot picks it (like the trading posts). Group "capture_points"; clickable (collision layer 2).
## The rules run in CapturePoints (scripts/world/capture_points.gd, the service): it counts the presence once per
## second and calls `update_capture` 4 times per second; this node keeps the state, owns the watchtower's sight and
## forwards everything to its model. Set `kind`, `point_id` and `display_name` before it enters the tree.
## - Watchtower: 4 x 4 m body (layer 1 + 2, 1.8 m tall: blocks the build grid and the navmesh bake when it is under
##   the NavigationRegion3D), capture radius 7, 12 s; its owner gets a permanent SightMarker (sight 22).
## - Essence well: 3 x 3 m body, radius 6, 15 s (income and mana are paid by the service).
## - Wayshrine: no footprint (a layer-2 Area3D for clicks only; units walk through), radius 6, 8 s. Asleep until the
##   service wakes it; only an awake shrine can be captured; the capture grants the blessing and puts it to sleep
##   (it shows the capturer's colour until it wakes again, then turns neutral).
## Capture rules (4.3): a team present alone moves the progress by `rate / capture_time` per second, rate
## `min(1 + 0.25 x (n - 1), 1.75)` (n = presence, a wizard counts 2), x1.25 time on the other team's bank; an enemy-
## owned point is first neutralised then captured (full time each); both teams present = contested (frozen); nobody =
## decays 10 % per second. A team present alone on a point where the other team has partial progress first drains
## that progress at its own rate. The owner alone lets the other team's partial progress decay.
## Look: the model scenes of ART_PATHS (hooks `set_owner_color(c)`, `set_capture(color, ratio)`, `set_selected(bool)`,
## watchtower `play_captured()`, shrine `set_state(state)` / `play_blessing(color)`, well `play_pulse()`), else a
## small code placeholder. VFX through the group "mapfill_vfx" (`play(id, at, target)`) when it exists.

signal owner_changed(point: Node3D, new_team: int, old_team: int)
signal progress_changed(point: Node3D, team: int, ratio: float)
signal awakened(point: Node3D)
signal blessing_granted(point: Node3D, team: int)

const WATCHTOWER := &"watchtower"
const WELL := &"well"
const SHRINE := &"shrine"
## kind -> {radius (capture), time (s, 1 unit), footprint (m, square; 0 = none), clearing (decor radius)}.
const KIND_DATA := {
	&"watchtower": {"radius": 7.0, "time": 12.0, "footprint": 4.0, "clearing": 4.0},
	&"well": {"radius": 6.0, "time": 15.0, "footprint": 3.0, "clearing": 3.5},
	&"shrine": {"radius": 6.0, "time": 8.0, "footprint": 0.0, "clearing": 3.0},
}
const ART_PATHS := {
	&"watchtower": "res://art/buildings/capture/watchtower/watchtower.tscn",
	&"well": "res://art/buildings/capture/essence_well/essence_well.tscn",
	&"shrine": "res://art/buildings/capture/wayshrine/wayshrine.tscn",
}
const TOWER_SIGHT := 22.0
const FAR_BANK_FACTOR := 1.25        ## Capture time x this on the other team's bank.
const RATE_PER_EXTRA := 0.25         ## Rate + this per presence above 1.
const RATE_CAP := 1.75
const DECAY_PER_SECOND := 0.10       ## Abandoned progress falls this much (of the full bar) per second.
const BODY_HEIGHT := 1.8             ## <= 1.8 m: no navmesh island on top (step12-agent-rules 9).
const SHRINE_CLICK_RADIUS := 1.2
const SHRINE_CLICK_HEIGHT := 2.4
const PLAYER_TEAM := 0
const ENEMY_TEAM := 1
const NEUTRAL_TEAM := 2   # Unit.Team.NEUTRAL

const STATE_IDLE := &"idle"
const STATE_CAPTURING := &"capturing"
const STATE_NEUTRALISING := &"neutralising"
const STATE_CONTESTED := &"contested"
const STATE_ASLEEP := &"asleep"
const STATE_AWAKE := &"awake"

## Stable id (&"tower_nw", &"well_w", &"shrine_e"...).
@export var point_id: StringName = &""
## &"watchtower", &"well" or &"shrine".
@export var kind: StringName = WATCHTOWER
@export var display_name := "Watchtower"

var team: int = NEUTRAL_TEAM
## The owning team (PLAYER 0 / ENEMY 1), -1 = neutral.
var owner_team: int = -1
## The team whose progress `progress` is (-1 = none).
var capture_team: int = -1
## 0-1 progress of `capture_team` toward the next state (neutral, then owned).
var progress: float = 0.0
var capture_radius: float = 7.0
var capture_time: float = 12.0
var state: StringName = STATE_IDLE
## The bank the point stands on (RiverSystem.bank_of: PLAYER / ENEMY, -1 = isle / no river). Set by the service.
var bank: int = -1

var _awake := false
var _wake_at := INF          # match time of the next waking (shrines; INF = unknown / awake)
var _now := 0.0              # match time at the last service tick
var _selected := false
var _art: Node3D
var _placeholder_flag: MeshInstance3D
var _placeholder_glow: MeshInstance3D
var _sight: Node3D           # the owner's SightMarker (watchtowers)
var _body: CollisionObject3D


func _ready() -> void:
	add_to_group("capture_points")
	var data: Dictionary = KIND_DATA.get(kind, KIND_DATA[WATCHTOWER])
	capture_radius = float(data["radius"])
	capture_time = float(data["time"])
	state = STATE_ASLEEP if kind == SHRINE and not _awake else STATE_IDLE
	_build_body(float(data["footprint"]))
	var path: String = ART_PATHS.get(kind, "")
	if path != "" and ResourceLoader.exists(path):
		var scene := load(path) as PackedScene
		_art = scene.instantiate() as Node3D if scene else null
		if _art:
			_art.name = "Art"
			add_child(_art)
	if _art == null:
		_build_placeholder()
	_apply_look()


# ---------------------------------------------------------------- public (contract)

## Always true: it can't be destroyed.
func is_alive() -> bool:
	return true


## Never a target.
func is_targetable() -> bool:
	return false


func is_invulnerable() -> bool:
	return true


## Invulnerable: damage is ignored.
func take_damage(_amount: float = 0.0, _attacker: Node3D = null) -> void:
	pass


func is_capture_point() -> bool:
	return true


## Both teams stand in the circle: progress frozen.
func is_contested() -> bool:
	return state == STATE_CONTESTED


## Shrines: seconds of match time until it wakes (INF when awake, or not a shrine, or not scheduled yet).
func time_until_awake() -> float:
	if kind != SHRINE or _awake or _wake_at == INF:
		return INF
	return maxf(0.0, _wake_at - _now)


## Shrines: true while awake (capturable). Towers and wells: always true.
func is_awake() -> bool:
	return kind != SHRINE or _awake


## The selection look of the model (the UI shows the point panel on a click).
func set_selected(value: bool) -> void:
	_selected = value
	_art_call(&"set_selected", [value])


## The footprint as world x / z (the minimap square); a shrine has none (a zero-size rect at its centre).
func footprint_rect() -> Rect2:
	var size := float((KIND_DATA.get(kind, KIND_DATA[WATCHTOWER]) as Dictionary)["footprint"])
	var half := size * 0.5
	return Rect2(Vector2(global_position.x - half, global_position.z - half), Vector2(size, size))


## Decor clearing radius around the point (4 tower, 3.5 well, 3 shrine).
func clearing_radius() -> float:
	return float((KIND_DATA.get(kind, KIND_DATA[WATCHTOWER]) as Dictionary)["clearing"])


## Flat distance from `pos` to the centre.
func flat_distance(pos: Vector3) -> float:
	return Vector2(pos.x - global_position.x, pos.z - global_position.z).length()


## The team the owner's sight belongs to (watchtowers; -1 when neutral or not a tower), and its radius.
func sight_team() -> int:
	return owner_team if kind == WATCHTOWER else -1


func sight_radius() -> float:
	return TOWER_SIGHT if kind == WATCHTOWER else 0.0


## The model (art scene or placeholder root), for VFX anchors.
func model() -> Node3D:
	return _art


## Seconds a team needs alone with presence `n` to move the bar from 0 to 1 here (far bank included).
func time_for(for_team: int, n: int = 1) -> float:
	return capture_time * _far_factor(for_team) / _rate(n)


# ---------------------------------------------------------------- service calls (CapturePoints only)

## One rules step (map-fill.md 4.3). `n_player` / `n_enemy`: presence counts (a wizard counts 2).
func update_capture(dt: float, n_player: int, n_enemy: int) -> void:
	var old_progress := progress
	var old_team := capture_team
	if kind == SHRINE and not _awake:
		progress = 0.0
		capture_team = -1
		state = STATE_ASLEEP
	elif n_player > 0 and n_enemy > 0:
		state = STATE_CONTESTED
	elif n_player > 0 or n_enemy > 0:
		var t := PLAYER_TEAM if n_player > 0 else ENEMY_TEAM
		var n := n_player if n_player > 0 else n_enemy
		if owner_team == t:
			_decay(dt)
			state = _rest_state()
		else:
			var step := _rate(n) / (capture_time * _far_factor(t)) * dt
			if capture_team != t and capture_team != -1 and progress > 0.0:
				progress = maxf(0.0, progress - step)   # drain the other team's partial progress first
				if progress <= 0.0:
					capture_team = -1
			else:
				capture_team = t
				progress = minf(1.0, progress + step)
			state = STATE_NEUTRALISING if owner_team != -1 else STATE_CAPTURING
			if capture_team == t and progress >= 1.0:
				_complete(t)
	else:
		_decay(dt)
		state = _rest_state()
	if not is_equal_approx(progress, old_progress) or capture_team != old_team:
		_art_call(&"set_capture", [_team_color_or_null(capture_team) if progress > 0.0 else null, progress])
		progress_changed.emit(self, capture_team, progress)


## Shrines: wake up (neutral again, capturable). Emits owner_changed when it was owned, then awakened.
func wake() -> void:
	if kind != SHRINE or _awake:
		return
	_awake = true
	_wake_at = INF
	progress = 0.0
	capture_team = -1
	state = STATE_AWAKE
	if owner_team != -1:
		_set_owner(-1)
	_art_call(&"set_state", [STATE_AWAKE])
	_play_vfx(&"shrine_awaken")
	awakened.emit(self)


## Shrines: sleep (keeps the owner colour). The service does not need it (a capture puts it to sleep itself).
func sleep() -> void:
	if kind != SHRINE:
		return
	_awake = false
	progress = 0.0
	capture_team = -1
	state = STATE_ASLEEP
	_art_call(&"set_state", [STATE_ASLEEP])
	_art_call(&"set_capture", [null, 0.0])


## Shrines: the schedule (match time of the next waking, INF = unknown) and the current match time.
func set_wake_time(at: float, now: float) -> void:
	_wake_at = at
	_now = now


## Wells: an income tick was paid (model pulse + VFX).
func play_pulse() -> void:
	_art_call(&"play_pulse", [])
	_play_vfx(&"well_pulse")


## Forces the owner (missions, tests, save games). Emits owner_changed; no messages, no blessing.
func set_owner_team(new_team: int) -> void:
	progress = 0.0
	capture_team = -1
	_art_call(&"set_capture", [null, 0.0])
	_set_owner(new_team if new_team == PLAYER_TEAM or new_team == ENEMY_TEAM else -1)


# ---------------------------------------------------------------- internals

func _rate(n: int) -> float:
	return minf(1.0 + RATE_PER_EXTRA * float(maxi(n, 1) - 1), RATE_CAP)


func _far_factor(for_team: int) -> float:
	if (bank == PLAYER_TEAM or bank == ENEMY_TEAM) and bank != for_team:
		return FAR_BANK_FACTOR
	return 1.0


func _decay(dt: float) -> void:
	if progress <= 0.0:
		return
	progress = maxf(0.0, progress - DECAY_PER_SECOND * dt)
	if progress <= 0.0:
		capture_team = -1


func _rest_state() -> StringName:
	if kind == SHRINE:
		return STATE_AWAKE if _awake else STATE_ASLEEP
	return STATE_IDLE


## The bar is full for team `t`: an enemy-owned point turns neutral, a neutral one becomes t's.
func _complete(t: int) -> void:
	progress = 0.0
	capture_team = -1
	if owner_team != -1 and owner_team != t:
		state = STATE_NEUTRALISING
		_set_owner(-1)
		return
	state = _rest_state()
	_set_owner(t)
	_play_vfx(&"capture_done")
	if kind == WATCHTOWER:
		_art_call(&"play_captured", [])
	elif kind == SHRINE and _awake:
		_art_call(&"play_blessing", [_team_color_or_null(t)])
		blessing_granted.emit(self, t)
		sleep()


func _set_owner(new_team: int) -> void:
	if new_team == owner_team:
		return
	var old := owner_team
	owner_team = new_team
	_update_sight()
	_apply_look()
	owner_changed.emit(self, new_team, old)


## Watchtowers: a permanent SightMarker (sight 22) for the owner, re-created on every owner change.
func _update_sight() -> void:
	if kind != WATCHTOWER:
		return
	if _sight and is_instance_valid(_sight):
		_sight.remove_from_group(&"fog_sources")
		_sight.queue_free()
	_sight = null
	if owner_team != PLAYER_TEAM and owner_team != ENEMY_TEAM or not is_inside_tree():
		return
	var marker := SightMarker.new()
	marker.name = "OwnerSight"
	marker.team = owner_team
	marker.sight_radius = TOWER_SIGHT
	marker.lifetime = 0.0
	add_child(marker)
	_sight = marker


## The owner's SightMarker (watchtowers), or null.
func sight_marker() -> Node3D:
	return _sight if _sight and is_instance_valid(_sight) else null


func _apply_look() -> void:
	var color: Variant = _team_color_or_null(owner_team)
	_art_call(&"set_owner_color", [color])
	if kind == SHRINE:
		_art_call(&"set_state", [STATE_AWAKE if _awake else STATE_ASLEEP])
	if _placeholder_flag:
		(_placeholder_flag.material_override as StandardMaterial3D).albedo_color = \
				color if color is Color else Color(0.55, 0.55, 0.55)
	if _placeholder_glow:
		_placeholder_glow.visible = kind != SHRINE or _awake


static func _team_color_or_null(t: int) -> Variant:
	if t == PLAYER_TEAM or t == ENEMY_TEAM:
		return Unit.team_color(t)
	return null


func _art_call(method: StringName, args: Array) -> void:
	if _art and is_instance_valid(_art) and _art.has_method(method):
		_art.callv(method, args)


func _play_vfx(id: StringName) -> void:
	if not is_inside_tree():
		return
	var vfx := get_tree().get_first_node_in_group(&"mapfill_vfx")
	if vfx and vfx.has_method(&"play"):
		vfx.call(&"play", id, global_position, self)


## Towers and wells: a square body on layers 1 + 2 (blocks units, the grid and the bake; clicks find it).
## Shrines: only a layer-2 Area3D for clicks (units walk through).
func _build_body(footprint: float) -> void:
	var col := CollisionShape3D.new()
	if footprint > 0.0:
		var body := StaticBody3D.new()
		body.name = "Body"
		body.collision_layer = 1 | 2
		body.collision_mask = 0
		var box := BoxShape3D.new()
		box.size = Vector3(footprint, BODY_HEIGHT, footprint)
		col.shape = box
		col.position = Vector3(0.0, BODY_HEIGHT * 0.5, 0.0)
		body.add_child(col)
		_body = body
	else:
		var area := Area3D.new()
		area.name = "ClickArea"
		area.collision_layer = 2
		area.collision_mask = 0
		area.monitoring = false
		area.monitorable = true
		area.input_ray_pickable = true
		var cyl := CylinderShape3D.new()
		cyl.radius = SHRINE_CLICK_RADIUS
		cyl.height = SHRINE_CLICK_HEIGHT
		col.shape = cyl
		col.position = Vector3(0.0, SHRINE_CLICK_HEIGHT * 0.5, 0.0)
		area.add_child(col)
		_body = area
	add_child(_body)


## A small code look when the model is missing: tower = stone stump + timber crown + flag, well = stone ring +
## violet glow, shrine = standing stone + floating rune stone (glows while awake). The flag / rune shows the owner.
func _build_placeholder() -> void:
	_art = Node3D.new()
	_art.name = "Placeholder"
	add_child(_art)
	var stone := Color(0.52, 0.50, 0.46)
	match kind:
		WATCHTOWER:
			var base := CylinderMesh.new()
			base.top_radius = 1.5
			base.bottom_radius = 1.9
			base.height = 6.0
			_mesh(base, stone, Vector3(0.0, 3.0, 0.0), true)
			var crown := BoxMesh.new()
			crown.size = Vector3(3.2, 1.6, 3.2)
			_mesh(crown, Color(0.45, 0.31, 0.18), Vector3(0.0, 6.8, 0.0), true)
			var roof := PrismMesh.new()
			roof.size = Vector3(3.6, 1.6, 3.6)
			_mesh(roof, Color(0.35, 0.24, 0.16), Vector3(0.0, 8.4, 0.0), true)
			var flag := BoxMesh.new()
			flag.size = Vector3(1.0, 0.7, 0.05)
			_placeholder_flag = _mesh(flag, Color(0.55, 0.55, 0.55), Vector3(1.9, 5.2, 1.9), false)
		WELL:
			var ring := CylinderMesh.new()
			ring.top_radius = 1.4
			ring.bottom_radius = 1.5
			ring.height = 0.9
			_mesh(ring, stone, Vector3(0.0, 0.45, 0.0), true)
			var mist := CylinderMesh.new()
			mist.top_radius = 1.1
			mist.bottom_radius = 1.1
			mist.height = 0.1
			_placeholder_glow = _mesh(mist, Color(0.62, 0.35, 0.95), Vector3(0.0, 0.85, 0.0), false)
			_emissive(_placeholder_glow, Color(0.62, 0.35, 0.95))
			var rune := BoxMesh.new()
			rune.size = Vector3(0.5, 0.25, 0.05)
			_placeholder_flag = _mesh(rune, Color(0.55, 0.55, 0.55), Vector3(0.0, 0.5, 1.5), false)
		_:
			var stand := BoxMesh.new()
			stand.size = Vector3(0.7, 1.3, 0.45)
			_mesh(stand, stone, Vector3(0.0, 0.65, 0.0), true)
			var rune := BoxMesh.new()
			rune.size = Vector3(0.45, 0.45, 0.12)
			_placeholder_flag = _mesh(rune, Color(0.55, 0.55, 0.55), Vector3(0.0, 1.6, 0.0), false)
			var glow := SphereMesh.new()
			glow.radius = 0.35
			glow.height = 0.7
			_placeholder_glow = _mesh(glow, Color(1.0, 0.72, 0.28), Vector3(0.0, 1.6, 0.0), false)
			_emissive(_placeholder_glow, Color(1.0, 0.72, 0.28))


func _mesh(mesh: Mesh, color: Color, pos: Vector3, shadow: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_art.add_child(mi)
	return mi


func _emissive(mi: MeshInstance3D, color: Color) -> void:
	var mat := mi.material_override as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.8
