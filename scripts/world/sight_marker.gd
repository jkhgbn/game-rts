class_name SightMarker
extends Node3D
## A temporary point of vision for one team (docs/design/champions.md section 13): the Wayfinder's
## Flare Arrow, scouting effects... Group "fog_sources": FogOfWar stamps a circle of `sight_radius`
## around it for `team` on every pass, like a unit. It frees itself after `lifetime` seconds
## (lifetime <= 0 = stays until something frees it). Invisible (no mesh).

## The team that sees (Unit.Team: PLAYER 0, ENEMY 1; NEUTRAL has no fog).
@export var team: int = 0
## Metres of vision around the marker.
@export var sight_radius := 8.0
## Seconds before it frees itself; <= 0 = permanent.
@export var lifetime := 6.0

var _left := 0.0


## A new marker at `pos` under `parent` (default: the current scene). Returns it (in the tree).
static func spawn(for_team: int, pos: Vector3, radius: float, seconds: float, parent: Node = null) -> SightMarker:
	if parent == null:
		var tree := Engine.get_main_loop() as SceneTree
		if tree == null:
			return null
		parent = tree.current_scene if tree.current_scene else tree.root
	var marker := SightMarker.new()
	marker.name = "SightMarker"
	marker.team = for_team
	marker.sight_radius = radius
	marker.lifetime = seconds
	marker.position = pos
	parent.add_child(marker, true)
	marker.global_position = pos
	return marker


func _ready() -> void:
	add_to_group("fog_sources")
	_left = lifetime
	set_physics_process(lifetime > 0.0)


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		remove_from_group("fog_sources")   # the next fog pass already ignores it
		set_physics_process(false)
		queue_free()


## False once it has run out (FogOfWar skips sources whose is_alive() is false).
func is_alive() -> bool:
	return lifetime <= 0.0 or _left > 0.0


## Seconds before it disappears (INF when permanent).
func time_left() -> float:
	return INF if lifetime <= 0.0 else maxf(_left, 0.0)
