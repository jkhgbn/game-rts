extends Node3D
## E34 Ep3: the heart-stone's heartbeat as a cine vfx scene (`vfx heart_stone_pulse scene=res://art/cinematics/stage_sets/
## forge_ep3_memories/props/heart_pulse.tscn at=<stone> life=<s>`). One lub-dub every PERIOD s from age 0: a flash of the
## core + an amber shock shell swelling out. Posed only by set_cine_age(age) (cine stills / seek / record and the runtime
## call it), so the light lands on the stone_thump sfx cues placed at the same times. Unposed (editor), it runs on its clock.

const PERIOD := 1.15
@export var strength: float = 1.0

var _driven := false
var _age := 0.0


func _ready() -> void:
	set_cine_age(0.0)
	_driven = false


func _process(dt: float) -> void:
	if not _driven:
		_age += dt
		_pose(_age)


func set_cine_age(age: float) -> void:
	_driven = true
	_pose(age)


static func beat(p: float) -> float:
	return exp(-pow(p * 11.0, 2.0)) + 0.65 * exp(-pow((p - 0.26) * 11.0, 2.0))


func _pose(age: float) -> void:
	var p := fposmod(maxf(age, 0.0), PERIOD)
	var flash := get_node_or_null(^"Flash") as MeshInstance3D
	var wave := get_node_or_null(^"Wave") as MeshInstance3D
	if flash != null:
		(flash.material_override as ShaderMaterial).set_shader_parameter(&"energy", 3.2 * strength * beat(p))
		flash.scale = Vector3.ONE * (0.8 + 0.5 * beat(p))
	if wave != null:
		# the shock leaves on the "lub" and on the "dub" (two shells, the second smaller)
		var w1 := clampf(p / 0.55, 0.0, 1.0)
		var w2 := clampf((p - 0.26) / 0.45, 0.0, 1.0)
		var use2 := p > 0.36
		var w := w2 if use2 else w1
		var amp := (0.6 if use2 else 1.0) * pow(1.0 - w, 1.6) * strength
		wave.scale = Vector3.ONE * (0.12 + 0.85 * sqrt(w)) * (0.8 if use2 else 1.0)
		(wave.material_override as ShaderMaterial).set_shader_parameter(&"energy", 1.1 * amp)
