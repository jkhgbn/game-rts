class_name CastProxy
extends Node3D
## Puppet wrapper that lets the game's spell VFX hubs (SpellVfx / IceVfx / NatureVfx, which hook group "heroes" +
## a "SpellCaster" child) play real spell effects on a stage puppet (prologue 2.4). No Unit script, no AI.
## Use: `var p := CastProxy.new(); stage.add_child(p); p.setup(model, &"fire"); p.cast(&"fireball", at)`.

const PROJECTILE_IDS: Array[StringName] = [&"fireball", &"rime_bolt", &"shadow_lance"]
const KINGDOM_COLORS := {
	&"fire": Color(1.0, 0.45, 0.1), &"ice": Color(0.55, 0.85, 1.0),
	&"nature": Color(0.5, 0.95, 0.35), &"shadow": Color(0.7, 0.35, 1.0),
}
const DEFAULT_RADII := {
	&"flash_freeze": 3.0, &"wild_bloom": 5.0, &"umbral_shroud": 4.0, &"fireball": 2.5, &"thornburst": 3.0,
}

## Read by the hubs (`u.get("body_height")`).
var body_height := 1.8
var radius := 0.5
var kingdom: StringName = &"fire"
var team := 0
var _model: Node3D = null
var _caster: _ProxyCaster
var _streaks: Array[Dictionary] = []   # {node, from, to, t, time, id}


## Plain Node with the SpellCaster signals the hubs connect to.
class _ProxyCaster extends Node:
	signal spell_cast(id: StringName)
	signal spell_effect(id: StringName, position: Vector3)
	signal healed(amount: float)
	signal cooldown_started(id: StringName, seconds: float)
	var radii: Dictionary = {}

	func radius_of(id: StringName) -> float:
		return float(radii.get(id, DEFAULT_RADII.get(id, 3.0)))


func _init() -> void:
	name = "CastProxy"
	add_to_group(&"heroes")
	_caster = _ProxyCaster.new()
	_caster.name = "SpellCaster"
	add_child(_caster)


## `model`: the puppet's model node (it may already be in the tree elsewhere: the proxy then follows it).
func setup(model: Node3D, p_kingdom: StringName) -> void:
	_model = model
	kingdom = p_kingdom
	if model != null and model.get_parent() == null:
		add_child(model)
	if model != null and model.get(&"body_height") != null:
		body_height = float(model.get(&"body_height"))


func get_model() -> Node3D:
	return _model


func spell_caster() -> Node:
	return _caster


func set_radius(id: StringName, r: float) -> void:
	_caster.radii[id] = r


## Plays the cast pose now, emits `spell_cast` now and `spell_effect(id, at)` after `travel_time` (projectile ids
## draw a simple emissive streak from the hand to `at`).
func cast(spell_id: StringName, at: Vector3, travel_time: float = 0.6) -> void:
	_sync_to_model()
	if _model != null and _model.has_method(&"play_cast"):
		_model.call(&"play_cast", spell_id)
	_caster.spell_cast.emit(spell_id)
	if PROJECTILE_IDS.has(spell_id) and travel_time > 0.0:
		_start_streak(spell_id, at, travel_time)
	elif travel_time > 0.0:
		get_tree().create_timer(travel_time, true).timeout.connect(_emit_effect.bind(spell_id, at))
	else:
		_emit_effect(spell_id, at)


func _emit_effect(spell_id: StringName, at: Vector3) -> void:
	if is_inside_tree():
		_caster.spell_effect.emit(spell_id, at)


func _sync_to_model() -> void:
	if _model != null and _model.is_inside_tree() and _model.get_parent() != self:
		global_transform = _model.global_transform


func _start_streak(id: StringName, at: Vector3, time: float) -> void:
	var from := global_position + Vector3(0, body_height * 0.7, 0)
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.36
	mesh.radial_segments = 8
	mesh.rings = 4
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var c: Color = KINGDOM_COLORS.get(kingdom, Color.WHITE)
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 3.0
	mesh.material = mat
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.top_level = true
	add_child(mi)
	mi.global_position = from
	_streaks.append({"node": mi, "from": from, "to": at, "t": 0.0, "time": time, "id": id})


func _process(delta: float) -> void:
	for i in range(_streaks.size() - 1, -1, -1):
		var s: Dictionary = _streaks[i]
		s["t"] = float(s["t"]) + delta
		var k := clampf(float(s["t"]) / float(s["time"]), 0.0, 1.0)
		var node := s["node"] as Node3D
		if is_instance_valid(node):
			node.global_position = (s["from"] as Vector3).lerp(s["to"] as Vector3, k)
		if k >= 1.0:
			if is_instance_valid(node):
				node.queue_free()
			_streaks.remove_at(i)
			_emit_effect(s["id"], s["to"])
