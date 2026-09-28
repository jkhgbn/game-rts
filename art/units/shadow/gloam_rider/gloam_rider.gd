class_name GloamRiderModel
extends Node3D
## Gloam Rider (cavalry-mounts.md 4 / 10 row 13.V7): the Shadow draining lancer = the unit's model_scene. One scene, two
## kit models side by side (same transform, like Unit._visual for a wizard on a mount): "Steed" = the 13.V3 Dusk Steed
## (MountModel, unchanged) and "Rider" = GloamRiderRider (a ShadowModel seated on it with the kit's set_seated, 13.V1b;
## its _pose_seated holds and aims the lance, see gloam_rider_rider.gd for the look and the timelines).
## This root forwards the unit hooks (all has_method-guarded by callers; safe before _ready):
##   set_team_color(c), set_moving(speed) (the steed walks / gallops from its gallop_speed 3.8 m/s: the Gloam's 7.2 is
##   a full gallop; the rider bobs with the gait, lowers the lance forward and its cloak / pennon stream back),
##   play_attack() (`lance_charge`, melee: the rider couches and thrusts, the hit frame at 0.12 s; the steed's
##   mount_toss lunges with it), play_charge() (Unit.charged: the steed's charge + the rider's couched charge, strike
##   0.10 s, the lance fuller flares), play_hit(), play_death() + signal death_finished (1.0 s: the steed rolls over,
##   the rider rides the fall and dissolves violet, the lance tips down), revive() (both, re-seated), play_cast(id),
##   play_level_up(), set_veterancy(level), set_status(id, on) -> bool, set_barded(on) / is_barded() (the steed's
##   tarnished silver chanfron), play_fidget(), set_seated(on, mount = null) / is_seated() (the rider; null mount = the
##   own steed), set_carrying(on) (no-op).
## Read-only: attack_style &"lance_charge", attack_windup 0.0 (melee), body_height, get_lance_tip() -> Vector3 (world),
##   lance_pitch() -> float (deg, negative = tip up), couch_amount() -> float, is_charging(), gait_phase(),
##   gallop_blend(), is_galloping(), rider_model(), mount_model(), authored_mesh_count().
## Signals: death_finished, charge_struck(at: Vector3) (the charge strike, lance tip in world space: 13.V20 charge
##   impact / lifesteal wisps), lance_struck(at: Vector3) (the attack's hit frame, lance tip).

signal death_finished
signal charge_struck(at: Vector3)
signal lance_struck(at: Vector3)

@export var body_height: float = 3.0
@export var attack_style: StringName = &"lance_charge"
@export_range(0.0, 0.15, 0.01) var attack_windup: float = 0.0
@export var kingdom_color: Color = Color(0.42, 0.22, 0.6)
## The Unit writes its move speed here at spawn (walk-rate tuning of plain CharacterModels). Not forwarded: the steed
## keeps its own walk tuning and gallops from its gallop_speed.
var stride_speed: float = 7.2

var _steed: Node3D
var _rider: Node3D
var _dead: bool = false


func _parts() -> bool:
	if _steed == null:
		_steed = get_node_or_null(^"Steed") as Node3D
		_rider = get_node_or_null(^"Rider") as Node3D
	return _steed != null and _rider != null


func _ready() -> void:
	if not _parts():
		push_warning("GloamRiderModel: Steed / Rider missing")
		return
	_rider.call(&"set_seated", true, _steed)
	_steed.connect(&"death_finished", func() -> void: death_finished.emit())
	_rider.connect(&"charge_struck", func(at: Vector3) -> void: charge_struck.emit(at))
	_rider.connect(&"lance_struck", func(at: Vector3) -> void: lance_struck.emit(at))


# ================================================================ unit hooks

func set_team_color(c: Color) -> void:
	if _parts():
		_steed.call(&"set_team_color", c)
		_rider.call(&"set_team_color", c)


func set_moving(speed: float) -> void:
	if _parts():
		_steed.call(&"set_moving", speed)
		_rider.call(&"set_moving", speed)


func play_attack() -> void:
	if not _parts() or _dead:
		return
	_rider.call(&"play_attack")
	_steed.call(&"play_attack")


## The charge hit (Unit.charged): the steed's charge (head low, lunge) + the rider's couched lance.
func play_charge() -> void:
	if not _parts() or _dead:
		return
	_steed.call(&"play_charge")
	_rider.call(&"play_charge")


func play_hit() -> void:
	if _parts():
		_steed.call(&"play_hit")
		_rider.call(&"play_hit")


## The steed first (the rider then rides its fall instead of being thrown).
func play_death() -> void:
	if not _parts() or _dead:
		return
	_dead = true
	_steed.call(&"play_death")
	_rider.call(&"play_death")


func revive() -> void:
	if not _parts():
		return
	_dead = false
	_steed.call(&"revive")
	_rider.call(&"revive")
	_rider.call(&"set_seated", true, _steed)


func play_cast(spell_id: StringName) -> void:
	if _parts() and not _dead:
		_rider.call(&"play_cast", spell_id)


func play_level_up() -> void:
	if _parts():
		_steed.call(&"play_level_up")
		_rider.call(&"play_level_up")


func set_veterancy(level: int) -> void:
	if _parts():
		_steed.call(&"set_veterancy", level)
		_rider.call(&"set_veterancy", level)


func set_status(id: StringName, on: bool) -> bool:
	if not _parts():
		return false
	var a: bool = bool(_rider.call(&"set_status", id, on))
	var b: bool = bool(_steed.call(&"set_status", id, on))
	return a or b


func set_barded(on: bool) -> void:
	if _parts():
		_steed.call(&"set_barded", on)


func is_barded() -> bool:
	return _parts() and bool(_steed.call(&"is_barded"))


func play_fidget() -> void:
	if _parts():
		_steed.call(&"play_fidget")


func set_carrying(_on: bool) -> void:
	pass


func set_seated(on: bool, mount: Node3D = null) -> void:
	if _parts():
		_rider.call(&"set_seated", on, mount if mount else _steed)


func is_seated() -> bool:
	return _parts() and bool(_rider.call(&"is_seated"))


# ================================================================ read-only

func get_lance_tip() -> Vector3:
	if _parts():
		return _rider.call(&"get_lance_tip")
	return global_position + Vector3(0.2, 2.0, 3.0)


func lance_pitch() -> float:
	return float(_rider.call(&"lance_pitch")) if _parts() else 0.0


func couch_amount() -> float:
	return float(_rider.call(&"couch_amount")) if _parts() else 0.0


func is_charging() -> bool:
	return _parts() and bool(_rider.call(&"is_charging"))


func gait_phase() -> float:
	return float(_steed.call(&"gait_phase")) if _parts() else 0.0


func gallop_blend() -> float:
	return float(_steed.call(&"gallop_blend")) if _parts() else 0.0


func is_galloping() -> bool:
	return _parts() and bool(_steed.call(&"is_galloping"))


func rider_model() -> Node3D:
	_parts()
	return _rider


func mount_model() -> Node3D:
	_parts()
	return _steed


func authored_mesh_count() -> int:
	if not _parts():
		return 0
	return int(_rider.call(&"authored_mesh_count")) + int(_steed.call(&"authored_mesh_count"))


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
