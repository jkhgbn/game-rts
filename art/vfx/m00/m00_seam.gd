class_name M00Seam
extends Node3D
## The amber crack seam under the Emberfall watch courtyard (docs/design/mission-00.md 19.V24 "courtyard crack
## (closed / opening / sealed)"). A flat jagged decal of `length` metres along the node's local X (the mission turns it
## south-west to north-east). States: `closed` (a thin amber glow line), `opening` (wider, brighter, pulsing),
## `sealed` (cold dark scar with a last ember). Draw-only: no collider, 0 lights, no particles.

const STATES: Array[StringName] = [&"closed", &"opening", &"sealed"]
const SEGMENTS := 9

@export var length := 6.0

var state: StringName = &"closed"

var _glow: StandardMaterial3D
var _scar: StandardMaterial3D
var _pieces: Array[MeshInstance3D] = []
var _pulse: Tween


func _ready() -> void:
	_scar = StandardMaterial3D.new()
	_scar.albedo_color = Color(0.08, 0.06, 0.05, 0.85)
	_scar.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_scar.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow = StandardMaterial3D.new()
	_glow.albedo_color = Color(1.0, 0.62, 0.2, 0.9)
	_glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow.emission_enabled = true
	_glow.emission = Color(1.0, 0.55, 0.15)
	_glow.emission_energy_multiplier = 2.2
	var rng := RandomNumberGenerator.new()
	rng.seed = 1101
	var prev := Vector3(-length * 0.5, 0.0, 0.0)
	for i in SEGMENTS:
		var x := -length * 0.5 + length * float(i + 1) / float(SEGMENTS)
		var next := Vector3(x, 0.0, rng.randf_range(-0.28, 0.28) if i < SEGMENTS - 1 else 0.0)
		_piece(prev, next, 0.34, _scar, 0.02)
		_pieces.append(_piece(prev, next, 0.09, _glow, 0.03))
		if i % 3 == 1:   # a short side branch
			var tip := next + Vector3(rng.randf_range(-0.2, 0.4), 0.0, rng.randf_range(0.35, 0.7) * (1.0 if i % 2 else -1.0))
			_piece(next, tip, 0.18, _scar, 0.021)
			_pieces.append(_piece(next, tip, 0.05, _glow, 0.031))
		prev = next
	set_state(state)


func _piece(a: Vector3, b: Vector3, width: float, mat: Material, y: float) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = Vector3(a.distance_to(b) + width * 0.5, 0.01, width)
	var mi := MeshInstance3D.new()
	mi.mesh = box
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = (a + b) * 0.5 + Vector3(0.0, y, 0.0)
	mi.rotation.y = -atan2(b.z - a.z, b.x - a.x)
	add_child(mi)
	return mi


## `closed`, `opening` or `sealed` (unknown ids are ignored).
func set_state(id: StringName) -> void:
	if not STATES.has(id):
		return
	state = id
	if _glow == null:
		return
	if _pulse:
		_pulse.kill()
		_pulse = null
	match id:
		&"closed":
			_glow.albedo_color = Color(1.0, 0.62, 0.2, 0.75)
			_glow.emission_energy_multiplier = 1.6
			_set_width(1.0)
		&"opening":
			_glow.albedo_color = Color(1.0, 0.72, 0.3, 1.0)
			_glow.emission_energy_multiplier = 3.5
			_set_width(1.6)
			_pulse = create_tween().set_loops()
			_pulse.tween_property(_glow, "emission_energy_multiplier", 5.0, 0.35)
			_pulse.tween_property(_glow, "emission_energy_multiplier", 2.5, 0.35)
		&"sealed":
			_glow.albedo_color = Color(0.55, 0.22, 0.08, 0.55)
			_glow.emission_energy_multiplier = 0.5
			_set_width(0.6)


func _set_width(k: float) -> void:
	for p in _pieces:
		p.scale = Vector3(1.0, 1.0, k)
