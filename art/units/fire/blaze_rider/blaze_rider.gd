class_name BlazeRiderModel
extends Node3D
## Blaze Rider (cavalry-mounts.md 10, task 13.V10): the Fire shock cavalry = the unit's model_scene
## (art/units/fire/blaze_rider.tscn, same path as the old one-piece model). One scene, two kit models side by side
## (same transform, like the Glade Outrider): "Boar" = the shared 13.V2 Ember Boar (MountModel, unchanged) and
## "Rider" = BlazeRiderRider (a FireModel seated on it with the kit's set_seated; its _pose_seated carries the lance).
## This root forwards the unit hooks the old model had (all has_method-guarded by callers; safe before _ready):
##   set_team_color(c), set_moving(speed) (the boar walks / gallops from its gallop_speed 3.3 m/s: the rider's 7.5 is
##   a full gallop; the rider bobs with the gait, the lance lowers), play_attack() (the rider's `lance_charge` thrust,
##   melee: attack_windup 0, + the boar's tusk toss, both striking at ~0.12 s), play_hit(), play_death() + signal
##   death_finished (1.0 s: the boar rolls over and smoulders, the rider rides the fall and burns away), revive() (both,
##   re-seated), play_cast(id), play_level_up(), set_veterancy(level), set_status(id, on) -> bool, set_carrying(on)
##   (no-op), set_seated(on, mount = null) / is_seated().
## New: play_charge() (Unit.charged: the boar's charge (head drops, tusks level, lunge, gore toss, the mane flares) +
##   the rider's couched lance, lean and lance-head flare, strike 0.10 s), set_barded(on) / is_barded() (the boar's
##   bronze barding), play_fidget().
## Read-only: attack_style &"lance_charge", attack_windup 0.0, body_height, get_lance_tip() / get_weapon_tip() (world),
##   lance_pitch() -> float (deg, negative = tip up), couch_amount() -> float, is_charging(), gait_phase(),
##   gallop_blend(), is_galloping(), rider_model(), mount_model(), authored_mesh_count(); `_speed` mirrors the last
##   set_moving (tests read the model's _speed like a CharacterModel's).
## Signals (as the Gloam Rider's): death_finished, charge_struck(at: Vector3) (the charge hit frame, lance tip, world:
##   13.V20 impact), lance_struck(at: Vector3) (the attack's hit frame, lance tip).

signal death_finished
signal charge_struck(at: Vector3)
signal lance_struck(at: Vector3)

@export var body_height: float = 1.9
@export var attack_style: StringName = &"lance_charge"
@export_range(0.0, 0.15, 0.01) var attack_windup: float = 0.0
@export var kingdom_color: Color = Color(0.85, 0.3, 0.12)
## The Unit writes its move speed here at spawn (walk-rate tuning of plain CharacterModels). Not forwarded: the boar
## keeps its own walk tuning and gallops from its gallop_speed.
var stride_speed: float = 7.5
## The last set_moving speed (m/s).
var _speed: float = 0.0

## Kit audit compatibility (art/units/kit/tools/kitfix_glow_check.gd -- --audit and test_a17 read these off a unit's
## model root like a CharacterModel's): the flash / glow instances of both models, the boar's blob, _materials_of().
var _flash_all_targets: Array[GeometryInstance3D]:
	get:
		return _union(&"_flash_all_targets")
var _glow_nodes: Array[GeometryInstance3D]:
	get:
		return _union(&"_glow_nodes")
var _shadow: GeometryInstance3D:
	get:
		return _boar.get(&"_shadow") as GeometryInstance3D if _parts() else null

var _boar: Node3D
var _rider: Node3D
var _dead: bool = false


func _parts() -> bool:
	if _boar == null:
		_boar = get_node_or_null(^"Boar") as Node3D
		_rider = get_node_or_null(^"Rider") as Node3D
	return _boar != null and _rider != null


func _ready() -> void:
	if not _parts():
		push_warning("BlazeRiderModel: Boar / Rider missing")
		return
	_rider.call(&"set_seated", true, _boar)
	# The boar flashes ember like its rider (FireModel), not the kit's full white (in-game grade 2026-09-30).
	_boar.set(&"hit_flash_color", FireModel.HIT_FLASH_EMBER)
	_boar.set(&"hit_flash_scale", FireModel.HIT_FLASH_SCALE)
	_boar.connect(&"death_finished", _on_boar_death_finished)
	_rider.connect(&"charge_struck", func(at: Vector3) -> void: charge_struck.emit(at))
	_rider.connect(&"lance_struck", func(at: Vector3) -> void: lance_struck.emit(at))


func _on_boar_death_finished() -> void:
	death_finished.emit()


# ================================================================ unit hooks

func set_team_color(c: Color) -> void:
	if _parts():
		_boar.call(&"set_team_color", c)
		_rider.call(&"set_team_color", c)


func set_moving(speed: float) -> void:
	_speed = speed
	if _parts():
		_boar.call(&"set_moving", speed)
		_rider.call(&"set_moving", speed)


func play_attack() -> void:
	if not _parts() or _dead:
		return
	_rider.call(&"play_attack")
	_boar.call(&"play_attack")


## The charge hit (Unit.charged): boar charge + couched lance. 0.85 s.
func play_charge() -> void:
	if not _parts() or _dead:
		return
	_boar.call(&"play_charge")
	_rider.call(&"play_charge")


func play_hit() -> void:
	if _parts():
		_boar.call(&"play_hit")
		_rider.call(&"play_hit")


## The boar first (the rider then rides its fall instead of being thrown).
func play_death() -> void:
	if not _parts() or _dead:
		return
	_dead = true
	_speed = 0.0
	_boar.call(&"play_death")
	_rider.call(&"play_death")


func revive() -> void:
	if not _parts():
		return
	_dead = false
	_boar.call(&"revive")
	_rider.call(&"revive")
	_rider.call(&"set_seated", true, _boar)


func play_cast(spell_id: StringName) -> void:
	if _parts() and not _dead:
		_rider.call(&"play_cast", spell_id)
		_boar.call(&"play_cast", spell_id)


func play_level_up() -> void:
	if _parts():
		_boar.call(&"play_level_up")
		_rider.call(&"play_level_up")


func set_veterancy(level: int) -> void:
	if _parts():
		_boar.call(&"set_veterancy", level)
		_rider.call(&"set_veterancy", level)


func set_status(id: StringName, on: bool) -> bool:
	if not _parts():
		return false
	var a: bool = bool(_rider.call(&"set_status", id, on))
	var b: bool = bool(_boar.call(&"set_status", id, on))
	return a or b


func set_barded(on: bool) -> void:
	if _parts():
		_boar.call(&"set_barded", on)


func is_barded() -> bool:
	return _parts() and bool(_boar.call(&"is_barded"))


func play_fidget() -> void:
	if _parts():
		_boar.call(&"play_fidget")


func set_carrying(_on: bool) -> void:
	pass


func set_seated(on: bool, mount: Node3D = null) -> void:
	if _parts():
		_rider.call(&"set_seated", on, mount if mount else _boar)


func is_seated() -> bool:
	return _parts() and bool(_rider.call(&"is_seated"))


# ================================================================ read-only

## World position of the lance tip.
func get_lance_tip() -> Vector3:
	if _parts():
		return _rider.call(&"get_lance_tip")
	return global_position + Vector3(0, 1.8, 2.0)


func get_weapon_tip() -> Variant:
	return get_lance_tip()


func lance_pitch() -> float:
	return float(_rider.call(&"lance_pitch")) if _parts() else 0.0


func couch_amount() -> float:
	return float(_rider.call(&"couch_amount")) if _parts() else 0.0


func is_charging() -> bool:
	return _parts() and bool(_rider.call(&"is_charging"))


func gait_phase() -> float:
	return float(_boar.call(&"gait_phase")) if _parts() else 0.0


func gallop_blend() -> float:
	return float(_boar.call(&"gallop_blend")) if _parts() else 0.0


func is_galloping() -> bool:
	return _parts() and bool(_boar.call(&"is_galloping"))


func rider_model() -> Node3D:
	_parts()
	return _rider


func mount_model() -> Node3D:
	_parts()
	return _boar


func authored_mesh_count() -> int:
	if not _parts():
		return 0
	return int(_rider.call(&"authored_mesh_count")) + int(_boar.call(&"authored_mesh_count"))


# ================================================================ kit audit compatibility

## The materials a geometry instance of either model draws with (CharacterModel._materials_of; the kit audit).
func _materials_of(gi: GeometryInstance3D) -> Array[Material]:
	if not _parts():
		return []
	var owner_model: Node3D = _boar if _boar.is_ancestor_of(gi) else _rider
	return owner_model.call(&"_materials_of", gi)


func _union(prop: StringName) -> Array[GeometryInstance3D]:
	var out: Array[GeometryInstance3D] = []
	if _parts():
		out.append_array(_rider.get(prop) as Array[GeometryInstance3D])
		out.append_array(_boar.get(prop) as Array[GeometryInstance3D])
	return out


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
