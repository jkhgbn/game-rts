class_name BuildingGun
extends RefCounted
## The shooting part of a building: the Tower's and (balance-1) the Keep's. Picks targets like a unit
## with aggro_range = attack_range, never moves, prefers enemy units over enemy buildings, never shoots epic
## beasts (group "beasts"), and fires
## the kingdom's archer bolt (Projectile) with the BuildingType's attack_damage / range / cooldown.
## The owner calls tick(delta) from _physics_process while it is alive and finished.

const RETARGET_INTERVAL := 0.25
const BEAST_GROUP := &"beasts"

var target: Node3D = null   ## Read only: what the gun shoots at.
## Flat damage added to the type's attack_damage (the keep's tier: tiers.md, +4 Stronghold / +8 Citadel).
var damage_bonus := 0.0

var _building: Building
var _muzzle_height := 0.0
var _bolt_size := 0.14
var _extra_reach := 0.0     # added to attack_range (the keep measures from its walls)
var _cooldown_left := 0.0
var _retarget_left := 0.0


## `muzzle_height`: where bolts leave (above the building's origin); `extra_reach`: added to the range.
func _init(building: Building, muzzle_height: float, bolt_size: float = 0.14, extra_reach: float = 0.0) -> void:
	_building = building
	_muzzle_height = muzzle_height
	_bolt_size = bolt_size
	_extra_reach = extra_reach


## True if the building's type can shoot at all.
static func can_shoot(type: BuildingType) -> bool:
	return type != null and type.attack_damage > 0.0 and type.attack_range > 0.0


## Advances the cooldown, retargets and fires. Returns true on the frame a bolt leaves.
func tick(delta: float) -> bool:
	var type := _building.building_type
	if not can_shoot(type):
		return false
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	_retarget_left -= delta
	if target != null and (not _alive(target) or not _in_range(target) or is_ignored(target)):
		target = null
	# Look again a few times per second; a building target is dropped as soon as a unit shows up.
	if _retarget_left <= 0.0 and (target == null or not target is Unit):
		_retarget_left = RETARGET_INTERVAL
		var found := _find_target()
		if found:
			target = found
	if target != null and _cooldown_left <= 0.0:
		_cooldown_left = type.attack_cooldown
		_fire(target)
		return true
	return false


func _fire(at: Node3D) -> void:
	var type := _building.building_type
	var bolt := Projectile.new()
	var tree := _building.get_tree()
	var parent: Node = tree.current_scene if tree.current_scene else _building.get_parent()
	parent.add_child(bolt)
	var from := _building.global_position + Vector3.UP * _muzzle_height
	bolt.launch_at_target(_building, from, at, type.attack_damage + damage_bonus, type.projectile_color, _bolt_size)
	if type.on_hit_status != &"" and type.on_hit_duration > 0.0:
		bolt.hit_unit.connect(_apply_on_hit.bind(type.on_hit_status, type.on_hit_duration))


## The Rime Spire's chill (BuildingType.on_hit_status): only on living units that have apply_status.
static func _apply_on_hit(target: Node3D, _dealt: float, status_id: StringName, seconds: float) -> void:
	if is_instance_valid(target) and target is Unit and (target as Unit).is_alive() \
			and target.has_method(&"apply_status"):
		target.call(&"apply_status", status_id, seconds)


## The nearest enemy unit in range; if none, the nearest enemy building in range.
func _find_target() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	var own_team := int(_building.team)
	var tree := _building.get_tree()
	for node in tree.get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or int(u.team) == own_team or not u.is_alive() or not _in_range(u) or is_ignored(u) \
				or Unit.in_truce(_building, u):
			continue
		var d := _flat_distance(u.global_position)
		if d < best_d:
			best_d = d
			best = u
	if best:
		return best
	for node in tree.get_nodes_in_group("buildings"):
		var b := node as Node3D
		if b == null or b == _building or not _is_enemy(b) or not _alive(b) or not _in_range(b):
			continue
		var d := _flat_distance(b.global_position) - _reach_of(b)
		if d < best_d:
			best_d = d
			best = b
	return best


## True for what towers and keeps never shoot: epic beasts (group "beasts", map-fill.md 5.5: nobody can farm a
## beast from behind a tower).
static func is_ignored(t: Node) -> bool:
	return t != null and is_instance_valid(t) and t.is_in_group(BEAST_GROUP)


func _in_range(t: Node3D) -> bool:
	return _flat_distance(t.global_position) <= _building.building_type.attack_range + _extra_reach + _reach_of(t)


func _is_enemy(node: Node3D) -> bool:
	var t: Variant = node.get(&"team")
	return t != null and int(t) != int(_building.team) and not Unit.in_truce(_building, node)


static func _reach_of(t: Node3D) -> float:
	if t.has_method(&"target_radius"):
		return float(t.call(&"target_radius"))
	return 0.0


static func _alive(t: Variant) -> bool:
	return t != null and is_instance_valid(t) and (t as Object).has_method(&"is_alive") \
			and bool((t as Object).call(&"is_alive"))


func _flat_distance(pos: Vector3) -> float:
	var p := _building.global_position
	return Vector2(p.x - pos.x, p.z - pos.z).length()
