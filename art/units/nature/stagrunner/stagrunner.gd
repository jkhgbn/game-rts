class_name StagrunnerModel
extends Node3D
## Stagrunner (cavalry-mounts.md 4 / 10, task 13.V9): the Nature light cavalry = the unit's model_scene. One scene,
## two kit models side by side (same transform, like the Glade Outrider): "Stag" = the 13.V5 Grove Stag (MountModel,
## unchanged) and "Rider" = StagrunnerRider (a CharacterModel seated on it with the kit's set_seated, 13.V1b; its
## _pose_seated carries, couches and thrusts the bark shortspear).
## Read at 40 m vs the Glade Outrider on the same stag: a SPEAR line (upright at the walk, couched level at the
## gallop) with a team pennon and a glowing blade instead of a sideways bow; a long GOLDEN leaf cloak streaming
## straight back like a banner (the Outrider's is a short lime leaf cape); a dark bark-lamellar body with a gold leaf
## crest on a bark half-helm (the Outrider: tan jerkin, lime hood with antler twigs).
## This root forwards the unit hooks (all has_method-guarded by callers; safe before _ready):
##   set_team_color(c), set_moving(speed) (the stag walks / gallops from gallop_speed 3.5 m/s; the Stagrunner's 7.8
##   is a full gallop: the spear comes down to the couch, the cloak streams), play_attack() (`lance_charge`: the rider
##   levels and thrusts the spear at the target, strike at 0.12 s = attack_windup 0; the stag dips and tosses its
##   rack), play_charge() (the charge hit, Unit.charged: the stag's charge + the rider's couched lunge, strike at
##   0.10 s, blade flare, cloak flare; 0.85 s), play_hit(), play_death() + signal death_finished (1.0 s: the stag
##   rolls over, the rider rides the fall), revive() (both, re-seated), play_cast(id), play_level_up(),
##   set_veterancy(level), set_status(id, on) -> bool, set_barded(on) / is_barded() (the stag's woven bark),
##   play_fidget(), set_seated(on, mount = null) / is_seated() (the rider; null mount = the own stag),
##   set_carrying(on) (no-op).
## Aim: set_aim_target(target: Variant) = a Node3D (tracked every frame), a Vector3 world point or null (forward).
##   Without it, play_attack() / play_charge() aim at the owning unit's `attack_target` (read with get()).
## Read-only: attack_style &"lance_charge", attack_windup 0.0, body_height, get_spear_tip() -> Vector3 (world),
##   get_spear_dir() -> Vector3 (world, unit), spear_elevation() -> float (deg), gait_phase(), gallop_blend(),
##   is_galloping(), is_charging(), rider_model(), mount_model(), authored_mesh_count();
##   signal spear_struck(tip: Vector3, dir: Vector3, charge: bool) (world, at the strike frame of an attack or a
##   charge: for the 13.V20 charge streak / impact VFX).

signal death_finished
signal spear_struck(tip: Vector3, dir: Vector3, charge: bool)

@export var body_height: float = 2.6
@export var attack_style: StringName = &"lance_charge"
@export_range(0.0, 0.15, 0.01) var attack_windup: float = 0.0
@export var kingdom_color: Color = Color(0.35, 0.7, 0.25)
## The Unit writes its move speed here at spawn (walk-rate tuning of plain CharacterModels). Not forwarded: the stag
## keeps its own walk tuning and gallops from its gallop_speed.
var stride_speed: float = 7.8
## G-F: Unit._build_model sets this on the root; both kit models get it (they pause their animation and looping
## emitters off-camera).
var offscreen_freeze: bool = false:
	set(v):
		offscreen_freeze = v
		OffscreenEmitters.forward_freeze(self, v)

var _stag: Node3D
var _rider: Node3D
var _aim_explicit: bool = false
var _dead: bool = false


func _parts() -> bool:
	if _stag == null:
		_stag = get_node_or_null(^"Stag") as Node3D
		_rider = get_node_or_null(^"Rider") as Node3D
	return _stag != null and _rider != null


func _ready() -> void:
	if not _parts():
		push_warning("StagrunnerModel: Stag / Rider missing")
		return
	_rider.call(&"set_seated", true, _stag)
	_stag.connect(&"death_finished", _on_stag_death_finished)
	if _rider.has_signal(&"spear_struck"):
		_rider.connect(&"spear_struck", func(tip: Vector3, dir: Vector3, charge: bool) -> void:
			spear_struck.emit(tip, dir, charge))


func _on_stag_death_finished() -> void:
	death_finished.emit()


# ================================================================ unit hooks

func set_team_color(c: Color) -> void:
	if _parts():
		_stag.call(&"set_team_color", c)
		_rider.call(&"set_team_color", c)


func set_moving(speed: float) -> void:
	if _parts():
		_stag.call(&"set_moving", speed)
		_rider.call(&"set_moving", speed)


## The spear thrust (the rider) and a rack toss (the stag), both striking at 0.12 s. During a charge the stag keeps
## its charge pose (the charge hit usually arrives with the attack).
func play_attack() -> void:
	if not _parts() or _dead:
		return
	_auto_aim()
	_rider.call(&"play_attack")
	if not is_charging():
		_stag.call(&"play_attack")


## The charge hit (call on Unit.charged): the stag's charge (antlers levelled, lunge, toss) + the rider's couched
## lunge with the blade flare; strike at 0.10 s (spear_struck with charge = true).
func play_charge() -> void:
	if not _parts() or _dead:
		return
	_auto_aim()
	_stag.call(&"play_charge")
	_rider.call(&"play_charge")


## True during the 0.85 s charge (the rider's timer).
func is_charging() -> bool:
	return _parts() and not _dead and bool(_rider.call(&"is_charging"))


func play_hit() -> void:
	if _parts():
		_stag.call(&"play_hit")
		_rider.call(&"play_hit")


## The stag first (the rider then rides its fall instead of being thrown).
func play_death() -> void:
	if not _parts() or _dead:
		return
	_dead = true
	_stag.call(&"play_death")
	_rider.call(&"play_death")


func revive() -> void:
	if not _parts():
		return
	_dead = false
	_stag.call(&"revive")
	_rider.call(&"revive")
	_rider.call(&"set_seated", true, _stag)


func play_cast(spell_id: StringName) -> void:
	if _parts() and not _dead:
		_rider.call(&"play_cast", spell_id)


func play_level_up() -> void:
	if _parts():
		_stag.call(&"play_level_up")
		_rider.call(&"play_level_up")


func set_veterancy(level: int) -> void:
	if _parts():
		_stag.call(&"set_veterancy", level)
		_rider.call(&"set_veterancy", level)


func set_status(id: StringName, on: bool) -> bool:
	if not _parts():
		return false
	var a: bool = bool(_rider.call(&"set_status", id, on))
	var b: bool = bool(_stag.call(&"set_status", id, on))
	return a or b


func set_barded(on: bool) -> void:
	if _parts():
		_stag.call(&"set_barded", on)


func is_barded() -> bool:
	return _parts() and bool(_stag.call(&"is_barded"))


func play_fidget() -> void:
	if _parts():
		_stag.call(&"play_fidget")


func set_carrying(_on: bool) -> void:
	pass


func set_seated(on: bool, mount: Node3D = null) -> void:
	if _parts():
		_rider.call(&"set_seated", on, mount if mount else _stag)


func is_seated() -> bool:
	return _parts() and bool(_rider.call(&"is_seated"))


# ================================================================ aim / spear

## Where the rider thrusts: a Node3D (tracked every frame), a Vector3 world point, or null (forward). Once called,
## play_attack() / play_charge() stop looking up the owning unit's attack_target by themselves.
func set_aim_target(target: Variant) -> void:
	_aim_explicit = true
	if _parts():
		_rider.call(&"set_aim_target", target)


## World position of the spear's blade tip.
func get_spear_tip() -> Vector3:
	if _parts():
		return _rider.call(&"get_spear_tip")
	return global_position + Vector3.UP * 2.8


## World direction of the spear (butt -> tip, unit length).
func get_spear_dir() -> Vector3:
	if _parts():
		return _rider.call(&"get_spear_dir")
	return Vector3.UP


## Spear elevation above the horizontal (deg): ~65 carried at the walk, ~10 couched at the gallop, < 0 thrusting.
func spear_elevation() -> float:
	return float(_rider.call(&"spear_elevation")) if _parts() else 0.0


func gait_phase() -> float:
	return float(_stag.call(&"gait_phase")) if _parts() else 0.0


func gallop_blend() -> float:
	return float(_stag.call(&"gallop_blend")) if _parts() else 0.0


func is_galloping() -> bool:
	return _parts() and bool(_stag.call(&"is_galloping"))


func rider_model() -> Node3D:
	_parts()
	return _rider


func mount_model() -> Node3D:
	_parts()
	return _stag


func authored_mesh_count() -> int:
	if not _parts():
		return 0
	return int(_rider.call(&"authored_mesh_count")) + int(_stag.call(&"authored_mesh_count"))


func _auto_aim() -> void:
	if _aim_explicit:
		return
	var t := _owner_target()
	if t:
		_rider.call(&"set_aim_target", t)


## The owning unit's current attack target (the model sits under Unit._visual): a Node3D or null.
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
