class_name SupportCaster
extends Node
## Support autocast (kingdom-ice.md 2.3), shared by Ice (Rime Seer: shield) and Nature (Bloomtender:
## heal). Unit._ready adds one, named "SupportCaster", to every unit whose UnitType has `support_kind`.
## Every `support_interval` s, while the unit is alive and can_act(): the friendly soldier or wizard
## (never workers, buildings or itself) within `support_range` with the lowest HP ratio below 0.80
## gets `add_shield(support_amount, support_duration)` (skipping units that already carry this unit
## type's shield) or `heal(support_amount)`. Independent of the attack timer. Nothing found: the next
## try is one interval later. No XP is given.

## Emitted on every cast (the VFX artist hooks the real beam here; `kind` = &"shield" or &"heal").
signal support_cast(caster: Unit, target: Unit, kind: StringName)

const HP_RATIO_BELOW := 0.80
const BEAM_TIME := 0.25
const FIRST_TRY := 1.0          # a new unit looks for a target this long after spawning

var unit: Unit = null
var kind: StringName = &""
var amount := 0.0
var interval := 1.0
var support_range := 0.0
var duration := 0.0
## The shield tag written to Unit.shield_source (this unit type's id).
var source_id: StringName = &""
## Set false when a real VFX (listening to support_cast) replaces the placeholder beam.
var show_placeholder_beam := true

var _left := FIRST_TRY
var _research_sig := ""
var _cur_amount := 0.0
var _cur_interval := 1.0
var _cur_range := 0.0


## Reads the numbers from `u.unit_type`. Called by Unit before add_child.
func setup(u: Unit) -> void:
	unit = u
	var t := u.unit_type
	if t == null:
		return
	kind = t.support_kind
	amount = t.support_amount
	interval = maxf(0.1, t.support_interval)
	support_range = t.support_range
	duration = t.support_duration
	source_id = StringName("support:" + String(t.id))
	_left = minf(FIRST_TRY, interval)
	_refresh_research()


## The numbers in use now: the type's, or the team's unit research row (UR.G3, unit-upgrades.md 10:
## support_amount / support_interval / support_range through UnitResearch.param). Cached; refreshed at setup and
## whenever UnitResearch re-applies the unit (its row signature meta changes: a row done mid-life, a load).
func current_amount() -> float:
	return _cur_amount


func current_interval() -> float:
	return _cur_interval


func current_range() -> float:
	return _cur_range


func _refresh_research() -> void:
	_research_sig = str(unit.get_meta(UnitResearch.SIG_META, "")) if unit else ""
	_cur_amount = UnitResearch.param(unit, &"support_amount", amount) if unit else amount
	_cur_interval = maxf(0.1, UnitResearch.param(unit, &"support_interval", interval)) if unit else interval
	_cur_range = UnitResearch.param(unit, &"support_range", support_range) if unit else support_range


## Seconds before the next try.
func time_left() -> float:
	return maxf(0.0, _left)


func _physics_process(delta: float) -> void:
	if unit == null or kind == &"":
		return
	_left -= delta
	if _left > 0.0:
		return
	if not unit.is_alive() or not unit.can_act():
		return   # frozen: try again as soon as it thaws
	if unit.get_meta(UnitResearch.SIG_META, "") != _research_sig:
		_refresh_research()
	_left = _cur_interval
	try_cast()


## Picks a target and casts at once (ignores the timer). Returns the target, or null if none.
func try_cast() -> Unit:
	if unit == null or not unit.can_act():
		return null
	var target := find_target()
	if target == null:
		return null
	var amt := current_amount()
	match kind:
		&"shield":
			if target.shield >= amt:
				return null
			target.add_shield(amt, duration)
			target.shield_source = source_id
		&"heal":
			target.heal(amt)
		_:
			return null
	# The character model's support pose (Rime Seer, Bloomtender): play_cast(&"support").
	unit.model_call(&"play_cast", [&"support"])
	if show_placeholder_beam:
		_spawn_beam(target)
	support_cast.emit(unit, target, kind)
	return target


## The friendly soldier / wizard in range with the lowest HP ratio below 0.80 (null if none).
func find_target() -> Unit:
	var best: Unit = null
	var best_ratio := HP_RATIO_BELOW
	var me := unit.global_position
	var reach := current_range()
	var r2 := reach * reach
	var amt := current_amount()
	for node in unit.get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or u == unit or not Teams.is_allied_fast(int(u.team), int(unit.team)) or not u.is_alive() or u.max_hp <= 0.0:
			continue
		var ratio := u.hp / u.max_hp
		if ratio >= best_ratio:
			continue
		var dx := u.global_position.x - me.x
		var dz := u.global_position.z - me.z
		if dx * dx + dz * dz > r2 or not _is_soldier_or_wizard(u):
			continue
		# Never replace a shield as large or larger (Snow Shield, Vow, Rime Aegis, items; R3-2), nor our own.
		if kind == &"shield" and u.shield > 0.0 and (u.shield_source == source_id or u.shield >= amt):
			continue
		best = u
		best_ratio = ratio
	return best


static func _is_soldier_or_wizard(u: Unit) -> bool:
	if u.is_in_group(&"heroes") or u.is_in_group(&"enemy_heroes") or u.has_method(&"command_cast"):
		return true
	return u.unit_type != null and not u.unit_type.is_worker


# Placeholder: a thin glowing cylinder from the caster's hands to the target for 0.25 s.
func _spawn_beam(target: Unit) -> void:
	var scene := unit.get_tree().current_scene
	if scene == null:
		return
	var from := unit.global_position + Vector3.UP * unit.body_height * 0.7
	var to := target.global_position + Vector3.UP * target.body_height * 0.6
	var length := from.distance_to(to)
	if length < 0.05:
		return
	var color := unit.unit_type.projectile_color if unit.unit_type else Color(0.6, 0.9, 1.0)
	var beam := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.04
	cyl.bottom_radius = 0.04
	cyl.height = length
	cyl.radial_segments = 6
	cyl.rings = 1
	beam.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	beam.material_override = mat
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scene.add_child(beam)
	var y := (to - from) / length
	var x := y.cross(Vector3.UP)
	if x.length() < 0.01:
		x = Vector3.RIGHT
	x = x.normalized()
	var z := x.cross(y).normalized()
	beam.global_transform = Transform3D(Basis(x, y, z), (from + to) * 0.5)
	unit.get_tree().create_timer(BEAM_TIME).timeout.connect(beam.queue_free)
