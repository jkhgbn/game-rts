class_name SpellStatus
extends Node
## A timed status on a unit (spells.md "Statuses"): `haste` (Kindle) and `shroud` (Umbral Shroud).
## Use SpellStatus.apply(unit, id, duration). Re-applying refreshes the timer, never stacks.
## - If the unit has `apply_status(id, duration)` (Unit contract, when the lead adds it), that is used.
## - Else this node lives under the unit ("Status_<id>") and: speed / attack cooldown go through the
##   Stats API (`add_modifier` / `remove_modifier`) when the unit has it, else the fields are changed
##   and restored; "damage taken x 0.5" gives back half of every HP loss it sees (a hit bigger than the
##   unit's HP still kills: ask for a `damage_taken` stat or `apply_status` in unit.gd to do it exactly).
## Placeholder look: a small coloured sphere above the head (tech-artist replaces it, 3.U2).

signal expired(unit: Node3D, status_id: StringName)

## id -> {attack_cooldown_mult, move_speed_add, damage_taken_mult, color}
const STATUSES := {
	&"haste": {"attack_cooldown_mult": 0.70, "move_speed_add": 1.5, "damage_taken_mult": 1.0,
			"color": Color(1.0, 0.55, 0.15)},
	&"shroud": {"attack_cooldown_mult": 1.0, "move_speed_add": 2.0, "damage_taken_mult": 0.5,
			"color": Color(0.4, 0.2, 0.6, 0.5)},
}

var status_id: StringName
var time_left := 0.0
var unit: Node3D

var _uses_modifier := false
var _saved_cooldown := 0.0
var _saved_speed := 0.0
var _last_hp := 0.0
var _mark: MeshInstance3D


## Applies (or refreshes) status `id` on `target` for `seconds`. Returns false for an unknown id or
## a dead / invalid target.
static func apply(target: Node3D, id: StringName, seconds: float) -> bool:
	if not STATUSES.has(id) or target == null or not is_instance_valid(target):
		return false
	if target.has_method(&"is_alive") and not bool(target.call(&"is_alive")):
		return false
	if target.has_method(&"apply_status"):
		target.call(&"apply_status", id, seconds)
		return true
	var existing := target.get_node_or_null(NodePath("Status_" + String(id))) as SpellStatus
	if existing:
		existing.time_left = seconds
		return true
	var s := SpellStatus.new()
	s.name = "Status_" + String(id)
	s.status_id = id
	s.time_left = seconds
	s.unit = target
	target.add_child(s)
	return true


## Seconds left of status `id` on `target` (0 when it has none). Only sees statuses run by this node.
static func time_left_on(target: Node3D, id: StringName) -> float:
	if target == null or not is_instance_valid(target):
		return 0.0
	var s := target.get_node_or_null(NodePath("Status_" + String(id))) as SpellStatus
	return s.time_left if s else 0.0


func _ready() -> void:
	var data: Dictionary = STATUSES[status_id]
	var cd_mult: float = data["attack_cooldown_mult"]
	var speed_add: float = data["move_speed_add"]
	if unit.has_method(&"add_modifier"):
		_uses_modifier = true
		var mods := {}
		if cd_mult != 1.0:
			mods["attack_cooldown_pct"] = cd_mult - 1.0
		if speed_add != 0.0:
			mods["move_speed"] = speed_add
		unit.call(&"add_modifier", StringName("status_" + String(status_id)), mods)
	else:
		_saved_cooldown = float(unit.get(&"attack_cooldown"))
		_saved_speed = float(unit.get(&"move_speed"))
		unit.set(&"attack_cooldown", _saved_cooldown * cd_mult)
		unit.set(&"move_speed", _saved_speed + speed_add)
	_last_hp = float(unit.get(&"hp"))
	_build_mark(data["color"])


func _physics_process(delta: float) -> void:
	if not is_instance_valid(unit):
		return
	var mult: float = STATUSES[status_id]["damage_taken_mult"]
	var hp := float(unit.get(&"hp"))
	if mult < 1.0 and hp < _last_hp and hp > 0.0:
		unit.call(&"heal", (_last_hp - hp) * (1.0 - mult))
		hp = float(unit.get(&"hp"))
	_last_hp = hp
	time_left -= delta
	var dead := unit.has_method(&"is_alive") and not bool(unit.call(&"is_alive"))
	if time_left <= 0.0 or dead:
		_end()


func _end() -> void:
	set_physics_process(false)
	if _uses_modifier:
		unit.call(&"remove_modifier", StringName("status_" + String(status_id)))
	else:
		unit.set(&"attack_cooldown", _saved_cooldown)
		unit.set(&"move_speed", _saved_speed)
	expired.emit(unit, status_id)
	queue_free()


func _build_mark(color: Color) -> void:
	var host := unit as Node3D
	var height := float(host.get(&"body_height")) if host.get(&"body_height") != null else 1.6
	_mark = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	var big := status_id == &"shroud"
	sphere.radius = 1.4 if big else 0.15
	sphere.height = sphere.radius * 2.0
	_mark.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(color, 0.25) if big else color
	_mark.material_override = mat
	_mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mark.position.y = height * 0.5 if big else height + 0.3
	host.add_child(_mark)
	tree_exiting.connect(_mark.queue_free)
