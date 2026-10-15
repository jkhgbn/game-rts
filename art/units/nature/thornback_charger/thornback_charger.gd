extends Node3D
## Thornback Charger (stables.md 2, Nature slot C, tier 2 "heavy stag charger"; rank 3 "Thornback Warden"): the unit's
## model_scene. One scene, two kit models side by side (like the Glade Outrider): "Elk" = the Thornback elk
## (parts/thornback_elk.gd, a MountModel: a massive dark bark-brown stag with a ridge of big bark thorns along its spine
## and a short forward battering rack of pale antler) and "Rider" = the thorn lancer (parts/thornback_warden.gd, a
## NatureWarModel seated on it: bark lamellar, team tabard and cape, a pale moss mantle, an antler-crested helm, a
## wicker kite shield and the thorn lance with a team pennant).
## Read at 40 m: the biggest Nature rider after the Glade Outrider: a dark hump-backed stag bristling with thorns, a
## pale forward rack, a rider in team green with a pale moss mantle and a long lance.
## This root forwards the unit hooks (all has_method-guarded by callers; safe before _ready):
##   set_team_color(c) (the elk's blanket + the rider's tabard / cape / shield emblem / pennant), set_moving(speed)
##   (the elk walks / gallops from its gallop_speed 3.2 m/s: the unit's 6.6 is a gallop; the lance lowers level),
##   play_attack() (the rider's lance thrust, strike at 0.14 s, while the elk dips and tosses its rack), play_charge()
##   (the elk's charge + the rider's couched lance, impact 0.10 s), play_hit(), play_death() + signal death_finished
##   (1.0 s: the elk rolls over and withers, the rider returns to the grove), revive(), play_cast(id), play_level_up(),
##   set_veterancy(level), set_status(id, on) -> bool, set_barded(on) / is_barded() (the bark breastplate is part of the
##   elk: no-op / true), play_fidget(), set_seated(on, mount = null) / is_seated(), set_carrying(on) (no-op), dances
##   (MountedDance), set_rank(rank) (rank 3: the warden's standard, node "RankCrest" on the rider; meta `rank`).
## Read-only: attack_style &"lance_thrust", attack_windup 0.0 (melee), body_height, get_lance_tip() -> Vector3,
##   gait_phase(), gallop_blend(), is_galloping(), rider_model(), mount_model(), authored_mesh_count();
##   signal lance_struck(at: Vector3) (world, the lance tip at the strike frame: for a thorn-hit VFX).

signal death_finished
signal lance_struck(at: Vector3)

@export var body_height: float = 2.4
@export var attack_style: StringName = &"lance_thrust"
@export_range(0.0, 0.15, 0.01) var attack_windup: float = 0.0
@export var kingdom_color: Color = Color(0.35, 0.7, 0.25)
## Footprint rule (art-units 1.1): a mounted unit reaches 2.4 x its radius along z like the quadruped it rides.
## Read by the tools only (gameplay never reads it).
@export var is_quadruped: bool = true
## The Unit writes its move speed here at spawn. Not forwarded: the elk gallops from its own gallop_speed.
var stride_speed: float = 6.6
## G-F: Unit._build_model sets this on the root; both kit models get it (they pause their animation and looping
## emitters off-camera).
var offscreen_freeze: bool = false:
	set(v):
		offscreen_freeze = v
		OffscreenEmitters.forward_freeze(self, v)

var _mount: Node3D
var _rider: Node3D
var _dead: bool = false


func _parts() -> bool:
	if _mount == null:
		_mount = get_node_or_null(^"Elk") as Node3D
		_rider = get_node_or_null(^"Rider") as Node3D
	return _mount != null and _rider != null


func _ready() -> void:
	if not _parts():
		push_warning("ThornbackCharger: Elk / Rider missing")
		return
	_rider.call(&"set_seated", true, _mount)
	_mount.connect(&"death_finished", _on_mount_death_finished)
	if _rider.has_signal(&"lance_struck"):
		_rider.connect(&"lance_struck", func(at: Vector3) -> void: lance_struck.emit(at))


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


## The rider's lance thrust; the elk dips and tosses its rack with it (its mount_toss).
func play_attack() -> void:
	if _parts() and not _dead:
		_rider.call(&"play_attack")
		_mount.call(&"play_attack")


## The cavalry charge hit: the elk levels its rack and lunges, the rider couches the lance.
func play_charge() -> void:
	if not _parts() or _dead:
		return
	_mount.call(&"play_charge")
	_rider.call(&"play_charge_pose")


func play_hit() -> void:
	if _parts():
		_mount.call(&"play_hit")
		_rider.call(&"play_hit")


## The elk first (the rider then rides its fall instead of being thrown).
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


## The elk's bark breastplate is part of its model (always on): kept for the cavalry API.
func set_barded(_on: bool) -> void:
	pass


func is_barded() -> bool:
	return true


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

func get_lance_tip() -> Vector3:
	if _parts():
		return _rider.call(&"get_lance_tip")
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


## Stables16 rank-3 look ("Thornback Warden"): the warden's standard ("RankCrest") on the rider. Idempotent.
func set_rank(rank: int) -> void:
	set_meta(&"rank", rank)
	if _parts():
		_rider.call(&"set_rank_look", rank >= 3)
