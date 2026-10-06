class_name Projectile
extends Node3D
## Arrows, magic bolts and fireballs. Flies along an arc, then deals damage.
## A projectile aimed at a target (unit or building) follows it. One aimed at the ground explodes
## in an area, hurting enemy units and enemy buildings (group "buildings") in the radius.
## The shooter can be a Unit or a building (tower): anything with a `team`.

## Emitted when a projectile aimed at a target lands, with the damage it really dealt
## (capped by the target's remaining HP). Used by life-drain spells like Shadow Lance.
signal hit_unit(target: Node3D, damage_dealt: float)
## Emitted by a projectile aimed at the ground (Fireball) for each unit / building its blast hurt,
## with the HP it really lost. Used for Wizard.spell_hit.
signal hit_area(target: Node3D, damage_dealt: float)

const BUILDING_AIM_HEIGHT := 1.5

var source: Node3D
var source_team: int
var damage := 10.0
var splash_radius := 0.0
var color := Color(1.0, 0.6, 0.2)

var _start := Vector3.ZERO
var _target_pos := Vector3.ZERO
var _target: Node3D
var _target_offset := Vector3.UP   # where on the target we aim (a building: its wall facing us)
var _duration := 0.5
var _t := 0.0
var _arc := 0.5
var _mesh: MeshInstance3D


## Fires at a Unit or a building and follows it. `from_unit` is the shooter (Unit or tower).
func launch_at_target(from_unit: Node3D, from: Vector3, target: Node3D, dmg: float, col: Color, size: float,
		speed: float = 25.0, arc: float = 0.6) -> void:
	_target = target
	if not target is Unit:
		var away := from - target.global_position
		away.y = 0.0
		var reach := Unit.radius_of(target) * 0.8
		_target_offset = Vector3.UP * BUILDING_AIM_HEIGHT
		if away.length() > 0.01:
			_target_offset += away.normalized() * reach
	_setup(from_unit, from, target.global_position + _target_offset, dmg, 0.0, col, size, speed, arc)


## Old name, kept for existing callers. Same as launch_at_target.
func launch_at_unit(from_unit: Node3D, from: Vector3, target: Node3D, dmg: float, col: Color, size: float,
		speed: float = 25.0, arc: float = 0.6) -> void:
	launch_at_target(from_unit, from, target, dmg, col, size, speed, arc)


func launch_at_point(from_unit: Node3D, from: Vector3, target: Vector3, dmg: float, radius: float, col: Color) -> void:
	_setup(from_unit, from, target, dmg, radius, col, 0.4, 16.0, 3.0)


func _setup(from_unit: Node3D, from: Vector3, to: Vector3, dmg: float, radius: float,
		col: Color, size: float, speed: float, arc: float) -> void:
	source = from_unit
	source_team = int(from_unit.get(&"team"))
	damage = dmg
	splash_radius = radius
	color = col
	_arc = arc
	_start = from
	_target_pos = to
	_duration = max(0.15, from.distance_to(to) / speed)
	global_position = from

	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = size
	sphere.height = size * 2.0
	_mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 4.0
	_mesh.material_override = mat
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)

	if radius > 0.0:
		var light := OmniLight3D.new()
		light.light_color = col
		light.omni_range = 6.0
		light.light_energy = 2.0
		add_child(light)


func _process(delta: float) -> void:
	if _target != null:
		if _alive(_target):
			_target_pos = _target.global_position + _target_offset
		else:
			_target = null
	_t = min(1.0, _t + delta / _duration)
	global_position = _start.lerp(_target_pos, _t) + Vector3.UP * sin(_t * PI) * _arc
	if _t >= 1.0:
		_impact()


func _impact() -> void:
	set_process(false)
	var attacker: Node3D = source if is_instance_valid(source) else null
	if splash_radius > 0.0:
		for node in get_tree().get_nodes_in_group("units"):
			var u := node as Unit
			if u == null or Teams.is_allied_fast(int(u.team), int(source_team)) or not u.is_alive():
				continue
			if _flat_distance_to_impact(u) <= splash_radius + u.radius:
				var before := u.hp
				u.take_damage(damage, attacker)
				hit_area.emit(u, before - maxf(0.0, u.hp))
		for node in get_tree().get_nodes_in_group("buildings"):
			var b := node as Node3D
			if b == null or not _alive(b) or b.get(&"team") == null or Teams.is_allied_fast(int(b.get(&"team")), int(source_team)):
				continue
			if _flat_distance_to_impact(b) <= splash_radius + Unit.radius_of(b):
				var hp_b: Variant = b.get(&"hp")
				b.call(&"take_damage", damage, attacker)
				var hp_a: Variant = b.get(&"hp")
				hit_area.emit(b, float(hp_b) - maxf(0.0, float(hp_a)) if hp_b != null and hp_a != null else damage)
		_explode()
	else:
		if _target != null and is_instance_valid(_target):
			var hp_before := float(_target.get(&"hp")) if _target.get(&"hp") != null else 0.0
			_target.call(&"take_damage", damage, attacker)
			var hp_after: Variant = _target.get(&"hp")
			var dealt: float = hp_before - maxf(0.0, float(hp_after)) if hp_after != null else damage
			hit_unit.emit(_target, dealt)
		queue_free()


func _flat_distance_to_impact(node: Node3D) -> float:
	return Vector2(node.global_position.x - _target_pos.x, node.global_position.z - _target_pos.z).length()


static func _alive(node: Variant) -> bool:
	return node != null and is_instance_valid(node) and (node as Object).has_method(&"is_alive") \
			and bool((node as Object).call(&"is_alive"))


func _explode() -> void:
	_mesh.visible = false
	var blast := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	blast.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(color, 0.8)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	blast.material_override = mat
	blast.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	blast.scale = Vector3.ONE * 0.3
	add_child(blast)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(blast, "scale", Vector3.ONE * splash_radius, 0.3)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.45)
	tween.chain().tween_callback(queue_free)
