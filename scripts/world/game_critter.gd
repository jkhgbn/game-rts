class_name GameCritter
extends Node3D
## A huntable game critter: red deer or rabbit (docs/design/map-fill.md 3.4, task 12.C10; contract section 13).
## NOT a Unit and NOT in "units" / "buildings": no auto-aggro, attack-move, tower / keep fire, area spell, Magpie
## or camp creature ever touches it. It answers the "attack targets" contract (`team` NEUTRAL, `is_alive()`,
## `take_damage(amount, attacker)`, `target_radius()`), so an explicit `command_attack(critter)` hunts it.
## Group "game_critters". Usually driven by a CritterHerds (scripts/world/critter_herds.gd, which calls think()
## at 5 Hz staggered, pays the reward and respawns it); with `herds == null` it drives itself (same rules, no
## reward, no respawn).
##
## Behaviour: grazes (deer: around the herd's graze centre; rabbits: hops within 6 m of home), flees when damaged
## or when a PLAYER / ENEMY unit comes within 4 m (deer) / 3 m (rabbit) AND that unit is visible to every team
## whose fog shows the critter's cell (never runs from a hidden unit in front of someone). Deer sprint 12 m toward
## the herd's graze spot farthest from the threat (then walk on to it), rabbits bolt 5 m. Never into water, never
## over a ford / bridge / onto the other bank (RiverSystem, group "river", when it exists). Navmesh path queries
## only when it moves, at most one per 4 s (else a short straight, navmesh-checked bolt). After a sprint, nearby
## units do not startle it again for RESTARTLE_TIME (damage always does). A critter nobody sees does not graze
## about. Nearby units come from its "AlertArea" (layer 0, mask 2): the fog is read only when one is that close.
## Fog: `set_seen()` (CritterHerds, from the local team's FogOfWar) hides it and turns its click area off, like an
## enemy unit. A hidden attacker that hurts it in a cell some team sees is revealed to that team (SightMarker
## r 2, 1 s).
## Model: res://art/units/neutral/critters/<kind>.tscn (CritterModel, faces +Z, child "Model"; this node moves
## and turns, never the model root). Hooks play_idle / play_move(speed) / play_flee / play_hit / play_death, then
## `death_finished` parks it (hidden) until respawn() calls revive(). A plain box stands in when the scene is missing.

## Emitted once at the killing blow. `team` = the killer's team (PLAYER / ENEMY), -1 when unknown.
signal hunted(critter: Node3D, team: int, by: Node)
## Emitted when a flee starts (not on every re-sprint of an ongoing flee).
signal fled(critter: Node3D)

const TEAM_PLAYER := 0     # Unit.Team.PLAYER
const TEAM_ENEMY := 1      # Unit.Team.ENEMY
const TEAM_NEUTRAL := 2    # Unit.Team.NEUTRAL

## Per kind (map-fill.md 3.4): HP, radius, graze / flee speed, flee distance, alert radius, idle pause range,
## wander radius, model scene, click shape.
const KINDS := {
	&"deer": {
		"name": "Red deer", "hp": 60.0, "radius": 0.5, "walk": 3.0, "flee": 7.0, "flee_dist": 12.0,
		"alert": 4.0, "idle_min": 6.0, "idle_max": 14.0, "wander": 3.0,
		"scene": "res://art/units/neutral/critters/deer.tscn",
		"click_size": Vector3(0.8, 1.6, 1.9), "click_y": 0.85,
	},
	&"rabbit": {
		"name": "Rabbit", "hp": 12.0, "radius": 0.25, "walk": 2.0, "flee": 6.0, "flee_dist": 5.0,
		"alert": 3.0, "idle_min": 4.5, "idle_max": 9.0, "wander": 6.0,
		"scene": "res://art/units/neutral/critters/rabbit.tscn",
		"click_size": Vector3(0.8, 0.8, 0.8), "click_y": 0.3,
	},
}
## Default reward per kind (CritterHerds.REWARDS mirrors it; step 15 may add &"food").
const DEFAULT_REWARDS := {&"deer": {&"essence": 5}, &"rabbit": {&"essence": 1}}
const PATH_QUERY_INTERVAL := 4.0   ## At most one navmesh path query per critter per 4 s (map-fill.md 9).
const THINK_INTERVAL := 0.2        ## 5 Hz logic.
const REVEAL_RADIUS := 2.0         ## Hidden-attacker rule: SightMarker r 2 for 1 s.
const REVEAL_TIME := 1.0
const CLICK_LAYER := 2
const DEATH_FALLBACK := 4.8        ## Parks the critter this long after death when the model has no death_finished.
const SIGHT_MARKER_PATH := "res://scripts/world/sight_marker.gd"
const NAV_TOLERANCE := 0.45        ## A straight bolt sample farther than this from the navmesh is blocked.
const TURN_RATE := 10.0
## After a sprint ends, nearby units do not startle it again for this long (damage always does), so a chasing
## melee hunter can catch up: a hit, a 12 m / 5 m sprint, a trot, the hunter closes in, the next hit...
const RESTARTLE_TIME := 3.0

@export var kind: StringName = &"deer"
## Deer only: the stag (antlers) or a hind. Set before it enters the tree.
@export var stag: bool = true

var team: int = TEAM_NEUTRAL
var display_name := ""
var max_hp := 60.0
var hp := 60.0
## Paid to the hunter's team through CritterHerds.grant(team, reward, by). Step 15 may add &"food".
var reward: Dictionary = {}
var radius := 0.5
var walk_speed := 3.0
var flee_speed := 7.0
var flee_distance := 12.0
var alert_radius := 4.0
var wander_radius := 3.0
## Rabbits wander around it; deer spawn there.
var home := Vector3.ZERO
## Deer: where it grazes now (the herd's spot, set by CritterHerds; after a flee: where it fled to).
var graze_center := Vector3.ZERO
## Deer: the herd's graze spots (flee targets). Rabbits: empty.
var graze_spots := PackedVector3Array()
var herd_id: StringName = &""
## PLAYER / ENEMY bank of its home (RiverSystem.bank_of), -1 = no river / unknown.
var bank: int = -1
## The CritterHerds driving it (null = it drives itself).
var herds: Node = null
## Who landed the killing blow (null while alive or unknown) and its team (-1).
var killer: Node = null
var killer_team: int = -1

var _alive := true
var _parked := false          # death animation over: hidden until respawn()
var _state: StringName = &"idle"   # idle / move / flee / dead
var _path := PackedVector3Array()
var _path_i := 0
var _sprint_left := 0.0
var _idle_left := 0.0
var _clock := 0.0
var _last_query := -100.0
var _think_left := 0.0
var _calm_left := 0.0
var _seen := true
var _death_serial := 0
var _model: Node3D
var _area: Area3D
var _alert: Area3D            # layer 0, mask 2: the physics engine tracks units within alert_radius
var _near: Array = []         # Units inside _alert (freed ones pruned in find_threat)
var _rng := RandomNumberGenerator.new()
var _reveal_times := {}       # "attacker id:team" -> _clock of the last marker
var _fog: FogOfWar
var _fog_checked := -100.0
var _river: Node
var _river_checked := -100.0
var _river_full := false      # the river has is_water / is_ford / is_bridge / bank_of

static var _scene_cache := {}
static var _lift_map := RID()
static var _lift := 0.0
static var _placeholder_mat: StandardMaterial3D


## Sets the kind and its numbers (call before add_child). `spots`: the deer herd's graze spots.
func setup(p_kind: StringName, p_home: Vector3, spots: PackedVector3Array = PackedVector3Array(),
		p_seed: int = 0) -> void:
	kind = p_kind if KINDS.has(p_kind) else &"deer"
	var k: Dictionary = KINDS[kind]
	display_name = String(k["name"])
	max_hp = float(k["hp"])
	hp = max_hp
	radius = float(k["radius"])
	walk_speed = float(k["walk"])
	flee_speed = float(k["flee"])
	flee_distance = float(k["flee_dist"])
	alert_radius = float(k["alert"])
	wander_radius = float(k["wander"])
	reward = (DEFAULT_REWARDS[kind] as Dictionary).duplicate()
	home = Vector3(p_home.x, p_home.y, p_home.z)
	graze_center = home
	graze_spots = spots
	position = home
	_rng.seed = p_seed if p_seed != 0 else absi(hash(Vector2(p_home.x, p_home.z))) + 1
	_idle_left = _rng.randf_range(0.5, float(k["idle_max"]))
	_clock = _rng.randf_range(0.0, PATH_QUERY_INTERVAL)   # staggers the first moves
	_last_query = -100.0


func _init() -> void:
	add_to_group("game_critters")


func _ready() -> void:
	add_to_group("game_critters")
	if display_name == "":
		setup(kind, position, graze_spots)
	global_position = _snap(global_position)   # on the ground, on the navmesh (no-op before the bake)
	_build_model()
	_build_click_area()
	_build_alert_area()
	_call_model(&"play_idle")
	_think_left = _rng.randf_range(0.0, THINK_INTERVAL)
	set_physics_process(herds == null)
	_seen = herds == null   # hidden until the herds' first fog read (no flash in an unseen cell)
	_apply_seen()


# ================================================================ attack-target contract

func is_alive() -> bool:
	return _alive


## How far from its centre an attacker may stand and still reach it: 0.5 deer / 0.25 rabbit.
func target_radius() -> float:
	return radius


func is_game_critter() -> bool:
	return true


## True while sprinting away (the first 12 m / 5 m of a flee).
func is_fleeing() -> bool:
	return _alive and _state == &"flee"


## `attacker`: the Unit (or anything with a `team`) that hit it. Armor 0. Flees from the attacker; at 0 HP it
## dies and emits `hunted` (the reward is paid by CritterHerds).
func take_damage(amount: float, attacker: Node3D = null) -> void:
	if not _alive or amount <= 0.0:
		return
	var src: Node3D = attacker if attacker != null and is_instance_valid(attacker) else null
	hp -= amount
	_reveal_attacker(src)
	if hp <= 0.0:
		_die(src)
		return
	_call_model(&"play_hit")
	var from: Vector3 = src.global_position if src != null else global_position \
			- global_transform.basis.z * 2.0
	flee_from(from)


# ================================================================ public

## Starts (or renews) a flee away from `from_pos`. A path already leading away is kept (no new query).
func flee_from(from_pos: Vector3) -> void:
	if not _alive or not is_inside_tree():
		return
	var away := global_position - from_pos
	away.y = 0.0
	if away.length() < 0.05:
		var a := _rng.randf() * TAU
		away = Vector3(cos(a), 0.0, sin(a))
	away = away.normalized()
	var was_fleeing := _state == &"flee"
	if (_state == &"move" or _state == &"flee") and _path_leads_away(away):
		_sprint_left = flee_distance
	else:
		var path := _flee_path(from_pos, away)
		if path.size() < 2:
			return   # cornered: it just flinches
		_set_path(path)
		_sprint_left = flee_distance
		if kind == &"deer":
			graze_center = path[path.size() - 1]
	_state = &"flee"
	_call_model(&"play_flee")
	set_physics_process(true)
	if not was_fleeing:
		fled.emit(self)


## Deer: the herd moved on; walk to `center` after up to `delay` s (unless fleeing).
func set_graze_center(center: Vector3, delay: float = 0.0) -> void:
	graze_center = center
	if _alive and _state == &"idle":
		_idle_left = minf(_idle_left, delay)


## True when it is dead and its death animation is over (hidden, ready for respawn()).
func can_respawn() -> bool:
	return not _alive and _parked


## Back to life at `at` with full HP (CritterHerds calls it in an unseen cell); revives the model.
func respawn(at: Vector3) -> void:
	_alive = true
	_parked = false
	_death_serial += 1
	hp = max_hp
	killer = null
	killer_team = -1
	_state = &"idle"
	_path.clear()
	_path_i = 0
	_sprint_left = 0.0
	_calm_left = 0.0
	_idle_left = _rng.randf_range(1.0, 4.0)
	if is_inside_tree():
		at = _snap(at)
		global_position = at
		reset_physics_interpolation()
	else:
		position = at
	if kind == &"deer":
		graze_center = at
	_call_model(&"revive")
	_call_model(&"play_idle")
	_near.clear()
	if _alert:
		_alert.set_deferred(&"monitoring", true)
	set_physics_process(herds == null)
	if herds != null:
		_seen = false   # respawns happen in unseen cells; the next fog read shows it when that changes
	_apply_seen()


## Local-team fog (CritterHerds at the fog's 5 Hz tick): hidden = not drawn and not clickable.
func set_seen(seen: bool) -> void:
	if seen == _seen:
		return
	_seen = seen
	_apply_seen()


## True when fog is on and neither PLAYER nor ENEMY sees its cell now.
func _nobody_sees() -> bool:
	var fog := _get_fog()
	if fog == null or not fog.enabled:
		return false
	var pos := global_position
	return not fog.is_visible(TEAM_PLAYER, pos) and not fog.is_visible(TEAM_ENEMY, pos)


## True when `for_team`'s fog shows its cell now (fog off / no fog / NEUTRAL: true).
func is_visible_to(for_team: int) -> bool:
	var fog := _get_fog()
	if fog == null or not fog.enabled:
		return true
	return fog.is_visible(for_team, global_position)


## The flee rule's visibility test: false when some team sees `critter_pos` but not `unit_pos` (fleeing would
## give that unit away). `fog` may be null (no fog: true).
static func threat_is_visible(fog: FogOfWar, critter_pos: Vector3, unit_pos: Vector3) -> bool:
	if fog == null or not fog.enabled:
		return true
	for t: int in [TEAM_PLAYER, TEAM_ENEMY]:
		if fog.is_visible(t, critter_pos) and not fog.is_visible(t, unit_pos):
			return false
	return true


## The nearest living PLAYER / ENEMY unit within alert_radius (4 m deer / 3 m rabbit) that passes
## threat_is_visible(), or null. The candidates come from the "AlertArea" (layer 0, mask 2: the physics
## engine tracks the units inside), so a critter with nobody around costs nothing and the fog is read only
## when a unit is that close.
func find_threat() -> Node3D:
	if _near.is_empty() or not is_inside_tree():
		return null
	var pos := global_position
	var fog := _get_fog()
	var best: Node3D = null
	var best_d := alert_radius
	for i: int in range(_near.size() - 1, -1, -1):
		var n: Variant = _near[i]
		if not is_instance_valid(n):
			_near.remove_at(i)
			continue
		var u := n as Unit
		if u == null or (u.team != TEAM_PLAYER and u.team != TEAM_ENEMY) or not u.is_alive():
			continue
		var up := u.global_position
		var d := Vector2(up.x - pos.x, up.z - pos.z).length()
		if d > best_d or not threat_is_visible(fog, pos, up):
			continue
		best = u
		best_d = d
	return best


## 5 Hz logic (CritterHerds calls it staggered; `dt` = time since the last call): threats, graze moves.
func think(dt: float) -> void:
	_clock += dt
	if not _alive or not is_inside_tree():
		return
	if _calm_left > 0.0:
		_calm_left -= dt
	elif _state != &"flee" and not _near.is_empty():
		var threat := find_threat()
		if threat != null:
			flee_from(threat.global_position)
			return
	if _state == &"idle":
		_idle_left -= dt
		if _idle_left <= 0.0 and _query_ready():
			_wander()


## Moves along the current path (physics frame; runs only while moving when a CritterHerds drives it).
func advance(delta: float) -> void:
	if not _alive or _path_i >= _path.size():
		if _alive and (_state == &"move" or _state == &"flee"):
			_arrive()
		return
	var sprinting := _sprint_left > 0.0
	var step: float = (flee_speed if sprinting else walk_speed) * delta
	if sprinting:
		_sprint_left -= step
		if _sprint_left <= 0.0:
			_sprint_left = 0.0
			_calm_left = RESTARTLE_TIME
			if _state == &"flee":
				_state = &"move"
				_call_model(&"play_move", [walk_speed])
	var pos := global_position
	var heading := Vector3.ZERO
	while step > 0.0 and _path_i < _path.size():
		var target := _path[_path_i]
		var d := target - pos
		var dist := d.length()
		if dist > 0.001:
			heading = d
		if dist <= step:
			pos = target
			step -= dist
			_path_i += 1
		else:
			pos += d / dist * step
			step = 0.0
	global_position = pos
	heading.y = 0.0
	if heading.length_squared() > 0.0001:
		var goal := atan2(heading.x, heading.z)
		if absf(angle_difference(rotation.y, goal)) > 0.01:
			rotation.y = lerp_angle(rotation.y, goal, clampf(delta * TURN_RATE, 0.0, 1.0))
	if _path_i >= _path.size():
		_arrive()


func state() -> StringName:
	return _state


func model() -> Node3D:
	return _model


# ================================================================ internals

func _physics_process(delta: float) -> void:
	if herds == null:
		_think_left -= delta
		if _think_left <= 0.0:
			_think_left += THINK_INTERVAL
			think(THINK_INTERVAL)
	if _alive and (_state == &"move" or _state == &"flee"):
		advance(delta)
	elif herds != null:
		set_physics_process(false)


func _die(src: Node3D) -> void:
	_alive = false
	hp = 0.0
	_state = &"dead"
	_path.clear()
	_path_i = 0
	_sprint_left = 0.0
	killer = src
	killer_team = -1
	if src != null:
		var t: Variant = src.get(&"team")
		if t != null and (int(t) == TEAM_PLAYER or int(t) == TEAM_ENEMY):
			killer_team = int(t)
	if _area:
		_area.collision_layer = 0
	if _alert:
		_alert.set_deferred(&"monitoring", false)
	_near.clear()
	set_physics_process(herds == null)
	_death_serial += 1
	if _model != null and _model.has_method(&"play_death") and _model.has_signal(&"death_finished"):
		_model.call(&"play_death")
	elif is_inside_tree():
		var serial := _death_serial
		get_tree().create_timer(DEATH_FALLBACK, false).timeout.connect(func() -> void:
			if serial == _death_serial:
				_on_death_finished())
	hunted.emit(self, killer_team, killer)


func _on_death_finished() -> void:
	if _alive:
		return
	_parked = true
	_apply_seen()


func _apply_seen() -> void:
	var show := _seen and not _parked
	if visible != show:
		visible = show
	if _area:
		var layer: int = CLICK_LAYER if show and _alive else 0
		if _area.collision_layer != layer:
			_area.collision_layer = layer


func _arrive() -> void:
	if _state == &"flee":
		_calm_left = RESTARTLE_TIME
	_state = &"idle"
	_sprint_left = 0.0
	_path.clear()
	_path_i = 0
	var k: Dictionary = KINDS[kind]
	_idle_left = _rng.randf_range(float(k["idle_min"]), float(k["idle_max"]))
	_call_model(&"play_idle")
	if herds != null:
		set_physics_process(false)


func _set_path(path: PackedVector3Array) -> void:
	_path = path
	_path_i = 1 if path.size() > 1 and Vector2(path[0].x - global_position.x,
			path[0].z - global_position.z).length() < 0.05 else 0


func _path_leads_away(away: Vector3) -> bool:
	if _path_i >= _path.size():
		return false
	var d := _path[_path_i] - global_position
	d.y = 0.0
	if d.length() < 0.3:
		if _path_i + 1 >= _path.size():
			return false
		d = _path[_path_i + 1] - global_position
		d.y = 0.0
	return d.length() > 0.3 and d.normalized().dot(away) > 0.25


## A graze move: deer back to / around the herd's graze centre, rabbits a hop within 6 m of home.
## Nobody watching and already in its area: it stays put (no path query; its position means nothing to anyone).
func _wander() -> void:
	var pos := global_position
	var in_area: bool = _flat(pos, graze_center) <= wander_radius + 1.0 if kind == &"deer" \
			else _flat(pos, home) <= wander_radius
	if in_area and _nobody_sees():
		var k: Dictionary = KINDS[kind]
		_idle_left = _rng.randf_range(float(k["idle_min"]), float(k["idle_max"]))
		return
	var target := pos
	if kind == &"deer":
		if _flat(pos, graze_center) > wander_radius + 1.0:
			target = graze_center + _rand_offset(wander_radius * 0.7)
		else:
			var dir := _rand_dir()
			target = pos + dir * _rng.randf_range(1.2, 3.0)
			if _flat(target, graze_center) > wander_radius:
				target = graze_center + _rand_offset(wander_radius * 0.7)
	else:
		for i: int in 4:
			var cand := pos + _rand_dir() * _rng.randf_range(1.5, 4.0)
			if _flat(cand, home) <= wander_radius:
				target = cand
				break
		if target == pos:
			target = home + _rand_offset(wander_radius * 0.6)
	if _blocked_point(target) or _flat(target, pos) < 0.5:
		_idle_left = 2.0
		return
	var path := _query_path(pos, target)   # its last point is the target snapped to the navmesh
	if not _path_ok(path) or _path_length(path) < 0.5 or _path_length(path) > _flat(pos, target) * 2.5 + 4.0:
		_idle_left = 2.0
		return
	_set_path(path)
	_state = &"move"
	_call_model(&"play_move", [walk_speed])
	set_physics_process(true)


## Deer: toward the herd's graze spot farthest from the threat (a real path when a query is allowed);
## rabbits: 5 m straight away. Falls back to a navmesh-checked straight bolt.
func _flee_path(from_pos: Vector3, away: Vector3) -> PackedVector3Array:
	var pos := global_position
	if kind == &"deer" and not graze_spots.is_empty() and _query_ready():
		var best := Vector3.INF
		var best_d := -1.0
		for s: Vector3 in graze_spots:
			if _flat(s, pos) < 4.0 or _blocked_point(s):
				continue
			var d := _flat(s, from_pos)
			if d > best_d:
				best_d = d
				best = s
		if best != Vector3.INF:
			var path := _query_path(pos, _snap(best + _rand_offset(1.5)))
			if _path_ok(path) and _path_length(path) >= 2.0:
				return path
	elif kind != &"deer" and _query_ready():
		var goal := _snap(pos + away * flee_distance)
		if not _blocked_point(goal) and _flat(goal, pos) > flee_distance * 0.4:
			var path := _query_path(pos, goal)
			if _path_ok(path) and _path_length(path) <= flee_distance * 2.0 + 2.0:
				return path
	return _straight_bolt(away, flee_distance)


func _straight_bolt(away: Vector3, dist: float) -> PackedVector3Array:
	var pos := global_position
	for deg: float in [0.0, 35.0, -35.0, 70.0, -70.0, 110.0, -110.0]:
		var dir := away.rotated(Vector3.UP, deg_to_rad(deg))
		var goal := _snap(pos + dir * dist)
		if _flat(goal, pos) < dist * 0.4:
			continue
		if _segment_clear(pos, goal):
			return PackedVector3Array([pos, goal])
	return PackedVector3Array()


func _query_ready() -> bool:
	return _clock - _last_query >= PATH_QUERY_INTERVAL


func _query_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	_last_query = _clock
	var map := _nav_map()
	if not map.is_valid():
		return PackedVector3Array([from, to]) if _segment_clear(from, to) else PackedVector3Array()
	var path := NavigationServer3D.map_get_path(map, from, to, true)
	var lift := _nav_lift(map)
	if lift != 0.0:
		for i: int in path.size():
			path[i].y -= lift
	return path


## How far the baked navmesh floats above the ground (0.5 m with the current bake settings): measured once per
## map with one ray down on layer 1, then removed from every navmesh point so critters stand on the ground.
func _nav_lift(map: RID) -> float:
	if _lift_map == map:
		return _lift
	_lift_map = map
	_lift = 0.0
	var p := NavigationServer3D.map_get_closest_point(map, global_position)
	var space := get_world_3d().direct_space_state
	if space != null:
		var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 2.0, p + Vector3.DOWN * 3.0, 1)
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			_lift = clampf(p.y - (hit["position"] as Vector3).y, 0.0, 1.0)
	return _lift


func _path_ok(path: PackedVector3Array) -> bool:
	if path.size() < 2:
		return false
	_get_river()
	if not _river_full:
		return true
	for i: int in range(1, path.size()):
		var a := path[i - 1]
		var b := path[i]
		var n := maxi(1, ceili(_flat(a, b) / 2.0))
		for j: int in range(1, n + 1):
			if _blocked_point(a.lerp(b, float(j) / float(n))):
				return false
	return true


func _segment_clear(a: Vector3, b: Vector3) -> bool:
	var map := _nav_map()
	var n := maxi(1, ceili(_flat(a, b) / 1.5))
	for j: int in range(1, n + 1):
		var p := a.lerp(b, float(j) / float(n))
		if _blocked_point(p):
			return false
		if map.is_valid() and _flat(NavigationServer3D.map_get_closest_point(map, p), p) > NAV_TOLERANCE:
			return false
	return true


## Deep water, ford, bridge or the other bank (RiverSystem); false without a river.
func _blocked_point(p: Vector3) -> bool:
	var river := _get_river()
	if river == null or not _river_full:
		return false
	if bool(river.call(&"is_water", p)) or bool(river.call(&"is_ford", p)) or bool(river.call(&"is_bridge", p)):
		return true
	return bank >= 0 and int(river.call(&"bank_of", p)) != bank


func _snap(p: Vector3) -> Vector3:
	var map := _nav_map()
	if not map.is_valid():
		return p
	var q := NavigationServer3D.map_get_closest_point(map, p)
	q.y -= _nav_lift(map)
	return q


## The navigation map once it has a baked navmesh (else an invalid RID).
func _nav_map() -> RID:
	if not is_inside_tree():
		return RID()
	var w := get_world_3d()
	if w == null:
		return RID()
	var map := w.navigation_map
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return RID()
	return map


func _get_fog() -> FogOfWar:
	if _fog != null and is_instance_valid(_fog):
		return _fog
	_fog = null
	if not is_inside_tree() or _clock - _fog_checked < 1.0:
		return null
	_fog_checked = _clock
	_fog = get_tree().get_first_node_in_group(&"fog") as FogOfWar
	return _fog


func _get_river() -> Node:
	if _river != null and is_instance_valid(_river):
		return _river
	_river = null
	_river_full = false
	if not is_inside_tree() or _clock - _river_checked < 2.0:
		return null
	_river_checked = _clock
	_river = get_tree().get_first_node_in_group(&"river")
	if _river != null:
		_river_full = _river.has_method(&"is_water") and _river.has_method(&"is_ford") \
				and _river.has_method(&"is_bridge") and _river.has_method(&"bank_of")
		if _river_full and bank < 0:
			bank = int(_river.call(&"bank_of", home))
	return _river


## Hidden-attacker rule (map-fill.md 3.4, fog-of-war.md): each team that sees this cell but not the attacker
## gets a SightMarker (r 2, 1 s) at the attacker (at most one per attacker and team per 0.8 s).
func _reveal_attacker(src: Node3D) -> void:
	if src == null:
		return
	var fog := _get_fog()
	if fog == null or not fog.enabled:
		return
	var at: Variant = src.get(&"team")
	var src_team: int = int(at) if at != null else -1
	var here := global_position
	var there := src.global_position
	for t: int in [TEAM_PLAYER, TEAM_ENEMY]:
		if t == src_team or not fog.is_visible(t, here) or fog.is_visible(t, there):
			continue
		var key := "%d:%d" % [src.get_instance_id(), t]
		if _clock - float(_reveal_times.get(key, -100.0)) < 0.8:
			continue
		_reveal_times[key] = _clock
		_spawn_marker(t, there)
	if _reveal_times.size() > 64:
		_reveal_times.clear()


func _spawn_marker(for_team: int, at: Vector3) -> void:
	if not ResourceLoader.exists(SIGHT_MARKER_PATH):
		return
	var script := load(SIGHT_MARKER_PATH) as GDScript
	if script == null:
		return
	var marker := script.new() as Node3D
	if marker == null:
		return
	marker.name = "CritterRevealMarker"
	marker.set(&"team", for_team)
	marker.set(&"sight_radius", REVEAL_RADIUS)
	marker.set(&"lifetime", REVEAL_TIME)
	var parent: Node = get_tree().current_scene if get_tree().current_scene else get_parent()
	parent.add_child(marker, true)
	marker.global_position = at


func _build_model() -> void:
	if _model != null:
		return
	var path: String = KINDS[kind]["scene"]
	var scene: PackedScene = _scene_cache.get(kind) as PackedScene
	if scene == null and ResourceLoader.exists(path):
		scene = load(path) as PackedScene
		_scene_cache[kind] = scene
	if scene != null:
		_model = scene.instantiate() as Node3D
	if _model != null:
		if kind == &"deer" and &"antlers" in _model:
			_model.set(&"antlers", stag)
		if _model.has_signal(&"death_finished"):
			_model.connect(&"death_finished", _on_death_finished)
	else:
		_model = _placeholder()
	_model.name = "Model"
	add_child(_model)


## A plain box (deer) / sphere (rabbit) when the model scene is missing.
func _placeholder() -> Node3D:
	if _placeholder_mat == null:
		_placeholder_mat = StandardMaterial3D.new()
		_placeholder_mat.albedo_color = Color(0.55, 0.36, 0.22)
	var mi := MeshInstance3D.new()
	if kind == &"deer":
		var box := BoxMesh.new()
		box.size = Vector3(0.5, 1.2, 1.6)
		mi.mesh = box
		mi.position.y = 0.6
	else:
		var ball := SphereMesh.new()
		ball.radius = 0.22
		ball.height = 0.44
		mi.mesh = ball
		mi.position.y = 0.22
	mi.material_override = _placeholder_mat
	var root := Node3D.new()
	root.add_child(mi)
	return root


func _build_click_area() -> void:
	if _area != null:
		return
	var k: Dictionary = KINDS[kind]
	_area = Area3D.new()
	_area.name = "ClickArea"
	_area.collision_layer = CLICK_LAYER
	_area.collision_mask = 0
	_area.monitoring = false
	_area.input_ray_pickable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = k["click_size"]
	shape.shape = box
	shape.position.y = float(k["click_y"])
	_area.add_child(shape)
	add_child(_area)


## "AlertArea": layer 0 (nothing hits it), mask 2 (units), a sphere of alert_radius. The physics engine keeps
## _near up to date; think() reads it (no per-think queries, no "units" loop).
func _build_alert_area() -> void:
	if _alert != null:
		return
	_alert = Area3D.new()
	_alert.name = "AlertArea"
	_alert.collision_layer = 0
	_alert.collision_mask = 2
	_alert.monitorable = false
	_alert.input_ray_pickable = false
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = alert_radius
	shape.shape = sphere
	shape.position.y = 0.6
	_alert.add_child(shape)
	_alert.body_entered.connect(_on_body_near)
	_alert.body_exited.connect(_on_body_gone)
	add_child(_alert)


func _on_body_near(body: Node3D) -> void:
	if _alive and body is Unit and not _near.has(body):
		_near.append(body)


func _on_body_gone(body: Node3D) -> void:
	_near.erase(body)


func _call_model(method: StringName, args: Array = []) -> void:
	if _model != null and _model.has_method(method):
		_model.callv(method, args)


func _rand_dir() -> Vector3:
	var a := _rng.randf() * TAU
	return Vector3(cos(a), 0.0, sin(a))


func _rand_offset(r: float) -> Vector3:
	return _rand_dir() * (sqrt(_rng.randf()) * r)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _path_length(path: PackedVector3Array) -> float:
	var total := 0.0
	for i: int in range(1, path.size()):
		total += path[i - 1].distance_to(path[i])
	return total
