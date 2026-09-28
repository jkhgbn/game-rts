class_name RimehornRiderModel
extends Node3D
## Rimehorn Rider (cavalry-mounts.md 4 / 10, task 13.V8): the Ice cavalry "armored breaker" = the unit's model_scene.
## One scene, two kit models side by side (same transform, like Unit._visual for a wizard on a mount): "Rimehorn" = the
## 13.V4 Rimehorn (MountModel, unchanged) and "Rider" = RimehornRiderAxeman (an IceModel seated on it with the kit's
## set_seated, 13.V1b; its _pose_seated carries the ice shield and the great axe).
## This root forwards the unit hooks (all has_method-guarded by callers; safe before _ready):
##   set_team_color(c) (the rhino's saddle-cloth + the rider's surcoat / sleeves / shield snowflake), set_moving(speed)
##   (the rhino walks / gallops from its gallop_speed 3.4 m/s: the unit's 6.0 is a gallop; the rider bobs with it),
##   play_attack() (the rider's mounted `great_swing` chop, strike at 0.15 s), play_charge() (the rhino's horn charge +
##   the rider hunkering behind the shield, impact 0.10 s: call it when the charge hit lands, Unit.charged),
##   play_hit(), play_death() + signal death_finished (1.0 s: the rhino rolls over and frosts, the rider freezes and
##   shatters), revive() (both, re-seated), play_cast(id), play_level_up(), set_veterancy(level),
##   set_status(id, on) -> bool, set_barded(on) / is_barded() (the rhino's silver-blue plates), play_fidget(),
##   set_seated(on, mount = null) / is_seated() (the rider; null mount = the own rhino), set_carrying(on) (no-op).
## Read-only: attack_style &"great_swing", attack_windup 0.0 (melee), body_height, get_axe_head() -> Vector3 (world),
##   gait_phase(), gallop_blend(), is_galloping(), rider_model(), mount_model(), authored_mesh_count();
##   signal axe_struck(at: Vector3) (world, the blade at the strike frame: for a chill-hit VFX).

signal death_finished
signal axe_struck(at: Vector3)

@export var body_height: float = 2.7
@export var attack_style: StringName = &"great_swing"
@export_range(0.0, 0.15, 0.01) var attack_windup: float = 0.0
@export var kingdom_color: Color = Color(0.45, 0.75, 0.95)
## The Unit writes its move speed here at spawn (walk-rate tuning of plain CharacterModels). Not forwarded: the rhino
## keeps its own walk tuning and gallops from its gallop_speed.
var stride_speed: float = 6.0

var _mount: Node3D
var _rider: Node3D
var _dead: bool = false


func _parts() -> bool:
	if _mount == null:
		_mount = get_node_or_null(^"Rimehorn") as Node3D
		_rider = get_node_or_null(^"Rider") as Node3D
	return _mount != null and _rider != null


func _ready() -> void:
	if not _parts():
		push_warning("RimehornRiderModel: Rimehorn / Rider missing")
		return
	_rider.call(&"set_seated", true, _mount)
	_mount.connect(&"death_finished", _on_mount_death_finished)
	if _rider.has_signal(&"axe_struck"):
		_rider.connect(&"axe_struck", func(at: Vector3) -> void: axe_struck.emit(at))


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


func play_attack() -> void:
	if _parts() and not _dead:
		_rider.call(&"play_attack")


## The cavalry charge hit (Unit.charged): the rhino levels its horn and tosses, the rider braces behind the shield.
func play_charge() -> void:
	if not _parts() or _dead:
		return
	_mount.call(&"play_charge")
	_rider.call(&"play_charge_pose")


func play_hit() -> void:
	if _parts():
		_mount.call(&"play_hit")
		_rider.call(&"play_hit")


## The rhino first (the rider then rides its fall instead of being thrown).
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


func set_barded(on: bool) -> void:
	if _parts():
		_mount.call(&"set_barded", on)


func is_barded() -> bool:
	return _parts() and bool(_mount.call(&"is_barded"))


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

## World position of the axe blade (the strike point).
func get_axe_head() -> Vector3:
	if _parts():
		return _rider.call(&"get_axe_head")
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


# ================================================================ dances + rank (Stables16, MountedDance)

## Dances on both models (rider from the waist up, mount prance / rear, head low, trot in place). See MountedDance.
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


## Stables16 rank-3 upgrade look (placeholder gold crest until the art lands).
func set_rank(rank: int) -> void:
	MountedDance.set_rank(self, rank)
