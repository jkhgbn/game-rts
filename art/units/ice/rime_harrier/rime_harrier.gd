extends Node3D
## Rime Harrier (stables.md 2, Ice slot X, tier 1): the unit's model_scene. One scene, two kit models side by side (like
## the Rimehorn Rider): "Ram" = the Rime ram (rime_ram.gd, a MountModel: slim legs, two curled horns with cyan crystal
## tips, a shaggy belly fringe) and "Rider" = the javelineer (rime_harrier_rider.gd, an IceModel seated on it).
## Read at 40 m: a slim high-headed slate ram with two pale curls, a steel-blue rider with a team cowl and scarf, three
## cyan javelin heads over the shoulder and one frost javelin upright in the fist.
## This root forwards the unit hooks (all has_method-guarded by callers; safe before _ready):
##   set_team_color(c) (the ram's blanket + the rider's cowl / scarf / sleeves), set_moving(speed) (the ram walks /
##   bounds from its gallop_speed 3.0 m/s: the unit's 6.8 is a gallop), play_attack() (the rider's javelin throw,
##   release at attack_windup 0.12 s, the ram rears half-up with it; aims at the owning unit's attack_target unless set_aim_target was called),
##   play_charge() (the ram's charge), play_hit(), play_death() + signal death_finished (1.0 s: the ram rolls over and
##   frosts, the rider freezes and shatters), revive(), play_cast(id), play_level_up(), set_veterancy(level),
##   set_status(id, on) -> bool, set_barded(on) / is_barded() (no barding: no-op / false), play_fidget(),
##   set_seated(on, mount = null) / is_seated(), set_carrying(on) (no-op), dances + set_rank (MountedDance).
## Aim: set_aim_target(target: Variant) = a Node3D (tracked), a Vector3 world point or null.
## Read-only: attack_style &"javelin_throw", attack_windup 0.12, body_height, get_javelin_tip() -> Vector3,
##   gait_phase(), gallop_blend(), is_galloping(), rider_model(), mount_model(), authored_mesh_count();
##   signal javelin_released(from: Vector3, dir: Vector3) (world, at the release: for a frost-trail VFX).

signal death_finished
signal javelin_released(from: Vector3, dir: Vector3)

@export var body_height: float = 2.0
@export var attack_style: StringName = &"javelin_throw"
@export_range(0.0, 0.15, 0.01) var attack_windup: float = 0.12
@export var kingdom_color: Color = Color(0.45, 0.75, 0.95)
## Footprint rule (art-units 1.1): a mounted unit reaches 2.4 x its radius along z like the quadruped it rides.
## Read by the tools only (gameplay never reads it).
@export var is_quadruped: bool = true
## The Unit writes its move speed here at spawn. Not forwarded: the ram gallops from its own gallop_speed.
var stride_speed: float = 6.8

var _mount: Node3D
var _rider: Node3D
var _aim_explicit: bool = false
var _dead: bool = false


func _parts() -> bool:
	if _mount == null:
		_mount = get_node_or_null(^"Ram") as Node3D
		_rider = get_node_or_null(^"Rider") as Node3D
	return _mount != null and _rider != null


func _ready() -> void:
	if not _parts():
		push_warning("RimeHarrier: Ram / Rider missing")
		return
	_rider.call(&"set_seated", true, _mount)
	_mount.connect(&"death_finished", _on_mount_death_finished)
	if _rider.has_signal(&"javelin_released"):
		_rider.connect(&"javelin_released", func(from: Vector3, dir: Vector3) -> void: javelin_released.emit(from, dir))


func _on_mount_death_finished() -> void:
	death_finished.emit()


# ================================================================ unit hooks

func set_team_color(c: Color) -> void:
	if _parts():
		_mount.call(&"set_team_color", c)
		_rider.call(&"set_team_color", c)


func set_moving(speed: float) -> void:
	if _parts():
		_mount.call(&"set_moving", speed)
		_rider.call(&"set_moving", speed)


## The javelin throw, aimed at the owning unit's attack_target (unless set_aim_target was called); the ram rears
## half-up with it (its `rear_throw`).
func play_attack() -> void:
	if not _parts() or _dead:
		return
	if not _aim_explicit:
		var t := _owner_target()
		if t:
			_rider.call(&"set_aim_target", t)
	_rider.call(&"play_attack")
	_mount.call(&"play_attack")


## Where to throw: a Node3D (tracked every frame), a Vector3 world point, or null (back to the owner's target).
func set_aim_target(target: Variant) -> void:
	_aim_explicit = target != null
	if _parts():
		_rider.call(&"set_aim_target", target)


## The cavalry charge hit: the ram lowers its horns and butts.
func play_charge() -> void:
	if not _parts() or _dead:
		return
	_mount.call(&"play_charge")


func play_hit() -> void:
	if _parts():
		_mount.call(&"play_hit")
		_rider.call(&"play_hit")


## The ram first (the rider then rides its fall instead of being thrown).
func play_death() -> void:
	if not _parts() or _dead:
		return
	_dead = true
	_mount.call(&"play_death")
	_rider.call(&"play_death")


func revive() -> void:
	if not _parts():
		return
	_dead = false
	_mount.call(&"revive")
	_rider.call(&"revive")
	_rider.call(&"set_seated", true, _mount)


func play_cast(spell_id: StringName) -> void:
	if _parts() and not _dead:
		_rider.call(&"play_cast", spell_id)


func play_level_up() -> void:
	if _parts():
		_mount.call(&"play_level_up")
		_rider.call(&"play_level_up")


func set_veterancy(level: int) -> void:
	if _parts():
		_mount.call(&"set_veterancy", level)
		_rider.call(&"set_veterancy", level)


func set_status(id: StringName, on: bool) -> bool:
	if not _parts():
		return false
	var a: bool = bool(_rider.call(&"set_status", id, on))
	var b: bool = bool(_mount.call(&"set_status", id, on))
	return a or b


## The ram carries no barding (a light skirmisher): kept for the cavalry API.
func set_barded(_on: bool) -> void:
	pass


func is_barded() -> bool:
	return false


func play_fidget() -> void:
	if _parts():
		_mount.call(&"play_fidget")
		_rider.call(&"play_fidget")


func set_carrying(_on: bool) -> void:
	pass


func set_seated(on: bool, mount: Node3D = null) -> void:
	if _parts():
		_rider.call(&"set_seated", on, mount if mount else _mount)


func is_seated() -> bool:
	return _parts() and bool(_rider.call(&"is_seated"))


# ================================================================ read-only

func get_javelin_tip() -> Vector3:
	if _parts():
		return _rider.call(&"get_javelin_tip")
	return global_position + Vector3.UP * 2.2


func gait_phase() -> float:
	return float(_mount.call(&"gait_phase")) if _parts() else 0.0


func gallop_blend() -> float:
	return float(_mount.call(&"gallop_blend")) if _parts() else 0.0


func is_galloping() -> bool:
	return _parts() and bool(_mount.call(&"is_galloping"))


func rider_model() -> Node3D:
	_parts()
	return _rider


func mount_model() -> Node3D:
	_parts()
	return _mount


func authored_mesh_count() -> int:
	if not _parts():
		return 0
	return int(_rider.call(&"authored_mesh_count")) + int(_mount.call(&"authored_mesh_count"))


## The owning unit's current attack target (the model sits under Unit._visual).
func _owner_target() -> Node3D:
	var n := get_parent()
	for i: int in 3:
		if n == null:
			return null
		if &"attack_target" in n:
			var t: Variant = n.get(&"attack_target")
			if t is Node3D and is_instance_valid(t):
				return t
			return null
		n = n.get_parent()
	return null


# ================================================================ dances + rank (Stables16, MountedDance)

func play_clip(id: StringName) -> bool:
	return MountedDance.play(self, id)


func stop_clip() -> void:
	MountedDance.stop(self)


func current_clip() -> StringName:
	return MountedDance.current(self)


func has_clip(id: StringName) -> bool:
	return MountedDance.has(self, id)


func can_dance() -> bool:
	return MountedDance.can(self)


func set_rank(rank: int) -> void:
	MountedDance.set_rank(self, rank)
