class_name CasterHaze
extends Node3D
## A Pollen Haze cloud (docs/design/caster-units.md 5.3): for `lifetime` s, every 0.25 s, enemy GROUND units of `team`
## within `radius` get `hazed` (refreshed; it lingers 0.5 s after they leave): their ranged attacks only reach 2.5 m.
## Flyers, buildings and towers are never hazed; spells and melee are unaffected (Unit.effective_attack_range).
## The Bramblesage's Seedcloak uses a small one that follows it (`anchor`). Draw-only look: UnitVfx `pollen_haze` /
## `seedcloak` (played by CasterAbility) and `hazed` on each unit it refreshes. Lives in the level, so it outlasts its
## caster.

signal unit_hazed(u: Unit)

var team := 0
var radius := 3.5
var lifetime := 6.0
var tick := 0.25
var linger := 0.5
## Followed while it lives (Seedcloak); null = a fixed point.
var anchor: Node3D = null
## Units hazed at least once by this cloud (instance id -> true), for the caster's spell XP.
var hazed_ids := {}

var _left := 0.0
var _tick_left := 0.0


static func spawn(parent: Node, at: Vector3, owner_team: int, r: float, seconds: float, follow: Node3D = null) -> CasterHaze:
	var h := CasterHaze.new()
	h.name = "PollenHaze"
	h.team = owner_team
	h.radius = r
	h.lifetime = seconds
	h.anchor = follow
	h.position = at
	parent.add_child(h, true)
	h.global_position = at
	return h


func _ready() -> void:
	add_to_group(&"pollen_hazes")
	_left = lifetime


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	if anchor != null:
		if is_instance_valid(anchor) and anchor.is_inside_tree():
			global_position = anchor.global_position
		else:
			anchor = null
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left += tick
	_haze_now()


## Seconds left.
func time_left() -> float:
	return maxf(0.0, _left)


## True when `p` is inside the cloud.
func covers(p: Vector3) -> bool:
	return Vector2(p.x - global_position.x, p.z - global_position.z).length() <= radius


func _haze_now() -> void:
	var vfx := get_tree().get_first_node_in_group(&"unit_vfx")
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or Teams.is_allied_fast(int(u.team), int(team)):
			continue
		if HelperAbilities._is_flyer(u):
			continue
		if Vector2(u.global_position.x - global_position.x, u.global_position.z - global_position.z).length() \
				> radius + u.radius:
			continue
		u.apply_status(&"hazed", tick + linger, true)
		if vfx:
			vfx.call(&"play", &"hazed", u, tick + linger)
		var key := u.get_instance_id()
		if not hazed_ids.has(key):
			hazed_ids[key] = true
			unit_hazed.emit(u)
