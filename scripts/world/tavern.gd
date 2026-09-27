class_name Tavern
extends StaticBody3D
## A neutral tavern on Crown Hollow (docs/design/champions.md section 2): where champions are hired.
## Team NEUTRAL, invulnerable and never a target: it is in neither "units" nor "buildings", so no unit,
## spell or bot ever picks it (like the Ruin Peddler). Group "taverns"; clickable (collision layer 2:
## the UI opens the tavern window on a click, `_in_group_upwards(collider, "taverns")`).
## Its 6 x 6 m body (layer 1) blocks the build grid (BuildGrid's obstacle probe) and the navmesh: add it
## under the NavigationRegion3D before the bake. The body is turned so its front (local +Z, the door)
## faces the map centre; the door point is DOOR_DISTANCE in front of the centre (spot x 0.8 on Crown Hollow).
## - Closed until `open_time` (2:00) of match time (`match_time_source`, else its own age); `opened` fires once.
## - Rest: champions heal 2 % max HP / s within REST_RADIUS of `door_position()`; the Champion does it
##   itself (Champion.is_at_rest_spot reads the "taverns" group), the tavern only gives the door.
## - Held: `is_held_by_enemy_of(team)` when an enemy soldier / wizard / champion is within HOLD_RADIUS of
##   the door and none of `team`'s (workers never count, neutral units neither).
## Look: res://art/buildings/tavern/tavern_model.tscn (front = local +Z, footprint 6 x 6 centred on the
## origin) if it exists, else a code placeholder (stone base, timber walls, roof, glowing lantern sign).

signal opened(tavern: Tavern)

const FOOTPRINT := 6.0                  ## Metres (6 x 6).
const BODY_HEIGHT := 4.0                ## Collider height (the probe of BuildGrid sits at 0.15-2.15 m).
const DOOR_DISTANCE := 5.0              ## From the centre along the front: (-15, -15) -> (-11.5, -11.5); just outside the art's door corner (4.24 m) and its navmesh margin.
const OPEN_TIME := 120.0                ## 2:00 of match time.
const REST_RADIUS := 8.0                ## Champion rest around the door (applied by the Champion).
const HOLD_RADIUS := 12.0
const HOLD_CACHE_TIME := 0.25           ## is_held_by_enemy_of() rescans at most 4 times per second.
const LANTERN_COLOR := Color(1.0, 0.8, 0.4)
const ART_PATH := "res://art/buildings/tavern/tavern_model.tscn"

## Tavern window line while closed (champions.md section 2).
const MSG_CLOSED := "The tavern opens at 2:00"
## At 2:00 (the level shows them once, together).
const MSG_OPEN := "The taverns open their doors"
const HINT_HIRE := "Y: hire champions"

const NEUTRAL_TEAM := 2   # Unit.Team.NEUTRAL

var team: int = NEUTRAL_TEAM
var display_name := "Tavern"
## Seconds of match time at which it opens. Tests / scripted missions may change it before or during play.
@export var open_time := OPEN_TIME
## Returns the match time in seconds (the skirmish passes its match_time). Unset: this tavern's own age.
var match_time_source: Callable

var _age := 0.0
var _open := false
var _held_cache := {}    # team -> [physics frame, bool]


func _ready() -> void:
	add_to_group("taverns")
	collision_layer = 1 | 2   # 1: blocks units, build grid and navmesh; 2: clicks find it
	collision_mask = 0
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(FOOTPRINT, BODY_HEIGHT, FOOTPRINT)
	col.shape = box
	col.position = Vector3(0.0, BODY_HEIGHT * 0.5, 0.0)
	col.rotation.y = -PI / 4.0   # the art's house stands square on the grid inside the rotated root (9.V6)
	add_child(col)
	if ResourceLoader.exists(ART_PATH):
		var scene := load(ART_PATH) as PackedScene
		var art := scene.instantiate() as Node3D if scene else null
		if art:
			art.name = "Art"
			add_child(art)
			if art.has_method(&"set_open"):
				art.call(&"set_open", false)
				opened.connect(func(_t: Node) -> void: art.call(&"set_open", true))
			return
	_build_placeholder()


func _physics_process(delta: float) -> void:
	_age += delta
	if not _open and match_time() >= open_time:
		_open = true
		opened.emit(self)
		set_physics_process(false)   # nothing else to tick


# ---------------------------------------------------------------- public

func is_tavern() -> bool:
	return true


## Always true: it can't be destroyed (callers that check targets read is_targetable()).
func is_alive() -> bool:
	return true


## Never a target (not in "units" / "buildings" either).
func is_targetable() -> bool:
	return false


func is_invulnerable() -> bool:
	return true


## Invulnerable: damage is ignored.
func take_damage(_amount: float, _attacker: Node3D = null) -> void:
	pass


## Seconds of match time (match_time_source, else this tavern's age).
func match_time() -> float:
	return float(match_time_source.call()) if match_time_source.is_valid() else _age


## True from open_time (2:00) on.
func is_open() -> bool:
	return match_time() >= open_time


## Seconds until it opens (0 once open).
func time_until_open() -> float:
	return maxf(0.0, open_time - match_time())


## Where hired champions walk out and where they rest (y = 0): DOOR_DISTANCE in front of the centre.
func door_point() -> Vector3:
	var p := global_transform * Vector3(0.0, 0.0, DOOR_DISTANCE)
	return Vector3(p.x, 0.0, p.z)


## Same as door_point() (the name Champion.tavern_door() looks for).
func door_position() -> Vector3:
	return door_point()


## The 6 x 6 footprint as world x / z (axis-aligned bounds of the turned body: the minimap square).
func footprint_rect() -> Rect2:
	var half := FOOTPRINT * 0.5
	return Rect2(Vector2(global_position.x - half, global_position.z - half), Vector2(FOOTPRINT, FOOTPRINT))


## True when an enemy of `for_team` (a soldier, wizard or champion of the other side; never a worker or a
## neutral unit) is within HOLD_RADIUS of the door and none of `for_team`'s is (champions.md section 2).
func is_held_by_enemy_of(for_team: int) -> bool:
	var frame := Engine.get_physics_frames()
	var cached: Variant = _held_cache.get(for_team)
	if cached is Array and frame - int(cached[0]) < int(HOLD_CACHE_TIME * Engine.physics_ticks_per_second):
		return bool(cached[1])
	var held := _scan_held(for_team)
	_held_cache[for_team] = [frame, held]
	return held


## Shortcut for the tavern window: held by the enemy of `for_team` (default the player).
func held_by_enemy(for_team: int = 0) -> bool:
	return is_held_by_enemy_of(for_team)


## Clicks select nothing here (the UI opens the tavern window instead); kept so selection code can call it.
func set_selected(_value: bool) -> void:
	pass


## Flat distance from `pos` to the door.
func distance_to_door(pos: Vector3) -> float:
	var d := door_point()
	return Vector2(pos.x - d.x, pos.z - d.z).length()


## Every tavern in the current scene (group "taverns").
static func all() -> Array:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.get_nodes_in_group("taverns") if tree else []


## True when at least one tavern of the scene is open.
static func any_open() -> bool:
	for t in all():
		if t.has_method(&"is_open") and bool(t.call(&"is_open")):
			return true
	return false


# ---------------------------------------------------------------- internals

func _scan_held(for_team: int) -> bool:
	var enemy_near := false
	var door := door_point()
	var r2 := HOLD_RADIUS * HOLD_RADIUS
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or not u.is_alive() or u.is_worker():
			continue
		var t := int(u.team)
		if t == NEUTRAL_TEAM:
			continue
		var dx := u.global_position.x - door.x
		var dz := u.global_position.z - door.z
		if dx * dx + dz * dz > r2:
			continue
		if t == for_team:
			return false   # one of yours is there: not held
		enemy_near = true
	return enemy_near


## A timber-and-stone inn: stone base, timber walls, a pitched roof, a dark door on the front (+Z) and a
## hanging lantern sign that glows (no light node: the budget allows 0 lights here).
func _build_placeholder() -> void:
	var base := BoxMesh.new()
	base.size = Vector3(5.8, 1.0, 5.8)
	_mesh(base, Color(0.40, 0.42, 0.36), Vector3(0.0, 0.5, 0.0))
	var walls := BoxMesh.new()
	walls.size = Vector3(5.2, 2.6, 5.2)
	_mesh(walls, Color(0.52, 0.36, 0.20), Vector3(0.0, 2.3, 0.0))
	var roof := PrismMesh.new()
	roof.size = Vector3(6.4, 2.2, 6.0)
	_mesh(roof, Color(0.30, 0.34, 0.22), Vector3(0.0, 4.7, 0.0))
	var door := BoxMesh.new()
	door.size = Vector3(1.3, 2.0, 0.12)
	_mesh(door, Color(0.22, 0.14, 0.08), Vector3(0.0, 1.0, 2.62))
	var post := BoxMesh.new()
	post.size = Vector3(0.12, 0.12, 1.1)
	_mesh(post, Color(0.25, 0.17, 0.10), Vector3(1.4, 3.2, 3.1))
	var orb := SphereMesh.new()
	orb.radius = 0.24
	orb.height = 0.48
	var lantern := _mesh(orb, LANTERN_COLOR, Vector3(1.4, 2.85, 3.55))
	var mat := lantern.material_override as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = LANTERN_COLOR
	mat.emission_energy_multiplier = 2.0
	lantern.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _mesh(mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi
