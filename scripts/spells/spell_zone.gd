class_name SpellZone
extends Node3D
## A ticking circle on the ground: Ember Step's scorched ground and Soul Siphon.
## Every `tick_interval` seconds, each living enemy (units, neutrals and buildings, duck typing) whose
## edge is inside `radius` takes `tick_damage` with the caster as attacker; the caster heals
## `heal_ratio` x the damage really dealt on each tick (even if he walked away; not when dead).
## Ticks at 0.5, 1.0 ... duration: a 4 s zone ticks 8 times.
## Placeholder look: a flat disc (tech-artist replaces it, 3.U2).
## Fog: a zone of a team not allied to the local player is drawn only while its centre is in the player's sight
## (VfxFog rule, re-checked at VfxFog.RECHECK); ticks are not affected.

signal ticked(total_dealt: float)
## One target hurt by a tick, with the HP it really lost (Wizard.spell_hit).
signal hit_target(target: Node3D, dealt: float)
signal finished

var spell_id: StringName
var caster: Node3D
var team := 0
var radius := 2.5
var duration := 4.0
var tick_damage := 5.0
var tick_interval := 0.5
var heal_ratio := 0.0
var color := Color(1.0, 0.45, 0.1)
var total_dealt := 0.0

var _elapsed := 0.0
var _next_tick := 0.0
var _mat: StandardMaterial3D
var _fog_check_left := 0.0


func setup(p_caster: Node3D, p_team: int, p_radius: float, p_duration: float, p_tick_damage: float,
		p_interval: float, p_heal_ratio: float, p_color: Color) -> void:
	caster = p_caster
	team = p_team
	radius = p_radius
	duration = p_duration
	tick_damage = p_tick_damage
	tick_interval = maxf(0.05, p_interval)
	heal_ratio = p_heal_ratio
	color = p_color
	_next_tick = tick_interval


func _ready() -> void:
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.04
	disc.mesh = cyl
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color = Color(color, 0.55)
	disc.material_override = _mat
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disc.position.y = 0.06
	add_child(disc)
	_update_fog_visibility()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	_fog_check_left -= delta
	if _fog_check_left <= 0.0:
		_update_fog_visibility()
	while _elapsed + 0.0001 >= _next_tick and _next_tick <= duration + 0.0001:
		_tick()
		_next_tick += tick_interval
	if duration - _elapsed < 1.0 and _mat:
		_mat.albedo_color.a = 0.55 * clampf(duration - _elapsed, 0.0, 1.0)
	if _elapsed >= duration:
		set_physics_process(false)
		finished.emit()
		queue_free()


## Visuals only (the whole zone node): see the class comment.
func _update_fog_visibility() -> void:
	_fog_check_left = VfxFog.RECHECK
	var fog := VfxFog.fog()
	if fog == null or not fog.enabled or Teams.is_allied_fast(int(team), int(fog.local_team)):
		visible = true
	else:
		visible = VfxFog.ok(team, global_position)


func _tick() -> void:
	var attacker: Node3D = caster if is_instance_valid(caster) else null
	var dealt := 0.0
	for group in [&"units", &"buildings"]:
		for node in get_tree().get_nodes_in_group(group):
			var t := node as Node3D
			if t == null or not _is_enemy(t):
				continue
			var d := Vector2(t.global_position.x - global_position.x, t.global_position.z - global_position.z).length()
			if d > radius + SpellCaster.edge_radius(t):
				continue
			var one := SpellCaster.deal_damage(t, tick_damage, attacker)
			dealt += one
			hit_target.emit(t, one)
	total_dealt += dealt
	if heal_ratio > 0.0 and dealt > 0.0 and attacker and attacker.has_method(&"heal"):
		attacker.call(&"heal", dealt * heal_ratio)
	ticked.emit(dealt)


func _is_enemy(t: Node3D) -> bool:
	var other_team: Variant = t.get(&"team")
	if other_team == null or Teams.is_allied_fast(int(other_team), int(team)):
		return false
	# Mission truces spare a truced node (needs the living caster, like Unit.is_enemy_of).
	if Unit.truce_count > 0 and is_instance_valid(caster) and Unit.in_truce(caster, t):
		return false
	return t.has_method(&"is_alive") and bool(t.call(&"is_alive"))
