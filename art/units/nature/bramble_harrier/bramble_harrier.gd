extends Node3D
## Bramble Harrier (stables.md 2, Nature slot X, tier 1): the unit's model_scene. One scene, two kit models side by side
## (like the Glade Outrider): "Hare" = the Bramble hare (parts/bramble_hare.gd, a MountModel: a straw-brown giant hare
## with two tall ears, huge hind legs and a bramble collar) and "Rider" = the dart caster (parts/bramble_dartcaster.gd,
## a NatureWarModel seated on it: a wide pale straw hat, bark jerkin, team mantle, an atlatl and thorn darts).
## Read at 40 m: a hunched tan hare with two tall ears behind a big pale straw hat, the team mantle over its back.
## This root forwards the unit hooks (all has_method-guarded by callers; safe before _ready):
##   set_team_color(c) (the hare's blanket + the rider's mantle / sash), set_moving(speed) (the hare walks / bounds
##   from its gallop_speed 2.8 m/s: the unit's 7.4 is a gallop), play_attack() (the rider's side-arm dart throw,
##   release at attack_windup 0.12 s, the hare hops with it; aims at the owning unit's attack_target unless
##   set_aim_target was called), play_charge() (the hare's charge), play_hit(), play_death() + signal death_finished
##   (1.0 s: the hare rolls over and withers, the rider returns to the grove), revive(), play_cast(id),
##   play_level_up(), set_veterancy(level), set_status(id, on) -> bool, set_barded(on) / is_barded() (no barding),
##   play_fidget(), set_seated(on, mount = null) / is_seated(), set_carrying(on) (no-op), dances + set_rank (MountedDance).
## Aim: set_aim_target(target: Variant) = a Node3D (tracked), a Vector3 world point or null.
## Read-only: attack_style &"dart_sling", attack_windup 0.12, body_height, get_dart_tip() -> Vector3,
##   gait_phase(), gallop_blend(), is_galloping(), rider_model(), mount_model(), authored_mesh_count();
##   signal dart_released(from: Vector3, dir: Vector3) (world, at the release: for a thorn-trail VFX).

signal death_finished
signal dart_released(from: Vector3, dir: Vector3)

@export var body_height: float = 2.2
@export var attack_style: StringName = &"dart_sling"
@export_range(0.0, 0.15, 0.01) var attack_windup: float = 0.12
@export var kingdom_color: Color = Color(0.35, 0.7, 0.25)
## Footprint rule (art-units 1.1): a mounted unit reaches 2.4 x its radius along z like the quadruped it rides.
## Read by the tools only (gameplay never reads it).
@export var is_quadruped: bool = true
## The Unit writes its move speed here at spawn. Not forwarded: the hare gallops from its own gallop_speed.
var stride_speed: float = 7.4
## G-F: Unit._build_model sets this on the root; both kit models get it (they pause their animation and looping
## emitters off-camera).
var offscreen_freeze: bool = false:
	set(v):
		offscreen_freeze = v
		OffscreenEmitters.forward_freeze(self, v)

var _mount: Node3D
var _rider: Node3D
var _aim_explicit: bool = false
var _dead: bool = false


func _parts() -> bool:
	if _mount == null:
		_mount = get_node_or_null(^"Hare") as Node3D
		_rider = get_node_or_null(^"Rider") as Node3D
	return _mount != null and _rider != null


func _ready() -> void:
	if not _parts():
		push_warning("BrambleHarrier: Hare / Rider missing")
		return
	_rider.call(&"set_seated", true, _mount)
	_mount.connect(&"death_finished", _on_mount_death_finished)
	if _rider.has_signal(&"dart_released"):
		_rider.connect(&"dart_released", func(from: Vector3, dir: Vector3) -> void: dart_released.emit(from, dir))


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


## The dart throw, aimed at the owning unit's attack_target (unless set_aim_target was called); the hare hops with it
## (its `dart_hop`).
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


## The cavalry charge hit: the hare lunges.
func play_charge() -> void:
	if not _parts() or _dead:
		return
	_mount.call(&"play_charge")


func play_hit() -> void:
	if _parts():
		_mount.call(&"play_hit")
		_rider.call(&"play_hit")


## The hare first (the rider then rides its fall instead of being thrown).
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


## The hare carries no barding (a light skirmisher): kept for the cavalry API.
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

func get_dart_tip() -> Vector3:
	if _parts():
		return _rider.call(&"get_dart_tip")
	return global_position + Vector3.UP * 2.0


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
