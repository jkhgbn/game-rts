extends OmniLight3D
## Flicker of the burning hem (H05): the only real light in the set. Deterministic in time, no randomness.

var _base := 0.0
var _t := 0.0


func _ready() -> void:
	_base = light_energy


func _process(delta: float) -> void:
	_t += delta
	light_energy = _base * (0.86 + 0.09 * sin(_t * 13.0) + 0.05 * sin(_t * 29.7 + 1.3))
